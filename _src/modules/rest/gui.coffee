module.exports = class Gui extends require( "./basic" )
		
	defaults: =>
		@extend super,
			routeLogin: "login"
			routeAdmin: "tickets"
			routeTicketList: "tickets"
			routeTicketcreator: "new"
			routeTicketView: "ticket/:id"

	createRoutes: ( basepath, express )=>
		@basepath = basepath

		express.post "#{basepath}authenticate", @authenticate
		express.get "#{basepath}exit", @_checkAuth( false, @config.routeLogin ), @exit

		express.get "#{basepath}#{ @config.routeLogin }", @loginPage

		express.get "#{basepath}#{ @config.routeAdmin }*", @_checkAuth( true, @config.routeLogin, @config.routeTicketList ), @adminPage

		express.get "#{basepath}#{ @config.routeTicketcreator }", @_checkAuth( false, @config.routeLogin ), @newTicketPage
		express.get "#{basepath}#{ @config.routeTicketView }", @_checkAuth( false, @config.routeLogin ), @ticketPage

		return

	authenticate: ( req, res )=>
		
		_email = req.body.email 
		_pw = req.body.password

		_redir = req.query.redir
		@app.authenticator.login req, _email, _pw, ( err, sessiondata )=>
			if err
				if req.headers[ 'content-type' ] is "application/json"
					@_error( res, err )
				else
					console.log err
					res.redirect( "#{@basepath}#{ @config.routeLogin }?error=#{err.name}&email=#{_email}" )	
				return

			if _redir?
				res.redirect( _redir )
			else if sessiondata.role is "DEVELOPER"
				res.redirect( "#{@basepath}#{ @config.routeAdmin }" )
			else
				res.redirect( "#{@basepath}#{ @config.routeTicketcreator }" )

			return

		return

	redirBase: ( req, res )=>
		if req?.session?.role is "DEVELOPER"
			res.redirect( "#{@basepath}#{ @config.routeAdmin }" )
		else if req?.session?.role?
			res.redirect( "#{@basepath}#{ @config.routeTicketcreator }" )
		else
			res.redirect( "#{@basepath}#{ @config.routeLogin }" )
		return

	exit: ( req, res )=>
		@debug "exit"
		@app.authenticator.exit req, =>
			res.redirect( "#{@basepath}#{ @config.routeLogin }" )
		return

	loginPage: ( req, res )=>
		res.render( "login", req.query )
		return

	adminPage: ( req, res )=>
		_user = req.session
		res.render( "admin", user: _user )
		return

	newTicketPage: ( req, res )=>
		res.send( "newTicketPage" )
		return

	ticketPage: ( req, res )=>
		res.send( "ticketPage" )
		return