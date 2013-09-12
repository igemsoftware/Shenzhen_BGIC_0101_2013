define(
			[
				'dojo/_base/declare',
				'dijit/MenuItem',
				'JBrowse/Plugin',
				'./View/Pathway0',
				'./View/OptimizationWindow'
			],
		function(
			declare,
			dijitMenuItem,
			JBrowsePlugin, 
			PathwayWindow,
			OptimizationWindow
			) {
return declare( JBrowsePlugin, 
{
	pathwaywindow : null,
	browser: null,
	constructor: function( args ) {
		var that = this;
		this.browser = args.browser;
		//this.pathwaywindow = new PathwayWindow( {browser: args.browser } );
		args.browser.afterMilestone('completely initialized', 
			function() {
				that.addTool();
			}
		);
		
	},

	addTool: function() {
		var that = this;
		var browser = this.browser;

		browser.addGlobalMenuItem( 'Genovo_tools', new dijitMenuItem(
			{
				label: "Pathway",
				onClick: function() {
					new Pathwaywindow( {browser: browser } ).show();
				}
			}
			));

		browser.addGlobalMenuItem( 'Genovo_tools', new dijitMenuItem(
			{
				label: "Coden Optimize",
				onClick: function() {
					new OptimizationWindow( {browser: browser} ).show();
				}
			}
			));
		browser.renderGlobalMenu( 'Genovo_tools', {
			text: 'Tools'
		}, browser.menuBar);
			

	}



})

	})