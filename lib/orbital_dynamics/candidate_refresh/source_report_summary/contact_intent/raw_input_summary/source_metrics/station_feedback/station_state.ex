defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.RawInputSummary.SourceMetrics.StationFeedback.StationState do
  @moduledoc false

  alias __MODULE__.StateValues

  def feedback?(%{} = intent), do: is_map(state(intent))
  def feedback?(_intent), do: false

  def calendar_status(%{} = intent) do
    case state(intent) do
      %{} = station_state -> station_state["status"] || station_state["availability"]
      _state -> nil
    end
  end

  def calendar_status(_intent), do: nil

  defp state(%{} = intent), do: StateValues.state(intent)
end
