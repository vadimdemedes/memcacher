Memcacher = require '../lib/memcacher'
Client = new Memcacher ['127.0.0.1:11211']
require 'should'

describe 'Memcacher', ->
	it 'should save records', (done) ->
		Client.set key: 'test-key-first', value: 'first', expireIn: 360, tags: ['test-first'], ->
			Client.set key: 'test-key-second', value: 'second', expireIn: 360, tags: ['test-second'], ->
				Client.set key: 'test-keys', value: JSON.stringify(['first', 'second']), expireIn: 360, tags: ['test-first', 'test-second'], ->
					do done
	
	it 'should get record', (done) ->
		Client.get 'test-keys', (err, value) ->
			keys = JSON.parse value
			keys[0].should.equal('first') and keys[1].should.equal('second')
			do done

	it 'should remove record', (done) ->
		Client.del 'test-key-first', ->
			Client.get 'test-keys', (err, value) ->
				value.should.equal false
				do done
	
	it 'should chain methods', (done) ->
		Client.set(key: 'test-key', value: 'test', expireIn: 360).get 'test-key', (err, value) ->
			value.should.equal 'test'
			do done