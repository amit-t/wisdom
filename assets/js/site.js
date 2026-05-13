(function () {
  'use strict';

  // ===== EMBED MODE =====
  // When loaded inside amittiwari.me (?embed=1) we hide nav/footer/theme
  // switcher, accept the parent theme via query param + postMessage, and
  // preserve the embed flag across internal navigation so deep links stay
  // inside the embed.
  var params = new URLSearchParams(window.location.search);
  var EMBED = params.get('embed') === '1';
  var EMBED_PARENT_ORIGIN = 'https://amittiwari.me';

  if (EMBED) {
    document.documentElement.classList.add('embed');
    document.body.classList.add('embed');
  }

  // ===== THEME SELECTOR: light / dark / cyberpunk / solarized =====
  var THEME_KEY = 'wb-theme';
  var THEMES = ['light', 'dark', 'cyberpunk', 'solarized'];
  var body = document.body;
  var select = document.getElementById('theme-select');

  function apply(theme) {
    body.classList.remove('dark', 'cyberpunk', 'solarized');
    if (theme === 'dark') body.classList.add('dark');
    else if (theme === 'cyberpunk') body.classList.add('cyberpunk');
    else if (theme === 'solarized') body.classList.add('solarized');
    if (select && select.value !== theme) select.value = theme;
  }

  function readStored() {
    // Parent (amittiwari.me) wins over local storage in embed mode so the
    // chrome and the iframe always paint the same palette.
    if (EMBED) {
      var queryTheme = params.get('theme');
      if (THEMES.indexOf(queryTheme) !== -1) return queryTheme;
    }
    var s = localStorage.getItem(THEME_KEY);
    if (THEMES.indexOf(s) !== -1) return s;
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
      ? 'dark'
      : 'light';
  }

  apply(readStored());

  if (select) {
    select.addEventListener('change', function () {
      var next = select.value;
      if (THEMES.indexOf(next) === -1) return;
      localStorage.setItem(THEME_KEY, next);
      apply(next);
    });
  }

  // Live theme sync from the host page. Origin is validated so a stray
  // tab cannot push styles into this document.
  window.addEventListener('message', function (e) {
    if (e.origin !== EMBED_PARENT_ORIGIN && e.origin !== 'http://localhost:3000') return;
    var data = e.data || {};
    if (data.type !== 'wisdom:theme') return;
    if (THEMES.indexOf(data.theme) === -1) return;
    apply(data.theme);
  });

  // ===== EMBED LINK REWRITES =====
  // Preserve ?embed=1 (and the current theme) on every same-origin click
  // so the iframe never bounces into the standalone chrome.
  if (EMBED) {
    var currentTheme = readStored();
    document.addEventListener('click', function (e) {
      // Respect modifier-clicks and explicit target overrides.
      if (e.defaultPrevented || e.button !== 0) return;
      if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
      var a = e.target.closest && e.target.closest('a[href]');
      if (!a) return;
      if (a.target && a.target !== '' && a.target !== '_self') return;
      var href = a.getAttribute('href');
      if (!href || href.indexOf('#') === 0) return;
      var url;
      try {
        url = new URL(a.href, window.location.href);
      } catch (_) {
        return;
      }
      if (url.origin !== window.location.origin) return;
      if (!url.searchParams.has('embed')) url.searchParams.set('embed', '1');
      if (!url.searchParams.has('theme')) url.searchParams.set('theme', currentTheme);
      a.setAttribute('href', url.pathname + url.search + url.hash);
    });
  }

  // ===== COPY BUTTONS ON <pre> =====
  function attachCopyButtons() {
    var pres = document.querySelectorAll('.markdown-body pre');
    pres.forEach(function (pre) {
      if (pre.querySelector('.copy-btn')) return;
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'copy-btn';
      btn.setAttribute('aria-label', 'Copy code');
      btn.textContent = 'Copy';
      btn.addEventListener('click', function () {
        var code = pre.querySelector('code') || pre;
        var text = code.innerText;
        navigator.clipboard.writeText(text).then(function () {
          btn.textContent = 'Copied';
          btn.classList.add('copied');
          setTimeout(function () {
            btn.textContent = 'Copy';
            btn.classList.remove('copied');
          }, 1600);
        });
      });
      pre.appendChild(btn);
    });
  }
  attachCopyButtons();
})();

// Wisdom permalink: copy-link button
document.addEventListener('click', function (e) {
  var t = e.target;
  if (!t.classList || !t.classList.contains('wisdom-copy')) return;
  var url = t.getAttribute('data-clipboard');
  if (!url) return;
  navigator.clipboard.writeText(url).then(function () {
    var orig = t.textContent;
    t.textContent = 'Copied';
    setTimeout(function () { t.textContent = orig; }, 1200);
  });
});
