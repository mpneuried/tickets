define [ "backbone"], ( Backbone )->

	{ Model, Collection } = Backbone

	class User extends Model
		default: 
			email: ""
			short: "--"
			name: ""
			pushkey: null
			role: "USER"
			availible: false

	class Ticket extends Model
		default: 
			title: ""
			desc: ""
			author: ""
			comments: []

		parse: ( data )=>
			_commentsColl = @get( "comments" )
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

	class Comment extends Model
		urlRoot: =>
			tid = @collection._ticket.id
			return "/api/comments/" + tid

		default: 
			content: ""
			author: ""

	class Users extends Collection
		model: User
		url: "/api/users"

	class Tickets extends Collection
		model: Ticket
		url: "/api/tickets"

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

	collections = 
		tickets: new Tickets()
		users: new Users()

	return collections