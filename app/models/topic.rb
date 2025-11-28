class Topic < ApplicationRecord
  has_many :document_chunks, dependent: :destroy
end
