defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.DuplicateIdentity.ScopeRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.ReportShape

  @duplicate_scope_field "duplicate_timeline_identity_scope"

  def counts(rows) do
    ReportShape.count_rows(rows, @duplicate_scope_field)
  end

  def duplicate?(row) do
    row["timeline_identity_collision"] == true or
      row["duplicate_timeline_identity_scope"] in [
        "source",
        "replacement",
        "source_and_replacement"
      ]
  end

  def duplicate_scope?(row, scope) do
    case row["duplicate_timeline_identity_scope"] do
      ^scope -> true
      "source_and_replacement" when scope in ["source", "replacement"] -> true
      _scope -> false
    end
  end
end
