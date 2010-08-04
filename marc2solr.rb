#require 'rubygems'
require 'marc4j4r'
require 'marcspec'
require 'threach'
require 'jruby_streaming_update_solr_server'


####################################################################################
################################## CONFIG ##########################################
####################################################################################

#### Solr config ####

solrURL = 'http://localhost:8888/biblio/solr'
javabin = true; # true only if /update/javabin is defined in solrconfig.xml


#### Input file characteristics ####

readertype = :strictmarc 
#readertype = :permissivemarc 
#readertype = :marcxml

defaultEncoding = nil # let it guess
# defaultEncoding = :utf8
# defaultEncoding = :marc8
# defaultEncoding = :iso   # ISO-8859-1


#### Directory for extra code (ruby and/or .jars) ####

loadAllFilesIn = null

#### Field / mapping configuration ####

specfile = 'converted_index.rb'
translationMapsDir = './translation_maps'


#### How many threads to use ####

workerThreads = 2
sendToSolrThreads = 1


####################################################################################
###############################END CONFIG ##########################################
####################################################################################
