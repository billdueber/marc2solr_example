# Simple Spec, a simple marc2solr specification file to show how we do things
#
# I'm very open to alternative syntaxes for this -- I know this is a little verbose at the moment.

# The whole file is valid ruby code; an array of specificaiton hashes. 
# So, we stat with an open bracket to start the array

[

# The ID comes from the first 001, using the whole string
# Specifying just a tag gives you all its content (for a control field)
# or all the subfields in order, separated by spaces
#
# Without :firstOnly=>true, it would return a value for each 001 found,
# instead of just the first.

{:solrField=>"id", 
 :firstOnly=>true, 
 :specs=>[
   ["001"]
 ]
}, # don't forget the comma! This is a list



# For variable fields, we have placeholders for required values for ind1 and
# ind2 (not supported quite yet) and one or more subfields to get

{
  :solrField => "shorttitle",
  :specs=>[
    ["245", '*', '*', 'ab']
  ]
},


{
  :solrField => "lccn",
  :specs=>[
    ["010", '*', '*', 'a']
  ]
},

# For controlfieds, we support substrings, either by index (17) or
# range (15..17).
#
# Here, we also see taking just a couple subfields of the 752; they'll appear
# separated by spaces

{
 :solrField=> "country_code",
 :specs => [
  ["008", 15..17],
  ["008", 17],
  ["752", "*", "*", "ab"],
#  ["752", "*", "*", ['a', 'b']], # Could have also done subfields as an array
 ]
},

# You can always use a default value, which will be applied
# iff the given specs provide no data

{
 :solrField=> "genre",
 :default => "(No genre)",
 :specs => [
  ["655", "*", "*", "ab"],
 ]
},

# We can use a translation map to turn raw data into user-friendly data
# Translation maps are loaded before this file; you need just refer to them
# by name
#
# Entries that don't appear in the map are ignored (but see below for
# :noMapKeyDefault)
#
# Note that a default value *is not mapped*. It's just returned
# as-is

{
 :solrField=> "country_of_pub",
 :mapname => "country_map",
 :default => "(No country)",
 :specs => [
  ["008", 15..17],
  ["008", 17..17],
  ["752", "*", "*", "ab"],
 ]
},

# And, to round out our possible default options, it's also 
# possible to specify the default values for when (a) there
# stuff in the MARC, but (b) it doesn't match anything in the 
# map file. Not a lot of cases where you'd want to do this,
# but it's here.

{
  :solrField => "country_nomapkey",
  :mapname => 'country_map',
  :default => "(Not specified)",
  :noMapKeyDefault => "(Unknown country code)",
  :specs => [
    ["008", 15..17],
    ["008", 17..17],
    ["752", "*", "*", "ab"],
  ]
},

# As an extra bonus, if you specify :noMapKeyDefault => :passthrough,
# the un-mappable value will just be passed through. 

{
  :solrField => "country_passthrough",
  :mapname => 'country_map',
  :default => "(Not specified)",
  :noMapKeyDefault => :passthrough,
  :specs => [
    ["008", 15..17],
    ["008", 17..17],
    ["752", "*", "*", "ab"],
  ]
},

# And, finally, you can create custom functions.
#
# Every ruby or .jar in the 'lib' directory next to your spec file
# will be loaded at startup, so all those functions are 
# available to you.
#
# See the file marc2solr_custom.rb in the simple_spec/lib
# directory for some very simple examples
#
# Note that you can, if you'd like, use a map, default value, and
# noMapKeyDefault for a custom function just as you would for a
# regular one.

# (commented out so test output is more readable)
# {
#   :solrField => "fullrecord_as_xml",
#   :module => MARC2Solr::Custom, # the actual constant, NOT A STRING
#   :functionSymbol => :asXML
# },

# Custom methods can also take exra arguments
# (commented out so test output is more readable)
# {
#   :solrField => "allfields",
#   :module => MARC2Solr::Custom,
#   :functionSymbol => :getAllSearchableFields,
#   :methodArgs => ['010', '999'], # lower and upper bounds of the tags to get data from
# },  

# Note that since this is all Ruby, you can pass ruby objects as well; in this case,
# a pattern
{
  :solrField => "oclc",
  :module => MARC2Solr::Custom,
  :functionSymbol => :valsByPattern,
  :methodArgs => [
    '035', # the tag
    'a',   # the subfield code or list of subfield codes
    /(?:oclc|ocolc|ocm|ocn).*?(\d+)/i, # the pattern to match
    1 # the match index. In this case, we have one set of capturing parens ('?:' doesn't capture)
      # and we want what's in it -- the actual digits after the initial nonsense
  ]
},  

# It's also possible to repeat the same solrField. The result is that all the returned values from
# all the specs are added as values (to what must obviously be a multiValued solr field).
#
# For example, We can add both the full 245 and the 245 minus any non-filing chars to the single
# 'title' field like so:

{
  :solrField => 'title',
  :specs => [
    ['245', '*', '*'] # Just get the whole thing
  ] 
},

{
  :solrField => 'title',
  :module => MARC2Solr::Custom,
  :functionSymbol => :fieldWithoutIndexingChars, # and now do it again, minus the non-filing chars
  :methodArgs => ['245']
},

# Finally, you can have a single custom function provides values for multiple solr fields
# simultaneously. 
#
# Note in this case that a map, default value, etc. make no sense and are unallowed.

{
  :solrField => ['pubDate', 'pubDateRange'],
  :module => MARC2Solr::Custom,
  :functionSymbol => :pubDateAndRange
}


  
] # don't forget to close off the array!