initialTime  = Time.new

require 'rubygems'
require 'marc4j4r'
$: << '../marcspec/lib'
require 'marcspec'
$: << '../../threach/lib'
require 'threach'
require 'jruby_streaming_update_solr_server'
require 'logger'
require 'pp'

####################################################################################
################################## CONFIG ##########################################
####################################################################################
#### Local resource use ####

workerThreads = 1  # use 0 to fall back to a regular 'each'
sendToSolrThreads = 1
solrdocQueueSize = 64

#### Logging ####
$LOG = Logger.new('marc2solr.log')
$LOG.datetime_format = '%Y-%m-%d %H:%M:%S'
$LOG.level = Logger::DEBUG # Logger::INFO
logBatchSize = 1000

## DEBUGGING STUFF ###

actuallySendToSolr = false # whether or not to communicate with solr
ppMARC = true # So you can compare to the doc
ppDoc  = true # the doc as it would be sent to solr


#### Solr config ####

solrURL = 'http://localhost:8888/biblio/solr'
javabin = true; # true only if /update/javabin is defined in solrconfig.xml

# Clear solr out first (obviously very dangerous!)

clearSolrOut = false # CAREFUL!

# Do a commit at the end?

commitAtEnd = true

#### Input file characteristics ####

#readerType = :strictmarc 
readerType = :permissivemarc 
#readerType = :marcxml

defaultEncoding = nil # let it guess
# defaultEncoding = :utf8
# defaultEncoding = :marc8
# defaultEncoding = :iso   # ISO-8859-1


#### Directory for extra code (ruby and/or .jars) ####

loadAllFilesIn = ['simple_sample/lib'] # for custom code

#### Field / mapping configuration ####

specfile = 'simple_sample/simple_index.rb'
translationMapsDir = 'simple_sample/translation_maps'




####################################################################################
###############################END CONFIG ##########################################
####################################################################################



####################################################################################
####### Ignore everything in here ##################################################
####################################################################################

# Check to make sure we can get the specfile and the marc file

$LOG.info "Checking files"
unless File.readable? specfile
  raise ArgumentError, "Specfile '#{specfile}' not readable"
end
$LOG.debug "Spec file exists"

marcfile = ARGV[0]
unless File.readable? marcfile
  raise ArgumentError, "MARC File '#{marcfile}' not readable"
end
$LOG.debug "MARC file exists"

# Load up everything in the loadAllFilesIn directories
loadAllFilesIn.uniq.compact.each do |dir|
  unless File.exist? dir
    $LOG.info "Skipping load directory '#{dir}': Not found"
  end
  $LOG.info "Loading files in #{dir}"
  Dir.glob(["#{dir}/*.rb", "#{dir}/*.jar"]).each do |x|
    $LOG.debug "Loading #{x}"
    require x
  end
end

# Create a specset

ss = MARCSpec::SpecSet.new

ss.loadMapsFromDir translationMapsDir



# Get the list of specs and load them up. We differentiate a custom routine
# because it has a :module defined

speclist = eval(File.open(specfile).read)
speclist.each do |spechash|
  if spechash[:module]
    solrspec = MARCSpec::CustomSolrSpec.fromHash(spechash)
  else
    solrspec = MARCSpec::SolrFieldSpec.fromHash(spechash)
  end
  if spechash[:mapname]
    map = ss.map(spechash[:mapname])
    unless map
      $LOG.error "  Cannot find map #{spechash[:mapname]} for field #{spechash[:solrField]}"
    else
      $LOG.debug "  Found map #{spechash[:mapname]} for field #{spechash[:solrField]}"
      solrspec.map = map
    end
  end
  ss.add_spec solrspec
  $LOG.debug "Added spec #{solrspec.solrField}"
end

$LOG.info "Added #{ss.solrfieldspecs.size} specs"

# Create the SUSS

if actuallySendToSolr
  suss = StreamingUpdateSolrServer.new(solrurl,solrdocQueueSize,sendToSolrThreads)
  if javabin
    suss.setRequestWriter Java::org.apache.solr.client.solrj.impl.BinaryRequestWriter.new
  end
  $LOG.info "Got the suss"
end

# Get the reader

reader = MARC4J4R::Reader.new(marcfile, readerType, defaultEncoding)

$LOG.info "Got the reader"
## Clear things out if requested, and it's not a dry run

if clearSolrOut and actuallySendToSolr
  suss.deleteByQuery('*:*')
  suss.commit
  $LOG.info "Cleaned out Solr"
end


# Actually do the work
loopStartTime = Time.new
prevTime = loopStartTime



####################################################################################
####### OK, start paying attention again############################################
####################################################################################


i = 0 # Seed it so it'll exist after the loop exits
$LOG.debug "Starting the loop"

reader.threach(workerThreads, :each_with_index) do |r, i|

  doc = ss.doc_from_marc(r)
  # If you've got super-custom routines (that don't get put in your index file),
  # this is the spot for them.
  #
  # Do either
  #   doc[fieldname] = value_or_array_of_values
  # or
  #   doc.merge! hash_of_fieldname_value_pairs


  # Send it to solr
  suss << doc if actuallySendToSolr

  # ...and/or STDOUT
  puts r if ppMARC
  puts doc if ppDoc
  puts "\n--------------------------\n" if ppMARC or ppDoc

  # Throw a log line if it's time
  if (i % logBatchSize == 0)
    curtime = Time.new
    secs  = '%.0f' % (curtime.to_f - prevTime.to_f)
    pace  = '%.0f' % (i / (curtime.to_f - initialTime.to_f))
    $LOG.info "#{i} #{secs}s this batch, (#{pace}r/s so far)"
    prevTime = curtime
  end
end

# Final commit
$LOG.info "Final commit"
suss.commit if commitAtEnd and actuallySendToSolr

finalTime = Time.new
$LOG.info "Finished"
$LOG.info "Done. Waiting for HTTP Reader to time out or whatever it does"

$LOG.info "Started at:  " + initialTime.to_s
$LOG.info "Finished at: " + finalTime.to_s

$LOG.info "Total of #{i} records in " + '%.0f' % (finalTime.to_f - initialTime.to_f) + " seconds"
$LOG.info '%.0f' % (i / (finalTime.to_f - initialTime.to_f)) + ' records/sec pace for the whole thing'
