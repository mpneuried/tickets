require.config
	paths:
		#jquery: "lib/jquery-2.0.3"
		bootstrap: "lib/bootstrap.min"
		backbone: "lib/backbone"
		underscore: "lib/underscore"
		moment: "lib/moment"
		marionette: "lib/backbone.marionette"
		jade: "lib/jaderuntime"
		tmpl: "tmpl"
	shim:
		underscore:
			exports: "_"
		moment:
			exports: "moment"
		backbone:
			deps: [ "underscore" ]
			exports: "Backbone"
		marionette: 
			deps: [ "underscore", "backbone" ]
			exports: "Marionette"
		jade:
			exports: "jade"
		tmpl:
			deps: [ "jade" ]


require [ "app", "tickets/app" ], ( Main, Tickets )->

	#window.Main = Main
	Main.start()
	return