define [ "marionette", "app", "collections", "users/controller" ], ( marionette, App, AppCollections, Controller )->

	module = App.module( "Users", { startWithParent: false } )

	new Controller( module )

	$.when( AppCollections.users.fetchInit() ).then( ( ->
		_me = AppCollections.users.get( Init.uid )
		_menuList = [ { url: "users/me", title: _me.get( "name" ), icon: "user", sort: 5 } ]

		if Init.role is "DEVELOPER"
			_menuList.push { url: "users", title: "Nutzer", icon: "group", sort: 6 }

		AppCollections.menu.add( _menuList )
		AppCollections.menu.trigger( "reset" )
		module.start()
		return
	), console.error )

	return module