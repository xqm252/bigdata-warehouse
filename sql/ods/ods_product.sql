-- ============================================================
-- ODS 层：商品贴源表
-- 数据来源：MySQL biz_product 表 (Sqoop 全量/增量导入)
-- ============================================================

CREATE DATABASE IF NOT EXISTS ods;
USE ods;

DROP TABLE IF EXISTS ods.ods_product;

CREATE EXTERNAL TABLE ods.ods_product (
    product_id    BIGINT   COMMENT '商品ID',
    product_name  STRING   COMMENT '商品名称',
    category_id   INT      COMMENT '分类ID',
    price         DECIMAL(10,2) COMMENT '价格',
    brand         STRING   COMMENT '品牌'
)
COMMENT '商品贴源表 — ODS层'
PARTITIONED BY (dt STRING COMMENT '数据日期')
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/ods.db/ods_product';

-- ALTER TABLE ods.ods_product ADD PARTITION (dt='2026-07-26');
