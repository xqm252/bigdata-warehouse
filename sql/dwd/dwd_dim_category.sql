-- ============================================================
-- DWD 层：商品分类维度表
-- 分类数据不常变更，采用 SCD Type 1（直接覆盖）即可
-- 但为了保持整个数仓建模风格一致，这里也做成维度表格式
-- ============================================================

CREATE DATABASE IF NOT EXISTS dwd;
USE dwd;

DROP TABLE IF EXISTS dwd.dwd_dim_category;

CREATE TABLE dwd.dwd_dim_category (
    category_sk   INT    COMMENT '代理键',
    category_id   INT    COMMENT '分类业务ID',
    category_name STRING COMMENT '分类名称',
    parent_id     INT    COMMENT '父分类ID',
    parent_name   STRING COMMENT '父分类名称',
    level         TINYINT COMMENT '分类层级: 1一级 2二级'
)
COMMENT '商品分类维度表 — DWD层'
STORED AS ORC
TBLPROPERTIES ('orc.compress'='SNAPPY');
