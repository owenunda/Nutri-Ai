-- =========================================================
-- CATÁLOGO DE ALIMENTOS EN ESPAÑOL
--
-- El seed original (seed_foods.sql) trae 4 alimentos en inglés, así que
-- /api/v1/food/match no encontraba nada para mensajes como "tengo pasta
-- y tomate" y el agente de recetas se quedaba sin ingredientes.
--
-- La normalización de abajo (minúsculas y sin acentos) es la MISMA que usan
-- NORMALIZED_NAME_SQL en food.repository.js y normalizeFoodName() en
-- food.service.js. Si cambia una, tienen que cambiar las tres o el índice
-- deja de servir y las búsquedas empiezan a fallar en silencio.
--
-- Los plurales no se tocan aquí: los resuelve singularCandidates() en JS,
-- que propone varias formas porque quitar la "s" a ciegas convierte
-- "limones" en "limone".
--
-- El script es idempotente: se puede correr varias veces sin duplicar.
-- =========================================================

-- Índice funcional para la búsqueda por nombre normalizado.
-- lower() y translate() son IMMUTABLE, así que Postgres acepta indexarlas.
CREATE INDEX IF NOT EXISTS idx_foods_normalized_name
ON foods (
    translate(
        lower(name),
        'áàäâãéèëêíìïîóòöôõúùüûñç',
        'aaaaaeeeeiiiiooooouuuunc'
    )
);

INSERT INTO foods (name, calories_per_unit, base_unit, is_global, is_active)
SELECT nuevo.name, nuevo.calories, nuevo.unit, TRUE, TRUE
FROM (VALUES
    -- Proteínas
    ('Huevo',                 78.00, '1 UNIDAD'),
    ('Pechuga de pollo',     165.00, '100 G'),
    ('Muslo de pollo',       209.00, '100 G'),
    ('Carne de res molida',  250.00, '100 G'),
    ('Lomo de cerdo',        242.00, '100 G'),
    ('Atún en lata',         132.00, '100 G'),
    ('Salmón',               208.00, '100 G'),
    ('Tilapia',               96.00, '100 G'),
    ('Camarón',               99.00, '100 G'),
    ('Jamón',                145.00, '100 G'),
    ('Salchicha',            301.00, '100 G'),
    ('Tocineta',             541.00, '100 G'),

    -- Lácteos
    ('Leche entera',          61.00, '100 ML'),
    ('Leche descremada',      34.00, '100 ML'),
    ('Queso fresco',         264.00, '100 G'),
    ('Queso mozzarella',     280.00, '100 G'),
    ('Queso parmesano',      431.00, '100 G'),
    ('Yogur natural',         59.00, '100 G'),
    ('Mantequilla',          717.00, '100 G'),
    ('Crema de leche',       340.00, '100 G'),

    -- Granos y cereales
    ('Arroz blanco',         130.00, '100 G COCIDO'),
    ('Arroz integral',       111.00, '100 G COCIDO'),
    ('Pasta',                131.00, '100 G COCIDA'),
    ('Espagueti',            131.00, '100 G COCIDO'),
    ('Pan integral',         247.00, '100 G'),
    ('Pan blanco',           265.00, '100 G'),
    ('Avena',                389.00, '100 G'),
    ('Quinua',               120.00, '100 G COCIDA'),
    ('Arepa',                250.00, '1 UNIDAD'),
    ('Harina de trigo',      364.00, '100 G'),

    -- Legumbres
    ('Frijol',               127.00, '100 G COCIDO'),
    ('Lenteja',              116.00, '100 G COCIDA'),
    ('Garbanzo',             164.00, '100 G COCIDO'),
    ('Arveja',                81.00, '100 G'),

    -- Verduras y tubérculos
    ('Tomate',                18.00, '100 G'),
    ('Cebolla',               40.00, '100 G'),
    ('Cebolla larga',         32.00, '100 G'),
    ('Ajo',                  149.00, '100 G'),
    ('Papa',                  77.00, '100 G'),
    ('Yuca',                 160.00, '100 G'),
    ('Plátano',              122.00, '100 G'),
    ('Zanahoria',             41.00, '100 G'),
    ('Pimentón',              31.00, '100 G'),
    ('Brócoli',               34.00, '100 G'),
    ('Coliflor',              25.00, '100 G'),
    ('Espinaca',              23.00, '100 G'),
    ('Lechuga',               15.00, '100 G'),
    ('Pepino',                15.00, '100 G'),
    ('Calabacín',             17.00, '100 G'),
    ('Champiñón',             22.00, '100 G'),
    ('Apio',                  16.00, '100 G'),
    ('Maíz',                  86.00, '100 G'),
    ('Auyama',                26.00, '100 G'),
    ('Habichuela',            31.00, '100 G'),
    ('Cilantro',              23.00, '100 G'),

    -- Frutas
    ('Banano',                89.00, '100 G'),
    ('Manzana',               52.00, '100 G'),
    ('Naranja',               47.00, '100 G'),
    ('Fresa',                 32.00, '100 G'),
    ('Mango',                 60.00, '100 G'),
    ('Piña',                  50.00, '100 G'),
    ('Papaya',                43.00, '100 G'),
    ('Aguacate',             160.00, '100 G'),
    ('Limón',                 29.00, '100 G'),
    ('Uva',                   69.00, '100 G'),
    ('Mora',                  43.00, '100 G'),
    ('Maracuyá',              97.00, '100 G'),

    -- Despensa
    ('Aceite de oliva',      884.00, '100 ML'),
    ('Aceite vegetal',       884.00, '100 ML'),
    ('Azúcar',               387.00, '100 G'),
    ('Sal',                    0.00, '100 G'),
    ('Panela',               380.00, '100 G'),
    ('Miel',                 304.00, '100 G'),
    ('Chocolate',            546.00, '100 G'),
    ('Maní',                 567.00, '100 G'),
    ('Almendra',             579.00, '100 G')
) AS nuevo(name, calories, unit)
WHERE NOT EXISTS (
    SELECT 1
    FROM foods existente
    WHERE existente.is_global = TRUE
      AND translate(lower(existente.name),
                    'áàäâãéèëêíìïîóòöôõúùüûñç',
                    'aaaaaeeeeiiiiooooouuuunc')
        = translate(lower(nuevo.name),
                    'áàäâãéèëêíìïîóòöôõúùüûñç',
                    'aaaaaeeeeiiiiooooouuuunc')
);
