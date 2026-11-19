# MSroofing – generátor statického webu
# Použití:  powershell -ExecutionPolicy Bypass -File src\build.ps1
# Obsah je v src\content\*.json, výstup se zapisuje do složky msroofing\.
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
$out = Join-Path (Split-Path $src -Parent) 'msroofing'
$enc = New-Object System.Text.UTF8Encoding($false)

function Read-Json([string]$name) {
  $p = Join-Path $src "content\$name.json"
  return ([IO.File]::ReadAllText($p, [Text.Encoding]::UTF8) | ConvertFrom-Json)
}
function Enc([string]$s) { return [System.Net.WebUtility]::HtmlEncode($s) }

$site = Read-Json 'site'
$langs = @('cs', 'de', 'en') | Where-Object { Test-Path (Join-Path $src "content\$_.json") }
$C = @{}; foreach ($l in $langs) { $C[$l] = Read-Json $l }
$IMGDIR = $site.imgDir
function Img([string]$file, [int]$w) { return $IMGDIR + $site.images.$file + "-$w.jpg" }
function AbsImg([string]$file) { return $site.base + (Img $file 1600) }
function SrcSet([string]$file) { return (($site.sizes | ForEach-Object { "$(Img $file $_) ${_}w" }) -join ', ') }
function Pic([string]$file, [string]$alt, [string]$sizes, [string]$extra) { return "<img src=`"$(Img $file 800)`" srcset=`"$(SrcSet $file)`" sizes=`"$sizes`" alt=`"$(Enc $alt)`"$extra>" }
$LOGO = $IMGDIR + $site.images.'logo.jpg' + '-400.jpg'
$LABEL = @{ cs = 'CZ'; de = 'DE'; en = 'EN' }
$HREFLANG = @{ cs = 'cs'; de = 'de'; en = 'en' }

# ---------- ikony ----------
$icPhone = '<svg class="ring" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path class="ring-w ring-w1" d="M15.05 5A5 5 0 0 1 19 8.95"/><path class="ring-w ring-w2" d="M15.05 1A9 9 0 0 1 23 8.94"/><path class="ring-h" d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1.9.4 1.8.7 2.7a2 2 0 0 1-.5 2.1L8 9.8a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.4c.9.3 1.8.6 2.7.7a2 2 0 0 1 1.7 2z"/></svg>'
$icArrow = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6"/></svg>'
$icCheck = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" aria-hidden="true"><path d="M4 12.5l5 5L20 6.5"/></svg>'
$icWa = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><path d="M3.5 20.5l1.3-4.2A8.5 8.5 0 1 1 8 19.4z"/><path d="M9 8.8c0 3 2.6 6 6 6.2l1.2-1.4-1.9-1-1 .8c-1-.4-1.9-1.3-2.4-2.4l.8-1-1-1.9z" fill="currentColor" stroke="none"/></svg>'
$icMail = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6 9-6"/></svg>'
$icClock = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>'

# ---------- URL ----------
function HomePath([string]$l) { if ($l -eq 'cs') { return '/' } else { return "/$l/" } }
function SvcPath([string]$l, $s) { return (HomePath $l) + $C[$l].servicesPath + '/' + $s.slug.$l + '/' }
function Abs([string]$p) { return $site.base + $p }

function Save([string]$path, [string]$html) {
  $rel = $path.Trim('/')
  if ($rel -eq '') { $dir = $out } else { $dir = Join-Path $out ($rel -replace '/', '\') }
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  [IO.File]::WriteAllText((Join-Path $dir 'index.html'), $html, $enc)
}

function ToJson($o) { return ($o | ConvertTo-Json -Depth 12 -Compress) }

# ---------- strukturovaná data ----------
function Business([string]$l) {
  $T = $C[$l]
  return [ordered]@{
    '@type' = 'RoofingContractor'; '@id' = "$($site.base)/#firma"
    name = 'MSroofing s.r.o.'; url = Abs (HomePath $l); logo = $site.base + $LOGO
    image = @((AbsImg 'gerard.jpeg'), (AbsImg $site.poster))
    telephone = $site.phone; email = $site.email; vatID = 'SK2122703055'; taxID = '57408165'
    founder = [ordered]@{ '@type' = 'Person'; name = 'Dalibor Mikus' }
    address = [ordered]@{ '@type' = 'PostalAddress'; streetAddress = 'Kukučínova 3379/22'; addressLocality = 'Banská Bystrica'; postalCode = '974 01'; addressCountry = 'SK' }
    geo = [ordered]@{ '@type' = 'GeoCoordinates'; latitude = 48.7362; longitude = 19.1463 }
    areaServed = @('CZ', 'SK', 'DE', 'NL' | ForEach-Object { [ordered]@{ '@type' = 'Country'; name = $_ } })
    openingHoursSpecification = @(
      [ordered]@{ '@type' = 'OpeningHoursSpecification'; dayOfWeek = @('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'); opens = '07:00'; closes = '17:00' },
      [ordered]@{ '@type' = 'OpeningHoursSpecification'; dayOfWeek = 'Saturday'; opens = '08:00'; closes = '12:00' }
    )
    hasOfferCatalog = [ordered]@{ '@type' = 'OfferCatalog'; name = $T.ui.navServices; itemListElement = @($site.services | ForEach-Object { [ordered]@{ '@type' = 'Offer'; itemOffered = [ordered]@{ '@type' = 'Service'; name = $T.services.($_.id).nav; url = Abs (SvcPath $l $_) } } }) }
    sameAs = @($site.wa)
  }
}
function FaqLd($faqs, [string]$l) {
  return [ordered]@{ '@type' = 'FAQPage'; inLanguage = $l; mainEntity = @($faqs | ForEach-Object { [ordered]@{ '@type' = 'Question'; name = $_.q; acceptedAnswer = [ordered]@{ '@type' = 'Answer'; text = $_.a } } }) }
}

# ---------- části stránky ----------
function Head([string]$l, $pg) {
  $T = $C[$l]
  $alts = ($langs | ForEach-Object { "<link rel=`"alternate`" hreflang=`"$($HREFLANG[$_])`" href=`"$(Abs $pg.alts[$_])`">" }) -join "`n"
  $altLoc = ($langs | Where-Object { $_ -ne $l } | ForEach-Object { "<meta property=`"og:locale:alternate`" content=`"$($C[$_].locale)`">" }) -join "`n"
  return @"
<!doctype html>
<html lang="$l">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>$(Enc $pg.title)</title>
<meta name="description" content="$(Enc $pg.desc)">
<link rel="canonical" href="$(Abs $pg.path)">
$alts
<link rel="alternate" hreflang="x-default" href="$(Abs $pg.alts['cs'])">
<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1">
<meta name="theme-color" content="#16181a">
<meta property="og:locale" content="$($T.locale)">
$altLoc
<meta property="og:type" content="website">
<meta property="og:site_name" content="MSroofing">
<meta property="og:title" content="$(Enc $pg.ogTitle)">
<meta property="og:description" content="$(Enc $pg.desc)">
<meta property="og:url" content="$(Abs $pg.path)">
<meta property="og:image" content="$($pg.ogImage)">
<meta property="og:image:alt" content="$(Enc $pg.ogAlt)">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="$($site.base)/apple-touch-icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="preload" as="image" href="$($pg.preload)"$($pg.preloadSet) fetchpriority="high">
<link href="https://fonts.googleapis.com/css2?family=Public+Sans:wght@400;500;600&family=Schibsted+Grotesk:wght@600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/assets/css/style.css">
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('consent', 'default', {ad_storage:'denied', analytics_storage:'denied', ad_user_data:'denied', ad_personalization:'denied', wait_for_update: 500});
  gtag('js', new Date());
  gtag('config', '$($site.ga)');
</script>
<script async src="https://www.googletagmanager.com/gtag/js?id=$($site.ga)"></script>
<script type="application/ld+json">$($pg.ld)</script>
</head>
"@
}

function LangSwitch([string]$l, $alts) {
  $links = ($langs | ForEach-Object {
      $cur = ''; if ($_ -eq $l) { $cur = ' aria-current="page"' }
      "<a href=`"$($alts[$_])`" hreflang=`"$($HREFLANG[$_])`" lang=`"$($HREFLANG[$_])`"$cur>$($LABEL[$_])</a>"
    }) -join ''
  return "<nav class=`"lang`" aria-label=`"$(Enc $C[$l].ui.langAria)`">$links</nav>"
}

function Header([string]$l, $alts) {
  $T = $C[$l]; $U = $T.ui; $hp = HomePath $l; $id = $T.ids
  $nav = @(
    @($id.services, $U.navServices), @($id.refs, $U.navRefs), @($id.process, $U.navProcess), @($id.about, $U.navAbout), @($id.faq, $U.navFaq)
  ) | ForEach-Object { "<li><a href=`"$hp#$($_[0])`">$($_[1])</a></li>" }
  $ls = LangSwitch $l $alts
  return @"
<body>
<a class="skip" href="#main">$($U.skip)</a>
<header class="site-header">
  <div class="wrap header-in">
    <a class="brand" href="$hp" aria-label="$(Enc $U.homeAria)"><img src="$LOGO" alt="MSroofing – Roofing &amp; Carpentry" width="400" height="110"></a>
    <nav class="primary-nav" id="primary-nav" aria-label="$(Enc $U.navAria)">
      <ul>$($nav -join '')</ul>
      <div class="nav-extra">
        $ls
        <a class="btn btn-primary" href="#$($id.contact)">$($U.ctaLong)</a>
        <a class="btn btn-ghost" href="tel:$($site.phone)">$icPhone $($U.callBtn) $($site.phoneDisplay)</a>
      </div>
    </nav>
    <div class="header-cta">
      $ls
      <a class="header-phone" href="tel:$($site.phone)" aria-label="$(Enc "$($U.callBtn) $($site.phoneDisplay)")">$icPhone<span class="hp-num">$($site.phoneDisplay)</span><span class="hp-call">$($U.callBtn)</span></a>
      <button class="nav-toggle" type="button" aria-controls="primary-nav" aria-expanded="false" aria-label="Menu"><span></span></button>
    </div>
  </div>
</header>
<main id="main">
"@
}

function TrustList([string]$l, $items, [string]$cls) {
  $li = ($items | ForEach-Object { "<li>$icCheck<span>$_</span></li>" }) -join ''
  return "<ul class=`"trust $cls`" aria-label=`"$(Enc $C[$l].ui.trustAria)`">$li</ul>"
}

function StatList([string]$l, $items) {
  $li = ($items | ForEach-Object { "<li><strong>$(Enc $_.v)</strong><span>$(Enc $_.l)</span></li>" }) -join ''
  return "<ul class=`"hero-stats`" aria-label=`"$(Enc $C[$l].ui.trustAria)`">$li</ul>"
}

function HeroActions([string]$l) {
  $U = $C[$l].ui
  return "<div class=`"hero-actions`"><a class=`"btn btn-primary`" href=`"#$($C[$l].ids.contact)`">$($U.ctaLong) $icArrow</a><a class=`"btn btn-ghost`" href=`"tel:$($site.phone)`">$icPhone $($site.phoneDisplay)</a></div>"
}

function RefCard([string]$l, [string]$file) {
  $r = $C[$l].refs.$file
  return @"
<li class="ref-card">
  <button class="ref-open" type="button" aria-label="$(Enc "$($C[$l].ui.enlarge): $($r.title)")">$(Pic $file $r.alt '(min-width:980px) 380px, 50vw' " data-full=`"$(Img $file 1600)`" loading=`"lazy`" decoding=`"async`"")</button>
  <span class="ref-tag">$($r.tag)</span>
  <h3>$($r.title)</h3>
</li>
"@
}

function ProcessSection([string]$l) {
  $P = $C[$l].process; $n = 0
  $steps = ($P.steps | ForEach-Object { $n++; "<li class=`"step`"><span class=`"step-n`">0$n</span><span class=`"when`">$($_.when)</span><h3>$($_.t)</h3><p>$($_.d)</p></li>" }) -join ''
  return @"
<section class="section section-dark" id="$($C[$l].ids.process)" aria-labelledby="process-title">
  <div class="wrap">
    <div class="section-head"><div><span class="kicker">$($P.kicker)</span><h2 id="process-title">$($P.title)</h2><p>$($P.lead)</p></div>
    <a class="btn btn-primary" href="#$($C[$l].ids.contact)">$($C[$l].ui.ctaLong)</a></div>
    <ol class="steps">$steps</ol>
  </div>
</section>
"@
}

function FaqSection([string]$l, [string]$kicker, [string]$title, $faqs, [string]$cls) {
  $U = $C[$l].ui
  $items = ($faqs | ForEach-Object { "<details><summary>$($_.q)</summary><p>$($_.a)</p></details>" }) -join "`n"
  return @"
<section class="section $cls" id="$($C[$l].ids.faq)" aria-labelledby="faq-title">
  <div class="wrap faq-grid">
    <div class="faq-side"><span class="kicker">$kicker</span><h2 id="faq-title" class="h2">$title</h2>
      <p>$($U.faqHelpPre) <a href="tel:$($site.phone)"><strong>$($site.phoneDisplay)</strong></a>$($U.faqHelpPost)</p></div>
    <div class="faq-list">
$items
    </div>
  </div>
</section>
"@
}

function ContactSection([string]$l, [string]$selected) {
  $T = $C[$l]; $K = $T.contact
  $opts = "<option value=`"`">$($K.servicePh)</option>" + (($K.options.PSObject.Properties | ForEach-Object {
        $sel = ''; if ($_.Name -eq $selected) { $sel = ' selected' }
        "<option value=`"$($_.Name)`"$sel>$($_.Value)</option>"
      }) -join '')
  return @"
<section class="section section-dark" id="$($T.ids.contact)" aria-labelledby="contact-title">
  <div class="wrap contact-grid">
    <div>
      <span class="kicker">$($K.kicker)</span>
      <h2 id="contact-title" class="h2">$($K.title)</h2>
      <p class="contact-lead">$($K.lead)</p>
      <div class="contact-card">
        <a href="tel:$($site.phone)">$icPhone<span><small>$($K.phoneLabel)</small><b>$($site.phoneDisplay)</b></span></a>
        <a href="$($site.wa)" target="_blank" rel="noopener">$icWa<span><small>$($K.waLabel)</small><b>$($K.waText)</b></span></a>
        <a href="mailto:$($site.email)">$icMail<span><small>$($K.emailLabel)</small><b>$($site.email)</b></span></a>
        <div>$icClock<span><small>$($K.hoursLabel)</small><b>$($K.hours)</b></span></div>
      </div>
      <p class="company">$($K.company)</p>
    </div>
    <form class="form" id="contactForm" action="/send.php" method="post" novalidate>
      <h3>$($K.formTitle)</h3>
      <p>$($K.formLead)</p>
      <input type="hidden" name="lang" value="$l">
      <div class="hp" aria-hidden="true"><label for="f-web">$($K.hp)</label><input id="f-web" type="text" name="website" tabindex="-1" autocomplete="off"></div>
      <div class="form-grid">
        <div class="field"><label for="f-name">$($K.name)</label><input id="f-name" name="name" type="text" autocomplete="name" required></div>
        <div class="field"><label for="f-phone">$($K.phone)</label><input id="f-phone" name="phone" type="tel" autocomplete="tel" inputmode="tel" required></div>
        <div class="field"><label for="f-email">$($K.email)</label><input id="f-email" name="email" type="email" autocomplete="email" required></div>
        <div class="field"><label for="f-location">$($K.location) <span class="opt">$($K.optional)</span></label><input id="f-location" name="location" type="text" autocomplete="address-level2" placeholder="$(Enc $K.locationPh)"></div>
        <div class="field full"><label for="f-service">$($K.service)</label><select id="f-service" name="service" required>$opts</select></div>
        <div class="field full"><label for="f-msg">$($K.message)</label><textarea id="f-msg" name="message" required placeholder="$(Enc $K.messagePh)"></textarea></div>
        <label class="check"><input type="checkbox" name="gdpr" value="1" required><span>$($K.gdpr)</span></label>
        <button class="btn btn-primary" type="submit">$($K.submit)</button>
        <p class="form-note">$($K.note) <a href="tel:$($site.phone)">$($site.phoneDisplay)</a></p>
      </div>
    </form>
  </div>
</section>
"@
}

function Footer([string]$l) {
  $T = $C[$l]; $F = $T.footer; $hp = HomePath $l; $id = $T.ids; $U = $T.ui
  $svc = ($site.services | ForEach-Object { "<li><a href=`"$(SvcPath $l $_)`">$($T.services.($_.id).nav)</a></li>" }) -join ''
  $LB = $T.lb; $K = $T.cookie
  return @"
</main>
<footer class="site-footer">
  <div class="wrap">
    <div class="footer-grid">
      <div class="footer-brand"><img src="$LOGO" alt="MSroofing" width="400" height="110" loading="lazy"><p>$($F.brand)</p></div>
      <div><h2>$($F.services)</h2><ul>$svc</ul></div>
      <div><h2>$($F.company)</h2><ul>
        <li><a href="$hp#$($id.refs)">$($U.navRefs)</a></li>
        <li><a href="$hp#$($id.process)">$($U.navProcess)</a></li>
        <li><a href="$hp#$($id.about)">$($U.navAbout)</a></li>
        <li><a href="$hp#$($id.faq)">$($U.navFaq)</a></li>
      </ul></div>
      <div><h2>$($F.contact)</h2><ul>
        <li><a href="tel:$($site.phone)">$($site.phoneDisplay)</a></li>
        <li><a href="mailto:$($site.email)">$($site.email)</a></li>
        <li>$($F.hoursShort)</li>
      </ul></div>
    </div>
    <div class="footer-bottom">
      <span>&copy; <span id="year">2026</span> MSroofing s.r.o.</span>
      <nav aria-label="$(Enc $F.legalAria)"><a href="/gdpr.html">$($F.privacy)</a><a href="/cookies.html">$($F.cookies)</a></nav>
    </div>
  </div>
</footer>
<dialog class="lightbox" id="lightbox" aria-label="$(Enc $LB.aria)">
  <figure class="lb-fig">
    <img src="" alt="">
    <button class="lb-btn lb-prev" type="button" aria-label="$(Enc $LB.prev)">&lsaquo;</button>
    <button class="lb-btn lb-next" type="button" aria-label="$(Enc $LB.next)">&rsaquo;</button>
    <button class="lb-close" type="button" aria-label="$(Enc $LB.close)">&times;</button>
    <figcaption class="lb-caption"></figcaption>
  </figure>
</dialog>
<div class="cookie" id="cookieBar" role="region" aria-label="$(Enc $K.aria)" hidden>
  <p>$($K.text)</p>
  <div class="cookie-actions">
    <button class="btn btn-line" type="button" data-consent="denied">$($K.decline)</button>
    <button class="btn btn-dark" type="button" data-consent="granted">$($K.accept)</button>
  </div>
</div>
<script src="/assets/js/main.js" defer></script>
</body>
</html>
"@
}

# ---------- domovská stránka ----------
function BuildHome([string]$l) {
  $T = $C[$l]; $M = $T.home; $U = $T.ui; $id = $T.ids
  $alts = @{}; foreach ($x in $langs) { $alts[$x] = HomePath $x }
  $ld = ToJson ([ordered]@{ '@context' = 'https://schema.org'; '@graph' = @(
        (Business $l),
        [ordered]@{ '@type' = 'WebSite'; '@id' = "$($site.base)/#web"; url = Abs (HomePath $l); name = 'MSroofing'; inLanguage = $l; publisher = @{ '@id' = "$($site.base)/#firma" } },
        (FaqLd $M.faqs $l)
      ) })
  $pg = @{ title = $M.title; desc = $M.desc; path = (HomePath $l); alts = $alts; ogTitle = $M.ogTitle; ogImage = (AbsImg 'gerard.jpeg'); ogAlt = $M.ogAlt; preload = (Img $site.poster 800); preloadSet = ''; ld = $ld }

  $cards = ($site.services | ForEach-Object {
      $s = $T.services.($_.id); $url = SvcPath $l $_
      @"
<article class="svc-card">
  <a class="svc-card-img" href="$url">$(Pic $_.card '' '(min-width:1100px) 280px, (min-width:600px) 50vw, 100vw' ' loading="lazy" decoding="async"')<h3>$($s.nav)</h3><span class="arr">$icArrow</span></a>
  <div class="svc-card-body"><p>$($s.card)</p><a class="btn btn-line" href="$url" aria-label="$(Enc "$($U.more): $($s.nav)")">$($U.more) $icArrow</a></div>
</article>
"@ }) -join "`n"
  $cards += "<article class=`"svc-card svc-card--cta`"><h3>$($M.ctaCardT)</h3><p>$($M.ctaCardD)</p><a class=`"btn btn-primary`" href=`"#$($id.contact)`">$($M.ctaCardBtn)</a></article>"

  $stats = ($M.stats | ForEach-Object { "<div><strong>$($_.n)</strong><span>$($_.l)</span></div>" }) -join ''
  $aboutP = "<p>$(@($M.aboutP)[0])</p>"
  $refs = ($site.homeRefs | ForEach-Object { RefCard $l $_ }) -join "`n"

  $body = @"
<section class="hero" aria-labelledby="hero-title">
  <div class="hero-media"><video class="hero-video" autoplay muted loop playsinline preload="auto" poster="$(Img $site.poster 800)" aria-hidden="true"><source src="$($site.video)" type="video/mp4"></video></div>
  <div class="wrap hero-in">
    <span class="eyebrow">$($M.eyebrow)</span>
    <h1 id="hero-title">$($M.h1)</h1>
    <p class="hero-lead">$($M.lead)</p>
    $(HeroActions $l)
    $(StatList $l $M.heroStats)
  </div>
</section>

<section class="section" id="$($id.services)" aria-labelledby="svc-title">
  <div class="wrap">
    <div class="section-head"><div><span class="kicker">$($M.svcKicker)</span><h2 id="svc-title">$($M.svcTitle)</h2><p>$($M.svcLead)</p></div></div>
    <div class="svc-grid">
$cards
    </div>
  </div>
</section>

<section class="section section-stone about" id="$($id.about)" aria-labelledby="about-title">
  <div class="wrap about-grid">
    <div class="about-img">$(Pic $site.aboutImg $M.aboutImgAlt '(min-width:860px) 560px, 100vw' ' loading="lazy" decoding="async"')</div>
    <div>
      <span class="kicker">$($M.aboutKicker)</span>
      <h2 id="about-title" class="h2">$($M.aboutTitle)</h2>
      <blockquote>$($M.quote)<footer>$($M.quoteBy)</footer></blockquote>
      <div class="prose">$aboutP</div>
      <div class="stats">$stats</div>
    </div>
  </div>
</section>

$(ProcessSection $l)

<section class="section section-stone" id="$($id.refs)" aria-labelledby="refs-title">
  <div class="wrap">
    <div class="section-head"><div><span class="kicker">$($M.refsKicker)</span><h2 id="refs-title">$($M.refsTitle)</h2><p>$($M.refsLead)</p></div></div>
    <ul class="ref-grid">
$refs
    </ul>
    <div class="ref-more"><p>$($M.refsMore)</p><a class="btn btn-dark" href="#$($id.contact)">$($M.refsMoreBtn)</a></div>
  </div>
</section>

$(FaqSection $l $M.faqKicker $M.faqTitle $M.faqs '')

$(ContactSection $l '')
"@
  Save (HomePath $l) ((Head $l $pg) + (Header $l $alts) + $body + (Footer $l))
}

# ---------- podstránka služby ----------
function BuildService([string]$l, $svc) {
  $T = $C[$l]; $S = $T.services.($svc.id); $U = $T.ui; $V = $T.svc; $id = $T.ids
  $path = SvcPath $l $svc
  $alts = @{}; foreach ($x in $langs) { $alts[$x] = SvcPath $x $svc }
  $heroAlt = $S.heroAlt
  $ld = ToJson ([ordered]@{ '@context' = 'https://schema.org'; '@graph' = @(
        (Business $l),
        [ordered]@{ '@type' = 'Service'; name = $S.nav; serviceType = $S.nav; description = $S.desc; url = Abs $path; image = (AbsImg $svc.hero); inLanguage = $l; provider = @{ '@id' = "$($site.base)/#firma" }; areaServed = @('CZ', 'SK', 'DE', 'NL') },
        [ordered]@{ '@type' = 'BreadcrumbList'; itemListElement = @(
            [ordered]@{ '@type' = 'ListItem'; position = 1; name = $U.crumbHome; item = Abs (HomePath $l) },
            [ordered]@{ '@type' = 'ListItem'; position = 2; name = $U.crumbServices; item = (Abs (HomePath $l)) + '#' + $id.services },
            [ordered]@{ '@type' = 'ListItem'; position = 3; name = $S.nav; item = Abs $path }
          ) },
        (FaqLd $S.faq $l)
      ) })
  $pg = @{ title = $S.title; desc = $S.desc; path = $path; alts = $alts; ogTitle = $S.title; ogImage = (AbsImg $svc.hero); ogAlt = $heroAlt; preload = (Img $svc.hero 800); preloadSet = " imagesrcset=`"$(SrcSet $svc.hero)`" imagesizes=`"100vw`""; ld = $ld }

  $n = 0; $layers = ($S.layers | ForEach-Object { $n++; "<li class=`"layer-item`"><span class=`"layer-num`">$n</span><h3>$($_.t)</h3><p>$($_.d)</p></li>" }) -join "`n"
  $scope = ($S.scope | ForEach-Object { "<li>$_</li>" }) -join ''
  $refs = ($svc.refs | ForEach-Object { RefCard $l $_ }) -join "`n"
  $others = ($site.services | Where-Object { $_.id -ne $svc.id } | ForEach-Object {
      "<a class=`"mini`" href=`"$(SvcPath $l $_)`"><img src=`"$(Img $_.card 400)`" alt=`"`" width=`"72`" height=`"56`" loading=`"lazy`" decoding=`"async`"><span>$($T.services.($_.id).nav)</span>$icArrow</a>" }) -join ''

  $body = @"
<section class="hero hero--page" aria-labelledby="hero-title">
  <div class="hero-media">$(Pic $svc.hero $heroAlt '100vw' ' fetchpriority="high" decoding="async"')</div>
  <div class="wrap hero-in">
    <nav aria-label="$(Enc $U.crumbAria)"><ol class="crumbs"><li><a href="$(HomePath $l)">$($U.crumbHome)</a></li><li><a href="$(HomePath $l)#$($id.services)">$($U.crumbServices)</a></li><li><span aria-current="page">$($S.nav)</span></li></ol></nav>
    <h1 id="hero-title">$($S.h1)</h1>
    <p class="hero-lead">$($S.lead)</p>
    $(HeroActions $l)
    $(TrustList $l $S.facts 'trust--3')
  </div>
</section>

<section class="section" aria-labelledby="intro-title">
  <div class="wrap">
    <div class="intro-grid">
      <div><span class="kicker">$($V.introKicker)</span><h2 id="intro-title" class="h2">$($S.introTitle)</h2></div>
      <p>$($S.intro)</p>
    </div>
  </div>
</section>

<section class="section section-stone" id="$($id.layers)" aria-labelledby="layers-title">
  <div class="wrap">
    <div class="section-head"><div><span class="kicker">$($V.layersKicker)</span><h2 id="layers-title">$($S.layersTitle)</h2><p>$($S.layersLead)</p></div></div>
    <div class="stack-grid">
      <div class="stack-sticky"><div class="stack-figure" id="stack-figure" data-stack="$($svc.stack)" aria-hidden="true"></div></div>
      <div>
        <ol class="layer-list">
$layers
        </ol>
        <p class="stack-note">$($S.note)</p>
      </div>
    </div>
  </div>
</section>

<section class="section" aria-labelledby="scope-title">
  <div class="wrap scope-grid">
    <div class="scope-img">$(Pic $svc.scopeImg $T.refs.($svc.scopeImg).alt '(min-width:860px) 560px, 100vw' ' loading="lazy" decoding="async"')</div>
    <div>
      <span class="kicker">$($V.scopeKicker)</span>
      <h2 id="scope-title" class="h2">$($V.scopeTitle)</h2>
      <ul class="check-list">$scope</ul>
      <a class="btn btn-dark" href="#$($id.contact)">$($V.scopeBtn) $icArrow</a>
    </div>
  </div>
</section>

<section class="section section-stone" id="$($id.refs)" aria-labelledby="refs-title">
  <div class="wrap">
    <div class="section-head"><div><span class="kicker">$($V.refsKicker)</span><h2 id="refs-title">$($V.refsTitle)</h2></div></div>
    <ul class="ref-grid">
$refs
    </ul>
  </div>
</section>

$(FaqSection $l $V.faqKicker $V.faqTitle $S.faq '')

<section class="section section-stone" aria-labelledby="more-title">
  <div class="wrap">
    <div class="section-head"><div><span class="kicker">$($V.moreKicker)</span><h2 id="more-title">$($V.moreTitle)</h2></div></div>
    <div class="mini-grid">$others</div>
  </div>
</section>

$(ContactSection $l $svc.form)
"@
  Save $path ((Head $l $pg) + (Header $l $alts) + $body + (Footer $l))
}

# ---------- sestavení ----------
$count = 0
foreach ($l in $langs) {
  BuildHome $l; $count++
  foreach ($s in $site.services) { BuildService $l $s; $count++ }
}

# sitemap.xml
$urls = @()
$groups = @(, @($langs | ForEach-Object { HomePath $_ }))
foreach ($s in $site.services) { $groups += , @($langs | ForEach-Object { SvcPath $_ $s }) }
$today = (Get-Date).ToString('yyyy-MM-dd')
foreach ($g in $groups) {
  for ($k = 0; $k -lt $langs.Count; $k++) {
    $alt = ''
    for ($m = 0; $m -lt $langs.Count; $m++) { $alt += "<xhtml:link rel=`"alternate`" hreflang=`"$($HREFLANG[$langs[$m]])`" href=`"$(Abs $g[$m])`"/>" }
    $alt += "<xhtml:link rel=`"alternate`" hreflang=`"x-default`" href=`"$(Abs $g[0])`"/>"
    $urls += "  <url><loc>$(Abs $g[$k])</loc><lastmod>$today</lastmod>$alt</url>"
  }
}
$sm = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<urlset xmlns=`"http://www.sitemaps.org/schemas/sitemap/0.9`" xmlns:xhtml=`"http://www.w3.org/1999/xhtml`">`n" + ($urls -join "`n") + "`n</urlset>`n"
[IO.File]::WriteAllText((Join-Path $out 'sitemap.xml'), $sm, $enc)

Write-Host "Hotovo: $count stránek, jazyky: $($langs -join ', ')"
