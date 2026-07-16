defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportRowFallbacks do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def status(rows) do
    cond do
      Enum.any?(rows, &(&1["precondition_status"] == "blocked")) -> "blocked"
      Enum.any?(rows, &(&1["precondition_status"] == "review_required")) -> "review_required"
      Enum.any?(rows, &(&1["invalid_activity_input"] == true)) -> "review_required"
      true -> "clear"
    end
  end

  def count(rows, "blocked") do
    sum_report_count(rows, &numeric_report_count(&1, "blocked_precondition_count"))
  end

  def count(rows, "review_required") do
    sum_report_count(rows, &numeric_report_count(&1, "review_precondition_count"))
  end

  def types(rows, "blocked") do
    rows
    |> Enum.flat_map(&Map.get(&1, "blocked_precondition_types", []))
    |> sorted_string_values()
  end

  def types(rows, "review_required") do
    rows
    |> Enum.flat_map(&Map.get(&1, "review_precondition_types", []))
    |> sorted_string_values()
  end
end
