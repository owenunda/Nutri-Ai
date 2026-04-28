import pool from '../../database/connection.js';

// Esta capa consulta alimentos globales y, opcionalmente, los creados por un usuario.
export const findAllFoods = async ({ userId = null, page = null, limit = null } = {}) => {
  const filters = ['is_global = true'];
  const params = [];

  if (userId !== null) {
    params.push(userId);
    filters.push(`created_by_user_id = $${params.length}`);
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
