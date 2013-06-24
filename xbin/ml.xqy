xquery version "1.0-ml";

(:
:   Module Name: Open MARC/XML files, process, using MarkLogic
:
:   Module Version: 1.0
:
:   Date: 2013 June 20
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: MarkLogic
:
:   Xquery Specification: January 2007
:
:   Module Overview:     Using ML, Opens MARC/XML file(s) 
:       and processes them into RDF for future analysis
:
:)

(:~
:   Using ML, Opens MARC/XML file(s) 
:   and processes them into RDF for future analysis
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since June 20, 2013
:   @version 1.0
:)

(: IMPORTED MODULES :)
import module namespace processbibs    =   "info:lc/module/process-bibs#" at "../modules/module.ProcessBibs.xqy";

(: NAMESPACES :)
declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";
declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace ma            = "http://bibframe.org/marc-analysis/";

declare namespace dir           = "http://marklogic.com/xdmp/directory";
declare namespace xdmp          = "http://marklogic.com/xdmp";

declare option xdmp:output "indent-untyped=yes" ; 

(:~
: This variable is for the MARCXML location - externally defined.
:)
declare variable $MARCXMLLOC as xs:string := xdmp:get-request-field("marcxmlloc","");

declare function local:process-file($mloc as xs:string)
{
    let $marcxml :=
        xdmp:document-get(
            $mloc,
            <options xmlns="xdmp:document-get">
                <format>xml</format>
            </options>
        )
    let $marcxml := $marcxml//marcxml:record
    return 
        for $r in $marcxml
        return processbibs:process-record($r)

};


let $directory := 
    try {
        xdmp:filesystem-directory( fn:concat(xdmp:modules-root(), $MARCXMLLOC) )
    } catch ($e) {
        <no-dir />
    }

let $resources := 
    if ( fn:local-name($directory) eq "no-dir") then
        local:process-file( $MARCXMLLOC )
    else
        for $f in $directory/dir:entry/dir:pathname
        where fn:ends-with($f, ".xml")
        return local:process-file($f)    
        
return 
    <rdf:RDF
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns:ma="http://bibframe.org/marc-analysis/"
    >
        {$resources}
    </rdf:RDF>
    


