RedisSMQ = require("rsmq")

module.exports = class RsmqIntervall extends require( "./basic" )
	defaults: =>
		return @extend true, super,
			intervall: 30
			queuename: "pendings"
			maxReceiveCount: 10

	initialize: =>
		@on "next", @next
		@on "data", @check

		@queue = new RedisSMQ( client: @redis, ns: @prefix + "queue" )
		@queue.createQueue qname: @config.queuename, ( err, resp )=>
			if err?.name is "queueExists"
				@emit "ready"
				return

			throw err if err

			if resp is 1
				@debug "queue created"
			else
				@debug "queue allready existed"
			@emit "ready"
			return
		return

	send: ( msg, delay = 0 )=>
		@queue.sendMessage { qname: @config.queuename, message: msg, delay: delay }, ( err, resp )=>
			if err
				@error "send pending queue message", err
				return
			@emit "new", resp
			return
		return

	receive: ( _useIntervall = false )=>
		@debug "start receive"
		@queue.receiveMessage qname: @config.queuename, ( err, msg )=>
			@debug "received", msg
			if err
				@emit( "next", true ) if _useIntervall
				@error "receive queue message", err
				return
			if msg?.id
				@emit "data", msg
				@emit "message", msg.id, msg.message
				#@receive( true ) if _useIntervall
			else
				@emit( "next", true ) if _useIntervall
			return
		return

	del: ( id )=>
		@queue.deleteMessage qname: @config.queuename, id: id, ( err, resp )=>
			if err
				@error "delete queue message", err
				return
			@debug "delete queue message", resp
			return
		return

	check: ( msg )=>
		if msg.rc >= @config.maxReceiveCount
			@warning "message received more than #{@config.maxReceiveCount} times. So delete it", msg
			@del( msg.id )

		return


	intervall: =>
		@receive( true )
		return

	next: ( wait = false )=>
		@debug "wait"
		if wait
			clearTimeout( @timeout ) if @timeout?
			@timeout = _.delay( @intervall, @config.intervall * 1000 )
		else
			@intervall()
		return

	stop: =>
		clearTimeout( @timeout ) if @timeout?
		return