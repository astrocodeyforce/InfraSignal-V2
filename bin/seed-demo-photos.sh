#!/usr/bin/env bash
# Seed reports with category-appropriate demo photos for an environment.
#
#   Usage:  bin/seed-demo-photos.sh <dev|staging>
#
# Assigns one of 13 photorealistic "citizen report" photos (one per distinct
# issue type) to EVERY visible report, by category, so the environment looks
# credible. Reports keep fully independent per-id photo caches, so a later
# real upload on one report never affects another (FixMyStreet caches photos
# by report id; a new upload is content-hashed and only repoints that report).
#
# PROD is intentionally NOT a target: it is the clean customer-facing site.
set -euo pipefail

ENV="${1:-}"
case "$ENV" in
  staging)
    FMS=staging-fixmystreet-1; DB=staging-db-1
    PHOTODIR=/opt/infrasignal-staging/web/photo
    BASE=http://127.0.0.1:8080 ;;
  dev)
    FMS=infrasignal-dev-dev-fixmystreet-1; DB=infrasignal-dev-dev-db-1
    PHOTODIR=/opt/infrasignal-dev/web/photo
    BASE=http://127.0.0.1:3001 ;;
  *)
    echo "Usage: $0 <dev|staging>" >&2; exit 2 ;;
esac

ASSETS=${ASSETS:-/opt/infrasignal-dev/demo-assets/category-photos}
echo ">> seeding env=$ENV  db=$DB  photodir=$PHOTODIR"

psql() { sudo docker exec "$DB" psql -U postgres -d infrasignal "$@"; }

# 17 category strings -> 13 distinct master images
declare -A CAT2IMG=(
  ["Pothole / Road Damage"]="cat-pothole.jpg"
  ["Pothole & Road"]="cat-pothole.jpg"
  ["Sidewalk Damage"]="cat-sidewalk.jpg"
  ["Sidewalk"]="cat-sidewalk.jpg"
  ["Streetlight Outage"]="cat-streetlight.jpg"
  ["Streetlight"]="cat-streetlight.jpg"
  ["Abandoned Vehicle"]="cat-abandoned-vehicle.jpg"
  ["Illegal Dumping"]="cat-illegal-dumping.jpg"
  ["Graffiti / Vandalism"]="cat-graffiti.jpg"
  ["Graffiti"]="cat-graffiti.jpg"
  ["Traffic Signal / Sign Issue"]="cat-traffic-signal.jpg"
  ["Drainage / Flooding"]="cat-drainage.jpg"
  ["Park / Public Space Issue"]="cat-park.jpg"
  ["Fallen Tree / Vegetation"]="cat-fallen-tree.jpg"
  ["Water / Sewer Issue"]="cat-water-sewer.jpg"
  ["Bridge / Guardrail Damage"]="cat-bridge.jpg"
  ["Other"]="cat-other.jpg"
)

# 1) hash each distinct master + copy into the app's UPLOAD_DIR
declare -A IMG2HASH
for img in $(printf '%s\n' "${CAT2IMG[@]}" | sort -u); do
  h=$(sha1sum "$ASSETS/$img" | cut -c1-40)
  IMG2HASH["$img"]="$h"
  sudo docker cp "$ASSETS/$img" "$FMS:/var/www/upload/$h.jpeg" >/dev/null
  echo "master $img -> $h.jpeg"
done

# 2) per category: set photo on all reports, build fresh variants on a rep, fan out
for cat in "${!CAT2IMG[@]}"; do
  img="${CAT2IMG[$cat]}"
  h="${IMG2HASH[$img]}"
  ids=$(psql -A -t -c "SELECT id FROM problem WHERE state NOT IN ('hidden') AND category=\$\$${cat}\$\$ ORDER BY id;")
  ids=$(echo $ids)
  [ -z "$ids" ] && { echo "skip (no reports): $cat"; continue; }
  psql -q -c "UPDATE problem SET photo='${h}.jpeg' WHERE state NOT IN ('hidden') AND category=\$\$${cat}\$\$;" >/dev/null
  rep=$(echo "$ids" | tr ' ' '\n' | head -1)
  sudo rm -f "$PHOTODIR/$rep.0.fp.jpeg" "$PHOTODIR/$rep.0.tn.jpeg" "$PHOTODIR/$rep.0.jpeg"
  for u in "$rep.0.fp.jpeg" "$rep.0.tn.jpeg" "$rep.0.jpeg"; do
    curl -s -o /dev/null "$BASE/photo/$u"
  done
  sudo cp -f "$ASSETS/$img" "$PHOTODIR/$rep.0.full.jpeg"
  n=1
  for id in $ids; do
    [ "$id" = "$rep" ] && continue
    sudo cp -f "$PHOTODIR/$rep.0.fp.jpeg" "$PHOTODIR/$id.0.fp.jpeg"
    sudo cp -f "$PHOTODIR/$rep.0.tn.jpeg" "$PHOTODIR/$id.0.tn.jpeg"
    sudo cp -f "$PHOTODIR/$rep.0.jpeg"    "$PHOTODIR/$id.0.jpeg"
    sudo cp -f "$ASSETS/$img"             "$PHOTODIR/$id.0.full.jpeg"
    n=$((n+1))
  done
  echo "seeded $cat: $n reports (rep=$rep, $img)"
done
echo "DONE ($ENV)"
