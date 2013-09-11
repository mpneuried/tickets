define [ "marionette", "tmpl", "collections" ], ( marionette, tmpl, collections )->

	class Menu extends marionette.ItemView
		template: tmpl.menu
		tagName: "li"
		className: "menu"

	class Menus extends marionette.CollectionView
		itemView: Menu
		collection: collections.menu
		className: "menuitems"
		tagName: "ul"

	return Menus