module.exports = class RestUsers extends require( "./crud" )
	
	defaults: =>
		return @extend true, super,
			use: 
				list: true
				get: true
				create: true
				update: true
				del: false
			onlyDev: 
				list: false
				get: false
				create: true
				update: false
				del: true

	_beforeSend: ( type, data )=>
		if type is "list"
			_ret = []
			if data?.length
				for el in data
					_ret.push @_beforeSend( "get", el )
			return _ret
		else
			return _.omit( data, [ "password" ] )
