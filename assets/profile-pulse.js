"use strict";
/* OPENUTILITYLAB_GITHUB_PROFILE_PULSE_BRIDGE_V1: locally mirrored read-only evidence */
(function () {
  const list = document.getElementById("pulse-evidence-list");
  const status = document.getElementById("pulse-evidence-status");
  if (!list || !status) return;
  const groups = [
    { key: "accepted_upstream", label: "Accepted contribution to another project", count: 1 },
    { key: "accepted_inbound", label: "Merged community contribution", count: 2 },
    { key: "contribution_tasks", label: "Contributor task recorded as open", count: 1 },
  ];
  const canonical = /^https:\/\/github\.com\/([A-Za-z0-9-]{1,39})\/([A-Za-z0-9_.-]{1,100})\/(pull|issues)\/([1-9][0-9]*)$/;
  function validItem(item, group) {
    if (!item || typeof item !== "object" || typeof item.title !== "string" ||
        !item.title || item.title.length > 110 || typeof item.repo !== "string" ||
        !Number.isInteger(item.number) || item.number < 1 || typeof item.url !== "string") {
      return false;
    }
    const match = canonical.exec(item.url);
    return Boolean(match && match[1] + "/" + match[2] === item.repo &&
      Number(match[4]) === item.number &&
      match[3] === (group === "contribution_tasks" ? "issues" : "pull"));
  }
  function validPulse(pulse) {
    if (!pulse || pulse.schema !== "GITHUB_PORTFOLIO_PULSE_V1" ||
        typeof pulse.generated_at !== "string" ||
        !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(pulse.generated_at)) return false;
    const timestamp = Date.parse(pulse.generated_at);
    if (!Number.isFinite(timestamp) || timestamp > Date.now() + 600000) return false;
    return groups.every(({key}) => Array.isArray(pulse[key]) &&
      pulse[key].every(item => validItem(item, key)));
  }
  function appendEntry(label, entry) {
    const item = document.createElement("li");
    item.className = "pulse-evidence-item";
    const type = document.createElement("span");
    type.className = "pulse-evidence-type";
    type.textContent = label;
    const headline = document.createElement("a");
    headline.href = entry.url;
    headline.rel = "noopener noreferrer";
    headline.target = "_blank";
    headline.textContent = entry.title;
    const meta = document.createElement("span");
    meta.className = "pulse-evidence-meta";
    meta.textContent = entry.repo + " · #" + entry.number;
    item.append(type, headline, meta);
    list.appendChild(item);
  }
  async function render() {
    try {
      const response = await fetch("/data/profile-pulse.json", {
        cache: "no-cache", credentials: "omit"
      });
      if (!response.ok) throw new Error("Snapshot unavailable");
      const pulse = await response.json();
      if (!validPulse(pulse)) throw new Error("Invalid snapshot");
      const entries = [];
      for (const group of groups) {
        for (const item of pulse[group.key].slice(0, group.count)) {
          entries.push([group.label, item]);
        }
      }
      if (entries.length === 0) throw new Error("No eligible snapshot entries");
      for (const [label, entry] of entries) appendEntry(label, entry);
      status.textContent = "Last material change in the published snapshot: " +
        pulse.generated_at.slice(0, 10) +
        " (UTC). Records may change; confirm their current status on GitHub.";
    } catch (_) {
      list.replaceChildren();
      status.textContent = "GitHub evidence is temporarily unavailable here. View the source profile for current records.";
    }
  }
  render();
})();
