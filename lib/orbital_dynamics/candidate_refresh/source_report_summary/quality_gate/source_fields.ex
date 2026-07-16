defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.SourceFields do
  @moduledoc false

  alias __MODULE__.SourceCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1
    ]

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "quality_gate_report.v1",
      "count" => length(sources),
      "trust_boundary_status" => source_report_trust_boundary_status(reports),
      "trust_boundaries" => source_report_trust_boundaries(reports),
      "source_summary_model_counts" => SourceCounts.source_summary_model_counts(reports),
      "source_summary_schema_contract_counts" =>
        SourceCounts.source_summary_schema_contract_counts(reports),
      "source_artifact_type_counts" => SourceCounts.source_artifact_type_counts(reports),
      "source_readiness_report_count" => SourceCounts.source_readiness_report_count(reports)
    }
  end
end
