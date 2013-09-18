define [ "backbone", "lib/collection" ], ( Backbone, FilterCollection )->

	{ Model, Collection } = Backbone

	class Ticket extends Model
		default: 
			title: ""
			desc: ""
			author: ""
			comments: []

		parse: ( data, options )=>

			if options._ignoreComments
				data = _.omit( data, ["comments"] )
			else
				_commentsColl = @get( "comments" )
				#console.log "parse", data, _commentsColl
				if data.comments?.length
					if _commentsColl?
						_commentsColl.reset( data.comments )
					else
						data.comments = new Comments( data.comments, { ticket: @ } )
				else
					if _commentsColl?
						_commentsColl.reset()
					else
						data.comments = new Comments( [], { ticket: @ })

			return data

		toJSON: ( options )=>
			# prevent from saving comments
			return _.clone( _.omit( this.attributes, ["comments"] ) ) 

	class Comment extends Model
		urlRoot: =>
			tid = @collection._ticket.id
			return "/api/comments/" + tid

		default: 
			content: ""
			author: ""

	class Tickets extends FilterCollection
		model: Ticket
		url: "/api/tickets"
		comparator : ( el )->
			return el.get( "changedtime" ) * -1

	class Comments extends Collection
		model: Comment
		url: =>
			tid = @_ticket.id
			return "/api/comments/" + tid
		initialize: ( models, options )=>
			@_ticket = options.ticket
			return
		fetch: =>
			@_fetched = true
			super
		comparator : ( el )->
			return el.get( "createdtime" )

	_allTicktes = new Tickets()

	collections = 
		tickets: _allTicktes.sub( ( mod )->mod.get( "state" ) isnt "CLOSED" )
		closedtickets: _allTicktes.sub( ( mod )->mod.get( "state" ) is "CLOSED" )

	return collections