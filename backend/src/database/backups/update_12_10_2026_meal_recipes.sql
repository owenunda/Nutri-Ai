-- Recetas del chat registradas como comida.
--
-- Al registrar una receta se guardan sus ingredientes como alimentos normales
-- (las calorías se siguen calculando igual) y cada línea apunta a la receta
-- de la que salió, para poder mostrarla y borrarla entera desde cualquier
-- dispositivo. No se reutiliza meal_record_details.recipe_id: las
-- estadísticas tratan esa columna como "receta completa" y sumarían de más.

BEGIN;

CREATE TABLE IF NOT EXISTS meal_recipe_logs (
    meal_recipe_log_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title VARCHAR(200) NOT NULL,
    portions NUMERIC(5, 2) NOT NULL CHECK (portions > 0),
    recipe JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_meal_recipe_log_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

ALTER TABLE meal_record_details
    ADD COLUMN IF NOT EXISTS meal_recipe_log_id INTEGER;

ALTER TABLE meal_record_details
    DROP CONSTRAINT IF EXISTS fk_meal_record_detail_recipe_log;
ALTER TABLE meal_record_details
    ADD CONSTRAINT fk_meal_record_detail_recipe_log
    FOREIGN KEY (meal_recipe_log_id) REFERENCES meal_recipe_logs(meal_recipe_log_id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_meal_record_details_recipe_log
    ON meal_record_details (meal_recipe_log_id);

COMMIT;
