# para activar la extension del vector
rails generate migration EnableVectorExtension

# para inicializar el proyecto
docker compose up --build
# 
docker compose up -d --build

# si da error de cache
docker builder prune -a

# para borrar todo
docker compose down -v

# Crear base de datos y ejecutar migraciones (incluyendo activación de vector extension)
docker compose exec web bundle exec rails db:create db:migrate
# con borrado 
docker compose exec web bundle exec rails db:drop db:create db:migrate

# para exportar la variable de entorno
export GOOGLE_APPLICATION_CREDENTIALS="/home/Vulder/proyectos/code_mentor/gcloud/gcp-key.json"

# La aplicación estará disponible en http://localhost:3000

# Guía de Uso y Prueba (Demo)
Dado que es una versión de desarrollo, la ingesta de documentos se realiza actualmente a través de la consola, mientras que la interacción de chat se realiza vía web.

# Paso 1: Ingesta de Datos (Carga de Documentos)
Para probar el sistema RAG, primero debe cargar conocimiento en la base de datos.

Coloque un archivo PDF técnico (ej: manual.pdf) en la raíz del proyecto.

Acceda a la consola de Rails dentro del contenedor:

    docker compose exec web rails c 
    ó
    docker compose exec web bundle exec rails c

Ejecute los siguientes comandos en la consola de Ruby:

# 1. Crear un tópico de estudio
    topic = Topic.create(title: "Documentación Técnica")

# 2. Ejecutar el servicio de ingesta (Asegúrese de que el nombre del archivo coincida)
Esto leerá el PDF, generará vectores y los guardará en Postgres.
    Documents::IngestService.new(topic.id, "manual.pdf").call

    service = IngestService.new(topic.id, "app/manualruby.pdf")
    service.call

Si el proceso es exitoso, verá un mensaje de confirmación y los vectores almacenados en la tabla document_chunks.

# Paso 2: Interacción con el Chat
Navegue a http://localhost:3000/topics.

Seleccione el tópico creado ("Documentación Técnica").

Haga clic en "Iniciar Nueva Sesión".

Realice preguntas relacionadas con el documento PDF que subió.

# Resultados esperados:

La respuesta debe generarse en tiempo real (streaming).

La respuesta debe ser coherente con el PDF subido.

Al final del mensaje de la IA, debe aparecer un desplegable indicando las Fuentes Consultadas.

 # pruebas cloud

topic = Topic.first || Topic.create(title: "Prueba Cloud")

IngestService.new(Topic.first.id, "manual_ruby_basico.pdf").call

docker compose exec web bundle exec  rails runner "puts ENV.fetch('GOOGLE_CREDENTIALS')"