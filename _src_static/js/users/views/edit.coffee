define [ "marionette", "app", "collections", "tmpl" ], ( marionette, App, collections, tmpl )->

	class UserEdit extends marionette.ItemView
		template: tmpl.useredit
		serializeData: =>
			_data = @model.toJSON()
			_data._isNew = @model.isNew()
			return _data

		events: 
			"submit form": "save"

		modelEvents:
			"change": "tolist"

		collectionEvents: 
			"add": "tolist"

		tolist: =>
			App.vent.trigger( "users:list" )
			return

		formData: =>
			form = @$el.find( "form" )
			data = {}
			for line in form.serializeArray()
				data[ line.name ] = line.value

			if data.password is ""
				delete data.password

			if data.available?
				data.available = true
			else
				data.available = false

			return data

		save: ( event )=>
			event.preventDefault()
			if @model.isNew()
				@collection.create( @formData(), { wait: true } )
			else
				@model.save( @formData(), { _ignoreComments: true } )
			return

	return UserEdit