defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.TrustBoundaries do
  @moduledoc false

  alias __MODULE__.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [normalize_trust_boundaries: 1]

  def values(reports) when is_list(reports) do
    reports
    |> Enum.flat_map(&resource_filter_values/1)
    |> normalize_trust_boundaries()
  end

  def values(%{} = report), do: resource_filter_values(report)

  def values(_report), do: []

  defp resource_filter_values(%{"suppressed_candidates" => rows} = report)
       when is_list(rows) do
    report
    |> RowValues.values()
    |> Kernel.++(report_values(report))
    |> normalize_trust_boundaries()
  end

  defp resource_filter_values(_report), do: []

  defp report_values(report) do
    [
      Map.get(report, "trust_boundary"),
      get_in(report, ["provenance", "trust_boundary"])
    ]
  end
end
