redis = require("redis")
express = require('express')
RedisStore = require('connect-redis')(express)
http = require( "http" )
path = require( "path" )

root._ = require('lodash')._

module.exports = class AppServer extends require( "../libs/basic" )

	defaults: =>
		@extend super,
			port: 8400,
			host: "localhost"
			basepath: "/"
			authentication: true
			notificationServices: [ "tcsmail", "pushover" ]
			express:
				title: "Support Tickets"
				logger: "dev"
				tmpFolder: null
			redis:
				host: 'localhost'
				port: 6379
				options: {}
				prefix: "mlntckts:"
			roles: [ "USER", "DEVELOPER" ]


	constructor: ( options )->
		super( null, options )
		root._CONFIG = @config

		@express = express()

		@redis = redis.createClient( @config.redis.port, @config.redis.host, @config.redis.options )
		@redisPrefix = @config.redis.prefix

		@on "configured", @load
		@on "loaded", @start

		@rest = {}
		@models = {}

		@configure()

		return

	configure: =>
		
		@express.set( "title", @config.express.title )
		@express.use( @allowCrossDomain )
		@express.use( express.cookieParser() )
		@express.use( express.logger( @config.express.logger ) )
		@express.use( express.compress() )
		@express.use( express.bodyParser( uploadDir: @config.express.tmpFolder ) )
		@express.use( express.session({ key: "tickets", store: new RedisStore( client: @redis, prefix: "sessions:mtckts:" ), secret: "d0d693c0-1613-11e3-8ffd-0800200c9a66" } ) )
		
		#@express.use( express.directory( path.resolve( "./static/" ) ) )

		@express.use( express.static( path.resolve( "./static/" ) ) )

		@express.set('views', path.resolve( './views' ))
		@express.set('view engine', 'jade')

		###
		i18n = require('i18next')
		i18n.init
			fallbackLng: "de"
			resGetPath: 'static/i18n/__lng__/__ns__.json'

		i18n.registerAppHelper(@express)
		###
		@emit "configured"
		return

	load: =>
		# load non rest modules
		@authenticator =  new ( require( "./authenticator" ) )( @, @_getConfig( "authenticator" ) )
		@workflow =  new ( require( "./workflow" ) )( @, @_getConfig( "workflow" ) )
		@notifications =  new ( require( "./notifications" ) )( @, @_getConfig( "notifications" ) )

		# load notification services
		require( "./notifications/" )( @ )

		# init models
		@models.users = new ( require( "./model/users" ) )( "users", @, @_getConfig( "users" ) )
		@models.tickets = new ( require( "./model/tickets" ) )( "tickets", @, @_getConfig( "tickets" ) )
		@models.comments = new ( require( "./model/comments" ) )("comments",  @, @_getConfig( "comments" ) )

		# load rest modules
		@rest.gui = new ( require( "./rest/gui" ) )( @, "gui", @_getConfig( "gui" ) )
		@rest.users = new ( require( "./rest/users" ) )( @, "users", @_getConfig( "users_rest" ), @models.users )
		@rest.tickets = new ( require( "./rest/tickets" ) )( @, "tickets", @_getConfig( "tickets_rest" ), @models.tickets )
		@rest.comments = new ( require( "./rest/comments" ) )( @, "comments", @_getConfig( "comments_rest" ), @models.comments )

		@rest.gui.createRoutes( @config.basepath, @express )
		@rest.users.createRoutes( @config.basepath + "api/users", @express )
		@rest.tickets.createRoutes( @config.basepath + "api/tickets", @express )
		@rest.comments.createRoutes( @config.basepath + "api/comments", @express )

		# init 404 route
		@express.use @send404

		@emit "loaded"

		return

	_getConfig: ( section )=>
		_cnf = @config?[ section ] or {}
		if not _cnf.logging?.severity?
			_cnf.logging =
				severity: @config?.logging?.severity or "warning"
		_cnf

	start: =>
		# we instantiate the app using express 2.x style in order to use socket.io
		server = http.createServer( @express )
		server.listen( @config.port, @config.host )
	
		@log "info", "http listen to port #{@config.host}:#{ @config.port }"
		return

	allowCrossDomain: ( req, res, next ) =>
		res.header "Access-Control-Allow-Origin", "*"
		res.header "Access-Control-Allow-Methods", "GET,PUT,POST,DELETE,OPTIONS"
		res.header "Access-Control-Allow-Headers", "Content-Type, Authorization, Content-Length, X-Requested-With"
		
		# intercept OPTIONS method
		if "OPTIONS" is req.method
			res.send 200
		else
			next()

	send404: ( req, res )=>

		if req.url is "/"
			@rest.gui.redirBase( req, res )
		else
			res.status( 404 )
			res.send( "Page not found!" )

		return