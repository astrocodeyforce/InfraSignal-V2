// Hero pulse background for the InfraSignal homepage.
// Progressive enhancement: if JavaScript is unavailable, the hero remains fully usable.
(function () {
  "use strict";

  var PULSE_MS = 4000;
  var MAX_PULSES = 2;
  var SPAWN_MIN = 6000;
  var SPAWN_RAND = 6000;
  var CELL = 20;
  var EDGE_PROB = 0.55;
  var EXCL_PAD = 0.02;

  function buildGrid(vbW, vbH) {
    var cols = Math.ceil(vbW / CELL);
    var rows = Math.ceil(vbH / CELL);
    var lines = [];
    var c;
    var r;

    for (r = 0; r <= rows; r++) {
      for (c = 0; c <= cols; c++) {
        var x = c * CELL;
        var y = r * CELL;

        if (Math.random() < EDGE_PROB) {
          lines.push('<line x1="' + x + '" y1="' + y + '" x2="' + (x + CELL) + '" y2="' + y + '"/>');
        }

        if (Math.random() < EDGE_PROB) {
          lines.push('<line x1="' + x + '" y1="' + y + '" x2="' + x + '" y2="' + (y + CELL) + '"/>');
        }
      }
    }

    var verts = [];
    var horizs = [];
    for (c = 0; c <= cols; c++) verts.push(c * CELL);
    for (r = 0; r <= rows; r++) horizs.push(r * CELL);

    var svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ' + vbW + ' ' + vbH +
      '" preserveAspectRatio="xMidYMid slice" aria-hidden="true">' +
      '<g stroke="rgba(255,255,255,0.55)" stroke-width="0.75" stroke-linecap="square">' +
      lines.join("") + '</g></svg>';

    return { svg: svg, verts: verts, horizs: horizs };
  }

  function init(root) {
    if (window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    var vbW = parseInt(root.dataset.vbW, 10) || 1000;
    var vbH = parseInt(root.dataset.vbH, 10) || 700;
    var grid = buildGrid(vbW, vbH);
    var parent = root.parentElement;
    var exclusions = [];
    var visible = true;
    var onScreen = true;
    var timer = null;

    if (!parent) return;

    function recomputeExclusions() {
      var cRect = root.getBoundingClientRect();
      if (!cRect.width || !cRect.height) return;

      var els = parent.querySelectorAll("[data-hero-exclude]");
      var next = [];
      for (var i = 0; i < els.length; i++) {
        var rect = els[i].getBoundingClientRect();
        if (!rect.width || !rect.height) continue;

        next.push({
          x1: Math.max(0, (rect.left - cRect.left) / cRect.width - EXCL_PAD),
          x2: Math.min(1, (rect.right - cRect.left) / cRect.width + EXCL_PAD),
          y1: Math.max(0, (rect.top - cRect.top) / cRect.height - EXCL_PAD),
          y2: Math.min(1, (rect.bottom - cRect.top) / cRect.height + EXCL_PAD)
        });
      }
      exclusions = next;
    }

    function inExclusion(x, y) {
      var xp = x / vbW;
      var yp = y / vbH;
      for (var i = 0; i < exclusions.length; i++) {
        var zone = exclusions[i];
        if (xp >= zone.x1 && xp <= zone.x2 && yp >= zone.y1 && yp <= zone.y2) return true;
      }
      return false;
    }

    function renderPing(x, y) {
      var xPct = (x / vbW) * 100 + "%";
      var yPct = (y / vbH) * 100 + "%";
      var ping = document.createElement("div");
      var reveal = document.createElement("div");
      var core = document.createElement("span");

      ping.className = "hero-pulse__ping";
      ping.style.setProperty("--px", xPct);
      ping.style.setProperty("--py", yPct);

      reveal.className = "hero-pulse__reveal";
      reveal.innerHTML = grid.svg;

      core.className = "hero-pulse__core";

      ping.appendChild(reveal);
      ping.appendChild(core);
      root.appendChild(ping);

      setTimeout(function () { ping.remove(); }, PULSE_MS);
    }

    function schedule() {
      if (timer) clearTimeout(timer);
      timer = setTimeout(spawn, SPAWN_MIN + Math.random() * SPAWN_RAND);
    }

    function update() {
      if (visible && onScreen) schedule();
      else if (timer) {
        clearTimeout(timer);
        timer = null;
      }
    }

    function spawn() {
      var active = root.querySelectorAll(".hero-pulse__ping").length;
      if (active < MAX_PULSES) {
        var x = 0;
        var y = 0;
        var ok = false;
        for (var i = 0; i < 12; i++) {
          x = grid.verts[Math.floor(Math.random() * grid.verts.length)];
          y = grid.horizs[Math.floor(Math.random() * grid.horizs.length)];
          if (!inExclusion(x, y)) {
            ok = true;
            break;
          }
        }
        if (ok) renderPing(x, y);
      }
      schedule();
    }

    recomputeExclusions();

    if ("ResizeObserver" in window) {
      var ro = new ResizeObserver(recomputeExclusions);
      ro.observe(parent);
      var excluded = parent.querySelectorAll("[data-hero-exclude]");
      for (var i = 0; i < excluded.length; i++) ro.observe(excluded[i]);
    }
    window.addEventListener("resize", recomputeExclusions);

    document.addEventListener("visibilitychange", function () {
      visible = document.visibilityState !== "hidden";
      update();
    });

    if ("IntersectionObserver" in window) {
      new IntersectionObserver(function (entries) {
        onScreen = entries[0].isIntersecting;
        update();
      }, { threshold: 0.05 }).observe(root);
    }

    schedule();
  }

  function boot() {
    var roots = document.querySelectorAll("[data-hero-pulse]");
    for (var i = 0; i < roots.length; i++) init(roots[i]);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
}());