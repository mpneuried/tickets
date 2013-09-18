define [ "marionette", "lib/modulecontroller", "app", "tickets/collections", "tickets/views/ticketlist", "tickets/views/ticketview", "tickets/views/ticketedit" ], ( marionette, ModuleController, App, collections, viewTicketList, viewTicket, viewTicketEdit )->

	return class Controller extends ModuleController

		config: 
			list:
				event: "tickets:list"
				route: "tickets"
			add: 
				event: "tickets:add"
				route: "tickets/new"
			view:
				event: "tickets:view"
				route: "tickets/:id"
			edit:
				event: "tickets:edit"
				route: "tickets/edit/:id"	

		view: ( id )=>
			model = collections.tickets.get( id )
			if not model?
				App.vent.trigger( "tickets:list" )
				return
			App.content.show( new viewTicket( collection: model.get( "comments" ), model: model ) )
			@navigate( "view", id: id )
			return

		list: =>
			App.content.show( new viewTicketList( collection: collections.tickets ) )
			@navigate( "list" )
			return

		add: =>
			App.content.show( new viewTicketEdit( collection: collections.tickets, model: new collections.tickets.model() ) )
			@navigate( "add" )
			return

		edit: ( id )=>
			model = collections.tickets.get( id )
			App.content.show( new viewTicketEdit( collection: collections.tickets, model: model ) )
			@navigate( "edit", id: id )
			return