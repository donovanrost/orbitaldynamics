defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.InvalidInputs do
  @moduledoc false

  alias __MODULE__.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2, sorted_string_values: 1]

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
    |> Enum.flat_map(fn report ->
      report
      |> count()
      |> correlated_ids(Rows.ids(report))
      |> List.wrap()
    end)
    |> non_empty_values()
  end

  def correlated_ids(count, ids) when is_number(count) and count > 0 and is_list(ids) do
    ids = sorted_string_values(ids)

    if length(ids) == count,
      do: ids,
      else: nil
  end

  def correlated_ids(_count, _ids), do: nil

  def required_operator_action_counts(report) do
    Rows.required_operator_action_counts(report)
  end

  defp non_empty_values([]), do: nil
  defp non_empty_values(values), do: values
end
