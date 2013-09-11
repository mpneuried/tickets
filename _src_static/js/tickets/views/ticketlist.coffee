define [ "marionette", "tickets/collections", "tmpl", "tickets/views/ticket", "views/loading" ], ( marionette, collections, tmpl, viewTicket, viewLoading )->

	return class TicketsList extends marionette.CompositeView
		emptyView: viewLoading
		itemView: viewTicket
		template: tmpl.ticketlist
		itemViewContainer: "#ticketlist"