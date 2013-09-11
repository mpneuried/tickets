define [ "marionette", "moment", "tickets/collections", "tmpl" ], ( marionette, moment, collections, tmpl )->

	return class Ticket extends marionette.ItemView
		className: "ticket"
		tagName: "LI"
		model: collections.tickets.model
		template: tmpl.ticketlistitem
		serializeData: =>
			_data = @model?.toJSON() or {}
			_user = collections.users.get( _data.author )
			_data.user = _user?.toJSON() or {}
			_data.changed = moment( _data.changedtime * 1000 ).fromNow()
			return _data

