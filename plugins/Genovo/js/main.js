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
				'dojo/domReady!'
			],
		function(
			declare,
			Menu,
			dijitMenuItem,
			PopupMenuItem,
			JBrowsePlugin, 
			PathwayWindow,
			OptimizationWindow,
			GetPriceWindow,
			HistoryWindow,
			UploadDialog
			) {
return declare( JBrowsePlugin, 
{
	pathwayWindow : null,
	optimizationWindow: null,
	getPriceWindow: null,
	browser: null,
	historyWindow: null,
	uploadDialig: null,

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
				alert("delete");
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
				dojo.xhrGet({
					url: "server/REST/index.php/Segmentation/whole2mega",
					content: {
						baseUrl: browser.config.baseUrl
					},
					load: function( d ) {
						console.log(d);
					}
				});
				//alert("Segmentation 30K");
			}
		}));

		pSubMenu.addChild(new dijitMenuItem({
			label: "globalREmarkup",
			onClick: function() {
				dojo.xhrGet({
					url: "server/REST/index.php/Segmentation/globalREmarkup",
					content: {
						baseUrl: browser.config.baseUrl
					},
					load: function( d ) {
						console.log(d);
					}
				});
			}
		}))
		pSubMenu.addChild(new dijitMenuItem({
			label: "mega2chunk2mini",
			onClick: function() {
				dojo.xhrGet({
					url: "server/REST/index.php/Segmentation/mega2chunk2mini",
					content: {
						baseUrl: browser.config.baseUrl
					},
					load: function( d ) {
						console.log(d);
					}
				});
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
