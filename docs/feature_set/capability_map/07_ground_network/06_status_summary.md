# Status Summary

Status: **partial**.

## Candidate refresh and V1 reporting

- Candidate refresh can suppress unavailable ground-station contacts and annotate reduced station capacity.
- V1 can report:
  - same-station and same-spacecraft cross-station contention;
  - fixed-rate link-capacity summaries;
  - manifest-supplied and declared-provider station calendar overlays, including reserved-overlap contention metadata and overlapping-entry context;
  - optional direction scoping for uplink/command/downlink/tracking-specific station state;
  - optional policy classification evidence.

## Direction-scoped station calendar entries

- Direction-scoped station calendar entries are now honored consistently by standalone station-calendar overlays, contact filtering, candidate refresh, contact allocation, operator review, and Cadence-import handoffs.
- As a result, an uplink-only outage or reservation does not suppress a downlink opportunity at the same station and time.
- Typed tracking and health-check contacts also infer those provider-calendar directions when no explicit contact `direction` is supplied.
- Replayed provider-calendar contention groups infer direction scope from embedded source station-calendar entries when the group summary omits directions.
- Candidate-refresh resource-filter replay preserves suppressed-candidate
  direction routing, so downlink, command, tracking, and health-check resource
  suppression pressure remains visible without reopening suppressed rows.

## Contact filtering and station-calendar parsing

- **Contact filtering** now parses, before suppression decisions:
  - clean numeric-string contact timing aliases;
  - station capacity fractions;
  - top-level or metadata-supplied contact/command trimmed case-insensitive success booleans, results, factors, and source labels.
- It also normalizes nested source station-calendar evidence for schema-validated review rows.
- **Station-calendar provider entries** likewise parse clean numeric-string timing aliases, capacity fractions, and `capacity_pack_capacity_fraction` before interval validation and reduced-capacity classification.
- Executable provider validation now matches exported JSON Schema by requiring a direct `trust_boundary` or `provenance.trust_boundary` on `station_calendar_provider.v1` artifacts.

## Duplicate and ambiguous ground-network state

- Duplicate overlapping ground-network state rows do not drive arbitrary contact-filter or candidate-refresh suppression decisions.
- Same-severity unavailable or reserved ambiguity is preserved as explicit ambiguous station-calendar context instead of being treated as an ordinary available contact.
- Mixed-priority station-calendar overlaps now keep compact overlap count, entry ID, and availability evidence on the selected highest-precedence suppression row, so reserved or unavailable decisions can still expose lower-precedence reduced-capacity context.

## Candidate budget

- Candidate refresh can apply a deterministic post-contact/resource/allocation-filter candidate budget via `candidate_limit_policy` and `refresh_budget_report.v1`.
- The budget stage counts duplicate candidate IDs by row occurrence, so one selected duplicate does not hide other dropped rows.
- Executable validation checks input/kept/dropped counts against the kept/dropped ID arrays.
- Candidate diffs distinguish budget-dropped refreshed replacements from candidates that were never generated, preserving budget-dropped replacement IDs for repair/review explanations.
- Malformed candidate-limit policy values or shapes are preserved as invalid policy evidence in refresh-budget review/import gates instead of silently disabling the limit.

## Retained candidate diffs and provider handoff

- Retained candidate diffs now also compare station-calendar entry ID plus flattened provider-calendar provider and entry identity, so provider handoff changes remain visible even when a refreshed downlink keeps the same candidate ID.
- Malformed prior-candidate provider-calendar IDs are preserved as invalid prior-candidate evidence instead of weakening the diff.

## Downlink-completion feedback

- Downlink-demand operational feedback or explicit downlink-completion objectives now add required-demand, candidate-throughput, shortfall, status, completion ratio, shortfall, source evidence, and exact `downlink_completion_sources` lineage to refreshed downlink rows and reusable activity context.
- They also contribute a deterministic `downlink_completion_value` score term that can change candidate-budget selection.

## Not modeled

- Link budgets, live external provider calendars, and schedule mutation/reservation are not modeled.

## Roadmap

- **`near-term`** — add live provider station calendar adapters only when there is a concrete provider boundary and network policy.
- **`later`** — link budgets, modulation/data-rate models, provider networks, calibrated station capacity packing, contact contention resolution, and calibrated command window constraints.
- **`out of scope`** — direct Cadence scheduling, station provider API calls, and command execution.
