MailClient = require 'tcs_node_mail_client'

module.exports = class Mailservice extends require( "../libs/basic" )

	defaults: =>
		return @extend true, super,
			mailAppId: null
			mailConfig: {}

	initialize: =>

		if not @config.mailAppId
			@_handleError( null, "no-configuration" )
			return

		@factory = new MailClient( @config.mailAppId, @config.mailConfig )

		@app.on "loaded", @start
		return

	start: =>
		@app.on "sendmail", @sendMail
		return

	sendMail: ( user, data, cb )=>
		@debug "send mail to #{user.email}"
		mail = @factory.create()
		mail.to( user.email )

		mail.subject( data.subject )

		data.content =+ "\n\n" + data.link + "\n\n" + "... sent by Support Ticket System"

		mail.text( data.content )

		mail.send ( err )=>
			if err
				if cb
					cb( err )
				else
					@error "send mail", err
				return
			cb( null ) if cb
			return 
		return


	ERRORS: =>
		@extend super, 
			"no-configuration": "To use the mail service you have to configurate it via `config.json`"