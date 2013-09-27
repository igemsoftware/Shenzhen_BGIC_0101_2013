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
              'dojox/validate',
              "dijit/form/Textarea",
              "dijit/form/CheckBox"
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
                    var progress = dijit.byId("globalProgress").set("label", 
                                            "well, begin work now");
                    progress.set("indeterminate", true);
                    var content = {
                      baseUrl: that.browser.config.baseUrl,
                      dataset: that.browser.config.dataset_id,
                    };
                    if (dijit.byId("checkCRISPR").checked) {
                        content["crisprnum"] = dijit.byId("crisprnum").value;
                        content["database"] = dijit.byId("database").value;
                    }
                    if (dijit.byId("checkoptimize").checked) {
                        content["codonoptimize"] = dijit.byId("codonoptimize").value;
                        content["optimizelist"] = dijit.byId("optimizelist").value;
                        if (content["optimizelist"] == "optimizegenelist") {
                            var selected = that.featuresGrid.selection.selected;
                            var msg = [];
                            for (var a in selected) {
                              if (a && selected[a]) {
                                  msg.push(that.data.items[a].feature[0]);
                              }
                            };
                            if (msg.length == 0) {
                              alert("You can highlight the genes,\n Then comeback to select what you want :)")
                            }
                            msg = msg.join(",");
                            content["optimizelist"] = msg;
                        }
                    }

                    if (dijit.byId("checkRepeat").checked) {
                        content["repeatsmash"] = dijit.byId("repeatsmash").value;
                    }
                    if (dijit.byId("checkenzyme").checked) {
                        content["addenzymelist"] = dijit.byId("addenzymelist").value;
                        content["addenzymeconfig"] = dijit.byId("addenzymeconfig").value;
                    }
                    if (dijit.byId("checkBiobrick").checked) {
                        content["biobrickstrand"] = dijit.byId("biobrickstrand").value;
                    }
                    dojo.xhrGet({
                      url: "server/REST/index.php/NucleoMod",
                      content: content,
                      load: function( d ) {
                        var value = that.browser.config.dataset_id + "_nucleo";
                        that.genovo.updateSelectBox({
                            value: value,
                            label: value
                        });
                        console.log(d);
                         var progress = dijit.byId("globalProgress").set("label", 
                                            "I Done lots things for you :)");
                          progress.set("indeterminate", false);
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

      fillGrid: function() {
                var that = this;
                var highlight = that.browser.getHighlight();
                if (highlight == null) {
                //  alert("Please Select Region use Highlight Tools");
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

      setupEvent: function() {
            var that = this;
            dojo.connect(dijit.byId("optimizelist"), "onChange", function(d) {
                if (d == "optimizeallgene") {
                  dojo.query("#optimizeGridPane").style("display", "false");
                } else {
                  dojo.query("#optimizeGridPane").style("display", "true");
                }
            });
            dojo.connect(dijit.byId("checkCRISPR"), "onChange", function(d) {
              //  console.log(d);
                if (d == true) {
                  dojo.query("#CRISPR").style("visibility", "visible");
                } else {
                  dojo.query("#CRISPR").style("visibility", "hidden");
                }
            });
            dojo.connect(dijit.byId("checkRepeat"), "onChange", function(d) {
                if (d == false) {
                  dojo.query("#repeat").style("visibility", "hidden");
                } else {
                  dojo.query("#repeat").style("visibility", "visible");
                }
            });
            dojo.connect(dijit.byId("checkBiobrick"), "onChange", function(d) {
                if (d == false) {
                  dojo.query("#biobrick").style("visibility", "hidden");
                } else {
                  dojo.query("#biobrick").style("visibility", "visible");
                }
            });
            dojo.connect(dijit.byId("checkenzyme"), "onChange", function(d) {
                if (d == false) {
                  dojo.query("#addenzyme").style("visibility", "hidden");
                } else {
                  dojo.query("#addenzyme").style("visibility", "visible");
                }
            });
            dojo.connect(dijit.byId("checkoptimize"), "onChange", function(d) {
                if (d == false) {
                  dojo.query("#codonoptimizebody").style("visibility", "hidden");
                } else {
                  dojo.query("#codonoptimizebody").style("visibility", "visible");
                }
            });
      },

      show: function() {

              var that = this;
              this.inherited( arguments );
              this.fillGrid();
              this.setupEvent();
      },

      _makeDefaultContent: function() {
        var that = this;
        var appContainer = this.appContainer = new BorderContainer({
                style: "height: " + window.screen.height*0.66 + "px; width: " + window.screen.width*0.6 + "px;"
        });

        var content = '<table cellpadding="0" cellspacing="3">'
                    // CRISPR
                        +     '<tr><td valign="top"><input id="checkCRISPR" name="checkCRISPR" data-dojo-type="dijit/form/CheckBox" checked="true"/>'
                        +     '<label for="checkCRISPR">CRISPR:</label></td></tr>'

                    +   "<tbody id='CRISPR'>"
                    +     ' <tr><td valign="top"><strong>Number of CRISPR site to design in a gene. : </strong></td><td><input type="text" required="true" name="crisprnum" id="crisprnum" placeholder="2" dojoType="dijit.form.NumberTextBox" missingMessage="Number of CRISPR site to design in a gene." value="2"/></td></tr>'
                    +     ' <tr><td valign="top"><strong>Genome fasta file of selected species.: </strong></td><td>'
                    +     ' <select name="database" id="database" dojoType="dijit.form.FilteringSelect">'
                    +     '     <option value="saccharomyces_cerevisiae_chr.fa ">saccharomyces_cerevisiae_chr.fa</option>'
                    +     ' </select>'
                    +   "</tbody>"
                    // repeat smash 
                        +     '<tr><td valign="top"><input id="checkRepeat" name="checkRepeat" data-dojo-type="dijit/form/CheckBox" checked="true"/>'
                        +     '<label for="checkRepeat">Repeat Smash: </label></td></tr>'    

                    +   '<tbody id="repeat">'
                          +     ' <tr><td valign="top"><strong>tandem Repeat bases longer than this value will be smash. : </strong></td><td><input type="text" required="true" name="repeatsmash" id="repeatsmash" placeholder="4" dojoType="dijit.form.NumberTextBox" missingMessage="tandem Repeat bases longer than this value will be smash" value="4"/></td></tr>'
                    +   '</tbody>'
                    
                    // biobrick format
                        +     '<tr><td valign="top"><input id="checkBiobrick" name="checkBiobrick" data-dojo-type="dijit/form/CheckBox" checked="true"/>'
                        +     '<label for="checkBiobrick">Biobrick format :</label></td></tr>'    

                    +   '<tbody id ="biobrick">'
                        +     ' <tr><td valign="top"><strong>Use biobrickstrand to delete enzyme : </strong></td><td>'
                        +     ' <select name="biobrickstrand" id="biobrickstrand" dojoType="dijit.form.FilteringSelect">'
                        +         '   <option value="biobrickstrand">biobrickstrand</option>'
                        +         '   <option value="common_enzyme.list">common_enzyme.list</option>'
                        +     ' </select>'
                    +   '</tbody>'
                    /// add enzyme
                        
                        +     '<tr><td valign="top"><input id="checkenzyme" name="checkenzyme" data-dojo-type="dijit/form/CheckBox" checked="true"/>'
                        +     '<label for="checkenzyme">Add enzyme :</label></td></tr>'    

                    +   '<tbody id="addenzyme">'
                        +     ' <tr><td valign="top"><strong>A file of enzyme structure to be add: </strong></td><td>'
                        +     ' <select name="addenzymelist" id="addenzymelist" dojoType="dijit.form.FilteringSelect">'
                        +         '   <option value="common_enzyme.list">common_enzyme.list</option>'
                        +     ' </select>'
                        +     ' <tr><td valign="top"><strong>A group of config for create enzyme: </strong></td><td>'
                        +     ' <textarea id="addenzymeconfig" name="addenzymeconfig" data-dojo-type="dijit/form/Textarea">'
                        +     ' </textarea>'
                    +   '</tbody>'
                    ///Codon Optimize
                        
                        +     '<tr><td valign="top"><input id="checkoptimize" name="checkoptimize" data-dojo-type="dijit/form/CheckBox" checked="true"/>'
                        +     '<label for="checkoptimize">codon optimization :</label></td></tr>'    

                    +   '<tbody id="codonoptimizebody">'
                        +     ' <tr><td valign="top"><strong>A file of codon priority of selected species: </strong></td><td>'
                        +     ' <select name="codonoptimize" id="codonoptimize" dojoType="dijit.form.FilteringSelect">'
                        +         '   <option value="yeast.CodonPriority.txt">yeast.CodonPriority.txt</option>'
                        +     ' </select>'
                        +     ' <tr><td valign="top"><strong>Choose how many genes to Optimize: </strong></td><td>'
                        +     ' <select name="optimizelist" id="optimizelist" dojoType="dijit.form.FilteringSelect">'
                        +         '   <option value="optimizeallgene">Optimize all genes in gff</option>'
                        +         '   <option value="optimizegenelist">Only genes selected will be optimized</option>'
                        +     ' </select>'
                    +   '</tbody>'
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
          style: "height: 10em",
          region: "bottom",
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
