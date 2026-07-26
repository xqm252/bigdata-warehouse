-- ============================================================
-- DWS 层：用户日活汇总表
--
-- 从 DWD 事实表按用户+日期粒度聚合
-- 产出的指标供 ADS 层直接取用，避免反复扫描事实表
-- ============================================================

CREATE DATABASE IF NOT EXISTS dws;
USE dws;

DROP TABLE IF EXISTS dws.dws_user_daily_summary;

CREATE TABLE dws.dws_user_daily_summary (
    user_sk          BIGINT         COMMENT '用户代理键',
    order_cnt        BIGINT         COMMENT '当日下单数',
    order_amount     DECIMAL(18,2)  COMMENT '当日下单金额',
    pay_cnt          BIGINT         COMMENT '当日支付数（已支付+已发货+已完成）',
    pay_amount       DECIMAL(18,2)  COMMENT '当日支付金额',
    cancel_cnt       BIGINT         COMMENT '当日取消数',
    first_order_date STRING         COMMENT '历史首单日期（用于判断新老客）',
    last_order_date  STRING         COMMENT '最近下单日期'
)
COMMENT '用户日活汇总表 — DWS层'
PARTITIONED BY (dt STRING COMMENT '数据日期')
STORED AS ORC
TBLPROPERTIES ('orc.compress'='SNAPPY');

-- ==================== ETL 逻辑 ====================
-- 每日执行，汇总当天数据
INSERT OVERWRITE TABLE dws.dws_user_daily_summary PARTITION (dt = '${dt}')
SELECT
    user_sk,
    COUNT(1) AS order_cnt,
    SUM(order_amount) AS order_amount,
    -- 支付：状态 2/3/4 都算支付
    SUM(CASE WHEN order_status IN (2, 3, 4) THEN 1 ELSE 0 END) AS pay_cnt,
    SUM(CASE WHEN order_status IN (2, 3, 4) THEN order_amount ELSE 0 END) AS pay_amount,
    SUM(CASE WHEN order_status = 5 THEN 1 ELSE 0 END) AS cancel_cnt,
    -- 历史首单/末单日期（首次加载时 = 当天，后续需跨分区查询更新）
    CAST(MIN(create_time) AS STRING) AS first_order_date,
    CAST(MAX(create_time) AS STRING) AS last_order_date
FROM dwd.dwd_fact_order
WHERE dt = '${dt}'
GROUP BY user_sk;
