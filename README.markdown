# marc2solr -- index MARC records in Solr via JRuby

`marc2solr` is a package wrapping up functionality in a variety of other gems, designed to make getting data from [MARC21](http://en.wikipedia.org/wiki/MARC_standards) files into [Solr](http://lucene.apache.org/solr/) as painless as possible.

`marc2solr` is based on [Solrmarc](), the excellent Java-based program that does the same thing. `marc2solr` is *not* a drop-in replacement for Solrmarc, but can do most of the same things.

It relies on [jruby](http://jruby.org/) to pull it all together; this will not run under stock Ruby!

## Current problems

* There are debugging issues with `threach` -- see the `threach` section, below
* I've not yet figured out how to deal with logging done by the java code. At this point, it just spams STDOUT. I'm sure it's solvable, I just haven't solved it yet.


## INSTALLATION

### Get JRuby
First, you need to download a copy of [JRuby](http://jruby.org/download), untar/gzip it, and make sure its `bin/` directory is in your path.

Maybe something like this:

    <Download jruby-bin-1.5.1.tar.gz>
    cd ~/bin
    tar xzf /path/to/jruby-bin-1.5.1.tar.gz
    ln -s jruby-1.5.1/ jruby
    cd jruby/bin
    export PATH=`pwd`:$PATH


### Get the marc2solr code

    cd /where/you/want/it
    git clone git://github.com/billdueber/marc2solr.git


### Installed the required gems

`marc2solr` is set up to use [Bundler](http://gembundler.com). 

    jruby -S gem install bundler
    jruby -S bundle install
    
### Translate your Solrmarc files (optional)

If you have a Solrmarc installation, you can attempt an automated translation of the Solrmarc format files to `marc2solr` format. 

We assume:

*  There's a single index file (e.g. umich_index.properties)
*  There's a single directory of translation maps called `translation_maps` "next to" the index file

In this case, you can run
    jruby bin/fromsolrmarc.rb /path/to/the/index.properties /my/new/dir
  
...e.g.

    jruby bin/fromsolrmarc.rb /solr/umich/umich_index.properties ./umich
  
The results will be:

* Creation of `/my/new/dir`
* Translation, as much as possible, of `umich_index.properties` into `index.rb`
* Translation of all the translation maps
* Creation of a 'fromsolrmarc.log' file in `/my/new/dir`

Check out the logfile to see what the translator was unable to move over. Most custom functions will need to be re-written in ruby; a small few are provided with this distribution (see `/my/new/dir/lib/marc2solr_custom.rb`).


### Create your own index.rb and translation files (eventually)

The format for these files is explained pretty well in the appropriate files 
within `simple_sample`. Start there, and send any questions to me so I can improve the docs.


### Create and/or use custom routines

There are a small handful of custom routines in `lib/marc2solr_custom.rb` (basically, just the ones I was using), which is copied into the `lib/` directory when you run `fromsolrmarc.rb`, too. You can see how to apply them by looking at `simple_sample/index.rb` and how to write them by looking at `simiple_sample/lib/marc2solr_custom.rb`.

To create your own custom functions, create a module 

Note that *all* files in the `targetdir/lib` directory that end in either `.rb` or `.jar` will be loaded; you can include both ruby code java code in this way. Just create your file and dump it in there.

## Running to debug

Right now, the configuration above and beyond what's in the index and translation maps is right in the `marc2solr.rb` file; this will have to change at some point.

### Edit the marc2solr.rb file

The top of the `marc2solr.rb` file is full of all sorts of configuration information -- where solr is, whether to commit at the end, etc. As shipped, it expects a binary MARC file with unspecified MARC encoding, and will 
NOT send stuff to Solr -- just to STDOUT.

### Run it in debug mode and check out the results

The top of the `marc2solr.rb` file has three configuration variables to dictate what to do in terms of actually sending stuff to solr and spitting debug info out to STDOUT. It can be useful at times to push out both the MARC record and what it gets turned into for debugging purposes. 

None of those options are mutually exclusive; you can push to solr and STDOUT at the same time.

In any case, go ahead and run

    jruby marc2solr.rb /path/to/marcfile.mrc /dir/containing/index/ > out.txt

...e.g.,

    jruby marc2solr.rb /path/to/mymarcfilie.mrc ./simple_sample/ > out.txt

Assuming you haven't changed anything in the config section of marc2solr, you should have two files: 

*  A file called 'out.txt' that has text representations of what would have been sent to Solr
*  A file called `<basename of your marc file>-<date>-<time>.log` that has all the log info (you can crank this up by changing the log level to Logger::DEBUG)


## Actually sending stuff to solr

When you've tested your index.rb file and all your custom routines seem to be working ok,  you can actually send stuff to Solr. 

Edit marc2solr.rb to do the following:

*  Put the URL to your solr install -- *not* all the way to the update handler; just to the solr installation itself. This will likely look something like `http://machine.name:port/solr` (or, for a vufind install, `http://machine.name:port/solr/biblio` )
* Set `javabin` to true if you've defined the binary update script in your `solrconfig.xml` file. It should look like this:

      <requestHandler name="/update/javabin" 
                    class="solr.BinaryUpdateRequestHandler" />

The javabin handler isn't necessary, but it speeds things up.

* Make sure to set actuallySendToSolr to 'true'
* Decide whether or not to set `cleanOutSolr`; if true, the target Solr install will be completely emptied before indexing begins.

The logfile will again show you what's 

## Speeding things up even more with threach

It's possible to speed things up even more by using even more threads to do the marc->solrdocument translation process. By specifying multiple work threads in your configuration section and changing the main loop to use `threach` instead of `each` (just comment/uncomment out the appropriate lines) you can get a big speed increase. 

There are some issues with using `threach`:
* `threach`, however, doesn't deal with thrown errors very well, so if you expect you'll have exceptions that aren't caught, you might end up with a silent deadlock and nothing to do but hit Ctrl-C. This is the big one.
* The reported number of records indexed will almost certainly not match reality. Check your solr admin panel for that. 

Having said all that, I use `threach` in production with no problems; just program defensively.