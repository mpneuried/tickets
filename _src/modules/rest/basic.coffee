module.exports = class BasicRest extends require( "../../libs/basic" )

	constructor: ( @app, @name, options, @model )->
		@isRest = true
		super( @app, options )

		return

	createRoutes: ( basepath, express )=>

		return

	###
	## _send
	
	`apibase._send( req, data )`
	
	Generic send method to send the results as text or JSON string
	
	@param { Response } res Express Response 
	@param { Any } data Any simple data to send to the client
	
	@api private
	###
	_send: ( res, data, statusCode = 200 )=>

		if _.isString( data )
			res.send( data, statusCode )
		else
			res.json( data, statusCode )

		return


	###
	## _error
	
	`apibase._error( req, err [, statusCode] )`
	
	Generic error method to anser the client with an error. This method also tries to optimize the error with some details out of the **Errors detail helper**
	
	@param { Response } res Express Response 
	@param { Error|Object|String } err The error name or Object
	@param { Number } [statusCode=500] The http status code. This could also be defined via the **Errors detail helper**
	
	@api private
	###
	_error: ( res, err, statusCode = 500 )=>
		
		if _.isString( err )
			if @_ERRORS[ err ]? and ( [ statusCode, msg ] = @_ERRORS[ err ] )
				_err = 
					errorcode: err
					message: msg( err )
				_err.data = err.data if err.data?
				res.json( _err, statusCode )
			else
				res.send( err, statusCode )
		else
			if err instanceof Error
				if @_ERRORS[ err.name ]?
					[ statusCode, msg ] = @_ERRORS[ err.name ]
					_err = 
						errorcode: err.name
						message: err.message or msg( err )
					_err.data = err.data if err.data?
				else
					try 
						_msg = JSON.parse( err.message )
					catch e
						_msg = err.message

					_err = 
						errorcode: err.name
						message: _msg
					_err.data = err.data if err.data?

				if statusCode is 500 and _err.errorcode.indexOf( "validation" ) >= 0
					statusCode = 406

				res.json( _err, statusCode )
			else
				res.json( err.toString(), statusCode )
		return

	_checkAuth: ( onlyDev = false, redirect, redirectNoDev )=>
		return ( req, res, next )=>
			if not @app.config.authentication
				next()
				return
			if not req.session?.uid?
				if redirect?
					_rdir = redirect + if redirect.indexOf( "?" ) >= 0 then "&" else "?" + "redir=" + encodeURIComponent( req.url )
					res.redirect( _rdir )
				else
					@_error( res, "unauthorized" )
			else if onlyDev and req.session.role isnt "DEVELOPER"
				if redirectNoDev?
					res.redirect( redirectNoDev )
				else
					@_error( res, "forbidden" )
			else
				next()
			return

	_checkRight: ( sec, type )=>
		return ( req, res, next )=>
			next()
			return

	ERRORS: =>
		@extend super, 
			"unauthorized": [ 401, "Unauthorized request. Please login" ]
			"forbidden": [ 403, "Forbidden request." ]
			"not-found": [ 404, "Element not found" ]