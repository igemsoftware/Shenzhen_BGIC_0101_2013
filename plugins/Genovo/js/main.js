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
			globalREmarkupWindow
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
						that.pathwayWindow = new PathwayWindow( {browser: browser } );
					}
					that.pathwayWindow.show();
				}
			}
		));

		var modify = new Menu();
		modify.addChild(new dijitMenuItem({
			label: "Add loxp",
			onClick: function() {
				dojo.xhrGet({
					url:"server/REST/index.php/modify/Add",
					content: {
						dataset: browser.config.dataset_id,
						baseUrl: browser.config.baseUrl,
					},
					handlAs: "test",
					load: function( d ) {
						console.log(d);
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
								title: "Delete Features"/*,
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
				label: "Coden Optimize",
				onClick: function() {
					if (!that.codenOptimizeWindow) {
						that.codenOptimizeWindow = new CodenOptimizeWindow({
							browser: browser
						})
					} 
					that.codenOptimizeWindow.show();/*
						dojo.xhrGet({
							url: "server/REST/index.php/CodenOptimize",
							content: {
								baseUrl: browser.config.baseUrl,
								dataset: browser.config.dataset_id,
								step: {
									1: true,
									2: true
								}
							},
							load: function( d ) {
								console.log(d);
							}
						});
		*/
					/*
					if (!that.optimizationWindow) {
						that.optimizationWindow = new OptimizationWindow( {browser: browser} );
					}
					that.optimizationWindow.show();*/
				}
			}
			));
		browser.addGlobalMenuItem( 'Genovo_tools', new dijitMenuItem(
			{
				label: "fetch enzymes' Price",
				onClick: function() {
					if (!that.getPriceWindow) {
						that.getPriceWindow = new GetPriceWindow( {browser: browser});
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
					that.whole2mega = whole2megaWindow({browser:browser});
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
					that.globalREmarkup = globalREmarkupWindow({browser:browser});
				}
				that.globalREmarkup.show();
				
			}
		}))
		pSubMenu.addChild(new dijitMenuItem({
			label: "mega2chunk2mini",
			onClick: function() {
				if (!that.mega2chunk2mini) {
					that.mega2chunk2mini = mega2chunk2miniWindow({browser:browser});
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
                    		that.uploadDialig = new UploadDialog( { browser: browser });
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
						that.historyWindow = new HistoryWindow({browser: browser});
					}
					that.historyWindow.show( );
				}
			}
		));

		browser.renderGlobalMenu( 'History', {
			text: 'History'
		}, browser.menuBar);

	}

})

	})
