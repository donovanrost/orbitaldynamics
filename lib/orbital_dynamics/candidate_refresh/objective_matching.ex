defmodule OrbitalDynamics.CandidateRefresh.ObjectiveMatching do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def matches_downlink_candidate?(objective, refresh, scenario_id, ground_station_id) do
    matches_station?(objective, ground_station_id) and
      matches_spacecraft?(objective, refresh, scenario_id)
  end

  def matches_spacecraft?(objective, refresh, scenario_id) do
    candidate_scenario_id = encode_value(scenario_id)
    candidate_spacecraft_id = refresh_spacecraft_id(refresh, candidate_scenario_id)
    objective_scenario_id = Map.get(objective, "scenario_id")

    objective_spacecraft_id = objective_spacecraft_id(objective)

    objective_scenario_id in [nil, "", candidate_scenario_id] and
      objective_spacecraft_id in [nil, "", candidate_spacecraft_id, candidate_scenario_id]
  end

  def spacecraft_identity_by_scenario(refresh) do
    refresh
    |> refresh_spacecraft_states()
    |> Enum.reduce(%{}, fn state, acc ->
      scenario_id = encode_value(Map.get(state, "scenario_id"))
      spacecraft_id = spacecraft_state_identity(state)

      if scenario_id in [nil, ""] or spacecraft_id in [nil, ""] do
        acc
      else
        Map.put_new(acc, scenario_id, spacecraft_id)
      end
    end)
  end

  def required_downlink_mb(objective) do
    Enum.find_value(
      [
        "required_downlink_mb",
        "downlink_mb",
        "required_throughput_mb",
        "required_volume_mb",
        "required_data_volume_mb",
        "min_downlink_mb"
      ],
      fn field ->
        case ValueEncoding.numeric_value(Map.get(objective, field)) do
          value when is_number(value) -> value
          _value -> nil
        end
      end
    )
  end

  def id(%{"id" => id}), do: encode_value(id)
  def id(%{"objective_id" => id}), do: encode_value(id)
  def id(_objective), do: nil

  defp matches_station?(objective, ground_station_id) do
    objective_station_id = objective_station_id(objective)

    objective_station_id in [nil, "", encode_value(ground_station_id)]
  end

  defp objective_station_id(objective) do
    Map.get(objective, "ground_station_id") || Map.get(objective, "station_id") ||
      nested_station_id(objective)
  end

  defp objective_spacecraft_id(objective) do
    spacecraft_identity_value(Map.get(objective, "spacecraft_id")) ||
      spacecraft_identity_value(Map.get(objective, "satellite_id")) ||
      spacecraft_identity_value(Map.get(objective, "spacecraft")) ||
      spacecraft_identity_value(Map.get(objective, "satellite"))
  end

  defp refresh_spacecraft_id(refresh, scenario_id) do
    refresh
    |> spacecraft_identity_by_scenario()
    |> Map.get(scenario_id)
  end

  defp refresh_spacecraft_states(refresh) do
    [
      get_in(refresh, ["mission_state", "spacecraft_states"]) || [],
      get_in(refresh, ["accepted_planning_state", "spacecraft_states"]) || []
    ]
    |> List.flatten()
    |> Enum.map(&stringify_keys/1)
  end

  defp spacecraft_state_identity(state) do
    spacecraft_identity_value(Map.get(state, "spacecraft_id")) ||
      spacecraft_identity_value(Map.get(state, "satellite_id")) ||
      spacecraft_identity_value(Map.get(state, "spacecraft")) ||
      spacecraft_identity_value(Map.get(state, "satellite"))
  end

  defp spacecraft_identity_value(%{} = spacecraft) do
    Enum.find_value(["spacecraft_id", "satellite_id", "id"], fn field ->
      spacecraft_identity_value(Map.get(spacecraft, field))
    end)
  end

  defp spacecraft_identity_value(value), do: encode_value(value)

  defp nested_station_id(candidate) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(candidate, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(value), do: EncodedValue.value_with_keyword_maps(value)
end
