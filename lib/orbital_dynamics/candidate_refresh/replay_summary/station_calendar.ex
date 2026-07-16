defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SummarySelection
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.Summary

  def replay(refresh_or_artifact) do
    {station_summary, summary_source, replay_scope} =
      SummarySelection.selected_summary(refresh_or_artifact, nil)

    summary(station_summary, summary_source, replay_scope)
  end

  def summary(station_summary, summary_source, replay_scope),
    do: Summary.summary(station_summary, summary_source, replay_scope)
end
