ALTER TABLE recipes
ADD COLUMN description TEXT,
DROP COLUMN created_by_user_id CASCADE;
