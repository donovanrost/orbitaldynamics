defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.SourceFields do
  @moduledoc false

  alias __MODULE__.SourceMetadata

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_report_field_values: 2
    ]

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => SourceMetadata.contract(reports),
      "count" => length(sources),
      "source_summary_model_counts" => count_report_field_values(reports, "source_summary_model"),
      "source_summary_schema_contract_counts" =>
        count_report_field_values(reports, "source_summary_schema_contract"),
      "source_artifact_type_counts" => count_report_field_values(reports, "source_artifact_type")
    }
    |> Map.merge(SourceMetadata.trust_boundary_fields(reports))
  end
end
