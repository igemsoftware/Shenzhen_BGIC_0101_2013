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
                    var progress = dijit.byId("globalProgress").set("label", "YES, I'm whole2mega...");
                        progress.set("indeterminate", true);
                    dojo.xhrGet({
                      url: "server/REST/index.php/Segmentation/whole2mega",
                      content: {
                        baseUrl: that.browser.config.baseUrl,
                        ol: dijit.byId('ol').value,
                        ck: dijit.byId('ck').value
                      },
                      load: function( d ) {
                        var progress = dijit.byId("globalProgress").set("label", "Do not leave me alone, I'm whole2mega");
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
      },

      _makeDefaultContent: function() {
      	var that = this;
        var content = '<table cellpadding="0" cellspacing="2">'
                    +     ' <tr><td valign="top"><strong>overlap length: </strong></td><td><input type="text" required="true" name="ol" id="ol" placeholder="1000" dojoType="dijit.form.NumberTextBox" missingMessage="The length of overlap between megachunks" value="1000" /></td></tr>'
                    +     ' <tr><td valign="top"><strong>megachunks length:  </strong></td><td><input type="text" required="true" name="ck" id="ck" placeholder="30000" dojoType="dijit.form.NumberTextBox" missingMessage="The length of megachunks" value="30000"/></td></tr>'
                    +     '  <tr><td valign="top"><strong>The first marker for selection alternately: </strong></td><td>'
                    +     ' <select name="m1" id="m1" dojoType="dijit.form.FilteringSelect">'
                    +         '   <option value="LEU2">LEU2 (1797bp)</option>'
                    +     ' </select>'
                    +     '  <tr><td valign="top"><strong>The second marker: </strong></td><td>'
                    +     ' <select name="m2" id="m2" dojoType="dijit.form.FilteringSelect">'
                    +         '   <option value="URA3">URA3 (1112bp)</option>'
                    +     ' </select>'
                    +     '  <tr><td valign="top"><strong>The first marker orinally residing in first 30k segmentation: </strong></td><td>'
                    +     ' <select name="m3" id="m3" dojoType="dijit.form.FilteringSelect">'
                    +         '   <option value="HIS3">HIS3 (1774bp)</option>'
                    +     ' </select>'
                    +     '  <tr><td valign="top"><strong>The second marker : </strong></td><td>'
                    +     ' <select name="m4" id="m4" dojoType="dijit.form.FilteringSelect">'
                    +         '   <option value="TRP1">TRP1 (1467bp)</option>'
                    +     ' </select>'
                    +    ' </td></tr>'
                    + '</table>'
        return content;
      }
    });
  });
