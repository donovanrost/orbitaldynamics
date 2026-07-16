defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.BaseFields do
  @moduledoc false

  alias __MODULE__.ReportValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_report_field_values: 2,
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1
    ]

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => ReportValues.input_summary_contract(reports),
      "count" => length(sources),
      "row_count" => length(sources),
      "source_summary_model_counts" => count_report_field_values(reports, "source_summary_model"),
      "source_summary_schema_contract_counts" =>
        count_report_field_values(reports, "source_summary_schema_contract"),
      "source_artifact_type_counts" => count_report_field_values(reports, "source_artifact_type"),
      "readiness_level_counts" => count_report_field_values(reports, "readiness_level"),
      "import_classification_counts" =>
        count_report_field_values(reports, "import_classification"),
      "status_counts" => count_report_field_values(reports, "status"),
      "execution_boundary_counts" => count_report_field_values(reports, "execution_boundary"),
      "analysis_mode_source_counts" => count_report_field_values(reports, "analysis_mode_source"),
      "trust_boundary_status" => source_report_trust_boundary_status(reports),
      "trust_boundaries" => source_report_trust_boundaries(reports)
    }
    |> Map.merge(ReportValues.count_fields(reports))
  end
end
