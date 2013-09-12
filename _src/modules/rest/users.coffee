module.exports = class RestUsers extends require( "./crud" )
		
	_beforeSend: ( type, data )=>
		if type is "list"
			_ret = []
			for el in data
				_ret.push @_beforeSend( "get", el )
			return _ret
		else
			return _.omit( data, [ "password" ] )
