defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.InvalidInputs do
  @moduledoc false

  alias __MODULE__.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  def count(report) do
    report
    |> numeric_report_count("invalid_contact_input_count")
    |> case do
      0 -> Rows.count(report)
      count -> count
    end
  end

  def ids(reports) do
    reports
    |> Enum.flat_map(&Rows.ids/1)
    |> non_empty_values()
  end

  def required_operator_action_counts(report) do
    Rows.required_operator_action_counts(report)
  end

  defp non_empty_values([]), do: nil
  defp non_empty_values(values), do: values
end
