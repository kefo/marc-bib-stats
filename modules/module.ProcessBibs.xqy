xquery version "1.0";

(:
:   Module Name: Extract fields from MARC/XML Bibs to RDF
:
:   Module Version: 1.0
:
:   Date: 2013 June 20
:
:   Copyright: Public Domain
:
:   Proprietary XQuery Extensions Used: none
:
:   Xquery Specification: January 2007
:
:   Module Overview:     Extract fields from MARC/XML Bibs to RDF for
:       analysis.
:
:)

(:~
:   Extracts information from MARC BIB files into RDF for
:   future analysis.
:
:   @author Kevin Ford (kefo@loc.gov)
:   @since June 20, 2013
:   @version 1.0
:)

module namespace processbibs            =   "info:lc/module/process-bibs#";

(: NAMESPACES :)
declare namespace marcxml       = "http://www.loc.gov/MARC21/slim";
declare namespace rdf           = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs          = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace ma            = "http://bibframe.org/marc-analysis/";

declare variable $processbibs:BASEURI := "info:lc/bibs/"; 
    
declare variable $processbibs:FIELDS := 
    <fields>
        <!--
        <field>040</field>
        <field>050</field>
        -->
        <field>260</field>
        <field>530</field>
        <field>533</field>
        <field>534</field>
        <field>535</field>
    </fields>;

(: MAIN :)
declare function processbibs:process-record(
        $marcxml as element(marcxml:record)
    ) as element(rdf:Description)
{
    let $cf001 := xs:string($marcxml/marcxml:controlfield[@tag eq "001"])
    let $lccn := 
        element { "ma:marcLCCN" } { 
            fn:normalize-space($marcxml/marcxml:datafield[@tag eq "010"][1]/marcxml:subfield[@code eq "a"][1])
        }
    let $isbn-sets := processbibs:process-isbns($marcxml)
    let $isbns := 
        element {"ma:marcISBNcount"} {
            attribute rdf:datatype {"http://www.w3.org/2001/XMLSchema#integer"},
            xs:string( fn:count($isbn-sets/set) )
        }
    let $props := 
        for $f in $processbibs:FIELDS/field
        let $prop-base  := fn:concat("ma:marc", $f)
        let $field-count := 
            element { fn:concat($prop-base, "count") } {
                attribute rdf:datatype {"http://www.w3.org/2001/XMLSchema#integer"},
                fn:string(fn:count($marcxml/marcxml:datafield[@tag eq $f]))
            }
        let $p := 
            for $df in $marcxml/marcxml:datafield[@tag eq $f]            
            let $all-fields := 
                element { fn:concat($prop-base, "all") } {
                    fn:string-join($df/marcxml:subfield/@code, "")
                }    
            let $indiv-fields :=
                for $sf in $marcxml/marcxml:datafield[@tag eq $f]/marcxml:subfield
                return element {$prop-base} { xs:string($sf/@code) }
            let $ind1 := 
                for $sf in $marcxml/marcxml:datafield[@tag eq $f]/@ind1
                where $sf ne " "
                return element { fn:concat($prop-base, "i1") } { xs:string($sf) }
            let $ind2 := 
                for $sf in $marcxml/marcxml:datafield[@tag eq $f]/@ind2
                where $sf ne " "
                return element { fn:concat($prop-base, "i2") } { xs:string($sf) }
            return ($all-fields, $indiv-fields, $ind1, $ind2)
        return ($field-count, $p)
            
    return
        element rdf:Description {
            attribute rdf:about { fn:concat($processbibs:BASEURI , $cf001) },
            $lccn,
            $props,
            $isbns
        }
};


(:~
: This function takes a string and
: attempts to clean it up
: ISBD punctuation. based on 260 cleaning
:
: @param $s is fn:string
: @return fn:string
:)
declare function processbibs:clean-string(
    $s as xs:string?
    ) as xs:string
{
if (fn:exists($s)) then
let $s:= fn:replace($s,"from old catalog","","i")
let $s := fn:replace($s, "([\[\];]+)", "")
let $s := fn:replace($s, " :", "")
let $s := fn:normalize-space($s)
(:if it contains unbalanced parens, delete:)
let $s:= if (fn:contains($s,"(") and fn:not(fn:contains($s, ")")) ) then
fn:replace($s, "\(", "")
else if (fn:contains($s,")") and fn:not(fn:contains($s, "(")) ) then
fn:replace($s, "\)", "")    
else $s

return
if ( fn:ends-with($s, ",") ) then
fn:substring($s, 1, (fn:string-length($s) - 1) )
else
$s

else ""



};


(:~
: This function takes an ISBN string and
: determines if it's 10 or 13, and returns both the 10 and 13 for this one.
:
: @param $s is fn:string
: @return wrap/bf:isbn element()
:)

declare function processbibs:get-isbn($isbn as xs:string ) as element() {
    (:
let $isbn1:="9780792312307" (:produces 0792312309 ok:)
let $isbn1:="0792312309" (:produces 9780792312307 ok:)
let $isbn1:="0-571-08989-5" (:produces 9780571089895 ok:)
let $isbn1:="0 571 08989 5" (:produces 9780571089895 ok:)
verify here:http://www.isbn.org/converterpub.asp
let $isbn:="paperback" (:produces "error" ok:)
:)

    let $clean-isbn:=fn:replace($isbn,"[- ]+","")
    (:let $isbn-num:=replace($clean-isbn,"^[^0-9]*(\d+)[^0-9]*$","$1" ):)
    (: test on isbn 10, 13, hyphens, empty, strings only :)

    let $isbn-num1:= fn:replace($clean-isbn,"^[^0-9]*(\d+)[^0-9]*$","$1" )
    let $isbn-num:= if (fn:string-length($isbn-num1)=9) then fn:concat($isbn-num1,'X') else $isbn-num1

    (: test on isbn 10, 13, hyphens, empty, strings only :)

    return
        if (fn:number($isbn-num) or fn:number($isbn-num1) ) then
    
if ( fn:string-length($isbn-num) = 10 ) then
let $isbn12:= fn:concat("978",fn:substring($isbn-num,1,9))
let $odds:= fn:number(fn:substring($isbn12,1,1)) + fn:number(fn:substring($isbn12,3,1)) +fn:number(fn:substring($isbn12,5,1)) + fn:number(fn:substring($isbn12,7,1)) +fn:number(fn:substring($isbn12,9,1)) +fn:number(fn:substring($isbn12,11,1))
let $evens:= (fn:number(fn:substring($isbn12,2,1)) + fn:number(fn:substring($isbn12,4,1)) +fn:number(fn:substring($isbn12,6,1)) + fn:number(fn:substring($isbn12,8,1)) +fn:number(fn:substring($isbn12,10,1)) +fn:number(fn:substring($isbn12,12,1)) ) * 3
let $chk:=
if ( (($odds + $evens) mod 10) = 0) then
0
else
10 - (($odds + $evens) mod 10)
                return
                element wrap {
                element isbn10 {$isbn-num},
                element isbn13 { fn:concat($isbn12,$chk)}
                }
                 
            else (: isbn13 to 10 :)
                let $isbn9:=fn:substring($isbn-num,4,9)
                let $sum:= (fn:number(fn:substring($isbn9,1,1)) * 1)
                        + (fn:number(fn:substring($isbn9,2,1)) * 2)
                        + (fn:number(fn:substring($isbn9,3,1)) * 3)
                        + (fn:number(fn:substring($isbn9,4,1)) * 4)
                        + (fn:number(fn:substring($isbn9,5,1)) * 5)
                        + (fn:number(fn:substring($isbn9,6,1)) * 6)
                        + (fn:number(fn:substring($isbn9,7,1)) * 7)
                        + (fn:number(fn:substring($isbn9,8,1)) * 8)
                        + (fn:number(fn:substring($isbn9,9,1)) * 9)
                let $check_dig:=
                    if ( ($sum mod 11) = 10 ) then
                        'X'
                    else
                        ($sum mod 11)
                return
                    element wrap {
                        element isbn10 {fn:concat($isbn9,$check_dig) },
                        element isbn13 {$isbn-num}
                    }
           
        else
            element wrap {
                element isbn10 {"error"},
                element isbn13 {"error"}
            }

};

(:~
:   TAKEN FROM MARCXML BIB to BIBFRAME
:   This is the function that finds and dedups isbns, delivering a complete set for generate-instancefrom isbn
:   If the 020$a has a 10 or 13, they are matched in a set, if the opposite of a pair doesn't exist, it is calculated
:   @param $marcxml element is the MARCXML record
:   @return wrap as as wrapper for bf:set* as element() containing both marcxml:subfield [code=a] and bf:isbn calculated nodes
:
:)
declare function processbibs:process-isbns (
    $marcxml as element (marcxml:record)
) as element() {
    
    (:for books with isbns, generate all isbn10 and 13s from the data, list each pair on individual instances:)
    let $isbns:=$marcxml/marcxml:datafield[@tag eq "020"]/marcxml:subfield[@code eq "a"]
    let $isbn-sets:=
        for $str in $isbns
        let $isbn-str:=fn:normalize-space(fn:tokenize(fn:string($str),"\(")[1])
        return
            element isbn-pair {
                processbibs:get-isbn( processbibs:clean-string( $isbn-str ) )/*
            }

    let $unique-13s := fn:distinct-values($isbn-sets/isbn13)
    let $unique-pairs:=
        for $isbn13 in $unique-13s
        let $isbn-set := $isbn-sets[isbn13=$isbn13][1]
        return
            element set {
                element isbn { fn:string($isbn-set/isbn10) },
                element isbn { fn:string($isbn-set/isbn13) },
             for $sfa in $marcxml/marcxml:datafield[@tag eq "020"]/marcxml:subfield[@code eq "a"]
             where fn:contains(fn:string($sfa),fn:string($isbn-set/isbn10)) or fn:contains(fn:string($sfa),fn:string($isbn-set/isbn13))
                return $sfa
            }
    return
        element wrap {
            for $set in $unique-pairs
            return element set { $set/* }
        }

};
