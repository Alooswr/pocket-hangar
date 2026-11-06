"""Compose NPC station names, which the JSONL SDE does not ship as a field.

Rule (checked against ESI /universe/names for all 5210 NPC stations of build 3670638, 0 mismatches):

    <orbit part> - <owner corporation>[ <operation name>]

orbit part:
    station orbits a planet: planet.uniqueName, else "<system> <roman(planet.celestialIndex)>"
    station orbits a moon:   moon.uniqueName,   else "<planet part> - Moon <moon.orbitIndex>"
    anything else:           "<system>"

ESI returns English station names for every Accept-Language, so the Chinese name is composed from
the Chinese parts with the same layout ("Moon" becomes "卫星").
"""

from __future__ import annotations

_ROMAN = [
    (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"),
    (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
]

MOON_WORD = {"en": "Moon", "zh": "卫星"}


def roman(number: int) -> str:
    if number <= 0:
        raise ValueError(f"roman numerals start at 1, got {number}")
    out = []
    for value, symbol in _ROMAN:
        while number >= value:
            out.append(symbol)
            number -= value
    return "".join(out)


def _localized(names: dict | None, lang: str) -> str | None:
    if not names:
        return None
    return names.get(lang) or names.get("en")


class StationNamer:
    """planets/moons map id -> {celestialIndex, orbitID, orbitIndex, uniqueName}."""

    def __init__(self, systems: dict, planets: dict, moons: dict, corporations: dict, operations: dict):
        self.systems = systems  # id -> localized name dict
        self.planets = planets
        self.moons = moons
        self.corporations = corporations  # id -> localized name dict
        self.operations = operations  # id -> localized operationName dict

    def _planet_part(self, planet_id: int, system_name: str, lang: str) -> str:
        planet = self.planets[planet_id]
        unique = _localized(planet.get("uniqueName"), lang)
        if unique:
            return unique
        return f"{system_name} {roman(planet['celestialIndex'])}"

    def name(self, station: dict, lang: str = "en") -> str:
        system_name = _localized(self.systems.get(station["solarSystemID"]), lang) or str(station["solarSystemID"])
        orbit_id = station.get("orbitID")
        if orbit_id in self.planets:
            orbit_part = self._planet_part(orbit_id, system_name, lang)
        elif orbit_id in self.moons:
            moon = self.moons[orbit_id]
            unique = _localized(moon.get("uniqueName"), lang)
            if unique:
                orbit_part = unique
            else:
                planet_part = self._planet_part(moon["orbitID"], system_name, lang)
                orbit_part = f"{planet_part} - {MOON_WORD.get(lang, 'Moon')} {moon['orbitIndex']}"
        else:
            orbit_part = system_name

        owner = _localized(self.corporations.get(station.get("ownerID")), lang) or ""
        tail = owner
        if station.get("useOperationName"):
            operation = _localized(self.operations.get(station.get("operationID")), lang)
            if operation:
                tail = f"{tail} {operation}".strip()
        return f"{orbit_part} - {tail}" if tail else orbit_part
