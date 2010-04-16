require File.dirname(__FILE__) + '/test_helper.rb' 

class CacheTest < ActiveSupport::TestCase
  def setup
    @cache = CachableModel::Cache.new(User)
  end

  test "enabled? returns false in test environment and true otherwise" do
    assert !@cache.enabled?
    Rails.env.stubs(:test?).returns(false)
    assert @cache.enabled?    
  end
  
  test "parse_sql matches id lookups case insensitive, regardless of trailing LIMIT and quotes" do
    expect = {:column => "id", :value => "123"}
    assert_equal expect, @cache.parse_sql('select * from "users" where ("users"."id" = 123) LIMIT 1')
    assert_equal expect, @cache.parse_sql('select * from "users" where ("users"."id" = 123)')
    assert_equal expect, @cache.parse_sql('SELECT * FROM users where (users.id = 123)')
    'SELECT * FROM "users" WHERE (id = 1)  LIMIT 1'
  end
  
  test "parse_sql returns nil for SQL that is not an ID lookup" do
    assert_equal nil, @cache.parse_sql("SELECT * FROM users where (users.id = 123 AND users.name = 'Peter')")
  end
  
  test "parse_sql can parse lookups by other columns than ID" do
    @cache.options[:find_by] = [:username]
    expect = {:column => "username", :value => "joe"}
    assert_equal expect, @cache.parse_sql(%q{select * from "users" where ("users"."username" = 'joe') LIMIT 1})
    assert_equal nil, @cache.parse_sql(%q{select * from "users" where ("users"."name" = 'Joe') LIMIT 1})
  end
end
