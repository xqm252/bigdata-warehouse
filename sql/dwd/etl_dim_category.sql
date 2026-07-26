-- ============================================================
-- DWD ETL：商品分类维度表全量加载
-- 分类数据量小，直接全量覆盖即可 (SCD Type 1)
-- ============================================================

INSERT OVERWRITE TABLE dwd.dwd_dim_category
SELECT
    c1.category_id AS category_sk,
    c1.category_id,
    c1.category_name,
    c1.parent_id,
    COALESCE(c2.category_name, '无') AS parent_name,
    CASE WHEN c1.parent_id = 0 THEN 1 ELSE 2 END AS level
FROM ods.ods_category c1
LEFT JOIN ods.ods_category c2
    ON c1.parent_id = c2.category_id
WHERE c1.dt = '${dt}';
