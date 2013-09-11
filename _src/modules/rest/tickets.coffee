module.exports = class RestTickets extends require( "./crud" )

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

	create: ( req, res )=>
		_body = req.body

		_body.author = req.session.uid

		@model.create _body, @_expressReturn( "create", res )
		return