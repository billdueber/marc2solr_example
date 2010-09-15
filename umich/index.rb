[

################################
###### CORE FIELDS #############
################################

{
 :solrField=> "id",
 :firstOnly => true,
 :specs => [
  ["001"],
 ]
},
{
 :solrField=> "fullrecord",
 :module => MARC2Solr::Custom,
 :functionSymbol => :asXML,
 :functionArgs => []
},
{
 :solrField=> "allfields",
 :module => MARC2Solr::Custom,
 :functionSymbol => :getAllSearchableFields,
 :functionArgs => ["100", "999"]
},

###### Local Data ######
{
 :solrField=> "format",
 :mapname => "format_map_umich",
 :specs => [
  ["970", "a"],
 ]
},
{
 :solrField=> "availability",
 :mapname => "availability_map_umich",
 :specs => [
  ["973", "b"],
 ]
},

{
 :solrField=> "cat_date",
 :specs => [
  ["972", "c"],
 ]
},


#### INSTITUTION / LOCATION ####
{
 :solrField=> "institution",
 :mapname => "institution_map",
 :specs => [
  ["971", "a"],
 ]
},
{
 :solrField=> "building",
 :mapname => "library_map",
 :specs => [
  ["852", "bc"],
  ["971", "a"],
 ]
},
{
 :solrField=> "location",
 :mapname => "location_map",
 :noMapKeyDefault => :passthrough,
 :specs => [
  ["971", "a"],
  ["852", "b"],
  ["852", "bc"],
 ]
},

################################
######## IDENTIFIERS ###########
################################

{
 :solrField=> "lccn",
 :specs => [
  ["010", "a"],
 ]
},
{
 :solrField=> "rptnum",
 :specs => [
  ["088", "a"],
 ]
},
{
  :solrField => 'oclc',
  :module => MARC2Solr::Custom,
  :functionSymbol => :valsByPattern,
  :functionArgs => ['035', 'a', /(?:oclc|ocolc|ocm|ocn).*?(\d+)/i, 1]
},

{
  :solrField => 'sdrnum',
  :module => MARC2Solr::Custom,
  :functionSymbol => :valsByPattern,
  :functionArgs => ['035', 'a', /^sdr-?(.*)/, 0]
},

{
 :solrField=> "isbn",
 :specs => [
  ["020", "a"],
  ["020", "z"],
 ]
},
{
 :solrField=> "issn",
 :specs => [
  ["022", "a"],
  ["022", "l"],
  ["022", "m"],
  ["022", "y"],
  ["022", "z"],
  ["247", "x"],
 ]
},
{
 :solrField=> "isn_related",
 :specs => [
  ["400", "x"],
  ["410", "x"],
  ["411", "x"],
  ["440", "x"],
  ["490", "x"],
  ["500", "x"],
  ["510", "x"],
  ["534", "xz"],
  ["556", "z"],
  ["581", "z"],
  ["700", "x"],
  ["710", "x"],
  ["711", "x"],
  ["730", "x"],
  ["760", "x"],
  ["762", "x"],
  ["765", "xz"],
  ["767", "xz"],
  ["770", "xz"],
  ["772", "x"],
  ["773", "xz"],
  ["774", "xz"],
  ["775", "xz"],
  ["776", "xz"],
  ["777", "x"],
  ["780", "xz"],
  ["785", "xz"],
  ["786", "xz"],
  ["787", "xz"]
 ]
},
{
 :solrField=> "callnumber",
 :specs => [
  ["852", "hij"],
 ]
},
{
 :solrField=> "sudoc",
 :specs => [
  ["086", "a"],
  ["086", "z"],
 ]
},


################################
######### AUTHOR FIELDS ########
################################

{
 :solrField=> "author",
 :specs => [
  ["100", "abcd"],
  ["110", "abcd"],
  ["111", "abc"],
 ]
},
{
 :solrField=> "author2",
 :specs => [
  ["110", "ab"],
  ["111", "ab"],
  ["700", "abcd"],
  ["710", "ab"],
  ["711", "ab"],
 ]
},
{
 :solrField=> "author_top",
 :specs => [
  ["100", "abcdefgjklnpqtu0"],
  ["110", "abcdefgklnptu04"],
  ["111", "acdefgjklnpqtu04"],
  ["700", "abcdejqux034"],
  ["710", "abcdeux034"],
  ["711", "acdegjnqux034"],
  ["720", "a"],
  ["765", "a"],
  ["767", "a"],
  ["770", "a"],
  ["772", "a"],
  ["774", "a"],
  ["775", "a"],
  ["776", "a"],
  ["777", "a"],
  ["780", "a"],
  ["785", "a"],
  ["786", "a"],
  ["787", "a"],
  ["245", "c"],
 ]
},
{
 :solrField=> "author_rest",
 :specs => [
  ["505", "r"],
 ]
},


################################
########## TITLES ##############
################################
{
  :solrField => 'title',
  :module => MARC2Solr::Custom::UMich,
  :functionSymbol => :getTitle,
  :functionArgs => ['abdefghknp'.split(//)]
},
{
  :solrField => 'title_ab',
  :module => MARC2Solr::Custom::UMich,
  :functionSymbol => :getTitle,
  :functionArgs => ['akb'.split(//)]
},

{
  :solrField => 'title_a',
  :module => MARC2Solr::Custom::UMich,
  :functionSymbol => :getTitle,
  :functionArgs => ['ak'.split(//)]
},


# titleSort is the same as title_ab, but with the transform in 
# getTitleSortable applied

{
  :solrField => 'titleSort',
  :module => MARC2Solr::Custom::UMich,
  :functionSymbol => :getTitleSortable,
  :functionArgs => [['a', 'b']]
},


{
 :solrField=> "title_top",
 :specs => [
  ["240", "adfghklmnoprs0"],
  ["245", "abfghknps"],
  ["111", "acdefgjklnpqtu04"],
  ["130", "adfghklmnoprst0"],
 ]
},
{
 :solrField=> "title_rest",
 :specs => [
  ["210", "ab"],
  ["222", "ab"],
  ["242", "abhnpy"],
  ["243", "adfghklmnoprs"],
  ["246", "abdenp"],
  ["247", "abdenp"],
  ["700", "fghjklmnoprstx03"],
  ["710", "fghklmnoprstx03"],
  ["711", "acdefghjklnpqstux034"],
  ["730", "adfghklmnoprstx03"],
  ["740", "ahnp"],
  ["765", "st"],
  ["767", "st"],
  ["770", "st"],
  ["772", "st"],
  ["773", "st"],
  ["775", "st"],
  ["776", "st"],
  ["777", "st"],
  ["780", "st"],
  ["785", "st"],
  ["786", "st"],
  ["787", "st"],
  ["830", "adfghklmnoprstv"],
  ["440", "anpvx"],
  ["490", "avx"],
  ["505", "t"],
 ]
},
{
 :solrField=> "series",
 :specs => [
  ["440", "ap"],
  ["800", "abcdfpqt"],
  ["830", "ap"],
 ]
},
{
 :solrField=> "series2",
 :specs => [
  ["490", "a"],
 ]
},


# Serial titles count on the format alreayd being set and having the string 'Serial' in it.
{
  :solrField => 'serialTitle',
  :module => MARC2Solr::Custom::UMich,
  :functionSymbol => :getSerialTitle,
  :functionArgs => ['abdefghknp'.split(//)]
},

{
  :solrField => 'serialTitle_ab',
  :module => MARC2Solr::Custom::UMich,
  :functionSymbol => :getSerialTitle,
  :functionArgs => ['ab'.split(//)]
},

{
  :solrField => 'serialTitle_a',
  :module => MARC2Solr::Custom::UMich,
  :functionSymbol => :getSerialTitle,
  :functionArgs => [['a']]
},

{
  :solrField => 'serialTitle_rest',
  :module => MARC2Solr::Custom::UMich,
  :functionSymbol => :getSerialTitleRest
},



################################
######## SUBJECT / TOPIC  ######
################################

{
 :solrField=> "topic",
 :specs => [
  ["600", "abcdefghjklmnopqrstuvxyz"],
  ["600", "a"],
  ["610", "abcdefghklmnoprstuvxyz"],
  ["610", "a"],
  ["611", "acdefghjklnpqstuvxyz"],
  ["611", "a"],
  ["630", "adefghklmnoprstvxyz"],
  ["630", "a"],
  ["648", "avxyz"],
  ["648", "a"],
  ["650", "abcdevxyz"],
  ["600", "a"],
  ["651", "aevxyz"],
  ["651", "a"],
  ["653", "a"],
  ["654", "abevyz"],
  ["654", "a"],
  ["655", "abvxyz"],
  ["655", "a"],
  ["656", "akvxyz"],
  ["656", "a"],
  ["657", "avxyz"],
  ["657", "a"],
  ["658", "ab"],
  ["658", "a"],
  ["662", "abcdefgh"],
  ["662", "a"],
 ]
},

###############################
#### Genre / geography / dates
###############################

{
 :solrField=> "genre",
 :specs => [
  ["655", "ab"],
 ]
},
{
 :solrField=> "geographic",
 :mapname => "area_map",
 :specs => [
  ["043", "a"],
 ]
},

{
 :solrField=> "era",
 :specs => [
  ["600", "y"],
  ["610", "y"],
  ["611", "y"],
  ["630", "y"],
  ["650", "y"],
  ["651", "y"],
  ["654", "y"],
  ["655", "y"],
  ["656", "y"],
  ["657", "y"],
  ["690", "z"],
  ["691", "y"],
  ["692", "z"],
  ["694", "z"],
  ["695", "z"],
  ["696", "z"],
  ["697", "z"],
  ["698", "z"],
  ["699", "z"],
 ]
},
{
 :solrField=> "country_of_pub",
 :mapname => "country_map",
 :specs => [
  ["008", 15..17],
  ["008", 17..17],
  ["752", "ab"],
 ]
},
{
 :solrField=> "publishDate",
 :module => MARC2Solr::Custom,
 :functionSymbol => :getDate,
 :functionArgs => []
},
{
 :solrField=> "publishDateRange",
 :module => MARC2Solr::Custom::UMich,
 :functionSymbol => :publishDateRage,
},


# W, [2010-08-13T11:35:49.631000 #14227]  WARN -- : Skipping custom line publishDateRange = custom, getPublishDateRange


################################
########### MISC ###############
################################

{
 :solrField=> "publisher",
 :specs => [
  ["260", "b"],
  ["533", "c"],
 ]
},
{
 :solrField=> "edition",
 :specs => [
  ["250", "a"],
 ]
},

{
  :solrField => 'language',
  :mapname => 'language_map',
  :module => MARC2Solr::Custom::UMich,
  :functionSymbol => :getLanguage
},



############ HATHITRUST STUFF #######
{
 :solrField=> "ht_availability",
 :mapname => "availability_map_ht",
 :specs => [
  ["974", "r"],
 ]
},

{
 :solrField=> "ht_availability_intl",
 :mapname => "availability_map_ht_intl",
 :specs => [
  ["974", "r"],
 ]
},

{
  :solrField => 'htsource',
  :module => MARC2Solr::Custom,
  :functionSymbol => :valsByPattern,
  :functionArgs => ['974', 'u', /^([a-z0-9]+)\./, 1],
  :mapname => 'ht_namespace_map'
},

# Get teh rest of the HT data in one fell swoop
{
  :solrField => ['ht_id_display', 'ht_id_update', 'ht_id', 'ht_json'],
  :module => MARC2Solr::Custom::UMich,
  :functionSymbol => :getHathiStuff
},

########### HLB #############
{
  :solrField => ['hlb3', 'hlb3Delimited'],
  :module => MARC2Solr::Custom::HighLevelBrowse,
  :functionSymbol => :getHLBStuff
},


]
