-- Tipo de comida por línea y un solo registro de comidas por usuario y día.
-- La fusión de duplicados va antes del índice único: si existieran dos
-- registros del mismo día, sus detalles pasan al más antiguo.

BEGIN;

ALTER TABLE meal_record_details
    ADD COLUMN IF NOT EXISTS meal_type VARCHAR(10) NOT NULL DEFAULT 'SNACK';

ALTER TABLE meal_record_details
    DROP CONSTRAINT IF EXISTS chk_meal_record_details_meal_type;
ALTER TABLE meal_record_details
    ADD CONSTRAINT chk_meal_record_details_meal_type
    CHECK (meal_type IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'));

WITH ranked AS (
    SELECT meal_record_id,
           MIN(meal_record_id) OVER (PARTITION BY user_id, record_date) AS keep_id
    FROM meal_records
)
UPDATE meal_record_details d
SET meal_record_id = r.keep_id
FROM ranked r
WHERE d.meal_record_id = r.meal_record_id
  AND r.meal_record_id <> r.keep_id;

DELETE FROM meal_records mr
USING (
    SELECT meal_record_id,
           MIN(meal_record_id) OVER (PARTITION BY user_id, record_date) AS keep_id
    FROM meal_records
) r
WHERE mr.meal_record_id = r.meal_record_id
  AND r.meal_record_id <> r.keep_id;

CREATE UNIQUE INDEX IF NOT EXISTS uq_meal_records_user_date
    ON meal_records (user_id, record_date);

COMMIT;
