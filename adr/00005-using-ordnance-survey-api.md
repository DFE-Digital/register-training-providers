# 5. Using Ordnance Survey API

**Date:** 2025-09-10

## Status

Accepted

## Context

Our service needs to be able to produce geospatial information for addresses, as well as support geospatial searches linked to those addresses. Ordnance Survey (OS) provides authoritative datasets for the UK, including address look-ups, postcodes, and geospatial coordinates.

This is especially important for **schools and other places of teaching**, since a teacher may be connected not only to the main school building but also to annexes, outbuildings, or alternative teaching sites.

## UPRN (Unique Property Reference Number)

A **UPRN** is a unique 12-digit identifier allocated by local authorities to every addressable location in Great Britain. This includes residential properties, commercial premises, land parcels, schools, and their annexes or outbuildings.

Key points:

- UPRNs are coordinated nationally by **GeoPlace** and distributed by **Ordnance Survey** through its AddressBase products.
- They provide a **stable and permanent key** for linking locations across datasets.
- Every school and teaching site in the UK will have a UPRN.

We have not yet decided whether to store UPRNs in our system, but they are noteworthy as a potential mechanism for consistent linkage across providers, schools, and teaching sites.

## Decision

We will use the Ordnance Survey Places API to retrieve geospatial data. This gives us:

- Latitude/longitude coordinates for postcodes and addresses
- Consistent UK-specific data with authoritative updates
- Free access for our use case under the OS OpenData and public sector licensing

## Alternatives considered

- **Google Maps API**:
  - Strengths: widely used, global coverage, rich mapping features, searchable by name.
  - Weaknesses: Place IDs are proprietary, not UK-specific, and may not persist. Not all school buildings or annexes are included. Data comes from a mix of commercial datasets and user contributions. Licensing restrictions apply.

- **Ordnance Survey API (chosen)**:
  - Strengths: authoritative, free under public licences, stable and permanent identifiers. Every school building, annex, or other location where teaching takes place will have a UPRN allocated by the local authority. Enables reliable data linkage across government and public sector systems.
  - Weaknesses: coverage limited to the UK only (not an issue for our core use case).

## Consequences

- We depend on Ordnance Survey’s API uptime and availability.
- We must manage API keys securely and stay within rate limits.
- We may need to cache results locally to improve performance and reduce API usage.
- Licensing terms of Ordnance Survey data apply and must be adhered to.

## Implementation notes

- Use the following OS Places endpoints:
  - `places/v1/postcode` – for postcode look-ups (returns lat/long and related information)
  - `places/v1/find` – for free-text searches of addresses and places

- Each environment (local, QA, staging, production) should have its own API key.
- API keys must be stored in environment variables and not committed to source control.
- The geospatial data will mainly be used for providers, schools, and other teaching locations.

## Limitations

- The Ordnance Survey API and UPRNs only cover addresses in **Great Britain and Northern Ireland**.
- **Overseas British schools** are not included in Ordnance Survey datasets, and therefore will not have UPRNs. If they need to be supported, location data would have to come from alternative sources such as Google Maps, OpenStreetMap, or manual data entry.
- We may need to introduce Google Maps API or any other alternatives as a redundancy option.
