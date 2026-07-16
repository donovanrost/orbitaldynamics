defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.FreshnessBudget.RefreshBudgetFields.CandidateFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "input_candidate_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "input_candidate_count")),
      "kept_candidate_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "kept_candidate_count")),
      "dropped_candidate_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "dropped_candidate_count")),
      "kept_candidate_ids" => candidate_ids(reports, "kept_candidate_ids"),
      "dropped_candidate_ids" => candidate_ids(reports, "dropped_candidate_ids")
    }
  end

  defp candidate_ids(reports, field) do
    reports
    |> Enum.flat_map(&Map.get(&1, field, []))
    |> sorted_string_values()
  end
end
