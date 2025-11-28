module Documents
  class SearchService
    # Distancia coseno: menor es más similar en pgvector (dependiendo de la implementación), 
    # pero neighbor usa producto punto o coseno. Para embeddings normalizados de OpenAI/Google, 
    # neighbor suele ordenar por cercanía.
    LIMIT = 5

    def initialize(topic_id, query_text)
      @topic = Topic.find(topic_id)
      @query_text = query_text
    end

    def call
      query_embedding = Ai::EmbeddingGenerator.generate(@query_text)
      
      # Busca los fragmentos más cercanos dentro del tópico específico
      # neighbor facilita esto con el scope nearest_neighbors
      results = @topic.document_chunks.nearest_neighbors(query_embedding, LIMIT)

      # Retornamos los fragmentos completos para tener acceso al ID y al contenido
      results
    end
  end
end