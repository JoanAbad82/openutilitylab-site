"use strict";
/* OPENUTILITYLAB_ACCESSIBLE_THEME_V1. Defaults to system, persists explicit choice. */
(() => {
  const key = "openutilitylab.theme.v1";
  const allowed = ["system", "light", "dark"];
  const media = typeof window.matchMedia === "function"
    ? window.matchMedia("(prefers-color-scheme: dark)") : null;
  let choice = "system";
  try {
    const saved = window.localStorage.getItem(key);
    if (allowed.includes(saved)) choice = saved;
  } catch (_) { /* storage unavailable: use system */ }

  const effective = () => choice === "system"
    ? (media && media.matches ? "dark" : "light") : choice;

  function apply() {
    const theme = effective();
    document.documentElement.setAttribute("data-theme", theme);
    document.documentElement.style.colorScheme = theme;
    for (const control of document.querySelectorAll("[data-appearance-choice]")) {
      const selected = control.getAttribute("data-appearance-choice") === choice;
      control.setAttribute("aria-pressed", String(selected));
    }
  }
  apply(); // synchronous in <head> avoids light flash on dark devices
  if (media) {
    if (typeof media.addEventListener === "function") {
      media.addEventListener("change", () => { if (choice === "system") apply(); });
    } else if (typeof media.addListener === "function") {
      media.addListener(() => { if (choice === "system") apply(); });
    }
  }

  function mount() {
    if (document.getElementById("site-appearance-control")) return;
    const toolbar = document.createElement("div");
    toolbar.id = "site-appearance-control";
    toolbar.className = "site-appearance-control";
    toolbar.setAttribute("role", "group");
    toolbar.setAttribute("aria-label", "Site appearance");
    const label = document.createElement("span");
    label.className = "site-appearance-label";
    label.textContent = "Appearance";
    toolbar.append(label);
    for (const [value, caption] of [["system", "Auto"], ["light", "Light"], ["dark", "Dark"]]) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "site-appearance-button";
      button.setAttribute("data-appearance-choice", value);
      button.setAttribute("aria-label", value === "system" ? "Follow system appearance" : "Use " + value + " appearance");
      button.textContent = caption;
      button.addEventListener("click", () => {
        choice = value;
        try { window.localStorage.setItem(key, value); } catch (_) { /* session still works */ }
        apply();
      });
      toolbar.append(button);
    }
    document.body.append(toolbar);
    apply();
  }
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", mount, { once: true });
  } else {
    mount();
  }
})();
