defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.SourceFields do
  @moduledoc false

  alias __MODULE__.SourceContracts
  alias __MODULE__.TrustBoundaries

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_report_field_values: 2
    ]

  def fields(sources, reports) do
    source_fields(sources, reports)
    |> Map.merge(SourceContracts.fields(reports))
  end

  defp source_fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "contact_allocation_report.v1",
      "count" => length(sources),
      "source_summary_model_counts" => count_report_field_values(reports, "source_summary_model"),
      "source_summary_schema_contract_counts" =>
        count_report_field_values(reports, "source_summary_schema_contract"),
      "source_artifact_type_counts" => count_report_field_values(reports, "source_artifact_type"),
      "trust_boundary_status" => TrustBoundaries.status(reports),
      "trust_boundaries" => TrustBoundaries.values(reports)
    }
  end
end
