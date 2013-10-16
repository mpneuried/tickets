sanitizer = require( "sanitizer" )
utils = require( "../../libs/utils" )

module.exports = class ModelComments extends require( "./basic" )

	defaults: =>
		@extend super,
			stdLimit: 50


	_get: ( id, cb )=>
		@redis.get @_rKey( id ), @_handleReturn( "get", id, cb )
		return

	_list: ( query, cb )=>

		if not query?.ticket?.length or query.ticket.length isnt ( @app.models?.tickets?.config?.idLength or 5 )
			@_handleError( cb, "validation-ticket" )
			return

		if query.limit? and isNaN( ( _limit = parseInt( query.limit ) ) )
			@_handleError( cb, "validation-query-limit" )
			return
		else
			_limit = _limit or @config.stdLimit
		
		if query.offset? and isNaN( ( _offset = parseInt( query.offset ) ) )
			@_handleError( cb, "validation-query-offset" )
			return		

		@redis.zrevrangebyscore @_rKey( query.ticket, "ticketcomments" ), "+inf", "-inf", "LIMIT", _offset or 0, _limit, ( err, ids )=>
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

		@redis.multi( rM ).exec @_handleReturn( "update", id, data, current, cb )
		return

	_create: ( id, data, cb, opt = {} )=>
		@debug "_create", id, data
		
		rM = []
		rM.push( [ "SET", @_rKey( id ), JSON.stringify( data ) ])
		rM.push( [ "ZADD", @_rKey( data.ticket, "ticketcomments" ), data.createdtime, id ])

		if opt.asmultisatement?
			cb( null, rM )
		else
			@redis.multi( rM ).exec @_handleReturn( "create", id, data, cb )

		return

	validate: ( id, current, data, cb )=>
		@_validateDataAndGetTime data?.author, data?.ticket, ( err, sec, nsec )=>
			if err
				cb( err )
				return
			@debug "validate", id, data

			_omit = [ "createdtime", "changedtime" ]

			if id? 

				data = _.omit( data, _omit.concat( [ "ticket", "author" ] ) )

				if data?.content?.length
					data.content = utils.trim( sanitizer.escape( data.content ) )

				if data?.content? and not data?.content?.length
					@_handleError( cb, "validation-content" )
					return

				data.changedtime = sec
			else

				data = _.omit( data, _omit )

				if not data?.author?.length or data.author.length isnt ( @app.models?.users?.config?.idLength or 5 )
					@_handleError( cb, "validation-author" )
					return

				if not data?.ticket?.length or data.ticket.length isnt ( @app.models?.tickets?.config?.idLength or 5 )
					@_handleError( cb, "validation-ticket" )
					return

				if data?.content?.length
					data.content = utils.trim( sanitizer.escape( data.content ) )

				if not data?.content?.length
					@_handleError( cb, "validation-content" )
					return

				data.createdtime = sec
				data.changedtime = sec


			cb( null, data )
			return
		return


	_generateId: ( data, cb )=>
		cb( null, data.ticket + ":" + data.createdtime )
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
			"validation-ticket": "You have to define a valid ticket"
			"validation-author": "You have to define a valid author"
			"validation-content": "You have to define a valid comment content"
			"validation-query-limit": "You can only use a number as limit"