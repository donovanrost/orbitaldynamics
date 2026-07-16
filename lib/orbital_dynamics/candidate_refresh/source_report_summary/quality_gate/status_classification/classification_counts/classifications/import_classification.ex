defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.ClassificationCounts.Classifications.ImportClassification do
  @moduledoc false

  def value(report) do
    case report_rows(report) do
      [] ->
        Map.get(report, "import_classification")

      rows ->
        rows
        |> Enum.map(&Map.get(&1, "status"))
        |> from_statuses()
    end
  end

  defp from_statuses(statuses) do
    cond do
      "blocked" in statuses -> "blocked"
      "analysis_only" in statuses -> "analysis_only"
      "review_required" in statuses -> "review_only"
      true -> "importable"
    end
  end

  defp report_rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.filter(&is_map/1)
  end
end
