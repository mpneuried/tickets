utils = require( "../../libs/utils" )

module.exports = class BasicModelHash extends require( "../../libs/basic" )

	constructor: ( @name, @app, options )->
		super( @app, options )

		@redis = @app.redis
		@prefix = @app.redisPrefix

		return

	validate: ( id, current, data, cb )=>
		cb( null, data )
		return

	_rKey: ( id, name )=>
		_key = "#{@prefix}#{ name or @name }"
		_key += ":#{id}" if id?
		return _key

	list: ( query, cb )=>
		@_list( query, cb )
		return

	_list: ( query, cb )=>
		@_handleError( cb, "not-implemented" )
		return

	get: ( id, cb )=>
		@_get( id, cb )
		return

	_get: ( id, cb )=>
		@redis.hgetall @_rKey( id ), @_handleReturn( "get", id, cb )
		return

	has: ( id, cb )=>
		@debug "has", id
		@redis.exists @_rKey( id ), @_handleReturn( "exists", id, cb )
		return

	_beforeReturn: ( data )=>
		return data

	update: ( id, data, cb, opt )=>
		@debug "update", id, data
		@get id, ( err, current )=>
			if err
				cb( err )
				return
			@validate id, current, data, ( err, data )=>
				if err
					cb( err )
					return

				@_update( id, data, current, cb, opt )
			return
		return

	_update: ( id, data, current, cb, opt )=>
		rM = []
		mSet = []
		for _k, _v of data
			mSet.push( _k )
			mSet.push( _v )
		rM.push( [ "HMSET", @_rKey( id ) ].concat( mSet ) )

		@redis.multi( rM ).exec @_handleReturn( "update", id, data, current, cb )

		return

	create: ( data, cb, opt )=>
		@validate null, null, data, ( err, data )=>
			if err
				cb( err )
				return

			@_generateId data, ( err, id )=>
				if err
					cb( err )
					return
				@_create( id, data, cb, opt )
				return
			return
		return

	_create: ( id, data, cb, opt )=>
		rM = []
		mSet = []
		for _k, _v of data
			mSet.push( _k )
			mSet.push( _v )
		rM.push( [ "HMSET", @_rKey( id ) ].concat( mSet ) )

		@redis.multi( rM ).exec @_handleReturn( "create", id, data, cb )
		return

	_generateId: ( data, cb )=>
		_id = utils.randomString( @config.idLength, 1 )
		@debug "_generateId", _id
		@has _id, ( err, exisis )=>
			if err
				cb( err )
				return
			if not exisis
				cb( null, _id )
			else
				@warning "generate id", "generated existing id. So do a retry."
				@_generateId( data, cb )
			return
		return

	_getTime: ( cb )=>
		@redis.time ( err, time )=>
			if err
				cb( err )
				return		
			
			[ s, ns ] = time

			ns = ("000000" + ns)[0..5]
			ms = Math.round( (parseInt( s + ns , 10 ) / 1000 ) )

			cb( null, parseInt( s, 10 ), ms ) 
			return
		return

	_validateUser: ( users, cb )=>
		if not _.isArray( user )
			users = [ users ]

		rM = []
		for user in users
			rM.push( [ "EXISTS", @_rKey( user, "users" ) ]) if user?

		@redis.multi( rM ).exec ( err, results )=>
			if err
				cb( err )
				return

			@debug "_validateUser", results

			for result, idx in results when not result
				@_handleError( cb, "validation-user-notexists", uid: users[ idx ] )
				return

			cb( null ) 
			return

	_validateDataAndGetTime: =>
		[ args..., cb ] = arguments
		[ user, ticket ] = args

		rM = []

		rM.push( [ "TIME" ])
		rM.push( [ "EXISTS", @_rKey( user, "users" ) ]) if user?
		rM.push( [ "EXISTS", @_rKey( ticket, "tickets" ) ]) if ticket?

		@redis.multi( rM ).exec ( err, results )=>
			if err
				cb( err )
				return
			@debug "_validateUserAndGetTime", results

			if user? and not results[ 1 ]
				@_handleError( cb, "validation-author-notexists", uid: user )
				return

			if ticket? and not results[ 2 ]
				@_handleError( cb, "validation-ticket-notexists", tid: ticket )
				return

			[ s, ns ] = results[ 0 ]

			ns = ("000000" + ns)[0..5]
			ms = Math.round( (parseInt( s + ns , 10 ) / 1000 ) )

			cb( null, parseInt( s, 10 ), ms ) 
			return
		return

	_handleReturn: =>
		[ type, args..., cb ] = arguments
		[ id, input, old ] = args
		return ( err, data )=>
			if err
				cb( err )
				return

			if @_convertRawRedis?
				data = @_convertRawRedis( type, data )

			switch type
				when "exists"
					@debug "return exists", data
					cb( null, if data then true else false )
					return
				when "get"
					if not data?
						@_handleError( cb, "not-found" )
						return
					data.id = id
					cb( null, @_beforeReturn( data ) )
					return
				when "list"
					_ret = []
					for el, idx in data when data?
						_el = @_beforeReturn( el )
						_el.id = id[ idx ]
						_ret.push _el
					
					cb( null, _ret )
					return
				when "update"
					@debug "return update", arguments, id, input, old
					for _k, _v of old when input[ _k ]? and input[ _k ] isnt _v
						@emit "changed:#{_k}", id, input[ _k ], _v

					_ret = @extend( true, old, input ) 
					_ret.id = id
					_ret = @_beforeReturn( _ret )
					@emit( "update", id, _ret )
					cb( null, _ret )
					return

				when "create"
					_ret = input
					_ret.id = id
					_ret = @_beforeReturn( _ret )
					@emit( "create", id, _ret )
					@debug "return create", id, _ret
					cb( null, _ret )
					return

			cb( null, data )
			return

	ERRORS: =>
		@extend super, 
			"not-implemented": "This feature has not been implemented"
			"validation-author-notexists": "The user id `<%= uid %>` not exists"
			"validation-user-notexists": "The user id `<%= uid %>` not exists"
			"validation-ticket-notexists": "The ticket id `<%= tid %>` not exists"