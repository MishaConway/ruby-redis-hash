require "redis"

class RedisHash
	#class Hash
	attr_reader :name

	VERSION = "0.0.1"

	class InvalidNameException < StandardError;
	end;
	class InvalidRedisConfigException < StandardError;
	end;

	def initialize(name, redis_or_options = {})
		name = name.to_s if name.kind_of? Symbol

		raise InvalidNameException.new unless name.kind_of?(String) && name.size > 0
		@name = name
		@redis = if redis_or_options.kind_of? Redis
			         redis_or_options
			       elsif redis_or_options.kind_of? Hash
				       ::Redis.new redis_or_options
			       else
				       raise InvalidRedisConfigException.new
		         end
	end

	def get *keys
		keys = keys.flatten
		if keys.size > 0
			values = if 1 == keys.size
				         @redis.hget name, keys.first
				       else
					       @redis.hmget name, *keys
			         end

			keys.each_with_index.map do |k,i|
				[k, values[i]]
			end.to_h
		end
	end

	def set hash
		if hash.size > 0
			if 1 == hash.size
				@redis.hset name, hash.keys.first, hash.values.first
			else
				@redis.hmset name, *(hash.map { |k, v| [k, v] }.flatten)
			end
		end
	end

	def set_if_does_not_exist key, value
		@redis.hsetnx(name, key, value)
	end

	def increment_integer_key key, increment_amount
		@redis.hincrby(name, key, increment_amount)
	end

	def increment_float_key key, increment_amount
		@redis.hincrbyfloat(name, key, increment_amount)
	end

	def remove *keys
		keys = keys.flatten
		if keys.size > 0
			@redis.hdel name, *keys
		end
	end

	def all
		@redis.hgetall name
	end

	def keys
		@redis.hkeys name
	end

	def values
		@redis.hvals name
	end

	def include? key
		@redis.hexists(name, key)
	end

	def size
		@redis.hlen name
	end

	alias count size

	def scan cursor = 0, amount = 10, match = "*"
		@redis.hscan name, cursor, :count => amount, :match => match
	end

	def enumerator(slice_size = 10)
		cursor = 0
		Enumerator.new do |yielder|
			loop do
				cursor, items = scan cursor, slice_size
				items.each do |item|
					yielder << {item.first => item.last}
				end
				raise StopIteration if cursor.to_i.zero?
			end
		end
	end

	def clear
		@redis.del name
		{}
	end

	alias flush clear

	def expire seconds
		@redis.expire name, seconds
	end
	#end
end
