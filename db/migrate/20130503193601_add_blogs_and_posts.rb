class AddBlogsAndPosts < ActiveRecord::Migration
  def change
  	create_table :blogs do |t|
      t.boolean :following
      t.string :name
      t.integer :size, default: 0

      t.timestamps
    end

    create_table :posts do |t|
      t.string :target
      t.string :source
      t.string :type_of_post
      t.string :tags

      t.timestamps
    end
  end
end
