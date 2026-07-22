from __future__ import annotations

import unittest
from io import BytesIO

from openpyxl import load_workbook

from services.excel_service import build_business_evaluation_excel
from services.mock_data import (
    BUSINESS_CHALLENGES,
    CUSTOMER_ATTRIBUTES,
    FINANCIAL_ANALYSIS,
    SOURCE_DOCUMENTS,
    SWOT_ANALYSIS,
    TRADING_PARTNERS,
)


class BusinessEvaluationExcelTest(unittest.TestCase):
    def setUp(self) -> None:
        self.content = build_business_evaluation_excel(
            {
                "customer_attributes": CUSTOMER_ATTRIBUTES,
                "financial_analysis": FINANCIAL_ANALYSIS,
                "trading_partners": TRADING_PARTNERS,
                "swot_analysis": SWOT_ANALYSIS,
                "business_challenges": BUSINESS_CHALLENGES,
            },
            SOURCE_DOCUMENTS,
        )
        self.workbook = load_workbook(BytesIO(self.content), read_only=True)

    def test_builds_all_business_evaluation_sheets(self) -> None:
        self.assertEqual(
            self.workbook.sheetnames,
            ["評価サマリー", "顧客属性", "財務分析", "取引先", "SWOT分析", "事業課題"],
        )

    def test_records_processing_pipeline_and_source_documents(self) -> None:
        sheet = self.workbook["評価サマリー"]

        self.assertEqual(sheet["B3"].value, "要職員確認")
        self.assertEqual(sheet["B4"].value, "Azure AI Document Intelligence")
        self.assertEqual(sheet["B5"].value, "Azure OpenAI")
        self.assertEqual(sheet["A10"].value, f"1. {SOURCE_DOCUMENTS[0]}")

    def test_marks_generated_values_as_requiring_staff_review(self) -> None:
        self.assertEqual(self.workbook["顧客属性"]["C4"].value, "要確認")
        self.assertEqual(self.workbook["財務分析"]["G4"].value, "要確認")
        self.assertEqual(self.workbook["取引先"]["F4"].value, "要確認")
        self.assertEqual(self.workbook["SWOT分析"]["D4"].value, "要確認")
        self.assertEqual(self.workbook["事業課題"]["G4"].value, "要確認")

    def test_writes_customer_and_financial_values(self) -> None:
        customer = self.workbook["顧客属性"]
        financial = self.workbook["財務分析"]

        self.assertEqual(customer["A4"].value, "評価基準日")
        self.assertEqual(customer["B5"].value, "株式会社 遠州テクノ")
        self.assertEqual(financial["A4"].value, "売上高")
        self.assertEqual(financial["D4"].value, "548,000")


if __name__ == "__main__":
    unittest.main()
