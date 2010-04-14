require File.dirname(__FILE__) + '/test_helper.rb' 

class CachableModelTest < ActiveSupport::TestCase
  class Article < ActiveRecord::Base
  end 
  
  test "schema loaded" do
    assert_equal [], Article.all
  end
end
