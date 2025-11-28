class CreateEmbeddingCacheEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :embedding_cache_entries do |t|
      t.string :text_hash
      t.vector :embedding, limit: 768

      t.timestamps
    end
    add_index :embedding_cache_entries, :text_hash, unique: true
  end
end
