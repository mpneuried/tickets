bcrypt = require( "bcrypt" )

module.exports = class ModelUsers extends require( "./basic" )

	defaults: =>
		@extend super,
			bcryptRounds: 8
			idLength: 5
			stdLimit: 50

	_list: ( query, cb )=>

		if query.type? and query.type in [ "authors", "developers", "users" ]
			_type = query.type
		else
			_type = "authors"

		@redis.smembers @_rKey( null, _type ), ( err, ids )=>
			if err
				cb( err )
				return

			if not ids?.length
				cb( null, [] )
				return

			rM = []
			for id in ids
				rM.push [ "HGETALL", @_rKey( id ) ]
			@redis.multi( rM ).exec @_handleReturn( "list", ids, cb )
			return
		return

	getByMail: =>
		[ args...,cb ] = arguments
		[ email, exists ] = args
		@redis.hget "#{@prefix}emails", email, ( err, id )=>
			if err
				cb( err )
				return
			if not id?
				if exists
					cb( null, false )
					return
				@_handleError( cb, "not-found" )
				return

			if exists
				cb( null, true )
				return
			@get( id, cb )
			return
		return

	getRandomAvailibleDeveloper: ( cb )=>
		@redis.srandmember @_rKey( null, "availibledevelopers" ), 1, ( err, results )=>
			if err
				cb( err )
				return
			if results?[ 0 ]?
				cb( null, results[ 0 ] )
			else
				@_handleError( null, "no-randomuser-found" )
			return
		return

	_update: ( id, data, current, cb )=>
		rM = []
		mSet = []
		for _k, _v of data
			mSet.push( _k )
			mSet.push( _v )
		rM.push( [ "HMSET", @_rKey( id ) ].concat( mSet ) )

		# update email mapping
		if data.email? and current.email isnt data.email
			rM.push( [ "HDEL", @_rKey( null, "emails" ), current.email ] )
			rM.push( [ "HSET", @_rKey( null, "emails" ), data.email, id ] )

		# update user lists
		if data.role? and current.role isnt data.role
			if data.role is "DEVELOPER"
				rM.push( [ "ZREM", @_rKey( null, "users" ), id ] )
				rM.push( [ "SADD", @_rKey( null, "developers" ), id ] )
			else
				rM.push( [ "ZREM", @_rKey( null, "developers" ), id ] )
				rM.push( [ "SADD", @_rKey( null, "users" ), id ] )

		if data.available isnt current.available
			if data.available
				rM.push( [ "SADD", @_rKey( null, "availibledevelopers" ), id ] )
			else
				rM.push( [ "SREM", @_rKey( null, "availibledevelopers" ), id ] )
		@redis.multi( rM ).exec @_handleReturn( "update", id, data, current, cb )
		return

	_create: ( id, data, cb )=>
		@debug "_create", id, data
		rM = []
		mSet = []
		for _k, _v of data
			mSet.push( _k )
			mSet.push( _v )
		rM.push( [ "HMSET", @_rKey( id ) ].concat( mSet ) )
		rM.push( [ "HSET", @_rKey( null, "emails" ), data.email, id ] )

		rM.push( [ "SADD", @_rKey( null, "authors" ), id ] )

		if data.role is "DEVELOPER"
			rM.push( [ "SADD", @_rKey( null, "developers" ), id ] )
			if data.available
				rM.push( [ "SADD", @_rKey( null, "availibledevelopers" ), id ] )
			else
				rM.push( [ "SREM", @_rKey( null, "availibledevelopers" ), id ] )	
		else
			rM.push( [ "SADD", @_rKey( null, "users" ), id ] )

		@redis.multi( rM ).exec @_handleReturn( "create", id, data, cb )
		return

	_beforeReturn: ( data )=>
		data.available = if data.available is "true" or data.available is true then true else false

		data.notifyCount = parseInt( data.notifyCount, 10 ) or 0
		data.reactionCount = parseInt( data.reactionCount, 10 ) or 0
		data.ticketCount = parseInt( data.ticketCount, 10 ) or 0

		data

	emailRegex: /^[-a-z0-9~!$%^&*_=+}{\'?]+(\.[-a-z0-9~!$%^&*_=+}{\'?]+)*@([a-z0-9_][-a-z0-9_]*(\.[-a-z0-9_]+)*\.([a-z][a-z]+)|([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}))(:[0-9]{1,5})?$/i;
	validate: ( id, current, data, cb )=>
		@debug "validate", id, data
		if id? 

			if data?.short?.length and data?.short?.length > 3
				@_handleError( cb, "validation-short" )
				return

			if data?.email?.length and not @emailRegex.test( data?.email )
				@_handleError( cb, "validation-email" )
				return

			if data?.role?.length and data?.role not in @app.config.roles
				@_handleError( cb, "validation-role", roles: @app.config.roles )
				return

			if data?.password?.length
				salt = bcrypt.genSaltSync( @config.bcryptRounds )
				data.password = bcrypt.hashSync( data.password, salt )
			
			if data?.role is "DEVELOPER" or current?.role is "DEVELOPER"
				if data?.available?
					data.available = Boolean( data.available )

		else
			if not data?.name?.length
				@_handleError( cb, "validation-name" )
				return

			if not data?.short?.length and data?.short?.length > 3
				@_handleError( cb, "validation-short" )
				return

			if not data?.email?.length or not @emailRegex.test( data?.email )
				@_handleError( cb, "validation-email" )
				return

			if not data?.pushkey?.length 
				data.pushkey = null

			if not data?.role?.length or data?.role not in @app.config.roles
				@_handleError( cb, "validation-role", roles: @app.config.roles )
				return

			if not data?.password?.length
				@_handleError( cb, "validation-password", roles: @app.config.roles )
				return
			else
				salt = bcrypt.genSaltSync( @config.bcryptRounds )
				data.password = bcrypt.hashSync( data.password, salt )

			if data.role is "DEVELOPER"
				if data?.available?
					data.available = Boolean( data.available )
			else
				data.available = false

			data.notifyCount = 0
			data.reactionCount = 0
			data.ticketCount = 0

		# stop if email is not updated
		if id? and not data.email?
			cb( null, data )
			return

		if data.email isnt current?.email
			@getByMail data.email, true, ( err, exists )=>
				if err
					cb( err )
					return
				@debug "checked for existing mail", exists
				if exists
					@_handleError( cb, "validation-email-exists", email: data.email )
					return
				cb( null, data )
				return
		else
			cb( null, data )

		return

	ERRORS: =>
		@extend super, 
			"validation-name": "You have to define a name"
			"validation-short": "You have to define a short with max. 3 letters"
			"validation-password": "You have to define a password"
			"validation-email": "You have to define a valid email"
			"validation-role": "You have to define a role of (<%= roles.join( ', ' ) %>)"
			"validation-email-exists": "The given email `<%= email %>` allready exists."
			"no-randomuser-found": "No random user availible"