class DocumentChunk < ApplicationRecord
  belongs_to :topic

  scope :nearest_neighbors, ->(embedding, limit = 5) {
    order("embedding <-> ARRAY[#{embedding.join(',')}]::vector").limit(limit)
  }
end