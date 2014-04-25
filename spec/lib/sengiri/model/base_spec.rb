require 'spec_helper'

class SengiriModel < Sengiri::Model::Base
  sharding_group 'sengiri', {
      'sengiri_shards_1'=> {
        adapter: "sqlite3",
        database: "db/sengiri_shards_1.sqlite3",
        pool: 5,
        timeout: 5000,
      },
      'sengiri_shards_second'=> {
        adapter: "sqlite3",
        database: "db/sengiri_shards_2.sqlite3",
        pool: 5,
        timeout: 5000,
      },
    }
end

describe SengiriModel do
  # clear db
  before do
    [1, 'second'].each do |i|
      SengiriModel.shard(i).delete_all
    end
  end

  it 'stores shard names' do
    expect(SengiriModel.shard_names).to eq ['1','second']
  end

  context 'New record creation on shard' do
    subject { SengiriModel.shard('1').new }

    it 'returns shard name' do
      expect(subject.shard_name).to eq '1'
    end

    it 'returns sharding group name' do
      expect(subject.sharding_group_name).to eq 'sengiri'
    end

  end

  context 'Sparated database access' do
    let(:first)  { SengiriModel.shard(1) }
    let(:second) { SengiriModel.shard('second') }

    it 'creates on shard' do
      first.create(name: 'first')
      second.create(name: 'second')
      expect( second.first.name ).to eq 'second'
      expect( first.first.name  ).to eq 'first'
      expect( second.first.name ).to eq 'second'
    end

    it 'gathers records from all shard' do
      first.create  name: 'first'
      first.create  name: 'first_2'
      second.create name: 'second'

      expect( second.count ).to eq 1
      expect( first.count  ).to eq 2

      expect( SengiriModel.all.broadcast.count       ).to eq 3
      expect( SengiriModel.all.broadcast.map(&:name) ).to include('first', 'first_2', 'second')
    end

    it 'starts transactions' do
      begin
        SengiriModel.transaction do
          first.create(name: 'first')
          second.create(name: 'first_2')
          raise # to rollback
        end
      rescue
        expect( SengiriModel.all.broadcast.count ).to eq 0
      end
    end
  end
end
