module CachableModel
  module BaseMethods
    def cachable_model(options = {})
      cattr_accessor :model_cache
      self.model_cache = CachableModel::Cache.new(self, options)
      after_save    { |record| record.class.model_cache.object(record.id).delete }
      after_destroy { |record| record.class.model_cache.object(record.id).delete }
      self.send :extend, ClassMethods
    end
  end

  module ClassMethods
    def find_by_sql(sql)
      finder = CachableModel::Finder.new(self, sanitize_sql(sql))
      if finder.is_cached?
        finder.cached_objects
      else
        objects = super(sql)
        finder.store_in_cache(objects) if finder.can_cache?(objects)
        objects
      end
    end
  end
end

ActiveRecord::Base.send :extend, CachableModel::BaseMethods
