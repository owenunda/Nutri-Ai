import pool from '../../database/connection.js';

/**
 * Busca alimentos globales y, opcionalmente, los creados por un usuario específico.
 */
export const findAllFoods = async ({ userId = null, page = null, limit = null } = {}) => {
  const params = [userId];
  const whereClause = `
        WHERE
            is_active = true
            AND (
                is_global = true
                OR created_by_user_id = $1
            )
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
            updated_at AS "updatedAt",
            COUNT(*) OVER() AS total_items
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

  const { rows: dataRows } = await pool.query(dataQuery, params);
  const foods = dataRows.map(({ total_items, ...food }) => food);
  const totalItems = page !== null && limit !== null
    ? Number(dataRows[0]?.total_items ?? 0)
    : foods.length;

  const response = {
    foods,
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
 * Normaliza el nombre en SQL igual que normalizeFoodName() lo hace en JS:
 * minúsculas y sin acentos. Se usa translate() en vez de unaccent() para no
 * depender de una extensión de Postgres.
 *
 * Los plurales NO se tocan aquí: quitar la "s" a ciegas convierte "limones"
 * en "limone". El singular se resuelve en JS con singularCandidates(), que
 * propone varias formas y deja que la base diga cuál existe.
 *
 * Si esta expresión cambia hay que actualizar también el índice funcional de
 * update_26_07_2026.sql, o dejará de usarse.
 */
const NORMALIZED_NAME_SQL = `
    translate(
        lower(name),
        'áàäâãéèëêíìïîóòöôõúùüûñç',
        'aaaaaeeeeiiiiooooouuuunc'
    )
`;

const VISIBLE_FOODS_SQL = `
    SELECT
        food_id AS "foodId",
        name,
        calories_per_unit AS "caloriesPerUnit",
        base_unit AS "baseUnit",
        is_global AS "isGlobal",
        created_by_user_id AS "createdByUserId",
        ${NORMALIZED_NAME_SQL} AS normalized_name
    FROM foods
    WHERE is_active = true
        AND (is_global = true OR created_by_user_id = $2)
`;

const RETURNED_COLUMNS = `"foodId", name, "caloriesPerUnit", "baseUnit", "isGlobal", "createdByUserId"`;

/**
 * Igualdad estricta sobre el nombre normalizado. Para verificar duplicados:
 * crear "Pollo" no debe rechazarse porque exista "Pechuga de pollo".
 *
 * @param {string} normalizedName ya pasado por normalizeFoodName()
 */
export const findFoodByExactName = async (normalizedName, userId) => {
  const query = `
        WITH visibles AS (${VISIBLE_FOODS_SQL})
        SELECT ${RETURNED_COLUMNS}
        FROM visibles
        WHERE normalized_name = $1
        LIMIT 1
    `;
  const { rows } = await pool.query(query, [normalizedName, userId]);
  return rows[0];
};

/**
 * Búsqueda tolerante para mapear lo que escribe el usuario. Primero intenta
 * igualdad con cualquiera de las formas propuestas; si ninguna existe, acepta
 * que el término aparezca como palabra completa dentro del nombre, de modo que
 * "pollo" encuentre "Pechuga de pollo". Entre varias parciales gana la de
 * nombre más corto, que es la más genérica.
 *
 * @param {string[]} terms formas candidatas de singularCandidates()
 */
export const matchFoodByTerms = async (terms, userId) => {
  const query = `
        WITH visibles AS (${VISIBLE_FOODS_SQL})
        SELECT ${RETURNED_COLUMNS}
        FROM visibles
        WHERE normalized_name = ANY($1::text[])
            OR EXISTS (
                SELECT 1
                FROM unnest($1::text[]) AS t(term)
                WHERE normalized_name LIKE t.term || ' %'
                    OR normalized_name LIKE '% ' || t.term
                    OR normalized_name LIKE '% ' || t.term || ' %'
            )
        ORDER BY
            CASE WHEN normalized_name = ANY($1::text[]) THEN 0 ELSE 1 END,
            length(normalized_name),
            "foodId"
        LIMIT 1
    `;
  const { rows } = await pool.query(query, [terms, userId]);
  return rows[0];
};
