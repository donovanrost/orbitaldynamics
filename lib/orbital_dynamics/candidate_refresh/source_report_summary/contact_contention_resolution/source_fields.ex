defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.SourceFields do
  @moduledoc false

  alias __MODULE__.{Contracts, TrustBoundaries}

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_report_field_values: 2
    ]

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => Contracts.value(reports),
      "count" => length(sources),
      "source_summary_model_counts" => count_report_field_values(reports, "source_summary_model"),
      "source_summary_schema_contract_counts" =>
        count_report_field_values(reports, "source_summary_schema_contract"),
      "source_artifact_type_counts" => count_report_field_values(reports, "source_artifact_type"),
      "trust_boundary_status" => trust_boundary_status(reports),
      "trust_boundaries" => trust_boundaries(reports)
    }
  end

  defp trust_boundary_status(reports) do
    case trust_boundaries(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp trust_boundaries(reports), do: TrustBoundaries.values(reports)
end
