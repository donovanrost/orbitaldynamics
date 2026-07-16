defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.BaseFields.InvalidInputs.InputIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sorted_string_values: 1
    ]

  def values(reports) do
    reports
    |> Enum.flat_map(&report_values/1)
    |> sorted_string_values()
    |> non_empty_list()
  end

  defp report_values(report) do
    explicit_ids =
      report
      |> Map.get("invalid_resource_summary_input_ids")
      |> List.wrap()

    (explicit_ids ++ row_ids(report))
    |> sorted_string_values()
  end

  defp row_ids(report) do
    report
    |> Map.get("invalid_resource_summary_inputs", [])
    |> Enum.map(&EncodedValue.stringify_keys/1)
    |> Enum.map(&(&1["resource_summary_id"] || &1["subject_id"]))
  end

  defp non_empty_list([]), do: nil
  defp non_empty_list(values), do: values
end
