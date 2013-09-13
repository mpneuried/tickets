define [ "marionette", "app", "collections", "tickets/controller", "tickets/collections" ], ( marionette, App, AppCollections, Controller, collections )->

	module = App.module( "Tickets", { startWithParent: false } )

	new Controller( module )

	AppCollections.menu.add( [ { url: "/tickets", title: "Offene Tickets", icon: "ticket" }, { url: "/tickets/new", title: "Ticket erstellen", icon: "plus-sign" } ] )

	$.when( collections.tickets.fetch(), collections.users.fetch() ).then( ( ->module.start() ), console.error )

	return module