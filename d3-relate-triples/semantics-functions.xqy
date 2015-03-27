module namespace semantics = "d3.relate.semantics-functions";

declare namespace sem = "http://marklogic.com/semantics";

declare variable $nodeIDs := map:map();
declare variable $links := map:map();

declare function semantics:getTransitiveClosure(
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

declare function semantics:getSubjectByLabel(
    $label as xs:string
) as xs:string?  {
  
    cts:search(
        /sem:triples/sem:triple,
        cts:and-query((
          cts:element-value-query(xs:QName("sem:object"), $label, "case-insensitive"),
          cts:element-value-query(xs:QName("sem:predicate"), "http://www.w3.org/2004/02/skos/core#prefLabel", "exact"),
        ))
        
      )[1]/sem:subject/xs:string(.)
 
};

declare function semantics:getNodeId(
  $item as xs:string
) as xs:int {
 if (map:contains($nodeIDs, $item))
 then map:get($nodeIDs, $item)
 else 
   let $count := map:count($nodeIDs)
   let $_ := map:put($nodeIDs, $item, $count)
   return $count
};

declare function semantics:getGrpah(
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
                let $value := '{"source": ' || semantics:getNodeId($item) || ',  "target": ' || semantics:getNodeId($keys[$index - 1]) || "}"
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

declare function semantics:bfs(
  $s as sem:iri*, 
  $limit as xs:int, 
  $adjV
) as map:map {
    let $visited := map:map()
    let $_ := 
      for $spart in $s 
      let $spartMap := map:map()
      let $_ := map:put($spartMap, $spart, xs:string($spart))
      return map:put($visited, $spart, $spartMap)
    let $queue :=  map:map()
    let $_ := $s ! map:put($queue, ., xs:string(.))
    return semantics:bfs-inner($visited, $queue, $limit, $adjV)
};

declare function semantics:bfs-inner(
  $visited as map:map, 
  $queue as map:map?, 
  $limit as xs:int, 
  $adjacentVertices
)  as map:map {
    if (map:count($queue) eq 0 or $limit le 1)
    then $visited
    else
        let $nextQueue := $adjacentVertices($queue)
        let $notVisted  :=
            for $key in  map:keys($nextQueue)
            let $path := map:get($nextQueue, $key)
            return
                if (map:contains($visited, $key))
                then
                  let $visitedMap := map:get($visited, $key)
                  let $_ := map:put($visitedMap,  xs:string(map:count($visitedMap)), $path)
                  let $_ := map:put($visited,  $key, $visitedMap)
                  return ()
                else 
                  let $pathMap := map:map()
                  let $_ := map:put($pathMap, "0", $path)
                  let $_ := map:put($visited, $key, $pathMap) 
                  return $key
        let $thingstoEnqueue := map:map()
        let $_ := $notVisted ! map:put($thingstoEnqueue, ., map:get($nextQueue, .))
        return  semantics:bfs-inner($visited, $thingstoEnqueue, ($limit -1), $adjacentVertices)
};

declare function semantics:transitive-closure(
   $seeds as sem:iri*,
   $preds as sem:iri*,
   $limit as xs:int
) as map:map {
    semantics:bfs($seeds, $limit, function($queue as map:map) as map:map { 
       let $level := map:map()
       let $_ := cts:triples( (map:keys($queue) ! sem:iri(.)) ,$preds,()) ! map:put($level,  sem:triple-object(.), (map:get($queue, sem:triple-subject(.)), sem:triple-object(.)))
       return $level
    })
};