module CachableModel
  class Dependency
    attr_accessor :cache, :key, :dependent_key
    
    def initialize(cache, key, dependent_key)
      self.cache = cache
      self.key = key
      self.dependent_key = dependent_key
    end
    
    def write
      dependent_keys = (cache.read(cache_key) || []).dup
      dependent_keys << dependent_key
      cache.write(cache_key, dependent_keys)
    end

    def self.read(cache, key)
      cache.read(key) || []
    end

    def cache_key
      [key, "dependendencies"].join("-")
    end    
  end
end