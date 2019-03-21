require 'spec_helper'

describe RedisHash do
	let(:redis){Redis.new}
	let(:name){"some_hash"}
	let(:hash){described_class.new(name, redis)}

	before do
		redis.flushall
	end

	context "instance methods" do
		describe '#all' do
			subject{ hash.all }

			it 'should return all the items in the hash' do
				redis.hset(name, 'a', 1)
				redis.hset(name, 'b', 2)

				expect(subject).to eq({'a' => '1', 'b' => '2'})
			end
		end

		describe '#keys' do
			subject{ hash.keys }

			it 'should return all the keys in the hash' do
				redis.hset(name, 'a', 1)
				redis.hset(name, 'b', 2)

				expect(subject).to eq(%w(a b))
			end
		end

		describe '#values' do
			subject{ hash.values }

			it 'should return all the keys in the hash' do
				redis.hset(name, 'a', 1)
				redis.hset(name, 'b', 2)

				expect(subject).to eq(%w(1 2))
			end
		end

		describe '#size' do
			subject{ hash.size }

			it 'should return all the keys in the hash' do
				redis.hset(name, 'a', 1)
				redis.hset(name, 'b', 2)

				expect(subject).to eq(2)
			end
		end

		describe '#clear' do
			subject{ hash.clear }

			it 'should return all the keys in the hash' do
				redis.hset(name, 'a', 1)
				redis.hset(name, 'b', 2)

				expect(subject).to eq({})
				expect(redis.hlen name).to eq(0)
				expect(hash.size).to eq(0)
			end
		end

		describe '#include?' do
			it 'should return all the keys in the hash' do
				redis.hset(name, 'a', 1)
				redis.hset(name, 'b', 2)

				expect(hash.include?('a')).to be true
				expect(hash.include?('b')).to be true
				expect(hash.include?('c')).to be false
			end
		end

		describe '#get' do
		  subject{ hash.get keys}

		  before do
			  redis.hset(name, 'a', 1)
			  redis.hset(name, 'b', 2)
		  end

			context 'getting a single key' do
			  let(:keys){ 'a' }

				it 'gets the single value' do
				  expect(subject).to eq('a' => '1')
				end
			end

			context 'getting multiple keys' do
			  let(:keys){ %w(a b) }

				it 'gets all of the values' do
					expect(subject).to eq({'a' => '1', 'b' => '2'})
				end

				context 'getting multiple keys in reverse order' do
				  let(:keys){ %w(b a) }

				  it 'gets all of the values in reverse order' do
					  expect(subject).to eq({'b' => '2', 'a' => '1'})
				  end
				end
			end
		end


		describe '#set' do
			subject{ hash.set items }

			before do
			  # verify our hash is empty or else our tests won't be reliable
				expect(redis.hlen name).to eq(0)
			end

			context 'setting a single item' do
			  let(:items){ {'cool' => '111'} }

			  it 'can set a single item' do
					subject

				  expect(hash.all).to eq(items)
			  end
			end

			context 'setting multiple items' do
			  let(:items){ {'cool' => '111', 'awesome' => '222'} }

			  it 'can set multiple items' do
				  subject

				  expect(hash.all).to eq(items)
			  end

				context 'setting multiple items in reverse order' do
					let(:items){ {'awesome' => '222', 'cool' => '111'} }

					it 'can set multiple items' do
						subject

						expect(hash.all).to eq(items)
					end
				end
			end

			context 'setting multiple items in succession' do
			  it 'can set multiple items in succession' do
			    hash.set :x => 3
				  hash.set :y => 4, :z => 5
			    expect(hash.all).to eq({'x' => '3', 'y' => '4', 'z' => '5'})
			  end
			end
		end

		describe '#remove' do
		  subject{ hash.remove keys}

		  before do
			  redis.hset(name, 'a', 1)
			  redis.hset(name, 'b', 2)
			  redis.hset(name, 'c', 3)
		  end

			context 'removing a single key' do
				let(:keys){ 'a' }

				it 'removes a single key' do
					expect(redis.hlen name).to eq(3)
					subject
					expect(redis.hlen name).to eq(2)
					expect(hash.keys).to eq(%w(b c))
					expect(hash.all).to eq({'b' => '2', 'c' => '3'})
				end
			end

			context 'removing multiple keys' do
			  let(:keys){ %w(a c) }

				it 'removes multiple keys' do
					expect(redis.hlen name).to eq(3)
					subject
					expect(redis.hlen name).to eq(1)
					expect(hash.keys).to eq(%w(b))
					expect(hash.all).to eq({'b' => '2'})
				end
			end
		end


		describe '#set_if_does_not_exist' do
			let(:new_value){ 'some_value' }

		  before do
			  redis.hset(name, 'a', 1)
			  redis.hset(name, 'b', 2)
			  redis.hset(name, 'c', 3)
		  end

			subject{ hash.set_if_does_not_exist key => new_value}

			context 'when the key already exists' do
			  let(:key){'b'}
			  let(:old_value){'2'}

				it 'should do nothing' do
			    subject
					expect(hash.get(key)).to eq({key => old_value})
			  end
			end

			context 'when the key does not exist yet' do
			  let(:key){'d'}

				it 'should set the key' do
				  subject
					expect(hash.get(key)).to eq({key => new_value})
				end
			end
		end

		describe '#increment_integer_key' do
			before do
				redis.hset(name, 'a', 1)
				redis.hset(name, 'b', 2)
				redis.hset(name, 'c', 3)
			end

			it 'should increment integer keys' do
			  expect(hash.get(%w(a b c))).to eq({'a' => '1', 'b' => '2', 'c' => '3'})

				hash.increment_integer_key 'b'
			  expect(hash.get(%w(a b c))).to eq({'a' => '1', 'b' => '3', 'c' => '3'})

			  hash.increment_integer_key 'a', 5
			  expect(hash.get(%w(a b c))).to eq({'a' => '6', 'b' => '3', 'c' => '3'})
			end
		end

		describe '#increment_float_key' do
			before do
				redis.hset(name, 'a', 1.1)
				redis.hset(name, 'b', 2.2)
				redis.hset(name, 'c', 3.6)
			end

			it 'should increment integer keys' do
				expect(hash.get(%w(a b c))).to eq({'a' => '1.1', 'b' => '2.2', 'c' => '3.6'})

				hash.increment_float_key 'b'
				expect(hash.get(%w(a b c))).to eq({'a' => '1.1', 'b' => '3.2', 'c' => '3.6'})

				hash.increment_float_key 'a', 5
				expect(hash.get(%w(a b c))).to eq({'a' => '6.1', 'b' => '3.2', 'c' => '3.6'})
			end
		end
	end
end