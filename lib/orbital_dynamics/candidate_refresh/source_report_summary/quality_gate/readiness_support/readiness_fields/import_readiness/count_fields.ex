defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ReadinessSupport.ReadinessFields.ImportReadiness.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "ready_for_import_count" => row_count(reports, "ready_for_import_count"),
      "manifest_review_required_count" => row_count(reports, "manifest_review_required_count"),
      "blocked_import_count" => row_count(reports, "blocked_import_count"),
      "missing_import_count" => row_count(reports, "missing_import_count"),
      "invalid_cadence_import_count" => row_count(reports, "invalid_cadence_import_count"),
      "current_freshness_count" => row_count(reports, "current_freshness_count"),
      "stale_freshness_count" => row_count(reports, "stale_freshness_count"),
      "unknown_freshness_count" => row_count(reports, "unknown_freshness_count"),
      "freshness_status_counts" => count_map(reports, "freshness_status_counts"),
      "import_status_counts" => count_map(reports, "import_status_counts"),
      "cadence_import_status_counts" => count_map(reports, "cadence_import_status_counts")
    }
  end

  defp row_count(reports, field) do
    sum_report_count(reports, &RowFallbackValues.count(&1, field))
  end

  defp count_map(reports, field) do
    reports
    |> Enum.map(&RowFallbackValues.count_map(&1, field))
    |> merge_count_maps()
  end
end
