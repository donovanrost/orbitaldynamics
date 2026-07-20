# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema executable-registry catalog extraction.

Status:
Complete and pushed.

Selected boundary:
Extract the full executable contract map composition from `Schema` into a
focused `RegistryCatalog` module. Keep `Schema`'s compile-time `@contracts`
snapshot and every public registry API unchanged while establishing one
non-facade source for later capability-catalog validation ownership.

Selection evidence:
- `schema.ex` remains the dominant production hotspot at 4,712 lines; the other
  targeted public facades are now 164 to 524 lines.
- The facade currently owns about 80 lines of mechanical registry-map assembly
  used by every public contract, schema, and validation path.
- The capability-catalog validator is the only remaining direct clause that
  needs the full registry, so duplicating this assembly in a validator would
  create drift risk.
- A compile-time catalog snapshot preserves current semantics and removes no
  public API.

Implementation:
Added an 87-line compile-time `RegistryCatalog` containing the unchanged
executable registry merge sequence, then replaced the facade assembly with one
catalog call. `schema.ex` moved from 4,712 to 4,632 lines.

Verification:
- Strict registry, capability, export, and validation baseline: 31 tests passed.
- Entire schema test directory plus export coverage: 178 tests passed.
- A live equality check confirmed the catalog and public registry expose the
  same 121 contracts.
- Full schema export regenerated with no checked-in schema artifact changes.
- Formatting, diff whitespace, bounded dependency/reference checks, and the
  bounded semantic diff review passed.
- `MIX_ENV=test MIX_OS_CONCURRENCY_LOCK=0 mix compile --force
  --warnings-as-errors` compiled 4,089 files successfully.

Behavior/schema changes:
None. Registry merge order and contents, compile-time snapshot semantics, all
public `Schema` APIs, validation results, and checked-in exports remain
unchanged.

Last completed slice:
Schema executable-registry catalog extraction, selected in `fee6a3cc` and
implemented in `f51ff6ff`. `schema.ex` moved from 4,712 to 4,632 lines.

Next candidate:
Assess capability-catalog validation ownership against `RegistryCatalog`, then
re-rank the remaining recursive result-artifact route.

Blocked:
No.
