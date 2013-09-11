define [ "marionette", "tmpl" ], ( marionette, tmpl )->

	return class Loading extends marionette.ItemView
		template: tmpl.loading

