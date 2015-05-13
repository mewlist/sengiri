module Sengiri
  require "sengiri/model/base"
  require "sengiri/railtie" if defined? Rails
end


module ActiveRecord
  class Relation
    def broadcast
      records = []
      klass.shard_names.each do |shard_name|
        records += shard(shard_name).find_by_sql(to_sql)
      end
      @records = records
      @records
    end
  end
end
