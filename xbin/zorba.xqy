xquery version "3.0";

(:
:   Module Name: Open MARC/XML files, process, using Zorba
:
:   Module Version: 1.0
:
:   Date: 2013 June 20
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: Zorba (expath)
:
:   Xquery Specification: January 2007
:
:   Module Overview:     Using Zorba, Opens MARC/XML file(s) 
:       and processes them into RDF for future analysis
:
:)

(:~
:   Using Zorba, Opens MARC/XML file(s) 
:   and processes them into RDF for future analysis
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since June 20, 2013
:   @version 1.0
:)

(: IMPORTED MODULES :)
import module namespace http            =   "http://www.zorba-xquery.com/modules/http-client";
import module namespace file            =   "http://expath.org/ns/file";
import module namespace parsexml        =   "http://www.zorba-xquery.com/modules/xml";
import schema namespace parseoptions    =   "http://www.zorba-xquery.com/modules/xml-options";

import module namespace processbibs    =   "info:lc/module/process-bibs#" at "../modules/module.ProcessBibs.xqy";

(: NAMESPACES :)
declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";
declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace ma            = "http://bibframe.org/marc-analysis/";

declare namespace an = "http://www.zorba-xquery.com/annotations";
declare namespace httpexpath = "http://expath.org/ns/http-client";

(:~
:   This variable is for the MARCXML location - externally defined.
:)
declare variable $MARCXMLLOC as xs:string external;

declare %an:nondeterministic function local:process-file($mloc as xs:string)
{
    let $marcxml := 
        if ( fn:starts-with($mloc, "http://" ) or fn:starts-with($mloc, "https://" ) ) then
            let $http-response := http:get-node($mloc) 
            return $http-response[2]
        else
            let $raw-data as xs:string := file:read-text($mloc)
            let $mxml := parsexml:parse(
                $raw-data, 
                <parseoptions:options />
            )
            return $mxml
    let $marcxml := $marcxml//marcxml:record
    return 
        for $r in $marcxml
        return processbibs:process-record($r)
};


let $resources := 
    if ( file:is-directory($MARCXMLLOC) ) then
        let $files := file:list($MARCXMLLOC, fn:false(), "*.xml")
        return 
            for $file in $files
            return local:process-file( fn:concat($MARCXMLLOC, $file) )        
    else
        local:process-file($MARCXMLLOC)
        
return 
    <rdf:RDF
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns:ma="http://bibframe.org/marc-analysis/"
    >
        {$resources}
    </rdf:RDF>
    


