defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.BaseFields.InvalidInputs do
  @moduledoc false

  alias __MODULE__.InputIds

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "invalid_resource_summary_input_count" =>
        sum_report_count(reports, &invalid_resource_summary_input_count/1),
      "invalid_resource_summary_input_ids" => InputIds.values(reports)
    }
  end

  def invalid_resource_summary_input_count(report) do
    report
    |> numeric_report_count("invalid_resource_summary_input_count")
    |> case do
      0 -> length(Map.get(report, "invalid_resource_summary_inputs", []))
      count -> count
    end
  end
end
