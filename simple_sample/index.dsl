# The ID comes from the first 001, using the whole string
# Specifying just a tag gives you all its content (for a control field)
# or all the subfields in order, separated by spaces
#
# Without :firstOnly=>true, it would return a value for each 001 found,
# instead of just the first.

field('id') do
  spec(001)
  firstOnly
end

# For variable fields, we specify the tag and one or more subfields to get

field('shorttitle') do
  spec('245ab')
end

# You can also put the subfield definitions in a block; this is useful if you 
# want to generated the list of subfields algorithmically

field('lccn') do
  spec('010') {sub 'a'} # one line is fine if you like
end

# For controlfieds, we support substrings, either by index (17) or
# range (15..17).
#
# Here, we also see taking just a couple subfields of the 752 as a single string.
# The one result will just be the two strings separated by spaces

field('country_code') do
  spec('008') {chars 15..17}
  spec('008') {char 17}
  spec('752ab')
  # spec(752) {sub ['a', 'b']} # could also use array
end

# You can always use a default value, which will be applied
# iff the given specs provide no data

field('genre') do
  default "(No genre)"
  spec('665ab')
end

# We can use a translation map to turn raw data into user-friendly data
# Translation maps are loaded before this file; you need just refer to them
# by name
#
# Entries that don't appear in the map are ignored (but see below for
# :mapMissDefault)
#
# Note that a default value *is not mapped*. It's just returned
# as-is
#
# Also, you can see here that you can use char/chars (as well as sub/subs)
# multiple times withing a spec of the correct type; the result is exactly
# the same as if you'd made separate spec(...) entries.

field('country_of_pub') do
  default '(No country)'
  mapname 'country_map'
  spec('008') {
    chars 15..17
    char  17
  }
  spec('752ab')
end

# And, to round out our possible default options, it's also 
# possible to specify the default values for when (a) there
# stuff in the MARC, but (b) it doesn't match anything in the 
# map file. Not a lot of cases where you'd want to do this,
# but it's here.


field('country_nomapkey') do
  default '(Not specified)'
  mapname 'country_map'
  mapMissDefault '(Unknown country code)'
  spec('008') {chars 15..17}
  spec('008') {char 17}
  spec('752ab')
end

# As an extra bonus, if you specify :mapMissDefault => :passthrough,
# the un-mappable value will just be passed through. If there is a mappable
# value, then whatever is retuned from the map will go through 

field('country_passthrough') do
  default '(Not specified)'
  mapname 'country_map'
  mapMissDefault :passthrough
  spec('008') {chars 15..17}
  spec('008') {char 17}
  spec('752ab')
end

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
# mapMissDefault for a custom function just as you would for a
# regular one.

custom('fullrecord_as_xml') do
  function(:asXML) {       # the name of the function
    mod MARC2Solr::Custom  # the actual module
  }
end

# Custom methods can also take exra arguments

custom('allfields') do
  function(:getAllSearchableFields) {
    mod MARC2Solr::Custom
    args '010', '999' # lower and upper bounds of the tags to get data from
  }
end

# Note that since this is all Ruby, you can pass ruby objects as well; in this case,
# a pattern

custom('oclc') do
  function(:valsByPattern) {
    mod MARC2Solr::Custom
    args '035', # the tag
         'a',   # the subfield code or list of subfield codes
         /(?:oclc|ocolc|ocm|ocn).*?(\d+)/i, # the pattern to match
         1 # the match index. In this case, we have one set of capturing parens ('?:' doesn't capture)
           # and we want what's in it -- the actual digits after the initial nonsense
  }
end

# It's also possible to repeat the same solrField. The result is that all the returned values from
# all the specs are added as values (to what must obviously be a multiValued solr field).
#
# For example, We can add both the full 245 and the 245 minus any non-filing chars to the single
# 'title' field like so (in a not-very-efficient way):

field('title') do
  spec('245') # the whole thing
  spec('245') {
    subs 'ab'  # just the ab
    sub  'a'   # just the a
  }
end

custom('title') do
  function(:fieldWithoutIndexingChars) {
    mod MARC2Solr::Custom
    args '245'
  }
end

# Finally, you can have a single custom function provides values for multiple solr fields
# simultaneously; just enclose them in an array (brackets) and make sure your function returns
# the correct number of values!
#
# Note in this case that a map, default value, etc. make no sense and are unallowed.

custom(['pubDate','pubDateRange']) do
  function(:pubDateAndRange) {
    mod MARC2Solr::Custom
  }
end

