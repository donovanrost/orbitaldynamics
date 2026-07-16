defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactReviewReportRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactRows

  def operator_review_rows(package) do
    package
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(&1["review_type"] == "timeline_dependency_impact_review"))
    |> embedded_rows()
  end

  def cadence_import_rows(manifest) do
    manifest
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(fn row ->
      row["source_review_type"] == "timeline_dependency_impact_review" or
        row["import_action"] == "review_timeline_dependency_impact"
    end)
    |> embedded_rows()
  end

  defp embedded_rows(rows) do
    rows
    |> Enum.map(&TimelineDependencyImpactRows.row_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end

  defp stringify_keys(value), do: TimelineDependencyImpactRows.stringify_keys(value)
end
