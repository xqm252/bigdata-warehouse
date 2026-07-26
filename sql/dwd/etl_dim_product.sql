-- ============================================================
-- DWD ETL：商品维度表 SCD Type 2 增量加载
-- 逻辑与用户维度表一致
-- ============================================================

INSERT OVERWRITE TABLE dwd.dwd_dim_product
SELECT
    old.product_sk,
    old.product_id,
    old.product_name,
    old.category_id,
    old.category_name,
    old.brand,
    old.price,
    old.start_date,
    CASE
        WHEN new.product_id IS NOT NULL AND old.is_current = 1
             AND (old.product_name <> new.product_name
               OR old.price <> CAST(new.price AS DECIMAL(10,2))
               OR old.brand <> new.brand)
        THEN '${dt}'
        ELSE old.end_date
    END AS end_date,
    CASE
        WHEN new.product_id IS NOT NULL AND old.is_current = 1
             AND (old.product_name <> new.product_name
               OR old.price <> CAST(new.price AS DECIMAL(10,2))
               OR old.brand <> new.brand)
        THEN 0
        ELSE old.is_current
    END AS is_current
FROM dwd.dwd_dim_product old
LEFT JOIN (
    SELECT p.product_id, p.product_name, p.category_id, p.price, p.brand,
           c.category_name
    FROM ods.ods_product p
    LEFT JOIN ods.ods_category c ON p.category_id = c.category_id
    WHERE p.dt = '${dt}' AND c.dt = '${dt}'
) new ON old.product_id = new.product_id

UNION ALL

SELECT
    (COALESCE(max_sk, 0) + ROW_NUMBER() OVER (ORDER BY new.product_id)) AS product_sk,
    new.product_id,
    new.product_name,
    new.category_id,
    new.category_name,
    new.brand,
    CAST(new.price AS DECIMAL(10,2)) AS price,
    '${dt}' AS start_date,
    '9999-12-31' AS end_date,
    1 AS is_current
FROM (
    SELECT DISTINCT
        p.product_id, p.product_name, p.category_id, p.price, p.brand,
        c.category_name
    FROM ods.ods_product p
    LEFT JOIN ods.ods_category c ON p.category_id = c.category_id
    WHERE p.dt = '${dt}' AND c.dt = '${dt}'
) new
LEFT JOIN dwd.dwd_dim_product old2
    ON new.product_id = old2.product_id AND old2.is_current = 1
WHERE old2.product_id IS NULL
   OR old2.product_name <> new.product_name
   OR old2.price <> CAST(new.price AS DECIMAL(10,2))
   OR old2.brand <> new.brand
CROSS JOIN (SELECT COALESCE(MAX(product_sk), 0) AS max_sk FROM dwd.dwd_dim_product) t;
