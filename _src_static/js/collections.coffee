define [ "backbone", "lib/collections" ], ( Backbone, Collections )->

	{ Model } = Backbone

	class MenuItem extends Model
		default: 
			title: ""
			url: ""

	class User extends Model
		default: 
			email: ""
			short: "--"
			name: ""
			pushkey: null
			role: "USER"
			availible: false

	class MenuItems extends Collections.Collection
		model: MenuItem
		comparator: ( a, b )->
			_a = a.get( "sort" )
			_b = b.get( "sort" )
			if _a > _b
				return 1
			else if _a < _b
				return -1
			else
				return 0

	class Users extends Collections.Collection
		model: User
		url: "/api/users"

	collections = 
		menu: new MenuItems( [ { id: "menu", title: "Menu", url: "#togglemenu", icon: "ellipsis-vertical" } ] )
		users: new Users()

	return collections