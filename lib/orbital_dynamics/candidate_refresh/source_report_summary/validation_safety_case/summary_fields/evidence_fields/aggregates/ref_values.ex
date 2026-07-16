defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.EvidenceFields.Aggregates.RefValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.EvidenceRows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_list_maps: 1
    ]

  def evidence_refs_by(reports, field) do
    reports
    |> Enum.map(&EvidenceRows.refs_by(&1, field))
    |> merge_string_list_maps()
  end
end
