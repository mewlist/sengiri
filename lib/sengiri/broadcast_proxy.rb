module Sengiri
  class BroadcastProxy
    include Enumerable

    def initialize(shard_classes, scope: nil, max_threads: )
      @shard_classes = shard_classes
      @scope = scope
      @max_threads = max_threads
    end

    def each(&block)
      if block_given?
        to_a.each(&block)
      else
        to_a.each
      end
    end

    def to_a
      parallel(&:to_a).flatten
    end

    def size
      to_a.size
    end

    def find_by(query)
      records = parallel { |relation|
        relation.find_by(query)
      }
      records.detect { |record| record }
    end

    def find_by!(query)
      result = find_by(query)
      if result.nil?
        raise ActiveRecord::RecordNotFound.new("Couldn't find #{query} with an out of range value")
      end
      result
    end

    private

    def parallel
      Parallel.map(@shard_classes, in_threads: @max_threads){ |shard_class|
        shard_class.connection_pool.with_connection do
          yield scoped(shard_class)
        end
      }
    end

    def scoped(shard_class)
      if @scope
        shard_class.merge(@scope)
      else
        shard_class.all
      end
    end
  end
end
