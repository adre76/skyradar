from flask import Flask, render_template, jsonify, request
from werkzeug.middleware.proxy_fix import ProxyFix
import requests
import math

app = Flask(__name__)

# Necessário para funcionar corretamente atrás do nginx-ingress:
# - x_for=1   → respeita X-Forwarded-For (IP real do cliente)
# - x_prefix=1 → respeita X-Forwarded-Prefix (/radar), corrigindo url_for() etc.
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)

OPENSKY_URL = "https://opensky-network.org/api/states/all"


def get_aircraft_nearby(lat, lon, radius_km=150):
    """Fetch aircraft from OpenSky Network within a bounding box."""
    deg = radius_km / 111.0
    lamin = lat - deg
    lamax = lat + deg
    lomin = lon - deg * math.cos(math.radians(lat))
    lomax = lon + deg * math.cos(math.radians(lat))

    params = {
        "lamin": lamin, "lamax": lamax,
        "lomin": lomin, "lomax": lomax,
    }

    try:
        resp = requests.get(OPENSKY_URL, params=params, timeout=15)
        resp.raise_for_status()
        data = resp.json()
    except Exception as e:
        return [], str(e)

    states = data.get("states") or []
    aircraft = []
    for s in states:
        # s[5]=lon, s[6]=lat, s[8]=on_ground, s[10]=heading, s[7]=baro_alt, s[9]=velocity
        if s[5] is None or s[6] is None:
            continue
        if s[8]:  # skip grounded
            continue
        aircraft.append({
            "icao":      s[0].strip() if s[0] else "?",
            "callsign":  (s[1] or "").strip() or "N/A",
            "country":   s[2] or "?",
            "lon":       s[5],
            "lat":       s[6],
            "alt_m":     s[7],
            "alt_ft":    round(s[7] * 3.28084) if s[7] else None,
            "speed_ms":  s[9],
            "speed_kts": round(s[9] * 1.94384) if s[9] else None,
            "heading":   s[10] or 0,
            "squawk":    s[14] or "?",
        })
    return aircraft, None


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/aircraft")
def aircraft():
    lat = request.args.get("lat", type=float)
    lon = request.args.get("lon", type=float)
    radius = request.args.get("radius", default=150, type=int)

    if lat is None or lon is None:
        return jsonify({"error": "lat/lon required"}), 400

    planes, err = get_aircraft_nearby(lat, lon, radius)
    return jsonify({
        "count": len(planes),
        "aircraft": planes,
        "error": err,
        "center": {"lat": lat, "lon": lon},
    })


if __name__ == "__main__":
    print("\n🛫  SkyRadar iniciado! Abra http://localhost:5000\n")
    app.run(debug=True, port=5000)
