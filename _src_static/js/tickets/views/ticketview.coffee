define [ "marionette", "moment", "tmpl", "tickets/collections" ], ( marionette, moment, tmpl, collections )->

	class CommentView extends marionette.ItemView
		template: tmpl.comment
		tagName: "li"
		className: "comment"

		serializeData: =>
			_data = @model?.toJSON() or {}
			_user = collections?.users?.get( _data.author )
			_data.user = _user?.toJSON() or {}
			_data.changed = moment( _data.changedtime * 1000 ).fromNow()
			return _data

	class TicketView extends marionette.CompositeView
		template: tmpl.ticketview
		itemViewContainer: "#comments"
		itemView: CommentView
		className: "ticketDetail"

		events: 
			"submit form": "save"

		initialize: =>
			super
			@collection = @model.get( "comments" )
			if not @model.isNew() and not @collection._fetched
				@collection.fetch()
			return

		formData: =>
			form = @$el.find( "form" )
			data = {}
			for line in form.serializeArray()
				data[ line.name ] = line.value
			return data

		save: ( event )=>
			event.preventDefault()
			@collection.create( @formData(), wait: true )
			return

		serializeData: =>
			_data = @model?.toJSON() or {}
			_user = collections?.users?.get( _data.author )
			_data.user = _user?.toJSON() or {}
			_data.changed = moment( _data.changedtime * 1000 ).fromNow()
			return _data

	return TicketView