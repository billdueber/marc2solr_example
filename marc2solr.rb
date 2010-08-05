initialTime  = Time.new

require 'rubygems'
require 'marc4j4r'
$: << '../marcspec/lib'
require 'marcspec'
require 'threach'
require 'jruby_streaming_update_solr_server'
require 'logger'
require 'pp'

####################################################################################
################################## CONFIG ##########################################
####################################################################################

#### Just trying it out? Output as pretty strings instead ####
actuallySendToSolr = false

#### Logging ####
$LOG = Logger.new(STDOUT)
$LOG.level = Logger::WARN
logBatchSize = 25000

#### Solr config ####

solrURL = 'http://localhost:8888/biblio/solr'
javabin = true; # true only if /update/javabin is defined in solrconfig.xml

# Clear solr out first (obviously very dangerous!)

clearSolrOut = false # CAREFUL!

# Do a commit at the end?

commitAtEnd = true

#### Input file characteristics ####

readerType = :strictmarc 
#readertype = :permissivemarc 
#readertype = :marcxml

defaultEncoding = nil # let it guess
# defaultEncoding = :utf8
# defaultEncoding = :marc8
# defaultEncoding = :iso   # ISO-8859-1


#### Directory for extra code (ruby and/or .jars) ####

loadAllFilesIn = ['umich_sample/lib'] # for custom code

#### Field / mapping configuration ####

specfile = 'umich_sample/specs/umich_index.rb'
translationMapsDir = 'umich_sample/translation_maps'


#### Local resource use ####

workerThreads = 1
sendToSolrThreads = 1
solrdocQueueSize = 64


####################################################################################
###############################END CONFIG ##########################################
####################################################################################
puts "Loaded"
# Check to make sure we can get the specfile and the marc file

$LOG.debug "Checking files"
unless File.readable? specfile
  raise ArgumentError, "Specfile '#{specfile}' not readable"
end

puts "Spec file ok"
marcfile = ARGV[0]
unless File.readable? marcfile
  raise ArgumentError, "MARC File '#{marcfile}' not readable"
end
puts "MARC file ok"

# Load up everything in the loadAllFilesIn directories
loadAllFilesIn.uniq.compact.each do |dir|
  unless File.exist? dir
    $LOG.warn "Skipping load directory '#{dir}': Not found"
  end
  puts "Loading files in #{dir}"
  Dir.glob(["#{dir}/*.rb", "#{dir}/*.jar"]).each do |x|
    puts "Loading #{x}"
    require x
  end
end

# Create a specset

puts "Create ss"
ss = MARCSpec::SpecSet.new

# Load up the tmaps and the specfile
unless File.exist? translationMapsDir 
  $LOG.error "Can't find directory #{translationMapsDir}; aborting"
  exit
end

puts "Found tmaps dir"

Dir.glob("#{translationMapsDir}/*").each do |tmap|
  puts "Adding #{tmap}"
  ss.add_map(MARCSpec::Map.fromFile(tmap))
end

# Get the list of specs and load them up
speclist = eval(File.open(specfile).read)
speclist.each do |spec|
  solrspec = MARCSpec::SolrFieldSpec.fromHash(spec)
  if spec[:mapname]
    map = ss.map(spec[:mapname])
    unless map
      puts "  Cannot find map #{spec[:mapname]} for field #{spec[:solrField]}"
    else
      puts "  Found map #{spec[:mapname]} for field #{spec[:solrField]}"
      solrspec.map = map
    end
  end
  ss.add_spec solrspec
  puts "Added spec #{solrspec.solrField}"
end

puts "Added #{ss.solrfieldspecs.size} specs"

# Create the SUSS

if actuallySendToSolr
  suss = StreamingUpdateSolrServer.new(solrurl,solrdocQueueSize,sendToSolrThreads)
  if javabin
    suss.setRequestWriter Java::org.apache.solr.client.solrj.impl.BinaryRequestWriter.new
  end
end

puts "Got the suss (if requested)"
# Get the reader

reader = MARC4J4R::Reader.new(marcfile, readerType, defaultEncoding)

puts "Got the reader"
## Clear things out if requested, and it's not a dry run

if clearSolrOut and actuallySendToSolr
  suss.deleteByQuery('*:*')
  suss.commit
  $LOG.debug "Cleaned out Solr"
end

puts "Cleaned out (if requested)"

# Actually do the work
loopStartTime = Time.new
prevTime = loopStartTime

$LOG.debug "Starting the loop at #{loopStartTime}"

i = 0 # Seed it so it'll exist after the loop exits
reader.threach(workerThreads, :each_with_index) do |r, i|
  puts "Loaded a record: #{r['245']}"
  doc = ss.doc_from_marc(r)
  
  puts r
  puts doc
  next
  
  # We should be able to do custom routines via configuration pretty easily. For now,
  # stick them here. MARC2Solr::UMich is loaded from the lib directory automatically,
  # and everything is set up as module functions. This will allow us to configure
  # (eventually) like
  #  [:custom, MARC2Solr::UMich, :getAllSearchableFields, ['100', '999'], nil]
  #  [:custom, MARC2Solr::UMich, :getLanguage, nil, 'language_map']
  
  puts "Starting custom fields"
  doc['allfields']   = MARC2Solr::UMich.getAllSearchableFields(r, '100', '999')
  doc['language']    = MARC2Solr::UMich.getLanguage(r, ss.map('language_map'))
  doc['title']       = MARC2Solr::UMich.getTitle(r, %w(a b d e f g h k n p))
  doc['titleSort']   = MARC2Solr::UMich.getTitle_sort(r)
  doc['publishDate'] =  MARC2Solr::UMich.getDate(r)
  
  doc['fullrecord'] = r.to_xml
  
  if actuallySendToSolr
    suss << doc
    puts "Sent to solr"
  else
    pp doc
    pp "---------------\n"
  end
  
  if (i % logBatchSize)
    curtime = Time.new
    print ('%6d' % i) + "\t" +  Time.new.to_s 
    print (' %6d %6.0f' % [count, (curtime.to_f - prevtime.to_f)]) + "\t" + "seconds, " 
    puts ('%4.0f' % (count / (curtime.to_f - initialTime.to_f))) + ' r/s pace overall'
    prevtime = curtime
  end
  
end


# Final commit
$LOG.debug "Final commit"
suss.commit if commitAtEnd and actuallySendToSolr

$LOG.debug "Finished"
puts "Done. Waiting for HTTP Reader to time out or whatever it does"

puts "\n\nStarted at:  " + initialTime.to_s
puts "Finished at: " + finalTime.to_s

puts "\nTotal of #{i} records"
puts ('%6.0f' % (finalTime.to_f - initialTime.to_f)) + "\t" + "seconds for the whole batch of #{i}\n"
puts "      \t" + ('%4.0f' % (count / (finalTime.to_f - initialtime.to_f))) + ' records/s pace for the whole thing'
