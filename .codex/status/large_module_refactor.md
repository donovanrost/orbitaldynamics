# Large Module Refactor Status

Overall objective:
Reduce maintenance risk in the largest OrbitalDynamics modules and tests through
facade-preserving, responsibility-focused extraction with no public behavior,
artifact-contract, deterministic-output, or schema-export changes.

Current slice:
Operator-review-row generic callback ownership phase.

Status:
Complete and published.

Result:
- Removed 20 generic primitive, stable-ID, and collection entries from the
  106-entry operator-review-row callback bag.
- Renamed the remaining 86-entry bag to describe its review/handoff-domain role;
  85 entries use `call/4` and the deferred-priority validator remains the direct
  `validate_optional_rows/4` callback exactly as before.
- Replaced dynamic generic calls with direct focused-owner calls and removed one
  schema primitive import that became unused.
- Preserved `OperatorReviewRowContracts.validate/6`, all public
  responsibility-specific helpers, and the public `OrbitalDynamics.Schema`
  facade.
- Reduced `schema.ex` from 12,757 to 12,736 lines. Explicit imports grew the row
  contracts module from 1,189 to 1,218 lines while making its dynamic boundary
  domain-only; line count was not treated as the success criterion.

Tests run:
- `mix compile --warnings-as-errors` passed.
- Focused row-contract and representative handoff coverage passed 21/21.
- The full `test/orbital_dynamics/operator_review` directory passed 257/257.
- Schema export coverage passed 22/22.
- Full export left `schemas/` unchanged; the bundle fingerprint remained
  `831840C514054AEAA9C3B2275DBE55B442423DE771C7B41D4E3AF3AF83A7DDC0`.
- Xref, formatting, callback-residue, and `git diff --check` passed.
- The read-only reviewer found no issues, independently passed compile and 3
  focused tests, and confirmed the 106-to-86 AST callback count and domain use.

Verification gaps:
- Full repository suite not run.
- The unrelated contact-allocation line-1247 nil equality-message baseline was
  not exercised by this operator-review-row slice.

Last commit:
Published implementation `e8418b83`.

Next candidate:
- Candidate-refresh-report generic callback ownership phase. At 1,910 lines it
  is now the largest extracted schema contract module. Map its facade callback
  bag and remove only generic entries with established focused owners while
  retaining candidate-refresh domain callbacks.

Blocked:
No.
