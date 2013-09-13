define [ "marionette", "router", "views/menu" ], ( marionette, Router, viewMenu )->

	app = new marionette.Application()
	app.router = new Router()

	$mmenu = $('#menu')

	app.addRegions
		content: "#container"
		menu: "#menuitems"

	app.vent.on "navigate:after", ( route, module )=>
		$('#menu').trigger( 'close.mm' )
		return

	app.on "start", =>
		app.menu.show( new viewMenu() )

		Backbone.history.start( pushState: true )
		return

	return app