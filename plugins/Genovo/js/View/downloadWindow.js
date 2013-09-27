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

      title: "Data Download",
     // width: 1000,
     // height: 300,
      downloadGrid : null,
      data :null, 
      browser: null,

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
          
          dojo.xhrGet({
            url: "server/REST/index.php/data/info",
            content: {
              baseUrl: that.genovo.browser.config.baseUrl
            },
            handleAs: "json",
            load: function( d ) {

                      that.data.items = [];
                      var adddata = function (arr) {
                          for ( var v in arr ) {
                              that.data.items.push({
                                  file: arr[v]
                              });
                          }
                      }
                      var progress = dijit.byId("globalProgress").set("label", "Select Data ...");
                      progress.set("indeterminate", true);
                      if (d['markup'] != null ) adddata(d['markup']);
                      if (d['mini'] != null ) adddata(d['mini']);
                      if (d['mega'] != null ) {
                        for (var i in d['mega']['ID'] ) {
                          adddata([i]);
                        }
                      }
                      if (d['chip'] != null) adddata(d['chip']);
                      
                      var newStore = new ItemFileReadStore({ data: that.data});
                      that.downloadGrid.setStore(newStore);
                      progress = dijit.byId("globalProgress").set("label", "DANG.DANG. Got it...");
                      progress.set("indeterminate", false);
                  }
          })

        	this.inherited( arguments );
        	on(that, "hide", function() {
          //  this.downloadGrid.destroyRecursive(true);
        	})
        	
      },

      _makeDefaultContent: function() {
      	var that = this;
          var appContainer = this.appContainer = new BorderContainer({
                style: "height: " + 400 + "px; width: " + 500 + "px;"
              });


          this.data = {
          	identifier: "file",
          	items:[]
          };

          var store = new ItemFileReadStore( {data: this.data});
         	var layout = [[
         		{'name': 'file address', 'field': 'file', 'width':"auto"},
         	]]
          this.downloadGrid = new DataGrid({
          	id: 'filedownloadGrid',
          	store: store,
          	structure: layout
          });
     
	     				var contentBox = new ContentPane({
	     						id: "downloadBox",
	     						region: "center",
	     						content: this.downloadGrid.domNode
							});

              appContainer.addChild(contentBox);


              return appContainer.domNode;
      }
  });
  });
