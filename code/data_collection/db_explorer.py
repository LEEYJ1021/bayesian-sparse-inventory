#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
KAMIS/aT MySQL Database Explorer
데이터베이스 구조, 데이터 내용, 통계 및 탐색 기능 제공
"""

import pandas as pd
from sqlalchemy import create_engine, text, inspect
from urllib.parse import quote_plus
from tabulate import tabulate

def setup_database_connection():
    password = quote_plus("new_password_123")
    engine = create_engine(
        f"mysql+pymysql://remote_user:{password}@172.10.12.63:3306/agri_market_analytics?charset=utf8mb4",
        echo=False, pool_recycle=3600, pool_pre_ping=True
    )
    return engine

def analyze_database_schema(engine):
    """데이터베이스 스키마 분석"""
    print("=" * 80)
    print("📊 DATABASE SCHEMA ANALYSIS")
    print("=" * 80)
    
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    
    dim_tables = [t for t in tables if t.startswith('dim_')]
    fact_tables = [t for t in tables if t.startswith('fact_')]
    raw_tables = [t for t in tables if t.startswith('raw_')]
    
    print(f"\n📋 Total Tables: {len(tables)}")
    print(f"📈 Dimension Tables ({len(dim_tables)}): {', '.join(sorted(dim_tables))}")
    print(f"📊 Fact Tables ({len(fact_tables)}): {', '.join(sorted(fact_tables))}")
    print(f"📁 Raw Tables ({len(raw_tables)}): {', '.join(sorted(raw_tables))}")
    
    return tables, dim_tables, fact_tables, raw_tables, inspector

def analyze_business_insights(engine):
    """비즈니스 인사이트 분석"""
    print("\n" + "="*80)
    print("💡 BUSINESS INSIGHTS ANALYSIS")
    print("="*80)
    
    insight_queries = [
        ("Top 10 Most Traded Items", """
            SELECT i.item_nm, COUNT(*) as count, 
                   ROUND(AVG(f.exmn_dd_prc), 0) as avg_price
            FROM fact_price_daily_retail f
            JOIN dim_item i ON f.item_id = i.item_id
            WHERE f.exmn_dd_prc IS NOT NULL
            GROUP BY i.item_id, i.item_nm
            ORDER BY count DESC LIMIT 10
        """),
    ]
    
    with engine.connect() as conn:
        for title, query in insight_queries:
            print(f"\n📊 {title}:")
            result = conn.execute(text(query)).fetchall()
            if result:
                headers = result[0]._fields if hasattr(result[0], '_fields') else None
                rows = [[str(val) for val in row] for row in result]
                print(tabulate(rows, headers=headers, tablefmt='grid'))

def main():
    print("🚀 KAMIS/aT MySQL Database Explorer")
    engine = setup_database_connection()
    
    try:
        tables, dim_tables, fact_tables, raw_tables, inspector = analyze_database_schema(engine)
        analyze_business_insights(engine)
        print("\n✅ Database exploration finished successfully!")
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        engine.dispose()

if __name__ == "__main__":
    main()