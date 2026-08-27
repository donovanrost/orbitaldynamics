defmodule OrbitalDynamics.CandidateRefresh.RefreshedWindows do
  @moduledoc false

  alias OrbitalDynamics.AccessEventResultAdmission

  defdelegate admit_event_results(event_results), to: AccessEventResultAdmission
  defdelegate empty_invalid_observation_lighting, to: AccessEventResultAdmission
  defdelegate merge_invalid_observation_lighting(left, right), to: AccessEventResultAdmission

  defdelegate invalid_observation_lighting_scenario?(invalid_lighting, scenario_id),
    to: AccessEventResultAdmission

  def canonical_event_results(event_results) do
    case admit_event_results(event_results) do
      {:ok, event_results, _invalid_lighting} ->
        event_results
        |> Enum.map(&canonical_event_result/1)
        |> Enum.sort_by(&event_result_sort_key/1)

      {:error, {:invalid_observation_lighting, _reason}} ->
        []
    end
  end

  def refreshed_windows(event_results, event_timing_keys) when is_list(event_timing_keys) do
    event_results =
      case admit_event_results(event_results) do
        {:ok, event_results, _invalid_lighting} -> event_results
        {:error, {:invalid_observation_lighting, _reason}} -> []
      end

    %{
      "access_windows" => access_windows(event_results, event_timing_keys),
      "target_visibility_windows" => target_visibility_windows(event_results, event_timing_keys),
      "eclipse_intervals" => eclipse_intervals(event_results, event_timing_keys)
    }
  end

  defp canonical_event_result(%{events: events} = result) when is_list(events) do
    %{result | events: Enum.sort_by(events, &event_sort_key/1)}
  end

  defp canonical_event_result(result), do: result

  defp event_result_sort_key(result) do
    {
      encode_value(Map.get(result, :scenario_id)),
      encode_value(Map.get(result, :event_type)),
      map_sort_key(Map.get(result, :source, %{}))
    }
  end

  defp event_sort_key(event) when is_map(event) do
    metadata =
      case Map.get(event, :metadata, %{}) do
        %{} = metadata -> metadata
        _metadata -> %{}
      end

    {
      event_epoch_seconds(Map.get(event, :starts_at)),
      event_epoch_seconds(Map.get(event, :ends_at)),
      encode_value(Map.get(event, :type)),
      map_sort_key(Map.take(metadata, [:ground_station_id, :target_id, :source_window_id]))
    }
  end

  defp event_sort_key(event), do: inspect(event)

  defp event_epoch_seconds(%{seconds_since_j2000: seconds}), do: seconds
  defp event_epoch_seconds(_epoch), do: nil

  defp map_sort_key(%{} = map) do
    map
    |> encode_value()
    |> Enum.sort_by(fn {key, value} -> {key, inspect(value)} end)
  end

  defp map_sort_key(value), do: encode_value(value)

  defp access_windows(event_results, event_timing_keys) do
    event_results
    |> Enum.filter(&(Map.get(&1, :event_type) == :ground_station_access))
    |> Enum.flat_map(fn result ->
      result.events
      |> Enum.with_index(1)
      |> Enum.map(fn {event, index} ->
        source_id = encode_value(result.source.ground_station_id)

        %{
          "id" => window_id(result.scenario_id, "ground_station_access", source_id, index),
          "type" => "ground_station_access",
          "scenario_id" => encode_value(result.scenario_id),
          "ground_station_id" => source_id,
          "starts_at_s" => epoch_seconds(event.starts_at),
          "ends_at_s" => epoch_seconds(event.ends_at),
          "max_elevation_deg" => event.metadata.max_elevation_deg,
          "minimum_elevation_deg" => event.metadata.minimum_elevation_deg,
          "sample_count" => refreshed_window_sample_count(event),
          "assumptions" =>
            encode_value(
              Map.take(
                event.metadata,
                [
                  :geometry_model,
                  :interpolation,
                  :refraction,
                  :terrain_mask
                ] ++ event_timing_keys
              )
            )
        }
      end)
    end)
  end

  defp target_visibility_windows(event_results, event_timing_keys) do
    event_results
    |> Enum.filter(&(Map.get(&1, :event_type) == :target_visibility))
    |> Enum.flat_map(fn result ->
      result.events
      |> Enum.with_index(1)
      |> Enum.map(fn {event, index} ->
        source_id = encode_value(result.source.target_id)

        %{
          "id" => window_id(result.scenario_id, "target_visibility", source_id, index),
          "type" => "target_visibility",
          "scenario_id" => encode_value(result.scenario_id),
          "target_id" => source_id,
          "starts_at_s" => epoch_seconds(event.starts_at),
          "ends_at_s" => epoch_seconds(event.ends_at),
          "max_elevation_deg" => event.metadata.max_elevation_deg,
          "minimum_elevation_deg" => event.metadata.minimum_elevation_deg,
          "target_priority" => event.metadata.target_priority,
          "sample_count" => refreshed_window_sample_count(event),
          "assumptions" =>
            encode_value(
              Map.take(
                event.metadata,
                [
                  :geometry_model,
                  :interpolation,
                  :refraction,
                  :terrain_mask
                ] ++ event_timing_keys
              )
            )
        }
      end)
    end)
  end

  defp refreshed_window_sample_count(event) do
    sample_count = normalized_sample_count(Map.get(event.metadata, :sample_count))
    max_sample_step_s = Map.get(event.metadata, :max_sample_step_s)
    starts_at_s = epoch_seconds(event.starts_at)
    ends_at_s = epoch_seconds(event.ends_at)

    if is_number(max_sample_step_s) and max_sample_step_s > 0 do
      required_count =
        ends_at_s
        |> Kernel.-(starts_at_s)
        |> max(0.0)
        |> Kernel./(max_sample_step_s)
        |> Float.ceil()
        |> trunc()

      max(sample_count || 0, required_count)
    else
      sample_count
    end
  end

  defp normalized_sample_count(value) when is_integer(value) and value >= 0, do: value

  defp normalized_sample_count(value) when is_number(value) and value >= 0 do
    value
    |> Float.ceil()
    |> trunc()
  end

  defp normalized_sample_count(_value), do: nil

  defp eclipse_intervals(event_results, event_timing_keys) do
    event_results
    |> Enum.filter(&(Map.get(&1, :event_type) == :eclipse))
    |> Enum.flat_map(fn result ->
      result.events
      |> Enum.with_index(1)
      |> Enum.map(fn {event, index} ->
        %{
          "id" => window_id(result.scenario_id, "eclipse", "central_body_shadow", index),
          "type" => "eclipse",
          "scenario_id" => encode_value(result.scenario_id),
          "starts_at_s" => epoch_seconds(event.starts_at),
          "ends_at_s" => epoch_seconds(event.ends_at),
          "sample_count" => refreshed_window_sample_count(event),
          "sun_direction" => encode_value(Map.get(event.metadata, :sun_direction)),
          "minimum_shadow_axis_distance_km" =>
            Map.get(event.metadata, :minimum_shadow_axis_distance_km),
          "maximum_shadow_margin_km" => Map.get(event.metadata, :maximum_shadow_margin_km),
          "assumptions" =>
            encode_value(
              Map.take(
                event.metadata,
                [
                  :shadow_model,
                  :central_body,
                  :central_body_radius_km,
                  :interpolation
                ] ++ event_timing_keys
              )
            )
        }
      end)
    end)
  end

  defp epoch_seconds(%{seconds_since_j2000: seconds}), do: seconds

  defp window_id(scenario_id, type, source_id, index) do
    ["window", scenario_id, type, source_id, index]
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

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
