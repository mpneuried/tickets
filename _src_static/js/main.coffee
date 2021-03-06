require.config
	paths:
		#jquery: "vendor/jquery-2.0.3"
		bootstrap: "vendor/bootstrap.min"
		backbone: "vendor/backbone"
		underscore: "vendor/underscore"
		moment: "vendor/moment"
		moment_de: "vendor/moment_langs/de"
		marionette: "vendor/backbone.marionette"
		jade: "vendor/jaderuntime"
		showdown: "vendor/showdown"
		tmpl: "tmpl"
	urlArgs: "v" + window.Init.version
	shim:
		underscore:
			exports: "_"
		showdown:
			exports: "Showdown"
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


require [ "bootstrap", "lib/plugins", "app", "users/app", "tickets/app" ], ( Bootstrap, Plugins, Main, Tickets )->
	window.Main = Main
	Main.start()

	$( 'body' ).on 'mouseenter.tooltip.data-api', '[data-toggle^=tooltip]', ( el )->
		$( @ ).removeAttr( "data-toggle" ).tooltip( delay: { show: 500, hide: 100 } ).tooltip( "show" )
		$( @ ).on "click", ()->
			$( @ ).tooltip( "hide" )
			return
		return

	$( 'body' ).on 'mouseenter.btn.data-api', '[data-toggle^=btn]', ( el )->
		$( @ ).removeAttr( "data-toggle" ).button()
		return
	return