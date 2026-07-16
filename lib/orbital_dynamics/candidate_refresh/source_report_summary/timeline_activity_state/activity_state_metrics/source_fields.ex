defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics.SourceFields do
  @moduledoc false

  alias __MODULE__.SummaryFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1
    ]

  def fields(sources, states) do
    %{
      "paths" => Enum.map(sources, fn {path, _state} -> path end),
      "contract" => SummaryFields.contract(states),
      "count" => length(sources),
      "source_summary_model_counts" => SummaryFields.model_counts(states),
      "source_summary_schema_contract_counts" => SummaryFields.schema_contract_counts(states),
      "trust_boundary_status" => source_report_trust_boundary_status(states),
      "trust_boundaries" => source_report_trust_boundaries(states)
    }
  end
end
