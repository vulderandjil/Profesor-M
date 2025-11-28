# CodeMentor AI

**CodeMentor AI** es una plataforma de aprendizaje adaptativo que implementa el patrón RAG (Retrieval-Augmented Generation) utilizando Ruby on Rails 8 de forma nativa.

A diferencia de las arquitecturas tradicionales que delegan la lógica de IA a microservicios en Python, este proyecto demuestra cómo integrar capacidades de Búsqueda Vectorial y Grandes Modelos de Lenguaje (LLMs) directamente en el ecosistema de Rails y PostgreSQL.

## Arquitectura del Sistema

El sistema opera bajo un flujo de datos bidireccional:

1.  **Ingesta de Conocimiento:**
    * Los documentos (PDF/Texto) son procesados y fragmentados.
    * Se generan embeddings (vectores matemáticos) utilizando **Google Vertex AI**.
    * Los vectores se almacenan directamente en **PostgreSQL** mediante la extensión `pgvector`.

2.  **Motor de Chat (RAG):**
    * El usuario realiza una consulta a través de una interfaz reactiva (**Hotwire/Turbo**).
    * El sistema convierte la consulta en un vector y realiza una búsqueda de similitud coseno en la base de datos.
    * Se recuperan los fragmentos de contexto más relevantes.
    * **Gemini Pro (Vertex AI)** genera una respuesta basada estrictamente en el contexto recuperado, citando las fuentes utilizadas.

## Stack Tecnológico

* **Framework:** Ruby on Rails 8.0 (Beta)
* **Base de Datos:** PostgreSQL 16 con extensión `pgvector`
* **Inteligencia Artificial:** Google Vertex AI (Modelos: `text-embedding-004` y `gemini-1.5-pro`)
* **Frontend:** Hotwire (Turbo Streams & Stimulus), TailwindCSS
* **Infraestructura:** Docker & Docker Compose

## Requisitos Previos

Para ejecutar este proyecto localmente, asegúrese de tener instalado:

* **Docker** y **Docker Compose** (Método recomendado).
* Una cuenta de **Google Cloud Platform (GCP)** activa.

## Configuración del Entorno

### 1. Clonar el repositorio

```bash
git clone <URL_DEL_REPOSITORIO>
cd code_mentor