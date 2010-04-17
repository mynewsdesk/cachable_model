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
end