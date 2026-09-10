import os
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch

from configure_jupyter import configure_jupyter


class JupyterAuthTest(unittest.TestCase):
    def read_config(self, directory):
        config = SimpleNamespace(ServerApp=SimpleNamespace(), IdentityProvider=SimpleNamespace())
        exec((directory / "jupyter_lab_config.py").read_text(), {"c": config})
        return config

    def test_empty_or_missing_token_generates_private_credential(self):
        for env in ({}, {"JUPYTER_TOKEN": ""}):
            with self.subTest(env=env), tempfile.TemporaryDirectory() as tmp:
                directory = Path(tmp)
                with patch.dict(os.environ, env, clear=True):
                    configure_jupyter(directory)
                    first = self.read_config(directory).IdentityProvider.token
                    configure_jupyter(directory)
                config = self.read_config(directory)
                self.assertGreaterEqual(len(first), 43)
                self.assertNotEqual(first, config.IdentityProvider.token)
                self.assertFalse(hasattr(config.ServerApp, "allow_origin"))
                self.assertEqual(config.IdentityProvider.token, (directory / "jupyter_token").read_text())
                for name in ("jupyter_token", "jupyter_lab_config.py"):
                    self.assertEqual((directory / name).stat().st_mode & 0o777, 0o600)

    def test_config_quotes_explicit_token_and_restricts_existing_files(self):
        token = "quotes'\"\n; c.IdentityProvider.token = '' #"
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            for name in ("jupyter_token", "jupyter_lab_config.py"):
                (directory / name).touch(mode=0o644)
            with patch.dict(os.environ, {"JUPYTER_TOKEN": token, "JUPYTER_PORT": "9999"}, clear=True):
                configure_jupyter(directory)
            config = self.read_config(directory)
            self.assertEqual(config.IdentityProvider.token, token)
            self.assertEqual(config.ServerApp.port, 9999)
            self.assertEqual((directory / "jupyter_lab_config.py").stat().st_mode & 0o777, 0o600)


if __name__ == "__main__":
    unittest.main()
