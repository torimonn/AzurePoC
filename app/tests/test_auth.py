from __future__ import annotations

import os
import unittest
from unittest.mock import patch

from services.auth import authenticate


class AuthenticateTest(unittest.TestCase):
    def test_accepts_matching_temporary_code(self) -> None:
        with patch.dict(
            os.environ,
            {"AUTH_MODE": "temporary", "TEMP_LOGIN_CODE": "local-only-code"},
            clear=True,
        ):
            result = authenticate("123456", "local-only-code")

        self.assertTrue(result.ok)
        self.assertEqual(result.user.employee_no, "123456")

    def test_rejects_missing_temporary_code_configuration(self) -> None:
        with patch.dict(os.environ, {"AUTH_MODE": "temporary"}, clear=True):
            result = authenticate("123456", "anything")

        self.assertFalse(result.ok)
        self.assertIn("設定されていません", result.message)

    def test_rejects_non_numeric_employee_number(self) -> None:
        with patch.dict(
            os.environ,
            {"AUTH_MODE": "temporary", "TEMP_LOGIN_CODE": "local-only-code"},
            clear=True,
        ):
            result = authenticate("abc", "local-only-code")

        self.assertFalse(result.ok)

    def test_defers_non_temporary_authentication(self) -> None:
        with patch.dict(os.environ, {"AUTH_MODE": "entra"}, clear=True):
            result = authenticate("123456", "unused")

        self.assertFalse(result.ok)
        self.assertIn("FastAPI", result.message)


if __name__ == "__main__":
    unittest.main()
