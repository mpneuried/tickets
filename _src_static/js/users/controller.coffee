define [ "marionette", "lib/modulecontroller", "app", "collections", "users/views/edit", "users/views/list" ], ( marionette, ModuleController, App, collections, viewUserEdit, viewUserList )->

	return class Controller extends ModuleController

		config: 
			me:
				event: "users:me"
				route: "users/me"
			add: 
				event: "users:add"
				route: "users/new"
			view:
				event: "users:view"
				route: "users/:id"
			list: 
				event: "users:list"
				route: "users"

		me: =>
			model = collections.users.get( Init.uid )
			App.content.show( new viewUserEdit( model: model ) )
			@navigate( "me", id: Init.uid  )
			return

		view: ( id )=>
			model = collections.users.get( id )
			App.content.show( new viewUserEdit( model: model ) )
			@navigate( "me", id: id  )
			return

		add: =>
			App.content.show( new viewUserEdit( collection: collections.users, model: new collections.users.model() ) )
			@navigate( "add" )
			return

		list: =>
			App.content.show( new viewUserList( collection: collections.users ) )
			@navigate( "list" )
			return