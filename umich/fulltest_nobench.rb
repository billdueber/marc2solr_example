include Java

####### SETUP ####### 


#INPUTFILE = '/l/solr-vufind/data/vufind_full_20100524.seq'
#INPUTFILE = '/l/solr-vufind/data/150k.seq'
#INPUTFILE = 'fulldump/problem_record.seq'

PORT = ARGV[0]
INPUTFILE = ARGV[1]

pcthreads = 1
sussthreads = 1 # Number of threads to push docs from queue to solr

puts "Putting #{INPUTFILE} into port #{PORT}"
CLEAR = false
BINARY = true

if PORT == 8026
  puts "Not on my watch!"
  exit
end



NORMAL = true
CUSTOM = true
ALLFIELDS = true
XML = true
SUSS = true


solrurl = 'http://localhost:' + PORT.to_s + '/solr/biblio' # URL to solr

sussqueuesize = 64 # Size of producer cache

suss  = nil
pc = nil
reader = nil
ss = nil

logbatch = 25000

prevtime = Time.new
curtime = Time.new
initialtime = Time.new

puts "Starting: " + initialtime.to_s
puts "SUSS threads: #{sussthreads}"
puts "Worker threads: #{pcthreads}"

require 'rubygems'
require 'jruby-prof'

#### LOAD THE JARS #####
curdir = File.dirname(__FILE__)
Dir.glob("#{curdir}/../jars/*.jar") do |x|
  require x
end

puts "Finished loading jars"

#### LOAD THE GEMS AND LIBRARIES #####

require '../lib/custom.rb' # includes the jars, too

require '../../jruby_streaming_update_solr_server/lib/jruby_streaming_update_solr_server.rb'
require '../../marc4j4r/lib/marc4j4r.rb'
require '../lib/marc_translation_spec.rb'
require '../../threach/lib/threach.rb'

#### GET THE SUSS, READER, and PRODUCER/CONSUMER OBJECTS  


include_class Java::org.solrmarc.marc.MarcAlephSequentialReader

#reader = MARC4J4R.reader(INPUTFILE);
reader = MarcAlephSequentialReader.new(java.io.FileInputStream.new(INPUTFILE.to_java_string))

ss = MARC2Solr::SpecSet.new('../fixedrb/umich_index.rb', '../fixedrb/translation_maps')

####### Clean out solr #######

if SUSS
  suss = StreamingUpdateSolrServer.new(solrurl,sussqueuesize,sussthreads)
  if BINARY
    suss.setRequestWriter Java::org.apache.solr.client.solrj.impl.BinaryRequestWriter.new
  end
  if CLEAR
    suss.deleteByQuery('*:*')
    suss.commit
    puts "Cleaned out solr"
  end
end




#### Get an object that does the custom functions ####
umc = UMichCustom.new(ss)

puts "Got a UMichCustom object"

#### RUN THE LOOP ####

count = 0

reader.threach(pcthreads) do |r|
#reader.each do |r|
#  puts "Working on #{r['001']}"
  doc = nil
  doc = SolrInputDocument.new unless NORMAL
  doc = ss.doc_from_marc(r) if NORMAL

  doc['allfields'] = umc.getAllSearchableFields(r, '100', '999') if ALLFIELDS
  
  # OCLC & SDRNumber
  if CUSTOM
    doc['oclc'] = umc.getOCLC(r)
    doc['sdrnum'] = umc.getSDRNum(r)
    doc['htsource'] = umc.htSourcePrefixes(r)
    doc['language'] = umc.getLanguage(r)
    doc.merge! umc.getDateStuffAsHash(r)
    doc.merge! umc.getHathiStuffAsHash(r)
    doc['title'] = umc.getTitle(r, %w(a b d e f g h k n p))
    doc['title_ab'] = umc.getTitle(r, %w(a k b))
    doc['title_a'] = umc.getTitle(r, %w(a k))
    doc['titleSort'] = umc.getTitle_sort(r)
  
    # Get the list of formats for this stuff
      
    if doc[:format] and doc[:format].include? 'Serial'
      doc['serialTitle'] = umc.getTitle(r, %w(a b d e f g h k n p))
      doc['serialTitle_ab'] = umc.getTitle(r, %w(a b))
      doc['serialTitle_a'] = umc.getTitle(r, %w(a))
      doc['serialTitle_rest'] = umc.getSerialTitleRest(r)
    end
  end # CUSTOM

  doc.merge! umc.getHLBStuffAsHash(r)
  
  doc['fullrecord'] = r.to_xml if XML

  suss <<  doc if SUSS
  # puts "#{doc['id']} added (#{count})"
  
  count += 1

  #break if count > 10
  
  #### TIMINGS #####
  if (count % logbatch) == 0
    curtime = Time.new
    puts ('%6d' % count) + "\t" +  Time.new.to_s 
    puts ('%6d %6.0f' % [count, (curtime.to_f - prevtime.to_f)]) + "\t" + "seconds for this batch of #{logbatch}\n"
    puts "      \t" + ('%4.0f' % (count / (curtime.to_f - initialtime.to_f))) + ' records/s pace overall at this point'
    prevtime = curtime

   # only commit at end
   #  suss.commit if SUSS 
    
  end
  
end

puts "Final commit"
suss.commit if SUSS

finalTime = Time.new

puts "\n\nStarted at:  " + initialtime.to_s
puts "Finished at: " + finalTime.to_s

puts "\nTotal of #{count} records"
puts ('%6.0f' % (finalTime.to_f - initialtime.to_f)) + "\t" + "seconds for the whole batch of #{count}\n"
puts "      \t" + ('%4.0f' % (count / (finalTime.to_f - initialtime.to_f))) + ' records/s pace for the whole thing'

