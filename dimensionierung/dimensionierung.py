#!/usr/bin/env python3
"""Luftvolumenströme nach DIN 1946-6 (Ausgabe 2019) für ventilatorgestützte Lüftung.

Aufruf:  python3 dimensionierung.py [gebaeude.json]
Ausgabe: ergebnis.md, stufen.csv, raeume.csv, sweep.csv im selben Ordner.

Alle Normwerte stehen in NORM unten und lassen sich anpassen. Werte bitte gegen
die Norm prüfen, bevor ein Gerät bestellt wird.
"""
import csv, json, sys
from pathlib import Path

NORM = {
    # q_NL = a*A² + b*A + c  [m³/h], A = Fläche der Nutzungseinheit [m²]
    "nl_a": -0.002, "nl_b": 1.15, "nl_c": 11.0,
    "f_ws": {"hoch": 0.2, "niedrig": 0.3},      # Feuchteschutz-Faktor
    "f_rl": 0.7, "f_il": 1.3,                   # reduziert / intensiv relativ zu NL
    "person_m3h": 30.0,                         # personenbezogene Nennlüftung
    "abluft_min": {"kueche": 45, "bad": 45, "dusche": 45, "wc": 25, "hwr": 25, "sauna": 100},
    "zuluft_faktor": {"wohnzimmer": 3.0, "schlafzimmer": 2.0, "kinderzimmer": 2.0,
                      "esszimmer": 1.5, "arbeitszimmer": 1.5, "gaestezimmer": 1.5},
}
STUFEN = ["FL", "RL", "NL", "IL"]
STUFEN_NAME = {"FL": "Feuchteschutz", "RL": "Reduziert", "NL": "Nennlüftung", "IL": "Intensiv"}


def q_nl_flaeche(a):
    return NORM["nl_a"] * a * a + NORM["nl_b"] * a + NORM["nl_c"]


def berechne(g):
    flaeche = sum(r["flaeche_m2"] for r in g["raeume"])
    volumen = flaeche * g.get("raumhoehe_m", 2.5)
    abluft_summe = sum(NORM["abluft_min"].get(r["art"], 0) for r in g["raeume"] if r["typ"] == "abluft")
    q_flaeche = q_nl_flaeche(flaeche)
    q_person = g["personen"] * NORM["person_m3h"]
    nl = max(q_flaeche, q_person, abluft_summe)
    massgebend = {q_flaeche: "Fläche", q_person: "Personen", abluft_summe: "Abluftbedarf"}[nl]
    stufen = {
        "FL": NORM["f_ws"][g.get("waermeschutz", "hoch")] * q_flaeche,
        "RL": NORM["f_rl"] * nl,
        "NL": nl,
        "IL": NORM["f_il"] * nl,
    }
    return {"flaeche": flaeche, "volumen": volumen, "q_flaeche": q_flaeche, "q_person": q_person,
            "abluft_summe": abluft_summe, "massgebend": massgebend, "stufen": stufen}


def raumaufteilung(g, q):
    """Zuluft nach Raumfaktoren, Abluft proportional zu den Mindestwerten."""
    zu = [r for r in g["raeume"] if r["typ"] == "zuluft"]
    ab = [r for r in g["raeume"] if r["typ"] == "abluft"]
    fz = sum(NORM["zuluft_faktor"].get(r["art"], 1.5) for r in zu) or 1
    fa = sum(NORM["abluft_min"].get(r["art"], 25) for r in ab) or 1
    zeilen = []
    for r in g["raeume"]:
        werte = {}
        for s, v in q.items():
            if r["typ"] == "zuluft":
                werte[s] = v * NORM["zuluft_faktor"].get(r["art"], 1.5) / fz
            elif r["typ"] == "abluft":
                werte[s] = v * NORM["abluft_min"].get(r["art"], 25) / fa
            else:
                werte[s] = 0.0
        zeilen.append((r, werte))
    return zeilen


def main():
    pfad = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).with_name("gebaeude.json")
    g = json.loads(pfad.read_text(encoding="utf-8"))
    out = pfad.parent
    e = berechne(g)
    q = e["stufen"]

    with open(out / "stufen.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["stufe", "name", "m3h", "luftwechsel_1h"])
        for s in STUFEN:
            w.writerow([s, STUFEN_NAME[s], round(q[s]), round(q[s] / e["volumen"], 2)])

    zeilen = raumaufteilung(g, q)
    with open(out / "raeume.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["raum", "typ", "flaeche_m2"] + [f"{s}_m3h" for s in STUFEN])
        for r, werte in zeilen:
            w.writerow([r["name"], r["typ"], r["flaeche_m2"]] + [round(werte[s]) for s in STUFEN])

    # Sensitivität: Fläche und Personen variieren, um die Spannweite zu sehen
    sweep = []
    for a in range(80, 241, 20):
        for p in (2, 4, 6):
            gg = dict(g, personen=p, raeume=[{"name": "x", "flaeche_m2": a, "typ": "zuluft", "art": ""}] +
                      [r for r in g["raeume"] if r["typ"] == "abluft"])
            gg["raeume"][0]["flaeche_m2"] = a - sum(r["flaeche_m2"] for r in gg["raeume"][1:])
            ee = berechne(gg)
            sweep.append((a, p, *(round(ee["stufen"][s]) for s in STUFEN)))
    with open(out / "sweep.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["flaeche_m2", "personen"] + [f"{s}_m3h" for s in STUFEN])
        w.writerows(sweep)

    # Geräteempfehlung: NL soll bei ca. 60-70 % der Gerätenennleistung liegen (Akustik, Effizienz),
    # IL muss bei realistischem Kanaldruck (100-150 Pa) noch erreichbar sein.
    geraet_min = max(q["IL"], q["NL"] / 0.7)
    L = [f"# Luftmengen {g['name']} (DIN 1946-6)", "",
         f"Fläche {e['flaeche']:.0f} m², Volumen {e['volumen']:.0f} m³, {g['personen']} Personen, "
         f"Wärmeschutz {g.get('waermeschutz', 'hoch')}.", "",
         f"Nennlüftung nach Fläche {e['q_flaeche']:.0f} m³/h, nach Personen {e['q_person']:.0f} m³/h, "
         f"Abluft-Mindestsumme {e['abluft_summe']:.0f} m³/h. Maßgebend: **{e['massgebend']}**.", "",
         "| Stufe | m³/h | Luftwechsel 1/h |", "|---|---:|---:|"]
    L += [f"| {STUFEN_NAME[s]} ({s}) | {q[s]:.0f} | {q[s] / e['volumen']:.2f} |" for s in STUFEN]
    L += ["", f"**Gerät:** mindestens {geraet_min:.0f} m³/h bei 100-150 Pa externer Pressung; "
          f"Regelbereich bis hinunter auf {q['FL']:.0f} m³/h.", "",
          "| Raum | Typ | m² | " + " | ".join(STUFEN) + " |", "|---|---|---:|" + "---:|" * len(STUFEN)]
    L += [f"| {r['name']} | {r['typ']} | {r['flaeche_m2']} | " + " | ".join(f"{werte[s]:.0f}" for s in STUFEN) + " |"
          for r, werte in zeilen]
    (out / "ergebnis.md").write_text("\n".join(L) + "\n", encoding="utf-8")
    print("\n".join(L))


if __name__ == "__main__":
    main()
