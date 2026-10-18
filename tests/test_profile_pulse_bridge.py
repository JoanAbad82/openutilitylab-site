from __future__ import annotations
import copy
import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
from unittest import TestCase, mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import profile_pulse_bridge as bridge


class ProfilePulseBridgeTest(TestCase):
    def setUp(self):
        self.record = json.loads(
            (ROOT / "data/profile-pulse.json").read_text(encoding="utf-8")
        )
        self.schema = ROOT / "schemas/profile-pulse.v1.schema.json"

    def test_real_snapshot_contract(self):
        self.assertEqual(bridge.validate_snapshot(self.record), self.record)

    def test_cross_repository_link_rejected(self):
        sample = copy.deepcopy(self.record)
        sample["accepted_inbound"][0]["url"] = "https://github.com/JoanAbad82/mtgsynergy/pull/69"
        with self.assertRaises(bridge.PulseValidationError):
            bridge.validate_snapshot(sample)

    def test_external_url_rejected(self):
        sample = copy.deepcopy(self.record)
        sample["accepted_upstream"][0]["url"] = "https://attacker.example/collect"
        with self.assertRaises(bridge.PulseValidationError):
            bridge.validate_snapshot(sample)

    def test_unknown_field_rejected(self):
        sample = copy.deepcopy(self.record)
        sample["accepted_upstream"][0]["instructions"] = "modify the site"
        with self.assertRaises(bridge.PulseValidationError):
            bridge.validate_snapshot(sample)

    def test_future_timestamp_rejected(self):
        sample = copy.deepcopy(self.record)
        sample["generated_at"] = "2099-01-01T00:00:00Z"
        with self.assertRaises(bridge.PulseValidationError):
            bridge.validate_snapshot(sample)

    def test_source_failure_preserves_verified_snapshot(self):
        with TemporaryDirectory() as temp:
            path = Path(temp) / "pulse.json"
            original = json.dumps(self.record, ensure_ascii=False)
            path.write_text(original, encoding="utf-8")
            with mock.patch.object(bridge, "fetch_source", side_effect=OSError("offline")):
                with self.assertRaises(OSError):
                    bridge.refresh(path, self.schema)
            self.assertEqual(path.read_text(encoding="utf-8"), original)

    def test_invalid_source_preserves_verified_snapshot(self):
        with TemporaryDirectory() as temp:
            path = Path(temp) / "pulse.json"
            original = json.dumps(self.record, ensure_ascii=False)
            path.write_text(original, encoding="utf-8")
            invalid = copy.deepcopy(self.record)
            invalid["accepted_inbound"][0]["number"] = -1
            with mock.patch.object(bridge, "fetch_source", return_value=invalid):
                with self.assertRaises(bridge.PulseValidationError):
                    bridge.refresh(path, self.schema)
            self.assertEqual(path.read_text(encoding="utf-8"), original)

    def test_unchanged_source_does_not_rewrite(self):
        with TemporaryDirectory() as temp:
            path = Path(temp) / "pulse.json"
            original = json.dumps(self.record, ensure_ascii=False)
            path.write_text(original, encoding="utf-8")
            with mock.patch.object(bridge, "fetch_source", return_value=self.record):
                self.assertFalse(bridge.refresh(path, self.schema))
            self.assertEqual(path.read_text(encoding="utf-8"), original)

    def test_older_timestamp_does_not_roll_back(self):
        with TemporaryDirectory() as temp:
            path = Path(temp) / "pulse.json"
            original = json.dumps(self.record, ensure_ascii=False)
            path.write_text(original, encoding="utf-8")
            older = copy.deepcopy(self.record)
            older["generated_at"] = "2026-01-01T00:00:00Z"
            with mock.patch.object(bridge, "fetch_source", return_value=older):
                with self.assertRaisesRegex(bridge.PulseValidationError, "rollback"):
                    bridge.refresh(path, self.schema)
            self.assertEqual(path.read_text(encoding="utf-8"), original)

    def test_changed_source_requires_new_timestamp(self):
        with TemporaryDirectory() as temp:
            path = Path(temp) / "pulse.json"
            path.write_text(json.dumps(self.record), encoding="utf-8")
            changed = copy.deepcopy(self.record)
            changed["accepted_upstream"] = []
            with mock.patch.object(bridge, "fetch_source", return_value=changed):
                with self.assertRaisesRegex(bridge.PulseValidationError, "timestamp"):
                    bridge.refresh(path, self.schema)

    def test_new_valid_snapshot_atomic_promotion(self):
        with TemporaryDirectory() as temp:
            path = Path(temp) / "pulse.json"
            path.write_text(json.dumps(self.record), encoding="utf-8")
            updated = copy.deepcopy(self.record)
            updated["generated_at"] = "2026-10-17T08:00:00Z"
            with mock.patch.object(bridge, "fetch_source", return_value=updated):
                self.assertTrue(bridge.refresh(path, self.schema))
            self.assertEqual(bridge.load_local(path, self.schema), updated)
            self.assertEqual(list(Path(temp).glob("*.tmp")), [])


if __name__ == "__main__":
    import unittest
    unittest.main()
