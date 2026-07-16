defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs.RowPairs.DirectionValues.DirectionAliases.ProviderAliases do
  @moduledoc false

  @provider_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "uplink" => "uplink",
    "up" => "uplink",
    "up_link" => "uplink",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "downlink" => "downlink",
    "down_link" => "downlink",
    "tracking" => "tracking",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "health_check" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check",
    "contact" => "contact"
  }

  def normalize(token) when is_map_key(@provider_direction_aliases, token),
    do: Map.fetch!(@provider_direction_aliases, token)

  def normalize("nil"), do: nil
  def normalize(""), do: nil
  def normalize(value), do: value
end
