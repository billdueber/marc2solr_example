require 'rubygems'
require 'json'


module MARC2Solr
  module Custom
    module UMich
      
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
      
      def self.getTitleSortable doc, r, codes
        data = nil
        f = r['245'] # only the first one!
        subvals = f.sub_values(codes)
        subvals.compact!
        if subvals.size > 0
          val = subvals.join(' ')
          ind2 = f.indicator2.to_i
          if ind2 > 0 and ind2 < val.length
            val = val[ind2..-1]
          end
        end
        return val.gsub(/\p{Punct}/, ' ').gsub(/\s+/, ' ').strip.downcase 
      end

      def self.getDateRange(date, r)
        if date < "1500"
          return "Pre-1500"
        end

        case date.to_i
        when 1500..1800 then 
          century = date[0..1]
          return century + '00' + century + '99'
        when 1801..2100 then
          decade = date[0..2]
          return decade + "0-" + decade + "9";
        else
    #      puts "getDateRange: #{r['001'].value} invalid date #{date}"
        end
      end
      
      def self.publishDateRage(doc,r)
        pubdate = doc['publishDate']
        return [] unless pubdate and pubdate.size > 0
        return self.getDateRange pubdate[0], r
      end
      
      
      # Get all the hathi stuff at once
      def self.getHathiStuff doc, r
        defaultDate = '00000000'
        fields = r.find_by_tag('974')
        h = {}
        h['ht_id_display'] = []

        ids = fields.map {|f| f.sub_values('u')}
        ids.flatten!
        ids.compact!
        h['ht_id'] = ids

        # The update dates are in the d
        udates = fields.map {|f| f.sub_values('d')}
        udates.flatten!
        udates.compact!
        updatedates = udates
        if (updatedates.size > 0)
          h['ht_id_update'] = updatedates
        else
          h['ht_id_update'] = defaultDate
        end

        # Join the u,d and z to get the diplay for each. 
        fields.each do |f|
          h['ht_id_display'] << [f['u'], f['d'] || defaultDate, f['z']].join("|")
        end

        # Now make the json 
        # 
        jsonarr = []
        fields.each do |f|
          info  = {
            'htid' => f['u'],
            'ingest' => f['d'] || defaultDate       
          }
          info['enumcron'] = f['z'] if f['z']
          info['rights'] = f['r'] if f['r']
          jsonarr << info
        end

        h['ht_json'] = jsonarr.to_json

        return [h['ht_id_display'], h['ht_id_update'], h['ht_id'], h['ht_json']]
      end
      
      
      
    end
  end
end