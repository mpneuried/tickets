module.exports = ( app )=>
	for service in app.config.notificationServices
		new ( require( "./#{service}" ) )( app, app._getConfig( "notifications_" + service ) )
	return