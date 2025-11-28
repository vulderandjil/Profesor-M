class DocumentChunk < ApplicationRecord
  belongs_to :topic
  
  # Agrega esta línea para activar la magia de la gema neighbor
  has_neighbors :embedding
end