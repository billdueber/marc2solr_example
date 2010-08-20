require 'rubygems'
require '../../marc4j4r/lib/marc4j4r.rb'
require 'set'
require 'json'

curdir = File.dirname(__FILE__)
require "#{curdir}/marc_translation_spec.rb"


Dir.glob("#{curdir}/../jars/*.jar") do |x|
  require x
end



include_class Java::edu.umich.lib.hlb::HLB

class UMichCustom
   
  OCLCPAT = /(?:oclc|ocolc|ocm|ocn).*?(\d+)/i
  SDRPAT  = /^sdr-?(.*)/
  HTSOURCEPAT = /^([a-z0-9]+)\./


  
  def initialize(ss)
    @ss = ss
    @callNumberFieldSpec = nil
    fs = MARC2Solr::FieldSpec.new('hlbCallNumbers')
    fs << MARC2Solr::TagSpec.new('050', 'ab')
    fs << MARC2Solr::TagSpec.new('082', 'a')
    fs << MARC2Solr::TagSpec.new('090', 'ab')
    fs << MARC2Solr::TagSpec.new('099', 'a')
    fs << MARC2Solr::TagSpec.new('086', 'a')
    fs << MARC2Solr::TagSpec.new('086', 'z')
    fs << MARC2Solr::TagSpec.new('852', 'hij')
    @hlbCallNumberFieldSpec = fs
  end
  
  def serialTitleRestFieldsSpec
    return @serialTitleRestFieldsSpec if @serialTitleRestFieldsSpec
    fs = MARC2Solr::FieldSpec.new({'field' => 'serialTitleRest'})

    specstring = "130adfgklmnoprst:210ab:222ab:240adfgklmnprs:246abdenp:247abdenp:730anp:740anp:765st:767st:770st:772st:775st:776st:777st:780st:785st:786st:787st"

    specstring.split(/\s*:\s*/).each do |ss|
      m = /^(\d+)(.*)$/.match(ss)
      fs << MARC2Solr::TagSpec.new(m[1], m[2])
    end
    @serialTitleRestFieldsSpec = fs
    return @serialTitleRestFieldsSpec 
  end
      
  
  
  def getAllSearchableFields(r, lower, upper)
    data = []
    r.each do |field|
      next unless field.tag <= upper and field.tag >= lower
      field.each do |subfield|
        data << subfield.value
      end
    end
    return data.join(' ')
  end
  
  def valsByPattern(r, tags, codes, pattern, matchindex=0, tmap = nil)
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
    
  def getOCLC(r)
    return valsByPattern(r, '035', 'a', OCLCPAT, 1)
  end

  def getSDRNum(r)
    return valsByPattern(r, '035', 'a', SDRPAT)
  end
  
  def htSourcePrefixes(r)
    return valsByPattern(r, '974', 'u', HTSOURCEPAT, 1, @ss.tmaps['ht_namespace_map'])
  end
  
  
  def getLanguage(r)
    rawdata  = []
    map = @ss.tmaps['language_map']
    
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
    
    data = Set.new
    rawdata.each do |rd|
      mapped = map[rd]
      if mapped
        data << mapped 
      else 
#        puts "getLanguage: #{r['001'].value} Invalid language code #{rd}"
      end
    end
    return data.to_a
  end
  
  
  def getDate(r)
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
  
  def getDateRange(date, r)
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
  
  def getDateStuffAsHash(r)
    date = getDate(r)
    return {} unless date
    range = getDateRange(date, r)
    return {'publishDate'=>date, 'publishDateRange' => range}  
  end
  
  
  def getHathiStuffAsHash(r)
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

    #return it
    return h
  end
  
  def getHLBStuffAsHash(r)
    fs = @hlbCallNumberFieldSpec
    callnumbers = fs.marc_values(r)
    
    components = Set.new
    categories = Set.new
    callnumbers.each do |c|
      cats = HLB.categories(c).to_a
      cats.compact!
      cats.each do |cat|
        categories << cat
        cat.split(/\s*\|\s/).each do |comp|
          components << comp
        end
      end
    end
    return {
      'hlb3' => components.to_a,
      'hlb3Delimited' => categories.to_a
    }
  end

  def getTitle(r, codes)
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
  
  def getTitle_sort(r)
    field = r['245']
    return nil unless field
    val = field.sub_values(['a', 'b']).join(' ')
    ind2 = field.indicator2.to_i
    if ind2 > 0 and ind2 < val.length
      val = val[ind2..-1]
    end
    return val.gsub(/\p{Punct}/, ' ').gsub(/\s+/, ' ').strip.downcase
  end
    
  def getSerialTitleRest(r)
    fs = self.serialTitleRestFieldsSpec
    return fs.marc_values(r)
  end
    
    
          
  

end      