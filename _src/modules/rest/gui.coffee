module.exports = class Gui extends require( "./basic" )
		
	defaults: =>
		@extend super,
			routeLogin: "login"
			routeAdmin: "tickets"
			usersAdmin: "users"
			routeTicketList: "tickets"
			routeTicketcreator: "tickets"
			routeTicketView: "ticket/:id"

	createRoutes: ( basepath, express )=>
		@basepath = basepath

		express.get "#{basepath}ping", @ping

		express.post "#{basepath}authenticate", @authenticate
		express.get "#{basepath}exit", @_checkAuth( false, @config.routeLogin ), @exit

		express.get "#{basepath}#{ @config.routeLogin }", @loginPage

		express.get "#{basepath}#{ @config.routeAdmin }*", @_checkAuth( false, @config.routeLogin ), @adminPage
		express.get "#{basepath}#{ @config.usersAdmin }*", @_checkAuth( false, @config.routeLogin ), @adminPage

		return

	authenticate: ( req, res )=>
		
		_email = req.body.email 
		_pw = req.body.password

		_redir = req.body.redir
		@app.authenticator.login req, _email, _pw, ( err, sessiondata )=>
			if err
				if req.headers[ 'content-type' ] is "application/json"
					@_error( res, err )
				else
					res.redirect( "#{@basepath}#{ @config.routeLogin }?error=#{err.name}&email=#{_email}" )	
				return

			if _redir?
				res.redirect( _redir )
			else if sessiondata.role is "DEVELOPER"
				res.redirect( "#{@basepath}#{ @config.routeAdmin }" )
			else
				res.redirect( "#{@basepath}#{ @config.usersAdmin }" )

			return

		return

	redirBase: ( req, res )=>
		if req?.session?.role is "DEVELOPER"
			res.redirect( "#{@basepath}#{ @config.routeAdmin }" )
		else if req?.session?.role?
			res.redirect( "#{@basepath}#{ @config.usersAdmin }" )
		else
			redirect = "#{@basepath}#{ @config.routeLogin }"
			_rdir = redirect + if redirect.indexOf( "?" ) >= 0 then "&" else "?" + "redir=" + encodeURIComponent( req.url )
			res.redirect( _rdir )
		return

	exit: ( req, res )=>
		@debug "exit"
		@app.authenticator.exit req, =>
			res.redirect( "#{@basepath}#{ @config.routeLogin }" )
		return

	loginPage: ( req, res )=>
		res.render( "login", req.query )
		return

	ping: ( req, res )=>
		res.send( "OK" )
		return

	adminPage: ( req, res )=>
		_user = req.session
		session = _.pick( _user, ["uid", "name", "short", "role"] )
		res.render( "admin", user: session, version: @app.config.version, apptitle: @app.config.title )
		return
