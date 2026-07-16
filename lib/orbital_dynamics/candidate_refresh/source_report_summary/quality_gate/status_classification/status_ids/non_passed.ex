defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.NonPassed do
  @moduledoc false

  alias __MODULE__.StatusIds

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "non_passed_gate_count" => sum_report_count(reports, &non_passed_gate_count/1),
      "non_passed_gate_ids" =>
        reports
        |> Enum.flat_map(&StatusIds.gate_ids/1)
        |> sorted_string_values(),
      "non_passed_quality_gate_row_ids" =>
        reports
        |> Enum.flat_map(&StatusIds.row_ids/1)
        |> sorted_string_values()
    }
  end

  defp non_passed_gate_count(report) do
    case numeric_report_count(report, "non_passed_gate_count") do
      0 -> length(StatusIds.gate_ids(report))
      count -> count
    end
  end
end
