module.exports = class ModelTickets extends require( "./basic" )

	defaults: =>
		@extend super,
			states: [ "NEW", "REJECTED", "ACCEPTED", "WORKING", "WAITFORREPLY", "CLOSED" ]
			idLength: 5
			stdLimit: 50

	constructor: ->
		super
		@stateNEW = @config.states[ 0 ]
		@stateACCEPTED = @config.states[ 2 ]
		@stateCLOSED = _.last( @config.states )
		return

	_get: ( id, cb )=>
		@redis.get @_rKey( id ), @_handleReturn( "get", id, cb )
		return

	_list: ( query, cb )=>
		if query.type? and query.type in [ "open", "closed" ]
			_type = query.type + "tickets"
		else
			_type = "opentickets"

		if query.limit? and isNaN( ( _limit = parseInt( query.limit ) ) )
			@_handleError( cb, "validation-query-limit" )
			return
		else
			_limit = _limit or @config.stdLimit
		
		if query.offset? and isNaN( ( _offset = parseInt( query.offset ) ) )
			@_handleError( cb, "validation-query-offset" )
			return		

		@redis.zrangebyscore @_rKey( null, _type ), "-inf", "+inf", "LIMIT", _offset or 0, _limit, ( err, ids )=>
			if err
				cb( err )
				return

			if not ids?.length
				cb( null, [] )
				return

			args = [ "MGET" ]
			for id in ids
				args.push( @_rKey( id ) )
			@redis.multi( [ args ] ).exec @_handleReturn( "list", ids, cb )
			return
		return

	_update: ( id, data, current, cb )=>
		rM = []
		mSet = []

		data = @extend( true, {}, current, data )

		rM.push( [ "SET", @_rKey( id ), JSON.stringify( data ) ])

		# update email mapping
		if data.state is @stateCLOSED
			rM.push( [ "ZADD", @_rKey( null, "closedtickets" ), data.closedtime, id ])
			rM.push( [ "ZREM", @_rKey( null, "opentickets" ), id ])
		else
			rM.push( [ "ZADD", @_rKey( null, "opentickets" ), data.changedtime, id ])


		@redis.multi( rM ).exec @_handleReturn( "update", id, data, current, cb )
		return

	_create: ( id, data, cb )=>
		@debug "_create", id, data
		rM = []
		rM.push( [ "SET", @_rKey( id ), JSON.stringify( data ) ])
		rM.push( [ "ZADD", @_rKey( null, "opentickets" ), data.starttime, id ])

		@redis.multi( rM ).exec @_handleReturn( "create", id, data, cb )
		return

	validate: ( id, current, data, cb )=>
		@_validateDataAndGetTime ( if not id? then data?.author else null ), ( err, sec, nsec )=>
			if err
				cb( err )
				return
		
			@debug "validate", id, data

			if current?.state is @stateCLOSED
				@_handleError( cb, "validation-closed" )
				return

			_pick = [ "title", "desc" ]

			if id?

				data = _.pick( data, _pick.concat( [ "state" ] ) )

				if data?.state?.length and data.state isnt current.state and data?.state not in @config.states[1..]
					@_handleError( cb, "validation-state", states: @config.states[1..] )
					return

				if data.state? and data.state is @stateACCEPTED
					data.acceptedtime = sec

				if data.state? and data.state is @stateCLOSED
					data.closedtime = sec		

				data.changedtime = sec

			else

				data = _.pick( data, _pick.concat( [ "author" ] ) )

				if not data?.author?.length or data.author.length isnt ( @app.models?.users?.config?.idLength or 5 )
					@_handleError( cb, "validation-author" )
					return

				if not data?.title?.length
					@_handleError( cb, "validation-title" )
					return

				if not data?.desc?.length
					@_handleError( cb, "validation-desc" )
					return

				data.state = @stateNEW
				data.starttime = sec
				data.changedtime = sec
				data.acceptedtime = 0
				data.closedtime = 0

			cb( null, data )
			return
		return

	_convertRawRedis: ( type, data )=>
		switch type
			when "get"
				return JSON.parse( data )
			when "list"
				_json = []
				for el in data[ 0 ]
					_json.push if el? then el else "null"	
				return  JSON.parse( "[" + _json.join( "," ) + "]" )
			else
				return data


	ERRORS: =>
		@extend super, 
			"validation-closed": "It's not allowed to change a closed ticket."
			"validation-title": "You have to define a title"
			"validation-desc": "You have to define a description"
			"validation-author": "You have to define a valid author"
			"validation-state": "You have to define a state of (<%= states.join( ', ' ) %>)"
			"validation-query-limit": "You can only use a number as limit"