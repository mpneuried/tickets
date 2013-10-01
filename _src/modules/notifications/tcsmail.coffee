MailClient = require 'tcs_node_mail_client'

module.exports = class MailService extends require( "../../libs/basic" )

	defaults: =>
		return @extend true, super,
			mailAppId: null
			mailConfig: {}

	initialize: =>

		if not @config.mailAppId
			@_handleError( "INIT", "no-configuration" )
			return

		@factory = new MailClient( @config.mailAppId, @config.mailConfig )

		@app.on "loaded", @start
		return

	start: =>
		@app.on "sendnotification", @sendMail
		return

	sendMail: ( user, data, cb )=>

		if not user.email?
			cb( null )
			return

		@debug "send mail to #{user.email}"
		mail = @factory.create()
		mail.to( user.email )

		mail.subject( data.subject )

		html = """
<p>Hallo #{ user.name },</p>
<p>#{data.content}</p>
<a href="#{data.link}">#{data.ticket.title}</a>
<p>sent by Support Ticket System</p>
		"""

		mail.html( html )

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
			"no-configuration": "To use the mail service you have to configurate `notifications_tcsmail` in `config.json`"