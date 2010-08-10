module MARC2Solr
  module Custom
    
    # Custom routines are defined as module methods that take two arguments: a MARC4J4R record,
    # and an (optional) array of other arguments passed in. 
    #
    # They don't need to live in the MARC2Solr::Custom namespace, but it's not a bad idea to use, e.g.,
    # MARC2Solr::Custom::UMich, or maybe MARC2Solr::Custom::DateStuff
    #
    # You can return multiple values in an array
    
    # The simplest possible example; just call a method on the underlying MARC4J4R record
    # Note that even though we don't use the arguments, the method signature has to 
    # support it
    #
    # @param [MARC4J4R::Record] r A MARC4J4R record
    # @return [String] The XML representation of the record

    def self.asXML r, args=nil #Remember, module fucntion! Define with "def self.methodName"
      return r.to_xml
    end
    
    # Another for marc binary
    def self.asMARC r, args=nil
      return r.to_marc
    end
    
    # Here we get all the text from fields between (inclusive) the two tag strings in args;
    # 
    # @param [MARC4J4R::Record] r A MARC4J4R record
    # @param [Array<String>] args An array of two strings, the lowest tag you want to include, and
    # the highest
    # @return [String] A single single string with all the text from included fields
    def self.getAllSearchableFields(r, lower, upper)
      data = []
      r.each do |field|
        next unless field.tag <= upper and field.tag >= lower
        data << field.value
      end
      return data.join(' ')
    end
    
    # How about one to sort out, say, the 035s? We'll make a generic routine
    # that looks for specified values in specified subfields of variable
    # fields, and then make sure they match before returning them.
    #
    # See the use of this in the simple_sample/simple_index.rb file for field 'oclc'
    #
    # @param [MARC4J4R::Record] r A MARC4J4R record
    # @param [String] tag A tag string (e.g., '035')
    # @param [String, Array<String>] codes A subfield code ('a') or array of them (['a', 'c'])
    # @param [Regexp] pattern A pattern that must match for the value to be included
    # @param [Fixnum] matchindex The number of the substring captured by parens in the pattern to return
    # The default is zero, which means "the whole string"
    
    def self.valsByPattern(r, tag, codes, pattern, matchindex=0)
      data = []
      r.find_by_tag(tag).each do |f|
        f.sub_values(codes).each do |v|
          if m = pattern.match(v)
            data << m[matchindex]
          end
        end
      end
      data.uniq!
      return data
    end
  end # close the inner module Custom
end # close the module MARC2Solr
    