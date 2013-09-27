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
                    var progress = dijit.byId("globalProgress").set("label", "build chip need long time...");
                        progress.set("indeterminate", true);
                    dojo.xhrGet({
                      url: "server/REST/index.php/chip/chip",
                      content: {
                        fa: dijit.byId("chipfa").displayedValue,
                        a: dijit.byId("chipa").value,
                        b: dijit.byId("chipb").value,
                        c: dijit.byId("chipc").value,
                        d: dijit.byId("chipd").value,
                        f: dijit.byId("chipf").value,
                        i: dijit.byId("chipi").value,
                        n: dijit.byId("chipn").value,
                        u: dijit.byId("chipu").value,
                        baseUrl: that.browser.config.baseUrl
                      },
                      load: function( d ) {
                        var progress = dijit.byId("globalProgress").set("label", "chip is over, long long ago!");
                        progress.set("indeterminate", false);
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
        	dojo.xhrGet({
            url: 'server/REST/index.php/Segmentation/info',
            content: {
              baseUrl: that.browser.config.baseUrl,
            },
            handleAs: "json",
            load: function( json ) {
                console.log("loaddata");
                
                if (json['mini'] != null) {
                  var data = [];
                  var fa = dijit.byId('chipfa');
                  var id = json['mini'];
                  for ( var a in id ) {
                      data.push( {
                        name: id[a],
                        value: id[a]
                      } );
                  }
                  data[0]['selected'] = true;
                  var store = new Memory({
                    data: data
                  })
                  fa.store = store;
                  fa.startup();
                };
            }
          })
      },

      _makeDefaultContent: function() {
      	var that = this;
        // TODO file select
        var content = '<table cellpadding="0" cellspacing="2">'
                    +     ' <tr><td valign="top"><strong>fasta file input: </strong></td><td>'
                    +     ' <select name="chipfa" id="chipfa" dojoType="dijit.form.FilteringSelect">'
                    +     ' </select>'
                    +     ' <tr><td valign="top"><strong> plate position index of primer set when using fixed primer set: </strong></td><td><input type="text" required="true" name="chipa" id="chipa" placeholder="0" dojoType="dijit.form.NumberTextBox" missingMessage="plate position index of primer set when using fixed primer set." value="0"/></td></tr>'
                    +     ' <tr><td valign="top"><strong>true if all seqs in file get same primer set: </strong></td><td>'
                    +     ' <select name="chipb" id="chipb" dojoType="dijit.form.FilteringSelect">'
                    +     '     <option value="true">true</option>'
                    +     '     <option value="false">false</option>'
                    +     ' </select>'
                    +     ' <tr><td valign="top"><strong> Leeway in junction position: </strong></td><td><input type="text" required="true" name="chipc" id="chipc" placeholder="10" dojoType="dijit.form.NumberTextBox" missingMessage="plate position index of primer set when using fixed primer set." value="10"/></td></tr>'
                    +     ' <tr><td valign="top"><strong> plate # of primer set when using fixed primer set: </strong></td><td><input type="text" required="true" name="chipd" id="chipd" placeholder="1" dojoType="dijit.form.NumberTextBox" missingMessage="plate position index of primer set when using fixed primer set." value="2"/></td></tr>'
                    +     ' <tr><td valign="top"><strong> length of oligo can be + or - this #: </strong></td><td><input type="text" required="true" name="chipf" id="chipf" placeholder="10" dojoType="dijit.form.NumberTextBox" missingMessage="plate position index of primer set when using fixed primer set." value="10"/></td></tr>'
                   // +     ' <tr><td valign="top"><strong> Print help information : </strong></td><td><input type="text" required="true" name="h" id="h" placeholder="0" dojoType="dijit.form.NumberTextBox" missingMessage="plate position index of primer set when using fixed primer set." value=""/></td></tr>'
                    +     ' <tr><td valign="top"><strong> 96-well plates holding assembled constructs are numbered starting with this number (never set to 1): </strong></td><td><input type="text" required="true" name="chipi" id="chipi" placeholder="3" dojoType="dijit.form.NumberTextBox" missingMessage="plate position index of primer set when using fixed primer set." value="3"/></td></tr>'
                //    +     ' <tr><td valign="top"><strong> plate position index of primer set when using fixed primer set: </strong></td><td><input type="text" required="true" name="l" id="l" placeholder="0" dojoType="dijit.form.NumberTextBox" missingMessage="plate position index of primer set when using fixed primer set." value=""/></td></tr>'
                    +     ' <tr><td valign="top"><strong> selfDimerThreshold: </strong></td><td><input type="text" required="true" name="chipn" id="chipn" placeholder="3" dojoType="dijit.form.NumberTextBox" missingMessage="plate position index of primer set when using fixed primer set." value="3"/></td></tr>'
                    +     ' <tr><td valign="top"><strong> oligoSizeMax: </strong></td><td><input type="text" required="true" name="chipu" id="chipu" placeholder="200" dojoType="dijit.form.NumberTextBox" missingMessage="plate position index of primer set when using fixed primer set." value="200"/></td></tr>'
                    + '</table>'
        return content;
      }
    });
  });
