(:
    This code was taken from the marklogic Semantics functions and was rework in order to have paths shown
:)
xquery version "1.0-ml"; 

declare function local:bfs($s as sem:iri*, $adjV) as map:map {
    let $visited := map:map()
    let $_ := $s ! map:put($visited, ., .)
    return local:bfs-inner($visited, $visited,  $adjV)
};

declare function local:bfs-inner($visited as map:map, $queue as map:map?, $adjacentVertices)  as map:map {
    if (map:count($queue) eq 0)
    then $visited
    else
        let $nextQueue := $adjacentVertices($queue)
        let $notVisted  :=
            for $key in  map:keys($nextQueue)
            return
                if (map:contains($visited, $key))
                then (map:put($visited, $key, (map:get($visited, $key), map:get($nextQueue, $key))))
                else (map:put($visited, $key, map:get($nextQueue, $key)), $key)
        let $thingstoEnqueue := map:map()
        let $_ := $notVisted ! map:put($thingstoEnqueue, ., map:get($nextQueue, .))
        return  local:bfs-inner($visited, $thingstoEnqueue, $adjacentVertices)
};

declare function local:transitive-closure(
   $seeds as sem:iri*,
   $preds as sem:iri*
) as map:map {
    local:bfs($seeds, function($queue as map:map) as map:map { 
        let $level := map:map()
       let $buildMap := 
          cts:triples( (map:keys($queue) ! sem:iri(.)) ,$preds,()) ! map:put($level,  sem:triple-object(.), fn:concat(map:get($queue, sem:triple-subject(.)), " » ", sem:triple-object(.)))
        return $level
    })
};
let $transitive-closureWithPath := 
local:transitive-closure(
   sem:iri("http://www.lds.org/concept/gs/ark"),
   sem:iri("http://www.w3.org/2004/02/skos/core#related")
) 
return map:get($transitive-closureWithPath, "http://www.lds.org/concept/gs/jesus-christ") 
 (:  map:keys( $transitive-closureWithPath ) ! map:get($transitive-closureWithPath, .) :)
