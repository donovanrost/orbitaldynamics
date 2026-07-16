defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.SourceFields do
  @moduledoc false

  alias __MODULE__.SummaryFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1
    ]

  def fields(sources, summaries) do
    %{
      "paths" => Enum.map(sources, fn {path, _summary} -> path end),
      "contract" => SummaryFields.contract(summaries),
      "count" => length(sources),
      "source_summary_model_counts" => SummaryFields.model_counts(summaries),
      "source_summary_schema_contract_counts" => SummaryFields.schema_contract_counts(summaries),
      "trust_boundary_status" => source_report_trust_boundary_status(summaries),
      "trust_boundaries" => source_report_trust_boundaries(summaries)
    }
  end
end
