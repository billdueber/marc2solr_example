require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.add_dependency 'marc4j4r', '>=0.9.0'
    gem.add_dependency 'jruby_streaming_update_solr_server', '>=0.3.1'
    gem.add_dependency 'marcspec', '>= 0.7.2'
    gem.add_dependency 'threach', '>= 0.2.0'
    
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

task :default => :check_dependencies