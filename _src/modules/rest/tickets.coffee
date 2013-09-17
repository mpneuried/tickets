module.exports = class RestTickets extends require( "./crud" )

	createRoutes: ( basepath, express )=>

		express.get( "#{basepath}/state/:state/:id", @_checkAuth( @config.onlyDev.update ), @_checkRight( @name, "update" ), @setState ) if @config.use.update

		super

	setState: ( req, res )=>
		_id = req.params.id
		_state = req.params.state
		_user = req.session

		@model.setState _id, _state.toUpperCase(), _.pick( _user, ["uid", "name", "short", "role"] ), @_expressReturn( "update", res )
		return

	get: ( req, res )=>
		_id = req.params.id

		_cb = @_expressReturn( "get", res )
		if req.query?.withcomments?
			_expCb = _cb
			_cb = ( err, data )=>
				if err
					_expCb( err )
					return
				@app.models.comments.list ticket: _id, ( err, comments )=>
					if err
						_expCb( err )
						return
					data.comments = comments
					_expCb( null, data )
					return
				return
		@model.get( _id, _cb )
		return

	update: ( req, res )=>
		_id = req.params.id
		_body = _.omit( req.body, [ "state" ] )

		@model.update _id, _body, @_expressReturn( "update", res )
		return

	create: ( req, res )=>
		_body = req.body

		_body.author = req.session.uid

		@model.create _body, @_expressReturn( "create", res )
		return