defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.RowMetrics.RowValues.ActivityIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def counts(rows) do
    rows
    |> Enum.map(&value/1)
    |> count_source_report_values()
  end

  defp value(row) do
    row
    |> candidates()
    |> Enum.map(&StableIds.stable_id_or_nil/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  defp candidates(row) do
    [
      row["activity_id"],
      row["planned_activity_id"],
      row["realized_activity_id"],
      row["source_activity_id"],
      get_in(row, ["source_activity_context", "activity_id"]),
      get_in(row, ["source_activity_context", "id"]),
      get_in(row, ["realized_activity_context", "activity_id"]),
      get_in(row, ["realized_activity_context", "planned_activity_id"]),
      get_in(row, ["realized_activity_context", "realized_activity_id"])
    ]
  end
end
