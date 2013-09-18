define [ "marionette", "collections", "tickets/collections", "tmpl" ], ( marionette, AppCollections, collections, tmpl )->

	class EmtyTickets extends marionette.ItemView
		template: tmpl.emptyticketlist

	class Ticket extends marionette.ItemView
		className: "ticket"
		tagName: "LI"
		model: collections.tickets.model
		template: tmpl.ticketlistitem
		serializeData: =>
			_data = @model?.toJSON() or {}
			_author = AppCollections?.users?.get( _data.author )
			_data.author = _author?.toJSON() or {}
			_editor = AppCollections?.users?.get( _data.editor )
			_data.editor = _editor?.toJSON() or {}
			_data.changed = moment( _data.changedtime * 1000 ).fromNow()
			return _data

	return class TicketsList extends marionette.CompositeView
		emptyView: EmtyTickets
		itemView: Ticket
		template: tmpl.ticketlist
		itemViewContainer: "#ticketlist"