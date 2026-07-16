defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields do
  @moduledoc false

  alias __MODULE__.RowCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_report_field_values: 2,
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &RowCounts.summary_row_count/1),
      "record_count" => sum_report_count(reports, &record_count/1),
      "intended_use_counts" => count_report_field_values(reports, "intended_use"),
      "status_counts" => count_report_field_values(reports, "status"),
      "model_count" => sum_report_count(reports, &RowCounts.model_count/1),
      "accepted_count" => sum_report_count(reports, &RowCounts.status_count(&1, "accepted")),
      "review_required_count" =>
        sum_report_count(reports, &RowCounts.status_count(&1, "review_required")),
      "blocked_count" => sum_report_count(reports, &RowCounts.status_count(&1, "blocked")),
      "unknown_model_count" => sum_report_count(reports, &RowCounts.unknown_model_count/1),
      "validation_level_counts" =>
        reports
        |> Enum.map(&RowCounts.validation_level_counts/1)
        |> merge_count_maps()
    }
  end

  defp record_count(report), do: length(Map.get(report, "records", []))
end
