-- ============================================================
-- ODS 层：订单贴源表
-- 数据来源：MySQL biz_order 表 (Sqoop 增量导入，按 update_time)
-- 存储格式：TextFile
-- 分区策略：按 dt（日期）分区
-- ============================================================

CREATE DATABASE IF NOT EXISTS ods;
USE ods;

DROP TABLE IF EXISTS ods.ods_order;

CREATE EXTERNAL TABLE ods.ods_order (
    order_id      BIGINT         COMMENT '订单ID',
    user_id       BIGINT         COMMENT '用户ID',
    product_id    BIGINT         COMMENT '商品ID',
    order_amount  DECIMAL(10,2)  COMMENT '订单金额',
    order_status  TINYINT        COMMENT '订单状态: 1待支付 2已支付 3已发货 4已完成 5已取消',
    create_time   STRING         COMMENT '创建时间',
    update_time   STRING         COMMENT '更新时间'
)
COMMENT '订单贴源表 — ODS层'
PARTITIONED BY (dt STRING COMMENT '数据日期，格式yyyy-MM-dd')
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/ods.db/ods_order';

-- ALTER TABLE ods.ods_order ADD PARTITION (dt='2026-07-26');
