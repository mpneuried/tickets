sanitizer = require( "sanitizer" )
utils = require( "../../libs/utils" )

module.exports = class ModelTickets extends require( "./basic" )

	defaults: =>
		@extend super,
			states: [ "NEW", "PENDING", "ACCEPTED", "WORKING", "NEEDANSWER", "REPLIED", "CLOSED" ]
			userSetStates: [ "REPLIED", "CLOSED" ]
			idLength: 5
			stdLimit: 50

	statematrix: [
# old	  NEW		PENDING		ACCEPTED	WORKING		NEEDANSWER	REPLIED		CLOSED  | to-set
		[ true,		false,		false,		false,		false,		false,		false ]	# NEW
		[ true,		true,		false,		false,		false,		false,		false ]	# PENDING
		[ true,		true,		true,		false,		false,		false,		false ]	# ACCEPTED
		[ false,	false,		true,		true,		false,		true,		false ]	# WORKING
		[ false,	false,		false,		true,		true,		false,		false ]	# NEEDANSWER
		[ false,	false,		false,		false,		true,		true,		true ]	# REPLIED
		[ false,	false,		true,		true,		false,		true,		true ]	# CLOSED
	]

	constructor: ->
		super
		@stateNEW = @config.states[ 0 ]
		@stateACCEPTED = @config.states[ 2 ]
		@stateCLOSED = _.last( @config.states )
		return

	setState: ( id, state, editor, cb )=>
		if state not in @config.states
			@_handleError( cb, "unkown-state", state: state )
			return 

		if state not in @config.userSetStates and editor.role isnt "DEVELOPER"
			@_handleError( cb, "change-state-forbidden", state: state )
			return 			

		_body = 
			state: state
			editor: editor.uid

		_createSysComment = false
		_comment =
			type: "sys"
			author: editor.uid
			ticket: id

		switch state
			when "ACCEPTED"
				_createSysComment = true
				_comment.content = "Ticket wurde akzeptiert"
			when "WORKING"
				_createSysComment = true
				_comment.content = "Bearbeitung läuft"
			when "NEEDANSWER"
				_createSysComment = true
				_comment.content = "Eine Antwort wird benötigt"
			when "REPLIED"
				_createSysComment = true
				_comment.content = "Ticket-Author hat geantwortet"
			when "CLOSED"
				_createSysComment = true
				_comment.content = "Ticket wurde geschlossen"

		_run = ( err, rMComment )=>
			if err
				cb( err )
				return
			opt = {}
			if rMComment?.length
				opt.addRedisMulti = rMComment
			@update( id, _body, cb, opt )

			return

		if _createSysComment
			@app.models.comments.create _comment, _run, 
		else
			run( null )
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

		@redis.zrevrangebyscore @_rKey( null, _type ), "+inf", "-inf", "LIMIT", _offset or 0, _limit, ( err, ids )=>
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

	_update: ( id, data, current, cb, opt )=>
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

		if opt?.addRedisMulti?.length
			rM = rM.concat( opt.addRedisMulti )

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

			_pick = [ "title", "desc" ]

			if data?.title?.length
				data.title = utils.trim( sanitizer.escape( data.title ) )

			if data?.desc?.length
				data.desc = utils.trim( sanitizer.escape( data.desc ) )

			if id?
				data = _.pick( data, _pick.concat( [ "state", "editor" ] ) )

				data.changedtime = sec

				if data?.state?.length and data.state isnt current.state and data?.state not in @config.states[1..]
					@_handleError( cb, "validation-state", states: @config.states[1..] )
					return
			
				if data?.state?.length and not @statematrix[ @config.states.indexOf( data.state ) ][ @config.states.indexOf( current.state ) ]
					@_handleError( cb, "validation-state-change", current: current.state, set: data.state )
					return			

				if not data?.desc?.length
					data.desc = ""

				data.closedtime = 0
				if data.state? and data.state is @stateCLOSED
					data.closedtime = sec

				if data.state? and data.state is @stateACCEPTED
					data.acceptedtime = sec

					if not data?.editor?.length or data.editor.length isnt ( @app.models?.users?.config?.idLength or 5 )
						@_handleError( cb, "validation-editor" )
						return

					@_validateUser data?.editor, ( err )=>
						if err
							cb( err )
							return
						cb( null, data )	
						return						
				else
					delete data.editor
					cb( null, data )


			else

				data = _.pick( data, _pick.concat( [ "author" ] ) )

				if not data?.author?.length or data.author.length isnt ( @app.models?.users?.config?.idLength or 5 )
					@_handleError( cb, "validation-author" )
					return

				if not data?.title?.length
					@_handleError( cb, "validation-title" )
					return

				if not data?.desc?.length
					data.desc = ""

				data.state = @stateNEW
				data.starttime = sec
				data.changedtime = sec
				data.acceptedtime = 0
				data.closedtime = 0
				data.editor = null

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
			"validation-editor": "You have to define a valid editor"
			"validation-state": "You have to define a state of (<%= states.join( ', ' ) %>)"
			"validation-state-change": "It is not allowed to change the state from `<%= current %>` to `<%= set %>`"
			"validation-query-limit": "You can only use a number as limit"
			"unkown-state": "The state `<%= state %>` is unkown. Pleasde use one of <%= states.join( ', ' ) %>"
			"change-state-forbidden": "Only a developer can set the state `<%= state %>`"