defmodule OrbitalDynamics.Schema.StationCalendarCapabilityContext do
  @moduledoc false

  def station_calendar_capabilities do
    OrbitalDynamics.Communications.StationCalendar.capabilities()
  end

  def station_calendar_report_model_limits do
    station_calendar_capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  def station_calendar_provider_counteroffer_actions do
    station_calendar_capabilities().provider_counteroffer_actions
  end

  def station_calendar_provider_counteroffer_negotiation_states do
    station_calendar_capabilities().provider_counteroffer_negotiation_states
  end
end
