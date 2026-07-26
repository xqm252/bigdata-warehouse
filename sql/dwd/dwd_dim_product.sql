-- ============================================================
-- DWD 层：商品维度表 (SCD Type 2)
-- 同样采用缓慢变化维度策略，追踪商品价格、名称等变更历史
-- ============================================================

CREATE DATABASE IF NOT EXISTS dwd;
USE dwd;

DROP TABLE IF EXISTS dwd.dwd_dim_product;

CREATE TABLE dwd.dwd_dim_product (
    product_sk    BIGINT         COMMENT '代理键',
    product_id    BIGINT         COMMENT '商品业务ID',
    product_name  STRING         COMMENT '商品名称',
    category_id   INT            COMMENT '分类ID',
    category_name STRING         COMMENT '分类名称（退化维度）',
    brand         STRING         COMMENT '品牌',
    price         DECIMAL(10,2)  COMMENT '当前价格',
    start_date    STRING         COMMENT '版本生效日期',
    end_date      STRING         COMMENT '版本失效日期',
    is_current    TINYINT        COMMENT '是否当前有效'
)
COMMENT '商品维度表 (SCD Type 2) — DWD层'
STORED AS ORC
TBLPROPERTIES ('orc.compress'='SNAPPY');
