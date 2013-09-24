  define( [
              'dojo/_base/declare',
              'JBrowse/View/InfoDialog',
              "dijit/layout/BorderContainer", 
              "dijit/layout/ContentPane",
              "dijit/form/DropDownButton", 
              'dijit/form/Button',
              "dijit/DropDownMenu", 
              "dijit/MenuItem", 
              "dijit/PopupMenuItem", 
              "dijit/Menu",
              "dojo/aspect",
              'dojo/on',
              "dojo/dom",
              "dijit/popup",
              'dojo/query!css2',
              './d3.v3',
              './jquery-1.7.2',
              './Tooltip'
          ],
          function(
              declare,
              InfoDialog,
              BorderContainer,
              ContentPane,
              DropDownButton, 
              Button,
              DropDownMenu, 
              MenuItem, 
              PopupMenuItem, 
              Menu,
              aspect,
              on,
              dom,
              popup
          ) {
  return declare( InfoDialog, {

      title: "Pathway",
      width: 1000,
      height: 300,
      tooltip: null,
      nodes: null,
      links: null,
      hasInstance: null,
      modify: false,
      nodemenu: null,
      restart: null,
      //force: null,
      idpool: null,
      species: null,
      pathway: null,

      constructor: function(args) {
          this.width = window.screen.width*0.8;
          this.height = window.screen.height*0.64;
          this.browser = args.browser;
          this.tooltip = Tooltip("vis-toolTip", 230);



          this.defaultContent = this._makeDefaultContent();

          if( ! args.content && ! args.href ) {
              // make a div containing our help text
              this.content = this.defaultContent;
          }

      },

      _makeMenu: function() {
                var that = this;
                var menu = new DropDownMenu({ style: "display: none"});
                
                dojo.xhrGet({
                  url: "server/tools/toolsManager.php?nav=1",
                  handleAs: "json",
                  load: function(msg) {
                  //  console.log(msg);
                    for (var species in msg) {
                      var subMenu = new Menu();
                      for (var pathway in msg[species].pathway ) {
                          subMenu.addChild(that._makeSubMenu({
                            species:msg[species].paramter,
                            pathway:msg[species].pathway[pathway],
                            "that":that,
                          }))
                      };
                      var popMenu = new PopupMenuItem({
                        label: species,
                        popup: subMenu
                      });
                      menu.addChild(popMenu);
                    }
                  }
                })
                

                var selectButton = new DropDownButton({
                  label: "Select Path way",
                  name: "dropdown",
                  dropDown: menu,
                  id: "dropdownMenu"
                })

                dom.byId("dropMenuContainer").appendChild(selectButton.domNode);
                
                var randomStrong = 10;
                var goodLuckButton = new Button({
                    label: "Good Luck",
                    stype: "right: 5em",
                    onClick: function() {
                      var randomlinks = that.links.filter( function(d) {
                          return !d.source.created && !d.target.created;
                      })
                      var randomnodes = that.nodes.filter( function(d) {
                          return d.created;
                      })
                      for (var i = 0; i < randomStrong; ++i) {
                        var idx1 = Math.floor(Math.random()*randomnodes.length);
                        var idx2 = Math.floor(Math.random()*randomnodes.length);
                        if (idx1 == idx2)
                          continue;
                        var tmp = randomnodes[idx1];
                        randomnodes[idx1] = randomnodes[idx2];
                        randomnodes[idx2] = tmp;
                      }

                      for (var i = 0; i < randomnodes.length-1; ++i) {
                        var link = that.links.filter( function(l) {
                            return (l.source === randomnodes[i]&&l.target === randomnodes[i+1])
                                || (l.target === randomnodes[i]&&l.source === randomnodes[i+1]);
                        } )[0];
                        if (link == null) {
                          that.links.push({
                            source: randomnodes[i],
                            target: randomnodes[i+1],
                            left: false,
                            right: true
                          });
                        } else {
                          link.source = randomnodes[i];
                          link.target = randomnodes[i+1];
                        }
                      }
               
                      that.restart();
                      //that.force.stop();
                      ///that.force.start();
                    }
                });

                var createButton = new Button({
                    label: "Create Genome",
                    style: "right: 5em",
                    onClick: dojo.hitch( that, function () {
                        var outputNodes = that.nodes.filter( function( n ){
                          return (n.created);
                        })

                        var outputList = that.links.filter( function( n ) {
                          return (n.target.created && n.source.created);
                        })
                        if (outputList.length == 0 || outputNodes.length == 0) {
                          return;
                        }
                        var geneorder = getGeneList(outputNodes, outputList);
                      
                        dojo.xhrGet({
                            url: "server/REST/index.php/decouple/",
                            handleAs: "text",
                            content: {
                              "species": that.species,
                              "pathway": that.pathway,
                              "geneorder"   : geneorder
                            },
                            load: function(d) {
                              console.log(d);
// TODO 
// jump to created genome 
                            }
                        })

                        /*for (var i in that.nodes) {
                          callmsg += that.nodes[i].geneName + "\t" + 
                                      (that.nodes[i].type === "circle"? "+" : "-") + "\n";
                        }*/
                        //console.log("creating Genome\n" + callmsg);
                      }
                    )
                });

                function getGeneList(nodes, links) {
                  var msg = "";
                  var target = {};
                  var nextlist = {};
                  for (var i in links) {
                    var link = links[i];
                    if ( null == nextlist[link.source.id] ) {
                      nextlist[link.source.id] = {gene: link.source, next: []};
                    }
                    nextlist[link.source.id].next.push(link.target.id);
                    target[link.source.id] = true;
                  }
                  for (var i in links) {
                    delete target[links[i].target.id];
                  }
                  for (var id in target) {
                    var source = that.findNodeById(id);
                    do {
                      //
                      msg += source.geneName + " " +
                              (source.type === "circle"? "+" : "-") + "\n";
                      source = nextlist[source.id] == null? 
                                      null : nextlist[source.id].next[0];
                      source = that.findNodeById(source)
                    } while (source != null)
                   
                  }
                  console.log(msg);
                  return msg;
                }
                dom.byId("dropMenuContainer").appendChild(goodLuckButton.domNode);
                dom.byId("dropMenuContainer").appendChild(createButton.domNode);

              },
    _makePopMenu: function() {


    },

    hashCode: function(str){
      var hash = 0;
      if (str.length == 0) return hash;
      for (i = 0; i < str.length; i++) {
          char = str.charCodeAt(i);
          hash = ((hash<<5)-hash)+char;
          hash = hash & hash; // Convert to 32bit integer
      }
      return hash;
    },


    loadPathwayData: function(argv, callback) {
      var that = argv.that;
      return function() { 
        dojo.xhrGet({
          url: "server/tools/toolsManager.php",
          handleAs: "json",
          content: {
            'species':argv.species,
            'pathway':argv.pathway
          },
          load: function(msg) {
                          //this.catalog.clearItems();
                       //   console.log(msg);
            
            that.species = argv.species;
            that.pathway = argv.pathway;

          //  that.nodes = [];
          //  that.links = [];
      
            for (var i = that.nodes.length-1; i>=0; i--) {
                if (!that.nodes[i].created) {
                  that.removeNode(that.nodes[i]);
                }
            }

            var nodes = msg.nodes;
            var links = msg.links;
            var nameID = {};

            for (var n in nodes) {
              var node = {
                id: that.idpool, 
                reflexive: false,
                x: that.width/2+(Math.random()-1)*that.width/2, 
                y: that.height*0.6*Math.random(),
                geneName: nodes[n],
                type: "circle"
              };
              that.nodes.push(node);
              nameID[node.geneName] = that.idpool++;
            }
            for (var v in links) {
              var n = links[v];
              for (var u in n) {
                var source = that.findNodeById(nameID[v]);
                that.links.push( {
                  source: source, 
                  target: that.findNodeById(nameID[n[u]]),
                  left: false,
                  right: true
                });
              }
            }
            callback();
          }
        });
      }
    },

    removeNode: function( node ) {
      this.nodes.splice(this.nodes.indexOf(node), 1);
      this.spliceLinksForNode(node);
    },

    findNodeById: function( id ) {
      for (var v in this.nodes) {
        if (this.nodes[v]['id'] == id) {
          return this.nodes[v];
        }
      }
    },

    _makeSubMenu: function( argv ) {
              var that = argv.that;
            //  that.species = argv.species;
            //  that.pathway = argv.pathway;
              return new MenuItem( {
                  label: argv.pathway,
                  onClick: that.loadPathwayData(argv, function() {
                        //d3.select('svg').remove();
                        //that.buildsvg();
                        that.restart();
                       
                  })
/*
                   dojo.hitch(that, function() {
                    dojo.xhrGet({
                      url: "server/tools/toolsManager.php",
                      handleAs: "json",
                        content: {
                            'species':argv.species,
                            'pathway':argv.pathway
                        },
                      load: function(msg) {
                        //this.catalog.clearItems();
                     //   console.log(msg);
                        that.nodes = [];
            						that.links = [];
            						var hash = {};
            						var nodes = msg.nodes;
            						var links = msg.links;
            						for (var n in nodes) {
            							that.nodes.push({id:parseInt(n), reflexive: false,
            									x: that.width/2+(Math.random()-1)*that.width/2, 
                              y: that.height*0.6*Math.random(),
            									geneName: nodes[n],
                              type: "circle"
                            });
            							hash[nodes[n]] = n;
            						}
            						for (var v in links) {
            							var n = links[v];
            							for (var u in n) {
            								that.links.push({source: that.nodes[ hash[ v ] ], 
            										 target: that.nodes[ hash[ n[u] ] ],
            										 left: false,
            										 right: true});
            							}
            						}
            						d3.select('svg').remove();
            						that.buildsvg();
                      }
                    });
                    return true;
                  })
  */
                });

      },

      

      buildsvg: function() {
            var that = this;
            var svg = d3.select('#svgPane')
                        .append('svg')
                        .attr("id", 'pathwaySVG')
                        .attr("width", "100%")
                        .attr("height", "99%");
            var width = this.width;
                height =  this.height,
                colors = d3.scale.category10();

            var nodes = that.nodes || [
                {id: 0, reflexive: false, 
                      x: width/2+(Math.random()-1)*width/2, 
                      y: height*0.6*Math.random(),
                      type: "square" 
                    },
                {id: 1, reflexive: true , 
                      x: width/2+(Math.random()-1)*width/2, 
                      y: height*0.6*Math.random(),
                      type: "circle"
                    },
                {id: 2, reflexive: false, 
                      x: width/2+(Math.random()-1)*width/2, 
                      y: height*0.6*Math.random(),
                      type: "square"
                    }
            ];
            that.idpool+=10;
            that.nodes = nodes;
            var links = that.links || [
                {source: nodes[0], target: nodes[1], left: false, right: true },
                {source: nodes[1], target: nodes[2], left: false, right: true }
            ];

            that.links = links;

            // init D3 force layout
            var force = that.force = d3.layout.force()
                .nodes(that.nodes)
                .links(that.links)
                .size([width, height])
                .linkDistance(50)
                .charge(0)
                .gravity(0)
                .on('tick', tick)

            // define arrow markers for graph links
            svg.append('svg:defs').append('svg:marker')
                .attr('id', 'end-arrow')
                .attr('viewBox', '0 -5 10 10')
                .attr('refX', 6)
                .attr('markerWidth', 3)
                .attr('markerHeight', 3)
                .attr('orient', 'auto')
              .append('svg:path')
                .attr('d', 'M0,-5L10,0L0,5')
                .attr('fill', '#000');

            svg.append('svg:defs').append('svg:marker')
                .attr('id', 'start-arrow')
                .attr('viewBox', '0 -5 10 10')
                .attr('refX', 4)
                .attr('markerWidth', 3)
                .attr('markerHeight', 3)
                .attr('orient', 'auto')
              .append('svg:path')
                .attr('d', 'M10,-5L0,0L10,5')
                .attr('fill', '#000');

            // line displayed when dragging new nodes
            var drag_line = svg.append('svg:path')
              .attr('class', 'link dragline hidden')
              .attr('d', 'M0,0L0,0');

            // handles to link and node element groups
            var path = svg.append('svg:g').selectAll('path'),
                circle = svg.append('svg:g').selectAll('g');

            var splitline = svg.append('svg:line')
                                .attr("x1", 0)
                                .attr("x2", width)
                                .attr("y1", height*0.6)
                                .attr("y2", height*0.6)
                                .attr("stroke-width", 14)
                                .attr("stroke", "black");
            // mouse event vars
            var selected_node = null,
                selected_link = null,
                mousedown_link = null,
                mousedown_node = null,
                mouseup_node = null;

            function resetMouseVars() {
              mousedown_node = null;
              mouseup_node = null;
              mousedown_link = null;
            }

            // update force layout (called automatically each iteration)
            function tick() {
              // draw directed edges with proper padding from node centers
     
              path.attr('d', function(d) {
                var deltaX = d.target.x - d.source.x,
                    deltaY = d.target.y - d.source.y,
                    dist = Math.sqrt(deltaX * deltaX + deltaY * deltaY),
                    normX = deltaX / dist,
                    normY = deltaY / dist,
                    sourcePadding = d.left ? 17 : 12,
                    targetPadding = d.right ? 17 : 12,
                    sourceX = d.source.x + (sourcePadding * normX),
                    sourceY = d.source.y + (sourcePadding * normY),
                    targetX = d.target.x - (targetPadding * normX),
                    targetY = d.target.y - (targetPadding * normY);
                return 'M' + sourceX + ',' + sourceY + 'L' + targetX + ',' + targetY;
              });

              circle
             //   .each(collide(.5)) 
                .attr('transform', function(d) {
                  if (!d.created) {
                    return 'translate(' + d.x + ',' + Math.min(d.y, 0.6*height-10) + ')';
                  } else {
                    //console.log(d)
                    var y = Math.min( Math.max(0.6*height+10, d.y), height );
                    return 'translate(' + d.x + ',' + y + ')';
                  }
                });

            }
            // update graph (called when needed)
            var restart = that.restart = function() {
              // path (link) group

              nodes = that.nodes;
              links = that.links;
              //path = svg.selectAll("path").data(links);
              
              path = path.data(links);

              // update existing links
              path.classed('selected', function(d) { return d === selected_link; })
                .style('marker-start', function(d) { return d.left ? 'url(#start-arrow)' : ''; })
                .style('marker-end', function(d) { return d.right ? 'url(#end-arrow)' : ''; });


              // add new links
              path.enter().append('svg:path')
                .attr('class', 'link')
                .classed('selected', function(d) { return d === selected_link; })
                .style('marker-start', function(d) { return d.left ? 'url(#start-arrow)' : ''; })
                .style('marker-end', function(d) { return d.right ? 'url(#end-arrow)' : ''; })
                .on('mousedown', function(d) {
                  if(d3.event.ctrlKey) return;

                  // select link
                  mousedown_link = d;
                  if(mousedown_link === selected_link) selected_link = null;
                  else selected_link = mousedown_link;
                  selected_node = null;
                  restart();
                });

              // remove old links
              path.exit().remove();

              // circle (node) group
              // NB: the function arg is crucial here! nodes are known by id, not by index!
              //circle = svg.selectAll('g').data(nodes);
              circle = circle.data(nodes, function(d) { return d.id; });

              // update existing nodes (reflexive & selected visual states)
              circle.selectAll('path')
                .style('fill', function(d) { return (d === selected_node) ? 
                        d3.rgb(colors(d.id)).brighter().toString() : colors(d.id); })
                .classed('reflexive', function(d) { return d.reflexive; })
                .attr('d', d3.svg.symbol().type( 
                      function(d) { //console.log(d.type); 
                        return d.type;
                      }).size(400)
                );

              // add new nodes
              var g = circle.enter().append('svg:g');

              g.append('svg:path')
                .attr('class', 'pathwaynode')
                //.attr('r', 12)
                //.attr('size', 25)
                .attr('d', d3.svg.symbol().type( 
                      function(d) { //console.log(d.type); 
                        return d.type;
                      }).size(400)
                )
                .style('fill', function(d) { 
                               // console.log( d.color + " or " + colors(d.id) );
                                return d.color?d.color : d.color=colors(d.id);
                                        //return (d === selected_node) ? d3.rgb(d.color).brighter().toString() : d.color; 
                                      })
                .style('stroke', function(d) { return d3.rgb(colors(d.id)).darker().toString(); })
                .classed('reflexive', function(d) { return d.reflexive; })
                .on('mouseover', function(d) {
                  if(!mousedown_node || d === mousedown_node) return;
                  // enlarge target node
                  d3.select(this).attr('transform', 'scale(1.1)');
                })
                .on('mouseout', function(d) {
                  if(!mousedown_node || d === mousedown_node) return;
                  // unenlarge target node
                  d3.select(this).attr('transform', '');
                })
                .on('mousedown', function(d) {
                  if(d3.event.ctrlKey) return;
       
                //  console.log(d3.event);
/*
                  if (d3.event.which == 3) {
                    if (that.nodemenu == null) {
                      that._makeDropDownNodeMenu();
                    }
                    console.log(this);
                    var thatnode = this;
                    popup.open( {
                        x: thatnode.getBoundingClientRect().left+10,
                        y: thatnode.getBoundingClientRect().top,
                        popup: that.nodemenu,
                        onExecute: function() {
                          popup.close(that.nodemenu);
                        },
                        onCancel: function() {
                          popup.close(that.nodemenu);
                        },
                        
                      } );

                    return false;
                  }*/
                  if (d3.event.which != 1) return;
                  if (d3.event.shiftKey ) {

                    d.type = d.type === "square" ?  "circle" : "square";
                    restart();
                  }
                  //console.log(d3.event);
               //   d.type = d.type === "square" ?  "circle" : "square";
                  // select node
                  mousedown_node = d;

                  if ( mousedown_node === selected_node && !d.created) {
                    
                    //if (have.length < 2) {
              
                    var cnode = { id : that.idpool++, 
                                    reflexive : false,
                                    x : d.x,
                                    y : height*0.6+d.y*0.4*Math.random()+10,
                                    color : d.color,
                                    geneName: d.geneName,
                                    created : true,
                                    type: d.type
                                  }

                      //console.log(cnode.y);
                    nodes.push(cnode);
                     // restart();
                    //}
                  }


                  //if(mousedown_node === selected_node) selected_node = null;
                  //else 
                  selected_node = mousedown_node;
                  selected_link = null;

                  // reposition drag line
                  drag_line
                    .style('marker-end', 'url(#end-arrow)')
                    .classed('hidden', false)
                    .attr('d', 'M' + mousedown_node.x + ',' + mousedown_node.y + 'L' + mousedown_node.x + ',' + mousedown_node.y);

                  restart();
                })
                .on('mouseup', function(d) {
                  if(!mousedown_node) return;

                  // needed by FF
                  drag_line
                    .classed('hidden', true)
                    .style('marker-end', '');

                  // check for drag-to-self
                  mouseup_node = d;


                  if(mouseup_node === mousedown_node) { resetMouseVars(); return; }

                  // unenlarge target node
                  d3.select(this).attr('transform', '');

                  // add link to graph (update if exists)
                  // NB: links are strictly source < target; arrows separately specified by booleans
                  var source, target, direction;
                 // if(mousedown_node.id < mouseup_node.id) {
                    source = mousedown_node;
                    target = mouseup_node;
                    if ( !source.created || !target.created) {
                        resetMouseVars(); return;
                    }
                    direction = 'right';
                  /*
                  } else {
                    source = mouseup_node;
                    target = mousedown_node;
                    direction = 'left';
                  }*/

                  var link;
                  link = links.filter(function(l) {
                    return (l.source === source && l.target === target) || 
                            (l.target === source && l.source === target);
                  })[0];

                  if(link) {
                    link.source = source;
                    link.target = target;
                    link[direction] = true;
                  } else {
                    link = {source: source, target: target, left: false, right: false};
                    link[direction] = true;
                    links.push(link);
                  }

                  // select new link
                  selected_link = link;
                  selected_node = null;
                  restart();
                });

              // show node IDs
              g.append('svg:text')
                  .attr('x', 0)
                  .attr('y', 4)
                  .attr('class', 'pathwaytext')
                  .text(function(d) { return d.geneName; });

              // remove old nodes
              circle.exit().remove();

              // set the graph in motion
              force.start();

             
              d3.selectAll(".pathwaynode").on("mouseover", showDetails)
                .on("mouseout", hideDetails);

            }
            /*
            function mousedown() {
              // prevent I-bar on drag
              //d3.event.preventDefault();
              
              // because :active only works in WebKit?
              svg.classed('active', true);

              if(d3.event.ctrlKey || mousedown_node || mousedown_link) return;

              // insert new node at point
              var point = d3.mouse(this),
                  node = {id: ++lastNodeId, reflexive: false};
              node.x = point[0];
              node.y = point[1];
              nodes.push(node);

              restart();
            }
            */
            function mousemove() {
              if(!mousedown_node) return;

              // update drag line
              drag_line.attr('d', 'M' + mousedown_node.x + ',' + mousedown_node.y + 'L' + d3.mouse(this)[0] + ',' + d3.mouse(this)[1]);

              restart();
            }

            function mouseup() {
              if(mousedown_node) {
                // hide drag line
                drag_line
                  .classed('hidden', true)
                  .style('marker-end', '');
              }

              // because :active only works in WebKit?
              svg.classed('active', false);

              // clear mouse event vars
              resetMouseVars();
            }

            

            // only respond once per keydown
            var lastKeyDown = -1;

            function keydown() {
              d3.event.preventDefault();

              if(lastKeyDown !== -1) return;
              lastKeyDown = d3.event.keyCode;

              // ctrl
              if(d3.event.keyCode === 17) {
                circle.call(force.drag);
                svg.classed('ctrl', true);
              }

              if(!selected_node && !selected_link) return;
              switch(d3.event.keyCode) {
                case 8: // backspace
                case 46: // delete
                  if(selected_node) {
                    nodes.splice(nodes.indexOf(selected_node), 1);
                    that.spliceLinksForNode(selected_node);
                  } else if(selected_link) {
                    links.splice(links.indexOf(selected_link), 1);
                  }
                  selected_link = null;
                  selected_node = null;
                  restart();
                  break;
                case 66: // B
                  if(selected_link) {
                    // set link direction to both left and right
                    selected_link.left = true;
                    selected_link.right = true;
                  }
                  restart();
                  break;
                case 76: // L
                  if(selected_link) {
                    // set link direction to left only
                    selected_link.left = true;
                    selected_link.right = false;
                  }
                  restart();
                  break;
                case 82: // R
                  if(selected_node) {
                    // toggle node reflexivity
                    selected_node.reflexive = !selected_node.reflexive;
                  } else if(selected_link) {
                    // set link direction to right only
                    selected_link.left = false;
                    selected_link.right = true;
                  }
                  restart();
                  break;
              }
            }

            function keyup() {
              lastKeyDown = -1;

              // ctrl
              if(d3.event.keyCode === 17) {
                circle
                  .on('mousedown.drag', null)
                  .on('touchstart.drag', null);
                svg.classed('ctrl', false);
              }
            }

            var that = this;

            function hideDetails(d, i) {
                that.tooltip.hideTooltip()
            }

            function showDetails(d, i) {
              //console.log("asdasda");
                content = '<p class="main">' + d.id + '</span></p>'
                content += '<hr class="tooltip-hr">'
                content += '<p class="main">' + d.geneName + '</span></p>'
                that.tooltip.showTooltip(content,d3.event)
                
            }
/*
            // app starts here
            function collide(alpha) {
              var quadtree = d3.geom.quadtree(that.nodes);
              return function(d) {
                var r = //d.size + 
                        20+10,
                    nx1 = d.x - r,
                    nx2 = d.x + r,
                    ny1 = d.y - r,
                    ny2 = d.y + r;
                quadtree.visit(function(quad, x1, y1, x2, y2) {
                  if (quad.point && (quad.point !== d)) {
                    var x = d.x - quad.point.x,
                        y = d.y - quad.point.y,
                        l = Math.sqrt(x * x + y * y),
                        r = //d.radius + 
                          20+quad.point.radius + (d.color !== quad.point.color);
                    if (l < r) {
                      l = (l - r) / l * alpha;
                      d.x -= x *= l;
                      d.y -= y *= l;
                      quad.point.x += x;
                      quad.point.y += y;
                    }
                  }
                  return x1 > nx2
                      || x2 < nx1
                      || y1 > ny2
                      || y2 < ny1;
                });
              };
            }
*/
            svg//.on('mousedown', mousedown)
              .on('mousemove', mousemove)
              .on('mouseup', mouseup);
            d3.select(window)
              .on('keydown', keydown)
              .on('keyup', keyup);
            restart();

      },

      spliceLinksForNode: function(node) {
              var that = this;
              var toSplice = this.links.filter(function(l) {
                return (l.source === node || l.target === node);
              });
              toSplice.map(function(l) {
                that.links.splice(that.links.indexOf(l), 1);
              });
      },

      _makeDropDownNodeMenu: function() {
     
      },

      build: function() {
        if (!this.hasInstance) {
              this.buildsvg();
              this._makeMenu();
              this.hasInstance = true;
              this._makeDropDownNodeMenu();
        }
      },

      show: function() {
            var that = this;
            this.build();
              //$("body").addClass("user_select_none");
             /*
              window.onresize = function() {
                appContainer.layout();
                };*/
           //     this._makeMenu();
        this.inherited( arguments );
        /*
        on(that, "hide", function() {
            d3.select("#svgPane > svg").remove();
            console.log("remove");
        })
  */

/*
        aspect.after( that, 'hide', dojo.hitch( that, function() {
                               setTimeout( function() { d3.select("svgPane").remove(); }, 500 );
                        }));
*/  
      },

      _makeDefaultContent: function() {
          this.idpool = 1;
          var appContainer = this.appContainer = new BorderContainer({
                style: "height: " + this.height + "px; width: " + this.width + "px;"
              });

              var menuBar = new ContentPane({
                  id: "menuBar",
                  region: "top",
                  style: "height:2.5em",
                  content: dojo.create("div", {id: "dropMenuContainer"})
              });

              var svg = new ContentPane({
                  id: "svgPane",
                  region: "center",
                  //style: "height:" + this.height + "%, width: " + this.width + "%"
                 // content: dojo.create("div", {id: "svg_", style: "height: 100%, width: 100%"}),
              });


              appContainer.addChild(menuBar);
              appContainer.addChild(svg);

              document.onselectstart=function(){return false}
              //Firefox、Chrome、Safaria
              d3.select('body').classed('user_select_none', true);

              return appContainer.domNode;
      }
  });
  });
