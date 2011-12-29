= chbs

* FIX (url)

== DESCRIPTION:

Generate a 4 word password from words of size 3-8 characters, with
frequencies in the 30th-60th percentile. This range gives a nice set
of uncommon but not completely alien words.

    chbs generate --verbose -W 3..8 -P 30..60
    Corpus size: 6396 candidate words of 33075 total
    Entropy: 48 bits (2^48 = 281474976710656)
    Years to guess at 1000 guesses/sec: 8926
    magnate-thermal-sandbank-augur

With the --verbose flag, the utility will calculate a time-to-guess
based on a completely arbitrary 1000 guesses/sec.  If you'd like a
more secure password, either relax the various filtering rules (-W and
-P), add more words to the password, or use a larger corpus.

By default we use the Project Gutenberg 2005 corpus taken from Wiktionary.

See http://xkcd.com/936/ for the genesis of the idea.

Data sources:

     http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists
     http://wordfrequency.info/

== FEATURES/PROBLEMS:

* FIX (list of features or problems)

== SYNOPSIS:

  FIX (code sample of usage)

== REQUIREMENTS:

* FIX (list of requirements)

== INSTALL:

* FIX (sudo gem install, anything else)

== DEVELOPERS:

After checking out the source, run:

  $ rake newb

This task will install any missing dependencies, run the tests/specs,
and generate the RDoc.

== LICENSE:

(The MIT License)

Copyright (c) 2011 FIX

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
