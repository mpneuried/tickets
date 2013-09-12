fs = require "fs"
extend = require( "extend" )

fs.readFile "config.json", ( err, file )=>
	if err?.code is "ENOENT"
		_cnf = {}
	else if err
		throw err
		return
	else
		try 
			_cnf = JSON.parse( file )
		catch err
			err.message = "cannot parse config.json"
			throw err
			return

	_config = extend( true, {}, require( "./modules/config" ), _cnf )

	new ( require "./modules/server" )( _config )

	return