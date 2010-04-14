ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.string :name
  end
  
  create_table :articles, :force => true do |t|
    t.string :name
    t.integer :user_id
  end
end
