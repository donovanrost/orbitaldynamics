defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.TrustBoundaries.Values do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      normalize_trust_boundaries: 1,
      source_report_trust_boundaries: 1,
      source_rows: 1
    ]

  def for_report(%{"rows" => rows} = report) when is_list(rows) do
    report
    |> source_rows()
    |> Enum.flat_map(&row_values/1)
    |> Kernel.++(report_values(report))
    |> normalize_trust_boundaries()
  end

  def for_report(%{} = report) do
    source_report_trust_boundaries([report])
  end

  def for_report(_report), do: []

  defp row_values(row) do
    [
      row["source_trust_boundary"],
      row["trust_boundary"],
      get_in(row, ["source_timeline_integrity", "trust_boundary"]),
      get_in(row, ["source_timeline_integrity", "provenance", "trust_boundary"])
    ]
  end

  defp report_values(report) do
    [
      Map.get(report, "trust_boundary"),
      get_in(report, ["provenance", "trust_boundary"])
    ]
  end
end
