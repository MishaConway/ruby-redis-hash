require 'spec_helper'

describe RedisHash do
	let(:redis){Redis.new}
	let(:name){"some_hash"}
	let(:hash){described_class.new(name, redis)}

	context "instance methods" do
		describe '#all' do
			subject{ hash.all }

			it 'should return all the items in the hash' do
				redis.hset(name, 'a', 1)
				redis.hset(name, 'b', 2)

				expect(subject).to eq({'a' => '1', 'b' => '2'})
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

			
		end


	end




end