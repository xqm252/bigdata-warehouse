-- ============================================================
-- DWD ETL：订单事实表 初始全量加载
--
-- 从 ODS 读取订单数据，关联维度表获取代理键，写入事实表。
-- ============================================================

SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE dwd.dwd_fact_order PARTITION (dt)
SELECT
    ROW_NUMBER() OVER (ORDER BY o.order_id) AS order_sk,
    CAST(o.order_id AS BIGINT) AS order_id,
    u.user_sk,
    p.product_sk,
    CAST(o.order_amount AS DECIMAL(10,2)) AS order_amount,
    CAST(o.order_status AS TINYINT) AS order_status,
    CAST(o.create_time AS TIMESTAMP) AS create_time,
    CAST(o.update_time AS TIMESTAMP) AS update_time,
    '${dt}' AS dt
FROM ods.ods_order o
INNER JOIN dwd.dwd_dim_user u
    ON CAST(o.user_id AS BIGINT) = u.user_id AND u.is_current = 1
INNER JOIN dwd.dwd_dim_product p
    ON CAST(o.product_id AS BIGINT) = p.product_id AND p.is_current = 1
WHERE o.dt = '${dt}'
  AND o.order_id IS NOT NULL
  AND o.order_amount > 0
  AND o.order_status IN (1, 2, 3, 4, 5);
