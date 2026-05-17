<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:georss="http://www.georss.org/georss">
  <xsl:output method="html" encoding="UTF-8" />
  <xsl:variable name="title" select="/rss/channel/title" />
  <xsl:variable name="uri" select="/rss/channel/atom:link/@href" />
  <xsl:variable name="site_link" select="/rss/channel/link" />
  <xsl:variable name="item_count" select="count(/rss/channel/item)" />

  <xsl:template match="/">
    <html>
      <head>
        <title><xsl:value-of select="$title" /> XML Feed</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <style type="text/css"><![CDATA[
          * { box-sizing: border-box; }
          html { min-width: 0; background: #f8f9fb; color: #111827; }
          body {
            margin: 0;
            min-width: 0;
            background: #f8f9fb;
            color: #111827;
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            font-size: 16px;
            line-height: 1.5;
          }
          a { color: inherit; }
          img { max-width: 100%; }
          .rss-shell { min-height: 100vh; background: #f8f9fb; }
          .rss-container {
            width: min(72rem, calc(100% - 32px));
            margin: 0 auto;
          }
          .rss-topbar {
            position: sticky;
            top: 0;
            z-index: 20;
            background: #1f3b63;
            box-shadow: 0 2px 12px rgba(15, 36, 68, 0.18);
          }
          .rss-topbar__inner {
            display: flex;
            min-height: 64px;
            align-items: center;
            justify-content: space-between;
            gap: 1rem;
          }
          .rss-brand {
            display: inline-flex;
            align-items: center;
            gap: 0.65rem;
            text-decoration: none;
          }
          .rss-brand img { display: block; width: 132px; height: auto; }
          .rss-nav {
            display: none;
            align-items: center;
            gap: 0.45rem;
          }
          .rss-nav a {
            display: inline-flex;
            align-items: center;
            min-height: 2.25rem;
            padding: 0 0.8rem;
            border-radius: 8px;
            color: #bfdbfe;
            font-size: 0.875rem;
            font-weight: 600;
            text-decoration: none;
          }
          .rss-nav a:hover,
          .rss-nav a.is-active { background: rgba(255, 255, 255, 0.12); color: #fff; }
          .rss-hero {
            position: relative;
            overflow: hidden;
            background: linear-gradient(135deg, #0f2444 0%, #1e40af 68%, #18338c 100%);
            color: #fff;
            text-align: center;
          }
          .rss-hero:before {
            content: "";
            position: absolute;
            inset: 0;
            background-image: radial-gradient(rgba(255,255,255,0.16) 1px, transparent 1px);
            background-size: 22px 22px;
            opacity: 0.42;
            pointer-events: none;
          }
          .rss-hero:after {
            content: none;
          }
          .rss-hero__inner {
            position: relative;
            z-index: 1;
            display: block;
            padding: 2rem 0 2.25rem;
          }
          .rss-hero__eyebrow,
          .rss-pill {
            display: inline-flex;
            align-items: center;
            gap: 0.4rem;
            width: fit-content;
            border-radius: 999px;
            font-size: 0.75rem;
            font-weight: 700;
            line-height: 1.2;
          }
          .rss-hero__eyebrow {
            padding: 0.3rem 0.75rem;
            border: 1px solid rgba(255,255,255,0.22);
            background: rgba(255,255,255,0.12);
            color: #fff;
          }
          .rss-hero__title {
            max-width: 42rem;
            margin: 0.75rem auto 0;
            color: #fff;
            font-size: clamp(1.625rem, 5vw, 2.125rem);
            line-height: 1.15;
            font-weight: 700;
            letter-spacing: 0;
          }
          .rss-hero__lead {
            max-width: 34rem;
            margin: 0.75rem auto 0;
            color: rgba(255,255,255,0.78);
            font-size: 0.9375rem;
            line-height: 1.6;
          }
          .rss-hero__actions {
            display: flex;
            flex-wrap: wrap;
            justify-content: center;
            gap: 0.75rem;
            margin-top: 1.25rem;
          }
          .rss-button {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 0.45rem;
            min-height: 2.35rem;
            padding: 0 0.85rem;
            border: 1px solid transparent;
            border-radius: 8px;
            font-size: 0.8125rem;
            font-weight: 700;
            text-decoration: none;
            cursor: pointer;
          }
          .rss-button--primary { background: #f97316; color: #fff; }
          .rss-button--primary:hover { background: #ea580c; }
          .rss-button--secondary { border-color: rgba(255,255,255,0.24); background: rgba(255,255,255,0.1); color: #fff; }
          .rss-button--secondary:hover { background: rgba(255,255,255,0.16); }
          .rss-hero__badge {
            display: none;
          }
          .rss-hero__badge strong,
          .rss-hero__badge span { display: block; }
          .rss-hero__badge strong { font-size: 2rem; line-height: 1; }
          .rss-hero__badge span { margin-top: 0.35rem; color: rgba(255,255,255,0.78); font-size: 0.8125rem; }
          .rss-body { padding: 2rem 0 4rem; background: #f8f9fb; }
          .rss-grid { display: flex; flex-direction: column; gap: 2.5rem; align-items: stretch; }
          .rss-side { display: none; }
          .rss-side__nav {
            position: static;
            display: grid;
            gap: 0.35rem;
          }
          .rss-side__title {
            display: none;
          }
          .rss-side__link {
            display: block;
            padding: 0.625rem 1rem;
            border-radius: 0.75rem;
            color: #64748b;
            font-size: 0.875rem;
            font-weight: 500;
            text-decoration: none;
          }
          .rss-side__link:hover,
          .rss-side__link.is-active { background: rgba(30, 64, 175, 0.08); color: #1e40af; }
          .rss-side__link.is-active { border-left: 3px solid #1e40af; font-weight: 600; }
          .rss-side__card {
            margin-top: 1.5rem;
            padding: 1rem;
            border: 1px solid #d9e1ec;
            border-radius: 0.75rem;
            background: #fff;
          }
          .rss-side__card-title { margin: 0; color: #111827; font-size: 0.9375rem; font-weight: 700; }
          .rss-side__card-sub { margin: 0.35rem 0 0.85rem; color: #64748b; font-size: 0.8125rem; line-height: 1.5; }
          .rss-main { display: flex; min-width: 0; max-width: 42rem; flex: 1 1 auto; flex-direction: column; gap: 1rem; }
          .rss-panel {
            border: 1px solid #d9e1ec;
            border-radius: 0.75rem;
            background: #fff;
            box-shadow: 0 1px 2px rgba(15, 36, 68, 0.04);
          }
          .rss-copy { padding: 1.25rem; }
          .rss-section-title { margin: 0; color: #111827; font-size: 1.125rem; font-weight: 700; line-height: 1.25; }
          .rss-section-sub { margin: 0.35rem 0 0; color: #64748b; font-size: 0.875rem; line-height: 1.6; }
          .rss-copy__row { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 0.65rem; margin-top: 1rem; }
          .rss-copy__input {
            width: 100%;
            min-width: 0;
            padding: 0.65rem 0.85rem;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            background: #f8f9fb;
            color: #111827;
            font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
            font-size: 0.8125rem;
          }
          .rss-copy__input:focus { outline: 3px solid rgba(30,64,175,0.16); border-color: #1e40af; }
          .rss-copy__button { width: auto; border: 0; background: #1e40af; color: #fff; }
          .rss-copy__button:hover { background: #18338c; }
          .rss-copy__button.is-copied { background: #047857; }
          .rss-reader-list {
            display: flex;
            flex-wrap: wrap;
            gap: 0.45rem;
            margin: 1rem 0 0;
            padding: 0;
            list-style: none;
          }
          .rss-reader-list a {
            display: inline-flex;
            align-items: center;
            min-height: 2rem;
            padding: 0 0.7rem;
            border: 1px solid #d9e1ec;
            border-radius: 999px;
            background: #fff;
            color: #4b5563;
            font-size: 0.75rem;
            font-weight: 600;
            text-decoration: none;
          }
          .rss-reader-list a:hover { border-color: #1e40af; color: #1e40af; background: #eef4ff; }
          .rss-items { padding: 1.25rem; }
          .rss-items__head {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 0.75rem;
            margin-bottom: 1rem;
          }
          .rss-pill { padding: 0.35rem 0.65rem; background: rgba(30,64,175,0.08); color: #1e40af; font-weight: 600; }
          .rss-list { display: grid; gap: 0.85rem; margin: 0; padding: 0; list-style: none; }
          .rss-item {
            position: relative;
            display: grid;
            gap: 0.85rem;
            padding: 1rem;
            border: 1px solid #d9e1ec;
            border-radius: 0.75rem;
            background: #fff;
          }
          .rss-item:before { content: none; }
          .rss-item__meta {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 0.5rem;
            color: #64748b;
            font-size: 0.75rem;
            font-weight: 500;
          }
          .rss-item__tag {
            display: inline-flex;
            align-items: center;
            padding: 0.18rem 0.55rem;
            border-radius: 999px;
            background: rgba(249,115,22,0.11);
            color: #ea580c;
            font-size: 0.6875rem;
            font-weight: 700;
            text-transform: uppercase;
          }
          .rss-item__title { margin: 0.45rem 0 0; color: #111827; font-size: 1rem; font-weight: 700; line-height: 1.3; }
          .rss-item__title a { color: inherit; text-decoration: none; }
          .rss-item__title a:hover { color: #1e40af; }
          .rss-item__summary {
            margin-top: 0.5rem;
            color: #4b5563;
            font-size: 0.9rem;
            line-height: 1.6;
          }
          .rss-item__summary br { display: none; }
          .rss-item__summary img {
            display: block;
            width: min(100%, 15rem);
            max-height: 10rem;
            object-fit: cover;
            margin: 0.85rem 0 0;
            border: 1px solid #d9e1ec;
            border-radius: 8px;
          }
          .rss-item__summary a { display: none; }
          .rss-item__open {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-height: 2.35rem;
            padding: 0 0.85rem;
            border: 1px solid #d9e1ec;
            border-radius: 0.75rem;
            color: #1e40af;
            font-size: 0.8125rem;
            font-weight: 600;
            text-decoration: none;
          }
          .rss-item__open:hover { background: #eef4ff; border-color: #1e40af; }
          .rss-empty {
            padding: 2.5rem 1.25rem;
            border: 1px dashed #cbd5e1;
            border-radius: 8px;
            text-align: center;
            color: #64748b;
          }
          .rss-footer { padding: 4rem 0 2rem; background: #0f2444; color: #bfdbfe; }
          .rss-footer__grid { display: grid; gap: 2rem; }
          .rss-footer__heading { margin: 0 0 1rem; color: #e0ecff; font-size: 0.875rem; font-weight: 800; letter-spacing: 0.08em; text-transform: uppercase; }
          .rss-footer__desc { max-width: 15rem; margin: 0; color: #93b7e8; font-size: 0.9375rem; line-height: 1.55; }
          .rss-footer__list { display: grid; gap: 0.7rem; margin: 0; padding: 0; list-style: none; }
          .rss-footer a { color: #93b7e8; text-decoration: none; font-weight: 500; }
          .rss-footer a:hover { color: #fff; }
          .rss-footer__langs { margin-top: 1.25rem; color: #93b7e8; font-size: 0.8125rem; line-height: 1.5; }
          .rss-footer__langs p { margin: 0 0 0.35rem; }
          .rss-footer__bottom { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 1rem; margin-top: 3rem; padding-top: 1.5rem; border-top: 1px solid rgba(147, 183, 232, 0.18); color: #93b7e8; font-size: 0.875rem; }
          @media (min-width: 640px) {
            .rss-item { grid-template-columns: minmax(0, 1fr) auto; align-items: start; }
            .rss-item__open { margin-top: 1.9rem; }
          }
          @media (min-width: 768px) {
            .rss-nav { display: flex; }
            .rss-hero__inner { padding: 3rem 0; }
            .rss-body { padding-top: 2.5rem; }
            .rss-grid { flex-direction: row; }
            .rss-side {
              position: sticky;
              top: 6rem;
              display: block;
              flex: 0 0 14rem;
              align-self: flex-start;
              max-height: calc(100vh - 7rem);
              overflow-y: auto;
              padding-bottom: 0.25rem;
            }
            .rss-copy, .rss-items { padding: 1.5rem; }
            .rss-footer__grid { grid-template-columns: 1.4fr 1fr 1fr 1fr; }
          }
          @media (max-width: 520px) {
            .rss-container { width: min(100% - 24px, 1120px); }
            .rss-brand img { width: 124px; }
            .rss-copy__row { grid-template-columns: 1fr; }
            .rss-copy__button { width: 100%; }
            .rss-hero__actions .rss-button { width: 100%; }
          }
        ]]></style>
      </head>
      <body>
        <div class="rss-shell">
          <header class="rss-topbar">
            <div class="rss-container rss-topbar__inner">
              <a class="rss-brand" href="[% c.cobrand.base_url %]/" aria-label="[% site_name %] home">
                <img src="/cobrands/infrasignal/images/logo_web.png" alt="[% site_name %]" />
              </a>
              <nav class="rss-nav" aria-label="Primary">
                <a href="[% c.cobrand.base_url %]/">Home</a>
                <a href="[% c.cobrand.base_url %]/reports">All reports</a>
                <a class="is-active" href="[% c.cobrand.base_url %]/alert">Local alerts</a>
                <a href="[% c.cobrand.base_url %]/faq">Help</a>
                <a href="[% c.cobrand.base_url %]/contact">Contact</a>
              </nav>
            </div>
          </header>

          <main>
            <section class="rss-hero">
              <div class="rss-container rss-hero__inner">
                <div>
                  <span class="rss-hero__eyebrow">RSS feed</span>
                  <h1 class="rss-hero__title"><xsl:value-of select="$title" /></h1>
                  <p class="rss-hero__lead">This live feed lets you follow new infrastructure reports without giving us your email address. Copy the feed URL into Feedly, Inoreader, Thunderbird, NetNewsWire, or any RSS reader.</p>
                  <div class="rss-hero__actions">
                    <a class="rss-button rss-button--primary" href="{$uri}">Open XML feed</a>
                    <a class="rss-button rss-button--secondary" href="[% c.cobrand.base_url %]/alert">Create another alert</a>
                  </div>
                </div>
                <div class="rss-hero__badge" aria-label="Recent items in this feed">
                  <strong><xsl:value-of select="$item_count" /></strong>
                  <span>recent reports in this feed</span>
                </div>
              </div>
            </section>

            <section class="rss-body">
              <div class="rss-container rss-grid">
                <aside class="rss-side" aria-label="RSS help">
                  <nav class="rss-side__nav">
                    <p class="rss-side__title">Help and info</p>
                    <a class="rss-side__link is-active" href="{$uri}">This RSS feed</a>
                    <a class="rss-side__link" href="[% c.cobrand.base_url %]/alert">Back to Local Alerts</a>
                    <a class="rss-side__link" href="https://www.bbc.co.uk/news/10628494">What is RSS?</a>
                    <a class="rss-side__link" href="[% c.cobrand.base_url %]/about/privacy">Privacy</a>
                    <a class="rss-side__link" href="[% c.cobrand.base_url %]/contact">Contact us</a>
                  </nav>
                  <div class="rss-side__card">
                    <p class="rss-side__card-title">Prefer email?</p>
                    <p class="rss-side__card-sub">You can get the same local report updates delivered to your inbox.</p>
                    <a class="rss-item__open" href="[% c.cobrand.base_url %]/alert">Subscribe by email</a>
                  </div>
                </aside>

                <div class="rss-main">
                  <section class="rss-panel rss-copy" aria-labelledby="rss-copy-title">
                    <h2 id="rss-copy-title" class="rss-section-title">Copy this URL into your RSS reader</h2>
                    <p class="rss-section-sub">Paste the link below into your preferred reader. The feed updates automatically as new matching reports are published.</p>
                    <div class="rss-copy__row">
                      <input id="rss-feed-url" class="rss-copy__input" type="text" readonly="readonly" onclick="this.select(); this.setSelectionRange(0, this.value.length);" aria-label="RSS feed URL">
                        <xsl:attribute name="value"><xsl:value-of select="$uri" /></xsl:attribute>
                      </input>
                      <button type="button" class="rss-button rss-copy__button" data-copy-target="rss-feed-url" data-copy-label="Copy" data-copied-label="Copied">Copy</button>
                    </div>
                    <ul class="rss-reader-list" aria-label="Reader options">
                      <li><a href="https://feedly.com/i/subscription/feed/{$uri}" target="_blank" rel="noopener">Feedly</a></li>
                      <li><a href="https://www.inoreader.com/?add_feed={$uri}" target="_blank" rel="noopener">Inoreader</a></li>
                      <li><a href="{$uri}" download="download">Download XML</a></li>
                      <li><a href="{$site_link}">View matching reports</a></li>
                    </ul>
                  </section>

                  <section class="rss-panel rss-items" aria-labelledby="rss-items-title">
                    <div class="rss-items__head">
                      <div>
                        <h2 id="rss-items-title" class="rss-section-title">Latest reports in this feed</h2>
                        <p class="rss-section-sub"><xsl:value-of select="/rss/channel/description" /></p>
                      </div>
                      <span class="rss-pill"><xsl:value-of select="$item_count" /> items</span>
                    </div>
                    <xsl:choose>
                      <xsl:when test="count(/rss/channel/item) &gt; 0">
                        <ol class="rss-list">
                          <xsl:apply-templates select="rss/channel/item" />
                        </ol>
                      </xsl:when>
                      <xsl:otherwise>
                        <div class="rss-empty">
                          <strong>No reports yet</strong>
                          <p>New reports will appear here as soon as they match this feed.</p>
                        </div>
                      </xsl:otherwise>
                    </xsl:choose>
                  </section>
                </div>
              </div>
            </section>
          </main>

          <footer class="rss-footer">
            <div class="rss-container">
              <div class="rss-footer__grid">
                <div>
                  <h4 class="rss-footer__heading">InfraSignal</h4>
                  <p class="rss-footer__desc">Report infrastructure issues and get them fixed. Serving communities across all 51 US states.</p>
                </div>
                <div>
                  <h4 class="rss-footer__heading">Platform</h4>
                  <ul class="rss-footer__list">
                    <li><a href="[% c.cobrand.base_url %]/">Report an Issue</a></li>
                    <li><a href="[% c.cobrand.base_url %]/reports">All Reports</a></li>
                    <li><a href="[% c.cobrand.base_url %]/alert">Get Alerts</a></li>
                    <li><a href="[% c.cobrand.base_url %]/my">My Reports</a></li>
                  </ul>
                </div>
                <div>
                  <h4 class="rss-footer__heading">Company</h4>
                  <ul class="rss-footer__list">
                    <li><a href="[% c.cobrand.base_url %]/about">About</a></li>
                    <li><a href="[% c.cobrand.base_url %]/how-it-works">How It Works</a></li>
                    <li><a href="[% c.cobrand.base_url %]/about/for-local-government">For Local Government</a></li>
                    <li><a href="[% c.cobrand.base_url %]/faq">FAQ</a></li>
                    <li><a href="[% c.cobrand.base_url %]/contact">Contact</a></li>
                  </ul>
                </div>
                <div>
                  <h4 class="rss-footer__heading">Legal</h4>
                  <ul class="rss-footer__list">
                    <li><a href="[% c.cobrand.base_url %]/about/privacy">Privacy Policy</a></li>
                    <li><a href="[% c.cobrand.base_url %]/about/terms">Terms of Use</a></li>
                  </ul>
                  <div class="rss-footer__langs">
                    <p>Available in:</p>
                    <p>English / Spanish / Russian / Turkish</p>
                  </div>
                </div>
              </div>
              <div class="rss-footer__bottom">
                <span>2026 InfraSignal. All rights reserved.</span>
                <a href="[% c.cobrand.base_url %]/about/for-local-government">For Local Government</a>
              </div>
            </div>
          </footer>
        </div>
        <script type="text/javascript"><![CDATA[
          (function () {
            var buttons = document.querySelectorAll('[data-copy-target]');
            Array.prototype.forEach.call(buttons, function (button) {
              button.addEventListener('click', function () {
                var input = document.getElementById(button.getAttribute('data-copy-target'));
                if (!input) { return; }
                input.select();
                input.setSelectionRange(0, input.value.length);
                var label = button.getAttribute('data-copy-label') || 'Copy';
                var copied = button.getAttribute('data-copied-label') || 'Copied';
                function done() {
                  button.textContent = copied;
                  button.classList.add('is-copied');
                  setTimeout(function () {
                    button.textContent = label;
                    button.classList.remove('is-copied');
                  }, 1600);
                }
                if (navigator.clipboard && navigator.clipboard.writeText) {
                  navigator.clipboard.writeText(input.value).then(done, done);
                } else {
                  try { document.execCommand('copy'); } catch (e) {}
                  done();
                }
              });
            });
          }());
        ]]></script>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="item">
    <li>
      <article class="rss-item">
        <div>
          <div class="rss-item__meta">
            <xsl:if test="category"><span class="rss-item__tag"><xsl:value-of select="category" /></span></xsl:if>
            <xsl:if test="pubDate"><time><xsl:value-of select="pubDate" /></time></xsl:if>
            <xsl:if test="georss:point"><span><xsl:value-of select="georss:point" /></span></xsl:if>
          </div>
          <h3 class="rss-item__title"><a href="{link}"><xsl:value-of select="title" /></a></h3>
          <div class="rss-item__summary"><xsl:value-of disable-output-escaping="yes" select="description" /></div>
        </div>
        <a class="rss-item__open" href="{link}">View report</a>
      </article>
    </li>
  </xsl:template>
</xsl:stylesheet>