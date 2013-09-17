define [ "marionette", "app", "collections", "tickets/controller", "tickets/collections" ], ( marionette, App, AppCollections, Controller, collections )->

	module = App.module( "Tickets", { startWithParent: false } )

	new Controller( module )

	AppCollections.menu.add( [ { url: "/tickets", title: "Offene Tickets", icon: "ticket", sort: 12 }, { url: "/tickets/new", title: "Ticket erstellen", icon: "plus-sign", sort: 11 } ] )
	AppCollections.menu.trigger( "reset" )
	$.when( collections.tickets.fetch(), AppCollections.users.fetch() ).then( ( ->module.start() ), console.error )

	return module