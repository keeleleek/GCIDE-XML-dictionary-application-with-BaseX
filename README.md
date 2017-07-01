# XQuery and BaseX for GCIDE XML dictionary searching


## Introduction

This write-up is a hands-on setting up a BaseX XML database and create a
simple but powerful search page for the _GNU version of The Collaborative 
International Dictionary of English_.

We will implement the dictionary search engine with a few XQuery
functions and further add RESTXQ annotations for making some of
these functions available via internet. For dictionary data we will use
the XML version of the _GNU version of The Collaborative International
Dictionary of English_ (GCIDE_XML). The dictionary is available under the
GNU General Public License. Read more about the [GCIDE
here](http://gcide.gnu.org.ua/) and about the [GCIDE_XML
here](http://www.ibiblio.org/webster/).



## Getting BaseX up and running

We will use the official BaseX zip distribution from
http://basex.org/products/download/all-downloads/. This is the easiest
and most generic way of starting an BaseX instance reachable through HTTP.
Download and unzip the file in your home folder:

```bash
wget http://files.basex.org/releases/8.6.4/BaseX864.zip
unzip BaseX864.zip
```

To start the http server and letting it run after closing the SSH session, use
the ``nohup`` command:

```bash
cd basex
nohup ./bin/basexhttp > $HOME/basexrunning.log &
```

All information emitted by the BaseX server is stored in the
 ``basexrunning.log`` file.

To stop the server use the command:

```bash
$HOME/basex/bin/basexhttpstop
```


## Walk-through of BaseX

The BaseX server is running and is reachable via port 8984 on the address
``http://yourhost:8984/``. The BaseX distribution includes a demonstration of
several examples of HTTP services, two of them will be detailed here. The
code of the demonstration is shown on the webpage, but it is saved in
``basex/webapp/restxq.xqm``.


### Walk-through the BaseX HTTP service examples

The code in _Example 1_ shows how easy it is to get variable data from the URL and thus set up a simple RESTful API for a function.

The code in _Example 2_ shows how to use POST data.

The code in _Example 3_ includes the full XQuery code for the example page.

The dictionary search application uses the technique from example 1 to make a simple headword search. Instead of POST the main search function of the dictionary application uses the GET verb.


### Walk-through of the DBA

The DBA is a simple database administration interface and was built for
demonstration purposes by the BaseX team. Log in on
``http://yourhost:8984/dba`` with `admin` and `admin` as your credentials.
You should change the default password under the '[Jobs & Users](http://yourhost:8984/dba/jobs-users)' page .


# Make your own dictionary search application

We will make a very simple search tool for the dictionary. The search tool
supports both searching for words and for finding words according to their
definitions.


## Get the data

Instead of using the DBA for uploading our data, we will connect to the BaseX server instance using the client.

Find the zipped xml files from the [GCIDE_XML](http://www.ibiblio.org/webster/) homepage.

Download and unzip the dictionary data to your home folder on the server

```bash
wget http://www.ibiblio.org/webster/gcide_xml-0.51.zip
unzip gcide_xml-0.51.zip
```

The main file is ``gcide.xml`` which defines and links to the other files (which are called _external general parsed entities_ in XML parlour).

Now import them into BaseX. We allready have a BaseX server running and reachable from the web, we can connect to it using a local client with the ``basexclient`` command.

Log in using your credentials as specified you specified them in the DBA. The following commands creates a new database and populates it with the data from the GCIDE_XML files:

```bash
CREATE DB gcide        # db name is 'gcide'
SET INTPARSE true      # use internal parser
SET CHOP false         # don't chop whitespace
SET AUTOOPTIMIZE true  # enable autooptimize
SET DTD true           # parse DTD and entities
SET FTINDEX true       # enable Full-Text search index
SET STEMMING true      # and enable stemming of words
SET LANGUAGE English   # for English language
# now add the main file 'gcide.xml'
ADD /home/centos/gcide_xml-0.51/xml_files/gcide.xml
# now disconnect
exit
```

When importing the files we will need to specify only the main file gcide.xml and specify the parsing option for „parse DTD and entities” and disable „chop whitespace”.

You can now inspect and query the database using the DBA. To make sure it worked, run the query ``count(//def)``. It should return 179750 (that's how many 'def' elements there are in the dictionary).

## The XQuery search functions

Now let's build the search functions. We do this by writing XQuery functions in a module file and adding some RESTXQ annotations for mapping HTTP requests to these XQuery functions.

The XQuery code for the dictionary application is found in the file ``gcide.xqm`` and some basic styling is found in the file ``static/gcide.css``. Put them in the folder ``/home/centos/basex/webapp``. BaseX reacts directly to the file's presence and its RESTXQ annotations, so the search functionality updates directly each time the .xqm-file is uploaded.

The search application is available at http://yourhost:8984/gcide/search and the word search function is available at http://yourhost:8984/gcide/word/YourWordHere.

The following XQuery code declares the search function for finding all headwords that have the given terms in their definitions (headwords are the 'p' elements and definitions are 'def' elements in GCIDE_XML). It uses the full-text search module of BaseX but could have been implemented directly in XQuery syntax without the dependency on BaseX modules.

```XQuery
declare
function gcide:search-full-text-definition($search-terms as xs:string+)
as element(p)*
{
  db:open("gcide")//dictionary/body/p//def[
          ft:contains(., $search-terms, $gcide:full-text-options)
        ]//parent::p
};
```

The search function is integrated into the webpage that is served by the function ``gcide:gui-search-full-text-definition/1``. The webpage's function declaration is annotated with RESTXQ directives that specify its output method, which url path it is accessible from and which parameters it takes, etc. The head of the declaration without the body is shown below.

```xquery
declare
  %rest:path("/gcide/search")
  %output:method("xhtml")
  %rest:GET
  %rest:query-param("q","{$search-q}", "")
  %output:omit-xml-declaration("no")
  %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")
  %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")
function gcide:gui-search-full-text-definition($search-q as xs:string)
as element(Q{http://www.w3.org/1999/xhtml}html)
```
