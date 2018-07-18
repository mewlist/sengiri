require 'spec_helper'

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

  context 'separated database access' do
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
      expect {
        begin
          SengiriModel.transaction do
            first.create(name: 'first')
            second.create(name: 'first_2')
            raise # to rollback
          end
        rescue
        end
      }.to_not change { SengiriModel.all.broadcast.count }
    end
  end

  context 'has no databases' do
    it 'should raise an error' do
      expect {
        class SengiriModelWithoutDatabases < Sengiri::Model::Base
          sharding_group 'sengiri', confs: {}
        end
      }.to raise_error RuntimeError
    end
  end

  context 'is included in module' do
    let(:sengiri_model) {
      module SengiriModule
        class SengiriModel < Sengiri::Model::Base
          sharding_group 'sengiri', confs: {
              'sengiri_shard_1_rails_env'=> {
                adapter: "sqlite3",
                database: "spec/db/sengiri_shard_1.sqlite3",
                pool: 5,
                timeout: 5000,
              },
              'sengiri_shard_second_rails_env'=> {
                adapter: "sqlite3",
                database: "spec/db/sengiri_shard_2.sqlite3",
                pool: 5,
                timeout: 5000,
              },
            }
        end
      end
    }
    it 'should be normal' do
      expect { sengiri_model }.not_to raise_error
    end
    context 'when sengiri_model is evaluated' do
      before do
        sengiri_model
      end
      it 'should create a new shard class in the module' do
        expect { SengiriModule::SengiriModel1 }.not_to raise_error
      end
    end
  end

  context 'when the other model with the same DB confs exists' do
    before do
      class SengiriModelWithSameDBConfs < Sengiri::Model::Base
        sharding_group 'sengiri', confs: {
            'sengiri_shard_1_rails_env'=> {
              adapter: "sqlite3",
              database: "spec/db/sengiri_shard_1.sqlite3",
              pool: 5,
              timeout: 5000,
            },
            'sengiri_shard_second_rails_env'=> {
              adapter: "sqlite3",
              database: "spec/db/sengiri_shard_2.sqlite3",
              pool: 5,
              timeout: 5000,
            },
          }
      end
    end

    it 'should use the same connections' do
      aggregate_failures 'testing connections' do
        expect(SengiriModel.connection).to be SengiriModelWithSameDBConfs.connection
        expect(SengiriModel.shard('1').connection).to be SengiriModelWithSameDBConfs.shard('1').connection
        expect(SengiriModel.shard('second').connection).to be SengiriModelWithSameDBConfs.shard('second').connection
      end
    end
  end

  context 'when inheriting' do
    it 'should be held individually connection' do
      expect(SengiriModel.connection).to_not be(SengiriModelSubclass.connection)
    end
  end
end
