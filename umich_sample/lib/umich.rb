require 'rubygems'


module MARC2Solr
  module UMich
   
    oclcpat = /(?:oclc|ocolc|ocm|ocn).*?(\d+)/i

  
    def self.getAllSearchableFields(r, lower, upper)
      data = []
      r.each do |field|
        next unless field.tag <= upper and field.tag >= lower
        field.each do |subfield|
          data << subfield.value
        end
      end
      return data.join(' ')
    end
  
    def self.valsByPattern(r, tags, codes, pattern, matchindex=0, tmap = nil)
      data = []
      r.find_by_tag(tags).each do |f|
        f.sub_values(codes).each do |v|
          if m = pattern.match(v)
            if tmap
              mapped = tmap[m[matchindex]]
              data << mapped if mapped
            else
              data << m[matchindex]
            end
          end
        end
      end
  #    pp data
      data.uniq!
      return data
    end
    
    def self.getOCLC(r)
      return self.valsByPattern(r, '035', 'a', OCLCPAT, 1)
    end

  
    def self.getLanguage(r, map)
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
    
      data = []
      rawdata.each do |rd|
        mapped = map[rd]
        if mapped
          data << mapped 
        else 
  #        puts "getLanguage: #{r['001'].value} Invalid language code #{rd}"
        end
      end
      return data.uniq
    end
  
  
    def self.getDate(r)
      data = []
      begin
        ohoh8 = r['008'].value
        date1 = ohoh8[7..10].downcase
        datetype = ohoh8[6..6]
        if ['n','u','b'].include? datetype
          date1 = ""
        else 
          date1 = date1.gsub('u', '0').gsub('|', ' ')
          date1 = '' if date1 == '0000'
        end
    
        if m = /^\d\d\d\d$/.match(date1)
          return m[0]
        end
      rescue
       # do nothing ... go on to the 260c
      end

    
      # No good? Fall back on the 260c
      begin
        d =  r['260']['c']
        if m = /\d\d\d\d/.match(d)
          return m[0]
        end
      rescue
  #      puts "getDate: #{r['001'].value} has no date"
        return nil
      end
    end
  


    def self.getTitle(r, codes)
      data = []
      fields = r.find_by_tag('245')
      fields.each do |f|
        subvals = f.sub_values(codes)
        subvals.compact!
        if subvals.size
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
  
    def self.getTitle_sort(r)
      field = r['245']
      return nil unless field
      val = field.sub_values(['a', 'b']).join(' ')
      ind2 = field.indicator2.to_i
      if ind2 > 0 and ind2 < val.length
        val = val[ind2..-1]
      end
      return val.gsub(/\p{Punct}/, ' ').gsub(/\s+/, ' ').strip.downcase
    end
  end
end      