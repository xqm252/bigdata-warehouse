-- ============================================================
-- ADS 层：每日核心 KPI 指标表
--
-- 这是整个数仓的最终产出，直接对接 BI 报表/数据大屏。
-- 所有指标从 DWS 层汇总而来，无需回查明细数据。
--
-- 产出指标：
--   dau            日活用户数（当天下单的用户）
--   new_user_cnt   新增用户数（历史首次下单）
--   order_cnt      下单数
--   order_amount   下单金额(GMV)
--   pay_cnt        支付单数
--   pay_amount     支付金额
--   pay_rate       支付转化率
--   avg_order_amount 客单价
--   cancel_rate    取消率
-- ============================================================

CREATE DATABASE IF NOT EXISTS ads;
USE ads;

DROP TABLE IF EXISTS ads.ads_daily_kpi;

CREATE TABLE ads.ads_daily_kpi (
    dau              BIGINT         COMMENT '日活用户数（当天下单的独立用户）',
    new_user_cnt     BIGINT         COMMENT '新增用户数（历史首次下单）',
    order_cnt        BIGINT         COMMENT '下单数',
    order_amount     DECIMAL(18,2)  COMMENT '下单金额 (GMV)',
    pay_cnt          BIGINT         COMMENT '支付单数',
    pay_amount       DECIMAL(18,2)  COMMENT '支付金额',
    pay_rate         DECIMAL(8,4)   COMMENT '支付转化率 = 支付单数/下单数',
    avg_order_amount DECIMAL(10,2)  COMMENT '客单价 = 下单金额/下单数',
    cancel_rate      DECIMAL(8,4)   COMMENT '取消率 = 取消单数/下单数'
)
COMMENT '每日核心KPI指标表 — ADS层'
PARTITIONED BY (dt STRING COMMENT '数据日期')
STORED AS ORC
TBLPROPERTIES ('orc.compress'='SNAPPY');

-- ==================== ETL 逻辑 ====================
INSERT OVERWRITE TABLE ads.ads_daily_kpi PARTITION (dt = '${dt}')
SELECT
    -- 日活：当天下单的独立用户数
    COUNT(DISTINCT user_sk) AS dau,

    -- 新增用户：首单日期 = 今天的用户
    COUNT(DISTINCT CASE WHEN first_order_date = '${dt}'
                        THEN user_sk END) AS new_user_cnt,

    -- 下单
    SUM(order_cnt) AS order_cnt,
    SUM(order_amount) AS order_amount,

    -- 支付
    SUM(pay_cnt) AS pay_cnt,
    SUM(pay_amount) AS pay_amount,

    -- 支付转化率
    CAST(SUM(pay_cnt) AS DECIMAL(18,4))
        / NULLIF(CAST(SUM(order_cnt) AS DECIMAL(18,4)), 0) AS pay_rate,

    -- 客单价
    CAST(SUM(order_amount) AS DECIMAL(18,4))
        / NULLIF(CAST(SUM(order_cnt) AS DECIMAL(18,4)), 0) AS avg_order_amount,

    -- 取消率
    CAST(SUM(cancel_cnt) AS DECIMAL(18,4))
        / NULLIF(CAST(SUM(order_cnt) AS DECIMAL(18,4)), 0) AS cancel_rate

FROM dws.dws_user_daily_summary
WHERE dt = '${dt}';
