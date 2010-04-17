require File.dirname(__FILE__) + '/test_helper.rb' 

class CachableModelTest < ActiveSupport::TestCase
  def setup
    User.destroy_all
    Article.destroy_all
    @user = User.create!(:name => "David", :username => "dhh", :email => "david@example.com")
    @other_user = User.create!(:name => "Peter", :username => "flygarn", :email => "peter@example.com")
    @article = @user.articles.create!(:name => "Rails 3.0 Released!")
    @user_key = User.model_cache.object(@user.id).key
    @article_key = CachableModel::Cache.new(Article).object(@article.id).key
    Rails.cache.clear
    CachableModel::Cache.any_instance.stubs(:enabled?).returns(true)    
  end
  
  test "find(ID) is cached" do
    assert_equal nil, Rails.cache.read(@user_key)
    assert_equal @user, User.find(@user.id)
    assert_equal [@user], Rails.cache.read(@user_key)
    assert_equal @user, User.find(@user.id)
    ActiveRecord::Base.connection.execute("update users set name = 'foobar' where id = #{@user.id}")
    assert_equal "David", User.find(@user.id).name # We still hit the cache and not the database
    Rails.cache.write(@user_key, ["foobar"])
    assert_equal "foobar", User.find(@user.id)    
  end

  test 'find(:first) is cached' do
    assert_equal nil, Rails.cache.read(@user_key)
    assert_equal @user, User.find(:first, :conditions => {:id => @user.id})
    assert_equal [@user], Rails.cache.read(@user_key)
    Rails.cache.write(@user_key, ["foobar"])
    assert_equal "foobar", User.find(:first, :conditions => {:id => @user.id})
  end
  
  test "find(ID) is not cached when CachableModel::Cache#enabled? returns false" do
    CachableModel::Cache.any_instance.stubs(:enabled?).returns(false)
    assert_equal @user, User.find(@user.id)
    assert_equal nil, Rails.cache.read(@user_key)    
  end
  
  test "find_by_id is cached" do
    assert_equal nil, Rails.cache.read(@user_key)
    assert_equal @user, User.find_by_id(@user.id)
    assert_equal [@user], Rails.cache.read(@user_key)
    assert_equal @user, User.find_by_id(@user.id)    
  end

  test "find_by_username is cached and is flushed on update" do
    assert_equal @user, User.find_by_username("dhh")
    assert_equal [@user], Rails.cache.read(@user_key)
    username_key = CachableModel::IDLookup.new("username", "dhh", User.model_cache).key
    assert_equal @user.id, Rails.cache.read(username_key)
    dep_key = CachableModel::Dependency.new(User.model_cache, @user_key, username_key).cache_key
    assert_equal [username_key], Rails.cache.read(dep_key)
    
    assert_equal @user, User.find_by_username("dhh")
    assert_equal [@user], Rails.cache.read(@user_key)
    ActiveRecord::Base.connection.execute("update users set name = 'foobar' where id = #{@user.id}")
    assert_equal "David", User.find_by_username("dhh").name

    assert_equal "foobar", User.find_by_email("david@example.com").name
    email_key = CachableModel::IDLookup.new("email", "david@example.com", User.model_cache).key
    assert_equal @user.id, Rails.cache.read(email_key)
    assert_equal [username_key, email_key].sort, Rails.cache.read(dep_key).sort

    @user.update_attributes!(:name => "David Heinemeier")
    assert_equal "David Heinemeier", User.find_by_email("david@example.com").name    
  end

  test "when find_by_username returns nothing, nothing is cached" do
    assert_equal nil, User.find_by_username("foobar")
    assert_equal nil, User.find_by_username("foobar")
    username_key = CachableModel::IDLookup.new("username", "foobar", User.model_cache).key
    assert_equal nil, Rails.cache.read(username_key)
  end

  test "find_by_name is not cached" do
    user = User.find_by_name("David")
    ActiveRecord::Base.connection.execute("update users set username = 'foobar' where id = #{user.id}")
    assert_equal "foobar", User.find_by_name("David").username
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

  test "object fetched from the cache can be modified (is not frozen)" do
    User.find(@user.id) # initialize the cache
    user = User.find(@user.id) # fetch from the cache
    user.name = "Michael"
    user.email = "michael@example.com"
    user.save!
    user = User.find(@user.id)
    assert_equal "Michael", user.name
    assert !user.frozen?
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
    assert Rails.cache.read(@user_key).blank?
  end
  
  test "model without cachable is not cached" do
    assert_equal nil, Rails.cache.read(@article_key)
    assert_equal @article, Article.find_by_id(@article.id)
    assert_equal nil, Rails.cache.read(@article_key)
    assert_equal @article, Article.find_by_id(@article.id)
  end
  
  # Useful for memory store but not memcache store
  def cache_data
   Rails.cache.instance_eval { @data.inspect }
  end
end
