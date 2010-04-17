module CachableModel
  class Cache
    attr_accessor :options, :klass
    delegate :read, :write, :to => :data
    
    def initialize(klass, options = {})
      self.klass = klass
      self.options = options
      options[:find_by] = (options[:find_by] ? Array(options[:find_by]).uniq : [])
    end

    def object(id)
      CachedObject.new(self, id)
    end

    def delete(key)
      data.delete(key)
      # Not checking for circular cache dependencies here so eternal loops are possible
      Dependency.read(self, key).each { |dependent_key| delete(dependent_key) }
    end
    
    # Having caching enabled in tests is problematic since the cache can get out of sync with the db
    # in betweeen tests. If you want to keep caching enabled when running tests make sure you do a 
    # Rails.cache.clear in between every test (i.e. in a setup/before block).
    def enabled?
      !Rails.env.test?
    end
    
    # Create a cache key that is safe for memcached
    def safe_key(method, *args)
      "CachableModel[#{klass.name}].#{method}(#{args.join(',')})".gsub(/\s/, "-")[0, 220]
    end

    private

    def data
      Rails.cache
    end
  end
end
