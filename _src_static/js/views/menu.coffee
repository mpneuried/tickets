define [ "marionette", "tmpl", "collections" ], ( marionette, tmpl, collections )->

	class Menu extends marionette.ItemView
		template: tmpl.menu
		tagName: "li"
		id: ->
			return if @model.id is "menu" then "open-icon-menu" else null


	class Menus extends marionette.CollectionView
		itemView: Menu
		collection: collections.menu
		id: "navigation"
		tagName: "ul"

	return Menus