# mateuszkielbasa.dev

Strona sprzedażowa usług: tworzenie stron internetowych i aplikacji (cennik, porównanie pakietów, zamówienie wyceny). Jeden plik `index.html` (HTML5 + Tailwind Play CDN + vanilla JS), dwujęzyczny PL/EN.

## i18n
Tekst PL jest w HTML (domyślny, indeksowany). Tłumaczenia EN w atrybutach:
`data-en` (tekst), `data-en-html` (HTML), `data-en-placeholder`, `data-en-aria-label`, `data-en-content`.
Wybór języka: `?lang=en` → localStorage → język przeglądarki.

## Przed publikacją
- Podmień przykładowe dane (liczby, historia zatrudnienia, certyfikaty, case studies, NIP, e-mail, LinkedIn) — E-E-A-T wymaga prawdziwych informacji.
- Ustaw `FORM_ENDPOINT` w skrypcie (bez niego formularz otwiera `mailto:`).
- Dodaj `/og-image.png` (1200×630), `/favicon.svg`, `/polityka-prywatnosci`, `sitemap.xml`, `robots.txt`.
- Artykuły poradnika potrzebują osobnych stron pod `/poradnik/<slug>`.
- Ceny, telefon i realizacje to przykłady — ustaw własne.

## Czy backend w Spring Boot?
Na teraz — nie. Statyczny frontend na CDN (Vercel / Netlify / Cloudflare Pages) jest szybszy, tańszy i bezpieczniejszy.
Formularz: Formspree / Web3Forms albo jedna funkcja serverless. Blog: Markdown w repo + generator statyczny (Astro).
Spring Boot ma sens, gdy pojawi się: panel klienta, logowanie, płatności, rezerwacje albo gdy chcesz pokazać backend jako osobny projekt w portfolio.

## Wdrożenie na własny serwer (nginx)
Pliki w `deploy/`: `nginx-mateuszkielbasa.dev.conf` (konfiguracja vhosta) i `deploy.sh` (aktualizacja z GitHuba).
