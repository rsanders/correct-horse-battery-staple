= chbs

* http://github.com/rsanders/correct-horse-battery-staple

== DESCRIPTION:

Generate a 4 word password from words of size 3-8 characters, with
frequencies in the 30th-60th percentile. This range gives a nice set
of uncommon but not completely alien words.

    $ chbs generate --verbose -W 3..8 -P 30..60
    Corpus size: 6396 candidate words of 33075 total
    Entropy: 48 bits (2^48 = 281474976710656)
    Years to guess at 1000 guesses/sec: 8926
    magnate-thermal-sandbank-augur

With the --verbose flag, the utility will calculate a time-to-guess
based on a completely arbitrary 1000 guesses/sec.  If you'd like a
more secure password, either relax the various filtering rules (-W and
-P), add more words to the password, or use a larger corpus.

By default we use the American TV Shows & Scripts corpus taken from
Wiktionary.

Others provided:

* Project Gutenberg 2005 corpus taken from Wiktionary.
* 1 of every 7 of the top 60000 lemmas from wordfrequency.info (6900
  actual lemmas after processing)

See http://xkcd.com/936/ for the genesis of the idea.

Data sources:

     http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists
     http://wordfrequency.info/

== FEATURES/PROBLEMS:

* Generates pretty decent XKCD-style passwords using pretty simple logic
* Meant to be a proof-of-concept, and succeeds at that.

Not so good:

* Corpus loading is slow and memory-hungry
* Needs a good corpus abstraction beyond serialized arrays/objects
  loaded from CSV/JSON/Marshal
* Should probably store default filter params per-corpus (e.g., 30-70
  percentile works great for one corpus, badly for another)
* Probably needs a ~/.correct-horse-battery-staple file to set defaults


== SYNOPSIS:

Command line usage, for a password of 4 words (default), each word of
length between 3-8 letters, taken from the 30th through the 60th
percentile range of the corpus sorted by word frequency from least to
most frequent:

    $ chbs generate --verbose -W 3..8 -P 30..60

    Corpus size: 6396 candidate words of 33075 total
    Entropy: 48 bits (2^48 = 281474976710656)
    Years to guess at 1000 guesses/sec: 8926
    magnate-thermal-sandbank-augur

The 'chbs' command line program is the best reference for usage of the
underlying library.  This would be a minimal version:

    require 'correct_horse_battery_staple'
    corpus    = CorrectHorseBatteryStaple.default_corpus
    generator = CorrectHorseBatteryStaple::Generator.new(corpus)
    puts generator.make(4)

== REQUIREMENTS:

* Ruby 1.8.7, 1.9.x, or (approximately) JRuby 1.5.x or later.

== INSTALL:

Just "gem install" and use the "chbs" wrapper program.

== DEVELOPERS:

After checking out the source, run:

  $ rake newb

This task will install any missing dependencies, run the tests/specs,
and generate the RDoc.

== LICENSE:

(The MIT License)

Copyright (c) 2011 Robert Sanders, opensource@esquimaux.otherinbox.com

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

