bcrypt = require( "bcrypt" )
utils = require( "../libs/utils" )

module.exports = class Authenticator extends require( "../libs/basic" )

	login: ( req, email, password, cb )=>

		@app.models.users.getByMail email, ( err, user )=>
			if err
				@_delayError( cb, "login-failed" )
				return

			bcrypt.compare password, user.password, ( err, same )=>
				if err or not same
					@_delayError( cb, "login-failed" )
					return

				@createSession req, user, ( err, sessiondata )=>
					if err
						@_delayError( cb, "login-failed" )
						return
					cb( null, sessiondata )
					return
				return
			return
		return

	exit: ( req, cb )=>
		req.session.destroy( cb )
		return


	createSession: ( req, user, cb )=>
		_data = 
			uid: user.id
			short: user.short
			name: user.name
			role: user.role


		@extend( req.session, _data )
		cb( null, _data )
		return


	# delay errors to handle timing attacks
	###
	## _delayError
	
	`login._delayError( cb, err )`
	
	delay errors to handle timing attacks
	
	@param { Function } cb Callback function 
	@param { Error } err Error object to return delayed 
	
	@api private
	###
	_delayError: ( cb, err )=>
		_delay = utils.randRange( 10, 200 )
		_tfnErr = _.delay( @_handleError, _delay, cb, err )
		return

	ERRORS: =>
		@extend super, 
			"login-failed": "Login faild. Please check your e-mail and password"