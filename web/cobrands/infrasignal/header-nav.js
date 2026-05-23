/**
 * InfraSignal — Header navigation & mobile interactions
 * Hamburger menu toggle, language switcher portal, mobile tab-bar active state,
 * header scroll shadow
 */
(function () {
  'use strict';

  /* ── Header Scroll Effect ── */
  var header = document.getElementById('site-header');
  if (header) {
    var scrolled = false;
    window.addEventListener('scroll', function () {
      var isScrolled = window.scrollY > 10;
      if (isScrolled !== scrolled) {
        scrolled = isScrolled;
        if (scrolled) {
          header.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.15)';
        } else {
          header.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.1)';
        }
      }
    }, { passive: true });
  }

  /* ── Hamburger Menu ── */
  var hamburger = document.querySelector('.header-hamburger');
  var mobileMenu = document.querySelector('.header-mobile-menu');

  if (hamburger && mobileMenu) {
    hamburger.addEventListener('click', function () {
      var expanded = hamburger.getAttribute('aria-expanded') === 'true';
      hamburger.setAttribute('aria-expanded', String(!expanded));
      hamburger.classList.toggle('is-open');
      mobileMenu.classList.toggle('is-open');
    });

    // Close mobile menu when clicking a link
    mobileMenu.querySelectorAll('a').forEach(function (link) {
      link.addEventListener('click', function () {
        hamburger.setAttribute('aria-expanded', 'false');
        hamburger.classList.remove('is-open');
        mobileMenu.classList.remove('is-open');
      });
    });
  }

  /* Focus the address form when report CTAs point to the homepage form. */
  function focusReportAddressForm() {
    var form = document.getElementById('postcodeForm');
    var input = document.getElementById('pc');
    if (!form || !input) return false;

    try {
      form.scrollIntoView({ behavior: 'smooth', block: 'center' });
    } catch (e) {
      form.scrollIntoView();
    }
    window.setTimeout(function () {
      try {
        input.focus({ preventScroll: true });
      } catch (e) {
        input.focus();
      }
    }, 250);
    return true;
  }

  document.querySelectorAll('a[href="/#postcodeForm"], a[href="#postcodeForm"]').forEach(function (link) {
    link.addEventListener('click', function (event) {
      var url = new URL(link.href, window.location.href);
      var currentPath = window.location.pathname.replace(/\/+$/, '') || '/';
      var linkPath = url.pathname.replace(/\/+$/, '') || '/';
      if (url.hash === '#postcodeForm' && linkPath === currentPath && focusReportAddressForm()) {
        event.preventDefault();
        if (window.history && window.history.pushState) {
          window.history.pushState(null, '', '#postcodeForm');
        } else {
          window.location.hash = 'postcodeForm';
        }
      }
    });
  });

  if (window.location.hash === '#postcodeForm') {
    window.setTimeout(focusReportAddressForm, 150);
  }

  /* ── Language Switcher Portal ── */
  var langBtn = document.querySelector('#lang-switcher-header .lang-dd__btn');
  if (langBtn) {
    var langs = [
      { code: 'en-gb', flag: '/cobrands/infrasignal/flags/en.svg', label: 'EN' },
      { code: 'es',    flag: '/cobrands/infrasignal/flags/es.svg', label: 'ES' },
      { code: 'ru',    flag: '/cobrands/infrasignal/flags/ru.svg', label: 'RU' },
      { code: 'tr',    flag: '/cobrands/infrasignal/flags/tr.svg', label: 'TR' }
    ];

    var curLang = document.documentElement.lang || 'en-gb';

    var portal = document.createElement('ul');
    portal.className = 'lang-dd__portal';
    portal.style.cssText =
      'display:none;position:fixed;margin:0;padding:4px 0;background:#fff;' +
      'border:1px solid rgba(0,0,0,0.12);border-radius:5px;' +
      'box-shadow:0 4px 12px rgba(0,0,0,0.15);list-style:none;z-index:99999;min-width:90px';

    langs.forEach(function (l) {
      var li = document.createElement('li');
      li.style.cssText = 'margin:0;padding:0;list-style:none;display:block';
      if (l.code === curLang) li.className = 'lang-dd--sel';

      var a = document.createElement('a');
      a.href = '?lang=' + l.code;
      a.style.cssText =
        'display:flex;align-items:center;gap:8px;padding:7px 14px;color:#333;' +
        'text-decoration:none;font-size:13px;font-weight:600;white-space:nowrap;transition:background-color 0.1s';
      a.innerHTML =
        '<img src="' + l.flag +
        '" style="width:18px;height:18px;border-radius:50%;object-fit:cover;border:1px solid rgba(0,0,0,0.12)" alt="">' +
        l.label;

      a.onmouseenter = function () { a.style.backgroundColor = '#f0f4ff'; };
      a.onmouseleave = function () { a.style.backgroundColor = ''; };
      if (l.code === curLang) a.style.backgroundColor = '#e8edf5';

      li.appendChild(a);
      portal.appendChild(li);
    });

    document.body.appendChild(portal);
    var isOpen = false;

    function positionPortal() {
      var r = langBtn.getBoundingClientRect();
      portal.style.top = (r.bottom + 4) + 'px';
      portal.style.left = r.left + 'px';
    }

    langBtn.addEventListener('click', function (e) {
      e.stopPropagation();
      isOpen = !isOpen;
      portal.style.display = isOpen ? 'block' : 'none';
      langBtn.setAttribute('aria-expanded', String(isOpen));
      if (isOpen) positionPortal();
    });

    document.addEventListener('click', function () {
      if (isOpen) {
        isOpen = false;
        portal.style.display = 'none';
        langBtn.setAttribute('aria-expanded', 'false');
      }
    });
  }

  /* ── Mobile Tab Bar — active state ── */
  var tabBar = document.querySelector('.mobile-tab-bar');
  if (tabBar) {
    var path = window.location.pathname;
    tabBar.querySelectorAll('.mobile-tab-bar__item').forEach(function (item) {
      var link = item.querySelector('a');
      if (!link) return;
      var href = link.getAttribute('href');
      if (href === '/' && path === '/') {
        item.classList.add('is-active');
      } else if (href !== '/' && path.indexOf(href) === 0) {
        item.classList.add('is-active');
      }
    });
  }
})();
