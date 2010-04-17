require File.dirname(__FILE__) + '/test_helper.rb' 

class SQLParserTest < ActiveSupport::TestCase
  test "parse_sql matches id lookups case insensitive, regardless of trailing LIMIT and quotes" do
    expect = {:column => "id", :value => "123"}
    assert_parsing expect, parser('select * from "users" where ("users"."id" = 123) LIMIT 1')
    assert_parsing expect, parser('select * from "users" where ("users"."id" = 123)')
    assert_parsing expect, parser('SELECT * FROM users where (users.id = 123)')
    assert_parsing expect, parser('SELECT * FROM `users` WHERE (`users`.`id` = 123)') # mysql quoting
    assert_parsing expect, parser('SELECT * FROM "users" WHERE (users.id = 123)  LIMIT 1')
  end
  
  test "parse_sql returns nil for SQL that is not an ID lookup" do
    assert_unparsable parser("SELECT * FROM users where (users.id = 123 AND users.name = 'Peter')")
  end
  
  test "parse_sql can parse lookups by other columns than ID" do
    CachableModel::SQLParser.any_instance.stubs(:postgresql?).returns(true) # to activate postgresql quoting
    find_by = [:username]
    expect = {:column => "username", :value => "joe"}
    assert_parsing expect, parser(%q{select * from "users" where ("users"."username" = 'joe') LIMIT 1}, find_by)
    assert_parsing expect, parser(%q{SELECT * FROM "users" WHERE ("users"."username" = E'joe')  LIMIT 1}, find_by) # postgresql quoting
    assert_unparsable parser(%q{select * from "users" where ("users"."name" = 'Joe') LIMIT 1}, find_by)
  end

  def parser(sql, find_by = [])
    CachableModel::SQLParser.new(sql, User, find_by)
  end
  
  def assert_parsing(expect, parser)
    assert_equal expect[:column], parser.column
    assert_equal expect[:value], parser.value
  end
  
  def assert_unparsable(parser)
    assert_nil parser.column
    assert_nil parser.value
    assert !parser.parsable?    
  end
end
