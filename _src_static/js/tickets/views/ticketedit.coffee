define [ "marionette", "app", "tickets/collections", "tmpl" ], ( marionette, App, collections, tmpl )->

	class TicketEdit extends marionette.ItemView
		template: tmpl.ticketedit
		serializeData: =>
			_data = @model.toJSON()
			_data._isNew = @model.isNew()
			return _data

		events: 
			"submit form": "save"

		modelEvents:
			"change": "toticket"

		collectionEvents: 
			"add": "tolist"

		tolist: =>
			App.vent.trigger( "tickets:list" )
			#Backbone.history.navigate("/tickets", {trigger: true} )
			return

		toticket: =>
			App.vent.trigger( "tickets:view", @model.id )
			#Backbone.history.navigate("/tickets/" + @model.id, {trigger: true} )
			return

		formData: =>
			form = @$el.find( "form" )
			data = {}
			for line in form.serializeArray()
				data[ line.name ] = line.value
			return data

		save: ( event )=>
			event.preventDefault()

			if @model.isNew()
				@collection.create( @formData(), { wait: true } )
			else
				@model.save( @formData(), { _ignoreComments: true } )
			return

	return TicketEdit