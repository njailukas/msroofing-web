# MSroofing – nový web

Web střechařské firmy MSroofing s.r.o. v češtině, němčině a angličtině.

**Náhled:** https://njailukas.github.io/msroofing-web/
Náhled je jen pro klienta. Google ho neindexuje a kontaktní formulář v něm nefunguje, protože GitHub Pages neumí spustit PHP.

## Struktura

| Složka | Obsah |
| --- | --- |
| `msroofing/` | Hotový web. Na hosting se nahraje obsah této složky. |
| `src/content/` | Texty (`cs.json`, `de.json`, `en.json`) a nastavení (`site.json`) |
| `src/build.ps1` | Generátor, který z textů vytvoří HTML stránky |
| `src/optimize-images.ps1` | Ze `src/_originals/` vytvoří zmenšené obrázky |

## Úpravy

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File src\optimize-images.ps1   # jen při změně fotek
powershell -NoProfile -ExecutionPolicy Bypass -File src\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File serve.ps1                 # http://localhost:8765
```

Po `git push` do větve `main` se náhled na GitHub Pages sám aktualizuje.

## Ostré spuštění

Obsah `msroofing/` se nahraje na hosting domény msroofing.eu. Na serveru musí zůstat `send.php` (kontaktní formulář), `gdpr.html` a `cookies.html`.
