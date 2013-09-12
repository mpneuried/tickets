module.exports = class RestCrudBasic extends require( "./basic" )

	defaults: =>
		return @extend true, super,
			use: 
				list: true
				get: true
				create: true
				update: true
				del: false
			onlyDev: 
				list: false
				get: false
				create: false
				update: false
				del: true

	createRoutes: ( basepath, express )=>

		express.get( "#{basepath}/:id", @_checkAuth( @config.onlyDev.get ), @_checkRight( @name, "get" ), @get ) if @config.use.get

		express.put( "#{basepath}/:id", @_checkAuth( @config.onlyDev.update ), @_checkRight( @name, "update" ), @update ) if @config.use.update

		express.del( "#{basepath}/:id", @_checkAuth( @config.onlyDev.del ), @_checkRight( @name, "del" ), @del ) if @config.use.del

		express.get( "#{basepath}", @_checkAuth( @config.onlyDev.list ), @_checkRight( @name, "list" ), @list ) if @config.use.list

		express.post( "#{basepath}", @_checkAuth( @config.onlyDev.create ), @_checkRight( @name, "create" ), @create ) if @config.use.create

		return

	get: ( req, res )=>
		_id = req.params.id

		@model.get _id, @_expressReturn( "get", res )
		return

	list: ( req, res )=>
		_query = req.query or {}

		@model.list _query, @_expressReturn( "list", res )
		return

	update: ( req, res )=>
		_id = req.params.id
		_body = req.body

		@model.update _id, _body, @_expressReturn( "update", res )
		return

	del: ( req, res )=>
		_id = req.params.id

		@model.del _id, @_expressReturn( "del", res )
		return

	create: ( req, res )=>
		_body = req.body
		@debug "create", _body
		@model.create _body, @_expressReturn( "create", res )
		return

	_beforeSend: ( type, data )=>
		#@debug "_beforeSend", data
		return data

	_expressReturn: ( type, res )=>
		return ( err, data )=>

			data = @_beforeSend( type, data )

			#@debug "express return", type, err, data
			if err
				@_error( res, err )
				return
			@_send( res, data )
			return
		
