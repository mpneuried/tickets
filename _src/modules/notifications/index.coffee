module.exports = ( app )=>
	for service in app.config.notificationServices
		try
			new ( require( "./#{service}" ) )( app, app._getConfig( "notifications_" + service ) )
		catch _err
			console.warn _err
	return