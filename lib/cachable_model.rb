module CachableModel
  def self.key(klass, id)
    "#{klass.name}.find_by_id(#{id})"
  end
  
  def self.fetch(klass, id, &block)
    Rails.cache.fetch(key(klass, id), &block)
  end
  
  def self.expire(klass, id)
    Rails.cache.delete(key(klass, id))
  end

  def self.get_cachable_id(klass, sql)
    sql.gsub(/["']/, '') =~ %r{^\s*SELECT \* FROM #{klass.table_name} WHERE \(#{klass.table_name}\.id = (\d+)\)} ? $1 : nil
  end

  module BaseMethods
    def cachable(options = {})
      after_save    { |record| CachableModel.expire(record.class, record.id) }
      after_destroy { |record| CachableModel.expire(record.class, record.id) }
      self.send :extend, ClassMethods
      self.send :include, InstanceMethods
    end
  end

  module ClassMethods
    def find_by_sql(sql)
      if id = CachableModel.get_cachable_id(self, sql)
        CachableModel.fetch(self, id) { super(sql) }
      else
        super(sql)
      end    
    end
  end
  
  module InstanceMethods
    def reload
      CachableModel.expire(self.class, self.id)
      super
    end    
  end
end

ActiveRecord::Base.send :extend, CachableModel::BaseMethods
