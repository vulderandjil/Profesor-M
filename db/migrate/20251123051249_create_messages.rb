class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :chat_session, null: false, foreign_key: true
      t.integer :role
      t.text :content

      t.timestamps
    end
  end
end
