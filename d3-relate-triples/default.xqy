xquery version "1.0-ml";

import module namespace semantics = "org.lds.gte.core-semantics-functions" at "/core/semantics-functions.xqy";

declare namespace sem = "http://marklogic.com/semantics";

declare option xdmp:output "method = html";


declare variable $nodeIDs := map:map();
declare variable $links := map:map();
declare variable $subject := xdmp:get-request-field( "subject", "Smith, Joseph Jr." );
declare variable $target := xdmp:get-request-field( "target", "Jesus Christ" );


declare function local:getTransitiveClosure(
    $subject as xs:string,  
    $target as xs:string
) as map:map? {
    if ($subject ne "" and $target ne "")
    then
        let $subjectIRI := semantics:getSubjectByLabel($subject)
        let $targetIRI := semantics:getSubjectByLabel($target)
        return 
            if (fn:empty($subjectIRI) or fn:empty($targetIRI) )
            then ()
            else
                let $map := semantics:transitive-closure(sem:iri($subjectIRI), sem:iri("http://www.w3.org/2004/02/skos/core#related"), 99) ! map:get(., $targetIRI)
                let $_ := 
                    for $key in map:keys($map)
                    return
                        if (fn:count(map:get($map, $key)[. eq $targetIRI]) gt 1)
                        then map:delete($map, $key)
                        else ()
                return $map
    else ()
};

declare function local:getNodeId(
  $item as xs:string
) as xs:int {
 if (map:contains($nodeIDs, $item))
 then map:get($nodeIDs, $item)
 else 
   let $count := map:count($nodeIDs)
   let $_ := map:put($nodeIDs, $item, $count)
   return $count
};

declare function local:getGrpah(
    $map as map:map
) {
     let $_:=
        for $key in map:keys($map)
        return 
            let $keys := map:get($map, $key)
            for $item at $index in $keys
            let $_:= 
              if ($index gt 1 )
              then 
                let $value := '{"source": ' || local:getNodeId($item) || ',  "target": ' || local:getNodeId($keys[$index - 1]) || "}"
                return map:put($links, xs:string(map:count($links)), $value)
              else ()
            return ()

    let $linksOutput :=  
    "[" || fn:string-join(map:keys($links) ! map:get($links, .), ",") || "]" 
    
    let $nodesOutput := 
       for $iri in map:keys($nodeIDs)
       let $number :=  map:get($nodeIDs, $iri)
       let $label  :=  semantics:get-label($iri)
       order by $number
       return '{ "iri": "' || $iri || '", "label": "' ||  $label ||'"}'
    
    return  
     ( 
       '{"links":' ||  $linksOutput || ",", 
       '"nodes": [' ||  fn:string-join($nodesOutput, ",") || "]}" 
     )
  
};

let $transitiveClosure := local:getTransitiveClosure($subject, $target)
return
  <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
       
      <body xmlns="">
          <div class="container">
              <div class="row">
                  <div class="col-lg-4">
                      <form class="form-inline" method="get" action="relate/">
                          <p class="input-group">
                              <div class="scrollable-dropdown-menu">
                                <input name="subject" value="{ $subject }" type="text" class="form-control typeahead"/>
                              </div>
                              <div class="scrollable-dropdown-menu">
                                <input name="target" value="{ $target }" type="text" class="form-control typeahead"/>
                              </div>
                          </p><!-- /input-group -->
                           <span class="input-group-btn">
                                  <button class="btn btn-default" type="submit">Relate</button>
                              </span>
                      </form>
                      <div class="container-fluid alert alert-info">
                           <h4 class="list-group-item-heading">Getting started</h4>
                           <p class="list-group-item-text">In the input boxes above, enter a term in both boxes then click relate</p>
                        </div>
                       <div class="container-fluid alert alert-info">  
                           <h4 class="list-group-item-heading">Examples</h4>
                           <ul>
                            <li><a href="?subject=Atone&amp;target=Smith%2C+Joseph+Jr.">Atone, Smith, Joseph Jr.</a></li>
                            <li><a href="?subject=Wealth&amp;target=Joy">Wealth, Joy</a></li>
                            <li><a href="?subject=Worthy&amp;target=Inspiration">Inspiration, Worthy</a></li>
                            <li><a href="?subject=Atone&amp;target=Jesus+Christ">Atone, Jesus Christ</a></li>
                            <li><a href="?subject=Teach&amp;target=Love">Teach, Love</a></li>
                            <li><a href="?subject=Family&amp;target=Love">Family, Love</a></li>
                            <li><a href="?subject=God&amp;target=Marriage">God, Marriage</a></li>
                           </ul>
                      </div>
                     
                  </div>
                  <div class="col-lg-8">
                      <div id="visualization" class="text-center" />
                  </div>

             </div>
              
          </div> <!-- /container -->

    </body>
    <script type="text/javascript">
      relate = {{}};
      relate.subject = "{fn:lower-case($subject)}";
      relate.target = "{fn:lower-case($target)}";
      relate.dataset = {if (fn:empty($transitiveClosure)) then ("undefined")  else local:getGrpah($transitiveClosure)}
    </script>
    <script type="text/javascript" src="d3.v3.min.js"></script>
    
    <script type="text/javascript" src="relate.js"></script>
   
    
  </html>