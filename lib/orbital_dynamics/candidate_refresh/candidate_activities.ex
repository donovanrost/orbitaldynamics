defmodule OrbitalDynamics.CandidateRefresh.CandidateActivities do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.BuildContext
  alias OrbitalDynamics.CandidateRefresh.DownlinkCandidate
  alias OrbitalDynamics.CandidateRefresh.ObservationCandidate
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
    eclipse_intervals_by_scenario = eclipse_intervals_by_scenario(event_results)

    min_duration_s =
      ValueEncoding.numeric_value(Map.get(constraints, "min_activity_duration_s")) ||
        0.0

    avoid_eclipse? = constraint_boolean(constraints, "avoid_eclipse", true)
    horizon = BuildContext.remaining_horizon(refresh, &ValueEncoding.numeric_value/1)

    event_results
    |> Enum.flat_map(fn
      %{event_type: :target_visibility} = result ->
        eclipse_intervals =
          Map.get(
            eclipse_intervals_by_scenario,
            encode_value(result.scenario_id),
            []
          )

        result.events
        |> Enum.with_index(1)
        |> Enum.map(fn event_with_index ->
          ObservationCandidate.build(
            result,
            event_with_index,
            refresh,
            eclipse_intervals,
            policy,
            operational_feedback_fun,
            &ValueEncoding.numeric_value/1,
            refresh_objectives_fun
          )
        end)
        |> Enum.reject(fn activity ->
          activity["duration_s"] < min_duration_s or
            not within_horizon?(activity, horizon) or
            (avoid_eclipse? and activity["eclipse_overlap_s"] > 0.0)
        end)

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
    |> Enum.filter(&(&1.event_type == :eclipse))
    |> Enum.group_by(
      &encode_value(&1.scenario_id),
      fn result ->
        Enum.map(result.events, fn event ->
          {
            epoch_seconds(event.starts_at),
            epoch_seconds(event.ends_at)
          }
        end)
      end
    )
    |> Map.new(fn {scenario_id, grouped_intervals} ->
      {scenario_id, List.flatten(grouped_intervals)}
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
