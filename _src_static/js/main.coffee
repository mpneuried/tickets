require.config
	paths:
		#jquery: "vendor/jquery-2.0.3"
		bootstrap: "vendor/bootstrap.min"
		backbone: "vendor/backbone"
		underscore: "vendor/underscore"
		moment: "vendor/moment"
		marionette: "vendor/backbone.marionette"
		jade: "vendor/jaderuntime"
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