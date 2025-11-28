require "google/cloud/ai_platform/v1"
require "digest"

module Ai
  class EmbeddingGenerator
    def self.generate(text)
      new.generate(text)
    end

    def generate(text)
      # 1. Calcular un hash único para el texto de entrada.
      text_hash = Digest::SHA256.hexdigest(text)

      # 2. Buscar en el caché.
      cached_entry = EmbeddingCacheEntry.find_by(text_hash: text_hash)
      if cached_entry
        Rails.logger.info "Embedding cache hit for hash: #{text_hash}"
        return cached_entry.embedding
      end

      Rails.logger.info "Embedding cache miss. Generating new embedding for hash: #{text_hash}"

      # 3. Si no está en caché, generar el embedding llamando a la API.
      client = VertexAIClient.client

      # Formato correcto para Gemini Embeddings
      instance = Google::Protobuf::Value.new(
        struct_value: Google::Protobuf::Struct.from_hash({ "content" => text })
      )

      endpoint_path = "projects/#{ENV['GOOGLE_PROJECT_ID']}/locations/#{VertexAIClient::REGION}/publishers/google/models/text-embedding-004"

      response = client.predict(
        endpoint: endpoint_path,
        instances: [instance]
      )

      # 4. Extraer el vector y guardarlo en el caché para el futuro.
      embedding = response.predictions.first.struct_value.to_h['embeddings']['values']

      EmbeddingCacheEntry.create!(
        text_hash: text_hash,
        embedding: embedding
      )

      embedding
    end
  end
end
