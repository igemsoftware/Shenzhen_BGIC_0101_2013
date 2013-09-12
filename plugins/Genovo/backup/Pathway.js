  define( [
              'dojo/_base/declare',
              'JBrowse/View/InfoDialog',
              "dijit/layout/BorderContainer", 
              "dijit/layout/ContentPane", 
              "dojo/dom-class",
              "dojo/dom-attr", 
              "dojo/dom", 
              "dojo/dnd/Source", 
              "dojo/topic", 
              "dijit/form/DropDownButton", 
              "dijit/DropDownMenu", 
              "dijit/MenuItem", 
              "dijit/PopupMenuItem", 
              "dijit/Menu",
              "dojo/aspect"
          ],
          function(
              declare,
              InfoDialog,
              BorderContainer, 
              ContentPane, 
              domClass, 
              domAttr, 
              dom, 
              Source, 
              topic, 
              DropDownButton, 
              DropDownMenu, 
              MenuItem, 
              PopupMenuItem, 
              Menu,
              aspect
          ) {
  return declare( InfoDialog, {

      title: "Pathway",

      constructor: function(args) {
          this.browser = args.browser;
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
                    console.log(msg);
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
                

                var button = new DropDownButton({
                  label: "Select Path way",
                  name: "dropdown",
                  dropDown: menu,
                  id: "dropdownMenu"
                })
                dom.byId("dropMenuContainer").appendChild(button.domNode);
              },
    _makePopMenu: function() {


    },
      _makeSubMenu: function( argv ) {
              var that = argv.that;
              return new MenuItem( {
                  label: argv.pathway,
                  onClick: dojo.hitch(that, function() {
                    dojo.xhrGet({
                      url: "server/tools/toolsManager.php",
                      handleAs: "json",
                        content: {
                            'species':argv.species,
                            'pathway':argv.pathway
                        },
                      load: function(msg) {
                        //this.catalog.clearItems();
                        console.log(msg);
                        
                        that.catalog.selectAll();
                        that.catalog.deleteSelectedNodes();
                        for (var geneid in msg) {
                          that.catalog.insertNodes(false, [{data: msg[geneid], type: ["gene"]}]);
                        }
                        that.catalog.forInItems(function(item, id, map){
                          domClass.add(id, item.type[0]);
                        });
                        //this.catalog.insertNodes(false, {})})
                      }
                    });
                    return true;
                  })
                });

      },


      show: function() {
              var that = this;
              var catalog = this.catalog = new Source("genelistNode",
                    { 
                      accept: [ "gene"], 
                      creator: function( item, hint ) {
                        var div = dojo.create("li", {innerHTML: item.data||item});
                        console.log(div+ item.data||item);
                        return {node: div, data: item, type: ['gene']};
                      } 
                    });
                catalog.insertNodes(false, [
                    { data: "Wrist watch",        type: [ "gene" ] },
                    { data: "Life jacket",        type: [ "gene" ] },
                    { data: "Toy bulldozer",      type: [ "gene" ] },
                    { data: "Vintage microphone", type: [ "gene" ] },
                    { data: "TIE fighter",        type: [ "gene" ] },
                    { data: "Apples",             type: [ "gene" ] },
                    { data: "Bananas",            type: [ "gene" ] },
                    { data: "Tomatoes",           type: [ "gene" ] },
                    { data: "Bread",              type: [ "gene" ] }
                ]);
                catalog.forInItems(function(item, id, map){
                    domClass.add(id, item.type[0]);

                });
                
                topic.subscribe("/dnd/start", function() {
                  console.log("start received: ", arguments);
                })
                topic.subscribe("/dnd/drop", function() {
                  cart.forInItems( function(item, id, map) {
                      domClass.add(id, "PathwayfloatGene");
                  });
                  console.log("drop received: ", arguments);
                })

                function floatCreator( item, hint ) {
                  var li = dojo.create("li", {innerHTML: item.data==undefined?item:item.data, class: "PathwayfloatGene"});
                  console.log("creator: " + item.data);
                  console.log([item])
                  return {node: li, data: item.data==undefined ? item:item.data, type: ['gene']};
                }

                var cart = new Source(this.workplace.domNode, {
                                        accept: [ "gene" ],
                                        creator: floatCreator});
          /*
              window.onresize = function() {
                appContainer.layout();
                };*/
                this._makeMenu();
        this.inherited( arguments );


        aspect.after( that, 'hide', dojo.hitch( that, function() {
                               setTimeout( function() { that.destroyRecursive(); }, 500 );
                        }));
      },

      _makeDefaultContent: function() {
          var appContainer = this.appContainer = new BorderContainer({
                style: "height: 300px; width: 1000px;"
              });


               var menu =new ContentPane({
                  id: "pathwaymenu",
                  region: "top",
                  style: "height: 2em",
                  content: dojo.create("div", {id: "dropMenuContainer"}),
                  splitter: true
               });


               appContainer.addChild(menu);

              // create a ContentPane as the left pane in the BorderContainer
              var navigator = new ContentPane({
                  id: "pathwaynavigator",
                  region: "left",
                  style: "width: 20%",
                  splitter: true, 
              });
              navigator.setContent(dojo.create("ol", {id: "genelistNode"}));
              appContainer.addChild(navigator);

              // create a ContentPane as the center pane in the BorderContainer
              var workplace = this.workplace = new ContentPane({
                  id: "pathwayworkplace",
                  region: "center",
                  class: "floatWorkplace"
              });
              appContainer.addChild(workplace);
              return appContainer.domNode;
      }
  });
  });
