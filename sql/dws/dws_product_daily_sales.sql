-- ============================================================
-- DWS 层：商品日销量汇总表
-- 按商品+日期粒度聚合
-- ============================================================

CREATE DATABASE IF NOT EXISTS dws;
USE dws;

DROP TABLE IF EXISTS dws.dws_product_daily_sales;

CREATE TABLE dws.dws_product_daily_sales (
    product_sk   BIGINT         COMMENT '商品代理键',
    order_cnt    BIGINT         COMMENT '当日下单数',
    order_amount DECIMAL(18,2)  COMMENT '当日下单金额',
    pay_cnt      BIGINT         COMMENT '当日支付数',
    pay_amount   DECIMAL(18,2)  COMMENT '当日支付金额',
    buyer_cnt    BIGINT         COMMENT '当日购买人数',
    cancel_cnt   BIGINT         COMMENT '当日取消数'
)
COMMENT '商品日销量汇总表 — DWS层'
PARTITIONED BY (dt STRING COMMENT '数据日期')
STORED AS ORC
TBLPROPERTIES ('orc.compress'='SNAPPY');

-- ==================== ETL 逻辑 ====================
INSERT OVERWRITE TABLE dws.dws_product_daily_sales PARTITION (dt = '${dt}')
SELECT
    product_sk,
    COUNT(1) AS order_cnt,
    SUM(order_amount) AS order_amount,
    SUM(CASE WHEN order_status IN (2, 3, 4) THEN 1 ELSE 0 END) AS pay_cnt,
    SUM(CASE WHEN order_status IN (2, 3, 4) THEN order_amount ELSE 0 END) AS pay_amount,
    COUNT(DISTINCT user_sk) AS buyer_cnt,
    SUM(CASE WHEN order_status = 5 THEN 1 ELSE 0 END) AS cancel_cnt
FROM dwd.dwd_fact_order
WHERE dt = '${dt}'
GROUP BY product_sk;
