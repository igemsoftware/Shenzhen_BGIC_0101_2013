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
              './jquery-1.9.1',
              './plugins/Genovo/js/View/chat.js'
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

      title: "We Need You",
     // width: 1000,
     // height: 300,
      hasInstance: null,
      chat: null,

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
      },

      setupChat: function() {
        var that = this;
        if (!this.hasInstance) {
          this.chat = new Chat();
          this.name = prompt("Enter your chat name:", "Guest");
          if (!that.name || that.name === ' ') {
            that.name = "Guest";  
          }
          
          // strip tags
          that.name = that.name.replace(/(<([^>]+)>)/ig,"");

          $(function() {
      
             that.chat.getState(); 
             
                  // watch textarea for key presses
                  $("#sendie").keydown(function(event) {  
                 
                     var key = event.which;  
               
                     //all keys including return.  
                     if (key >= 33) {
                       
                         var maxLength = $(this).attr("maxlength");  
                         var length = this.value.length;  
                         
                         // don't allow new content if length is maxed out
                         if (length >= maxLength) {  
                             event.preventDefault();  
                         }  
                      }  
                                                                                                            });
                     // watch textarea for release of key press
                  $('#sendie').keyup(function(e) { 
                               
                        if (e.keyCode == 13) { 
                
                        var text = $(this).val();
                        var maxLength = $(this).attr("maxlength");  
                                var length = text.length; 
                                 
                                // send 
                                if (length <= maxLength + 1) { 
                                  that.chat.send(text, that.name);  
                                  $(this).val("");
                                } else {
                                  $(this).val(text.substring(0, maxLength));
                                } 
                        }
                  });
                
          });
          setInterval(that.chat.update(), 1000);
          this.hasInstance = true;
        }
      },

      show: function() {

          var that = this;
          that.setupChat();
        	this.inherited( arguments );
        	on(that, "hide", function() {
          //  this.priceGrid.destroyRecursive(true);
        	})
        	
      },

      _makeDefaultContent: function() {
      	var that = this;
        var content = ' <div id="page-wrap">'
                       +     '<p id="name-area"></p>'
                       +     '<div id="chat-wrap">'
                       +         '<div id="chat-area"></div>'
                       +     '</div>'
                       +     '<form id="send-message-area">'
                       +         '<p>Your message: </p>'
                       +         '<textarea id="sendie" maxlength ="100" ></textarea>'
                       +     '</form>'
                       + '</div>';

        return content;
      }
    });
  });
