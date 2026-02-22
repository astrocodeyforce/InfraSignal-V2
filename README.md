# InfraSignal Platform

InfraSignal is a civic infrastructure reporting platform built on the
[FixMyStreet Platform](https://fixmystreet.org/) (AGPL v3). It enables
residents to report common infrastructure problems — potholes, broken
streetlights, drainage issues, and more — to the appropriate local authority.

Reports are routed using a 3-tier priority system (city → county → state) and
include built-in content moderation powered by
[SightEngine](https://sightengine.com).

## Key Features

- **Infrastructure Reporting** — 13 built-in categories (Pothole/Road Damage,
  Streetlight Outage, Drainage/Flooding, etc.) with smart auto-fill defaults.
- **3-Tier Priority Routing** — Reports are automatically sent to the most
  local authority that handles the issue (city first, then county, then state).
- **Image Moderation** — Uploaded photos are automatically screened for nudity,
  weapons, violence, gore, drugs, offensive content, AI-generated images, and
  more via the SightEngine API.
- **Text Moderation** — Report titles and descriptions are checked for
  profanity, URLs/links, personal information (emails/phone numbers), and
  classified via ML models for sexual, discriminatory, insulting, violent, or
  toxic content.
- **Category Auto-Fill** — Selecting a report category auto-populates the
  title and description with sensible defaults that users can customise.
- **US Coverage** — Pre-loaded with US states, counties, and cities from
  Census 2020 data.
- **Multi-Language Support** — Cookie-based language switching with full
  translation across UI strings (gettext), database content (categories,
  states), and static pages. Currently available: English, Turkish (Türkçe),
  Spanish (Español), Russian (Русский). See
  `PROJECT PLAN/LANGUAGE_TRANSLATION_GUIDE.md` for adding new languages.
- **Duplicate Detection** — Geographic duplicate suggestion (500m public,
  1500m inspectors) with admin management page at `/admin/duplicate_reports`.
- **Server Scaling** — Tuned for 200–500 concurrent users: 10 Starman
  workers with preload-app, nginx rate/connection limiting, PostgreSQL
  memory optimization, and memcached tuning.

## Installation

### Docker (Recommended)

```bash
cd docker
docker compose -f docker-compose-dev.yml up -d
```

The application will be available at `http://localhost:3000`.

### Configuration

Copy the example config and fill in your settings:

```bash
cp conf/general.yml-example conf/general.yml
```

**Required settings:**
- `FMS_DB_*` — PostgreSQL database connection
- `BASE_URL` — Your public URL
- `MAPIT_URL` — MapIt instance for geographic lookups
- `ALLOWED_COBRANDS` — Set to `infrasignal`

**Content moderation (SightEngine):**
- `SIGHTENGINE_ENABLED: 1`
- `SIGHTENGINE_API_USER` — from [dashboard.sightengine.com](https://dashboard.sightengine.com)
- `SIGHTENGINE_API_SECRET` — from [dashboard.sightengine.com](https://dashboard.sightengine.com)

> **Security:** Never commit API keys or secrets to version control.
> Keep credentials in `conf/general.yml` (gitignored) or environment variables only.

See `conf/general.yml-example` for all available options.

### Development

```bash
script/server    # Start dev server with auto-reload
script/test      # Run test suite
script/update    # Update dependencies
```

## Architecture

| Component | Technology |
|-----------|-----------|
| Backend | Perl / Catalyst framework |
| Database | PostgreSQL + PostGIS |
| Templates | Template Toolkit |
| Frontend | jQuery, OpenLayers (maps) |
| Content Moderation | SightEngine API |
| Caching | Memcached (128MB, 1024 connections) |
| Containerisation | Docker Compose |

## Upstream

Based on [FixMyStreet Platform](https://github.com/mysociety/fixmystreet)
v6.0 by [mySociety](https://www.mysociety.org/). See CHANGELOG.md for the
full version history.

## Contribution Guidelines

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

GNU Affero General Public License v3 — see [LICENSE.txt](LICENSE.txt).
