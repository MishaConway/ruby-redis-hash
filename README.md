# RedisHash

Lightweight wrapper over redis hashes.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis-hash'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis-hash

## Getting started

```ruby
h = RedisHash.new 'completed_customer_ids'
```

Or you can pass in your own instance of the Redis class.

```ruby
h = RedisHash.new 'completed_customer_ids', Redis.new(:host => "10.0.1.1", :port => 6380, :db => 15)
```

A third option is to instead pass your Redis configurations.

```ruby
h = RedisHash.new 'completed_customer_ids', :host => "10.0.1.1", :port => 6380, :db => 15
```

## Using the hash

You can add data to the hash using the set method.

```ruby
# setting a single item
h.set {"hello" => "world"}

# setting multiple items
h.add {"hello" => "world", "goodbye" => "universe"}
```

You can read data from the hash with the get method

```ruby
# reading a single key
h.get "hello"

# reading multiple keys
h.get "hello", "goodbye"
```

You can remove keys from the hash with the remove method
```ruby
# removing a single key
h.remove "hello"  

# removing multiple keys
h.remove "hello", "goodbye" 

```


You can get the size of the hash.

```ruby
h.size
```

You can see if a key exists in the hash.

```ruby
h.include? "hello"
```

You can get all items in the hash.

```ruby
h.all
```

You can get all keys in the hash.

```ruby
h.keys
```

You can get all values in the hash.

```ruby
h.values
```

The hash can be cleared of all items
```ruby
h.clear
```

The hash can also be hash to expire (in seconds).
```ruby
# expire in five minutes
h.expire 60*5
```

You can enumerate the hash in batches.
```ruby
#enumerate through the hash in batches of 100 items per redis op
h.enumerator(100).each{ |i| puts i } 
