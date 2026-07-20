# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema capability-catalog validation owner extraction.

Status:
Selected; implementation pending.

Selected boundary:
Add a focused `CapabilityCatalogValidation` owner that resolves its required
fields from `ValidationPolicyRegistryContracts` and its executable contract
list from `RegistryCatalog`. Route the direct `capability_catalog.v1` `Schema`
clause through it.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,632 lines; the other
  targeted public facades are now 164 to 524 lines.
- The catalog clause is now the only remaining non-recursive route with
  facade-owned validation setup.
- `RegistryCatalog` is the authoritative full-registry source and
  `ValidationPolicyRegistryContracts` owns the catalog artifact definition.
- No route needs recursive `Schema` lookup.

Implementation:
Pending.

Verification:
Pending.

Behavior/schema changes:
None intended. Required fields, full executable registry contents, validation
ordering and paths, public `Schema`, validation results, and checked-in exports
must remain unchanged.

Last completed slice:
Schema executable-registry catalog extraction, selected in `fee6a3cc` and
implemented in `f51ff6ff`. `schema.ex` moved from 4,712 to 4,632 lines.

Next candidate:
Implement and verify the selected capability-catalog owner, then re-rank the
remaining recursive result-artifact route.

Blocked:
No.
