defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.ConflictGroups do
  @moduledoc false

  alias __MODULE__.Rows
  alias __MODULE__.ValueCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  def count(report) do
    numeric_report_count(report, "conflict_group_count")
    |> case do
      0 -> Rows.count(report)
      count -> count
    end
  end

  def resource_scope_counts(report) do
    report
    |> ValueCounts.token_counts("resource_scope")
    |> empty_counts_if_nil()
  end

  def ground_station_counts(report) do
    report
    |> ValueCounts.stable_id_counts("ground_station_id")
  end

  def contact_id_counts(report) do
    ValueCounts.contact_id_counts(report)
  end

  def required_operator_action_counts(report) do
    report
    |> ValueCounts.token_counts("required_operator_action")
  end

  defp empty_counts_if_nil(nil), do: %{}
  defp empty_counts_if_nil(counts), do: counts
end
