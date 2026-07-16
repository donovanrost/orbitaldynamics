defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.DuplicateIdentities.Scopes do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.RowFieldCounts

  @duplicate_identity_scopes [
    "source",
    "replacement",
    "source_and_replacement"
  ]

  @single_identity_scopes [
    "source",
    "replacement"
  ]

  def duplicate?(row) do
    row["timeline_identity_collision"] == true or
      row["duplicate_timeline_identity_scope"] in @duplicate_identity_scopes
  end

  def matches?(row, scope) do
    case row["duplicate_timeline_identity_scope"] do
      ^scope -> true
      "source_and_replacement" -> scope in @single_identity_scopes
      _scope -> false
    end
  end

  def counts(rows) do
    RowFieldCounts.counts(rows, "duplicate_timeline_identity_scope")
  end
end
