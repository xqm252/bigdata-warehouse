-- ============================================================
-- DWD ETL：订单事实表增量加载
--
-- 核心逻辑：
--   1. 从 ODS 读取当日增量订单
--   2. 通过 user_id 关联 dwd_dim_user 获取当前有效的 user_sk
--   3. 通过 product_id 关联 dwd_dim_product 获取当前有效的 product_sk
--   4. 字段类型转换：STRING → TIMESTAMP
--   5. 脏数据过滤
--
-- 注意：事实表的外键关联必须取 is_current=1 的维度记录
-- ============================================================

-- 设置 Hive 动态分区
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE dwd.dwd_fact_order PARTITION (dt)
SELECT
    -- 代理键：使用 ROW_NUMBER 生成
    ROW_NUMBER() OVER (ORDER BY o.order_id) + COALESCE(max_sk, 0) AS order_sk,
    o.order_id,
    -- 关联维度表获取代理键（关键步骤！）
    u.user_sk,
    p.product_sk,
    o.order_amount,
    o.order_status,
    -- 字段清洗：STRING → TIMESTAMP
    CAST(o.create_time AS TIMESTAMP) AS create_time,
    CAST(o.update_time AS TIMESTAMP) AS update_time,
    '${dt}' AS dt
FROM (
    SELECT
        order_id,
        user_id,
        product_id,
        order_amount,
        order_status,
        create_time,
        update_time
    FROM ods.ods_order
    WHERE dt = '${dt}'
      -- 脏数据过滤
      AND order_id IS NOT NULL
      AND user_id IS NOT NULL
      AND product_id IS NOT NULL
      AND order_amount > 0
      AND order_status IN (1, 2, 3, 4, 5)
) o
-- 关联当前有效的用户维度
LEFT JOIN dwd.dwd_dim_user u
    ON o.user_id = u.user_id AND u.is_current = 1
-- 关联当前有效的商品维度
LEFT JOIN dwd.dwd_dim_product p
    ON o.product_id = p.product_id AND p.is_current = 1
CROSS JOIN (
    SELECT COALESCE(MAX(order_sk), 0) AS max_sk FROM dwd.dwd_fact_order
) t
-- 过滤掉维度关联不上的脏数据
WHERE u.user_sk IS NOT NULL AND p.product_sk IS NOT NULL;
