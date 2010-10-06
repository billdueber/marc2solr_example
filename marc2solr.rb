$KCODE = 'utf8'
initialTime  = Time.new
require 'rubygems'
gem 'threach'
gem 'marcspec', ">= 1.5.0"
gem 'marc4j4r'
gem 'jruby_streaming_update_solr_server'

require 'logger'
require 'pp'


####################################################################################
################     Get the arguments        ######################################

marcfile = ARGV[0] # where the MARC file is
baseDir =  ARGV[1] # The directory that contains index.rb, translation_maps/ and lib/

unless marcfile =~ /\S/ and baseDir =~ /\S/
  puts "Need both a marcfile and a directory"
  exit
end

####################################################################################
################################## CONFIG ##########################################
####################################################################################

## DEBUGGING STUFF ###

benchmarkspecs = false # get timings for each of your solrFields. Only with useThreach == false!!!
actuallySendToSolr = false # whether or not to communicate with solr
ppMARC = false # Pretty print the MARC, so you can compare to the doc
ppDoc  = true  # Pretty print the doc as it would be sent to solr
useThreach = false

#### Solr config ####

solrURL = 'http://mojito.umdl.umich.edu:8024/solr/biblio/'
javabin = true; # true only if /update/javabin is defined in solrconfig.xml

# Clear solr out first (obviously very dangerous!)

clearSolrOut = false # CAREFUL!

# Do a commit at the end?

commitAtEnd = true


#### Index, translation maps, and directory for extra code (ruby and/or .jars) ####

# Derive the rest
loadAllFilesIn = ["#{baseDir}/lib"] # for custom code
# specfile = "#{baseDir}/index.rb"
specfile = "#{baseDir}/index.dsl"
translationMapsDir = "#{baseDir}/translation_maps"



#### Local resource use ####

workerThreads = 2  
sendToSolrThreads = 1
solrdocQueueSize = 64

#### Logging ####

logfilename = File.basename(marcfile).split(/\./)[0] + '-' + Time.new.strftime('%Y%m%d-%H%M%S') + '.log'
marcfileextension  = File.basename(marcfile).split(/\./)[-1]

if marcfileextension == 'gz'
  marcfileextension  = File.basename(marcfile).split(/\./)[-2]
  gzipped = true
end

# loglevel = Logger::DEBUG
loglevel = Logger::INFO 
logBatchSize = 1000

$stderr.sync = true
$stderr.puts "Processing #{marcfile}\n Logfile is #{logfilename}"

#### Input file characteristics ####

readerType = :figureOutByExtension
# readerType = :strictmarc 
# readerType = :permissivemarc 
# readerType = :marcxml

defaultEncoding = nil # let it guess
# defaultEncoding = :utf8
# defaultEncoding = :marc8
# defaultEncoding = :iso   # ISO-8859-1





####################################################################################
###############################END CONFIG ##########################################
####################################################################################



####################################################################################
####### Ignore everything in here ##################################################
####################################################################################

# Check to make sure we can get the specfile and the marc file


$LOG = Logger.new(logfilename)
$LOG.datetime_format = '%Y%m%d %H:%M:%S'
$LOG.level = loglevel


$LOG.info "Checking files"
unless File.readable? specfile
  raise ArgumentError, "Specfile '#{specfile}' not readable"
end
$LOG.debug "Spec file exists"

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
  Dir.glob(["#{dir}/*.jar"]).each do |x|
    $LOG.debug "Loading #{x}"
    require x
  end
  Dir.glob(["#{dir}/*.rb"]).each do |x|
    $LOG.debug "Loading #{x}"
    require x
  end
end

# Create a specset

ss = MARCSpec::SpecSet.new

ss.loadMapsFromDir translationMapsDir

ss.buildSpecsFromDSLFile(specfile)

$LOG = Logger.new(logfilename)
$LOG.datetime_format = '%Y%m%d %H:%M:%S'
$LOG.level = Logger::DEBUG
# $LOG.level = Logger::INFO 



$LOG.info "Added #{ss.solrfieldspecs.size} specs"

# Create the SUSS

if actuallySendToSolr
  suss = StreamingUpdateSolrServer.new(solrURL,solrdocQueueSize,sendToSolrThreads)
  if javabin
    suss.setRequestWriter Java::org.apache.solr.client.solrj.impl.BinaryRequestWriter.new
  end
  $LOG.info "Got the suss"
end

# Get the reader

typeOfReader = readerType # as set up above in config
if readerType == :figureOutByExtension
  case marcfileextension 
  when /XML/i
    typeOfReader = :marcxml
  when /SEQ/i
    typeOfReader = :alephsequential
  else
    typeOfReader = :permissivemarc
  end
end

source = marcfile
if gzipped
  source = Java::java.util.zip.GZIPInputStream.new(IOConvert.byteinstream(marcfile))
end

puts "Source is #{source.inspect}"

reader = MARC4J4R::Reader.new(source, typeOfReader, defaultEncoding)

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

if useThreach
  method = :threach
  args = [workerThreads, :each_with_index]
else
  method = :each_with_index
  args = []
end

reader.send(method, *args) do |r, i|
  doc = ss.doc_from_marc(r, benchmarkspecs)
  # Send it to solr
  suss << doc if actuallySendToSolr

  # ...and/or STDOUT
  puts r if ppMARC
  if ppDoc
    doc.keys.sort.each do |k|
      puts [doc['id'][0], k, doc[k].sort.join('^')].join("\t")
    end
  end
  # puts "\n--------------------------\n" if ppMARC or ppDoc

  # Throw a log line if it's time
  
  if (i % logBatchSize == 0)
    curtime = Time.new
    secs  = '%.1f' % (curtime.to_f - prevTime.to_f)
    pace  = '%.0f' % (i / (curtime.to_f - initialTime.to_f))
    $LOG.info "#{i} #{secs}s this batch, (#{pace}r/s so far)"
    prevTime = curtime
  end
end

# Final commit
if commitAtEnd and actuallySendToSolr
  suss.commit 
  $LOG.info "Final commit"
end


finalTime = Time.new
$LOG.info "Finished"
$LOG.info "Done. Waiting for HTTP Reader to time out or whatever it does"

$LOG.info "Started at:  " + initialTime.to_s
$LOG.info "Finished at: " + finalTime.to_s

$LOG.info "Total of #{i} records in " + '%.0f' % (finalTime.to_f - initialTime.to_f) + " seconds"
$LOG.info '%.0f' % (i / (finalTime.to_f - initialTime.to_f)) + ' records/sec pace for the whole thing'

if benchmarkspecs
  ss.benchmarks.keys.sort{|a,b| ss.benchmarks[b].real <=> ss.benchmarks[a].real}.each do |k|
    $LOG.info("%-20s %s" % [k + ':', ss.benchmarks[k].real.to_s])
  end
end

