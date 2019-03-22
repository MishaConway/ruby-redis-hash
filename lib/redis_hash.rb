require "redis"

class RedisHash
	attr_reader :name

	VERSION = "0.0.4"

	class InvalidNameException < StandardError; end;
	class InvalidRedisConfigException < StandardError; end;

	def initialize(name, redis_or_options = {})
		name = name.to_s if name.kind_of? Symbol

		raise InvalidNameException.new unless name.kind_of?(String) && name.size > 0
		@name = name
		@redis = if redis_or_options.kind_of?(Redis)
			         redis_or_options
			       elsif redis_or_options.kind_of? Hash
				       ::Redis.new redis_or_options
			       elsif defined?(ActiveSupport::Cache::RedisStore) && redis_or_options.kind_of?(ActiveSupport::Cache::RedisStore)
							 @pooled = redis_or_options.data.kind_of?(ConnectionPool)
				       redis_or_options.data
			       elsif defined?(ConnectionPool) && redis_or_options.kind_of?(ConnectionPool)
							 @pooled = true
							 redis_or_options
			       else
				       raise InvalidRedisConfigException.new
		         end
	end

	def get *keys
		keys = keys.flatten
		if keys.size > 0
			values = if 1 == keys.size
				         with{|redis| redis.hget name, keys.first }
				       else
					       with{|redis| redis.hmget name, *keys }
			         end

			keys.each_with_index.map do |k,i|
				[k, values[i]]
			end.to_h
		end
	end

	def set hash
		if hash.size > 0
			with do |redis|
				if 1 == hash.size
					redis.hset name, hash.keys.first, hash.values.first
				else
					redis.hmset name, *(hash.map { |k, v| [k, v] }.flatten)
				end
			end
		end
	end

	def set_if_does_not_exist hash
		with{|redis| redis.hsetnx(name, hash.keys.first, hash.values.first)}
	end

	def increment_integer_key key, increment_amount = 1
		with{|redis| redis.hincrby(name, key, increment_amount)}
	end

	def increment_float_key key, increment_amount = 1
		with{|redis| redis.hincrbyfloat(name, key, increment_amount)}
	end

	def remove *keys
		keys = keys.flatten
		if keys.size > 0
			with{|redis| redis.hdel name, *keys}
		end
	end

	def all
		with{|redis| redis.hgetall name}
	end

	def keys
		with{|redis| redis.hkeys name}
	end

	def values
		with{|redis| redis.hvals name}
	end

	def include? key
		with{|redis| redis.hexists(name, key)}
	end

	def size
		with{|redis| redis.hlen name}
	end

	alias count size

	def scan cursor = 0, amount = 10, match = "*"
		with{|redis| redis.hscan name, cursor, :count => amount, :match => match}
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
		with{|redis| redis.del name}
		{}
	end

	alias flush clear

	def expire seconds
		with{|redis| redis.expire name, seconds}
	end

	private

	def with(&block)
		if pooled?
			@redis.with(&block)
		else
			block.call(@redis)
		end
	end

	def pooled?
		!!@pooled
	end
end
