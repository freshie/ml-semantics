if (typeof relate.dataset !== "undefined"){
  //Width and height
  var w = 550;
  var h = 400;

  //Initialize a default force layout, using the nodes and edges in dataset
  var force = d3.layout.force()
             .nodes(relate.dataset.nodes)
             .links(relate.dataset.links)
             .size([w, h])
             .linkDistance([40])
             .charge([-1000])
              //.linkDistance([50])
              //.linkStrength(15)
              .friction(.75)
              //.distance(120)
              //.charge(-1000)
              .gravity(.25)
              //.theta(76)
              //.alpha(5555)
             .start();

  //Create SVG element
  var svg = d3.select("body").select("#visualization")
        .append("svg")
        .attr("width", w)
        .attr("height", h);

  //Create edges as lines
  var edges = svg.selectAll("line")
    .data(relate.dataset.links)
    .enter()
    .append("line")
    .style("stroke", "#333")
    .style("stroke-width", 1);

  var node = svg.selectAll(".node")
    .data(relate.dataset.nodes)
    .enter().append("g")
    .attr("class", "node")
    
    .call(force.drag);

   node.append("circle")
   .attr("r", 15) 
   .style("fill", pickColor) 

   node.append("text")
   .attr("dx", 15)
   .attr("dy", ".33em")
   .text(function(d) { return d.label });



  //Every time the simulation "ticks", this will be called
  force.on("tick", function() {

    edges.attr("x1", function(d) { return d.source.x; })
       .attr("y1", function(d) { return d.source.y; })
       .attr("x2", function(d) { return d.target.x; })
       .attr("y2", function(d) { return d.target.y; });

     node.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });

  });

  function pickColor (d, i){
    var lowerCase = d.label.toLowerCase()
    if (lowerCase  === relate.subject || lowerCase  === relate.target ){
      return "#5cb85c"
     } else {
       return "#428bca"
    }
  }

}