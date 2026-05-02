import pool from '../../database/connection.js';

/**
 * Busca alimentos globales y, opcionalmente, los creados por un usuario específico.
 */
export const findAllFoods = async ({ userId = null, page = null, limit = null } = {}) => {
  const filters = ['is_global = true AND is_active = true'];
  const params = [];

  if (userId !== null) {
    params.push(userId);
    filters.push(`created_by_user_id = $${params.length} AND is_active = true`);
  }

  const whereClause = `WHERE ${filters.join(' OR ')}`;

  const countQuery = `
        SELECT COUNT(*) AS total
        FROM foods
        ${whereClause}
    `;

  let dataQuery = `
        SELECT
            food_id AS "foodId",
            name,
            calories_per_unit AS "caloriesPerUnit",
            base_unit AS "baseUnit",
            is_global AS "isGlobal",
            is_active AS "isActive",
            created_by_user_id AS "createdByUserId",
            created_at AS "createdAt",
            updated_at AS "updatedAt"
        FROM foods
        ${whereClause}
        ORDER BY food_id ASC
    `;

  if (page !== null && limit !== null) {
    const offset = (page - 1) * limit;
    params.push(limit);
    dataQuery += ` LIMIT $${params.length}`;
    params.push(offset);
    dataQuery += ` OFFSET $${params.length}`;
  }

  // Corregido: countParams debe coincidir con la lógica de params de la dataQuery
  const countParams = userId !== null ? [userId] : [];

  const [{ rows: dataRows }, { rows: countRows }] = await Promise.all([
    pool.query(dataQuery, params),
    pool.query(countQuery, countParams),
  ]);

  const totalItems = Number(countRows[0].total);

  const response = {
    foods: dataRows,
  };

  if (page !== null && limit !== null) {
    response.pagination = {
      page,
      limit,
      totalItems,
      totalPages: Math.ceil(totalItems / limit),
    };
  }

  return response;
};

/**
 * Verifica la existencia de múltiples IDs de alimentos.
 */
export const checkFoodsExist = async (foodIds) => {
  const query = `
        SELECT food_id 
        FROM foods 
        WHERE food_id = ANY($1)
    `;
  const { rows } = await pool.query(query, [foodIds]);
  return rows.map(row => row.food_id);
};

/**
 * Inserta un nuevo alimento personalizado.
 */
export const create = async (foodData) => {
  const { name, calories_per_unit, base_unit, userId } = foodData;

  const query = `
        INSERT INTO foods (
            name, 
            calories_per_unit, 
            base_unit, 
            is_global, 
            is_active,
            created_by_user_id
        ) VALUES ($1, $2, $3, false, true, $4)
        RETURNING food_id AS "foodId"
    `;

  const { rows } = await pool.query(query, [name, calories_per_unit, base_unit, userId]);
  return rows[0].foodId;
};

/**
 * Obtiene un alimento por su ID (usado para validar propiedad antes de editar).
 * Corregido para usar la columna correcta 'food_id'.
 */
export const getFoodById = async (id) => {
  const query = `
        SELECT 
            food_id AS "foodId", 
            created_by_user_id AS "createdByUserId", 
            is_global AS "isGlobal",
            is_active AS "isActive"
        FROM foods 
        WHERE food_id = $1
    `;
  const { rows } = await pool.query(query, [id]);
  return rows[0];
};

/**
 * Actualiza un alimento de forma dinámica.
 * Implementa consultas parametrizadas para seguridad.
 */
export const updateFood = async (id, data) => {
  if (Object.keys(data).length === 0) {
    return null;
  }

  const fields = [];
  const values = [];
  let idx = 1;

  // Construcción dinámica asegurando que los nombres de las columnas coincidan con DB
  for (const [key, value] of Object.entries(data)) {
    fields.push(`${key} = $${idx}`);
    values.push(value);
    idx++;
  }

  values.push(id);
  const query = `
        UPDATE foods 
        SET ${fields.join(', ')}, updated_at = NOW() 
        WHERE food_id = $${idx} 
        RETURNING 
            food_id AS "foodId", 
            name, 
            calories_per_unit AS "caloriesPerUnit", 
            base_unit AS "baseUnit"
    `;

  const { rows } = await pool.query(query, values);
  return rows[0];
};

/**
 * Desactiva un alimento por su ID.
 */
export const deactivateFood = async (id) => {
  const query = `
        UPDATE foods
        SET is_active = false, updated_at = NOW()
        WHERE food_id = $1
        RETURNING food_id AS "foodId"
    `;
  const { rows } = await pool.query(query, [id]);
  return rows[0];
};

/**
 * Verifica si existe un alimento con el nombre dado (global o creado por el usuario)
 */
export const findFoodByName = async (name, userId) => {
  const query = `
        SELECT food_id AS "foodId", name, is_global AS "isGlobal", created_by_user_id AS "createdByUserId"
        FROM foods
        WHERE name = $1 AND (is_global = true OR created_by_user_id = $2)
        LIMIT 1
    `;
  const { rows } = await pool.query(query, [name, userId]);
  return rows[0];
};
