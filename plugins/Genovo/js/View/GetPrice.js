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
              'dojo/data/ItemFileReadStore'
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

      title: "Get Price",
     // width: 1000,
     // height: 300,
      priceGrid : null,
      data :null, 

      constructor: function(args) {
    //      this.width = window.screen.width*0.8;
    //      this.height = window.screen.height*0.64;
          this.browser = args.browser;


          this.defaultContent = this._makeDefaultContent();

          if( ! args.content && ! args.href ) {
              // make a div containing our help text
              this.content = this.defaultContent;
          }

      },

      show: function() {
            var that = this;
              //$("body").addClass("user_select_none");
             /*
              window.onresize = function() {
                appContainer.layout();
                };*/
           //     this._makeMenu();
        	this.inherited( arguments );
        	on(that, "hide", function() {
          //  this.priceGrid.destroyRecursive(true);
        	})
        	
      },

      _makeDefaultContent: function() {
      	var that = this;
          var appContainer = this.appContainer = new BorderContainer({

                style: "height: " + 300 + "px; width: " + 250 + "px;"
              });

          var inputvalue = 	dojo.create("input", {
                  						id: 'enzymesValue',
                  						type: 'text',
                  						value: 'SspI',
                  						size: 25,
                  					});
          var inputbutton = dojo.create('button', {
          		id: 'submitenzymes',
          		type: 'button',
          		innerText: 'Get Price of enzymes',
          		onclick: function () {
                var progress = dijit.byId("globalProgress").set("label", "Geting price From Internt...");
                progress.set("indeterminate", true);
          			var enzymes = inputvalue.value;
          			dojo.xhrGet({
          				url: 'server/toolsManager.php?GetPrice=1&enzyme='+enzymes,
          				handleAs: 'json',
          				load: function( msg ) {
          						console.log(msg);
          						that.data.items = [];
          						msg = msg.slice(1);
          						for ( var v in msg ) {
          							console.log(msg[v]);
          							var a = msg[v].split('\t');
          							that.data.items.push({
          								catalog: a[1],
          								size: a[2],
          								price: a[3]
          							});
          						}
          						var newStore = new ItemFileReadStore({ data: that.data});
          						that.priceGrid.setStore(newStore);
                      progress = dijit.byId("globalProgress").set("label", "DANG.DANG. price GOT...");
                      progress.set("indeterminate", false);
          				}
          			})
          		}
          });
          inputbutton.innerText = 'Get Price of enzymes';
          this.data = {
          	identifier: "catalog",
          	items:[]
          };

          var store = new ItemFileReadStore( {data: this.data});
         	var layout = [[
         		{'name': 'Catalog', 'field': 'catalog'},
         		{'name': 'Size', 'field': 'size'},
         		{'name': 'Price', 'field':'price'}
         	]]
          this.priceGrid = new DataGrid({
          	id: 'priceGrid',
          	store: store,
          	structure: layout
          });
     
             var inputBar = new ContentPane({
                  id: "inputBar",
                  region: "top",
                  content: [
                  	inputvalue,
                  	inputbutton,
                  ]
                  //style: "height:" + this.height + "%, width: " + this.width + "%"
                 // content: dojo.create("div", {id: "svg_", style: "height: 100%, width: 100%"}),
              });
	     				var contentBox = new ContentPane({
	     						id: "PriceBox",
	     						region: "center",
	     						content: this.priceGrid.domNode
							});

              appContainer.addChild(inputBar);
              appContainer.addChild(contentBox);

           //   document.onselectstart=function(){return false}
              //Firefox、Chrome、Safaria
           //   d3.select('body').classed('user_select_none', true);

              return appContainer.domNode;
      }
  });
  });
