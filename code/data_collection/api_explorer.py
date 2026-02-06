#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
KAMIS / aT 공공데이터 API 11종 종합 탐색기
- 컬럼 수집, 타입 추정, 범위/결측/고유값 요약
- JSON/XML 자동 파싱
- 페이지네이션 자동 처리
"""

import os
import re
import json
import time
from typing import Any, Dict, List, Tuple, Optional

import requests
import pandas as pd
from xml.etree import ElementTree as ET

# ========== 사용자 설정 ==========
SERVICE_KEY = os.getenv(
    "DATA_GO_KR_KEY",
    "c959b1074b16a04fc9221af9189eefc623ecf05912b2680e78ab33736068f5e6",
)
TIMEOUT = 30
SLEEP_SEC = 0.2
NUM_OF_ROWS = 100
MAX_PAGES = 50
RETURN_TYPE = "JSON"

DEFAULT_DATE_GTE = "20250101"
DEFAULT_DATE_LTE = "20251231"
DEFAULT_YM_GTE = "202501"
DEFAULT_YM_LTE = "202512"

# ========== 엔드포인트 정의 ==========
APIS = [
    {
        "name": "perDay_price",
        "base": "https://apis.data.go.kr/B552845/perDay/price",
        "params": {
            "cond[exmn_ymd::GTE]": DEFAULT_DATE_GTE,
            "cond[exmn_ymd::LTE]": DEFAULT_DATE_LTE,
        },
    },
    {
        "name": "ecoFriendly_price",
        "base": "https://apis.data.go.kr/B552845/ecoFriendly/price",
        "params": {
            "cond[exmn_ymd::GTE]": DEFAULT_DATE_GTE,
            "cond[exmn_ymd::LTE]": DEFAULT_DATE_LTE,
        },
    },
    {"name": "recent_price", "base": "https://apis.data.go.kr/B552845/recent/price", "params": {}},
    {
        "name": "perYearMonth_price",
        "base": "https://apis.data.go.kr/B552845/perYearMonth/price",
        "params": {
            "cond[exmn_ym::GTE]": DEFAULT_YM_GTE,
            "cond[exmn_ym::LTE]": DEFAULT_YM_LTE,
        },
    },
    {
        "name": "perRegion_price",
        "base": "https://apis.data.go.kr/B552845/perRegion/price",
        "params": {
            "cond[exmn_ymd::GTE]": DEFAULT_DATE_GTE,
            "cond[exmn_ymd::LTE]": DEFAULT_DATE_LTE,
        },
    },
    {
        "name": "priceSequel_info",
        "base": "https://apis.data.go.kr/B552845/priceSequel/info",
        "params": {"cond[exmn_ymd::EQ]": DEFAULT_DATE_LTE},
    },
    {
        "name": "risesAndFalls_info",
        "base": "https://apis.data.go.kr/B552845/risesAndFalls/info",
        "params": {"cond[exmn_ymd::EQ]": DEFAULT_DATE_LTE},
    },
    {
        "name": "periodRetail_price",
        "base": "https://apis.data.go.kr/B552845/periodRetail/price",
        "params": {
            "cond[exmn_ymd::GTE]": DEFAULT_DATE_GTE,
            "cond[exmn_ymd::LTE]": DEFAULT_DATE_LTE,
        },
    },
    {
        "name": "shipmentSequel_info",
        "base": "https://apis.data.go.kr/B552845/shipmentSequel/info",
        "params": {"cond[spmt_ymd::EQ]": DEFAULT_DATE_LTE},
    },
    {
        "name": "periodWholesale_price",
        "base": "https://apis.data.go.kr/B552845/periodWholesale/price",
        "params": {
            "cond[exmn_ymd::GTE]": DEFAULT_DATE_GTE,
            "cond[exmn_ymd::LTE]": DEFAULT_DATE_LTE,
        },
    },
    {
        "name": "listingException_dealings",
        "base": "https://apis.data.go.kr/B552845/listingException/dealings",
        "params": {"cond[clcln_ymd::EQ]": DEFAULT_DATE_LTE},
    },
]


# ========== 유틸 ==========
def is_json_response(text: str, content_type: str) -> bool:
    if content_type and "json" in content_type.lower():
        return True
    t = (text or "").strip()
    return t.startswith("{") or t.startswith("[")


def parse_xml_items(xml_text: str) -> List[Dict[str, Any]]:
    root = ET.fromstring(xml_text)
    items: List[Dict[str, Any]] = []
    for item in root.findall(".//item"):
        row: Dict[str, Any] = {}
        for child in item:
            row[child.tag] = child.text
        if row:
            items.append(row)
    return items


def _normalize_items(obj: Any) -> List[Dict[str, Any]]:
    if obj is None:
        return []
    if isinstance(obj, list):
        out = []
        for x in obj:
            if isinstance(x, dict):
                out.append(x)
            else:
                out.append({"value": x})
        return out
    if isinstance(obj, dict):
        if "item" in obj:
            return _normalize_items(obj.get("item"))
        return [obj]
    return [{"value": obj}]


def extract_items(resp_text: str, content_type: str) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
    if is_json_response(resp_text, content_type):
        data = json.loads(resp_text)
        items_obj = None
        if isinstance(data, dict) and "response" in data:
            body = (data.get("response") or {}).get("body") or {}
            items_obj = body.get("items")
        elif isinstance(data, dict) and "items" in data:
            items_obj = data.get("items")
        else:
            items_obj = data
        items = _normalize_items(items_obj)
        return items, data
    items = parse_xml_items(resp_text)
    return items, {}


def _extract_total_count(meta: Dict[str, Any]) -> Optional[int]:
    try:
        body = (meta.get("response") or {}).get("body") or {}
        tc = body.get("totalCount")
        return int(tc) if tc is not None else None
    except Exception:
        return None


def request_page(url: str, params: Dict[str, Any]) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
    r = requests.get(url, params=params, timeout=TIMEOUT)
    r.raise_for_status()
    items, meta = extract_items(r.text, r.headers.get("Content-Type", ""))
    return items, meta


def paginate(url: str, base_params: Dict[str, Any]) -> List[Dict[str, Any]]:
    all_items: List[Dict[str, Any]] = []
    page = 1

    while page <= MAX_PAGES:
        params = dict(base_params)
        params["pageNo"] = page
        params["numOfRows"] = NUM_OF_ROWS
        params["serviceKey"] = SERVICE_KEY
        params["returnType"] = RETURN_TYPE

        items, meta = request_page(url, params)
        if not items:
            break

        all_items.extend(items)

        total_count = _extract_total_count(meta)
        if total_count is not None and len(all_items) >= total_count:
            break

        if len(items) < NUM_OF_ROWS:
            break

        page += 1
        time.sleep(SLEEP_SEC)

    return all_items


def infer_type(series: pd.Series) -> str:
    s = series.dropna().astype(str).str.strip()
    s = s[s != ""]
    if s.empty:
        return "unknown"

    def is_number(x: str) -> bool:
        return re.fullmatch(r"-?\d+(\.\d+)?", x) is not None

    def is_date(x: str) -> bool:
        return (
            re.fullmatch(r"\d{8}", x) is not None
            or re.fullmatch(r"\d{6}", x) is not None
            or re.fullmatch(r"\d{4}-\d{2}-\d{2}", x) is not None
        )

    num_ratio = s.map(is_number).astype("float").mean()
    date_ratio = s.map(is_date).astype("float").mean()

    if date_ratio >= 0.9:
        return "date"
    if num_ratio >= 0.9:
        int_ratio = s.map(lambda x: re.fullmatch(r"-?\d+", x) is not None).astype("float").mean()
        return "int" if int_ratio >= 0.9 else "float"
    return "string"


def summarize_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    summary_rows: List[Dict[str, Any]] = []

    for col in df.columns:
        ser = df[col]
        inferred = infer_type(ser)

        nonnull = ser.dropna()
        missing_rate = 1.0 - (len(nonnull) / len(df) if len(df) else 0.0)
        nunique = nonnull.astype(str).nunique() if len(nonnull) else 0

        minv = maxv = None
        if inferred in ("int", "float"):
            nums = pd.to_numeric(nonnull, errors="coerce").dropna()
            if not nums.empty:
                minv, maxv = float(nums.min()), float(nums.max())
        elif inferred == "date":
            vals = nonnull.astype(str).str.strip()
            vals = vals[vals != ""]
            if not vals.empty:
                minv, maxv = vals.min(), vals.max()
        else:
            vals = nonnull.astype(str)
            if not vals.empty:
                lengths = vals.map(len)
                minv, maxv = int(lengths.min()), int(lengths.max())

        summary_rows.append(
            {
                "column": col,
                "inferred_type": inferred,
                "missing_rate": round(missing_rate, 4),
                "nunique": int(nunique),
                "min": minv,
                "max": maxv,
            }
        )

    return pd.DataFrame(summary_rows).sort_values("column").reset_index(drop=True)


# ========== 실행 ==========
def main():
    os.makedirs("output", exist_ok=True)
    all_summaries: List[pd.DataFrame] = []

    for api in APIS:
        name = api["name"]
        url = api["base"]
        params = api.get("params", {})

        print(f"\n=== Fetching: {name} ===")
        items = paginate(url, params)
        print(f"Rows fetched: {len(items)}")

        if not items:
            print("No data.")
            continue

        df = pd.DataFrame(items)
        df.to_csv(f"output/{name}_data.csv", index=False, encoding="utf-8-sig")

        summary = summarize_dataframe(df)
        summary.to_csv(f"output/{name}_schema_summary.csv", index=False, encoding="utf-8-sig")

        df.head(10).to_csv(f"output/{name}_sample.csv", index=False, encoding="utf-8-sig")

        print(summary)

        summary_with_api = summary.copy()
        summary_with_api["api_name"] = name
        all_summaries.append(summary_with_api)

    if all_summaries:
        all_df = pd.concat(all_summaries, ignore_index=True)
        all_df.to_csv("output/_all_schema_summary.csv", index=False, encoding="utf-8-sig")
        print("\nSaved: output/_all_schema_summary.csv")


if __name__ == "__main__":
    main()