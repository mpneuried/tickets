define [ "backbone"], ( Backbone )->

	{ Model, Collection } = Backbone

	class MenuItem extends Model
		default: 
			title: ""
			url: ""

	class MenuItems extends Collection
		model: MenuItem

	collections = 
		menu: new MenuItems()

	return collections