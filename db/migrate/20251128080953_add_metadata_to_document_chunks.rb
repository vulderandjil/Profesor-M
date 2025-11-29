class AddMetadataToDocumentChunks < ActiveRecord::Migration[8.1]
  def change
    add_column :document_chunks, :metadata, :jsonb
  end
end
