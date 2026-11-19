/* MSroofing – main.js (bez závislostí) */
(function () {
  'use strict';
  var doc = document, root = doc.documentElement;
  root.classList.add('js');
  var I18N = {
    cs: { open: 'Otevřít menu', close: 'Zavřít menu', sending: 'Odesílám…' },
    de: { open: 'Menü öffnen', close: 'Menü schließen', sending: 'Wird gesendet…' },
    en: { open: 'Open menu', close: 'Close menu', sending: 'Sending…' }
  };
  var T = I18N[(root.lang || 'cs').slice(0, 2)] || I18N.cs;

  /* ---------- Header: stín při scrollu ---------- */
  var header = doc.querySelector('.site-header');
  function onScrollHeader() { header.classList.toggle('is-scrolled', window.scrollY > 8); }
  window.addEventListener('scroll', onScrollHeader, { passive: true });
  onScrollHeader();

  /* ---------- Hero video: šetrné přehrávání ---------- */
  var heroVideo = doc.querySelector('.hero-video');
  if (heroVideo) {
    var saveData = navigator.connection && navigator.connection.saveData;
    var noMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (saveData || noMotion) {
      heroVideo.removeAttribute('autoplay');
      heroVideo.preload = 'none';
      heroVideo.pause();
    } else {
      var tryPlay = function () { var p = heroVideo.play(); if (p && p.catch) p.catch(function () {}); };
      if ('IntersectionObserver' in window) {
        new IntersectionObserver(function (entries) {
          if (entries[0].isIntersecting) tryPlay(); else heroVideo.pause();
        }).observe(heroVideo);
      } else { tryPlay(); }
    }
  }

  /* ---------- Mobilní menu ---------- */
  var toggle = doc.querySelector('.nav-toggle');
  var nav = doc.getElementById('primary-nav');
  function setMenu(open) {
    toggle.setAttribute('aria-expanded', String(open));
    toggle.setAttribute('aria-label', open ? T.close : T.open);
    root.classList.toggle('menu-open', open);
  }
  toggle.addEventListener('click', function () { setMenu(toggle.getAttribute('aria-expanded') !== 'true'); });
  nav.addEventListener('click', function (e) { if (e.target.closest('a')) setMenu(false); });
  doc.addEventListener('keydown', function (e) { if (e.key === 'Escape') setMenu(false); });
  window.matchMedia('(min-width: 1200px)').addEventListener('change', function (m) { if (m.matches) setMenu(false); });

  /* ---------- Skladba střechy: izometrické ilustrace ---------- */
  var fig = doc.getElementById('stack-figure');
  if (fig) {
    var C = 0.866, S = 0.5, W = 300, D = 220;
    var bounds = { x0: 1e9, y0: 1e9, x1: -1e9, y1: -1e9 }, OFF = 0;
    var P = function (x, y, z) {
      var q = [(x - y) * C, (x + y) * S - z];
      var sy = q[1] - OFF;
      if (q[0] < bounds.x0) bounds.x0 = q[0]; if (q[0] > bounds.x1) bounds.x1 = q[0];
      if (sy < bounds.y0) bounds.y0 = sy; if (sy > bounds.y1) bounds.y1 = sy;
      return q;
    };
    var pts = function (a) { return a.map(function (q) { return q[0].toFixed(1) + ',' + q[1].toFixed(1); }).join(' '); };
    var shade = function (hex, f) {
      var n = parseInt(hex.slice(1), 16);
      var r = Math.min(255, Math.round((n >> 16) * f)), g = Math.min(255, Math.round(((n >> 8) & 255) * f)), b = Math.min(255, Math.round((n & 255) * f));
      return '#' + ((1 << 24) | (r << 16) | (g << 8) | b).toString(16).slice(1);
    };
    var poly = function (a, fill) { return '<polygon points="' + pts(a) + '" fill="' + fill + '"/>'; };
    var box = function (x, y, z, w, d, h, col) {
      var top = [P(x, y, z + h), P(x + w, y, z + h), P(x + w, y + d, z + h), P(x, y + d, z + h)];
      var left = [P(x, y + d, z), P(x + w, y + d, z), P(x + w, y + d, z + h), P(x, y + d, z + h)];
      var right = [P(x + w, y, z), P(x + w, y + d, z), P(x + w, y + d, z + h), P(x + w, y, z + h)];
      return poly(left, shade(col, 0.8)) + poly(right, shade(col, 0.66)) + poly(top, col);
    };
    var line = function (a, b, stroke, w, dash) {
      return '<line x1="' + a[0].toFixed(1) + '" y1="' + a[1].toFixed(1) + '" x2="' + b[0].toFixed(1) + '" y2="' + b[1].toFixed(1) +
        '" stroke="' + stroke + '" stroke-width="' + (w || 1) + '"' + (dash ? ' stroke-dasharray="' + dash + '"' : '') + '/>';
    };
    // šikmý trám v rovině y–z (krokev): spodní hrana z (y1,z1) do (y2,z2), šířka w ve směru x, výška t
    var beam = function (x, w, y1, z1, y2, z2, t, col) {
      var dy = y2 - y1, dz = z2 - z1, L = Math.sqrt(dy * dy + dz * dz);
      var ny = -dz / L * t, nz = dy / L * t;
      if (nz < 0) { ny = -ny; nz = -nz; }
      var A = [y1, z1], B = [y2, z2], Cc = [y2 + ny, z2 + nz], Dd = [y1 + ny, z1 + nz];
      var side = [P(x + w, A[0], A[1]), P(x + w, B[0], B[1]), P(x + w, Cc[0], Cc[1]), P(x + w, Dd[0], Dd[1])];
      var top = [P(x, Dd[0], Dd[1]), P(x, Cc[0], Cc[1]), P(x + w, Cc[0], Cc[1]), P(x + w, Dd[0], Dd[1])];
      return poly(side, shade(col, 0.7)) + poly(top, col);
    };

    /* společné vrstvy */
    var rafters = function () { var s = ''; for (var i = 0; i < 6; i++) s += box(i * (W - 16) / 5, 0, 0, 16, D, 22, '#C89B62'); return s; };
    var insulation = function () { var s = box(0, 0, 0, W, D, 16, '#E4C463'); for (var i = 12; i < W; i += 12) s += line(P(i, 0, 16), P(i, D, 16), 'rgba(255,255,255,.28)', 1); return s; };
    var membrane = function () { var s = box(0, 0, 0, W, D, 3, '#D6DEE3'); for (var j = 30; j < D; j += 38) s += line(P(0, j, 3), P(W, j, 3), '#8FA5B5', 1.2, '10 8'); return s; };
    var counter = function () { var s = ''; for (var i = 0; i < 6; i++) s += box(i * (W - 16) / 5 + 3, 0, 0, 10, D, 9, '#A87B4A'); return s; };
    var battens = function (step) { var s = ''; for (var j = 6; j <= D - 10; j += step) s += box(0, j, 0, W, 10, 8, '#D6AA70'); return s; };
    var tiles = function (col, rowCol, jointCol) {
      var s = box(0, 0, 0, W, D, 10, col);
      for (var j = 0, i = 0; j < D; j += 22, i++) {
        if (j > 0) s += line(P(0, j, 10), P(W, j, 10), rowCol, 1.4);
        for (var x = (i % 2) * 15 + 15; x < W; x += 30) s += line(P(x, j, 10), P(x, Math.min(j + 22, D), 10), jointCol, 1);
      }
      return s;
    };
    var flashingSet = function () { return box(-4, -6, 6, W + 8, 18, 9, '#9EA6AB') + box(W - 2, 0, 3, 8, D, 9, '#AEB5BA') + box(-4, D - 2, -10, W + 8, 12, 12, '#BCC3C8'); };

    var STACKS = {
      pitched: { gap: 44, layers: [rafters, insulation, membrane, counter, function () { return battens(26); },
        function () { return tiles('#2F3439', '#50575E', '#454B51'); }, flashingSet] },

      tile: { gap: 44, layers: [rafters, membrane, counter, function () { return battens(26); },
        function () { return tiles('#B4552F', '#8A3B1E', '#9C4626'); },
        function () {
          var s = box(-4, -6, 8, W + 8, 18, 12, '#9A4527');
          for (var x = 30; x < W; x += 30) s += line(P(x, -6, 20), P(x, 12, 20), '#7A341C', 1.2);
          return s + box(-4, 0, 2, W + 8, 6, 6, '#3B3F43');
        }] },

      metal: { gap: 44, layers: [rafters, membrane, counter, function () { return battens(36); },
        function () {
          var s = box(0, 0, 0, W, D, 8, '#3B4248'), j, x;
          for (j = 35; j < D; j += 35) s += line(P(0, j, 8), P(W, j, 8), '#262B30', 2);
          for (x = 25; x < W; x += 25) s += line(P(x, 0, 8), P(x, D, 8), '#5D666E', 1.6);
          return s;
        }, flashingSet] },

      shingle: { gap: 44, layers: [rafters,
        function () { var s = box(0, 0, 0, W, D, 8, '#CDA56E'); for (var j = 22; j < D; j += 22) s += line(P(0, j, 8), P(W, j, 8), '#A9844F', 1.2); return s; },
        function () { var s = box(0, 0, 0, W, D, 3, '#3A3D40'); for (var j = 55; j < D; j += 55) s += line(P(0, j, 3), P(W, j, 3), '#5A5E62', 1.2, '12 6'); return s; },
        function () { return box(W - 10, 0, 0, 12, D, 4, '#AEB5BA') + box(-3, D - 10, 0, W + 6, 12, 4, '#B9C0C5'); },
        function () {
          var s = box(0, 0, 0, W, D, 6, '#6B4F45');
          for (var j = 0, i = 0; j < D; j += 18, i++) {
            if (j > 0) s += line(P(0, j, 6), P(W, j, 6), '#4E3832', 1.4);
            for (var x = (i % 2) * 12 + 12; x < W; x += 24) s += line(P(x, j, 6), P(x, Math.min(j + 10, D), 6), '#57403A', 1);
          }
          return s;
        },
        function () { return box(-4, -6, 4, W + 8, 18, 10, '#5A433B') + box(-4, 4, 1, W + 8, 4, 4, '#2E2F31'); }] },

      flat: { gap: 44, layers: [
        function () { return box(0, 0, 0, W, D, 22, '#A7A9A4'); },
        function () { var s = box(0, 0, 0, W, D, 3, '#5F7486'); for (var j = 50; j < D; j += 50) s += line(P(0, j, 3), P(W, j, 3), '#7D91A2', 1.2); return s; },
        function () {
          var s = box(0, 0, 0, W, D, 26, '#ECECE6'), x, j;
          for (x = 60; x < W; x += 60) s += line(P(x, 0, 26), P(x, D, 26), '#C9C9C0', 1.2);
          for (j = 55; j < D; j += 55) s += line(P(0, j, 26), P(W, j, 26), '#C9C9C0', 1.2);
          return s;
        },
        function () { return box(0, 0, 0, W, D, 3, '#2C2E30'); },
        function () { var s = box(0, 0, 0, W, D, 4, '#5B5E61'); for (var j = 48; j < D; j += 48) s += line(P(0, j, 4), P(W, j, 4), '#7C8083', 1.6); return s; },
        function () {
          return box(0, 0, 0, W, 14, 30, '#B8BDB9') + box(-3, -3, 30, W + 6, 20, 4, '#C3CACF') +
                 box(W - 14, 14, 0, 14, D - 14, 30, '#B8BDB9') + box(W - 17, 14, 30, 20, D - 11, 4, '#C3CACF');
        }] },

      truss: (function () {
        var H = 105, Z0 = 26, xs = [], i;
        for (i = 0; i < 6; i++) xs.push(i * (W - 14) / 5);
        return { gap: 0, anchors: [[W, D - 7, 6], [W, D * 0.82, 20], [W, D * 0.78, Z0 + H * 0.3], [W, D / 2, Z0 + H - 6], [xs[4] + 22, D * 0.62, Z0 + H * 0.58]],
          layers: [
            function () { return box(0, 0, 0, W, 14, 12, '#B98A55') + box(0, D - 14, 0, W, 14, 12, '#B98A55'); },
            function () { var s = ''; xs.forEach(function (x) { s += box(x, 0, 12, 14, D, 14, '#C89B62'); }); return s; },
            function () { var s = ''; xs.forEach(function (x) { s += beam(x, 14, 0, Z0, D / 2, Z0 + H, 16, '#D2A66C') + beam(x, 14, D, Z0, D / 2, Z0 + H, 16, '#D2A66C'); }); return s; },
            function () { return box(0, D / 2 - 8, Z0 + H - 18, W, 16, 16, '#B07E48'); },
            function () {
              var s = '', h = H * 0.55, y1 = h / H * (D / 2) + 4, y2 = D - y1;
              for (var k = 0; k < 5; k++) s += box(xs[k] + 14, y1, Z0 + h, 8, y2 - y1, 12, '#A87B4A');
              return s;
            }] };
      })(),

      flashing: { gap: 0, anchors: [[W * 0.78, D * 0.32, 10], [W, 3, 15], [W + 6, D * 0.55, 12], [W * 0.25, D + 8, 9], [W * 0.55, D + 20, -6], [W - 14, D + 18, -96], [164, 114, 58]],
        layers: [
          function () { return tiles('#2F3439', '#50575E', '#454B51'); },
          function () { return box(-4, -6, 6, W + 8, 16, 9, '#9EA6AB'); },
          function () { return box(W - 2, -2, 4, 8, D + 4, 10, '#AEB5BA'); },
          function () { return box(-4, D - 2, 6, W + 8, 10, 3, '#B9C0C5'); },
          function () {
            var s = '';
            for (var x = 20; x < W; x += 56) s += box(x, D + 2, -6, 5, 14, 4, '#7E878D');
            s += box(-6, D + 4, -14, W + 12, 18, 12, '#C3CACF');
            s += poly([P(-3, D + 7, -2), P(W + 3, D + 7, -2), P(W + 3, D + 19, -2), P(-3, D + 19, -2)], '#8C959B');
            return s;
          },
          function () { return box(W - 27, D + 6, -20, 15, 15, 8, '#B3BABF') + box(W - 24, D + 9, -150, 9, 9, 132, '#BCC3C8') + box(W - 26, D + 7, -156, 13, 13, 8, '#AEB5BA'); },
          function () {
            return box(114, 64, 10, 56, 56, 6, '#B9C0C5') + box(120, 70, 10, 44, 44, 72, '#9C5B45') +
              line(P(164, 70, 30), P(164, 114, 30), '#7E4636', 1) + line(P(164, 70, 50), P(164, 114, 50), '#7E4636', 1) +
              box(116, 66, 82, 52, 52, 5, '#8A8F93');
          }] }
    };

    var type = fig.getAttribute('data-stack') || 'pitched';
    var cfg = STACKS[type] || STACKS.pitched;
    var tipDefault = [W, D, 0];
    var body = '';
    cfg.layers.forEach(function (fn, k) {
      OFF = k * cfg.gap;
      var content = fn();
      var a = (cfg.anchors && cfg.anchors[k]) || tipDefault;
      var t = P(a[0], a[1], a[2]);
      var mx = t[0] + 44, my = t[1] + 2;
      bounds.x1 = Math.max(bounds.x1, mx + 13); bounds.y0 = Math.min(bounds.y0, my - OFF - 13); bounds.y1 = Math.max(bounds.y1, my - OFF + 13);
      body += '<g transform="translate(0,' + (-OFF) + ')"><g class="ly" data-i="' + k + '">' + content +
        '<g class="mk" stroke="none"><line x1="' + (t[0] + 4).toFixed(1) + '" y1="' + my.toFixed(1) + '" x2="' + (mx - 12).toFixed(1) + '" y2="' + my.toFixed(1) + '" stroke="#9a9d98" stroke-width="1"/>' +
        '<circle cx="' + mx.toFixed(1) + '" cy="' + my.toFixed(1) + '" r="11"/>' +
        '<text x="' + mx.toFixed(1) + '" y="' + (my + 4).toFixed(1) + '" text-anchor="middle">' + (k + 1) + '</text></g></g></g>';
    });
    var pad = 14, vbW = bounds.x1 - bounds.x0 + pad * 2, vbH = bounds.y1 - bounds.y0 + pad * 2 + 40;
    fig.innerHTML = '<svg viewBox="' + (bounds.x0 - pad).toFixed(0) + ' ' + (bounds.y0 - pad - 40).toFixed(0) + ' ' + vbW.toFixed(0) + ' ' + vbH.toFixed(0) +
      '" role="presentation" focusable="false" xmlns="http://www.w3.org/2000/svg"><g stroke="rgba(0,0,0,.18)" stroke-width=".6" stroke-linejoin="round">' + body + '</g></svg>';

    var section = fig.closest('section');
    var grid = fig.closest('.stack-grid');
    var sticky = fig.closest('.stack-sticky');
    var items = [].slice.call(doc.querySelectorAll('.layer-list .layer-item'));
    var lyEls = [].slice.call(fig.querySelectorAll('.ly'));
    var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    var current = -2;
    section.classList.add('is-animated');

    // Mobil: pevná „scéna“ – schéma, ukazatel postupu a popis aktuální vrstvy.
    // Seznam pod ní slouží jen jako dráha pro scroll, popisy se jen prolínají.
    var dotsBox = sticky.querySelector('.stack-dots');
    var capBox = sticky.querySelector('.stack-caption');
    var dots = [], caps = [];
    if (!reduce && dotsBox && capBox) {
      items.forEach(function (li, k) {
        var dot = doc.createElement('i'); dotsBox.appendChild(dot); dots.push(dot);
        var cap = doc.createElement('div'); cap.className = 'cap';
        cap.innerHTML = '<span class="layer-num">' + (k + 1) + '</span><div><b></b><p></p></div>';
        cap.querySelector('b').textContent = li.querySelector('h3').textContent;
        cap.querySelector('p').textContent = li.querySelector('p').textContent;
        capBox.appendChild(cap); caps.push(cap);
      });
      section.classList.add('is-stage');
    }
    var stageMq = window.matchMedia('(max-width: 699px) and (min-height: 520px)');

    var setActive = function (a) {
      if (a === current) return;
      current = a;
      lyEls.forEach(function (el, k) { el.classList.toggle('on', k <= a); el.classList.toggle('cur', k === a); });
      items.forEach(function (el, k) { el.classList.toggle('active', k === a); el.classList.toggle('done', k < a); });
      dots.forEach(function (el, k) { el.classList.toggle('on', k <= a); });
      caps.forEach(function (el, k) { el.classList.toggle('on', k === a); el.classList.toggle('done', k < a); });
    };
    if (reduce) { setActive(items.length - 1); }
    else {
      var ticking = false;
      var update = function () {
        ticking = false;
        var a = -1;
        if (caps.length && stageMq.matches) {
          // podle toho, jak daleko je scéna „přišpendlená“
          var top = parseFloat(getComputedStyle(sticky).top) || 0;
          var run = grid.offsetHeight - sticky.offsetHeight;
          var p = run > 0 ? (top - grid.getBoundingClientRect().top) / run : 0;
          a = Math.floor(p * items.length);
          setActive(Math.min(items.length - 1, Math.max(0, a)));
          return;
        }
        var refLine = window.innerHeight * (window.innerWidth < 700 ? 0.72 : 0.55);
        for (var n = 0; n < items.length; n++) if (items[n].getBoundingClientRect().top < refLine) a = n;
        setActive(Math.max(0, a));
      };
      window.addEventListener('scroll', function () { if (!ticking) { ticking = true; requestAnimationFrame(update); } }, { passive: true });
      window.addEventListener('resize', update);
      update();
    }
  }

  /* ---------- Reference: lightbox ---------- */
  var cards = [].slice.call(doc.querySelectorAll('.ref-card'));
  var dlg = doc.getElementById('lightbox');
  if (dlg && cards.length && typeof dlg.showModal === 'function') {
    var lbImg = dlg.querySelector('img'), lbCap = dlg.querySelector('.lb-caption'), lbIdx = 0;
    var show = function (card) {
      var img = card.querySelector('img');
      lbImg.src = img.dataset.full || img.currentSrc || img.src; lbImg.alt = img.alt;
      lbCap.textContent = card.querySelector('h3').textContent + ' — ' + card.querySelector('.ref-tag').textContent;
    };
    cards.forEach(function (card, i) {
      card.querySelector('.ref-open').addEventListener('click', function () { lbIdx = i; show(card); dlg.showModal(); });
    });
    var step = function (d) { lbIdx = (lbIdx + d + cards.length) % cards.length; show(cards[lbIdx]); };
    dlg.querySelector('.lb-prev').addEventListener('click', function () { step(-1); });
    dlg.querySelector('.lb-next').addEventListener('click', function () { step(1); });
    dlg.querySelector('.lb-close').addEventListener('click', function () { dlg.close(); });
    dlg.addEventListener('click', function (e) { if (e.target === dlg) dlg.close(); });
    dlg.addEventListener('keydown', function (e) { if (e.key === 'ArrowLeft') step(-1); if (e.key === 'ArrowRight') step(1); });
    var tx = null;
    dlg.addEventListener('touchstart', function (e) { tx = e.touches[0].clientX; }, { passive: true });
    dlg.addEventListener('touchend', function (e) { if (tx === null) return; var dx = e.changedTouches[0].clientX - tx; if (Math.abs(dx) > 50) step(dx < 0 ? 1 : -1); tx = null; });
  }

  /* ---------- Formulář ---------- */
  var form = doc.getElementById('contactForm');
  if (form) {
    form.addEventListener('submit', function (e) {
      if (form.website && form.website.value) { e.preventDefault(); return; }
      if (!form.checkValidity()) {
        e.preventDefault();
        form.classList.add('was-validated');
        var bad = form.querySelector(':invalid');
        if (bad) bad.focus();
        return;
      }
      var btn = form.querySelector('[type=submit]');
      btn.disabled = true; btn.textContent = T.sending;
    });
  }

  /* ---------- Cookies (Consent Mode v2) ---------- */
  var bar = doc.getElementById('cookieBar');
  var stored = null;
  try { stored = localStorage.getItem('msr_consent'); } catch (e) {}
  var grant = function (ok) {
    if (typeof window.gtag === 'function') {
      var v = ok ? 'granted' : 'denied';
      window.gtag('consent', 'update', { ad_storage: v, analytics_storage: v, ad_user_data: v, ad_personalization: v });
    }
  };
  if (stored) { grant(stored === 'granted'); }
  else if (bar) { bar.hidden = false; }
  if (bar) {
    bar.addEventListener('click', function (e) {
      var b = e.target.closest('[data-consent]');
      if (!b) return;
      var v = b.dataset.consent;
      try { localStorage.setItem('msr_consent', v); } catch (err) {}
      grant(v === 'granted');
      bar.hidden = true;
    });
  }

  /* ---------- Rok v patičce ---------- */
  var y = doc.getElementById('year'); if (y) y.textContent = new Date().getFullYear();
})();
