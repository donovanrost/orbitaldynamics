defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.SourceFields.TrustBoundaryFields.Values.ReportValues do
  @moduledoc false

  alias __MODULE__.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      normalize_trust_boundaries: 1,
      source_report_trust_boundaries: 1
    ]

  def values(%{"dependency_impact_rows" => rows} = report) when is_list(rows) do
    rows
    |> Enum.flat_map(&RowValues.values/1)
    |> Kernel.++([
      Map.get(report, "trust_boundary"),
      get_in(report, ["provenance", "trust_boundary"])
    ])
    |> normalize_trust_boundaries()
  end

  def values(%{} = report), do: source_report_trust_boundaries([report])
  def values(_report), do: []
end
