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
				'./View/chip',
				'dijit/ProgressBar',
				'./View/chatroom',
				'./View/downloadWindow',
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
			chipWindow,
			ProgressBar,
			chatroomWindow,
			downloadWindow
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
	chip: null,
	download: null,


	constructor: function( args ) {
		var that = this;
		this.browser = args.browser;
		
		args.browser.afterMilestone('completely initialized', 
			function() {
				that.addTools();
			}
		);
		
	},

	updateSelectBox: function( argv ) {
		var value = argv.value;
		var label = argv.label;
		var selectbox = dijit.byId("datasetSelectBox");
		for (var i in selectbox.options) {
			if (selectbox.options[i].value == value)
				return;
		}
		this.browser.config.datasets[value] = {
			url: "index.html?data=data/"+value
		}
		dijit.byId("datasetSelectBox").addOption(
			{
				lable:label,
				value:value
			})
	},

	addTools: function() {
		var that = this;
		var browser = this.browser;

		browser.addGlobalMenuItem( 'Neochr', new dijitMenuItem(
			{
				label: "Pathway",
				iconClass: 'dijitIconConnector',
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
		//modify.addChild(new dijitMenuItem({
		browser.addGlobalMenuItem( 'Neochr', new dijitMenuItem( {
			label: "Add",
			iconClass: 'dijitIconEditTask',
			onClick: function() {
				var progress = dijit.byId("globalProgress").set("label", "We are adding loxp for you.");
       			progress.set("indeterminate", true);
				dojo.xhrGet({
					url:"server/REST/index.php/modify/Add",
					content: {
						dataset: browser.config.dataset_id,
						baseUrl: browser.config.baseUrl,
					},
					handlAs: "text",
					load: function( d ) {
						console.log(d);
						var progress = dijit.byId("globalProgress").set("label", "Loxp success...");
        				progress.set("indeterminate", false);

        				that.updateSelectBox({
        					value: browser.config.dataset_id+"_add",
        					label: browser.config.dataset_id+"_add"
        				})
					}
				})
			}
		}));

		browser.addGlobalMenuItem( 'Neochr', new dijitMenuItem( {
		//modify.addChild(new dijitMenuItem({
			label: "Delete",
			iconClass: 'dijitIconDelete',
			onClick: function() {
				if (!that.featuresDialog) {
					that.featuresDialog = new FeaturesDialog({
								browser:browser,
								title: "Delete Features",
								genovo: that
							});
				}
				that.featuresDialog.show();
			}
		}));

		browser.renderGlobalMenu( 'Neochr', {
			text: 'NeoChr'
		}, browser.menuBar);

/*
		browser.addGlobalMenuItem( 'Genovo_tools', new PopupMenuItem({
			label: "Modify",
			popup: modify
		}));
*/

		browser.addGlobalMenuItem( 'NucleoMod', new dijitMenuItem(
			{
				label: "NucleoMod",
				iconClass: 'dijitIconConfigure',
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

		browser.renderGlobalMenu( 'NucleoMod', {
			text: 'NucleoMod'
		}, browser.menuBar);



		var pSubMenu = new Menu();
		browser.addGlobalMenuItem( 'SegmMan', new dijitMenuItem( {
		//pSubMenu.addChild(new dijitMenuItem({
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

		browser.addGlobalMenuItem( 'SegmMan', new dijitMenuItem( {
		//pSubMenu.addChild(new dijitMenuItem({
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

		browser.addGlobalMenuItem( 'SegmMan', new dijitMenuItem( {
		//pSubMenu.addChild(new dijitMenuItem({
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
		}));

		browser.renderGlobalMenu( 'SegmMan', {
			text: 'SegmMan'
		}, browser.menuBar);


		browser.addGlobalMenuItem( 'Chip', new dijitMenuItem(
			{
				label: "Chip",
				iconClass: 'dijitIconConfigure',
				onClick: function() {
					if (!that.chip) {
						that.chip = new chipWindow({
							browser: browser,
							genovo: that
						})
					} 
					that.chip.show();
				}
			}
			));

		browser.renderGlobalMenu( 'Chip', {
			text: 'Chip'
		}, browser.menuBar);

/*
		browser.addGlobalMenuItem( 'Genovo_tools', new PopupMenuItem(
			{
				label: "Segmentation",
				popup: pSubMenu
			}
		));
*/
		browser.addGlobalMenuItem( 'Others', new dijitMenuItem( 
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

		browser.addGlobalMenuItem( 'Others', new dijitMenuItem(
			{
				label: "fetch enzymes' Price",
				iconClass: 'dijitIconDatabase',
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

		

		browser.addGlobalMenuItem( 'Others', new dijitMenuItem(
			{
				label: "Edit History",
				iconClass: 'dijitIconUndo',
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

		browser.addGlobalMenuItem( 'Others', new dijitMenuItem(
			{
				label: "Chat room",
				iconClass: 'dijitIconSearch',
				onClick: function() {
					if (!that.chatroom) {
						that.chatroom = new chatroomWindow({genovo:that});
					}
					that.chatroom.show();
				}
			}
		));

		browser.addGlobalMenuItem( 'Others', new dijitMenuItem(
		{
			label: "Download",
			iconClass: '', 
			onClick: function() {
				if (!that.downloadWindow) {
					that.download = new downloadWindow({
						genovo:that,
						jbrowse: browser
					});
				}
				that.download.show();
			}
		}));

		browser.renderGlobalMenu( 'Others', {
			text: 'Others'
		}, browser.menuBar);
	
		var progress = new ProgressBar({
			style: "width: 300px",
			id: "globalProgress",
			indeterminate:false,
			label: "Welcome to Genovo"
		});
		dojo.addClass(progress.domNode, "menu");
		browser.menuBar.appendChild(progress.domNode);

	}

})

})
