module CachableModel
  class SQLParser
    attr_accessor :sql, :find_by, :klass, :column, :value

    def initialize(sql, klass, find_by)
      self.sql = sql
      self.klass = klass
      self.find_by = find_by      
      parse_sql
    end

    def parsable?
      column.present? && value.present?
    end

    def cachable?
      parsable? && klass.model_cache.enabled?
    end

    def parse_sql
      match, self.column, self.value = *unquoted_sql.match(sql_pattern)
    end

    def unquoted_sql
      unquoted = sql.dup
      unquoted.gsub!(/E'/, '') if postgresql?
      unquoted.gsub!(/["'`]/, '')
      unquoted
    end

    def postgresql?
      defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) && klass.connection.class == ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    end

    def sql_pattern
      column_pattern = (find_by + [:id]).join("|")
      %r{^\s*SELECT \* FROM #{klass.table_name} WHERE \(#{klass.table_name}\.(#{column_pattern}) = (\S+?)\)}i
    end
  end
end