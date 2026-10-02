"""Read-only checks for the independent Python 3.12 image chain."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Python312ImageTests(unittest.TestCase):
    def test_base_installs_one_python312_environment(self):
        text = (ROOT / 'base-py312/Dockerfile').read_text()
        self.assertIn('uv python install 3.12', text)
        self.assertIn('uv venv /opt/venv --python 3.12', text)
        self.assertNotIn('3.13', text)
        self.assertNotIn('chmod -R 777', text)

    def test_mlbio_inherits_the_new_base(self):
        text = (ROOT / 'mlbio/Dockerfile').read_text()
        self.assertIn('/base-py312:master', text)
        self.assertNotIn('uv python install', text)
        self.assertNotIn('venv-py312', text)
        self.assertIn('source /opt/venv/bin/activate', (ROOT / 'mlbio/.bashrc').read_text())

    def test_workflows_publish_base_before_mlbio(self):
        base = (ROOT / '.github/workflows/docker-base-py312.yml').read_text()
        self.assertIn('name: base-py312', base)
        self.assertIn("'base-py312/**'", base)
        mlbio = (ROOT / '.github/workflows/docker-mlbio.yml').read_text()
        self.assertIn('workflows: ["base-py312"]', mlbio)
        self.assertIn("github.event.workflow_run.conclusion == 'success'", mlbio)
        self.assertIn('/base-py312:master', mlbio)

    def test_python313_generalizations_chain_is_preserved(self):
        self.assertIn('uv python install 3.13', (ROOT / 'base-py313/Dockerfile').read_text())
        self.assertIn('/base-py313:master', (ROOT / 'generalizations-py313/Dockerfile').read_text())


if __name__ == '__main__':
    unittest.main()
