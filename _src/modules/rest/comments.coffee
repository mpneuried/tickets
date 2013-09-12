module.exports = class RestComments extends require( "./crud" )

	createRoutes: ( basepath, express )=>

		express.get( "#{basepath}/:tid/:id", @_checkAuth( @config.onlyDev.get ), @_checkRight( @name, "get" ), @get ) if @config.use.get

		express.put( "#{basepath}/:tid/:id", @_checkAuth( @config.onlyDev.update ), @_checkRight( @name, "update" ), @update ) if @config.use.update

		express.del( "#{basepath}/:tid/:id", @_checkAuth( @config.onlyDev.del ), @_checkRight( @name, "del" ), @del ) if @config.use.del

		express.get( "#{basepath}/:tid", @_checkAuth( @config.onlyDev.list ), @_checkRight( @name, "list" ), @list ) if @config.use.list

		express.post( "#{basepath}/:tid", @_checkAuth( @config.onlyDev.create ), @_checkRight( @name, "create" ), @create ) if @config.use.create

		return

	list: ( req, res )=>
		_query = req.query or {}
		_tid = req.params.tid
		
		_query.ticket = _tid

		@model.list _query, @_expressReturn( "list", res )
		return

	update: ( req, res )=>
		_id = req.params.id
		_tid = req.params.tid
		_body = req.body

		_body.ticket = _tid
		_body.type = "user"

		@model.update _id, _body, @_expressReturn( "update", res )
		return

	create: ( req, res )=>
		_body = req.body
		_tid = req.params.tid

		_body.author = req.session.uid

		_body.ticket = _tid
		_body.type = "user"
		
		@debug "create", _tid, _body
		@model.create _body, @_expressReturn( "create", res )
		return
