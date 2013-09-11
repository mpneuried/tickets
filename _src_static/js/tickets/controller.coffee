define [ "marionette", "app", "tickets/collections", "tickets/views/ticketlist", "tickets/views/ticketview", "tickets/views/ticketedit" ], ( marionette, App, collections, viewTicketList, viewTicket, viewTicketEdit )->

	return class Controller

		routes: 
			'tickets': 'list'
			'tickets/new': 'add'
			'tickets/:id': 'view'
			'tickets/edit/:id': 'edit'

		constructor: ( @module )->

			App.vent.on "tickets:list", @list
			App.vent.on "tickets:view", @view
			App.vent.on "tickets:add", @add
			App.vent.on "tickets:edit", @edit

			@module.router = new marionette.AppRouter
				appRoutes: @routes
				controller: @

			return

		checkInitialized: ( cb, args )=>
			if App.Tickets._isInitialized
					cb.apply( cb, args )
				else
					App.Tickets.on "start", =>
						cb.apply( cb, args )
						return
			return

		list: =>@checkInitialized( @_list, arguments )
		view: =>@checkInitialized( @_view, arguments )
		add: =>@checkInitialized( @_add, arguments )
		edit: =>@checkInitialized( @_edit, arguments )

		_view: ( id )=>

			model = collections.tickets.get( id )
			App.content.show( new viewTicket( collection: model.get( "comments" ), model: model ) )
			#Backbone.navigate(  )
			return

		_list: =>
			console.log arguments
			App.content.show( new viewTicketList( collection: collections.tickets ) )
			return

		_add: =>
			App.content.show( new viewTicketEdit( collection: collections.tickets, model: new collections.tickets.model() ) )
			return

		_edit: ( id )=>
			model = collections.tickets.get( id )
			App.content.show( new viewTicketEdit( collection: collections.tickets, model: model ) )
			return