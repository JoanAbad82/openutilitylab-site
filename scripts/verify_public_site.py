#!/usr/bin/env python3
from __future__ import annotations

import json
from urllib.parse import urlsplit
import jsonschema
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(msg: str) -> None:
    print(f"ERROR: {msg}")
    raise SystemExit(1)


def tracked_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return [x.strip() for x in result.stdout.splitlines() if x.strip()]


def validate_referrals() -> None:
    manifest_path = ROOT / "REFERRAL_ATTRIBUTION.json"
    redirects_path = ROOT / "_redirects"

    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    campaigns = data.get("campaigns")
    if not isinstance(campaigns, list) or not campaigns:
        fail("referral manifest must contain at least one campaign")

    ids: set[str] = set()
    paths: set[str] = set()
    expected_redirects: set[str] = set()

    for campaign in campaigns:
        cid = campaign.get("id", "")
        path = campaign.get("path", "")
        destination = campaign.get("destination", "")
        source = campaign.get("source_platform", "")
        status = campaign.get("status", "")

        if not cid or cid in ids:
            fail(f"invalid or duplicate referral id: {cid!r}")
        if not path.startswith("/r/mb/") or path in paths:
            fail(f"invalid or duplicate referral path: {path!r}")
        if source != "moltbook":
            fail(f"unexpected referral source_platform for {cid}: {source!r}")
        if status not in {"active", "retired"}:
            fail(f"invalid referral status for {cid}: {status!r}")
        if not destination.startswith("https://github.com/JoanAbad82/"):
            fail(f"referral destination must stay on the owned GitHub surface: {cid}")

        ids.add(cid)
        paths.add(path)
        if status == "active":
            expected_redirects.add(f"{path} {destination} 302")

    actual_redirects = {
        line.strip()
        for line in redirects_path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
    if actual_redirects != expected_redirects:
        fail("_redirects does not exactly match active referral campaigns")

    if data.get("privacy", {}).get("unique_per_agent_tokens") is not False:
        fail("referral attribution must not use per-agent tokens")
    if data.get("privacy", {}).get("fingerprinting") is not False:
        fail("referral attribution must not enable fingerprinting")
    if data.get("privacy", {}).get("cookies_added") is not False:
        fail("referral attribution must not add cookies")



def validate_agent_index_contract(agents: dict) -> None:
    """Structural and bounded cross-reference validation; no network access."""
    schema_path = ROOT / "schemas" / "agents.v1.schema.json"
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    jsonschema.Draft202012Validator.check_schema(schema)
    validator = jsonschema.Draft202012Validator(
        schema, format_checker=jsonschema.FormatChecker()
    )
    errors = sorted(validator.iter_errors(agents), key=lambda e: tuple(map(str, e.path)))
    if errors:
        fail("agents.json schema: " + errors[0].message)
    known_agents = {a["name"] for a in agents["custom_agents"]}
    if len(known_agents) != len(agents["custom_agents"]):
        fail("agents.json duplicate custom agents")
    known_repos = {"JoanAbad82/" + r["name"] for r in agents["repositories"]}
    allowed_task_repos = {s["repository"] for s in agents["task_surfaces"]}
    for surface in agents["task_surfaces"]:
        if surface["primary_project"] not in known_repos:
            fail("agents.json unknown primary_project")
        selected = surface.get("recommended_review_agent")
        if selected is not None and selected not in known_agents:
            fail("agents.json unknown recommended_review_agent")
    for category, repositories in agents["capability_index"].items():
        for repository in repositories:
            if repository not in known_repos and repository not in allowed_task_repos:
                fail(f"agents.json capability {category} references unknown repo")
    for surface in agents["task_surfaces"]:
        for key in ("live_agent_ready_query", "task_index", "project_status"):
            url = urlsplit(surface[key])
            if url.scheme != "https" or url.hostname not in {
                "github.com", "raw.githubusercontent.com"
            } or url.username or url.password:
                fail("agents.json untrusted task URL in " + key)
    for key, value in agents["contextual_links"].items():
        url = urlsplit(value)
        if url.scheme != "https" or url.hostname != "openutilitylab.com":
            fail("agents.json untrusted contextual link " + key)


def validate_editorial_catalog(path: Path | None = None) -> None:
    """Fail closed on automatic promotion and restricted disclosures."""
    catalog_path = path or (
        ROOT / "project_sources/editorial/PORTFOLIO_PROJECT_CATALOG_V1_2026-10-18.json"
    )
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    if catalog.get("schema_version") != "1.0":
        fail("editorial catalog schema version mismatch")
    if catalog.get("purpose") != "noncanonical_editorial_candidate_inventory":
        fail("editorial catalog must remain noncanonical")
    if catalog.get("public_release_status") != "not_published_to_homepage":
        fail("editorial catalog must not claim publication")
    if catalog.get("rules", {}).get("no_automatic_homepage_mutation") is not True:
        fail("editorial catalog must forbid automatic homepage mutation")
    if catalog.get("rules", {}).get("private_items_have_no_public_names_or_urls") is not True:
        fail("editorial catalog must keep private entries anonymous")
    rows = catalog.get("projects")
    if not isinstance(rows, list) or not rows:
        fail("editorial catalog project list is empty")
    ids: set[str] = set()
    counts = {"public": 0, "experimental": 0, "private": 0}
    valid_presence = {"listed", "candidate", "not_listed"}
    for row in rows:
        if not isinstance(row, dict):
            fail("editorial catalog contains non-object item")
        pid = row.get("id")
        bucket = row.get("category")
        if not isinstance(pid, str) or not re.fullmatch(r"[a-z0-9_]+", pid) or pid in ids:
            fail(f"invalid or duplicate editorial project id: {pid!r}")
        ids.add(pid)
        if bucket not in counts:
            fail(f"unrecognized editorial category: {pid!r}")
        counts[bucket] += 1
        if row.get("presence") not in valid_presence:
            fail(f"invalid editorial presence: {pid!r}")
        if not row.get("publication_gate"):
            fail(f"missing editorial gate: {pid!r}")
        if not isinstance(row.get("evidence"), list) or not row["evidence"] or not all(
            isinstance(e, str) and e.strip() for e in row["evidence"]
        ):
            fail(f"missing editorial evidence: {pid!r}")
        if not isinstance(row.get("claim_limit"), str) or not row["claim_limit"].strip():
            fail(f"missing editorial claim limit: {pid!r}")
        url = row.get("public_url")
        if url is not None:
            parts = urlsplit(url) if isinstance(url, str) else None
            if parts is None or parts.scheme != "https" or not parts.hostname or parts.username or parts.password:
                fail(f"invalid editorial public URL: {pid!r}")
        if bucket == "private":
            if (
                not isinstance(row.get("name"), str)
                or not row["name"].lower().startswith("private ")
                or url is not None
                or row.get("safe_summary") is not None
                or row.get("presence") != "not_listed"
                or row.get("publication_gate") != "do_not_publish"
            ):
                fail(f"private editorial entry exposed or promotable: {pid!r}")
        elif bucket == "public" and (url is None or not row.get("safe_summary")):
            fail(f"public editorial candidate lacks evidence-ready preview: {pid!r}")
    if not all(counts.values()):
        fail("editorial catalog must distinguish public, experimental and private")


def validate_public_portfolio_refresh() -> None:
    home = (ROOT / "index.html").read_text(encoding="utf-8")
    profile = (ROOT / "ai-assisted-work/index.html").read_text(encoding="utf-8")
    expected = {
        "Repàs Actiu": "https://repasactiu.pages.dev/",
        "Programación Práctica": "https://programacion-practica.pages.dev/",
        "GitHub Hidden Gems": "https://github.com/JoanAbad82/github-hidden-gems",
    }
    for name, url in expected.items():
        if name not in home or name not in profile:
            fail("missing public project in home or professional profile: " + name)
        if f'href="{url}"' not in home or f'href="{url}"' not in profile:
            fail("public project link mismatch: " + name)
    if home.count('id="featured-work"') != 1:
        fail("homepage current work section must be unique")
    if profile.count('id="recent-case-studies"') != 1:
        fail("professional profile recent case studies must be unique")
    if 'href="/ai-assisted-work/#recent-case-studies"' not in home:
        fail("homepage profile bridge missing")
    if not all(x in home for x in (
        "Research with explicit limits", "The work remains experimental",
        "Professional inquiries:", "mailto:abadbatallajoan@gmail.com"
    )):
        fail("homepage research/professional trust copy missing")
    for document in (home, profile):
        for forbidden in ("M2M_EVIDENCE_ROUTER", "AGENTE_MULTIPLE_AUTONOMO"):
            if forbidden in document:
                fail("private project identifier in public HTML")

def main() -> int:
    required = [
        "README.md",
        "AGENTS.md",
        "PROJECT_CONTEXT.json",
        "SECURITY.md",
        "CONTRIBUTING.md",
        "sitemap.xml",
        "robots.txt",
        "index.html",
        "_redirects",
        "REFERRAL_ATTRIBUTION.json",
        "REFERRAL_ATTRIBUTION.md",
        "PROJECT_STATUS.json",
        "llms.txt",
        "agents.json",
        "schemas/agents.v1.schema.json",
        "tasks.json",
        ".github/copilot-instructions.md",
    ]
    for rel in required:
        if not (ROOT / rel).exists():
            fail(f"missing required file: {rel}")

    json.loads((ROOT / "PROJECT_CONTEXT.json").read_text(encoding="utf-8"))
    json.loads((ROOT / "PROJECT_STATUS.json").read_text(encoding="utf-8"))
    agents = json.loads((ROOT / "agents.json").read_text(encoding="utf-8"))
    validate_agent_index_contract(agents)
    if agents.get("trust", {}).get("production_write_access") is not False:
        fail("agents.json must keep production_write_access=false")
    if agents.get("trust", {}).get("automatic_production_promotion") is not False:
        fail("agents.json must keep automatic_production_promotion=false")
    concrete = agents.get("concrete_tasks", {})
    if concrete.get("url") != "https://openutilitylab.com/tasks.json":
        fail("agents.json concrete_tasks.url must point to /tasks.json")

    custom_agents = agents.get("custom_agents")
    if not isinstance(custom_agents, list) or not custom_agents:
        fail("agents.json custom_agents must be a non-empty array")
    custom_agent_names: set[str] = set()
    for agent in custom_agents:
        if not isinstance(agent, dict):
            fail("agents.json custom_agents contains non-object")
        name = agent.get("name")
        repository = agent.get("repository")
        path = agent.get("path")
        if not isinstance(name, str) or not name.strip():
            fail("agents.json custom agent missing name")
        if name in custom_agent_names:
            fail(f"agents.json duplicate custom agent name: {name}")
        custom_agent_names.add(name)
        if repository != "JoanAbad82/github-hidden-gems":
            fail(f"unexpected custom agent repository: {repository!r}")
        if not isinstance(path, str) or not path.startswith(".github/agents/"):
            fail(f"invalid custom agent path for {name}: {path!r}")

    evidence_auditor = next(
        (agent for agent in custom_agents if agent.get("name") == "Evidence Auditor"),
        None,
    )
    if evidence_auditor is None:
        fail("agents.json missing Evidence Auditor")
    if evidence_auditor.get("path") != ".github/agents/evidence-auditor.agent.md":
        fail("Evidence Auditor path drift")
    if evidence_auditor.get("safety") != "read-only":
        fail("Evidence Auditor safety must remain read-only")
    if evidence_auditor.get("user_invocable") is not True:
        fail("Evidence Auditor must remain user-invocable")

    task_surfaces = agents.get("task_surfaces")
    if not isinstance(task_surfaces, list):
        fail("agents.json task_surfaces must be an array")
    review_agent_by_repo: dict[str, str] = {}
    for surface in task_surfaces:
        if not isinstance(surface, dict):
            fail("agents.json task_surfaces contains non-object")
        repo = surface.get("repository")
        review_agent = surface.get("recommended_review_agent")
        if review_agent is not None:
            if review_agent not in custom_agent_names:
                fail(
                    f"task surface {repo} references unknown recommended_review_agent: "
                    f"{review_agent!r}"
                )
            review_agent_by_repo[str(repo)] = str(review_agent)

    tasks = json.loads((ROOT / "tasks.json").read_text(encoding="utf-8"))
    if tasks.get("owner") != "JoanAbad82":
        fail("tasks.json owner mismatch")
    if tasks.get("source_policy", {}).get("state") != "open":
        fail("tasks.json source_policy.state must be open")
    if tasks.get("source_policy", {}).get("label") != "agent-ready":
        fail("tasks.json source_policy.label must be agent-ready")
    task_rows = tasks.get("tasks")
    if not isinstance(task_rows, list):
        fail("tasks.json tasks must be an array")
    if tasks.get("task_count") != len(task_rows):
        fail("tasks.json task_count mismatch")
    seen_task_ids: set[str] = set()
    for task in task_rows:
        task_id = task.get("task_id")
        if not task_id or task_id in seen_task_ids:
            fail(f"invalid or duplicate task_id: {task_id!r}")
        seen_task_ids.add(task_id)
        if task.get("state") != "open":
            fail(f"task must be open: {task_id}")
        if "agent-ready" not in task.get("labels", []):
            fail(f"task missing agent-ready label: {task_id}")
        if not task.get("task_contract", "").startswith("https://raw.githubusercontent.com/JoanAbad82/"):
            fail(f"task contract must stay on owned GitHub surface: {task_id}")
        expected_review_agent = review_agent_by_repo.get(str(task.get("repository")))
        if expected_review_agent is not None:
            if task.get("recommended_review_agent") != expected_review_agent:
                fail(
                    f"task recommended_review_agent drift for {task_id}: "
                    f"{task.get('recommended_review_agent')!r} != {expected_review_agent!r}"
                )

    ET.parse(ROOT / "sitemap.xml")
    validate_referrals()
    validate_editorial_catalog()
    validate_public_portfolio_refresh()

    forbidden_claims = [r"No tracking or analytics\.", r"no analytics, no tracking"]
    for rel in ["README.md", "affiliate-friction-auditor/index.html"]:
        text = (ROOT / rel).read_text(encoding="utf-8", errors="ignore")
        for pattern in forbidden_claims:
            if re.search(pattern, text, re.I):
                fail(f"stale analytics claim in {rel}: {pattern}")

    risky = re.compile(r"(^|/)(\.env($|\.)|.*\.(pem|key|p12|pfx)$)", re.I)
    bad = [p for p in tracked_files() if risky.search(p)]
    if bad:
        fail("risky tracked files: " + ", ".join(bad))

    print("PUBLIC_SITE_VERIFY=PASS")
    print("Required context: PASS")
    print("Project context JSON: PASS")
    print("Sitemap XML: PASS")
    print("Referral attribution policy/redirects: PASS")
    print("Noncanonical editorial catalog / privacy gates: PASS")
    print("Homepage / profile public project integration: PASS")
    print("Privacy/analytics wording: PASS")
    print("Tracked secret-file policy: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
