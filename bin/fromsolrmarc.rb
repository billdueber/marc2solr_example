require 'rubygems'
require 'logger'
require 'marc4j4r'
require 'pp'
require 'marcspec'
require 'fileutils'

$LOG = Logger.new(STDOUT)
$LOG.level = Logger::WARN

# We'll take two arguments: a .properties index file, and a new directory 
propfile = ARGV[0]
newdir = ARGV[1]


# First, try to create the new directory structure
libdir = File.dirname(__FILE__).split('/')[0..-2]
if libdir.size == 0
  libdir = 'lib'
else
  libdir = libdir.join('/') + '/lib'
end

Dir.glob("#{libdir}/*") do |f|
  require f
end

begin
  FileUtils.mkdir_p "#{newdir}/translation_maps"
  FileUtils.mkdir "#{newdir}/lib"
  Dir.glob("#{libdir}/*").each do |f|
    FileUtils.cp f, "#{newdir}/lib/"
  end
rescue Exception => e
  $LOG.debug e
end

# Fix the log so it points to the logfile
$LOG = Logger.new("#{newdir}/fromsolrmarc.log")
$LOG.level = Logger::WARN

unless File.exist? propfile
  $LOG.error "Can't find file '#{propfile}"
  exit
end
unless File.readable? propfile
  $LOG.error "File '#{propfile}' exists but cannot be read"
  exit
end


propfiledir = File.dirname(propfile)
trmapdir = propfiledir + '/translation_maps'
# newpropfile = File.basename(propfile, '.properties') + '.rb'
newpropfile = 'index.rb'





ss  = MARCSpec::SpecSet.new
Dir.glob(trmapdir + '/*.properties').each do |f|
  File.open(f) do |fh|
    fh.each_line do |line|
      next if line =~ /^\s*#/
      next unless line =~ /\S/
      if line =~ /^\s*pattern/
        $LOG.debug "Adding '#{File.basename f}' as a pattern map"
        ss.add_map MARCSpec::MultiValueMap.from_solrmarc_file(f)
        break
      else
        $LOG.debug "Adding '#{File.basename f}' as a key/value map"
        ss.add_map MARCSpec::KVMap.from_solrmarc_file(f)
        break
      end
    end
  end
end



WHOLE = /^(\d{3})$/
CTRL = /^(\d{3})\[(.+?)\]/
VAR  = /^(\d{3})(.+)/

File.open(propfile) do |fh|
  fh.each_line do |line|
    next unless line =~ /\S/
    line.strip!
    
    # Leave comments alone
    if line =~ /^#/
      puts line
      next
    end
    
    fieldname,spec = line.split(/\s*=\s*/)
    
    # Deal with built-in functions if we can
    if spec == 'FullRecordAsXML'
      csf = MARCSpec::CustomSolrSpec.new(:solrField=>fieldname,
                                          :module => MARC2Solr::Custom,
                                          :functionSymbol => :asXML)
      ss << csf
      next
    end

    if spec == 'FullRecordAsMARC'
      csf = MARCSpec::CustomSolrSpec.new(:solrField=>fieldname,
                                          :module => MARC2Solr::Custom,
                                          :functionSymbol => :asMARC)
      ss << csf
      next
    end
    
    if spec == 'DateOfPublication'
      csf = MARCSpec::CustomSolrSpec.new(:solrField=>fieldname,
                                          :module => MARC2Solr::Custom,
                                          :functionSymbol => :getDate)
      ss << csf
      next
    end
      
    
    if spec =~ /^custom,\s*getAllSearchableFields\((\d+),\s*(\d+)\)/
      low = $1
      high = $2
      csf = MARCSpec::CustomSolrSpec.new(:solrField=>fieldname,
                                         :module => MARC2Solr::Custom,
                                         :functionSymbol => :getAllSearchableFields,
                                         :functionArgs => [low, high])
      ss << csf
      next
    end
    
    # Log and ignore custom fields
    if spec =~ /^custom/
      $LOG.warn "Skipping custom line #{line}"
      next
    end
    
      
      
    
    
    sfs = MARCSpec::SolrFieldSpec.new(:solrField => fieldname)
    
    marcfields, *specials = spec.split(/\s*,\s*/)
    
    marcfields.split(/\s*:\s*/).each do |ms|
      if WHOLE.match ms
        tag = $1
        if MARC4J4R::ControlField.control_tag? tag
          sfs << MARCSpec::ControlFieldSpec.new(tag)
        else
          sfs << MARCSpec::VariableFieldSpec.new(tag)
        end
        next

      elsif CTRL.match ms
        tag = $1
        range = $2
        first,last = range.split('-')
        last ||= first
        first = first.to_i
        last = last.to_i
        sfs << MARCSpec::ControlFieldSpec.new(tag, first..last)
        next
      elsif VAR.match ms
        tag = $1
        sfcodes = $2.split(//)
        sfs << MARCSpec::VariableFieldSpec.new(tag, sfcodes)
      else
        $LOG.warn "Didn't recognize line '#{line}'"
      end
    end # marcfields.split
    
    # Add in the specials
    specials.each do |special|
      case special
      when 'first'
        sfs.first = true
      else
        origmapname = special
        mapname =  special.gsub(/.properties/, '')
        sfs.map = ss.map(mapname)
        if mapname.nil? 
          $LOG.warn "Map problem in #{fieldname}: Unrecognized map name '#{mapname}' (specified as '#{origmapname}')"
        end
        if mapname =~ /\((.*)\)/
          $LOG.warn "Map problem in #{fieldname}: Translator doesn't deal at all with property key prefixes ('#{$1}' in this case). Please break them into separate map files or complain to Bill."
        end
      end
    end
    ss << sfs if sfs.marcfieldspecs.size > 0
  end
end

# Spit it out

# First, put the maps in newdir/translation_maps

ss.tmaps.each do |name, map|
  filename = name + '.rb'
  $LOG.debug "Writing out translation map #{filename}"
  File.open("#{newdir}/translation_maps/#{filename}", 'w') do |f|
    f.puts map.asPPString
  end
end

# Now the solrspecs
File.open("#{newdir}/#{newpropfile}", 'w') do |f|
  $LOG.debug "Writing out spec file #{newpropfile}"
  f.puts '['
  ss.solrfieldspecs.each do |sfs|
    f.puts sfs.asPPString + ','
  end
  f.puts ']'
end

