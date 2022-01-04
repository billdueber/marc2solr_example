# marc2Solr_example -- example files for marc2solr

----

**Deprecated and archived**. See [traject/traject](https://github.com/traject/traject) for where things ended up.

----

These are just a set of example for how to configure [marc2solr](http://github.com/billdueber/marc2solr), a program to take MARC records, transform them, and send them to Solr.

For easy access, you should probably just clone this repository:

    git clone http://github.com/billdueber/marc2solr_example.git


## simple_sample

The `simple_sample` directory has some very basic, but hopefully well-documented, examples of an index file and translation maps. 

To test it, you could do something like

    cd simple_sample
    marc2solr index --config debug.m2s \
                    --indexfile index.dsl \
                    --tmapdir translation_maps <nameOfMarcFile>

The results will be a log file showing what happened, and a file called `debug.txt` that shows the transformed document for each MARC record read. 

## umich

The `umich` directory is where I eat my own dogfood; this is the actual live configuration setup I use to index [Mirlyn](http://mirlyn.lib.umich.edu/), at the [University of Michigan Library](http://lib.umich.edu/).

It's less well-documented than the `simple_sample` but is necessarily more complex. It also includes, in the `lib` subdirectory, the custom functions we use here. 

## For more information

...you should see the [marc2solr wiki](http://github.com/billdueber/marc2solr/wiki).


