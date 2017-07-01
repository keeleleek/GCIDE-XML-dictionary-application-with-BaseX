xquery version "3.1";

(:~
 : This module contains some basic examples for a dictionary search system
 : @author MTÜ Keeleleek
 :)
module namespace gcide = 'keeleleek-example-namespace-for-gcide';




(:~ 
 : Global variables specifying full-text search options
 :)
declare variable $gcide:full-text-options := map {
    "mode": "all words",
    "stemming": true(),
    "language": "en"
  };




(:~ 
 : The html page for searching definitions
 :) 
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
{
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Search GCIDE by definitions</title>
      <link rel="stylesheet" type="text/css" href="/static/gcide.css"/>
    </head>
    <body>
      <h1>Find words by definition</h1>
      <form method="get" action=".">
        <p>Words contained in the definition:<br />
        <input name="q" size="100" value="{$search-q}"></input>
        <input type="submit" /></p>
      </form>
      {
        if($search-q = "")
        then()
        else(
          let $search-terms := tokenize($search-q)
          return 
            for $element in gcide:search-full-text-definition($search-terms)
              return gcide:show-elements-as-html($element)
        )
      }
    </body>
  </html>
};




(:~ 
 : The html page for showing a headwords
 :) 
declare
  %rest:path("/gcide/word/{$word}")
  %output:method("xhtml")
  %output:omit-xml-declaration("no")
  %output:doctype-public("-//W3C//DTD XHTML 1.0 Transitional//EN")
  %output:doctype-system("http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")
function gcide:gui-search-headword($word as xs:string)
  as element(Q{http://www.w3.org/1999/xhtml}html)
{
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>GCIDE headword "{$word}"</title>
      <link rel="stylesheet" type="text/css" href="/static/gcide.css"/>
    </head>
    <body>
      <h1>GCIDE headword "{$word}"</h1>
      {
          (: search and insert the results here :)
          gcide:search-headword($word)
      }
      <a href="javascript:history.back()">👈 Go back</a>
    </body>
  </html>
};




(:~ 
 : Simple xslt kind of transforming some elements into hypertext
 : @since v1.0
 : @param $node the input root node
 : @return node() depends on the input
 :)
declare
function gcide:show-elements-as-html($element as node())
{
  typeswitch ($element)
    (: ent is enclosed within a hypertext link :)
    case  element(ent)   return
            element {"a"}
            {
              attribute {"href"} {concat("/gcide/word/", $element/string())},
              attribute {"title"} {concat('See word details for "', $element/string(), '"')},
              
              element {node-name($element)}
              {
                for $sub-element in $element/node()
                  return  gcide:show-elements-as-html($sub-element)
              }
            }
    
    (: br elements are simply ignored and removed :)
    case element(br)
      return ()
    
    (: element nodes are copied recursively :)
    case element()
      return 
           element {node-name($element)}
             {
                for $sub-element in $element/node()
                  return  gcide:show-elements-as-html($sub-element)
             }
     
    (: text nodes are returned as leaves :)
    case node()
      return $element
    
    (: all other nodes will be simply ignored :)
    default
      return ()
};




(:~
 : Function for finding all headwords by full-text searching their definitions for the given terms.
 : The full-text search options are given in the variable $gcide:full-text-options
 : @since v1.0
 : @param $search-terms as xs:string+
 : @return list of dictionary articles ('p' elements)
 :)
declare
function gcide:search-full-text-definition($search-terms as xs:string+)
as element(p)*
{ 
  db:open("gcide")//dictionary/body/p//def[
          ft:contains(., $search-terms, $gcide:full-text-options)
        ]//parent::p
};




(:~ 
 : Simple search function for finding headword.
 : @since v1.0
 : @param $worc as xs:string
 : @return list of dectionary articles ('p' elements)
 :)
declare
function gcide:search-headword($word as xs:string)
as element(p)*
{
  let $search-q := concat("^", normalize-space($word), "$")
  let $matches-flags := "i"
  
  return db:open("gcide")//dictionary/body/p/ent[matches(., $search-q, $matches-flags)]/parent::p
};
