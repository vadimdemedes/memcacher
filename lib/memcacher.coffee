memcached = require 'memcached'
async = require 'async'

class Memcacher
	constructor: (servers = []) ->
		@client = new memcached servers
	
	set: (options, callback) ->
		if options.tags
			for tag in options.tags
				@bindTagToKey tag: tag, key: options.key
		
		@client.set options.key, options.value, options.expireIn or options.expire_in, ->
			callback no if callback
		
		@
	
	get: (options, callback) ->
		key = if typeof options is 'object' then options.key else options
		
		@client.get key, (err, value) ->
			callback err, value if callback
		
		@
	
	delByTag: (options, callback) ->
		tag = if typeof options is 'object' then options.tag else options
		
		that = @
		
		@client.get "#{ tag }-keys", (err, value) ->
			return callback no if not value
			
			that.client.del "#{ tag }-keys", ->
			async.forEach JSON.parse(value), (key, nextKey) ->
				that.client.del key, ->
					do nextKey
			, ->
				callback no if callback
		
		@
	
	del: (options, callback) ->
		key = if typeof options is 'object' then options.key else options
		
		that = @
		
		@client.get "#{ key }-tags", (err, value) ->
			return callback no if not value
			
			async.forEach JSON.parse(value), (tag, nextTag) ->
				that.delByTag tag, nextTag
			, ->
				that.client.del "#{ key }-tags", ->
				that.client.del key, ->
					callback no if callback
		
		@
	
	bindTagToKey: (options, callback) ->
		that = @
		
		bindKeys = (done) ->
			that.client.get "#{ options.tag }-keys", (err, value) ->
				if not value # keys, related to that tag, do not exist
					that.client.set "#{ options.tag }-keys", JSON.stringify([options.key]), 2592000, ->
						do done
				else
					keys = JSON.parse value
					keys.push options.key
					that.client.set "#{ options.tag }-keys", JSON.stringify(keys), 2592000, ->
						do done
		
		bindTags = (done) ->
			that.client.get "#{ options.key }-tags", (err, value) ->
				if not value # tags, related to that key, do not exist
					that.client.set "#{ options.key }-tags", JSON.stringify([options.tag]), 2592000, ->
						do done
				else
					tags = JSON.parse value
					tags.push options.tag
					that.client.set "#{ options.key }-tags", JSON.stringify(tags), 2592000, ->
						do done
		
		async.parallel [bindKeys, bindTags], ->
			callback no if callback
	
	close: ->
		do @client.end
	
	end: ->
		do @close

module.exports = Memcacher