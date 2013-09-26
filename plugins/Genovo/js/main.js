define(
			[
				'dojo/_base/declare',
				'dijit/Menu',
				'dijit/MenuItem',
				'dijit/PopupMenuItem',
				'JBrowse/Plugin',
				'./View/Pathway0',
				'./View/OptimizationWindow',
				'./View/GetPrice',
				'./View/HistoryWindow',
				'./View/UploadDialog',
				'./View/FeaturesDialog',
				'./View/whole2megaWindow',
				'./View/mega2chunk2miniWindow',
				'./View/globalREmarkupWindow',
				'dijit/ProgressBar',
				'./View/chatroom',
				'dojo/domReady!'
			],
		function(
			declare,
			Menu,
			dijitMenuItem,
			PopupMenuItem,
			JBrowsePlugin, 
			PathwayWindow,
			CodenOptimizeWindow,
			GetPriceWindow,
			HistoryWindow,
			UploadDialog,
			FeaturesDialog,
			whole2megaWindow,
			mega2chunk2miniWindow,
			globalREmarkupWindow,
			ProgressBar,
			chatroomWindow
			) {
return declare( JBrowsePlugin, 
{
	pathwayWindow : null,
	codenOptimizeWindow: null,
	getPriceWindow: null,
	browser: null,
	historyWindow: null,
	uploadDialig: null,
	featuresDialog: null,
	whole2mega: null,
	chatroom: null,

	constructor: function( args ) {
		var that = this;
		this.browser = args.browser;
		
		args.browser.afterMilestone('completely initialized', 
			function() {
				that.addTool();
			}
		);
		
	},

	openChromosome: function() {
	    new UploadDialog({ browser: this })
	        .show({
	            openCallback: dojo.hitch( this, function( results ) {

	            })
	        });
	},

	addTool: function() {
		var that = this;
		var browser = this.browser;

		browser.addGlobalMenuItem( 'Genovo_tools', new dijitMenuItem(
			{
				label: "Pathway",
				onClick: function() {
					//new PathwayWindow( {browser: browser } ).show();
					if (!that.pathwayWindow) {
						that.pathwayWindow = new PathwayWindow( {
									browser: browser,
									genovo: that
								} );
					}
					that.pathwayWindow.show();
					//that.getPriceWindow.show();
				}
			}
		));

		var modify = new Menu();
		modify.addChild(new dijitMenuItem({
			label: "Add loxp",
			onClick: function() {
				var progress = dijit.byId("globalProgress").set("label", "We are adding loxp for you.");
       			progress.set("indeterminate", true);
				dojo.xhrGet({
					url:"server/REST/index.php/modify/Add",
					content: {
						dataset: browser.config.dataset_id,
						baseUrl: browser.config.baseUrl,
					},
					handlAs: "test",
					load: function( d ) {
						console.log(d);
						var progress = dijit.byId("globalProgress").set("label", "Loxp success...");
        				progress.set("indeterminate", false);
					}
				})
			}
		}));

		modify.addChild(new dijitMenuItem({
			label: "Delete gene or features",
			onClick: function() {
				if (!that.featuresDialog) {
					that.featuresDialog = new FeaturesDialog({
								browser:browser,
								title: "Delete Features",
								genovo: that/*,
								callback: function() {
									dojo.xhrGet({
										url: "server/REST/index.php/Delete",
										content: {

										},
										load: function() {

										}
									});
								}*/
							});
				}
				that.featuresDialog.show();
			}
		}));

		browser.addGlobalMenuItem( 'Genovo_tools', new PopupMenuItem({
			label: "Modify",
			popup: modify
		}));


		browser.addGlobalMenuItem( 'Genovo_tools', new dijitMenuItem(
			{
				label: "NucleoMod",
				onClick: function() {
					if (!that.codenOptimizeWindow) {
						that.codenOptimizeWindow = new CodenOptimizeWindow({
							browser: browser,
							genovo: that
						})
					} 
					that.codenOptimizeWindow.show();
				}
			}
			));
		browser.addGlobalMenuItem( 'Genovo_tools', new dijitMenuItem(
			{
				label: "fetch enzymes' Price",
				onClick: function() {
					if (!that.getPriceWindow) {
						that.getPriceWindow = new GetPriceWindow( 
									{
										browser: browser,
										genovo: that
									});
					}
					that.getPriceWindow.show();
				}
			}
		));

		

		var pSubMenu = new Menu();
		pSubMenu.addChild(new dijitMenuItem({
			label: "whole2mega",
			onClick: function() {
				if (!that.whole2mega) {
					that.whole2mega = whole2megaWindow(
						{
							browser:browser,
							genovo: that
						});
				}
				that.whole2mega.show();
				/*
				*/
				//alert("Segmentation 30K");
			}
		}));

		pSubMenu.addChild(new dijitMenuItem({
			label: "globalREmarkup",
			onClick: function() {
				if (!that.globalREmarkup) {
					that.globalREmarkup = globalREmarkupWindow(
						{
							browser:browser,
							genovo: that
						});
				}
				that.globalREmarkup.show();
				
			}
		}))
		pSubMenu.addChild(new dijitMenuItem({
			label: "mega2chunk2mini",
			onClick: function() {
				if (!that.mega2chunk2mini) {
					that.mega2chunk2mini = mega2chunk2miniWindow(
						{
							browser:browser,
							genovo: that
						});
				}
				that.mega2chunk2mini.show();
				
			}
		}))

		browser.addGlobalMenuItem( 'Genovo_tools', new PopupMenuItem(
			{
				label: "Segmentation",
				popup: pSubMenu
			}
		));

		browser.addGlobalMenuItem( 'Genovo_tools', new dijitMenuItem( 
        {
                    label: 'Add New chromosome', 
                    iconClass: 'dijitIconFolderOpen',
                    onClick: function() {
                    	if (!that.uploadDialig) {
                    		that.uploadDialig = new UploadDialog( 
                    			{ 
                    				browser: browser, 
                    				genovo: that
                    			});
                    	}
                    	that.uploadDialig.show( {
	            			openCallback: function( results ) {}
	            		})
                    }
        }));



		browser.renderGlobalMenu( 'Genovo_tools', {
			text: 'Tools'
		}, browser.menuBar);


		browser.addGlobalMenuItem( 'History', new dijitMenuItem(
			{
				label: "Edit History",
				class: "share",
				onClick: function() {
					if (!that.historyWindow) {
						//alert("TODO POP HIST");
						that.historyWindow = new HistoryWindow({
							browser: browser,
							genovo: that
						});
					}
					that.historyWindow.show( );
				}
			}
		));



		browser.renderGlobalMenu( 'History', {
			text: 'History'
		}, browser.menuBar);

		browser.addGlobalMenuItem( 'Socity', new dijitMenuItem(
			{
				label: "Chat room",
				onClick: function() {
					if (!that.chatroom) {
						that.chatroom = new chatroomWindow({genovo:that});
					}
					that.chatroom.show();
				}
			}
		));

		browser.renderGlobalMenu( 'Socity', {
			text: "Socity"
		}, browser.menuBar);
		var progress = new ProgressBar({
			style: "width: 300px",
			id: "globalProgress",
			indeterminate:false,
			label: "Welcome to Genovo"
		});
		dojo.addClass(progress.domNode, "menu");
		browser.menuBar.appendChild(progress.domNode);


		/*
		var i = 0;
		setInterval(function() {
			progress.set("value", i++ %100);
		}, 100);*/
	}

})

	})
