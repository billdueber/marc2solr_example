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
  spec('970') {sub 'a'}
end

field("availability") do
  mapname "availability_map_umich"
  spec("973") {sub 'b'}
end

field("cat_date") do
  spec("972") {sub 'c'}
end

#### INSTITUTION / LOCATION ####

field("institution") do
  mapname "institution_map"
  spec("971") {sub 'a'}
end

field("building") do
  mapname "library_map"
  spec("852") {sub 'bc'}
  spec("971") {sub 'a'}
end

field('location') do
  mapname "location_map"
  mapMissDefault :passthrough
  spec("971") {sub 'a'}
  spec("852") {
    sub 'b'
    sub 'bc'
  }
end

################################
######## IDENTIFIERS ###########
################################

field('lccn') do
  spec('010') {sub 'a'}
end

field('rptnum') do
  spec("088") {sub 'a'}
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

field('isbn') do
  spec("020") {
    sub 'a'
    sub 'z'
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
  spec(247) {
    sub 'x'
  }
end


field('isn_related') do
  spec("400") {subs "x"}
  spec("410") {subs "x"}
  spec("411") {subs "x"}
  spec("440") {subs "x"}
  spec("490") {subs "x"}
  spec("500") {subs "x"}
  spec("510") {subs "x"}
  spec("534") {subs "xz"}
  spec("556") {subs "z"}
  spec("581") {subs "z"}
  spec("700") {subs "x"}
  spec("710") {subs "x"}
  spec("711") {subs "x"}
  spec("730") {subs "x"}
  spec("760") {subs "x"}
  spec("762") {subs "x"}
  spec("765") {subs "xz"}
  spec("767") {subs "xz"}
  spec("770") {subs "xz"}
  spec("772") {subs "x"}
  spec("773") {subs "xz"}
  spec("774") {subs "xz"}
  spec("775") {subs "xz"}
  spec("776") {subs "xz"}
  spec("777") {subs "x"}
  spec("780") {subs "xz"}
  spec("785") {subs "xz"}
  spec("786") {subs "xz"}
  spec("787") {subs "xz"}
end

field('callnumber') do
  spec("852") { subs 'hij'}
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
  spec("100") {sub 'abcd'}
  spec("110") {sub 'abcd'}
  spec("111") {sub 'abc'}
end

field('author2') do
  spec("110") {sub 'ab'}
  spec("111") {sub 'ab'}
  spec("700") {sub 'abcd'}
  spec("710") {sub 'ab'}
  spec("711") {sub 'ab'}
end

field("author_top") do
  spec("100") {subs "abcdefgjklnpqtu0"}
  spec("110") {subs "abcdefgklnptu04"}
  spec("111") {subs "acdefgjklnpqtu04"}
  spec("700") {subs "abcdejqux034"}
  spec("710") {subs "abcdeux034"}
  spec("711") {subs "acdegjnqux034"}
  spec("720") {sub "a"}
  spec("765") {sub "a"}
  spec("767") {sub "a"}
  spec("770") {sub "a"}
  spec("772") {sub "a"}
  spec("774") {sub "a"}
  spec("775") {sub "a"}
  spec("776") {sub "a"}
  spec("777") {sub "a"}
  spec("780") {sub "a"}
  spec("785") {sub "a"}
  spec("786") {sub "a"}
  spec("787") {sub "a"}
  spec("245") {sub "c"}
end

field("author_rest") do
  spec("505") {sub 'r'}
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
  spec("240") {subs 'adfghklmnoprs0'}
  spec("245") {subs 'abfghknps'}
  spec("111") {subs 'acdefgjklnpqtu04'}
  spec("130") {subs 'adfghklmnoprst0'}
end

field('title_rest') do
  spec("210") {subs "ab"}
  spec("222") {subs "ab"}
  spec("242") {subs "abhnpy"}
  spec("243") {subs "adfghklmnoprs"}
  spec("246") {subs "abdenp"}
  spec("247") {subs "abdenp"}
  spec("700") {subs "fghjklmnoprstx03"}
  spec("710") {subs "fghklmnoprstx03"}
  spec("711") {subs "acdefghjklnpqstux034"}
  spec("730") {subs "adfghklmnoprstx03"}
  spec("740") {subs "ahnp"}
  spec("765") {subs "st"}
  spec("767") {subs "st"}
  spec("770") {subs "st"}
  spec("772") {subs "st"}
  spec("773") {subs "st"}
  spec("775") {subs "st"}
  spec("776") {subs "st"}
  spec("777") {subs "st"}
  spec("780") {subs "st"}
  spec("785") {subs "st"}
  spec("786") {subs "st"}
  spec("787") {subs "st"}
  spec("830") {subs "adfghklmnoprstv"}
  spec("440") {subs "anpvx"}
  spec("490") {subs "avx"}
  spec("505") {subs "t"}
end

field('series') do
  spec("440") {subs "ap"}
  spec("800") {subs "abcdfpqt"}
  spec("830") {subs "ap"}
end

field('series2') do
  spec("490") {sub 'a'}
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
  spec("600") {subs "abcdefghjklmnopqrstuvxyz"}
  spec("600") {subs "a"}
  spec("610") {subs "abcdefghklmnoprstuvxyz"}
  spec("610") {subs "a"}
  spec("611") {subs "acdefghjklnpqstuvxyz"}
  spec("611") {subs "a"}
  spec("630") {subs "adefghklmnoprstvxyz"}
  spec("630") {subs "a"}
  spec("648") {subs "avxyz"}
  spec("648") {subs "a"}
  spec("650") {subs "abcdevxyz"}
  spec("600") {subs "a"}
  spec("651") {subs "aevxyz"}
  spec("651") {subs "a"}
  spec("653") {subs "a"}
  spec("654") {subs "abevyz"}
  spec("654") {subs "a"}
  spec("655") {subs "abvxyz"}
  spec("655") {subs "a"}
  spec("656") {subs "akvxyz"}
  spec("656") {subs "a"}
  spec("657") {subs "avxyz"}
  spec("657") {subs "a"}
  spec("658") {subs "ab"}
  spec("658") {subs "a"}
  spec("662") {subs "abcdefgh"}
  spec("662") {subs "a"}
end




###############################
#### Genre / geography / dates
###############################


field('genre') do
  spec("655") {sub 'ab'}
end

field('geographic') do
  mapname 'area_map'
  spec("043") {sub 'a'}
end

field('era') do
  spec("600") {sub "y"}
  spec("610") {sub "y"}
  spec("611") {sub "y"}
  spec("630") {sub "y"}
  spec("650") {sub "y"}
  spec("651") {sub "y"}
  spec("654") {sub "y"}
  spec("655") {sub "y"}
  spec("656") {sub "y"}
  spec("657") {sub "y"}
  spec("690") {sub "z"}
  spec("691") {sub "y"}
  spec("692") {sub "z"}
  spec("694") {sub "z"}
  spec("695") {sub "z"}
  spec("696") {sub "z"}
  spec("697") {sub "z"}
  spec("698") {sub "z"}
  spec("699") {sub "z"}
end

field('country_of_pub') do
  mapname 'country_map'
  spec('008') {
    chars 15..17
    char  17
  }
  spec("752") {subs 'ab'}
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
  spec("260") {sub 'b'}
  spec("533") {sub 'c'}
end

field('edition') do
  spec("250") {sub 'a'}
end

custom('language') do
  mapname 'language_map'
  function(:getLanguage) {
    mod mcu
  }
end

############ HATHITRUST STUFF #######

field('ht_availability') do
  mapname 'availability_map_ht'
  spec("974") {sub 'r'}
end

field('ht_availability_intl') do
  mapname 'availability_map_ht_intl'
  spec("974") {sub 'r'}
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

########### HLB #############


custom(['hlb3', 'hlb3Delimited']) do
  function(:getHLBStuff) {
    mod MARC2Solr::Custom::HighLevelBrowse
  }
end










