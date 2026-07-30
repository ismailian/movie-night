# 🎬 Reel Roulette

A random movie picker built with **Flutter + Dart**. Press the glowing button, watch the film‑reel spin and decelerate onto a pick, then see its full metadata pulled live from the **OMDb API** (IMDb‑sourced data): poster, IMDb rating, year, genres, plot, director and cast — plus one‑tap **Watch Trailer** and **Open in IMDb**.

## Quick start

```bash
# 1. Generate the android/ios/web platform folders (keeps your lib/ + pubspec)
flutter create .

# 2. Install dependencies
flutter pub get

# 3. Add your OMDb API key (see below), then run
flutter run
```

Requires Flutter 3.19+ (Dart SDK ≥ 3.3).

## Add your API key

There is **no free official IMDb API** — IMDb's own API is enterprise‑only. This app uses **OMDb**, the standard free stand‑in that serves IMDb data.

1. Get a free key (1,000 lookups/day): https://www.omdbapi.com/apikey.aspx
2. Open `lib/config/api_config.dart` and replace `PASTE_YOUR_KEY_HERE` with your key.

Or pass it at run time without editing code:

```bash
flutter run --dart-define=OMDB_API_KEY=yourkeyhere
```

The app still runs without a key — it just shows an "add your key" card instead of real metadata.

## Use your own movie list

Edit `assets/movies.csv`. Only a **title** column is required; `year` and `imdb_id` are optional but improve accuracy (an `imdb_id` like `tt1375666` makes the lookup exact).

```csv
title,year,imdb_id
Inception,2010,tt1375666
Parasite,2019,tt6751668
```

The CSV parser is forgiving about headers (case‑insensitive):

| Field | Accepted column names |
|-------|-----------------------|
| title | `title`, `name`, `movie`, `primaryTitle`, `originalTitle` |
| year  | `year`, `release_year`, `startYear` |
| imdb  | `imdb_id`, `imdbid`, `imdb`, `tconst`, `id` |

After changing the CSV, hot‑restart (not just hot‑reload) so the asset reloads.

## How it picks

The movie is chosen **before** the animation — the reel is a visual flourish that decelerates onto the already‑selected title (`Curves.easeOutQuart`). Metadata is fetched **in parallel** while the reel spins, so the result is usually ready the moment it lands.

## Project layout

```
lib/
  config/api_config.dart        # OMDb key + endpoint
  theme/app_theme.dart          # palette + typography (Bebas Neue / Inter)
  models/                       # MovieEntry (CSV), MovieDetails (API)
  data/movie_repository.dart    # loads + parses the CSV
  services/omdb_service.dart    # OMDb lookups (by imdb id, else title+year)
  widgets/
    reel_spinner.dart           # the film‑reel slot machine (signature)
    pick_button.dart            # glowing gradient CTA with idle pulse
    movie_result_card.dart      # poster, rating, genres, plot, actions
    status_card.dart            # missing‑key / error / empty states
  screens/home_screen.dart      # orchestration
assets/movies.csv               # sample dataset (swap in your own)
```

## Notes

- **Trailers:** OMDb doesn't serve trailer links, so the button opens a YouTube search for the exact title + year. To embed real trailers, add a TMDB key and swap in its `/movie/{id}/videos` endpoint.
- **Android 11+:** if external links don't open, add an `<intent> https` entry under `<queries>` in `android/app/src/main/AndroidManifest.xml` (url_launcher docs cover this).
- Fonts (Bebas Neue, Inter) are fetched at runtime by `google_fonts`; for fully offline builds, bundle them as assets instead.
