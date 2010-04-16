ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.string :name
    t.string :username, :unique => true
    t.string :email, :unique => true
  end
  
  create_table :articles, :force => true do |t|
    t.string :name
    t.integer :user_id
  end
end
