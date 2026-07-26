#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
电商模拟数据生成器
===================
生成四张业务表的 CSV 数据，供数仓 ETL 使用。

输出文件（输出到 data/ 目录）：
  - biz_user.csv       用户表（~10000条）
  - biz_category.csv   商品分类表（~50条）
  - biz_product.csv    商品表（~5000条）
  - biz_order.csv      订单表（~100000条）

用法：
  python3 generate_mock_data.py
  python3 generate_mock_data.py --users 50000 --orders 500000  # 自定义数量
"""

import csv
import os
import random
import argparse
from datetime import datetime, timedelta

# ==================== 配置 ====================
# 中文数据集
CITIES = [
    ("北京", "北京市"), ("上海", "上海市"), ("广州", "广东省"),
    ("深圳", "广东省"), ("杭州", "浙江省"), ("成都", "四川省"),
    ("武汉", "湖北省"), ("南京", "江苏省"), ("西安", "陕西省"),
    ("重庆", "重庆市"), ("长沙", "湖南省"), ("郑州", "河南省"),
    ("苏州", "江苏省"), ("天津", "天津市"), ("东莞", "广东省"),
    ("青岛", "山东省"), ("厦门", "福建省"), ("合肥", "安徽省"),
]

BRANDS = [
    "Apple", "华为", "小米", "OPPO", "vivo", "三星",
    "Nike", "Adidas", "安踏", "李宁", "优衣库", "ZARA",
    "良品铺子", "三只松鼠", "百草味", "来伊份",
    "宜家", "无印良品", "名创优品", "网易严选",
    "兰蔻", "雅诗兰黛", "欧莱雅", "珀莱雅",
    "海尔", "美的", "格力", "戴森",
]

CATEGORY_TREE = {
    "电子产品": {
        "手机通讯": None,
        "电脑办公": None,
        "智能穿戴": None,
        "摄影摄像": None,
    },
    "服装鞋帽": {
        "男装": None,
        "女装": None,
        "运动户外": None,
        "内衣配饰": None,
    },
    "食品饮料": {
        "休闲零食": None,
        "饮料冲调": None,
        "生鲜水果": None,
        "粮油调味": None,
    },
    "家居用品": {
        "家纺布艺": None,
        "厨房用具": None,
        "收纳整理": None,
        "灯具照明": None,
    },
    "图书音像": {
        "小说文学": None,
        "教育考试": None,
        "少儿读物": None,
        "人文社科": None,
    },
    "美妆个护": {
        "面部护肤": None,
        "彩妆香水": None,
        "身体护理": None,
        "口腔护理": None,
    },
}

PRODUCT_NAMES = {
    "手机通讯": ["智能手机A", "智能手机B", "折叠屏手机", "游戏手机", "老年手机"],
    "电脑办公": ["轻薄笔记本", "游戏笔记本", "平板电脑", "机械键盘", "无线鼠标"],
    "智能穿戴": ["智能手表", "运动手环", "无线耳机", "智能眼镜"],
    "摄影摄像": ["微单相机", "运动相机", "无人机", "三脚架"],
    "男装": ["纯棉T恤", "休闲衬衫", "牛仔裤", "羽绒服", "运动长裤"],
    "女装": ["连衣裙", "针织开衫", "半身裙", "阔腿裤", "雪纺衫"],
    "运动户外": ["跑步鞋", "篮球鞋", "瑜伽垫", "登山包", "冲锋衣"],
    "内衣配饰": ["棉袜套装", "鸭舌帽", "围巾", "腰带", "太阳镜"],
    "休闲零食": ["坚果礼盒", "薯片大包", "肉脯干", "夹心饼干", "巧克力"],
    "饮料冲调": ["速溶咖啡", "柠檬茶", "豆浆粉", "蛋白粉", "枸杞茶"],
    "生鲜水果": ["苹果礼盒", "车厘子", "牛油果", "草莓", "蓝莓"],
    "粮油调味": ["橄榄油", "生抽酱油", "五常大米", "火锅底料", "芝麻酱"],
    "家纺布艺": ["四件套", "记忆枕", "夏凉被", "床垫保护罩", "沙发垫"],
    "厨房用具": ["不粘锅", "料理机", "保温杯", "砧板套装", "调料瓶"],
    "收纳整理": ["收纳箱", "衣架套装", "鞋盒", "真空压缩袋", "化妆品收纳盒"],
    "灯具照明": ["LED台灯", "氛围灯带", "吸顶灯", "小夜灯", "落地灯"],
    "小说文学": ["长篇小说", "短篇集", "科幻小说", "悬疑推理", "武侠小说"],
    "教育考试": ["考研英语", "行测题库", "CPA教材", "雅思真题", "高考必刷题"],
    "少儿读物": ["绘本套装", "科普百科", "儿童文学", "拼图书", "启蒙卡片"],
    "人文社科": ["历史入门", "哲学简史", "经济学原理", "心理学入门", "社会学导论"],
    "面部护肤": ["保湿面霜", "精华液", "防晒霜", "洗面奶", "面膜套装"],
    "彩妆香水": ["口红", "粉底液", "眼影盘", "淡香水", "卸妆油"],
    "身体护理": ["沐浴露", "身体乳", "护手霜", "磨砂膏", "止汗露"],
    "口腔护理": ["电动牙刷", "牙膏套装", "牙线", "漱口水", "美白牙贴"],
}


def parse_args():
    parser = argparse.ArgumentParser(description="电商模拟数据生成器")
    parser.add_argument("--users", type=int, default=10000, help="用户数量")
    parser.add_argument("--products", type=int, default=5000, help="商品数量")
    parser.add_argument("--orders", type=int, default=100000, help="订单数量")
    parser.add_argument("--output", type=str, default="../data", help="输出目录")
    return parser.parse_args()


def ensure_output_dir(path):
    os.makedirs(path, exist_ok=True)


def flatten_categories():
    """将分类树展开为 (category_id, category_name, parent_id) 列表"""
    cats = []
    cat_id = 1
    parent_map = {}
    for parent_name, children in CATEGORY_TREE.items():
        parent_map[parent_name] = cat_id
        cats.append((cat_id, parent_name, 0))
        cat_id += 1
        for child_name in children:
            cats.append((cat_id, child_name, parent_map[parent_name]))
            cat_id += 1
    return cats


def get_brand_for_category(cat_name):
    """根据分类映射合适品牌"""
    brand_map = {
        "手机通讯": ["Apple", "华为", "小米", "OPPO", "vivo", "三星"],
        "电脑办公": ["Apple", "华为", "小米", "戴尔", "联想"],
        "智能穿戴": ["Apple", "华为", "小米", "OPPO"],
        "摄影摄像": ["佳能", "索尼", "尼康", "大疆"],
        "男装": ["Nike", "Adidas", "优衣库", "ZARA", "海澜之家"],
        "女装": ["优衣库", "ZARA", "UR", "太平鸟", "伊芙丽"],
        "运动户外": ["Nike", "Adidas", "安踏", "李宁", "迪卡侬"],
        "休闲零食": ["良品铺子", "三只松鼠", "百草味", "来伊份"],
        "饮料冲调": ["雀巢", "星巴克", "立顿", "蒙牛"],
        "面部护肤": ["兰蔻", "雅诗兰黛", "欧莱雅", "珀莱雅", "SK-II"],
        "彩妆香水": ["MAC", "YSL", "迪奥", "完美日记", "花西子"],
        "家纺布艺": ["宜家", "无印良品", "网易严选", "水星家纺"],
        "厨房用具": ["苏泊尔", "双立人", "美的", "九阳"],
    }
    return random.choice(brand_map.get(cat_name, BRANDS))


def generate_users(count):
    """生成用户数据"""
    rows = []
    for i in range(1, count + 1):
        city, province = random.choice(CITIES)
        gender = random.choices([0, 1, 2], weights=[5, 48, 47])[0]  # 0未知,1男,2女
        days_ago = random.randint(0, 1095)
        register_time = datetime.now() - timedelta(days=days_ago)
        rows.append([
            i,                                          # user_id
            f"用户{i:06d}",                              # user_name
            gender,
            city,
            province,
            register_time.strftime("%Y-%m-%d %H:%M:%S"),
        ])
    return rows


def generate_products(count, categories):
    """生成商品数据"""
    rows = []
    # 子分类列表（有parent的）
    leaf_cats = [(cid, cname, pid) for cid, cname, pid in categories if pid > 0]

    for i in range(1, count + 1):
        cat_id, cat_name, parent_id = random.choice(leaf_cats)
        product_name_templates = PRODUCT_NAMES.get(cat_name, ["通用商品"])
        base_name = random.choice(product_name_templates)
        product_name = f"{base_name}-{random.choice(['Pro','Max','Lite','Plus','SE',''])}{chr(65+random.randint(0,5))}"
        product_name = product_name.rstrip("-")
        brand = get_brand_for_category(cat_name)
        price = round(random.uniform(9.9, 9999), 2)

        rows.append([
            i,                  # product_id
            product_name,
            cat_id,
            price,
            brand,
        ])
    return rows


def generate_orders(count, user_count, product_count):
    """生成订单数据"""
    rows = []
    now = datetime.now()

    for i in range(1, count + 1):
        user_id = random.randint(1, user_count)
        product_id = random.randint(1, product_count)
        amount = round(random.uniform(9.9, 9999), 2)

        # 订单状态分布: 1=待支付(10%) 2=已支付(15%) 3=已发货(20%) 4=已完成(50%) 5=已取消(5%)
        status = random.choices([1, 2, 3, 4, 5], weights=[10, 15, 20, 50, 5])[0]

        # 时间在过去365天内
        days_ago = random.randint(0, 365)
        hours = random.randint(0, 23)
        minutes = random.randint(0, 59)
        seconds = random.randint(0, 59)
        create_time = now - timedelta(days=days_ago, hours=hours, minutes=minutes, seconds=seconds)
        update_time = create_time + timedelta(hours=random.randint(0, 48))

        rows.append([
            i,                      # order_id (自增，实际业务中应该是业务ID)
            user_id,
            product_id,
            amount,
            status,
            create_time.strftime("%Y-%m-%d %H:%M:%S"),
            update_time.strftime("%Y-%m-%d %H:%M:%S"),
        ])
    return rows


def write_csv(filename, headers, rows, output_dir):
    filepath = os.path.join(output_dir, filename)
    with open(filepath, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(rows)
    file_size = os.path.getsize(filepath)
    print(f"  ✓ {filename}: {len(rows):,} 条记录, {file_size/1024:.1f} KB")


def main():
    args = parse_args()
    output_dir = os.path.abspath(args.output)
    ensure_output_dir(output_dir)

    print("=" * 60)
    print("  电商模拟数据生成器")
    print("=" * 60)
    print(f"  目标: {args.users:,} 用户 | {args.products:,} 商品 | {args.orders:,} 订单")
    print(f"  输出: {output_dir}")
    print()

    # 1. 生成分类
    categories = flatten_categories()
    write_csv("biz_category.csv",
              ["category_id", "category_name", "parent_id"],
              categories, output_dir)

    # 2. 生成用户
    print("  生成用户数据...")
    users = generate_users(args.users)
    write_csv("biz_user.csv",
              ["user_id", "user_name", "gender", "city", "province", "register_time"],
              users, output_dir)

    # 3. 生成商品
    print("  生成商品数据...")
    products = generate_products(args.products, categories)
    write_csv("biz_product.csv",
              ["product_id", "product_name", "category_id", "price", "brand"],
              products, output_dir)

    # 4. 生成订单
    print("  生成订单数据...")
    orders = generate_orders(args.orders, len(users), len(products))
    write_csv("biz_order.csv",
              ["order_id", "user_id", "product_id", "order_amount", "order_status", "create_time", "update_time"],
              orders, output_dir)

    print()
    print("=" * 60)
    print("  ✓ 全部数据生成完成!")
    print("=" * 60)


if __name__ == "__main__":
    random.seed(42)  # 固定随机种子，保证每次生成的数据一致
    main()
