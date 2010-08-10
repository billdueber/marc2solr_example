# A KV (Key-Value) map is just a ruby hash with some metadata. Keys are what you expect to come out of the 
# MARC record, and values are what you want in the Solr document.
#
# Note that the values can be either strings or arrays of strings -- you can map a single
# key to multiple values in this way. If you need to map multiple keys to multiple values, 
# you need to use a MultiValueMap. 


{
  # The mapname is what's used to map this structure to a given solr field spec in your
  # index file
  :mapname => 'SimpleKVMap',
  
  # Maptype is either :kv (for this) or :multi (for a multivalue map)
  :maptype => :kv,
  
  # Then the map -- just a hash mapping strings onto either strings
  # or arrays of strings
  
  :map = {
    'ONE' => 'one',
    'TWO' => 'two',
    'THREE' => ['three', 'tres', 'drei']
  }
  
  
  
}