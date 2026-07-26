defmodule OrbitalDynamics.CampaignPlanner.RepairReplacementIntent do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    DownlinkActivityNormalization,
    RepairActivityIdentity
  }

  def eligible?(source, candidate) do
    source = normalize_source_context(source)
    eligible?(source, candidate, intent_type(source))
  end

  def eligible?(source, candidate, intent_type) do
    candidate_kind_matches?(candidate, intent_type) and
      matches?(source, candidate, intent_type)
  end

  def matches?(source, candidate) do
    source = normalize_source_context(source)
    matches?(source, candidate, intent_type(source))
  end

  def matches?(source, candidate, "downlink") do
    source_station_id = RepairActivityIdentity.ground_station_id(source)

    ActivityIdentity.same_scenario?(source, candidate) and
      (is_nil(source_station_id) or
         source_station_id == RepairActivityIdentity.ground_station_id(candidate))
  end

  def matches?(source, candidate, "observe") do
    source["target_id"] == candidate["target_id"]
  end

  def matches?(_source, _candidate, _intent_type), do: true

  def candidate_kind_matches?(candidate, "downlink") do
    DownlinkActivityNormalization.downlink?(candidate)
  end

  def candidate_kind_matches?(candidate, intent_type) do
    candidate["type"] == intent_type
  end

  def intent_type(%{} = source) do
    activity_type =
      Map.get(source, "type") || get_in(source, ["timeline_identity", "activity_type"])

    source =
      if is_binary(activity_type), do: Map.put_new(source, "type", activity_type), else: source

    if DownlinkActivityNormalization.downlink?(source), do: "downlink", else: activity_type
  end

  def intent_type(_source), do: nil

  defp normalize_source_context(%{} = source) do
    case get_in(source, ["timeline_identity", "scenario_id"]) do
      scenario_id when is_binary(scenario_id) -> Map.put_new(source, "scenario_id", scenario_id)
      _scenario_id -> source
    end
  end

  defp normalize_source_context(source), do: source
end
