module.exports = class Notifications extends require( "../libs/basic" )

	initialize: =>
		@app.on "loaded", @start
		return

	start: =>
		@app.on "notify", @notify
		return

	notify: ( type, user_id, ticket_id, ticket )=>
		@app.models.users.get user_id, ( err, user )=>
			if err
				@error "get user", err
				return

			@getNotificationContent type, user, ticket_id, ticket, ( err, nData )=>
				if err
					@error "get notification content", err
					return

				@debug "created notification", nData

				@app.emit( "sendnotification", user, nData )

				return
			return
		return

	getNotificationContent: ( type, receiver, ticket_id, ticket, cb )=>

		_link = "http://#{ @app.config.host }"
		if @app.config.port isnt 80
			_link += ":" + @app.config.port
		_link += "/tickets/#{ticket_id}"

		_notificationData = 
			link: _link
			ticket: ticket

		switch	type
			when "pending"
				_notificationData.subject = "Neues Ticket '#{ticket_id}'"
				_notificationData.content = "Ein neues Ticket '#{ticket.title} ( #{ticket_id} )' wurde angelegt."
			when "accepted"
				_notificationData.subject = "Ticket '#{ticket_id}' wurde akzeptiert"
				_notificationData.content = "Das Ticket '#{ticket.title} ( #{ticket_id} )' wurde akzeptiert."
			else
				_notificationData.subject = "Ticket '#{ticket_id}' status '#{type}'"
				_notificationData.content = "Der Status des Ticket '#{ticket.title} ( #{ticket_id} )' wurde auf '#{type}' geändert."

		cb( null, _notificationData )

		return