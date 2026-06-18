import sys
import unittest
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

import app as backend_app  # noqa: E402


class BackendSmokeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = backend_app.app.test_client()

    def test_health_route_reports_ready_state(self):
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertEqual(payload["status"], "ok")
        self.assertTrue(payload["model_loaded"])
        self.assertGreaterEqual(payload["supported_classes"], 1)

    def test_voice_advisory_returns_actionable_payload(self):
        response = self.client.post(
            "/voice-advisory",
            json={"transcript": "Tomato leaves have brown spots and yellowing"},
        )

        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertIn("predicted_class", payload)
        self.assertIn("advice", payload)
        self.assertIn("prevention", payload)
        self.assertGreater(len(payload["advice"]), 0)
        self.assertGreaterEqual(payload["confidence"], 0.0)


if __name__ == "__main__":
    unittest.main()
