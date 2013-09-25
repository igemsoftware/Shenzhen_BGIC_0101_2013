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
              dom
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
                    + '</table>'
        return content;
      }
    });
  });
