-- ============================================================
-- DWD ETL：用户维度表 SCD Type 2 增量加载
--
-- 执行频率：每日一次（在 ODS 数据就绪后执行）
-- 处理逻辑：
--   Step 1: 将 ODS 中已变更的用户旧版本标记为失效
--   Step 2: 为变更用户插入新版本记录
--   Step 3: 对新用户直接插入
--
-- 传参：${dt} = 数据日期，如 '2026-07-26'
-- ============================================================

-- ====== Step 0: 设置参数 ======
-- 在 beeline 中执行时传入: --hivevar dt=2026-07-26
-- 这里用变量引用

-- ====== Step 1: 处理已存在的用户 — 变更的标记失效 ======
-- 逻辑：如果 ODS 中的某个字段与当前有效版本不同，则旧记录失效
INSERT OVERWRITE TABLE dwd.dwd_dim_user
SELECT
    old.user_sk,
    old.user_id,
    old.user_name,
    old.gender,
    old.city,
    old.province,
    old.register_time,
    old.start_date,
    -- 如果有变更且当前有效，end_date 设为昨天
    CASE
        WHEN new.user_id IS NOT NULL AND old.is_current = 1
             AND (old.user_name <> new.user_name
               OR old.city <> new.city
               OR old.province <> new.province
               OR old.gender <> CAST(new.gender AS TINYINT))
        THEN '${dt}'
        ELSE old.end_date
    END AS end_date,
    -- 如果有变更且当前有效，标记为失效
    CASE
        WHEN new.user_id IS NOT NULL AND old.is_current = 1
             AND (old.user_name <> new.user_name
               OR old.city <> new.city
               OR old.province <> new.province
               OR old.gender <> CAST(new.gender AS TINYINT))
        THEN 0
        ELSE old.is_current
    END AS is_current
FROM dwd.dwd_dim_user old
LEFT JOIN (
    SELECT user_id, user_name, gender, city, province, register_time
    FROM ods.ods_user
    WHERE dt = '${dt}'
) new ON old.user_id = new.user_id

UNION ALL

-- ====== Step 2: 插入变更用户的新版本 + 新用户 ======
SELECT
    (COALESCE(max_sk, 0) + ROW_NUMBER() OVER (ORDER BY new.user_id)) AS user_sk,
    new.user_id,
    new.user_name,
    CAST(new.gender AS TINYINT) AS gender,
    new.city,
    new.province,
    new.register_time,
    '${dt}' AS start_date,
    '9999-12-31' AS end_date,
    1 AS is_current
FROM (
    SELECT DISTINCT new2.*
    FROM ods.ods_user new2
    LEFT JOIN dwd.dwd_dim_user old2
      ON new2.user_id = old2.user_id AND old2.is_current = 1
    WHERE new2.dt = '${dt}'
      -- 新用户 (old 不存在) 或 有变更的用户
      AND (old2.user_id IS NULL
           OR old2.user_name <> new2.user_name
           OR old2.city <> new2.city
           OR old2.province <> new2.province
           OR old2.gender <> CAST(new2.gender AS TINYINT))
) new
CROSS JOIN (SELECT COALESCE(MAX(user_sk), 0) AS max_sk FROM dwd.dwd_dim_user) t;
