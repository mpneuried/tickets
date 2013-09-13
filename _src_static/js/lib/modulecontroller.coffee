define [ "marionette", "app" ], ( marionette, App )->

	return class Controller

		config: {}	

		constructor: ( @module )->

			@initRoute( type, sett ) for type, sett of @config

			@router = @module.router = new marionette.AppRouter
				appRoutes: @getRoutes()
				controller: @

			return

		initRoute: ( type, sett )=>
			@[ "_" + type ] = =>@checkInitialized( @[ type ], arguments )
			App.vent.on( sett.event, @[ "_" + type ] )
			return

		getRoutes: =>
			_routes = {}
			for type, sett of @config
				_routes[ sett.route ] = "_" + type
			_routes

		checkInitialized: ( cb, args )=>
			if @module._isInitialized
					cb.apply( cb, args )
				else
					@module.on "start", =>
						cb.apply( cb, args )
						return
			return

		navigate: ( type, data )=>
			if not @config[ type ]?
				_err new Error()
				_err.name = "invalid-route-type"
				_err.message = "the type `#{type}` not exists in map."
				throw _err
			else
				_route = @config[ type ].route
				if data?
					for _k, _v of data
						_route = _route.replace( ":#{_k}", _v )

				Backbone.history.navigate( _route, trigger: false )
				@module.app.vent.trigger( "navigate:after", _route, @module )
			return