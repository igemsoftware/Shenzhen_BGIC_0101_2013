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
              'dijit/form/FilteringSelect',
              'dijit/form/NumberTextBox',
              'dojox/validate'
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

      title: "Coden Optimization",
      featuresGrid : null,
      data :null, 

      constructor: function(args) {

          this.browser = args.browser;


          this.defaultContent = this._makeDefaultContent();

          if( ! args.content && ! args.href ) {
              // make a div containing our help text
              this.content = this.defaultContent;
          }

      },

      _fillActionBar: function( actionBar ) {
            var that = this;
            new Button({
                className: 'OK',
                label: 'OK',
                onClick: function() {
                    dojo.xhrGet({
                      url: "server/REST/index.php/CodenOptimize",
                      content: {
                        baseUrl: that.browser.config.baseUrl,
                        re: dijit.byId("re").value,
                        ct: dijit.byId('ct').value
                      },
                      load: function( d ) {
                        console.log(d);
                      }
                    });
                    that.hide();
                },
                focus: false
            })
            .placeAt( actionBar);
            new Button({
                label: 'Cancel',
                onClick: dojo.hitch(this, 'hide'),
                focus: false
            }).placeAt( actionBar );
      },

      show: function() {
                var that = this;
                this.inherited( arguments );
                var highlight = that.browser.getHighlight();
                if (highlight == null) {
                  alert("Please Select Region use Highlight Tools");
                  return;
                }
                var progress = dijit.byId("globalProgress").set("label", 
                                            "I'm working hard to get features");
                progress.set("indeterminate", true);
                
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
                          if (msg[i].Name || msg[i].Load_id)
                            that.data.items.push( {
                              "feature": msg[i].Name || msg[i].Load_id,
                              "start": msg[i].Start,
                              "end":  msg[i].End
                            });
                      }
                      var newStore = new ItemFileReadStore({ data: that.data});
                      that.featuresGrid.setStore(newStore);
                      progress = dijit.byId("globalProgress").set("label", "show you..");
                      progress.set("indeterminate", false);
                  }
                });
      },

      _makeDefaultContent: function() {
        var that = this;
        var appContainer = this.appContainer = new BorderContainer({
                style: "height: " + window.screen.height*0.66 + "px; width: " + window.screen.width*0.6 + "px;"
        });

        var content = '<table cellpadding="0" cellspacing="2">'
                    +     ' <tr><td valign="top"><strong>restriction enzyme sites list: </strong></td><td>'
                    +     ' <select name="re" id="re" dojoType="dijit.form.FilteringSelect">'
                    +     '     <option value="Standard_and_IIB">Standard_and_IIB</option>'
                    +     '     <option value="Standard_and_IIA">Standard_and_IIA</option>'
                    +     '     <option value="Standard_and_IIP">Standard_and_IIP</option>'
                    +     ' </select>'
                    +     ' <tr><td valign="top"><strong>codon table file: </strong></td><td>'
                    +     ' <select name="ct" id="ct" dojoType="dijit.form.FilteringSelect">'
                    +         '   <option value="Standard.ct">Standard.ct</option>'
                    +     ' </select>'
                    + '</table>';
        var configContent = new ContentPane({
          id: "optimizePane",
          region: "center",
          content: [
            content
          ]
        });
       // dojo.place(content, configContent.domNode, "first");

          this.data = {
            identifier: "start",
            items:[]
          };

          var store = new ItemFileReadStore( {data: this.data});
          var layout = [
            { type: "dojox.grid._CheckBoxSelector" },
          [
            {'name': 'feature Name', 'field': 'feature', 'width': "auto"},
            {'name': 'start', 'field': 'start', 'width': "auto"},
            {'name': 'end', 'field':'end', 'width': "auto"}
          ]]
          this.featuresGrid = new DataGrid({
            id: 'OptimizationGrid',
            store: store,
            structure: layout
          });
        var optimizeGridPane = new ContentPane({
          id: "optimizeGridPane",
          region: "right",
          content: [
            that.featuresGrid.domNode
          ]
        });

        appContainer.addChild(configContent);
        appContainer.addChild(optimizeGridPane);
        return appContainer.domNode;
      }
    });
  });
