class IngestService
  def initialize(topic_id, file_path)
    @topic = Topic.find(topic_id)
    @file_path = file_path
  end

  def call
    text = extract_text
    chunks = split_text(text)
    
    chunks.each do |chunk|
      vector = Ai::EmbeddingGenerator.generate(chunk)
      @topic.document_chunks.create!(
        content: chunk,
        embedding: vector
      )
    end
  end

  private

  def extract_text
    # Lógica simple para PDF. Si es .txt o .rb, leer directo.
    reader = PDF::Reader.new(@file_path)
    reader.pages.map(&:text).join("\n")
  end

  def split_text(text)
    # Implementación de un divisor de texto recursivo.
    # Intenta dividir por los separadores en orden para mantener el contexto.
    chunk_size = 1000 # Tamaño de fragmento deseado
    chunk_overlap = 100 # Superposición para no perder contexto entre fragmentos
    separators = ["\n\n", "\n", " ", ""] # De más general a más específico

    recursive_split(text, separators, chunk_size, chunk_overlap)
  end

  def recursive_split(text, separators, chunk_size, chunk_overlap)
    final_chunks = []
    # Toma el primer separador de la lista
    separator = separators.first
    
    # Si no quedan separadores o el texto es pequeño, se devuelve como un solo fragmento.
    if separator.nil? || text.length <= chunk_size
      return [text] if text.present?
      return []
    end

    # Intenta dividir el texto con el separador actual
    splits = text.split(separator)
    current_chunk = ""

    splits.each do |part|
      # Si añadir la siguiente parte excede el tamaño, guarda el fragmento actual y empieza uno nuevo.
      if (current_chunk + separator + part).length > chunk_size && current_chunk.present?
        final_chunks << current_chunk
        # El nuevo fragmento empieza con una superposición del anterior.
        current_chunk = current_chunk[-chunk_overlap, chunk_overlap] + separator + part
      else
        current_chunk += (current_chunk.empty? ? "" : separator) + part
      end
    end
    final_chunks << current_chunk if current_chunk.present? # Añade el último fragmento

    final_chunks
  end

end