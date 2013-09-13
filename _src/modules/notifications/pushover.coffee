PushOver = require 'node-pushover'

module.exports = class PushOverService extends require( "../../libs/basic" )

	defaults: =>
		return @extend true, super,
			apptoken: null

	initialize: =>

		if not @config.apptoken
			@_handleError( null, "no-configuration" )
			return

		@service = new PushOver( token: @config.apptoken )

		@app.on "loaded", @start
		return

	start: =>
		@app.on "sendnotification", @sendPush
		return

	sendPush: ( user, data, cb )=>

		if not user.pushkey?
			cb( null )
			return

		@debug "send push notification to #{user.pushkey} (#{user.short})"
		
		@service.send user.pushkey, data.subject, data.link, ( err, result )=>
			if err
				if cb
					cb( err )
				else
					@error "send push", err
				return
			@debug "send push", result
			cb( null ) if cb
			return
		
		return


	ERRORS: =>
		@extend super, 
			"no-configuration": "To use the pushover service you have to configurate `notifications_pushover.apptoken` in `config.json`"