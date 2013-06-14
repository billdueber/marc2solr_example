#!/bin/bash -l
rvm_path=/htsolr/catalog/bin/rvm


solrspecfile=$1
delfile=$2
marcfile=$3

source $rvm_path/scripts/rvm 
rvm jruby 
marc2solr delete -c $solrspecfile --skipcommit $delfile
marc2solr index -c $solrspecfile -c ht.m2s --threads 1 --sussthreads 1 --skipcommit $marcfile

