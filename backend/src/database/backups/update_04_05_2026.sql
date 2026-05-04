ALTER TABLE users
ADD COLUMN age INTEGER;

ALTER TABLE users
ADD CONSTRAINT chk_users_age_range
CHECK (age >= 16 AND age <= 120);