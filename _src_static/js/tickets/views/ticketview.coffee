define [ "marionette", "moment", "showdown", "app", "tmpl", "collections", "tickets/collections" ], ( marionette, moment, Showdown, App, tmpl, AppCollections, collections )->
	_mdconverter = new Showdown.converter()
	class CommentView extends marionette.ItemView
		template: tmpl.comment
		tagName: "li"
		className: =>
			"comment #{@model.get( "type" ) or "user"}"

		serializeData: =>
			_data = @model?.toJSON() or {}
			if _data?.content?.length
				_data.content = _mdconverter.makeHtml( _data?.content )
			_author = AppCollections?.users?.get( _data.author )
			_data.author = _author?.toJSON() or {}
			_data.changed = moment( _data.changedtime * 1000 ).fromNow()
			return _data

	class TicketView extends marionette.CompositeView
		template: tmpl.ticketview
		itemViewContainer: "#comments"
		itemView: CommentView
		className: "ticketdetail"

		events: 
			"submit form": "save"
			"click .setstate": "changeState"

		modelEvents:
			"change": "render"	

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
			$( "#ticket-desc" ).val( "" )
			return

		tolist: =>
			App.vent.trigger( "tickets:list" )
			return

		changeState: ( event )=>
			_state = $( event.currentTarget ).data( "state" ).toUpperCase()

			$.ajax
				url: "/api/tickets/state/#{_state}/#{@model.id}"
				method: "GET"
				success: =>
					_set = 
						state: _state

					if _state is "ACCEPTED"
						_set.editor = window.Init.uid

					@model.set( _set )

					if _state is "CLOSED"
						@tolist()
						return

					@collection.fetch()
					return
				error: =>
					console.log "ERROR", arguments
					return
			#@model.save( state: _state )
			return

		serializeData: =>
			_data = @model?.toJSON() or {}
			if _data?.desc?.length
				_data.desc = _mdconverter.makeHtml( _data?.desc )
			_user = AppCollections?.users?.get( _data.author )
			_author = AppCollections?.users?.get( _data.author )
			_data.author = _author?.toJSON() or {}
			_editor = AppCollections?.users?.get( _data.editor )
			_data.editor = _editor?.toJSON() or {}
			_data.changed = moment( _data.changedtime * 1000 ).fromNow()
			return _data

	return TicketView