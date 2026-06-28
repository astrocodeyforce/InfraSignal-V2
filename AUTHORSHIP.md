# Authorship & Attribution

## Project
**InfraSignal** — a civic infrastructure-reporting platform that lets U.S. residents
report public infrastructure problems and routes each report to the correct level of
government (city → county → state).

## Creator & Lead Engineer
**Mansur Islamov** (GitHub: [@astrocodeyforce](https://github.com/astrocodeyforce))
designed, built, deployed, and operates InfraSignal.

## Built on open-source foundations
InfraSignal is built on the open-source **FixMyStreet** platform created by
[mySociety](https://www.mysociety.org/), licensed under the **GNU Affero General Public
License v3 (AGPL-3.0)**. InfraSignal gratefully builds on that foundation and remains
AGPL-licensed. Upstream: https://github.com/mysociety/fixmystreet

## InfraSignal-specific work by Mansur Islamov
The following components were designed and implemented for InfraSignal (i.e., they are
not part of the upstream FixMyStreet platform):

- **AI image moderation** integration (SightEngine) for automated screening of uploaded report photos.
- **AI text assessment** integration (OpenAI) for automated review of report descriptions.
- **Geographic priority-zone classifier** using OpenStreetMap data to add priority context to reports.
- **U.S. multi-jurisdiction configuration** — U.S. Census body data and city/county/state routing setup, plus branded UI/templates.
- **Production operations & infrastructure** — multi-environment Docker deployment, CI to container registry, automated backups, health checks, and deploy/rollback tooling (single VPS, Cloudflare-fronted).

## License
This repository is distributed under AGPL-3.0 (see `LICENSE.txt`). In accordance with
AGPL §13, the complete corresponding source of the running version is available from
this repository.
