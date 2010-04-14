require File.dirname(__FILE__) + '/test_helper.rb' 

class CachableModelTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(:name => "DHH")
    @article = @user.articles.create!(:name => "Rails 3.0 Released!")
    @user_key = CachableModel.key(User, @user.id)
    @article_key = CachableModel.key(Article, @article.id)
    Rails.cache.delete(@user_key)
    Rails.cache.delete(@article_key)
  end
  
  test "find(ID) is cached" do
    assert_equal nil, Rails.cache.read(@user_key)
    assert_equal @user, User.find(@user.id)
    assert_equal [@user], Rails.cache.read(@user_key)
    assert_equal @user, User.find(@user.id)
    ActiveRecord::Base.connection.execute("update users set name = 'foobar' where id = #{@user.id}")
    assert_equal "DHH", User.find(@user.id).name # We still hit the cache and not the database
    Rails.cache.write(@user_key, ["foobar"])
    assert_equal "foobar", User.find(@user.id)    
  end
  
  test "find_by_id is cached" do
    assert_equal nil, Rails.cache.read(@user_key)
    assert_equal @user, User.find_by_id(@user.id)
    assert_equal [@user], Rails.cache.read(@user_key)
    assert_equal @user, User.find_by_id(@user.id)    
  end
  
  test "belongs_to association is cached" do
    assert_equal nil, Rails.cache.read(@user_key)
    article = Article.find(@article.id)
    assert_equal @user, article.user
    assert_equal [@user], Rails.cache.read(@user_key)
    assert_equal @user, article.reload.user
    Rails.cache.write(@user_key, ["foobar"])
    assert_equal "foobar", article.reload.user
  end
  
  test "cache is flushed on update" do
    assert_equal nil, Rails.cache.read(@user_key)
    assert_equal @user, User.find(@user.id)
    assert_equal [@user], Rails.cache.read(@user_key)
    @user.update_attribute(:name, "foobar")
    assert_equal "foobar", User.find(@user.id).name
    assert_equal "foobar", Rails.cache.read(@user_key).first.name
  end
  
  test "cache is flushed on destroy" do
    assert_equal nil, Rails.cache.read(@user_key)
    assert_equal @user, User.find_by_id(@user.id)
    assert_equal [@user], Rails.cache.read(@user_key)
    @user.destroy
    assert_equal nil, User.find_by_id(@user.id)
    assert_equal [], Rails.cache.read(@user_key)
  end
  
  test "model without cachable is not cached" do
    assert_equal nil, Rails.cache.read(@article_key)
    assert_equal @article, Article.find_by_id(@article.id)
    assert_equal nil, Rails.cache.read(@article_key)
    assert_equal @article, Article.find_by_id(@article.id)
  end
end
