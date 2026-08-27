defmodule OrbitalDynamics.CandidateRefresh.CandidateActivities do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.BuildContext
  alias OrbitalDynamics.CandidateRefresh.DownlinkCandidate
  alias OrbitalDynamics.CandidateRefresh.ObservationCandidate
  alias OrbitalDynamics.CandidateRefresh.RefreshedWindows
  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def build(
        event_results,
        refresh,
        constraints,
        policy,
        operational_feedback_fun,
        refresh_objectives_fun,
        refresh_ground_network_fun
      ) do
    build(
      event_results,
      refresh,
      constraints,
      policy,
      operational_feedback_fun,
      refresh_objectives_fun,
      refresh_ground_network_fun,
      RefreshedWindows.empty_invalid_observation_lighting()
    )
  end

  def build(
        event_results,
        refresh,
        constraints,
        policy,
        operational_feedback_fun,
        refresh_objectives_fun,
        refresh_ground_network_fun,
        inherited_invalid_observation_lighting
      ) do
    {event_results, invalid_observation_lighting} =
      admit_event_results(event_results, inherited_invalid_observation_lighting)

    eclipse_intervals_by_scenario = eclipse_intervals_by_scenario(event_results)

    min_duration_s =
      ValueEncoding.numeric_value(Map.get(constraints, "min_activity_duration_s")) ||
        0.0

    avoid_eclipse? = constraint_boolean(constraints, "avoid_eclipse", true)
    horizon = BuildContext.remaining_horizon(refresh, &ValueEncoding.numeric_value/1)

    event_results
    |> Enum.flat_map(fn
      %{event_type: :target_visibility} = result ->
        if RefreshedWindows.invalid_observation_lighting_scenario?(
             invalid_observation_lighting,
             result.scenario_id
           ) do
          []
        else
          eclipse_intervals =
            Map.get(
              eclipse_intervals_by_scenario,
              encode_value(result.scenario_id),
              []
            )

          result.events
          |> Enum.with_index(1)
          |> Enum.flat_map(fn event_with_index ->
            case ObservationCandidate.build(
                   result,
                   event_with_index,
                   refresh,
                   eclipse_intervals,
                   policy,
                   operational_feedback_fun,
                   &ValueEncoding.numeric_value/1,
                   refresh_objectives_fun
                 ) do
              {:error, {:invalid_observation_lighting, _reason}} -> []
              %{} = activity -> [activity]
            end
          end)
          |> Enum.reject(fn activity ->
            activity["duration_s"] < min_duration_s or
              not within_horizon?(activity, horizon) or
              (avoid_eclipse? and activity["eclipse_overlap_s"] > 0.0)
          end)
        end

      %{event_type: :ground_station_access} = result ->
        result.events
        |> Enum.with_index(1)
        |> Enum.map(fn event_with_index ->
          DownlinkCandidate.build(
            result,
            event_with_index,
            refresh,
            policy,
            operational_feedback_fun,
            refresh_objectives_fun,
            refresh_ground_network_fun
          )
        end)
        |> Enum.reject(fn activity ->
          activity["duration_s"] < min_duration_s or not within_horizon?(activity, horizon)
        end)

      _result ->
        []
    end)
  end

  defp admit_event_results(event_results, inherited_invalid_observation_lighting) do
    case RefreshedWindows.admit_event_results(event_results) do
      {:ok, event_results, invalid_observation_lighting} ->
        {
          event_results,
          RefreshedWindows.merge_invalid_observation_lighting(
            inherited_invalid_observation_lighting,
            invalid_observation_lighting
          )
        }

      {:error, {:invalid_observation_lighting, _reason}} ->
        {[], inherited_invalid_observation_lighting}
    end
  end

  defp constraint_boolean(constraints, key, default) do
    case boolean_value(Map.get(constraints, key)) do
      value when is_boolean(value) -> value
      _value -> default
    end
  end

  defp within_horizon?(activity, %{"starts_at_s" => start_s, "ends_at_s" => end_s})
       when is_number(start_s) and is_number(end_s) do
    activity["ends_at_s"] > start_s and activity["starts_at_s"] < end_s
  end

  defp within_horizon?(_activity, _horizon), do: true

  defp eclipse_intervals_by_scenario(event_results) do
    event_results
    |> Enum.reduce(%{}, fn
      %{event_type: :eclipse, events: events, scenario_id: scenario_id}, intervals_by_scenario ->
        scenario_id = encode_value(scenario_id)

        events
        |> Enum.reduce(intervals_by_scenario, fn event, intervals_by_scenario ->
          interval = {
            epoch_seconds(event.starts_at),
            epoch_seconds(event.ends_at)
          }

          Map.update(intervals_by_scenario, scenario_id, [interval], &[interval | &1])
        end)

      _result, intervals_by_scenario ->
        intervals_by_scenario
    end)
    |> Map.new(fn {scenario_id, intervals} ->
      {scenario_id, Enum.reverse(intervals)}
    end)
  end

  defp epoch_seconds(%{seconds_since_j2000: seconds}), do: seconds

  defp boolean_value(value) when is_boolean(value), do: value

  defp boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      value when value in ~w(true 1) -> true
      value when value in ~w(false 0) -> false
      _value -> nil
    end
  end

  defp boolean_value(_value), do: nil

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
