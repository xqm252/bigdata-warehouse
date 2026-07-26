-- ============================================================
-- DWD 层：订单事实表（星型模型的核心）
--
-- 设计要点：
--   1. 外键关联：user_sk → dwd_dim_user, product_sk → dwd_dim_product
--   2. 时间字段已从 STRING 清洗为 TIMESTAMP 类型
--   3. 按 dt 分区，支持按日期快速查询
--   4. 使用 ORC 列式存储 + SNAPPY 压缩
-- ============================================================

CREATE DATABASE IF NOT EXISTS dwd;
USE dwd;

DROP TABLE IF EXISTS dwd.dwd_fact_order;

CREATE TABLE dwd.dwd_fact_order (
    order_sk      BIGINT         COMMENT '订单代理键',
    order_id      BIGINT         COMMENT '订单业务ID',
    user_sk       BIGINT         COMMENT '用户代理键（关联 dwd_dim_user.user_sk）',
    product_sk    BIGINT         COMMENT '商品代理键（关联 dwd_dim_product.product_sk）',
    order_amount  DECIMAL(10,2)  COMMENT '订单金额',
    order_status  TINYINT        COMMENT '订单状态: 1待支付 2已支付 3已发货 4已完成 5已取消',
    create_time   TIMESTAMP      COMMENT '订单创建时间（已清洗为时间类型）',
    update_time   TIMESTAMP      COMMENT '订单更新时间'
)
COMMENT '订单事实表 — DWD层（星型模型核心）'
PARTITIONED BY (dt STRING COMMENT '数据日期分区')
STORED AS ORC
TBLPROPERTIES ('orc.compress'='SNAPPY');
