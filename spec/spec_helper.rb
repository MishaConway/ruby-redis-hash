require_relative 'redis_helper'

RSpec.configure do |config|
	config.include RSpec::RedisHelper, redis: true
end
