define [ "marionette", "collections", "tmpl" ], ( marionette, collections, tmpl )->

	class User extends marionette.ItemView
		className: "ticket"
		tagName: "LI"
		model: collections.users.model
		template: tmpl.userlistitem

	return class UsersList extends marionette.CompositeView
		itemView: User
		itemViewContainer: "#userlist"
		template: tmpl.userlist
