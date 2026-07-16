defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields.RowValues do
  @moduledoc false

  alias __MODULE__.ActivityIds
  alias __MODULE__.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def row_count(report), do: Rows.count(report)

  def feedback_count(report, predicate) when is_function(predicate, 1) do
    report
    |> Rows.values()
    |> Enum.count(predicate)
  end

  def activity_id_counts(report) do
    case Rows.values(report) do
      [] ->
        Map.get(report, "activity_id_counts")

      rows ->
        ActivityIds.counts(rows)
    end
  end

  def field_counts(report, field) do
    report
    |> Rows.values()
    |> Enum.map(&Map.get(&1, field))
    |> count_source_report_values()
  end
end
