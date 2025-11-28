class CreateTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :topics do |t|
      t.string :title

      t.timestamps
    end
  end
end
