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
                    dojo.xhrGet({
                      url: "server/REST/index.php/Segmentation/globalREmarkup",
                      content: {
                        baseUrl: that.browser.config.baseUrl,
                        re: dijit.byId("re").value,
                        ct: dijit.byId('ct').value,
                        sg: dijit.byId('sg').displayedValue
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
        	dojo.xhrGet({
            url: 'server/REST/index.php/Segmentation/info',
            content: {
              baseUrl: that.browser.config.baseUrl,
            },
            handleAs: "json",
            load: function( json ) {
              //  console.log("asd");
                
                if (json['mega'] != null) {
                  var data = [];
                  var sg = dijit.byId('sg');
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
                  sg.store = store;
                  sg.startup();
                };
            }
          })
      },

      _makeDefaultContent: function() {
      	var that = this;
        // TODO file select
        var content = '<table cellpadding="0" cellspacing="2">'
                    +     ' <tr><td valign="top"><strong>The fasta file: </strong></td><td>'
                    +     ' <select name="sg" id="sg" dojoType="dijit.form.FilteringSelect">'
                    +     ' </select>'
                    +     ' <tr><td valign="top"><strong>restriction enzyme sites list: </strong></td><td>'
                    +     ' <select name="re" id="re" dojoType="dijit.form.FilteringSelect">'
                    +     '     <option value="standard_and_IIB">standard_and_IIB</option>'
                    +     '     <option value="standard_and_IIA">standard_and_IIA</option>'
                    +     '     <option value="standard_and_IIP">standard_and_IIP</option>'
                    +     ' </select>'
                    +     ' <tr><td valign="top"><strong>codon table file: </strong></td><td>'
                    +     ' <select name="ct" id="ct" dojoType="dijit.form.FilteringSelect">'
                    +         '   <option value="Standard.ct">Standard.ct</option>'
                    +     ' </select>'
                    + '</table>'
        return content;
      }
    });
  });
