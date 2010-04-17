module CachableModel
  class CachedObject
    attr_accessor :cache, :id
    
    def initialize(cache, id)
      self.cache = cache
      self.id = id
    end
    
    def read
      cache.read(key)
    end

    def write(object_array)
      cache.write(key, object_array)
    end

    def delete
      cache.delete(key)
    end
    
    def key
      cache.safe_key("find_by_id", id)
    end    
  end
end