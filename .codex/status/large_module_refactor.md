# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema capability-catalog validation owner extraction.

Status:
Complete and pushed.

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
Added a 27-line `CapabilityCatalogValidation` owner that resolves catalog
required fields from the validation-policy registry and the complete executable
contract list from `RegistryCatalog`. Routed the direct catalog clause through
it. `schema.ex` moved from 4,632 to 4,627 lines.

Verification:
- Strict capability, registry, fixture, and validation baseline: 16 tests
  passed.
- Capability, registry, JSON-schema export, full export, validation, and fixture
  adjacency: 34 tests passed.
- Full schema export regenerated with no checked-in schema artifact changes.
- Formatting, diff whitespace, bounded dependency/reference checks, and the
  bounded semantic diff review passed.
- `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force
  --warnings-as-errors` compiled 4,090 files successfully.

Behavior/schema changes:
None. Required fields, full executable registry contents, validation ordering
and paths, public `Schema`, validation results, and checked-in exports remain
unchanged.

Last completed slice:
Schema capability-catalog validation owner extraction, selected in `c4e1db05`
and implemented in `cf2a0310`. `schema.ex` moved from 4,632 to 4,627 lines.

Next candidate:
Assess the remaining recursive result-artifact route and the facade-owned
nested execution-report callback before selecting another boundary.

Blocked:
No.
