# Mastercode AI

**Mastercode AI** es una plataforma de aprendizaje adaptativo (RAG) construida con Ruby on Rails y PostgreSQL, diseñada para integrar búsqueda vectorial y generación de lenguaje grande (LLMs) directamente dentro de la aplicación Rails.

Funciones actualmente implementadas: ingestión y fragmentación de documentos, cálculo y almacenamiento de embeddings con Google Vertex AI, búsqueda por similitud usando `pgvector`, un motor de chat RAG que usa Gemini (Vertex AI) y una interfaz reactiva con Hotwire/Turbo.

**Resumen rápido**

- Ingesta y fragmentación de documentos (PDF / texto).
- Generación de embeddings con Google Vertex AI y almacenamiento en PostgreSQL (`pgvector`).
- Caché de embeddings para evitar re-cálculos innecesarios.
- Búsqueda por similitud para recuperar contexto relevante.
- Motor de chat que utiliza Gemini Pro (Vertex AI) para generar respuestas basadas en contexto.
- Interfaz en Rails con Hotwire/Turbo y TailwindCSS.
- Procesamiento asíncrono mediante Jobs (ActiveJob) para ingestión y generación de respuestas.

## Arquitectura del sistema

- Ingesta: `app/services/ingest_service.rb` y el job `jobs/ingest_document_job.rb` procesan y fragmentan documentos.
- Embeddings: generados vía la integración en `app/services/ai/` y almacenados en `app/models/embedding_cache_entry.rb` y `document_chunk.rb` usando `pgvector`.
- Búsqueda: consultas vectoriales en PostgreSQL para recuperar fragmentos relevantes.
- Chat: `ChatSession` y `Message` manejan la sesión de conversación; la generación de respuestas se hace en background (`ai_response_job.rb`).

## Funcionalidades principales

- Ingesta de documentos (PDF/Text) y fragmentación.
- Generación de embeddings (Vertex AI) y persistencia en Postgres con `pgvector`.
- Cache de embeddings para optimizar costos y latencia.
- Recuperación de contexto vía búsqueda vectorial (similitud coseno).
- Respuestas generadas por Gemini Pro (Vertex AI) estrictamente basadas en el contexto recuperado (RAG).
- UI reactiva con Hotwire/Turbo y componentes Stimulus para conversación en tiempo real.
- Jobs en background para ingestión y generación de respuestas.

## Requisitos previos

- Docker y Docker Compose (recomendado para desarrollo local).
- Cuenta en Google Cloud Platform (GCP) con permisos para Vertex AI.
- PostgreSQL 16 con extensión `pgvector` (el contenedor Docker incluido instala/configura esto).

## Configuración rápida (Docker)

1) Copia tu fichero de credenciales de GCP (JSON) a la raíz del proyecto o apunta su ruta en la variable de entorno.

2) Crear archivo de variables de entorno (ejemplo `.env`) o exportar:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/gcp-key.json
export DATABASE_URL=postgres://user:password@db:5432/code_mentor_development
export RAILS_ENV=development
```

3) Levantar los contenedores:

```bash
docker compose up --build
```

4) Ejecutar migraciones y tareas de setup:

```bash
docker compose run --rm web bin/rails db:create db:migrate db:seed
```

5) Iniciar workers para jobs en background (si usa Sidekiq o ActiveJob adapter configurado):

```bash
docker compose up -d
# o, si usa un proceso de worker separado
docker compose run --rm worker bin/rails jobs:work
```

Nota: los comandos exactos para workers pueden variar según la configuración en `Procfile.dev` y `docker-compose.yml`.

## Variables de entorno importantes

- `GOOGLE_APPLICATION_CREDENTIALS` — Ruta al JSON de la cuenta de servicio GCP.
- `DATABASE_URL` — Cadena de conexión a PostgreSQL.
- `RAILS_ENV`, `SECRET_KEY_BASE` — variables Rails estándar.
- `VERTEX_EMBEDDING_MODEL` — (opcional) nombre del modelo de embeddings usado.
- `VERTEX_LLM_MODEL` — (opcional) modelo LLM (ej. `gemini-1.5-pro`).

## Uso

- Ingestar un documento (ejemplo): la aplicación expone endpoints y jobs para procesar documentos. Puedes usar la interfaz web o encolar `IngestDocumentJob`.
- Iniciar una sesión de chat: desde la UI, crea una `ChatSession` y envía mensajes; la respuesta se genera en background por `AiResponseJob`.
- Ver logs y rastreo de jobs en `log/` y el dashboard de Active Job / Sidekiq si está instalado.

## Estructura relevante del código

- `app/services/ingest_service.rb` — lógica de ingestión y fragmentación.
- `app/services/ai/` — clientes y adaptadores para Vertex AI (embeddings + LLM).
- `app/models/document_chunk.rb` — fragmentos de documentos con vectores.
- `app/models/embedding_cache_entry.rb` — caché para embeddings.
- `app/jobs/` — jobs asíncronos (ingest, generación de respuestas).
- `app/controllers/chat_sessions_controller.rb`, `messages_controller.rb` — endpoints de chat.

## Desarrollo y pruebas

- Ejecutar pruebas:

### Prerrequisitos para ejecutar pruebas localmente

- `Ruby` (la versión usada por el proyecto; consulta `Gemfile`).
- `Bundler` (`gem install bundler`).
- `Node.js` y `npm`/`yarn` para compilar assets si es necesario.
- `PostgreSQL` (idealmente v16) con la extensión `pgvector` en las bases de datos de desarrollo y test.
- `Docker` y `docker compose` (opcional — recomendado para reproducir el entorno local).
- Para tests del sistema (capybara/system): navegador y driver (Headless Chrome + Chromedriver o Cuprite).
