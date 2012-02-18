Memcacher = require '../lib/memcacher'
Client = new Memcacher ['127.0.0.1:11211']
require 'should'

describe 'Memcacher', ->
	describe 'setting record', ->
		it 'should save', (done) ->
			Client.set 'test-key-first', 'first', 2592000, ['test-first'], ->
				Client.set 'test-key-second', 'second', 2592000, ['test-second'], ->
					Client.set 'test-keys', JSON.stringify(['first', 'second']), 2592000, ['test-first', 'test-second'], ->
						do done
	
	describe 'getting record', ->
		it 'should return two keys', (done) ->
			Client.get 'test-keys', (err, value) ->
				keys = JSON.parse value
				keys[0].should.equal('first') and keys[1].should.equal('second')
				do done
	
	describe 'removing one of the records', ->
		it 'should remove record and remove "test-keys" record', (done) ->
			Client.del 'test-key-first', ->
				Client.get 'test-keys', (err, value) ->
					value.should.equal false
					do done
	
	describe 'testing chainable API', ->
		it 'should chain methods', (done) ->
			Client.set('test-key', 'test', 2592000, []).get 'test-key', (err, value) ->
				value.should.equal 'test'
				do done