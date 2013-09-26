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
              'dojo/store/Memory',
              'dijit/form/FilteringSelect',
              'dijit/form/NumberTextBox',
              'dojox/validate',
              './jquery-1.9.1'
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
              Memory
          ) {
  return declare( InfoDialog, {

      title: "Segmention",
     // width: 1000,
     // height: 300,

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

      _fillActionBar: function( actionBar ) {
            var that = this;
            new Button({
                className: 'OK',
                label: 'OK',
                onClick: function() {
                    dojo.xhrGet({
                      url: "server/REST/index.php/Segmentation/mega2chunk2mini",
                      content: {
                        baseUrl: that.browser.config.baseUrl,
                        sg: dijit.byId('sg3').displayedValue,
                        ps: dijit.byId('ps').displayedValue,
                        re: dijit.byId('re1').value
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
        //  dijit.byId("")
        console.log("asd");
          dojo.connect( dijit.byId("a2"), "onChange", function(d) {
             if (d == "Gibson") {
              dojo.query("#a2extern").style("display", "inline");
             } else {
              dojo.query("#a2extern").style("display", "none");
             }
          })
          
          dojo.connect( dijit.byId("a10"), "onChange", function(d) {
             if (d == "Goldengate") {
              dojo.query("#a10extern").style("display", "inline");
             } else {
              dojo.query("#a10extern").style("display", "none");
             }
          })
          console.log("asd");
          dojo.xhrGet({
            url: 'server/REST/index.php/Segmentation/info',
            content: {
              baseUrl: that.browser.config.baseUrl,
            },
            handleAs: "json",
            load: function( json ) {
                console.log("asd");
                
                if (json['mega'] != null) {
                  var data = [];
                  var sg3 = dijit.byId('sg3');
                  var id = json['mega']['ID'];
                  for ( var a in id ) {
                      data.push( {
                        name: a,
                        value: a
                      } );
                  }
                  data[0]['selected'] = true;
                  var store = new Memory({
                    data: data
                  })
                  sg3.store = store;
                  sg3.startup();
                };

                if (json['markup']) {
                  var data = [];
                  var ps = dijit.byId('ps');
                  for (var i in json['markup']) {
                    data.push( {
                      name: json['markup'][i],
                      value: json['markup'][i]
                    });
                  }
                  var store = new Memory({
                    data: data
                  });
                  ps.store = store;
                  ps.startup();
                }
            }
          });



        	this.inherited( arguments );
        	on(that, "hide", function() {
          //  this.priceGrid.destroyRecursive(true);
        	})
        	
      },

      _makeDefaultContent: function() {
      	var that = this;
        var content = '<table cellpadding="0" cellspacing="2" style="display:inline">'
                    +     ' <tr><td valign="top"><strong>The fasta file of the 30k segmentation(first step output): </strong></td><td>'  
                    +     ' <select name="sg3" id="sg3" dojoType="dijit.form.FilteringSelect">'
                    +     ' </select>'
                    +     ' <tr><td valign="top"><strong>The markup file of the 30k segmentation(second step output): </strong></td><td>'  
                    +     ' <select name="ps" id="ps" dojoType="dijit.form.FilteringSelect">'
                    +     ' </select>'
                    +     ' <tr><td valign="top"><strong>restriction enzyme sites list: </strong></td><td>'  
                    +     ' <select name="re1" id="re1" dojoType="dijit.form.FilteringSelect">'
                    +     '     <option value="standard_and_IIB">standard_and_IIB</option>'
                    +     '     <option value="IIA">IIA</option>'
                    +     '     <option value="IIP">IIP</option>'
                    +     '     <option value="IIB">IIB</option>'
                    +     '     <option value="nonpal">nonpal</option>'
                    +     ' </select>'
                    +     ' <tr><td valign="top"><strong>2k to 10k assembly strategy : </strong></td><td>'
                    +     ' <select name="a2" id="a2" dojoType="dijit.form.FilteringSelect">'
                    +     '     <option value="Gibson">Gibson</option>'
                    +     '     <option value="Goldengate">Goldengate</option>'
                    +     ' </select>'
                    +     ' <tr><td valign="top"><strong>10k to 30k assembly strategy: </strong></td><td>'
                    +     ' <select name="a10" id="a10" dojoType="dijit.form.FilteringSelect">'
                    +     '     <option value="Goldengate">Goldengate</option>'
                    +     '     <option value="Gibson">Gibson</option>'
                    +     ' </select>'
                    +     ' <tr><td valign="top"><strong>The maximum length of minichunks : </strong></td><td><input type="text" required="true" name="ckmax2" id="ckmax2" placeholder="2200" dojoType="dijit.form.NumberTextBox" missingMessage="The maximum length of minichunks(bp)" value="2200"/></td></tr>'
                    +     ' <tr><td valign="top"><strong>The minimum length of minichunks :  </strong></td><td><input type="text" required="true" name="ckmin2" id="ckmin2" placeholder="1800" dojoType="dijit.form.NumberTextBox" missingMessage="The minimum length of minichunks (bp)" value="1800"/></td></tr>'
                    +     ' <tr><td valign="top"><strong>The number of minichunks in a chunk :  </strong></td><td><input type="text" required="true" name="cknum" id="cknum" placeholder="5" dojoType="dijit.form.NumberTextBox" missingMessage="The number of minichunks in a chunk" value="5"/></td></tr>'
               //     + '</table>'
                    + '<tbody id="a2extern" cellpadding="0" cellspacing="2" style="display:inline">'
                    +     ' <tr><td valign="top"><strong>The length of overlap(bp) : </strong></td><td><input type="text" required="true" name="ol2" id="ol2" placeholder="40" dojoType="dijit.form.NumberTextBox" missingMessage="The length of overlap(bp)" value="40"/></td></tr>'
                    +     ' <tr><td valign="top"><strong>maximum melting temperature(℃) : </strong></td><td><input type="text" required="true" name="tmax2" id="tmax2" placeholder="60" dojoType="dijit.form.NumberTextBox" missingMessage="The maximum melting temperature of the overlap of minichunks" value="60"/></td></tr>'
                    +     ' <tr><td valign="top"><strong>minimum melting temperature(℃) : </strong></td><td><input type="text" required="true" name="tmin2" id="tmin2" placeholder="56" dojoType="dijit.form.NumberTextBox" missingMessage="The minimum melting temperature of the overlap of minichunks" value="56"/></td></tr>'
                    +     ' <tr><td valign="top"><strong>minimum free energy : </strong></td><td><input type="text" required="true" name="fe2" id="fe2" placeholder="-3" dojoType="dijit.form.NumberTextBox" missingMessage="The minimum free energy of the overlap of minichunks" value="-3"/></td></tr>'
                    +     ' <tr><td valign="top"><strong>minimum distance between minichunks(bp) : </strong></td><td><input type="text" required="true" name="lo2" id="lo2" placeholder="40" dojoType="dijit.form.NumberTextBox" missingMessage="The minimum distance between minichunks overlap and loxpsym" value="40"/></td></tr>'
                    +     ' <tr><td valign="top"><strong>temperature of enzyme(℃) : </strong></td><td><input type="text" required="true" name="et2" id="et2" placeholder="37" dojoType="dijit.form.NumberTextBox" missingMessage="The temperature of enzyme used in minichunks digestion" value="37"/></td></tr>'
                    +     ' <tr><td valign="top"><strong>maximum unit price of enzyme($/unit) : </strong></td><td><input type="text" required="true" name="ep2" id="ep2" placeholder="0.5" dojoType="dijit.form.NumberTextBox" missingMessage="The maximum unit price of enzyme used in minichunks digestion" value="0.5"/></td></tr>'
                    +     ' <tr><td valign="top"><strong>The type of exonuclease used for minichunks: </strong></td><td>'
                    +     ' <select name="ex2" id="ex2" dojoType="dijit.form.FilteringSelect">'
                    +         '   <option value="T5">T5</option>'
                    +     ' </select>'
                    +     ' <tr><td valign="top"><strong>The type of enzyme flanking minichunks: </strong></td><td>'
                    +     ' <select name="en2" id="en2" dojoType="dijit.form.FilteringSelect">'
                    +         '   <option value="IIP">IIP</option>'
                    +     ' </select>'
                    + '</tbody>'
                    + '<tbody id="a10extern" cellpadding="0" cellspacing="2" style="display:inline">'
                    +     ' <tr><td valign="top"><strong>The type of enzyme flanking chunks: </strong></td><td>'
                    +     ' <select name="en10" id="en10" dojoType="dijit.form.FilteringSelect">'
                    +         '   <option value="IIB">IIB</option>'
                    +     ' </select>'
                    +     ' <tr><td valign="top"><strong>The temperature of enzyme used in chunks digestion : </strong></td><td><input type="text" required="true" name="et10" id="et10" placeholder="37" dojoType="dijit.form.NumberTextBox" missingMessage="The temperature of enzyme used in chunks digestion℃" value="37"/></td></tr>'
                    + '</tbody>'
        return content;
      }
    });
  });
