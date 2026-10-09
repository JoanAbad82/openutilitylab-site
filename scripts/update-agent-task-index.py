#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
OWNER = "JoanAbad82"
SCHEMA_URL = "https://raw.githubusercontent.com/JoanAbad82/JoanAbad82/main/schemas/agent-task-index.schema.json"
SOURCES = [
    "JoanAbad82/github-hidden-gems-research-intake",
    "JoanAbad82/repasactiu-research-intake",
]
USER_AGENT = "JoanAbad82-AgentTaskIndex/1.0"


def request_json(url: str) -> Any:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": USER_AGENT,
        "X-GitHub-Api-Version": "2022-11-28",
    }
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        raise SystemExit(f"HTTP {exc.code} for {url}") from exc
    except urllib.error.URLError as exc:
        raise SystemExit(f"URL error for {url}: {exc.reason}") from exc


def raw_url(repo: str, path: str) -> str:
    owner, name = repo.split("/", 1)
    return f"https://raw.githubusercontent.com/{owner}/{name}/main/{path}"


def load_surface_capabilities(repo: str) -> list[str]:
    task = request_json(
        f"https://api.github.com/repos/{repo}/contents/AGENT_TASKS.json"
    )
    if not isinstance(task, dict) or "content" not in task:
        raise SystemExit(f"Cannot read AGENT_TASKS.json for {repo}")
    import base64
    decoded = base64.b64decode(task["content"]).decode("utf-8-sig")
    obj = json.loads(decoded)
    caps = obj.get("capabilities") or obj.get("accepted_task_types")
    if not isinstance(caps, list) or not caps:
        raise SystemExit(f"No capabilities in {repo}/AGENT_TASKS.json")
    return sorted(dict.fromkeys(str(x) for x in caps))


def load_open_agent_ready_issues(repo: str) -> list[dict[str, Any]]:
    query = urllib.parse.urlencode(
        {"state": "open", "labels": "agent-ready", "per_page": "100"}
    )
    data = request_json(f"https://api.github.com/repos/{repo}/issues?{query}")
    if not isinstance(data, list):
        raise SystemExit(f"Unexpected issues response for {repo}")
    return [item for item in data if isinstance(item, dict) and "pull_request" not in item]


def main() -> int:
    tasks: list[dict[str, Any]] = []
    latest_updated_at: str | None = None

    routing = json.loads((ROOT / "agents.json").read_text(encoding="utf-8"))
    custom_agent_names = {
        str(item.get("name"))
        for item in routing.get("custom_agents", [])
        if isinstance(item, dict) and item.get("name")
    }
    review_agent_by_repo = {
        str(surface.get("repository")): str(surface.get("recommended_review_agent"))
        for surface in routing.get("task_surfaces", [])
        if isinstance(surface, dict)
        and surface.get("repository")
        and surface.get("recommended_review_agent")
    }
    for repo, agent_name in review_agent_by_repo.items():
        if agent_name not in custom_agent_names:
            raise SystemExit(
                f"Unknown recommended_review_agent {agent_name!r} for {repo}"
            )

    for repo in SOURCES:
        capabilities = load_surface_capabilities(repo)
        contract = raw_url(repo, "AGENT_TASKS.json")
        for issue in load_open_agent_ready_issues(repo):
            labels = sorted(
                {
                    str(label.get("name"))
                    for label in issue.get("labels", [])
                    if isinstance(label, dict) and label.get("name")
                }
            )
            updated_at = str(issue.get("updated_at") or "")
            if updated_at and (latest_updated_at is None or updated_at > latest_updated_at):
                latest_updated_at = updated_at

            number = int(issue["number"])
            task = {
                "task_id": f"{repo}#{number}",
                "repository": repo,
                "issue_number": number,
                "title": str(issue.get("title") or "").strip(),
                "url": str(issue.get("html_url") or ""),
                "state": "open",
                "updated_at": updated_at,
                "task_contract": contract,
                "surface_capabilities": capabilities,
                "labels": labels,
                "human_review_required": "human-review-required" in labels,
            }
            review_agent = review_agent_by_repo.get(repo)
            if review_agent:
                task["recommended_review_agent"] = review_agent
            tasks.append(task)

    tasks.sort(key=lambda x: (x["repository"], x["issue_number"]))

    output = {
        "$schema": SCHEMA_URL,
        "schema_version": "1.0",
        "owner": OWNER,
        "purpose": "live concrete agent-ready tasks routed from the global agent discovery surface",
        "updated_at": latest_updated_at,
        "source_policy": {
            "state": "open",
            "label": "agent-ready",
            "repositories": SOURCES,
        },
        "task_count": len(tasks),
        "tasks": tasks,
    }

    target = ROOT / "tasks.json"
    target.write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"AGENT_TASK_INDEX_GENERATED={len(tasks)}")
    print(f"OUTPUT={target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
