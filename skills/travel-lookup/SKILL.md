---
name: travel-lookup
description: Retrieve named-location weather, China geocoding, POIs and routes, global places, hotels, flights and events, plus explicitly confirmed paid flight-status data through the websearch MCP. Use for lightweight travel facts rather than full trip planning or booking.
---

# Travel Lookup

Use the MCP server named `websearch`.

## Route

- Prefer OpenMinis native iOS weather for the phone's immediate location. Use `weather_search` for
  a named or remote place; automatic routing prefers AMap for Chinese names and OpenWeather abroad.
- Use `geo_search` for China:
  - `geocode`, `reverse_geocode`, or `poi` for location data.
  - `route` with `origin`, `destination`, and `mode=driving|walking|transit`.
- Use `travel_search` for global places, hotels, scheduled flight options, and events.
- Use `aviation_search` only for VariFlight real-time status, airport weather, aircraft tracking,
  transfers, or comfort data.

```sh
minis-mcp-cli call websearch weather_search --input '{"location":"东京","days":3}'
minis-mcp-cli call websearch geo_search --input '{"action":"route","origin":"上海虹桥站","destination":"外滩","city":"上海","mode":"driving"}'
minis-mcp-cli call websearch travel_search --input '{"kind":"hotels","query":"Tokyo Station hotels","check_in_date":"2026-10-01","check_out_date":"2026-10-03"}'
```

## Paid aviation rule

First call `aviation_search` with `confirm_paid=false`. Show the returned price to the user and ask
for explicit confirmation. Only after confirmation, repeat the exact request with
`confirm_paid=true`. Never infer confirmation or silently change the flight/date parameters.

Do not claim that a booking, reservation, calendar event, or purchase occurred. For multi-day
planning and complex optimization, collect a compact evidence set and hand the task to OpenClaw.
