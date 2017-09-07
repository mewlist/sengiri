module Helpers
  def shard1
    SengiriModel.shard(1)
  end

  def shard2
    SengiriModel.shard('second')
  end
end
