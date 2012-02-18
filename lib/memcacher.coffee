memcached = require 'memcached'
async = require 'async'

class Memcacher
	constructor: (servers = []) ->
		@client = new memcached servers
	
	set: (key, value, expireIn, tags = [], callback) ->
		for tag in tags
			@bindTagToKey tag, key
		@client.set key, value, expireIn, ->
			process.nextTick ->
				callback no if callback
	
	get: (key, callback) ->
		@client.get key, (err, value) ->
			process.nextTick ->
				callback err, value if callback
	
	del: (key, callback) ->
		@remove key, callback
	
	remove: (key, callback) ->
		that = @
		@client.get "#{ key }-tags", (err, value) ->
			return if not value
			
			tags = JSON.parse value
			async.forEach tags, (tag, nextTag) ->
				that.client.get "#{ tag }-keys", (err, value) ->
					return do nextTag if not value
					
					keys = JSON.parse value
					for key in keys
						that.client.del key, ->
					
					do nextTag
			, ->
				that.client.del key, ->
					process.nextTick ->
						callback no if callback
		
	
	bindTagToKey: (tag, key, callback) ->
		that = @
		bindKeys = (done) ->
			that.client.get "#{ tag }-keys", (err, value) ->
				if not value # keys, related to that tag, do not exist
					that.client.set "#{ tag }-keys", JSON.stringify([key]), 2592000, ->
						process.nextTick ->
							do done
				else
					keys = JSON.parse value
					keys.push key
					that.client.set "#{ tag }-keys", JSON.stringify(keys), 2592000, ->
						process.nextTick ->
							do done
		
		bindTags = (done) ->
			that.client.get "#{ key }-tags", (err, value) ->
				if not value # tags, related to that key, do not exist
					that.client.set "#{ key }-tags", JSON.stringify([tag]), 2592000, ->
						process.nextTick ->
							do done
				else
					tags = JSON.parse value
					tags.push tag
					that.client.set "#{ key }-tags", JSON.stringify(tags), 2592000, ->
						process.nextTick ->
							do done
		
		async.parallel [bindKeys, bindTags], ->
			process.nextTick ->
				callback no if callback
	
	close: ->
		do @client.end

module.exports = Memcacher