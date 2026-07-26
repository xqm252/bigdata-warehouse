-- ============================================================
-- DWD 层：用户维度表 (SCD Type 2 — 缓慢变化维度)
--
-- SCD Type 2 说明：
--   当用户属性（城市、省份等）发生变更时，不覆盖旧记录，
--   而是将旧记录标记为失效，插入一条新记录。
--   这样可以追溯用户在不同时间段的信息，支持历史分析。
--
-- 关键字段：
--   user_sk    : 代理键，唯一标识维度表中的一行
--   user_id    : 业务主键，来自源系统
--   start_date : 该版本生效日期
--   end_date   : 该版本失效日期（9999-12-31 表示当前有效）
--   is_current : 1=当前有效版本, 0=历史版本
-- ============================================================

CREATE DATABASE IF NOT EXISTS dwd;
USE dwd;

DROP TABLE IF EXISTS dwd.dwd_dim_user;

CREATE TABLE dwd.dwd_dim_user (
    user_sk       BIGINT   COMMENT '代理键（自增，唯一标识）',
    user_id       BIGINT   COMMENT '业务主键（来自源系统）',
    user_name     STRING   COMMENT '用户名',
    gender        TINYINT  COMMENT '性别: 0未知 1男 2女',
    city          STRING   COMMENT '城市',
    province      STRING   COMMENT '省份',
    register_time STRING   COMMENT '注册时间',
    start_date    STRING   COMMENT '版本生效日期',
    end_date      STRING   COMMENT '版本失效日期（9999-12-31=当前有效）',
    is_current    TINYINT  COMMENT '是否当前有效: 1有效 0已失效'
)
COMMENT '用户维度表 (SCD Type 2) — DWD层'
STORED AS ORC
TBLPROPERTIES ('orc.compress'='SNAPPY');

-- 注意：此表为 DDL 建表，实际数据由 etl_dim_user.sql 每日 ETL 产生
