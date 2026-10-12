-- Metadatos de cada mensaje del chat
-- El texto sigue en content; aquí viaja lo que la app necesita para repintar
-- el mensaje al reabrir un chat: el tipo de respuesta (RECIPE, ANSWER, ...)
-- y las acciones interactivas (paso a paso, tip).
-- Nullable: los mensajes viejos y los del usuario no lo llevan.

ALTER TABLE chat_messages
    ADD COLUMN IF NOT EXISTS metadata JSONB;
