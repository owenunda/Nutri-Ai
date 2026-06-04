-- =========================================================
-- ÍNDICES PARA OPTIMIZAR RENDIMIENTO
-- Fecha: 2026-05-02
-- =========================================================
-- Índice en fridges(user_id) - CRÍTICO para getFridgeByUserId
CREATE INDEX idx_fridges_user_id ON fridges(user_id);
-- Índice en fridge_items(food_id) - para JOINs eficientes
CREATE INDEX idx_fridge_items_food_id ON fridge_items(food_id);
-- Índice compuesto en fridge_items - optimiza búsquedas por fridge y food
CREATE INDEX idx_fridge_items_fridge_food ON fridge_items(fridge_id, food_id);
-- Índice compuesto en foods - filtra globales y activos frecuentemente
CREATE INDEX idx_foods_global_active ON foods(is_global, is_active);
-- Índice en foods(created_by_user_id) - para búsquedas de alimentos personalizados
CREATE INDEX idx_foods_created_by_user ON foods(created_by_user_id);
-- Índice en user_recipes(user_id) - para consultas de recetas del usuario
CREATE INDEX idx_user_recipes_user_id ON user_recipes(user_id);
-- Índice compuesto en user_recipes - para JOINs eficientes
CREATE INDEX idx_user_recipes_user_recipe ON user_recipes(user_id, recipe_id);
-- Índice en roles(name) - para búsquedas por nombre
CREATE INDEX idx_roles_name ON roles(name);
-- Índice en plans(name) - para búsquedas por nombre
CREATE INDEX idx_plans_name ON plans(name);
-- Índice en statuses(name) - para búsquedas por nombre
CREATE INDEX idx_statuses_name ON statuses(name);