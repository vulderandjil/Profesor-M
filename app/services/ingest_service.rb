require "google/cloud/storage"
require "pdf-reader"
require "tempfile"

class IngestService
  # Configuración del Bucket
  BUCKET_NAME = "mentor_ia_bd"
  FOLDER_PREFIX = "pdf/" # La carpeta dentro del bucket donde están los archivos

  def initialize(topic_id, filename)
    @topic = Topic.find(topic_id)
    @filename = filename
    
    # Inicializa el cliente de Storage usando las credenciales del entorno
    @storage = Google::Cloud::Storage.new(
      project_id: ENV.fetch("GOOGLE_PROJECT_ID"),
      credentials: ENV.fetch("GOOGLE_CREDENTIALS")
    )
  end

  def call
    puts "⬇Iniciando descarga de: #{@filename} desde GCS..."
    
    # 1. Descargar desde GCS a un archivo temporal
    temp_pdf = download_from_bucket
    
    begin
      puts "Procesando archivo temporal: #{temp_pdf.path}..."
      
      # 2. Extraer texto usando el archivo temporal
      text = extract_text(temp_pdf.path)
      
      # 3. Dividir texto (usando tu lógica recursiva PRO)
      chunks = split_text(text)
      
      puts "🧩 Generando vectores para #{chunks.size} fragmentos..."

      # 4. Vectorización y guardado
      chunks.each do |chunk|
        # Usamos tu generador con caché
        vector = Ai::EmbeddingGenerator.generate(chunk)
        
        @topic.document_chunks.create!(
          content: chunk,
          embedding: vector,
          # Opcional: Guardamos la fuente original para referencia futura
          metadata: { source: "gs://#{BUCKET_NAME}/#{FOLDER_PREFIX}#{@filename}" }
        )
        print "." # Feedback visual
      end
    ensure
      # 5. Limpieza: Importante cerrar y borrar el tempfile
      if temp_pdf
        temp_pdf.close
        temp_pdf.unlink 
        puts "\n🧹 Archivo temporal eliminado."
      end
    end
    
    puts "\nIngesta desde GCS completada con éxito."
  end

  private

  def download_from_bucket
    bucket = @storage.bucket(BUCKET_NAME)
    # Construimos la ruta completa: pdf/nombre_archivo.pdf
    file_path = "#{FOLDER_PREFIX}#{@filename}"
    gcs_file = bucket.file(file_path)

    unless gcs_file
      raise "Error: El archivo '#{file_path}' no existe en el bucket '#{BUCKET_NAME}'"
    end

    # Crear un archivo temporal donde descargaremos el contenido
    # 'binmode' es vital para archivos binarios como PDFs
    temp_file = Tempfile.new([@filename, ".pdf"], binmode: true)
    
    # Descargar el contenido del bucket al archivo temporal
    gcs_file.download(temp_file.path)
    
    temp_file
  end

  def extract_text(file_path)
    reader = PDF::Reader.new(file_path)
    reader.pages.map(&:text).join("\n")
  rescue StandardError => e
    raise "Error leyendo el PDF: #{e.message}"
  end

  def split_text(text)
    chunk_size = 1000
    chunk_overlap = 100
    separators = ["\n\n", "\n", " ", ""]

    recursive_split(text, separators, chunk_size, chunk_overlap)
  end

  def recursive_split(text, separators, chunk_size, chunk_overlap)
    final_chunks = []
    separator = separators.first
    
    if separator.nil? || text.length <= chunk_size
      return [text] if text.present?
      return []
    end

    splits = text.split(separator)
    current_chunk = ""

    splits.each do |part|
      if (current_chunk + separator + part).length > chunk_size && current_chunk.present?
        final_chunks << current_chunk
        current_chunk = current_chunk[-chunk_overlap, chunk_overlap] + separator + part
      else
        current_chunk += (current_chunk.empty? ? "" : separator) + part
      end
    end
    final_chunks << current_chunk if current_chunk.present?

    final_chunks
  end
end