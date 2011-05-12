require 'java'
require 'je-4.10.jar'
java_import 'com.sleepycat.je.Environment'
java_import 'com.sleepycat.je.EnvironmentConfig'
java_import 'com.sleepycat.je.Cursor'
java_import 'com.sleepycat.je.Database'
java_import 'com.sleepycat.je.DatabaseConfig'
java_import 'com.sleepycat.je.DatabaseEntry'
java_import 'com.sleepycat.je.Environment'
java_import 'com.sleepycat.je.EnvironmentConfig'
java_import 'com.sleepycat.je.OperationStatus'
java_import 'com.sleepycat.je.Transaction'
java_import 'com.sleepycat.bind.tuple.IntegerBinding'
java_import 'com.sleepycat.bind.tuple.StringBinding'


module LCSHDB

  LINEPAT = /<[^>]+\/sh(.+?)\#concept>\s+<.+?\#(.+)>\s*"(.+)"/
  LABELPAT = /Label$/

  class LCSHDB
    def initialize dir="/l/solr-vufind/apps/marc2solr_example/umich/lcshdb"
      @envConf = EnvironmentConfig.new()
      @envConf.setAllowCreate(true)
      @dbdir = java.io.File.new(dir)
      @env = Environment.new(@dbdir, @envConf);

      @dbConf = DatabaseConfig.new()
      @dbConf.setAllowCreate(true)
      @db = @env.openDatabase(nil, "lcshids", @dbConf)

      @key = DatabaseEntry.new()
      @data = DatabaseEntry.new()
    end
  
    def put label, id
      label.gsub! /\p{P}+$/u, ''
      label.strip!
      IntegerBinding.intToEntry(id.to_i, @data)
      StringBinding.stringToEntry(label, @key)
      status = @db.put(nil, @key, @data)
      if (status != OperationStatus::SUCCESS) 
        throw RuntimeError.new(status)
      end
    end
  
    def get label
      label.gsub! /\p{P}+$/u, ''
      StringBinding.stringToEntry(label, @key)
      status = @db.get(nil, @key, @data, nil)
      return nil if status == OperationStatus::NOTFOUND
      if (status != OperationStatus::SUCCESS) 
        throw RuntimeError.new(status)
      end
      return IntegerBinding.entryToInt(@data)
    end
    
    def fill filename
      File.open(filename) do |f|
        f.each_line do |l|
          fixed = l.gsub(/\\u([A-Za-z0-9]{4})/){|p| [$1.to_i(16)].pack("U")}
          m = LINEPAT.match fixed
          next unless m
          id, verb, label = m[1], m[2], m[3]
          next unless LABELPAT.match verb
          self.put label, id
        end
      end
    end
    
  end
end