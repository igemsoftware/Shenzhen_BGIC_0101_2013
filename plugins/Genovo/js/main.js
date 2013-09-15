define(
			[
				'dojo/_base/declare',
				'dijit/MenuItem',
				'JBrowse/Plugin',
				'./View/Pathway0',
				'./View/OptimizationWindow',
				'./View/GetPrice'
			],
		function(
			declare,
			dijitMenuItem,
			JBrowsePlugin, 
			PathwayWindow,
			OptimizationWindow,
			GetPriceWindow
			) {
return declare( JBrowsePlugin, 
{
	pathwayWindow : null,
	optimizationWindow: null,
	getPriceWindow: null,
	browser: null,
	constructor: function( args ) {
		var that = this;
		this.browser = args.browser;
		
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
					//new PathwayWindow( {browser: browser } ).show();
					if (!that.pathwayWindow) {
						that.pathwayWindow = new PathwayWindow( {browser: browser } );
					}
					that.pathwayWindow.show();
				}
			}
			));

		browser.addGlobalMenuItem( 'Genovo_tools', new dijitMenuItem(
			{
				label: "Coden Optimize",
				onClick: function() {
					if (!that.optimizationWindow) {
						that.optimizationWindow = new OptimizationWindow( {browser: browser} );
					}
					that.optimizationWindow.show();
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
		browser.renderGlobalMenu( 'Genovo_tools', {
			text: 'Tools'
		}, browser.menuBar);
	}

})

	})
