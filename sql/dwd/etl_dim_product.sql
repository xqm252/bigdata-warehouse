-- ============================================================
-- DWD ETL：商品维度表 初始全量加载 (SCD Type 2)
-- ============================================================

INSERT OVERWRITE TABLE dwd.dwd_dim_product
SELECT
    ROW_NUMBER() OVER (ORDER BY p.product_id) AS product_sk,
    CAST(p.product_id AS BIGINT) AS product_id,
    p.product_name,
    CAST(p.category_id AS INT) AS category_id,
    COALESCE(c.category_name, '未知') AS category_name,
    p.brand,
    CAST(p.price AS DECIMAL(10,2)) AS price,
    '${dt}' AS start_date,
    '9999-12-31' AS end_date,
    1 AS is_current
FROM ods.ods_product p
LEFT JOIN ods.ods_category c
    ON p.category_id = c.category_id AND c.dt = '${dt}'
WHERE p.dt = '${dt}';
