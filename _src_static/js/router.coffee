define [ "marionette" ], ( marionette )->
	
	return class AppRouter extends marionette.AppRouter
		appRoutes: {}

		initialize:=>
			super
			@initPushSate()
			return

		initPushSate: =>
			$( "body" ).on "click", "a:not([data-bypass])", ( event )->
				href = $(event.currentTarget).attr('href')
				if href is "#togglemenu"
					event.stopImmediatePropagation()
					event.preventDefault()
					$('#menu').trigger( 'toggle.mm' )
					return
				protocol = this.protocol + '//'
				if href?.slice( protocol.length ) isnt protocol
					event.preventDefault()
					Backbone.history.navigate(href, {trigger: true} )
				return
			return

		controller: {}