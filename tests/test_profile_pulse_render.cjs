"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const { test } = require("node:test");

const root = path.resolve(__dirname, "..");
const source = fs.readFileSync(path.join(root, "assets/profile-pulse.js"), "utf8");
const snapshot = JSON.parse(fs.readFileSync(path.join(root, "data/profile-pulse.json"), "utf8"));
const home = fs.readFileSync(path.join(root, "index.html"), "utf8");
const professional = fs.readFileSync(path.join(root, "ai-assisted-work/index.html"), "utf8");

class Element {
  constructor(tag, mode = null) {
    this.tag = tag;
    this.mode = mode;
    this.children = [];
    this.textContent = "";
  }
  getAttribute(name) { return name === "data-pulse-mode" ? this.mode : null; }
  append(...children) { this.children.push(...children); }
  appendChild(child) { this.children.push(child); }
  replaceChildren() { this.children = []; }
  set innerHTML(_) { throw new Error("unsafe HTML sink"); }
}

async function render(page, pulse = snapshot, ok = true) {
  const tag = page.match(/<ul\b[^>]*\bid="pulse-evidence-list"[^>]*>/)?.[0];
  assert.ok(tag);
  const mode = tag.match(/data-pulse-mode="([^"]+)"/)?.[1] ?? null;
  const list = new Element("ul", mode);
  const status = new Element("p");
  const calls = [];
  const context = {
    document: {
      getElementById: id => ({ "pulse-evidence-list": list, "pulse-evidence-status": status }[id]),
      createElement: tag => new Element(tag),
    },
    fetch: async (url, options) => {
      calls.push([url, options.cache, options.credentials]);
      return { ok, json: async () => pulse };
    },
    Date,
  };
  vm.runInNewContext(source, context);
  await new Promise(resolve => setImmediate(resolve));
  assert.deepEqual(calls, [["/data/profile-pulse.json", "no-cache", "omit"]]);
  return { list, status, links: list.children.map(item => item.children[1].href) };
}

test("professional page displays only the first three accepted upstream PRs", async () => {
  assert.match(professional, /<script src="\/assets\/profile-pulse\.js\?[^"]+" defer><\/script>/);
  const pulse = structuredClone(snapshot);
  pulse.external_inbound = [structuredClone(pulse.accepted_inbound[0])];
  const { links, list, status } = await render(professional, pulse);
  assert.equal(links.length, 3);
  assert.deepEqual(links, pulse.accepted_upstream.slice(0, 3).map(x => x.url));
  assert.ok(list.children.every(item => item.children[0].textContent === "Accepted contribution to another project"));
  assert.match(status.textContent, new RegExp(pulse.generated_at.slice(0, 10)));
});

test("homepage retains original one upstream, inbound and starter selection", async () => {
  const { links } = await render(home);
  assert.deepEqual(links, [
    ...snapshot.accepted_upstream.slice(0, 1),
    ...snapshot.accepted_inbound.slice(0, 2),
    ...snapshot.contribution_tasks.slice(0, 1),
  ].map(x => x.url));
});

test("professional page never fills empty slots with other contribution types", async () => {
  const pulse = structuredClone(snapshot);
  pulse.accepted_upstream = pulse.accepted_upstream.slice(0, 1);
  assert.deepEqual((await render(professional, pulse)).links, [pulse.accepted_upstream[0].url]);
  pulse.accepted_upstream = [];
  const { links, status } = await render(professional, pulse);
  assert.deepEqual(links, []);
  assert.match(status.textContent, /temporarily unavailable/);
});

test("malicious URLs or future timestamps fail closed", async () => {
  for (const change of [
    pulse => { pulse.accepted_upstream[0].url = "https://attacker.example/collect"; },
    pulse => { pulse.generated_at = "2099-01-01T00:00:00Z"; },
  ]) {
    const pulse = structuredClone(snapshot);
    change(pulse);
    const { links, status } = await render(professional, pulse);
    assert.deepEqual(links, []);
    assert.match(status.textContent, /temporarily unavailable/);
  }
});

test("unavailable snapshot preserves canonical fallback and no generated entries", async () => {
  const { links, status } = await render(professional, snapshot, false);
  assert.deepEqual(links, []);
  assert.match(status.textContent, /temporarily unavailable/);
  assert.match(professional, /href="https:\/\/github\.com\/JoanAbad82\/JoanAbad82\/blob\/main\/profile-pulse\.json"/);
});

test("external titles stay literal text and links use noopener noreferrer", async () => {
  const pulse = structuredClone(snapshot);
  pulse.accepted_upstream[0].title = '<img src=x onerror="alert(1)">';
  const { list } = await render(professional, pulse);
  const link = list.children[0].children[1];
  assert.equal(link.textContent, pulse.accepted_upstream[0].title);
  assert.equal(link.children.length, 0);
  assert.equal(link.rel, "noopener noreferrer");
  assert.equal(link.target, "_blank");
});
