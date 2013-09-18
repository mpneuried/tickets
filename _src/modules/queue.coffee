RsmqIntervall = require("../libs/rsmqintervall")

module.exports = class Queue extends require( "../libs/basic" )

	defaults: =>
		return @extend true, super,
			accepttimeout: 60 * 10 # in sec.: 10 Min. until another will be notified
			intervall: 30
			queuename: "pendings"

	initialize: =>
		@queue = new RsmqIntervall( @app, @extend( @config, client: @redis, ns: @prefix + "queue" ) )
		@queue.on "ready", @ready
		@queue.on "message", @process
		return


	ready: =>
		@app.on "pendingtimeout", @createAcceptTimeout

		#start the intervall
		@queue.intervall()
		return


	process: ( msgid, ticket_id )=>
		@debug "process message", msgid, ticket_id

		@app.models.tickets.get ticket_id, ( err, ticket )=>
			if err? and err.name is "not-found"
				@queue.del( msgid )
				@queue.next()
			else if err
				@error "get ticket from queue", err
				return

			if ticket.state is "NEW"
				@app.models.tickets.update ticket_id, state: "PENDING", ( err, ticket )=>
					if err
						@error "update to pending state", ticket_id
						return
					@queue.del( msgid )
					@app.emit "selecteditor", ticket_id, ticket
					@queue.next()
					return
			else if ticket.state is "PENDING"
				@app.emit "selecteditor", ticket_id, ticket
				@queue.del( msgid )
				@queue.next()
			else
				@queue.del( msgid )
				@queue.next()
			return

		return

	createAcceptTimeout: ( ticket_id )=>
		@queue.send( ticket_id, @config.accepttimeout )
		return