module CachableModel
  class Cache
    attr_accessor :options, :klass
    
    def initialize(klass, options = {})
      self.klass = klass
      self.options = options
      options[:find_by] = (options[:find_by] ? Array(options[:find_by]).uniq : [])
    end

    def fetch(id, &block)
      Rails.cache.fetch(key(id), &block)
    end

    def key(id)
      safe_key("find_by_id", id)
    end

    def dep_key(key)
      [key, "dependendencies"].join("-")
    end

    def id_lookup_key(column, value)
      safe_key("id_lookup", column, value)
    end

    # Create a cache key that is safe for memcached
    def safe_key(method, *args)
      "CachableModel[#{klass.name}].#{method}(#{args.join(',')})".gsub(/\s/, "-")[0, 220]
    end

    def read_lookup_id(column, value)
      Rails.cache.read(id_lookup_key(column, value))      
    end

    def store_id_lookup(column, value, id)
      Rails.cache.write(id_lookup_key(column, value), id)
      add_dependent_key(key(id), id_lookup_key(column, value))
    end

    def add_dependent_key(key, dependent_key)
      dependent_keys = (Rails.cache.read(dep_key(key)) || []).dup
      dependent_keys << dependent_key
      Rails.cache.write(dep_key(key), dependent_keys)
    end

    def dependent_keys(key)
      Rails.cache.read(dep_key(key)) || []
    end

    def expire(id)
      expire_key(key(id))
    end

    def expire_key(key)
      Rails.cache.delete(key)
      # Not checking for circular cache dependencies here so eternal loops are possible
      dependent_keys(key).each { |dependent_key| expire_key(dependent_key) }
    end
    
    # Having caching enabled in tests is problematic since the cache can get out of sync with the db
    # in betweeen tests. If you want to keep caching enabled when running tests make sure you do a 
    # Rails.cache.clear in between every test (i.e. in a setup/before block).
    def enabled?
      !Rails.env.test?
    end

    def parse_sql(sql)
      column_pattern = (options[:find_by] + [:id]).join("|")
      normalized_sql = sql.gsub(/["']/, '')
      pattern = %r{^\s*SELECT \* FROM #{klass.table_name} WHERE \(#{klass.table_name}\.(#{column_pattern}) = (\S+?)\)}i
      match, column, value = *normalized_sql.match(pattern)
      #puts "pm debug normalized_sql='#{normalized_sql}' parse_sql pattern=#{pattern} column=#{column} value=#{value}"
      match ? {:column => column, :value => value} : nil
    end
  end

  module BaseMethods
    def cachable_model(options = {})
      cattr_accessor :model_cache
      self.model_cache = CachableModel::Cache.new(self, options)
      after_save    { |record| record.class.model_cache.expire(record.id) }
      after_destroy { |record| record.class.model_cache.expire(record.id) }
      self.send :extend, ClassMethods
    end
  end

  module ClassMethods
    def find_by_sql(sql)
      if model_cache.enabled? && cachable = model_cache.parse_sql(sanitize_sql(sql))
        if cachable[:column] == "id"
          return model_cache.fetch(cachable[:value]) { super(sql) }
        else
          if id = model_cache.read_lookup_id(cachable[:column], cachable[:value])
            return [find(id)]
          else
            objects = super(sql)
            # What if record doesn't exist? Well, we can't cache that since that introduces a dependency on all records.
            id = objects.first.try(:id)
            model_cache.store_id_lookup(cachable[:column], cachable[:value], id) if id && objects.size == 1
            return objects
          end
        end
      else
        return super(sql)
      end    
    end
  end
end

ActiveRecord::Base.send :extend, CachableModel::BaseMethods
