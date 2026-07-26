-- ============================================================
-- ODS 层：用户贴源表
-- 数据来源：MySQL biz_user 表 (Sqoop 全量/增量导入)
-- 存储格式：TextFile
-- 分区策略：按 dt（日期）分区
-- ============================================================

CREATE DATABASE IF NOT EXISTS ods;
USE ods;

DROP TABLE IF EXISTS ods.ods_user;

CREATE EXTERNAL TABLE ods.ods_user (
    user_id        BIGINT   COMMENT '用户ID',
    user_name      STRING   COMMENT '用户名',
    gender         TINYINT  COMMENT '性别: 0未知 1男 2女',
    city           STRING   COMMENT '城市',
    province       STRING   COMMENT '省份',
    register_time  STRING   COMMENT '注册时间'
)
COMMENT '用户贴源表 — ODS层'
PARTITIONED BY (dt STRING COMMENT '数据日期')
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/ods.db/ods_user';

-- ALTER TABLE ods.ods_user ADD PARTITION (dt='2026-07-26');
-- LOAD DATA INPATH '/user/data/biz_user.csv' INTO TABLE ods.ods_user PARTITION (dt='2026-07-26');
