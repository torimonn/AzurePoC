"""認証方式の切替口。

本番では資格情報をStreamlitに保持せず、FastAPIまたは認証プロキシへ委譲します。
このファイルの暫定認証は、閉域PoC用の動作モックです。
"""

from __future__ import annotations

import hashlib
import hmac
import os
from dataclasses import dataclass


@dataclass(frozen=True)
class User:
    employee_no: str
    display_name: str
    department: str
    auth_source: str


@dataclass(frozen=True)
class AuthResult:
    ok: bool
    user: User | None = None
    message: str = ""


AUTH_LABELS = {
    "temporary": "暫定職員番号認証",
    "onprem": "オンプレミスAD認証",
    "hybrid": "ハイブリッド認証",
    "entra": "Microsoft Entra ID認証",
}


def auth_mode() -> str:
    mode = os.getenv("AUTH_MODE", "temporary").lower().strip()
    return mode if mode in AUTH_LABELS else "temporary"


def authenticate(employee_no: str, login_code: str) -> AuthResult:
    """PoC用の暫定職員番号認証。

    AUTH_MODEを切り替えた場合は、FastAPI側の各認証エンドポイントへ
    置換する想定です。履歴キーは常にemployee_noを維持します。
    """
    mode = auth_mode()
    if mode != "temporary":
        return AuthResult(
            False,
            message=f"{AUTH_LABELS[mode]}はFastAPI側の接続設定後に利用できます。",
        )

    employee_no = "".join(c for c in employee_no if c.isdigit())
    if not (4 <= len(employee_no) <= 10):
        return AuthResult(False, message="職員番号を4〜10桁の数字で入力してください。")

    expected = os.getenv("TEMP_LOGIN_CODE")
    if not expected:
        return AuthResult(
            False,
            message="暫定ログインコードが設定されていません。管理者へ確認してください。",
        )

    if not hmac.compare_digest(
        hashlib.sha256(login_code.encode()).digest(),
        hashlib.sha256(expected.encode()).digest(),
    ):
        return AuthResult(False, message="ログインコードが違います。")

    return AuthResult(
        True,
        user=User(
            employee_no=employee_no,
            display_name="浜松 太郎",
            department="本店営業部",
            auth_source="temporary",
        ),
    )
