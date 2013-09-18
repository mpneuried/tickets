define [ "backbone" ], ( Backbone )->

	return class FilterCollection extends Backbone.Collection
		constructor: ->
			super
			@subColls = []
			return

		sub: ( filter )=>
			if _.isFunction( filter )
				fnFilter = filter
			else if _.isArray( filter )
				fnFilter = ( _m )=>
					_m.id in filter
			else if _.isString( filter )
				fnFilter = ( _m )=>
					_m.id is filter
			else
				fnFilter = ( _m )=>
					for _nm, _vl of filter
						if _m.get( _nm ) isnt _vl
							return false
					return true
			_models = @filter fnFilter
			_sub = new @constructor( _models )

			# recheck the model against the filter on change
			@on "change", _.bind( ( fnFilter, _m )->
				toAdd = fnFilter( _m ) 
				added = @get( _m )?
				if added and not toAdd
					@remove( _m )
				else if not added and toAdd
					@add( _m )
				return
			, _sub, fnFilter )

			# add model to base collection on add to sub
			_sub.on "add", _.bind( ( _m )->
				@add( _m )
				return
			, @)

			# add model to sub collection on add to base if it matches the filter
			@on "add", _.bind( ( fnFilter, _m )->
				if fnFilter( _m )
					@add( _m )
				return
			, _sub, fnFilter )

			# remove model from base collection on remove of sub
			_sub.on "remove", _.bind( ( _m )->
				#@remove( _m )
				return
			, @)

			# remove model from base collection on remove of sub
			@on "remove", _.bind( ( _m )->
				@remove( _m )
				return
			, _sub )

			@subColls.push( _sub )

			return _sub
