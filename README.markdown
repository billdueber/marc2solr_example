# marc2Solr -- index MARC records in Solr via JRuby

`marc2Solr` is a package wrapping up functionality in a variety of other gems, designed to make getting data from [MARC21](http://en.wikipedia.org/wiki/MARC_standards) files into [Solr](http://lucene.apache.org/Solr/) as painless as possible.

`marc2Solr` is based on [Solrmarc](), the excellent Java-based program that does the same thing. `marc2Solr` is *not* a drop-in replacement for Solrmarc, but can do most of the same things.

It relies on [jruby](http://jruby.org/) to pull it all together; this will not run under stock Ruby!

## VERSION

0.3.0

Consider this a *beta* -- things are pretty settled down, but some parts of the interface (as represented by marcspec) may still change. Announcements of updates to this code and the libraries that underly it will be made at [my blog](http://robotlibrarian.billdueber.com/).


## MAJOR CHANGES

There was a major change in the way custom functions work between version 0.1 and 0.2 -- see the section "CHANGES" at the end of this file.

## Current problems

* There are debugging issues with `threach` -- see the `threach` section, below
* I've not yet figured out how to deal with logging done by the java code. At this point, it just spams STDOUT. I'm sure it's solvable, I just haven't solved it yet.


## How is this different (not better or worse) than Solrmarc?

* It's JRuby, not java (although you can use java code in JRuby if you'd like), which may make adding custom field functions easier depending on your comfort level with ruby vs java.
* It talks to Solr via http, not by directly munging the lucene indexes. This allows you to do things like run updates against a live index if you'd like, or run the indexing code on a separate machine than your Solr install.
* Configuration is just Ruby files, so you could (in theory) do fancy stuff in there

## How is this better (in my opinion) than solrmarc
* Values in translation maps can be arrays of values, not just scalars
* A single custom function can return values for multiple solr fields simultaneously. 
* It allows repeated solr field names (so values can come from multiple custom fields, if need be) and gives custom fields access to previously-computed values (so you don't need to re-do expensive work in many cases)
* You can easily multithread (with some caveats). With a single thread, it'll likely be a little slower. If you ramp it up with `threach`, it'll likely be a little faster (I'd *love* to hear from people about this).



## What's under the hood?
* [marcspec](http://github.org/billdueber/marcspec), a set of classes that allow one to easily pull bits of data out of MARC records (using the above). The whole of marc2solr is really a paper-thin wrapper over marcspec, which also uses the following.
* [jruby_streaming_update_Solr_server](http://github.com/billdueber/jruby_streaming_update_solr_server), a jruby wrapper around [org.apache.Solr.client.Solrj.impl.StreamingUpdateSolrServer](http://lucene.apache.org/Solr/api/org/apache/Solr/client/Solrj/impl/StreamingUpdateSolrServer.html). This provides both the connection to Solr (via StreamingUpdateSolrServer) and the ability to build a Solr document in a ruby-ish way (via SolrInputDocument)
* [marc4j4r/javamarc](http://github.com/billdueber/javamarc/tree/master/ruby/marc4j4r/), ruby wrappers around the incredible `marc4j.jar` java library. In this case, the code is based on my fork, which I've called [javamarc](http://github.org/billdueber/javamarc) to avoid confusion with Blas Peters' [original code in Tigres's CVS](http://marc4j.tigris.org/), given that I've already applied a significant patch (the original code re-orders tags as they are entered to maintain numeric tag-order regardless of the actual order in the MARC document; my patch just removes that reordering and leaves things alone)
* [threach](http://github.com/billdueber/threach), a simple "threaded each" that, despite its limitations, can be useful for easily speeding things up by throwing more cores at it.

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


### Get the marc2Solr code

    cd /where/you/want/it
    git clone git://github.com/billdueber/marc2Solr.git


### Installed the required gems

`marc2Solr` is set up to use [Bundler](http://gembundler.com). 

    jruby -S gem install bundler
    jruby -S bundle install
    
### Translate your Solrmarc files (optional)

If you have a Solrmarc installation, you can attempt an automated translation of the Solrmarc format files to `marc2Solr` format. 

We assume:

*  There's a single index file (e.g. umich_index.properties)
*  There's a single directory of translation maps called `translation_maps` "next to" the index file

In this case, you can run
    jruby bin/fromSolrmarc.rb /path/to/the/index.properties /my/new/dir
  
...e.g.

    jruby bin/fromSolrmarc.rb /Solr/umich/umich_index.properties ./umich
  
The results will be:

* Creation of `/my/new/dir`
* Translation, as much as possible, of `umich_index.properties` into `index.rb`
* Translation of all the translation maps
* Creation of a 'fromSolrmarc.log' file in `/my/new/dir`

Check out the logfile to see what the translator was unable to move over. Most custom functions will need to be re-written in ruby; a small few are provided with this distribution (see `/my/new/dir/lib/marc2Solr_custom.rb`).


### Create your own index.rb and translation files (eventually)

The format for these files is explained pretty well in the appropriate files 
within `simple_sample`. Start there, and send any questions to me so I can improve the docs.


### Create and/or use custom functions

There are a small handful of custom functions in `lib/marc2Solr_custom.rb` (basically, just the ones I was using), which is copied into the `lib/` directory when you run `fromSolrmarc.rb`, too. You can see how to apply them by looking at `simple_sample/index.rb` and how to write them by looking at `simiple_sample/lib/marc2Solr_custom.rb`.

To create your own custom functions, create a module and provide module-level function (again, see the example file in `lib/`). A custom routine specification just gives the module, method name (as a symbol), and optional arguments to pass besides the mid-construction document (a hashlike) and the MARC4J4R::Record object. 

A simple custom routine looks like this:

    module MARC2Solr
      module Custom
        module WhatzamattaU
          def self.doSomethingCustom(doc, record, myarg, myotherarg)
            previouslyComputedValues = doc['someField']
            vals = []
            if previousComptedValues.include? myarg
              vals << record['245']['a'] + myotherarg
            end
            return vals
          end
        end
      end
    end


...and is called via a spec like this:

    {
      :solrField => myField,
      :module => MARC2Solr::Custom::WhatzamattaU,
      :functionSymbol => :doSomethingCustom,
      :methodArgs => ['the first arg', 'the second arg']
    }
    
You can see that the module function (note that it's defined via `self.functionName`) will always have at least two arguments (`doc` and `record`), plus whatever you need to have passed in to do the work. When the system makes the call, you grab what you need from the document and the record and return an array of values. 

Note that *all* files in the `targetdir/lib` directory that end in either `.rb` or `.jar` will be loaded; you can include both ruby code java code in this way. Just create your file and dump it in there.

## Running to debug

Right now, the configuration above and beyond what's in the index and translation maps (e.g., where Solr is, how many threads to use, what kind of MARC file to expect) is just inlined at the top of the `marc2Solr.rb` file; this will have to change at some point.

### Edit the marc2Solr.rb file

The top of the `marc2Solr.rb` file is full of all sorts of configuration information -- where Solr is, whether to commit at the end, etc. As shipped, it expects a binary MARC file with unspecified MARC encoding, and will 
NOT send stuff to Solr -- just to STDOUT.

### Run it in debug mode and check out the results

`marc2Solr.rb` has three configuration variables (`actuallySendToSolr`, `ppMARC`, and `ppDoc`) to dictate what to do in terms of actually sending stuff to Solr and spitting debug info out to STDOUT. It can be useful at times to push out both the MARC record and what it gets turned into for debugging purposes. 

None of those options are mutually exclusive; you can push to Solr and STDOUT at the same time.

In any case, assuming you haven't messed with anything, go ahead and run

    jruby marc2Solr.rb /path/to/marcfile.mrc /dir/containing/index > out.txt

...e.g.,

    jruby marc2Solr.rb /path/to/mymarcfilie.mrc ./simple_sample > out.txt

Assuming you haven't changed anything in the config section of marc2Solr, you should have two files: 

*  A file called 'out.txt' that has text representations of what would have been sent to Solr
*  A file called `<basename of your marc file>-<date>-<time>.log` that has all the log info (you can crank this up by changing the log level to Logger::DEBUG)


## Actually sending stuff to Solr

When you've tested your index.rb file and all your custom functions seem to be working ok,  you can actually send stuff to Solr. 

Edit marc2Solr.rb to do the following:

*  Put the URL to your Solr install -- *not* all the way to the update handler; just to the Solr installation itself. This will likely look something like `http://machine.name:port/Solr` (or, for a vufind install, `http://machine.name:port/Solr/biblio` )
* Set `javabin` to true if you've defined the binary update script in your `Solrconfig.xml` file. It should look like this:

      <requestHandler name="/update/javabin" 
                    class="Solr.BinaryUpdateRequestHandler" />

The javabin handler isn't necessary, but it speeds things up.

* Make sure to set actuallySendToSolr to 'true'
* Decide whether or not to set `cleanOutSolr`; if true, the target Solr install will be completely emptied before indexing begins.

The logfile will again show you what's going on, including rough speeds.

## Speeding things up even more with threach

It's possible to speed things up even more by using even more threads to do the marc->Solrdocument translation process. By specifying multiple work threads in your configuration section and changing the main loop to use `threach` instead of `each` (just comment/uncomment out the appropriate lines) you can get a big speed increase. 

There are some issues with using `threach`:
* `threach`, however, doesn't deal with thrown errors very well, so if you expect you'll have exceptions that aren't caught, you might end up with a silent deadlock and nothing to do but hit Ctrl-C. This is the big one.
* The reported number of records indexed will almost certainly not match reality. Check your Solr admin panel for that. 

Having said all that, I use `threach` in production with no problems; just program defensively.

# CHANGES
0.4
:  Update marcspec version requirement to 0.7; this changes the configuration
   for a custom function to indicate what module function with the key   :functionSymbol (instead of the former :moduleSymbol). It's a module function, not any sort of method. 
   
0.3
:  Updated marcspec requirement to allow custom functions to return values for
   multiple solr fields simultaneously, and added example to 
   `simple_sample/index.rb` and `simple_sample/lib/marc2solr_custom.rb`
   
0.2
:  Added VERSION file and this CHANGES section
:  Update to use MARCSpec v0.4, which changes the signature of custom 
   functions. Instead of` (record, your,args)`, it's now `(doc, record, your, 
   args)`, where `doc` is a hashlike that contains the already-computed 
   fields. This allows you access to stuff you've already done in subsequent 
   field computations (e..g, use the results of the `format` fields to 
   influence setting -- or not -- the `serialTitle` field).

0.1
:  First public release