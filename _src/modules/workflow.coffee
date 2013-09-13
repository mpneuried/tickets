module.exports = class Workflow extends require( "../libs/basic" )

	initialize: =>
		@app.on "loaded", @start
		return

	start: =>
		@app.models.tickets.on "changed:state", @ticketStateChanged
		@app.models.tickets.on "create", @newTicket

		@app.on "selecteditor", @selectRandomEditor
		@app.on "setnexteditor", @setNextEditor
		return

	newTicket: ( id, ticket )=>
		@app.emit "selecteditor", id, ticket
		return

	ticketStateChanged: ( id, state, laststate )=>
		@debug "state changed", id, state

		@app.models.tickets.get id, ( err, ticket )=>
			if err
				@error "get ticket", err
				return
			
			switch state
				when "PENDING"
					@app.emit "selecteditor", id, ticket
				when "ACCEPTED"
					@app.emit "notify", "accepted", ticket.author, id, ticket
				when "WORKING"
					@app.emit "notify", "working", ticket.author, id, ticket
				when "NEEDANSWER"
					@app.emit "notify", "needanswer", ticket.author, id, ticket
				when "REPLIED"
					@app.emit "notify", "needanswer", ticket.editor, id, ticket
				when "CLOSED"
					@app.emit "notify", "closed", ticket.author, id, ticket
			return

		return

	selectRandomEditor: ( id, ticket )=>
		@app.models.users.getRandomAvailibleDeveloper ( err, editor_id )=>
			if err
				@error "get random developer", err
				return

			if editor_id?
				@setNextEditor( id, editor_id, ticket )	
			else
				@fatal "no random editor availible", id, ticket
			return

		return

	setNextEditor: ( id, editor_id, ticket )=>
		@app.emit "notify", "pending", editor_id, id, ticket
		@app.emit "pendingtimeout", id
		return