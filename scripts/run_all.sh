#!/bin/bash
# ============================================================
# 数仓 ETL 全链路执行脚本
#
# 用法:
#   bash run_all.sh                    # 默认处理昨天的数据
#   bash run_all.sh 2026-07-26         # 处理指定日期的数据
#   bash run_all.sh all                # 首次全量加载（所有历史数据）
#
# 前置条件:
#   1. docker-compose up -d 已启动集群
#   2. data/ 目录下有 biz_*.csv 数据文件
#   3. HDFS 已创建相应目录
# ============================================================

set -e  # 遇到错误立即退出

# ==================== 配置 ====================
HIVE_JDBC="jdbc:hive2://localhost:10000"
SQL_DIR="/opt/sql"
DATA_DIR="/opt/data"
HDFS_DATA="/user/data"

# 数据日期：默认昨天
DT="${1:-$(date -d 'yesterday' +%Y-%m-%d)}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==================== 辅助函数 ====================
log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "\n${BLUE}========================================${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}========================================${NC}"; }

run_hive_sql() {
    # 执行 Hive SQL 文件，自动替换 ${dt} 变量
    local sql_file="$1"
    local display_name="${2:-$sql_file}"

    log_info "执行: $display_name"
    docker exec hive-server beeline \
        -u "$HIVE_JDBC" \
        --hivevar dt="$DT" \
        -f "$SQL_DIR/$sql_file" 2>&1 | tail -10

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        log_error "执行失败: $display_name"
        return 1
    fi
    log_info "✓ 完成: $display_name"
}

# ==================== 主流程 ====================
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║       数仓 ETL 全链路自动化脚本                      ║"
echo "║       数据日期: $DT                                  ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ====== Step 1: 检查集群状态 ======
log_step "Step 1/8: 检查集群状态"
if ! docker ps --format '{{.Names}}' | grep -q "hive-server"; then
    log_error "Hive 集群未启动，请先执行: docker-compose up -d"
    exit 1
fi
log_info "集群运行正常"
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E "namenode|hive-server|hive-metastore"

# ====== Step 2: 数据准备 ======
log_step "Step 2/8: 生成模拟数据"
if [ ! -f "$DATA_DIR/biz_order.csv" ]; then
    log_warn "未找到数据文件，正在生成..."
    python3 /opt/scripts/generate_mock_data.py --output "$DATA_DIR"
fi
log_info "数据文件检查通过"
ls -lh "$DATA_DIR"/*.csv 2>/dev/null || log_warn "无 CSV 文件"

# ====== Step 3: 上传 HDFS ======
log_step "Step 3/8: 上传数据到 HDFS"
docker exec namenode hdfs dfs -mkdir -p "$HDFS_DATA" 2>/dev/null || true

for csv_file in "$DATA_DIR"/*.csv; do
    filename=$(basename "$csv_file")
    log_info "上传: $filename"
    docker cp "$csv_file" namenode:"/tmp/$filename" 2>/dev/null || true
    docker exec namenode hdfs dfs -put -f "/tmp/$filename" "$HDFS_DATA/$filename" 2>/dev/null || true
done
log_info "✓ HDFS 数据上传完成"
docker exec namenode hdfs dfs -ls "$HDFS_DATA" 2>/dev/null

# ====== Step 4: ODS 层 ======
log_step "Step 4/8: ODS 贴源层建表"
run_hive_sql "ods/ods_category.sql"  "ODS-商品分类"
run_hive_sql "ods/ods_user.sql"      "ODS-用户"
run_hive_sql "ods/ods_product.sql"   "ODS-商品"
run_hive_sql "ods/ods_order.sql"     "ODS-订单"

# ====== Step 5: DWD 层 - 维度表 ======
log_step "Step 5/8: DWD 明细层 — 维度表建表"
run_hive_sql "dwd/dwd_dim_category.sql" "DWD-DIM-分类"
run_hive_sql "dwd/dwd_dim_user.sql"     "DWD-DIM-用户"
run_hive_sql "dwd/dwd_dim_product.sql"  "DWD-DIM-商品"

# ====== Step 6: DWD 层 - ETL ======
log_step "Step 6/8: DWD 明细层 — ETL 数据加载"
run_hive_sql "dwd/etl_dim_category.sql" "ETL-分类维度"
run_hive_sql "dwd/etl_dim_user.sql"     "ETL-用户维度(SCD2)"
run_hive_sql "dwd/etl_dim_product.sql"  "ETL-商品维度(SCD2)"

# 事实表依赖维度表，放在后面
run_hive_sql "dwd/dwd_fact_order.sql"   "DWD-FACT-订单(DDL)"
run_hive_sql "dwd/etl_fact_order.sql"   "ETL-订单事实表"

# ====== Step 7: DWS 层 ======
log_step "Step 7/8: DWS 汇总层"
run_hive_sql "dws/dws_user_daily_summary.sql"    "DWS-用户日活汇总"
run_hive_sql "dws/dws_product_daily_sales.sql"   "DWS-商品日销量汇总"

# ====== Step 8: ADS 层 ======
log_step "Step 8/8: ADS 应用层 — KPI 指标"
run_hive_sql "ads/ads_daily_kpi.sql"  "ADS-每日KPI"

# ====== 完成 ======
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ✓  全链路 ETL 执行完成!                            ║"
echo "║  数据日期: $DT                                      ║"
echo "║  查看结果: docker exec hive-server beeline          ║"
echo "║           -u jdbc:hive2://localhost:10000           ║"
echo "║           -e 'SELECT * FROM ads.ads_daily_kpi;'     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# 快速验证
log_info "快速验证各层数据量..."
docker exec hive-server beeline -u "$HIVE_JDBC" --outputformat=csv2 \
    -e "
    SELECT 'ODS-订单', COUNT(*) FROM ods.ods_order WHERE dt='$DT'
    UNION ALL
    SELECT 'DWD-订单事实', COUNT(*) FROM dwd.dwd_fact_order WHERE dt='$DT'
    UNION ALL
    SELECT 'DWS-用户汇总', COUNT(*) FROM dws.dws_user_daily_summary WHERE dt='$DT'
    UNION ALL
    SELECT 'ADS-KPI', COUNT(*) FROM ads.ads_daily_kpi WHERE dt='$DT';
    " 2>&1
