
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
                then ()
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
          for $triple in cts:triples( (map:keys($queue) ! sem:iri(.)) ,$preds,())
          let $_ := map:put($level,  sem:triple-object($triple), fn:concat(map:get($queue, sem:triple-subject($triple)), " » ", sem:triple-object($triple)))
          return sem:triple-subject($triple) 
        return $level
    })
};
let $transitive-closureWithPath := 
local:transitive-closure(
   sem:iri("http://www.lds.org/concept/gs/ark"),
   sem:iri("http://www.w3.org/2004/02/skos/core#related")
) 
return  map:get($transitive-closureWithPath, "http://www.lds.org/concept/gs/mary-mother-of-jesus") 
(:map:keys( $transitive-closureWithPath ) ! map:get($transitive-closureWithPath, .):)