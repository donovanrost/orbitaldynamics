defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.RowMetrics.RowValues do
  @moduledoc false

  alias __MODULE__.ActivityIds
  alias __MODULE__.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def row_count(report), do: length(Map.get(report, "rows", []))

  def source_count_map(report, fallback_field, row_field) do
    case Rows.raw(report) do
      [] -> Map.get(report, fallback_field)
      _rows -> count_field(report, row_field)
    end
  end

  def count_field(report, field) do
    report
    |> Rows.all()
    |> Enum.map(&Map.get(&1, field))
    |> count_source_report_values()
  end

  def activity_id_counts(report) do
    case Rows.raw(report) do
      [] ->
        Map.get(report, "activity_id_counts")

      _rows ->
        report
        |> Rows.all()
        |> ActivityIds.counts()
    end
  end
end
