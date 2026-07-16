defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.SourceFields do
  @moduledoc false

  alias __MODULE__.{Metadata, TrustBoundaries}

  def fields(sources, reports) do
    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => Metadata.contract(reports),
      "count" => length(sources),
      "source_summary_model_counts" =>
        reports
        |> Metadata.count_field_values("source_summary_model"),
      "source_summary_schema_contract_counts" =>
        reports
        |> Metadata.count_field_values("source_summary_schema_contract"),
      "source_artifact_type_counts" =>
        reports
        |> Metadata.count_field_values("source_artifact_type"),
      "trust_boundary_status" => Metadata.trust_boundary_status(reports),
      "trust_boundaries" => trust_boundaries(reports)
    }
  end

  defdelegate trust_boundaries(report_or_reports), to: TrustBoundaries
end
