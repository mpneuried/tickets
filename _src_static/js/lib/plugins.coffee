define [ ], ->

	class DeleteButton
		defaults:
			# time in ms to automatic return to the default skin
			wait: 5000
			# time until the button will receive a real delete click
			clickdiff: 300
			# class to add
			attensionClass: "attention"
			# attribute data key with text
			confirm: "confirm"
			
		constructor: ( el, options )->

			@el = $( el ) 

			@options = _.extend( {}, @defaults, options )
			@_lastClick = 0
			@_cactive = false

			@_initialized = false
			@init()
			return

		delegate: =>
			@el.on( "click", @_onClick )
			return

		init: =>
			@delegate()
			
			@_initialized = true
			return

		_confirm: ( event )=>
			@_lastClick = event.timeStamp if event?.timeStamp
			if not @_cactive
				
				@el.on( "mouseenter", @_onEnter )
				@el.on( "mouseleave", @_onLeave)


				@_clearTimeout()
				@_cactive = true
				@el.addClass( @options.attensionClass ).button( @options.confirm )
				@_startTimeout()
			return

		_unconfirm: =>
			if @_cactive
				@el.off( "mouseenter", @_onEnter )
				@el.off( "mouseleave", @_onLeave)

				@_clearTimeout()
				@el.removeClass( @options.attensionClass ).button( "reset" )
				@_cactive = false
				@el
			return

		_startTimeout: =>
			@_clearTimeout()
			@_timeout = setTimeout( @_unconfirm, @options.wait )
			return

		_clearTimeout: =>
			clearTimeout( @_timeout ) if @_timeout
			return

		_resetTimeout: =>
			@_clearTimeout()
			@_startTimeout()
			return

		_onClick: ( event )=>
			if not @_cactive
				event.preventDefault()
				event.stopPropagation()
				@_confirm( event )
				false
			else
				if @_lastClick + @options.clickdiff < event.timeStamp
					@_lastClick = event.timeStamp
					@el.trigger( "delete.deletebutton" )
					true
				else
					event.preventDefault()
					event.stopPropagation()
					@_confirm( event )
					false

		_onEnter: ( event )=>
			if @_cactive
				@_resetTimeout()
			return

		_onLeave: ( event )=>
			@_unconfirm()
			return

	# Search PLUGIN DEFINITION
	# =====================
	$.fn.deletebutton = ( option )->
		return @each ()->
			_this = $( @ )
			data = _this.data()
			options = _.extend( data, option )
			newInst = new DeleteButton( @, options ) 
			_this.data( 'deletebutton', newInst )
			return

	$( 'body' ).on 'mouseenter.deletebutton.data-api', '[data-toggle^=deletebutton]', ( el )->
		$( @ ).removeAttr( "data-toggle" ).deletebutton( $( @ ).data() )
		return

	return