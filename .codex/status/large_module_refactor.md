# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Schema contact-planning property-dispatch extraction.

Status:
Slice selected; selection publication pending.

Selected slice:
Move JSON-property dispatch/context assembly for contact intent,
contact-intent summary, and proposed contact into an internal
`Schema.ContactPlanningPropertyDispatch` owner.

Why this slice:
`Schema` is 7,752 lines. These three contact-planning artifacts collectively
carry 13 policy, model, lineage, import, and timeline dependencies but still
route directly through the facade.

Current coupling/problem:
The facade owns intent policy/limit/issue contexts, summary contract/assumption
contexts, and proposed-contact import/source-window/timeline contexts.

Public facade to preserve:
All `Schema` APIs; the three JSON Schema documents; checked-in exports,
deterministic ordering, focused fallback behavior, lazy provider order, exact
proposed-contact import closure, and all errors.

Likely files:
- `lib/orbital_dynamics/schema.ex`
- `lib/orbital_dynamics/schema/contact_planning_property_dispatch.ex`
- `.codex/status/large_module_refactor.md`

Definition of done:
The three clauses pass compact dependencies to the new owner; named contexts
and focused fallback routing move out of `Schema`; focused campaign/contact/
refresh/export tests pass; strict compile, full byte-clean schema regeneration,
and independent review are clean.

Verification gaps:
- Focused baseline, strict compile, export proof, and independent review remain.

Tests run:
- None yet for this selected slice.

Behavior/schema changes:
None intended.

Last completed slice:
Policy artifact schema dispatch published as implementation `f5409c15` and
handoff `f229380f`: focused 19/19, strict 3,663-file compile, full byte-clean
schema regeneration, and independent review passed.

Next candidate:
After this slice, remap the remaining direct property clauses in `Schema`.

Blocked:
No.
