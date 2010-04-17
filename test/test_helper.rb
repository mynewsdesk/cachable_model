require 'rubygems'
require 'sqlite3'
require 'active_support'
require 'active_support/test_case'
require 'test/unit'
require 'mocha'

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'

require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/boot.rb'))

module Rails
  class Initializer
    def initialize_database
      config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
      ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
      db_adapter = ENV['DB'] || "postgresql"

      if db_adapter.nil?
        raise "No DB Adapter selected. Pass the DB= option to pick one, or install Sqlite or Sqlite3."
      end

      ActiveRecord::Base.establish_connection(config[db_adapter])
      load(File.dirname(__FILE__) + "/schema.rb")
    end
  end
end

config = Rails::Configuration.new
config.cache_store = ENV['CACHE'].try(:to_sym) || :mem_cache_store
Rails::Initializer.run(:process, config)

class User < ActiveRecord::Base    
  cachable_model :find_by => [:username, :email]
  has_many :articles
end 

class Article < ActiveRecord::Base
  belongs_to :user
end 
