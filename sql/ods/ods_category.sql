-- ============================================================
-- ODS 层：商品分类贴源表
-- 数据来源：MySQL biz_category 表 (Sqoop 全量导入)
-- 存储格式：TextFile（贴源保持原始格式）
-- 分区策略：按 dt（日期）分区，每天一个分区
-- ============================================================

CREATE DATABASE IF NOT EXISTS ods;
USE ods;

DROP TABLE IF EXISTS ods.ods_category;

CREATE EXTERNAL TABLE ods.ods_category (
    category_id   INT      COMMENT '分类ID',
    category_name STRING   COMMENT '分类名称',
    parent_id     INT      COMMENT '父分类ID，0表示一级分类'
)
COMMENT '商品分类贴源表 — ODS层'
PARTITIONED BY (dt STRING COMMENT '数据日期，格式yyyy-MM-dd')
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/ods.db/ods_category';

-- 注意：首次加载需要手动添加分区并加载数据
-- ALTER TABLE ods.ods_category ADD PARTITION (dt='2026-07-26');
-- LOAD DATA INPATH '/user/data/biz_category.csv' INTO TABLE ods.ods_category PARTITION (dt='2026-07-26');
