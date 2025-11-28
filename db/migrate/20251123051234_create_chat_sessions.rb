class CreateChatSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_sessions do |t|
      t.references :topic, null: false, foreign_key: true
      t.string :title

      t.timestamps
    end
  end
end
