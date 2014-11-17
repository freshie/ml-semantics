(:
    This code was taken from the marklogic Semantics functions and was rework in order to have paths shown
:)
xquery version "1.0-ml"; 

declare function local:bfs($s as sem:iri*, $limit as xs:int, $adjV) as map:map {
    let $visited := map:map()
    let $_ := 
      for $spart in $s 
      let $spartMap := map:map()
      let $_ := map:put($spartMap, $spart, $spart)
      return map:put($visited, $spart, $spartMap)
    let $queue :=  map:map()
    let $_ := $s ! map:put($queue, ., .)
    return local:bfs-inner($visited, $queue, $limit, $adjV)
};

declare function local:bfs-inner($visited as map:map, $queue as map:map?, $limit as xs:int, $adjacentVertices)  as map:map {
    if (map:count($queue) eq 0 or $limit le 1)
    then $visited
    else
        let $nextQueue := $adjacentVertices($queue)
        let $notVisted  :=
            for $key in  map:keys($nextQueue)
            return
                if (map:contains($visited, $key))
                then ( 
                  let $visitedMap := map:get($visited, $key)
                  let $_ := map:put($visitedMap,  xs:string(map:count($visitedMap) + 1), map:get($nextQueue, $key))
                  return 
                   map:put($visited,  $key, $visitedMap)
                )
                else 
                  let $pathMap := map:map()
                  let $_ :=  map:put($pathMap, "1", map:get($nextQueue, $key))
                  let $_ := map:put($visited, $key, $pathMap) 
                  return $key
                
        let $thingstoEnqueue := map:map()
        let $_ := $notVisted ! map:put($thingstoEnqueue, ., map:get($nextQueue, .))
        return  local:bfs-inner($visited, $thingstoEnqueue, ($limit -1), $adjacentVertices)
};

declare function local:transitive-closure(
   $seeds as sem:iri*,
   $preds as sem:iri*,
   $limit as xs:int
) as map:map {
    local:bfs($seeds, $limit, function($queue as map:map) as map:map { 
        let $level := map:map()
       let $buildMap := 
          cts:triples( (map:keys($queue) ! sem:iri(.)) ,$preds,()) ! map:put($level,  sem:triple-object(.), (map:get($queue, sem:triple-subject(.)), sem:triple-object(.)))
        return $level
    })
};
let $transitive-closureWithPath := 
local:transitive-closure(
   sem:iri("http://www.lds.org/concept/gs/ark"),
   sem:iri("http://www.w3.org/2004/02/skos/core#related"),
10
) 
return map:get($transitive-closureWithPath, "http://www.lds.org/concept/gs/jesus-christ")
 (: map:keys( $transitive-closureWithPath ) ! map:get($transitive-closureWithPath, .) :)
