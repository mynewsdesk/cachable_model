module CachableModel
  class IDLookup
    attr_accessor :column, :value, :cache

    def initialize(column, value, cache)
      self.column = column
      self.value = value
      self.cache = cache
    end

    def write(id)
      cache.write(key, id)
      Dependency.new(cache, cache.object(id).key, key).write
    end

    def read
      cache.read(key)
    end

    def key
      cache.safe_key("id_lookup", column, value)
    end
  end
end
