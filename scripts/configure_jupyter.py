"""Write authenticated Jupyter settings without printing credentials."""

import os
from pathlib import Path
import secrets


def configure_jupyter(config_dir: Path) -> None:
    token = os.environ.get("JUPYTER_TOKEN") or secrets.token_urlsafe(32)
    port = int(os.environ.get("JUPYTER_PORT", "8888"))
    config_dir.mkdir(parents=True, exist_ok=True)
    config = f'''
c.ServerApp.allow_root = False
c.ServerApp.allow_remote_access = True
c.ServerApp.open_browser = False
c.ServerApp.ip = "0.0.0.0"
c.ServerApp.port = {port}
c.ServerApp.notebook_dir = "/workspace"
c.ServerApp.terminado_settings = {{"shell_command": ["/bin/bash", "-l"]}}
c.IdentityProvider.token = {token!r}
'''
    for name, content in (("jupyter_lab_config.py", config), ("jupyter_token", token)):
        path = config_dir / name
        # Protect both new files and files left behind by earlier starts.
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w") as stream:
            os.fchmod(stream.fileno(), 0o600)
            stream.write(content)


if __name__ == "__main__":
    configure_jupyter(Path("/home/unsloth/.jupyter"))
    print("Jupyter authentication enabled. Retrieve the token from ~/.jupyter/jupyter_token.")
