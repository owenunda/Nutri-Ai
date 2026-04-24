-- =========================================================
-- TABLA: roles
-- Catálogo de roles del sistema para controlar permisos.
-- =========================================================
CREATE TABLE roles (
    role_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- TABLA: plans
-- Catálogo de planes disponibles para los usuarios.
-- =========================================================
CREATE TABLE plans (
    plan_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================
-- TABLA: statuses
-- Catálogo de estados para el flujo de recetas sugeridas.
-- =========================================================
CREATE TABLE statuses (
    status_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(20) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO roles (name) VALUES ('ADMIN'), ('USER');
INSERT INTO plans (name) VALUES ('FREE'), ('PRO');
INSERT INTO statuses (name) VALUES ('PENDING'), ('ACCEPTED'), ('REJECTED'), ('EXECUTED');

-- =========================================================
-- TABLA: users
-- Guarda la información principal de cada usuario.
-- role_id y plan_id conectan con los catálogos del sistema.
-- =========================================================
CREATE TABLE users (
    user_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    goal VARCHAR(255),
    role_id INTEGER NOT NULL,
    plan_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_role_user FOREIGN KEY (role_id) REFERENCES roles(role_id),
    CONSTRAINT fk_plan_user FOREIGN KEY (plan_id) REFERENCES plans(plan_id)
);

-- =========================================================
-- TABLA: foods
-- Catálogo de alimentos.
-- is_global = TRUE si pertenece al catálogo general.
-- is_global = FALSE si fue creado por un usuario.
-- calories_per_unit ahora usa NUMERIC para mayor precisión.
-- =========================================================
CREATE TABLE foods (
    food_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    calories_per_unit NUMERIC(10,2) NOT NULL CHECK (calories_per_unit >= 0),
    base_unit VARCHAR(50) NOT NULL,
    is_global BOOLEAN DEFAULT TRUE,
    created_by_user_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_food FOREIGN KEY (created_by_user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =========================================================
-- TABLA: recipes
-- Guarda las recetas generadas o registradas en el sistema.
-- Cada receta pertenece a un usuario creador.
-- =========================================================
CREATE TABLE recipes (
    recipe_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_by_user_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_recipe_creator FOREIGN KEY (created_by_user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =========================================================
-- TABLA: fridges
-- Cada usuario tiene una sola nevera.
-- user_id es UNIQUE para mantener relación 1 a 1.
-- =========================================================
CREATE TABLE fridges (
    fridge_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_fridge FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- =========================================================
-- TABLA: fridge_items
-- Inventario real de alimentos dentro de la nevera del usuario.
-- quantity usa NUMERIC porque puede haber fracciones.
-- UNIQUE (fridge_id, food_id) evita duplicar el mismo alimento
-- en la misma nevera; la cantidad total se maneja en una sola fila.
-- =========================================================
CREATE TABLE fridge_items (
    fridge_item_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fridge_id INTEGER NOT NULL,
    food_id INTEGER NOT NULL,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity >= 0),
    unit VARCHAR(50) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fridge_item FOREIGN KEY (fridge_id) REFERENCES fridges(fridge_id),
    CONSTRAINT fk_food_item FOREIGN KEY (food_id) REFERENCES foods(food_id),
    CONSTRAINT uq_fridge_food UNIQUE (fridge_id, food_id)
);

-- =========================================================
-- TABLA: recipe_ingredients
-- Relaciona cada receta con sus ingredientes.
-- UNIQUE (recipe_id, food_id) evita repetir el mismo alimento
-- dentro de una misma receta.
-- =========================================================
CREATE TABLE recipe_ingredients (
    recipe_ingredient_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recipe_id INTEGER NOT NULL,
    food_id INTEGER NOT NULL,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    unit VARCHAR(50) NOT NULL,
    CONSTRAINT fk_recipe_ingredient FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id) ON DELETE CASCADE,
    CONSTRAINT fk_food_ingredient FOREIGN KEY (food_id) REFERENCES foods(food_id),
    CONSTRAINT uq_recipe_food UNIQUE (recipe_id, food_id)
);

-- =========================================================
-- TABLA: user_recipes
-- Historial de recetas relacionadas con un usuario.
-- Permite saber si una receta fue aceptada, rechazada o ejecutada.
-- No se bloquean repeticiones porque el usuario puede volver a
-- ejecutar o consultar la misma receta varias veces.
-- =========================================================
CREATE TABLE user_recipes (
    user_recipe_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL,
    recipe_id INTEGER NOT NULL,
    status_id INTEGER NOT NULL,
    recipe_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_user_recipe FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_recipe_user_recipe FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id),
    CONSTRAINT fk_status_user_recipe FOREIGN KEY (status_id) REFERENCES statuses(status_id)
);

-- =========================================================
-- TABLA: physical_records
-- Guarda registros físicos del usuario para personalización:
-- altura, peso y fecha del registro.
-- height y weight usan NUMERIC para mayor precisión.
-- =========================================================
CREATE TABLE physical_records (
    physical_record_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL,
    height NUMERIC(5,2) CHECK (height > 0),
    weight NUMERIC(5,2) CHECK (weight > 0),
    record_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_physical_record FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- =========================================================
-- TABLA: meal_records
-- Encabezado del registro diario de comida del usuario.
-- =========================================================
CREATE TABLE meal_records (
    meal_record_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL,
    record_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_meal_record FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- =========================================================
-- TABLA: meal_record_details
-- Detalle de lo consumido en un registro de comida.
-- Puede referenciar una receta o un alimento individual.
-- quantity usa NUMERIC para soportar fracciones.
-- =========================================================
CREATE TABLE meal_record_details (
    meal_record_detail_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    meal_record_id INTEGER NOT NULL,
    recipe_id INTEGER,
    food_id INTEGER,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    CONSTRAINT fk_meal_record_detail FOREIGN KEY (meal_record_id) REFERENCES meal_records(meal_record_id) ON DELETE CASCADE,
    CONSTRAINT fk_recipe_detail FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id),
    CONSTRAINT fk_food_detail FOREIGN KEY (food_id) REFERENCES foods(food_id)
);

-- =========================================================
-- ÍNDICES
-- Mejoran búsquedas frecuentes por email, nombre, estado y fechas.
-- =========================================================
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_foods_name ON foods(name);
CREATE INDEX idx_meal_records_user_date ON meal_records(user_id, record_date);
CREATE INDEX idx_user_recipes_status ON user_recipes(status_id);
CREATE INDEX idx_fridge_items_fridge ON fridge_items(fridge_id);
