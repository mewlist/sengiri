require 'spec_helper'

describe Sengiri::BroadcastProxy do
  before do
    shard1.create!(name: 'hoge')
    shard1.create!(name: 'fuga')
    shard2.create!(name: 'moge')
    shard2.create!(name: 'hugo')
  end

  describe '#find_by' do
    subject do
      SengiriModel.broadcast.find_by(query)
    end

    let(:query) do
      { name: 'moge' }
    end

    it 'should find just one of all shards in' do
      expect(subject.name).to eq(query[:name])
    end
  end

  describe '#find_by!' do
    subject do
      SengiriModel.broadcast.find_by!(query)
    end

    context 'found it' do
      let(:query) do
        { name: 'hoge' }
      end

      it 'should find just one of all shards in' do
        expect(subject.name).to eq(query[:name])
      end
    end

    context 'record not found' do
      let(:query) do
        { name: '@@@@@@@' }
      end

      it 'should raise error' do
        expect {
          subject
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#exists' do
    subject do
      SengiriModel.where(query).broadcast.exists
    end

    context 'when found in any shards' do
      let(:query) do
        { name: 'moge' }
      end

      it { should be_truthy }
    end

    context 'not found' do
      let(:query) do
        { name: '@@@@@' }
      end

      it { should be_falsey }
    end
  end

  describe 'inherit current scope' do
    subject do
      SengiriModel.where(name: ['hoge', 'fuga']).broadcast
    end

    it 'should merge query' do
      expect(subject.find_by(name: 'hoge')).to be_present
      expect(subject.find_by(name: 'hugo')).to be_nil
    end
  end
end