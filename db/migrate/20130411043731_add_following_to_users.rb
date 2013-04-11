class AddFollowingToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :following, :string
  end
end
