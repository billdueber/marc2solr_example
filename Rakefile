require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "marc2solr"
    gem.summary = %Q{Get MARC data into Solr}
    gem.description = %Q{Use MARCSpec, jruby_streaming_update_solr_server, and MARC4J4R to extract data from MARC records and get them into Solr. A substitute for solrmarc}
    gem.email = "bill@dueber.com"
    gem.homepage = "http://github.com/billdueber/marc2solr"
    gem.authors = ["Bill Dueber"]
    
    gem.add_dependency 'marc4j4r', '>=1.1.0'
    gem.add_dependency 'jruby_streaming_update_solr_server', '>=0.4.1'
    gem.add_dependency 'marcspec', '>= 1.5.1'
    gem.add_dependency 'threach', '>= 0.2.0'
    
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "yard", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
