"""Bounded offline tests for the published agents.json discovery contract."""
import copy
import json
import sys
import unittest
from pathlib import Path
import jsonschema

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from scripts.verify_public_site import validate_agent_index_contract

class AgentIndexSchemaTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.schema=json.loads((ROOT/"schemas"/"agents.v1.schema.json").read_text(encoding="utf-8"))
        jsonschema.Draft202012Validator.check_schema(cls.schema)
        cls.validator=jsonschema.Draft202012Validator(cls.schema,format_checker=jsonschema.FormatChecker())
    def fixture(self,name):
        return json.loads((ROOT/"tests"/"fixtures"/name).read_text(encoding="utf-8"))
    def test_live_snapshot_is_schema_valid(self):
        value=json.loads((ROOT/"agents.json").read_text(encoding="utf-8"))
        self.validator.validate(value)
        validate_agent_index_contract(value)
    def test_synthetic_valid(self):
        value=self.fixture("agents_valid.json")
        self.validator.validate(value)
        validate_agent_index_contract(value)
    def test_write_access_rejected(self):
        value=self.fixture("agents_invalid_write.json")
        self.assertRaises(jsonschema.ValidationError,self.validator.validate,value)
    def test_agent_path_rejected(self):
        value=self.fixture("agents_invalid_reference.json")
        self.assertRaises(jsonschema.ValidationError,self.validator.validate,value)
    def test_unknown_review_agent_rejected(self):
        value=self.fixture("agents_valid.json")
        value["task_surfaces"][0]["recommended_review_agent"]="Nonexistent Auditor"
        with self.assertRaises(SystemExit):
            validate_agent_index_contract(value)
    def test_unknown_capability_repo_rejected(self):
        value=self.fixture("agents_valid.json")
        value["capability_index"]["repository-discovery"]=["Untrusted/repository"]
        with self.assertRaises(SystemExit):
            validate_agent_index_contract(value)
    def test_bad_contextual_url_rejected(self):
        value=self.fixture("agents_valid.json")
        value["contextual_links"]["hidden_gems"]="https://attacker.example/redirect"
        with self.assertRaises(SystemExit):
            validate_agent_index_contract(value)
if __name__=="__main__":unittest.main()
