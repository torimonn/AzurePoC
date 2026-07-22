"""事業性評価データを確認用Excelブックへ書き込む。"""

from __future__ import annotations

from io import BytesIO
from typing import Any

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.worksheet import Worksheet

NAVY = "16324F"
BLUE = "0B5CAB"
LIGHT_BLUE = "EAF3F8"
YELLOW = "FFD43B"
LIGHT_YELLOW = "FFF8D6"
WHITE = "FFFFFF"
GRID = "B8C8D6"


def _title(ws: Worksheet, text: str, last_column: int) -> None:
    ws.merge_cells(start_row=1, start_column=1, end_row=1, end_column=last_column)
    cell = ws.cell(1, 1, text)
    cell.font = Font(color=WHITE, bold=True, size=16)
    cell.fill = PatternFill("solid", fgColor=NAVY)
    cell.alignment = Alignment(horizontal="center", vertical="center")
    ws.row_dimensions[1].height = 32


def _write_table(
    ws: Worksheet,
    headers: list[str],
    rows: list[list[Any]],
    widths: list[int],
    *,
    header_row: int = 3,
) -> None:
    thin = Side(style="thin", color=GRID)
    for column, value in enumerate(headers, 1):
        cell = ws.cell(header_row, column, value)
        cell.font = Font(bold=True, color=WHITE)
        cell.fill = PatternFill("solid", fgColor=BLUE)
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = Border(left=thin, right=thin, top=thin, bottom=thin)

    for row_number, values in enumerate(rows, header_row + 1):
        for column, value in enumerate(values, 1):
            cell = ws.cell(row_number, column, value)
            cell.fill = PatternFill("solid", fgColor=LIGHT_BLUE if row_number % 2 == 0 else WHITE)
            cell.border = Border(left=thin, right=thin, top=thin, bottom=thin)
            cell.alignment = Alignment(vertical="top", wrap_text=True)
        status_cell = ws.cell(row_number, len(headers))
        status_cell.fill = PatternFill("solid", fgColor=LIGHT_YELLOW)
        status_cell.alignment = Alignment(horizontal="center", vertical="center")

    for index, width in enumerate(widths, 1):
        ws.column_dimensions[get_column_letter(index)].width = width
    ws.freeze_panes = f"A{header_row + 1}"
    if rows:
        ws.auto_filter.ref = f"A{header_row}:{get_column_letter(len(headers))}{header_row + len(rows)}"
    ws.sheet_view.showGridLines = False
    ws.page_setup.orientation = "landscape"
    ws.page_setup.fitToWidth = 1
    ws.sheet_properties.pageSetUpPr.fitToPage = True


def _summary_text(data: dict[str, Any], category: str) -> str:
    if category == "顧客属性":
        customer = data["customer_attributes"]
        return f"{customer.get('企業名', '')} / {customer.get('業種', '')}"
    if category == "財務分析":
        rows = data["financial_analysis"]
        return " / ".join(str(row.get("AI評価", "")) for row in rows[:2])
    if category == "取引先":
        return f"主要な販売先・仕入先 {len(data['trading_partners'])}先を確認"
    if category == "SWOT分析":
        swot = data["swot_analysis"]
        return f"強み: {swot.get('強み', {}).get('内容', '')} / 脅威: {swot.get('脅威', {}).get('内容', '')}"
    high_priority = [
        row.get("事業課題", "")
        for row in data["business_challenges"]
        if row.get("優先度") == "高"
    ]
    return " / ".join(high_priority)


def _build_summary_sheet(
    ws: Worksheet,
    data: dict[str, Any],
    source_documents: list[str],
) -> None:
    _title(ws, "事業性評価シート", 6)
    metadata = [
        ("作成状態", "要職員確認"),
        ("読取エンジン", "Azure AI Document Intelligence"),
        ("整形・分析エンジン", "Azure OpenAI"),
        ("対象企業", data["customer_attributes"].get("企業名", "")),
        ("評価基準日", data["customer_attributes"].get("評価基準日", "")),
    ]
    for row_number, (label, value) in enumerate(metadata, 3):
        ws.cell(row_number, 1, label).font = Font(bold=True, color=NAVY)
        ws.cell(row_number, 2, value)
    ws["B3"].fill = PatternFill("solid", fgColor=YELLOW)
    ws["B3"].font = Font(bold=True, color=NAVY)

    source_header_row = 9
    ws.cell(source_header_row, 1, "入力資料").font = Font(bold=True, color=NAVY, size=12)
    for index, filename in enumerate(source_documents, source_header_row + 1):
        ws.cell(index, 1, f"{index - source_header_row}. {filename}")

    evaluation_header_row = source_header_row + len(source_documents) + 2
    ws.cell(evaluation_header_row, 1, "評価領域").font = Font(bold=True, color=WHITE)
    ws.cell(evaluation_header_row, 1).fill = PatternFill("solid", fgColor=BLUE)
    ws.merge_cells(
        start_row=evaluation_header_row,
        start_column=2,
        end_row=evaluation_header_row,
        end_column=5,
    )
    ws.cell(evaluation_header_row, 2, "AI整理結果の概要").font = Font(bold=True, color=WHITE)
    ws.cell(evaluation_header_row, 2).fill = PatternFill("solid", fgColor=BLUE)
    ws.cell(evaluation_header_row, 6, "職員確認").font = Font(bold=True, color=WHITE)
    ws.cell(evaluation_header_row, 6).fill = PatternFill("solid", fgColor=BLUE)

    thin = Side(style="thin", color=GRID)
    categories = ["顧客属性", "財務分析", "取引先", "SWOT分析", "事業課題"]
    for row_number, category in enumerate(categories, evaluation_header_row + 1):
        ws.cell(row_number, 1, category)
        ws.merge_cells(start_row=row_number, start_column=2, end_row=row_number, end_column=5)
        ws.cell(row_number, 2, _summary_text(data, category))
        ws.cell(row_number, 6, "要確認")
        for column in range(1, 7):
            cell = ws.cell(row_number, column)
            cell.border = Border(left=thin, right=thin, top=thin, bottom=thin)
            cell.alignment = Alignment(vertical="top", wrap_text=True)
            cell.fill = PatternFill("solid", fgColor=LIGHT_BLUE if row_number % 2 == 0 else WHITE)
        ws.cell(row_number, 6).fill = PatternFill("solid", fgColor=LIGHT_YELLOW)
        ws.cell(row_number, 6).alignment = Alignment(horizontal="center", vertical="center")
        ws.row_dimensions[row_number].height = 46

    warning_row = evaluation_header_row + len(categories) + 2
    ws.merge_cells(start_row=warning_row, start_column=1, end_row=warning_row, end_column=6)
    ws.cell(
        warning_row,
        1,
        "注意: AIの抽出・分析結果は参考情報です。原資料と照合し、担当職員が確認・修正してから利用してください。",
    )
    ws.cell(warning_row, 1).fill = PatternFill("solid", fgColor=LIGHT_YELLOW)
    ws.cell(warning_row, 1).font = Font(bold=True, color=NAVY)
    ws.cell(warning_row, 1).alignment = Alignment(wrap_text=True, vertical="center")
    ws.row_dimensions[warning_row].height = 34
    for index, width in enumerate([20, 22, 22, 22, 22, 14], 1):
        ws.column_dimensions[get_column_letter(index)].width = width
    ws.sheet_view.showGridLines = False
    ws.freeze_panes = "A3"


def build_business_evaluation_excel(
    data: dict[str, Any],
    source_documents: list[str],
) -> bytes:
    """確認前の事業性評価データを6シートのExcelブックにする。"""
    workbook = Workbook()
    summary = workbook.active
    summary.title = "評価サマリー"
    _build_summary_sheet(summary, data, source_documents)

    customer = workbook.create_sheet("顧客属性")
    _title(customer, "顧客属性", 4)
    customer_rows = [
        [key, value, "要確認", ""]
        for key, value in data["customer_attributes"].items()
    ]
    _write_table(customer, ["項目", "内容", "職員確認", "備考"], customer_rows, [22, 48, 14, 30])

    financial = workbook.create_sheet("財務分析")
    _title(financial, "財務分析", 7)
    financial_rows = [
        [
            row.get("項目", ""),
            row.get("2024年3月期", ""),
            row.get("2025年3月期", ""),
            row.get("2026年3月期", ""),
            row.get("単位", ""),
            row.get("AI評価", ""),
            "要確認",
        ]
        for row in data["financial_analysis"]
    ]
    _write_table(
        financial,
        ["項目", "2024年3月期", "2025年3月期", "2026年3月期", "単位", "AI評価", "職員確認"],
        financial_rows,
        [20, 16, 16, 16, 10, 52, 14],
    )

    partners = workbook.create_sheet("取引先")
    _title(partners, "主要な販売先・仕入先", 6)
    partner_rows = [
        [
            row.get("区分", ""),
            row.get("取引先名", ""),
            row.get("取引比率", ""),
            row.get("決済条件", ""),
            row.get("取引状況・リスク", ""),
            "要確認",
        ]
        for row in data["trading_partners"]
    ]
    _write_table(
        partners,
        ["区分", "取引先名", "取引比率", "決済条件", "取引状況・リスク", "職員確認"],
        partner_rows,
        [12, 28, 18, 24, 52, 14],
    )

    swot_sheet = workbook.create_sheet("SWOT分析")
    _title(swot_sheet, "SWOT分析", 4)
    swot_rows = [
        [category, values.get("内容", ""), values.get("評価根拠", ""), "要確認"]
        for category, values in data["swot_analysis"].items()
    ]
    _write_table(swot_sheet, ["区分", "内容", "評価根拠", "職員確認"], swot_rows, [14, 58, 38, 14])

    challenges = workbook.create_sheet("事業課題")
    _title(challenges, "事業課題と対応方針", 7)
    challenge_rows = [
        [
            row.get("優先度", ""),
            row.get("分類", ""),
            row.get("事業課題", ""),
            row.get("現状・背景", ""),
            row.get("対応案", ""),
            row.get("KPI", ""),
            "要確認",
        ]
        for row in data["business_challenges"]
    ]
    _write_table(
        challenges,
        ["優先度", "分類", "事業課題", "現状・背景", "対応案", "KPI", "職員確認"],
        challenge_rows,
        [12, 14, 32, 45, 45, 30, 14],
    )

    stream = BytesIO()
    workbook.save(stream)
    return stream.getvalue()
