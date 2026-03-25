# PRD: Memory CLI

## Idea
CLI de memoria persistente para sesiones de desarrollo con agentes IA.
Solo guarda información útil para futuros desarrollos.

## Requisitos del usuario
- Lenguaje: Rust
- Interfaz: CLI (el agente invoca el binario directamente)
- Tipos de datos: decisiones técnicas, snippets de código, contexto de conversación
- Volumen estimado: cientos de entradas
- BD: liviana y rápida
- Prioridad #1: búsqueda ultra-rápida desde el agente hacia la memoria

## Comunicación agente → CLI
El agente ejecuta el CLI como subproceso con argumentos. Respuesta por stdout.
