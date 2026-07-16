defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.CountFields.IdentityFields.CountMaps.IdCounts do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def values(%{} = summary, "activity_id") do
    [
      Map.get(summary, "activity_id"),
      get_in(summary, ["timeline_identity", "activity_id"])
    ]
    |> count_source_report_values()
  end

  def values(%{} = summary, "timeline_id") do
    [
      Map.get(summary, "timeline_id"),
      get_in(summary, ["timeline_identity", "timeline_id"])
    ]
    |> count_source_report_values()
  end

  def values(_summary, _field), do: %{}
end
