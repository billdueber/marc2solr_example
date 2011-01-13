$KCODE = 'utf8'
require 'rubygems'
require 'json'
require 'marcspec'
require 'jlogger'

module MARC2Solr
  module Custom
    module UMich

      include JLogger::Simple
      

      
      # Create a marc spec for SerialTitleRest
      
      SerialTitleRestFieldsSpec = MARCSpec::SolrFieldSpec.fromHash( 
        {
        :solrField => 'serialTitleRest_internal',
        :specs => [
          ['130', 'adfgklmnoprst'],
          ["210", "ab"],
          ["222", "ab"],
          ["240", "adfgklmnprs"],
          ["246", "abdenp"],
          ["247", "abdenp"],
          ["730", "anp"],
          ["740", "anp"],
          ["765", "st"],
          ["767", "st"],
          ["770", "st"],
          ["772", "st"],
          ["775", "st"],
          ["776", "st"],
          ["777", "st"],
          ["780", "st"],
          ["785", "st"],
          ["786", "st"],
          ["787", "st"]          
        ]
      })
      
      
      # Get the country map
      COPMAP = MARCSpec::Map.fromFile(File.dirname(__FILE__) + '/../translation_maps/country_map.rb')
      
      def self.country_of_pub(doc, r)
        data = []
        return data unless r['008'];
        [r['008'].value[15..17], r['008'].value[17..17]].each do |s|
          data <<  COPMAP[s.gsub(/[^a-z]/, '')] if s
        end
        return data.compact
      end
          
      
      # Get the language(s)
      def self.getLanguage(doc, r)
        rawdata  = []

        # 008
        if r['008'] and r['008'].value[35..37]
          rawdata <<  r['008'].value[35..37].downcase
        end

        # 041, subfields adej
        codes = ['a', 'd', 'e', 'j']
        r.find_by_tag('041').each do |f|
          f.sub_values(codes).each do |v|
            unless v.size.modulo(3) == 0
    #          puts "getLanguage: #{r['001'].value} Invalid data length #{v.size} in 041. #{f.to_s}"
              next
            end
            v.split(//).each_slice(3) do |c|
              rawdata << langcode = c.join('').downcase
            end
          end
        end
        return rawdata
      end
      
      
      # For each title (245), extract the given codes, and then
      # return both that whole string and the the string with the
      # number of charactes indicated by ind2 (the "non-filing chars) removed.
      #
      # Could get more efficiency by passing data from title fields to each other down
      # the line (maybe shave 2-3% off total processing time)
      
      def self.getTitle(doc, r, codes)
        data = []
        fields = r.find_by_tag('245')
        fields.each do |f|
          subvals = f.sub_values(codes)
          subvals.compact!
          if subvals.size > 0
            val = subvals.join(' ')
            data << val
            ind2 = f.indicator2.to_i
            if ind2 > 0 and ind2 < val.length
              data << val[ind2..-1]
            end
          end
        end
        return data
      end
      
      def self.getSerialTitle doc, r, codes
        if doc['format'] and doc['format'].include? 'Serial'
          return self.getTitle(doc, r, codes)
        else
          return []
        end
      end
      
      
      def self.getSerialTitleRest doc, r
        if doc['format'] and doc['format'].include? 'Serial'
          return SerialTitleRestFieldsSpec.marc_values(r)
        else
          return []
        end
      end
      
            
      def self.getTitleSortable doc, r, codes
        f = r['245'] # only the first one!
        unless f
          log.error "No valid 245 title for record {}", r['001'].value
          return nil
        end
        subvals = f.sub_values(codes)
        subvals.compact!
        if subvals.size > 0
          val = subvals.join(' ')
          ind2 = f.indicator2.to_i
          if ind2 > 0 and ind2 < val.length
            val = val[ind2..-1]
          end
        else
          log.error "No valid 245 title for record {}", r['001'].value
	  return nil
        end
        return val.gsub(/[^\p{L}\p{N}]/, ' ').gsub(/\s+/, ' ').strip.downcase 
      end

      def self.getDateRange(date, r)
        if date < "1500"
          return "Pre-1500"
        end

        case date.to_i
        when 1500..1800 then 
          century = date[0..1]
          return century + '00-' + century + '99'
        when 1801..2100 then
          decade = date[0..2]
          return decade + "0-" + decade + "9";
        else
          log.debug "getDateRange: {} invalid date {}", r['001'].value, date
        end
      end
      
      def self.publishDateRange(doc,r)
        pubdate = doc['publishDate']
        return [] unless pubdate and pubdate.size > 0
        return self.getDateRange pubdate[0], r
      end
      
      
      
      # Create a sortable string based on the digit strings present in an
      # enumcron string

      def self.enumcronSortString str
        rv = '0'
        str.scan(/\d+/).each do |nums|
          rv += nums.size.to_s + nums
        end
        return rv
      end
      
      def self.enumcronSort a,b
        matcha = /(\d{4})/.match a['enumcron']
        matchb = /(\d{4})/.match b['enumcron']
        if (matcha and matchb)
          return matcha[1] <=> matchb[1] unless (matcha[1] == matchb[1])
        end
        return a[:sortstring] <=> b[:sortstring]
      end        


      # We'll take an easy way out; add a :sortstring entry to each hash, and then 
      # delete them later.
      #
      # @param [Array] info An array of hashes, each of which has an 'enumcron' entry
      # @return [Arrray] the array sorted by our best guess of enumcron order

      def self.sortHathiJSON arr
        # Only one? Never mind
        return arr if arr.size == 1
        
        # First, add the _sortstring entries
        arr.each do |h|
          if h.has_key? 'enumcron'
            h[:sortstring] = enumcronSortString(h['enumcron'])
          else
            h[:sortstring] = '0'
          end
        end
        

        arr.sort! {|a,b| self.enumcronSort(a, b)}
        arr.each do |h|
          h.delete(:sortstring)
        end
        return arr
      end
      
      # Get all the hathi stuff at once
      def self.getHathiStuff doc, r
        defaultDate = '00000000'
        fields = r.find_by_tag('974')
        return nil unless fields;
        
        h = {}
        ids = []
        udates = []
        display = []
        jsonarr = []
        gotEnumcron = false
        
        fields.each do |f|
          id = f['u']
          udate = f['d'] || defaultDate
          
          ids << id
          udates << udate
          display << [id, udate, f['z']].join("|")

          # Build up the json
          info = {
            'htid' => id,
            'ingest' => udate,
          }
          if f['z']
            info['enumcron'] = f['z'] 
            gotEnumcron = true
          end
          info['rights'] = f['r'] if f['r']
          jsonarr << info
        end
        
        # Sort the json in enumcron order if need be
        jsonarr = sortHathiJSON(jsonarr) if gotEnumcron
               
        # Make sure we're all uniq
        ids.uniq!
        udates.uniq!

        return [display, udates, ids, jsonarr.to_json]
      end
      
    
      # Figure out if the only holdings on an item are HathiTrust
      # searchonly.
      
      def self.isJustHathiSearchOnly doc, r, prevfield

        # First: are there even HT items?
        
        unless doc['ht_id'] and doc['ht_id'].size > 0
          return false;
        end
                   
        # Do we have fulltext HT holdings in the given field (ht_availability or ht_availability_intl)
        if (doc[prevfield].include? 'Full text')
          return 'false'
        end
        
        # Do we have umich holdings other than SDR?
        
        r.cachespot['hasUMICH'] = false
        r.find_by_tag('852').each do |f|
          if f['b'] != 'SDR'
            r.cachespot['hasUMICH'] = true
          end
        end
        
        return 'false' if r.cachespot['hasUMICH']
        
        # Otherwise...
        
        return 'true'
      end
      
      
    end
  end
end