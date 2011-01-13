###############################
######## HELPERS ##############
###############################

# First, just make a couple variables so I don't have to
# keep typing MARC2Solr::Custom and MARC2Solr::Custom::UMich

mc = MARC2Solr::Custom
mcu = MARC2Solr::Custom::UMich


################################
###### CORE FIELDS #############
################################



field('id') do
  firstOnly
  spec('001')
end

custom('fullrecord') do
  function(:asXML) {
    mod mc
  }
end

custom('allfields') do
  function(:getAllSearchableFields) {
    mod mc
    args '100', '999'
  }
end

######## Local Data ##########

field("format") do
  mapname 'format_map_umich'
  spec("970a")
end

field("availability") do
  mapname "availability_map_umich"
  spec("973b")
end

field("cat_date") do
  spec("972c")
end

#### INSTITUTION / LOCATION ####

field("institution") do
  mapname "institution_map"
  spec("971a")
end

field("building") do
  mapname "library_map"
  spec("852bc")
  spec("971a")
end

field('location') do
  mapname "location_map"
  mapMissDefault :passthrough
  spec("971a")
  spec("852") {
    sub 'b'
    sub 'bc'
  }
end

################################
######## IDENTIFIERS ###########
################################

field('lccn') do
  spec("010a")
end

field('rptnum') do
  spec("088a")
end

custom('oclc') do
  function(:valsByPattern) {
    mod mc
    args '035', 'a', /(?:oclc|ocolc|ocm|ocn).*?(\d+)/i, 1
  }
end

custom('sdrnum') do
  function(:valsByPattern) {
    mod mc
    args '035', 'a', /^sdr-?(.*)/, 0
  }
end

custom('isbn') do
  function(:getISBNS) {
    mod mc
    args ['a', 'z']
  }
end

field('issn') do
  spec("022") {
    sub 'a'
    sub 'l'
    sub 'm'
    sub 'y'
    sub 'z'
  }
  spec('247x')
end


field('isn_related') do
  spec("400x")
  spec("410x")
  spec("411x")
  spec("440x")
  spec("490x")
  spec("500x")
  spec("510x")
  spec("534xz")
  spec("556z")
  spec("581z")
  spec("700x")
  spec("710x")
  spec("711x")
  spec("730x")
  spec("760x")
  spec("762x")
  spec("765xz")
  spec("767xz")
  spec("770xz")
  spec("772x")
  spec("773xz")
  spec("774xz")
  spec("775xz")
  spec("776xz")
  spec("777x")
  spec("780xz")
  spec("785xz")
  spec("786xz")
  spec("787xz")
end

field('callnumber') do
  spec("852hij")
end

field('sudoc') do
  spec("086") {
    sub 'a'
    sub 'z'
  }
end

################################
######### AUTHOR FIELDS ########
################################

field('author') do
  spec("100abcd")
  spec("110abcd")
  spec("111abc")
end

field('author2') do
  spec("110ab")
  spec("111ab")
  spec("700abcd")
  spec("710ab")
  spec("711ab")
end

field("author_top") do
  spec("100abcdefgjklnpqtu0")
  spec("110abcdefgklnptu04")
  spec("111acdefgjklnpqtu04")
  spec("700abcdejqux034")
  spec("710abcdeux034")
  spec("711acdegjnqux034")
  spec("720a")
  spec("765a")
  spec("767a")
  spec("770a")
  spec("772a")
  spec("774a")
  spec("775a")
  spec("776a")
  spec("777a")
  spec("780a")
  spec("785a")
  spec("786a")
  spec("787a")
  spec("245c")
end

field("author_rest") do
  spec("505r")
end

################################
########## TITLES ##############
################################

custom('title') do
  function(:getTitle) {
    mod mcu
    args 'abdefghknp'.split(//)
  }
end

custom('title_ab') do
  function(:getTitle) {
    mod mcu
    args ['a', 'k', 'b']
  }
end

custom('title_a') do
  function(:getTitle) {
    mod mcu
    args ['a', 'k']
  }
end

# titleSort is the same as title_ab, but with the transform in 
# getTitleSortable applied

custom('titleSort') do
  function(:getTitleSortable) {
    mod mcu
    args ['a', 'k', 'b']
  }
end  

field('title_top') do
  spec("240adfghklmnoprs0")
  spec("245abfghknps")
  spec("111acdefgjklnpqtu04")
  spec("130adfghklmnoprst0")
end

field('title_rest') do
  spec("210ab")
  spec("222ab")
  spec("242abhnpy")
  spec("243adfghklmnoprs")
  spec("246abdenp")
  spec("247abdenp")
  spec("700fghjklmnoprstx03")
  spec("710fghklmnoprstx03")
  spec("711acdefghjklnpqstux034")
  spec("730adfghklmnoprstx03")
  spec("740ahnp")
  spec("765st")
  spec("767st")
  spec("770st")
  spec("772st")
  spec("773st")
  spec("775st")
  spec("776st")
  spec("777st")
  spec("780st")
  spec("785st")
  spec("786st")
  spec("787st")
  spec("830adfghklmnoprstv")
  spec("440anpvx")
  spec("490avx")
  spec("505t")
end

field('series') do
  spec("440ap")
  spec("800abcdfpqt")
  spec("830ap")
end

field('series2') do
  spec("490a")
end

# Serial titles count on the format alreayd being set and having the string 'Serial' in it.

custom('serialTitle') do
  function(:getSerialTitle) {
    mod mcu
    args 'abdefghknp'.split(//)
  }
end

custom('serialTitle_ab') do
  function(:getSerialTitle) {
    mod mcu
    args ['a', 'b']
  }
end

custom('serialTitle_a') do
  function(:getSerialTitle) {
    mod mcu
    args ['a']
  }
end

custom('serialTitle_rest') do
  function(:getSerialTitleRest) {
    mod mcu
  }
end

################################
######## SUBJECT / TOPIC  ######
################################

field('topic') do
  spec("600abcdefghjklmnopqrstuvxyz")
  spec("600a")
  spec("610abcdefghklmnoprstuvxyz")
  spec("610a")
  spec("611acdefghjklnpqstuvxyz")
  spec("611a")
  spec("630adefghklmnoprstvxyz")
  spec("630a")
  spec("648avxyz")
  spec("648a")
  spec("650abcdevxyz")
  spec("600a")
  spec("651aevxyz")
  spec("651a")
  spec("653a")
  spec("654abevyz")
  spec("654a")
  spec("655abvxyz")
  spec("655a")
  spec("656akvxyz")
  spec("656a")
  spec("657avxyz")
  spec("657a")
  spec("658ab")
  spec("658a")
  spec("662abcdefgh")
  spec("662a")
end




###############################
#### Genre / geography / dates
###############################


field('genre') do
  spec("655ab")
end

field('geographic') do
  mapname 'area_map'
  spec("043a")
end

field('era') do
  spec("600y")
  spec("610y")
  spec("611y")
  spec("630y")
  spec("650y")
  spec("651y")
  spec("654y")
  spec("655y")
  spec("656y")
  spec("657y")
  spec("690z")
  spec("691y")
  spec("692z")
  spec("694z")
  spec("695z")
  spec("696z")
  spec("697z")
  spec("698z")
  spec("699z")
end

# country from the 008; need processing until I fix the AlephSequential reader

custom('country_of_pub') do
  function(:country_of_pub) {
    mod mcu
  }
end

# Also do the 752 for country of pub
field('country_of_pub') do
  spec("752ab")
end

custom('publishDate') do
  function(:getDate) {
    mod mc
  }
end

custom('publishDateRange') do
  function(:publishDateRange) {
    mod mcu
  }
end


################################
########### MISC ###############
################################

field('publisher') do
  spec("260b")
  spec("533c")
end

field('edition') do
  spec("250a")
end

custom('language') do
  mapname 'language_map'
  function(:getLanguage) {
    mod mcu
  }
end

#####################################
############ HATHITRUST STUFF #######
#####################################

field('ht_availability') do
  mapname 'availability_map_ht'
  spec("974r")
end

field('ht_availability_intl') do
  mapname 'availability_map_ht_intl'
  spec("974r")
end

custom('htsource') do
  mapname 'ht_namespace_map'
  function(:valsByPattern) {
    mod mc
    args '974',  # tag
           'u',  # subfield
          /^([a-z0-9]+)\./, # match this
          1 # return this match variable (everything up to the first period)
  }
end

custom(['ht_id_display', 'ht_id_update', 'ht_id', 'ht_json']) do
  function(:getHathiStuff) {
    mod mcu
  }
end

#custom('ht_searchonly') do
#  function(:isJustHathiSearchOnly) {
#    mod mcu
#    args 'ht_availability'
#  }
#end

#custom('ht_searchonly_intl') do
#  function(:isJustHathiSearchOnly) {
#    mod mcu
#    args 'ht_availability_intl'
#  }
#end

########### HLB #############


custom(['hlb3', 'hlb3Delimited']) do
  function(:getHLBStuff) {
    mod MARC2Solr::Custom::HighLevelBrowse
  }
end

