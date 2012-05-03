# Memcacher

  Adding tags functionality to memcached without modifying its source. Using node-memcached module by 3rd-Eden.

# Installation

```
npm install memcacher
```

# Usage

Use it like you've used **memcached** module by 3rd-Eden. Memcacher just adds one more option to method **set** - tags. Take a look at such situation: Let's say we
have a list of posts, and when we delete one post, we don't want it to appear on our list of all posts, right? That's where tags come handy. Check out this example:


```coffee-script
Memcacher = require 'memcacher'

Client = new Memcacher ['127.0.0.1:11211']

Client.set key: 'first-post', value: 'first title', expireIn: 2592000, tags: ['first-post-tag'], ->
	Client.set key: 'second-post', value: 'second title', expireIn: 2592000, tags: ['second-post-tag'], ->
		Client.set key: 'posts', value: JSON.stringify(['first title', 'second title']), expireIn: 2592000, tags: ['first-post-tag', 'second-post-tag'], ->
			# all records are saved
			# now, if you will remove record with key "first-post", all records with tag "first-post-tag" will be removed
			Client.del 'first-post', ->
				# if you will try to get record with key "posts", it will be false
				Client.get 'posts', (err, value) ->
					# value is not ['first title', 'second title']
					# it is false
					# and you should calculate your list of posts again, excluding deleted ones
			
			# or, you can remove by tag
			
			Client.delByTag 'second-post-tag', ->
				# record with key "second-post" deleted
```

# Chainable methods

```coffee-script
Client.set(key: 'test-key', value: 'value', expireIn: 2592000, tags: ['some-tag']).get 'test-key', (err, value) ->
	value # 'value'
```

# Tests

Tests made using **mocha**. Run them by doing this:

```
mocha
```

# License 

(The MIT License)

Copyright (c) 2011 Vadim Demedes &lt;sbioko@gmail.com&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.