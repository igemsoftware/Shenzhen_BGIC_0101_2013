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
              'dojo/dom',
              'dojox/grid/DataGrid',
              'dojo/data/ItemFileReadStore',
              'dojox/grid/_CheckBoxSelector',
              './jquery-1.7.2'
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
              DataGrid,
              ItemFileReadStore
          ) {
  return declare( InfoDialog, {

      title: "",
     // width: 1000,
     // height: 300,
      featuresGrid : null,
      data :null, 
      callback: null,
      updatebutton: null,
      backupmsg: null,

      constructor: function(args) {
    //      this.width = window.screen.width*0.8;
    //      this.height = window.screen.height*0.64;
          this.browser = args.browser;

          this.title = args.title;
          this.defaultContent = this._makeDefaultContent();
          this.callback = args.callback;
          if( ! args.content && ! args.href ) {
              // make a div containing our help text
              this.content = this.defaultContent;
          }

      },

      show: function() {
            var that = this;
  
        	this.inherited( arguments );
          that.updatebutton.click();
        	on(that, "hide", function() {
          //  this.featuresGrid.destroyRecursive(true);
        	})
        	
      },

      _makeDefaultContent: function() {
      	var that = this;
          var appContainer = this.appContainer = new BorderContainer({
                style: "height: " + window.screen.height*0.66 + "px; width: " + window.screen.width*0.6 + "px;"
              });

          var deleteButton = 	dojo.create("button", {
                  						id: 'deleteit',
                  						type: 'button',
                  						value: 'Delete Them',
                  						size: 25,
                              onclick: function() {
                                var highlight = that.browser.getHighlight();
                                if (highlight === null) {
                                  alert("Please Select Region use Highlight Tools");
                                  return;
                                }
                                var todelete = that.featuresGrid.selection.selected;
                                var msg = [];
                                for (var a in todelete) {
                                  if (a && todelete[a]) {
                                      msg.push(that.backupmsg[a].Name);
                                  }
                                };
                                dojo.xhrGet({
                                  url: "server/REST/index.php/features/delete",
                                  content: {
                                    features: msg.join(","),
                                    baseUrl: that.browser.config.baseUrl,
                                    start: highlight.Start,
                                    end: highlight.End,
                                    refseq: highlight.ref,
                                    dataset: that.browser.config.dataset_id
                                  },
                                  handleAs: "text",
                                  load: function(d) {
                                    console.log(d);
                                  }
                                })
                              }
                  					});
          deleteButton.innerText = "Delete Them";
          var updatebutton = that.updatebutton = dojo.create('button', {
          		id: 'featuresDelete',
          		type: 'button',
          		innerText: 'Update History',
          		onclick: function () {
                var highlight = that.browser.getHighlight();

          			dojo.xhrGet({
          				url: 'server/REST/index.php/features/SearchByLocation',
                  content: {
                    dataset: that.browser.config.dataset_id,
                    baseUrl: that.browser.config.baseUrl,
                    refseq:highlight.ref,
                    start: highlight.start,
                    end: highlight.end
                  },
          				handleAs: 'json',
          				load: function( msg ) {
          						console.log(msg);
                      that.backupmsg = msg;
          						that.data.items = [];
          						for (var i = 0; i < msg.length; i++) {
                          that.data.items.push( {
                            "features": msg[i].Name,
                            "start": msg[i].Start,
                            "end":  msg[i].End
                          });
                      }
          						var newStore = new ItemFileReadStore({ data: that.data});
          						that.featuresGrid.setStore(newStore);
          				}
          			})
          		}
          });
          updatebutton.innerText = 'Update Data';
          this.data = {
          	identifier: "start",
          	items:[]
          };

          var store = new ItemFileReadStore( {data: this.data});
         	var layout = [
            { type: "dojox.grid._CheckBoxSelector" },
          [
         		{'name': 'features Name', 'field': 'features', 'width': "auto"},
         		{'name': 'start', 'field': 'start', 'width': "auto"},
         		{'name': 'end', 'field':'end', 'width': "auto"}
         	]]
          this.featuresGrid = new DataGrid({
          	id: 'featuresGrid',
          	store: store,
          	structure: layout
          });

             var featuresBar = new ContentPane({
                  id: "featuresBar",
                  region: "top",
                  content: [
                    deleteButton,
                  	updatebutton,
                  ]
                  //style: "height:" + this.height + "%, width: " + this.width + "%"
                 // content: dojo.create("div", {id: "svg_", style: "height: 100%, width: 100%"}),
              });
	     				var contentBox = new ContentPane({
	     						id: "FeaturesBox",
	     						region: "center",
	     						content: this.featuresGrid.domNode
							});

              appContainer.addChild(featuresBar);
              appContainer.addChild(contentBox);

           //   document.onselectstart=function(){return false}
              //Firefox、Chrome、Safaria
           //   d3.select('body').classed('user_select_none', true);

              return appContainer.domNode;
      }
  });
  });
