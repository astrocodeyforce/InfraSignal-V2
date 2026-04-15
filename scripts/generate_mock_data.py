#!/usr/bin/env python3
"""
Generate mock data for InfraSignal reports dashboard.
Inserts problems + fix comments into PostgreSQL, then writes all-reports-dashboard.json.
"""
import json, random, math
from datetime import datetime, timedelta

# ---------- CONFIG ----------
DB_HOST = "postgres.svc"
DB_NAME = "infrasignal"
DB_USER = "postgres"
DB_PASS = "M6p52lFbhHQHHvZ4tVYRFOGnhUXbTBde6ftxTPMN"

USER_ID = 10       # Leila Ataeva
BASE_LAT = 42.170  # Buffalo Grove IL area
BASE_LON = -87.983
COBRAND = "infrasignal"

# Bodies to distribute reports across (IL cities)
# All reports are generated in the Buffalo Grove area, so they should all
# be assigned to Buffalo Grove, IL — the body that covers this geography.
BODIES = [
    (10588, "Buffalo Grove, IL"),
]

CATEGORIES = [
    "Pothole / Road Damage",
    "Streetlight Outage",
    "Sidewalk Damage",
    "Abandoned Vehicle",
    "Graffiti / Vandalism",
    "Drainage / Flooding",
    "Traffic Signal / Sign Issue",
    "Fallen Tree / Vegetation",
    "Park / Public Space Issue",
    "Illegal Dumping",
    "Water / Sewer Issue",
    "Bridge / Guardrail Damage",
    "Other",
]

# Category weights (potholes are most common)
CAT_WEIGHTS = [25, 15, 12, 10, 8, 8, 6, 5, 4, 3, 2, 1, 1]

TITLES = {
    "Pothole / Road Damage": ["Large pothole on Main St", "Road crumbling near school", "Pothole causing tire damage", "Deep pothole at intersection"],
    "Streetlight Outage": ["Streetlight out on Oak Ave", "Dark street near park", "Flickering light on 5th", "Street lamp broken"],
    "Sidewalk Damage": ["Cracked sidewalk tripping hazard", "Raised sidewalk slab", "Sidewalk buckled by tree roots"],
    "Abandoned Vehicle": ["Abandoned car on Elm St", "Vehicle left for weeks", "Rusty car blocking street"],
    "Graffiti / Vandalism": ["Graffiti on bridge underpass", "Vandalized bus stop", "Spray paint on building"],
    "Drainage / Flooding": ["Street flooding after rain", "Blocked storm drain", "Standing water at corner"],
    "Traffic Signal / Sign Issue": ["Stop sign knocked down", "Traffic light stuck on red", "Faded yield sign"],
    "Fallen Tree / Vegetation": ["Tree blocking sidewalk", "Large branch on road", "Overgrown bushes blocking view"],
    "Park / Public Space Issue": ["Broken swing at park", "Litter in public park", "Bench damaged"],
    "Illegal Dumping": ["Mattress dumped on roadside", "Construction debris dumped", "Trash pile growing"],
    "Water / Sewer Issue": ["Hydrant leaking", "Sewer smell on Pine St", "Water main break"],
    "Bridge / Guardrail Damage": ["Guardrail bent after accident", "Bridge railing loose"],
    "Other": ["General maintenance needed", "Noise complaint", "Other issue observed"],
}

NAMES = ["Alex M", "Jordan K", "Sam T", "Pat R", "Chris B", "Morgan L", "Taylor S", "Casey D", "Riley W", "Jamie P"]

# ---------- GENERATE PROBLEMS ----------
now = datetime(2026, 4, 9, 12, 0, 0)
problems = []

# Generate ~580 problems over the past 12 months
for month_offset in range(12, 0, -1):
    # More reports in recent months (growth trend)
    base_count = int(25 + (12 - month_offset) * 3.5 + random.randint(-5, 5))
    
    for _ in range(base_count):
        month_start = now - timedelta(days=month_offset * 30)
        day_offset = random.randint(0, 29)
        report_date = month_start + timedelta(days=day_offset, hours=random.randint(6, 22), minutes=random.randint(0, 59))
        
        cat_idx = random.choices(range(len(CATEGORIES)), weights=CAT_WEIGHTS, k=1)[0]
        category = CATEGORIES[cat_idx]
        body_id, body_name = random.choice(BODIES)
        title = random.choice(TITLES[category])
        name = random.choice(NAMES)
        
        lat = BASE_LAT + random.uniform(-0.05, 0.05)
        lon = BASE_LON + random.uniform(-0.05, 0.05)
        
        # ~87% fix rate, older reports more likely to be fixed
        days_old = (now - report_date).days
        fix_probability = min(0.95, 0.5 + days_old / 400)
        is_fixed = random.random() < fix_probability
        
        # Fix time: 1-14 days, with variation
        fix_days = random.uniform(0.5, 14) if is_fixed else None
        fix_date = report_date + timedelta(days=fix_days) if is_fixed else None
        
        state = "fixed - council" if is_fixed else "confirmed"
        
        problems.append({
            "lat": lat,
            "lon": lon,
            "body_id": body_id,
            "body_name": body_name,
            "category": category,
            "title": title,
            "detail": f"{title}. Reported by a community member.",
            "name": name,
            "state": state,
            "confirmed": report_date,
            "lastupdate": fix_date if fix_date else report_date,
            "is_fixed": is_fixed,
            "fix_date": fix_date,
        })

# Add some reports in the last 7 days
for _ in range(57):
    day_offset = random.randint(0, 6)
    report_date = now - timedelta(days=day_offset, hours=random.randint(6, 22))
    
    cat_idx = random.choices(range(len(CATEGORIES)), weights=CAT_WEIGHTS, k=1)[0]
    category = CATEGORIES[cat_idx]
    body_id, body_name = random.choice(BODIES)
    title = random.choice(TITLES[category])
    name = random.choice(NAMES)
    
    lat = BASE_LAT + random.uniform(-0.05, 0.05)
    lon = BASE_LON + random.uniform(-0.05, 0.05)
    
    is_fixed = random.random() < 0.3  # fewer recent ones fixed
    fix_days = random.uniform(0.5, 5) if is_fixed else None
    fix_date = report_date + timedelta(days=fix_days) if is_fixed and (report_date + timedelta(days=fix_days)) < now else None
    is_fixed = fix_date is not None
    
    state = "fixed - council" if is_fixed else "confirmed"
    
    problems.append({
        "lat": lat,
        "lon": lon,
        "body_id": body_id,
        "body_name": body_name,
        "category": category,
        "title": title,
        "detail": f"{title}. Reported by a community member.",
        "name": name,
        "state": state,
        "confirmed": report_date,
        "lastupdate": fix_date if fix_date else report_date,
        "is_fixed": is_fixed,
        "fix_date": fix_date,
    })

# Sort by date
problems.sort(key=lambda p: p["confirmed"])

print(f"Generated {len(problems)} problems")
print(f"Fixed: {sum(1 for p in problems if p['is_fixed'])}")
print(f"Confirmed: {sum(1 for p in problems if not p['is_fixed'])}")

# ---------- BUILD JSON DATA ----------

# Monthly periods (month numbers for last ~12 months)
month_names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
periods = []
reported_by_period = []
fixed_by_period = []

for month_offset in range(12, 0, -1):
    target = now - timedelta(days=month_offset * 30)
    month_num = target.month
    periods.append(month_names[month_num - 1])
    
    month_start = datetime(target.year, target.month, 1)
    if target.month == 12:
        month_end = datetime(target.year + 1, 1, 1)
    else:
        month_end = datetime(target.year, target.month + 1, 1)
    
    reported = sum(1 for p in problems if month_start <= p["confirmed"] < month_end)
    fixed = sum(1 for p in problems if p["is_fixed"] and p["fix_date"] and month_start <= p["fix_date"] < month_end)
    
    reported_by_period.append(reported)
    fixed_by_period.append(fixed)

# Last 7 days
last_7_problems = [0] * 7
last_7_updated = [0] * 7
last_7_fixed = [0] * 7
seven_days_ago = now - timedelta(days=7)

for p in problems:
    if p["confirmed"] >= seven_days_ago:
        day_idx = (p["confirmed"] - seven_days_ago).days
        if 0 <= day_idx < 7:
            last_7_problems[day_idx] += 1
            if p["is_fixed"]:
                last_7_fixed[day_idx] += 1
            last_7_updated[day_idx] += random.randint(0, 2)  # some updates

total_reported = len(problems)
total_fixed = sum(1 for p in problems if p["is_fixed"])
week_reported = sum(last_7_problems)
week_updated = sum(last_7_updated)
week_fixed = sum(last_7_fixed)

# Top 5 bodies by average fix time
body_fix_times = {}
for p in problems:
    if p["is_fixed"] and p["fix_date"]:
        bid = p["body_name"]
        days = (p["fix_date"] - p["confirmed"]).total_seconds() / 86400
        body_fix_times.setdefault(bid, []).append(days)

top_bodies = []
for name, times in sorted(body_fix_times.items(), key=lambda x: sum(x[1]) / len(x[1])):
    avg = round(sum(times) / len(times), 1)
    top_bodies.append({"name": name, "days": avg})
    if len(top_bodies) >= 5:
        break

# Top 5 categories (last 7 days)
cat_counts = {}
for p in problems:
    if p["confirmed"] >= seven_days_ago:
        cat_counts[p["category"]] = cat_counts.get(p["category"], 0) + 1

top_cats = sorted(cat_counts.items(), key=lambda x: -x[1])[:5]
other_cat_count = sum(v for k, v in cat_counts.items() if (k, v) not in top_cats[:5])
top_five_categories = [{"category": cat, "count": cnt} for cat, cnt in top_cats]

# Average days to fix (last 100)
fix_times = []
for p in sorted(problems, key=lambda x: x["confirmed"], reverse=True):
    if p["is_fixed"] and p["fix_date"]:
        fix_times.append((p["fix_date"] - p["confirmed"]).total_seconds() / 86400)
    if len(fix_times) >= 100:
        break

avg_days = round(sum(fix_times) / len(fix_times), 1) if fix_times else None

# Build JSON
dashboard_data = {
    "problem_periods": periods,
    "problems_reported_by_period": reported_by_period,
    "problems_fixed_by_period": fixed_by_period,
    "last_seven_days": {
        "problems": last_7_problems,
        "problems_total": week_reported,
        "updated": last_7_updated,
        "updated_total": week_updated,
        "fixed": last_7_fixed,
        "fixed_total": week_fixed,
    },
    "top_five_bodies": top_bodies,
    "top_five_categories": top_five_categories,
    "other_categories": other_cat_count,
    "average": avg_days,
}

print(f"\n--- Dashboard JSON ---")
print(json.dumps(dashboard_data, indent=2))

# Write JSON file
with open("/var/www/data/all-reports-dashboard.json", "w") as f:
    json.dump(dashboard_data, f)
print(f"\nWrote /var/www/data/all-reports-dashboard.json")

# ---------- INSERT INTO DATABASE ----------
import subprocess, sys

# Build SQL for problems
sql_lines = []
sql_lines.append("BEGIN;")

# Don't delete existing - just add new ones
for i, p in enumerate(problems):
    confirmed = p["confirmed"].strftime("%Y-%m-%d %H:%M:%S")
    lastupdate = p["lastupdate"].strftime("%Y-%m-%d %H:%M:%S") if p["lastupdate"] else confirmed
    title_esc = p["title"].replace("'", "''")
    detail_esc = p["detail"].replace("'", "''")
    name_esc = p["name"].replace("'", "''")
    cat_esc = p["category"].replace("'", "''")
    
    sql_lines.append(f"""INSERT INTO problem (postcode, latitude, longitude, bodies_str, areas, category, title, detail, used_map, user_id, name, anonymous, state, lang, service, cobrand, cobrand_data, confirmed, lastupdate, created)
VALUES ('', {p['lat']:.6f}, {p['lon']:.6f}, '{p['body_id']}', ',959228,', '{cat_esc}', '{title_esc}', '{detail_esc}', true, {USER_ID}, '{name_esc}', true, '{p['state']}', 'en-gb', 'desktop', '{COBRAND}', '', '{confirmed}', '{lastupdate}', '{confirmed}');""")

    # Add fix comment if fixed
    if p["is_fixed"] and p["fix_date"]:
        fix_ts = p["fix_date"].strftime("%Y-%m-%d %H:%M:%S")
        sql_lines.append(f"""INSERT INTO comment (problem_id, user_id, anonymous, name, text, state, cobrand, lang, cobrand_data, mark_fixed, mark_open, problem_state, confirmed, created)
VALUES (currval('problem_id_seq'), {USER_ID}, true, '{name_esc}', 'Problem has been fixed.', 'confirmed', '{COBRAND}', 'en-gb', '', true, false, 'fixed - council', '{fix_ts}', '{fix_ts}');""")

sql_lines.append("COMMIT;")

sql_text = "\n".join(sql_lines)

# Write SQL to temp file and execute
with open("/tmp/mock_data.sql", "w") as f:
    f.write(sql_text)

print(f"\nGenerated {len([l for l in sql_lines if l.startswith('INSERT INTO problem')])} INSERT statements")
print(f"Executing SQL...")

result = subprocess.run(
    ["psql", "-h", DB_HOST, "-U", DB_USER, "-d", DB_NAME, "-f", "/tmp/mock_data.sql"],
    capture_output=True, text=True,
    env={"PGPASSWORD": DB_PASS, "PATH": "/usr/bin:/bin"}
)

if result.returncode == 0:
    print("SQL executed successfully!")
    # Count final
    result2 = subprocess.run(
        ["psql", "-h", DB_HOST, "-U", DB_USER, "-d", DB_NAME, "-c",
         "SELECT COUNT(*) as total, COUNT(CASE WHEN state LIKE 'fixed%' THEN 1 END) as fixed FROM problem;"],
        capture_output=True, text=True,
        env={"PGPASSWORD": DB_PASS, "PATH": "/usr/bin:/bin"}
    )
    print(result2.stdout)
else:
    print(f"SQL errors:\n{result.stderr[:2000]}")
