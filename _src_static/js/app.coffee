define [ "marionette", "router", "views/menu" ], ( marionette, Router, viewMenu )->

	app = new marionette.Application()
	app.router = new Router()

	app.addRegions
		content: "#container"
		menu: "#menu"

	app.on "start", =>
		app.menu.show( new viewMenu() )

		Backbone.history.start( pushState: true )
		return

	return app