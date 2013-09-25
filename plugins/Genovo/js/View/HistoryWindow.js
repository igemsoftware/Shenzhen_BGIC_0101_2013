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

      title: "Edit History",
     // width: 1000,
     // height: 300,
      updateButton: null,
      historyGrid : null,
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
            that.updateButton.click();
              //$("body").addClass("user_select_none");
             /*
              window.onresize = function() {
                appContainer.layout();
                };*/
           //     this._makeMenu();
          	this.inherited( arguments );
          	on(that, "hide", function() {
            //  this.historyGrid.destroyRecursive(true);
          	})
        	
      },

      _makeDefaultContent: function() {
      	var that = this;
          var appContainer = this.appContainer = new BorderContainer({
                style: "height: " + window.screen.height*0.66 + "px; width: " + window.screen.width*0.6 + "px;"
              });

          var inputvalue = 	dojo.create("input", {
                  						id: 'historyvalue',
                  						type: 'text',
                  						value: 'SspI',
                  						size: 25,
                  					});
          var updateButton = that.updateButton = dojo.create('button', {
          		id: 'updateHistory',
          		type: 'button',
          		innerText: 'Update History',
          		onclick: function () {
          			dojo.xhrGet({
          				url: 'server/REST/index.php/stats/version/'
                        +that.browser.config.dataset_id,
          				handleAs: 'json',
          				load: function( msg ) {
          						console.log(msg);
          						that.data.items = [];
          						for (var i = 0; i < msg.length; i+=3) {
                          that.data.items.push( {
                            "hashcode": msg[i],
                            "date": msg[i+1],
                            "msg":  msg[i+2]
                          });
                      }
          						var newStore = new ItemFileReadStore({ data: that.data});
          						that.historyGrid.setStore(newStore);
          				}
          			})
          		}
          });
          updateButton.innerText = 'update History Now';
          this.data = {
          	identifier: "hashcode",
          	items:[]
          };

          var store = new ItemFileReadStore( {data: this.data});
         	var layout = [[
         		{'name': 'HashCode', 'field': 'hashcode', 'width': "auto"},
         		{'name': 'Edit Date', 'field': 'date', 'width': "auto"},
         		{'name': 'Commit Msg', 'field':'msg', 'width': "auto"}
         	]]
          this.historyGrid = new DataGrid({
          	id: 'historyGrid',
          	store: store,
          	structure: layout
          });
     
          this.historyGrid.on("RowDblClick", function(e) {
            var idx = e.rowIndex, rowData = that.historyGrid.getItem(idx);
            var ready = confirm("Roll Back to Version:\n "+
                                  rowData.date+"\nwith msg:\n "+
                                  rowData.msg+". \nWarning: It can't UNDO");
            if (ready) {
              dojo.xhrPost({
                url: "server/REST/index.php/stats/version/"+
                        that.browser.config.dataset_id,
              //  headers: {"Content-Type": "application/json"},
                content: {
                            hashcode: rowData.hashcode,
                            date : rowData.date,
                            msg  : rowData.msg,
                            reset: true
                          },
                handleAs: "text",
                load: function(data) {
                  console.log(data);
                  return;
                  if (data.ok) {
                    console.log("roll back ok");
                  } else {
                    console.log("roll back error");
                  }
                }
              })
            }
            //console.log(""+idx + rowData + "Dbclicked");
          }, true);

             var historyBar = new ContentPane({
                  id: "historyBar",
                  region: "top",
                  content: [
          //        	inputvalue,
                  	updateButton,
                  ]
                  //style: "height:" + this.height + "%, width: " + this.width + "%"
                 // content: dojo.create("div", {id: "svg_", style: "height: 100%, width: 100%"}),
              });
	     				var contentBox = new ContentPane({
	     						id: "HistoryBox",
	     						region: "center",
	     						content: this.historyGrid.domNode
							});

              appContainer.addChild(historyBar);
              appContainer.addChild(contentBox);

           //   document.onselectstart=function(){return false}
              //Firefox、Chrome、Safaria
           //   d3.select('body').classed('user_select_none', true);

              return appContainer.domNode;
      }
  });
  });
