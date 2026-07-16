defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.PressureFields.RowValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      sorted_string_values: 1
    ]

  def activity_ids(row) do
    [
      Map.get(row, "activity_id"),
      Map.get(row, "planned_activity_id"),
      Map.get(row, "realized_activity_id")
    ] ++
      List.wrap(Map.get(row, "planned_activity_ids")) ++
      List.wrap(Map.get(row, "realized_activity_ids"))
  end

  def timeline_ids(rows, predicate) do
    rows
    |> Enum.filter(predicate)
    |> Enum.map(&Map.get(&1, "timeline_id"))
    |> sorted_values()
  end

  def sorted_values(values), do: sorted_string_values(values)
end
