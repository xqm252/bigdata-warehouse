-- ============================================================
-- DWD ETL：用户维度表 初始全量加载 (SCD Type 2)
--
-- 首次运行时执行，将所有 ODS 用户作为初始版本导入。
-- 生产环境的增量更新逻辑见 etl_dim_user_incremental.sql
-- ============================================================

INSERT OVERWRITE TABLE dwd.dwd_dim_user
SELECT
    ROW_NUMBER() OVER (ORDER BY user_id) AS user_sk,
    CAST(user_id AS BIGINT) AS user_id,
    user_name,
    CAST(gender AS TINYINT) AS gender,
    city,
    province,
    register_time,
    '${dt}' AS start_date,
    '9999-12-31' AS end_date,
    1 AS is_current
FROM ods.ods_user
WHERE dt = '${dt}';
