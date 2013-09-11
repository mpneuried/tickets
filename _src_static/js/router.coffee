define [ "marionette" ], ( marionette )->
	
	return class AppRouter extends marionette.AppRouter
		appRoutes: {}

		initialize:=>
			super
			@initPushSate()
			return

		initPushSate: =>
			$( "body" ).on "click", "a:not([data-bypass])", ( event )->
				href = $(event.target).attr('href')
				protocol = this.protocol + '//'
				if href?.slice( protocol.length ) isnt protocol
					event.preventDefault()
					Backbone.history.navigate(href, {trigger: true} )
				return
			return

		controller: {}