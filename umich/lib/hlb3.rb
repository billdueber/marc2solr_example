require 'rubygems'
require 'marcspec'
require 'pp'

$: << File.dirname(__FILE__)
require 'jackson-core-asl-1.4.3.jar'
require 'jackson-mapper-asl-1.4.3.jar'
require 'apache-solr-umichnormalizers.jar'
require 'HLB3.jar'
include_class Java::edu.umich.lib.hlb::HLB


module MARC2Solr
  module Custom
    module HighLevelBrowse
      
      # First, define a solrspec that will find all of the LC Call Numbers, as near as we can tell, anyway.
      # It's only for internal use, but useful nonetheless
      @spechash = {
        :solrField => 'internal_hlb',
        :specs => [
          ['050','ab'],
          ['082','a'],
          ['090','ab'],
          ['099','a'],
          ['086','a'],
          ['086','z'],
          ['852','hij'],
          ] 
      }
      
      @hlbspec = MARCSpec::SolrFieldSpec.fromHash @spechash
      
      # Now use it to get the HLB stuff
      
      def self.getHLBStuff doc, r
        callnumbers = @hlbspec.marc_values(r)

        components = []
        delimited = []
        callnumbers.each do |c|
          cats = HLB.categories(c).to_a # that's calling the java class method
          cats.compact!
          cats.each do |cat|
            delimited << cat
            cat.split(/\s*\|\s/).each do |comp|
              components << comp
            end
          end
        end
        components.uniq!
        delimited.uniq!
        return [components, delimited]
      end
    end
  end
end
      
