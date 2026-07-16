defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineCollectionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimeline

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalTimelineCollectionArtifactEncoding

  def reports(refresh) do
    refresh
    |> sources()
    |> reject_root_shadowed_mission_state_reports()
    |> Enum.flat_map(fn {path, report_or_reports} ->
      OperationalTimeline.entries(path, report_or_reports)
    end)
  end

  defp sources(refresh) do
    [
      {"accepted_planning_state.source_operational_timeline_report",
       get_in(refresh, ["accepted_planning_state", "source_operational_timeline_report"])},
      {"accepted_planning_state.operational_timeline_report",
       get_in(refresh, ["accepted_planning_state", "operational_timeline_report"])},
      {"mission_state.source_operational_timeline_report",
       get_in(refresh, ["mission_state", "source_operational_timeline_report"])},
      {"mission_state.operational_timeline_report",
       get_in(refresh, ["mission_state", "operational_timeline_report"])},
      {"source_operational_timeline_report",
       Map.get(refresh, "source_operational_timeline_report")},
      {"operational_timeline_report", Map.get(refresh, "operational_timeline_report")}
    ]
  end

  defp reject_root_shadowed_mission_state_reports(entries) do
    root_reports =
      entries
      |> Enum.reject(fn {path, _report} -> String.starts_with?(path, "mission_state.") end)
      |> Map.new(fn {path, report} -> {path, stringify_keys(report)} end)

    Enum.reject(entries, fn
      {"mission_state." <> root_path, %{} = report} ->
        Map.get(root_reports, root_path) == stringify_keys(report)

      {_path, _report} ->
        false
    end)
  end

  defp stringify_keys(value),
    do: OperationalTimelineCollectionArtifactEncoding.stringify_keys(value)
end
