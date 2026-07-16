defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.SourceMetrics.StationFeedback do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.SourceMetrics.StationFeedback.StationState

  def count(intents) do
    Enum.count(intents, &StationState.feedback?/1)
  end

  def status_counts(intents) do
    intents
    |> Enum.map(&StationState.calendar_status/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
  end
end
