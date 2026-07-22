"""FastAPIとの境界。

画面モックではローカル結果を返し、本番ではこのクラスだけをHTTP実装へ
差し替えることでStreamlitの画面ロジックを維持できます。
"""

from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class ApiSettings:
    base_url: str = os.getenv("FASTAPI_BASE_URL", "http://fastapi:8000")
    mock_mode: bool = os.getenv("MOCK_MODE", "true").lower() == "true"
    timeout_seconds: int = 60


class WorkAssistApi:
    def __init__(self, settings: ApiSettings | None = None) -> None:
        self.settings = settings or ApiSettings()

    def processing_pipeline(self) -> str:
        return "Azure AI Document Intelligence → Azure OpenAI"

    def health_label(self) -> str:
        return "モック接続" if self.settings.mock_mode else self.settings.base_url
