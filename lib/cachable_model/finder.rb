module CachableModel
  class Finder
    attr_accessor :klass, :cache, :sql, :id_lookup
    delegate :column, :value, :to => :sql
    extend ActiveSupport::Memoizable

    def initialize(klass, sql)
      self.klass = klass
      self.cache = klass.model_cache
      self.sql = SQLParser.new(sql, klass, cache.options[:find_by])
      self.id_lookup = IDLookup.new(column, value, cache)
    end

    def is_cached?
      sql.cachable? && cached_objects
    end

    def can_cache?(objects)
      sql.cachable? && objects.size == 1
    end

    def id
      if column == "id"
        value
      else
        id_lookup.read
      end      
    end

    def cached_objects
      id ? cache.object(id).read : nil
    end
    memoize :cached_objects

    def store_in_cache(objects)
      id_lookup.write(objects.first.id) if column != "id"
      cache.object(objects.first.id).write(objects)
    end
  end
end
