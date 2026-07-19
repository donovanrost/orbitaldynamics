# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules through
facade-preserving, responsibility-focused extraction without behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
ResourceFilter candidate-input extraction.

Status:
Completed and pushed in `a1b248fa`.

Selected boundary:
Extract candidate shape coercion, provider/station direction contracts,
stable-identity validation, station-calendar ID-list normalization,
provider-contact inference, feedback-factor validation, and invalid-candidate
construction into `OrbitalDynamics.ResourceFilter.CandidateInput`. Preserve all
ResourceFilter and root public facades.

Selection evidence:
- Excluding the generated/declarative candidate-refresh JSON-schema module,
  live re-ranking places `resource_filter.ex` at 1,964 lines, the largest
  ordinary eligible facade.
- ResourceFilter currently delegates only summary generation; candidate
  normalization and validation occupy lines 1,306-1,659, with their stable
  identity and station-calendar contracts still declared in the facade.
- The selected block has one responsibility: turn heterogeneous candidate
  inputs into valid normalized rows or deterministic reviewable invalid rows.
- Resource-summary normalization/ambiguity, suppression policy, approval
  routing, risk mapping, provenance counts, filter summaries, and all other
  capability contracts remain outside the boundary.
- Exact alias maps, stable-ID rules, station-calendar ID-list handling,
  direction/contact inference, time parsing, source-candidate preservation,
  report rows, summaries, and error behavior must remain unchanged.

Implementation:
- Added `OrbitalDynamics.ResourceFilter.CandidateInput` as the owner of
  candidate alias contracts, normalization, stable identity checks,
  station-calendar ID lists, contact inference, feedback-factor validation,
  and deterministic invalid rows.
- Preserved ResourceFilter and root public APIs as capability, filtering,
  report, and summary delegates.
- Routed shared stable-ID checks and resource activity alias normalization
  through CandidateInput so the moved contracts have one owner.
- `resource_filter.ex` moved from 1,964 to 1,542 lines; the new owner is 477
  lines.

Verification:
- Strict focused baseline passed all 37 ResourceFilter tests.
- Exact old/new public parity passed for four deterministic captures:
  candidate/direction capabilities, filtering without summaries, filtering
  against unavailable resources, and report construction across inferred
  contacts, station-calendar ID lists, invalid factors, missing IDs, and
  invalid raw shapes.
- Post-extraction focused and adjacent verification passed all 50 tests.
- Static checks confirm CandidateInput solely declares the moved contracts and
  owns the candidate normalization helper family; xref reports only
  ResourceFilter as a runtime caller.
- Strict warning-clean forced compile passed for 3,997 files.
- Formatting and `git diff --check` passed.

Behavior/schema changes:
None intended.

Last completed slice:
ResourceFilter candidate-input extraction, selected in `a2a84802` and
implemented in `a1b248fa`.
`resource_filter.ex` moved from 1,964 to 1,542 lines; the dedicated
CandidateInput owner is 477 lines.

Next candidate:
Re-rank the live checkout and select the next bounded facade-preserving
extraction. `communications/contact_allocation.ex` is now the largest ordinary
eligible facade at 1,953 lines, followed by TimelineFeedback and
OperationalReadiness.

Blocked:
No.
