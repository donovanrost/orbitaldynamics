defmodule OrbitalDynamics.CampaignPlanner.ActivityCandidate do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    ScalarValues,
    ValueEncoding
  }

  alias OrbitalDynamics.AccessEventResultAdmission
  alias OrbitalDynamics.EventDetectors.Eclipses

  @event_timing_keys [
    :interpolation,
    :boundary_refinement,
    :start_boundary,
    :end_boundary,
    :start_boundary_detail,
    :end_boundary_detail,
    :event_timing_policy,
    :event_detector,
    :event_time_tolerance_s,
    :max_sample_step_s,
    :confidence
  ]

  @max_eclipse_intervals 10_000
  @safe_number_limit 1.0e15

  def build(event_results, campaign, constraints, policy) do
    build(event_results, campaign, constraints, policy, callbacks())
  end

  def build(event_results, campaign, constraints, policy, callbacks) do
    {event_results, invalid_observation_lighting} =
      case AccessEventResultAdmission.admit_event_results(event_results) do
        {:ok, event_results, invalid_observation_lighting} ->
          {event_results, invalid_observation_lighting}

        {:error, {:invalid_observation_lighting, _reason}} ->
          {[], AccessEventResultAdmission.all_invalid_observation_lighting()}
      end

    event_results = canonical_event_results(event_results, callbacks)
    eclipse_intervals_by_scenario = eclipse_intervals_by_scenario(event_results, callbacks)
    numeric_policy_value = Keyword.fetch!(callbacks, :numeric_policy_value)
    boolean_policy_value = Keyword.fetch!(callbacks, :boolean_policy_value)
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    min_duration_s = numeric_policy_value.(constraints, "min_activity_duration_s", 0.0)
    avoid_eclipse? = boolean_policy_value.(constraints, "avoid_eclipse", true)

    event_results
    |> Enum.flat_map(fn
      %{event_type: :target_visibility} = result ->
        if AccessEventResultAdmission.invalid_observation_lighting_scenario?(
             invalid_observation_lighting,
             result.scenario_id
           ) do
          []
        else
          eclipse_intervals =
            Map.get(eclipse_intervals_by_scenario, encode_value.(result.scenario_id), [])

          result.events
          |> Enum.with_index(1)
          |> Enum.flat_map(fn event_with_index ->
            case observe(result, event_with_index, campaign, eclipse_intervals, policy, callbacks) do
              {:error, {:invalid_observation_lighting, _reason}} -> []
              %{} = activity -> [activity]
            end
          end)
          |> Enum.reject(fn activity ->
            activity["duration_s"] < min_duration_s or
              (avoid_eclipse? and activity["eclipse_overlap_s"] > 0.0)
          end)
        end

      %{event_type: :ground_station_access} = result ->
        contact_activity_types = contact_activity_types(policy, callbacks)

        result.events
        |> Enum.with_index(1)
        |> Enum.flat_map(fn event_index ->
          Enum.map(contact_activity_types, &contact(result, event_index, policy, &1, callbacks))
        end)
        |> Enum.reject(&(&1["duration_s"] < min_duration_s))

      _result ->
        []
    end)
  end

  def observe(result, {event, index}, campaign, eclipse_intervals, policy, callbacks) do
    overlap_duration = Keyword.fetch!(callbacks, :overlap_duration)

    with {:ok, result, event} <- AccessEventResultAdmission.admit_observation_input(result, event),
         starts_at_s = event.starts_at.seconds_since_j2000,
         ends_at_s = event.ends_at.seconds_since_j2000,
         target_id = event.metadata.target_id,
         {:ok, duration_s} <- duration_seconds(starts_at_s, ends_at_s),
         {:ok, eclipse_intervals} <- validate_eclipse_intervals(eclipse_intervals),
         {:ok, eclipse_overlap_s} <-
           observation_overlap_duration(
             overlap_duration,
             {starts_at_s, ends_at_s},
             eclipse_intervals
           ),
         :ok <- validate_lighting_inputs(duration_s, eclipse_overlap_s),
         {:ok, lighting_summary} <- lighting_summary(duration_s, eclipse_overlap_s) do
      build_observation_activity(
        result,
        event,
        index,
        campaign,
        policy,
        callbacks,
        starts_at_s,
        ends_at_s,
        target_id,
        duration_s,
        eclipse_overlap_s,
        lighting_summary
      )
    else
      {:error, reason} -> {:error, {:invalid_observation_lighting, reason}}
    end
  end

  defp build_observation_activity(
         result,
         event,
         index,
         campaign,
         policy,
         callbacks,
         starts_at_s,
         ends_at_s,
         target_id,
         duration_s,
         eclipse_overlap_s,
         lighting_summary
       ) do
    target = target_by_id(campaign, target_id, callbacks)
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    numeric_policy_value = Keyword.fetch!(callbacks, :numeric_policy_value)
    activity_id = Keyword.fetch!(callbacks, :activity_id)
    window_id = Keyword.fetch!(callbacks, :window_id)
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    score = Keyword.fetch!(callbacks, :score)

    priority =
      numeric_or_nil.(Map.get(target || %{}, "priority")) ||
        numeric_or_nil.(event.metadata.target_priority) || 1.0

    id = activity_id.(result.scenario_id, "observe", target_id, index)
    source_window_id = window_id.(result.scenario_id, "target_visibility", target_id, index)

    score_terms = %{
      "target_value" =>
        priority * duration_s * numeric_policy_value.(policy, "target_value_weight", 1.0),
      "eclipse_penalty" =>
        eclipse_overlap_s *
          numeric_policy_value.(policy, "eclipse_penalty_weight", 1.0) *
          -1.0
    }

    %{
      "id" => id,
      "type" => "observe",
      "scenario_id" => encode_value.(result.scenario_id),
      "target_id" => encode_value.(target_id),
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => duration_s,
      "score" => score.(score_terms),
      "score_terms" => score_terms,
      "eclipse_overlap_s" => eclipse_overlap_s,
      "source_window_id" => source_window_id,
      "source_window" =>
        %{
          "id" => source_window_id,
          "type" => "target_visibility",
          "max_elevation_deg" => event.metadata.max_elevation_deg,
          "minimum_elevation_deg" => event.metadata.minimum_elevation_deg
        }
        |> Map.merge(event_timing_metadata(event.metadata, callbacks)),
      "cadence_import" => %{
        "activity_type" => "observation",
        "external_id" => id
      }
    }
    |> Map.merge(activity_precondition_context(event.metadata, callbacks))
    |> Map.merge(activity_resource_projection_context(event.metadata, callbacks))
    |> Map.merge(lighting_summary)
  end

  def contact_activity_types(policy, callbacks) do
    normalized_status_token = Keyword.fetch!(callbacks, :normalized_status_token)

    policy
    |> Map.get("contact_activity_types", ["downlink"])
    |> List.wrap()
    |> Enum.map(normalized_status_token)
    |> Enum.filter(&(&1 in ["downlink", "command", "tracking", "health_check"]))
    |> case do
      [] -> ["downlink"]
      activity_types -> Enum.uniq(activity_types)
    end
  end

  def contact(result, {event, index}, policy, type, callbacks) do
    starts_at_s = event.starts_at.seconds_since_j2000
    ends_at_s = event.ends_at.seconds_since_j2000
    ground_station_id = result.source.ground_station_id
    duration_s = ends_at_s - starts_at_s
    numeric_policy_value = Keyword.fetch!(callbacks, :numeric_policy_value)
    activity_id = Keyword.fetch!(callbacks, :activity_id)
    window_id = Keyword.fetch!(callbacks, :window_id)
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    score = Keyword.fetch!(callbacks, :score)
    downlink_rate_mb_s = numeric_policy_value.(policy, "downlink_rate_mb_s", 1.0)
    id = activity_id.(result.scenario_id, type, ground_station_id, index)

    source_window_id =
      window_id.(result.scenario_id, "ground_station_access", ground_station_id, index)

    score_terms = %{
      "contact_value" => duration_s * numeric_policy_value.(policy, "contact_value_weight", 0.1)
    }

    %{
      "id" => id,
      "type" => type,
      "direction" => contact_candidate_direction(type),
      "scenario_id" => encode_value.(result.scenario_id),
      "ground_station_id" => encode_value.(ground_station_id),
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "duration_s" => duration_s,
      "station_availability" => "available",
      "schedule_conflict_status" => "not_evaluated",
      "score" => score.(score_terms),
      "score_terms" => score_terms,
      "source_window_id" => source_window_id,
      "source_window" =>
        %{
          "id" => source_window_id,
          "type" => "ground_station_access",
          "max_elevation_deg" => event.metadata.max_elevation_deg,
          "minimum_elevation_deg" => event.metadata.minimum_elevation_deg
        }
        |> Map.merge(event_timing_metadata(event.metadata, callbacks)),
      "cadence_import" => %{
        "activity_type" => contact_candidate_cadence_import_type(type),
        "external_id" => id,
        "schema_contract" => "proposed_contact.v1"
      }
    }
    |> Map.merge(activity_precondition_context(event.metadata, callbacks))
    |> Map.merge(activity_resource_projection_context(event.metadata, callbacks))
    |> maybe_add_downlink_throughput(type, duration_s, downlink_rate_mb_s)
  end

  defp target_by_id(campaign, target_id, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    campaign
    |> Map.get("targets", [])
    |> Enum.find(&(Map.get(&1, "id") == encode_value.(target_id)))
  end

  defp canonical_event_results(event_results, callbacks) do
    event_results
    |> Enum.map(&canonical_event_result(&1, callbacks))
    |> Enum.sort_by(&event_result_sort_key(&1, callbacks))
  end

  defp canonical_event_result(%{events: events} = result, callbacks) when is_list(events) do
    %{result | events: Enum.sort_by(events, &event_sort_key(&1, callbacks))}
  end

  defp canonical_event_result(result, _callbacks), do: result

  defp event_result_sort_key(result, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    {
      encode_value.(Map.get(result, :scenario_id)),
      encode_value.(Map.get(result, :event_type)),
      map_sort_key(Map.get(result, :source, %{}), callbacks)
    }
  end

  defp event_sort_key(event, callbacks) when is_map(event) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    metadata =
      case Map.get(event, :metadata, %{}) do
        %{} = metadata -> metadata
        _metadata -> %{}
      end

    {
      event_epoch_seconds(Map.get(event, :starts_at)),
      event_epoch_seconds(Map.get(event, :ends_at)),
      encode_value.(Map.get(event, :type)),
      map_sort_key(
        Map.take(metadata, [:ground_station_id, :target_id, :source_window_id]),
        callbacks
      )
    }
  end

  defp event_sort_key(event, _callbacks), do: inspect(event)

  defp event_epoch_seconds(%{seconds_since_j2000: seconds}), do: seconds
  defp event_epoch_seconds(_epoch), do: nil

  defp map_sort_key(%{} = map, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    map
    |> encode_value.()
    |> Enum.sort_by(fn {key, value} -> {key, inspect(value)} end)
  end

  defp map_sort_key(value, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    encode_value.(value)
  end

  defp eclipse_intervals_by_scenario(event_results, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    event_results
    |> Enum.reduce(%{}, fn
      %{event_type: :eclipse, events: events, scenario_id: scenario_id}, intervals_by_scenario ->
        scenario_id = encode_value.(scenario_id)

        events
        |> Enum.reduce(intervals_by_scenario, fn event, intervals_by_scenario ->
          interval = {
            event.starts_at.seconds_since_j2000,
            event.ends_at.seconds_since_j2000
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

  defp event_timing_metadata(metadata, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    metadata
    |> Map.take(@event_timing_keys)
    |> encode_value.()
  end

  defp activity_precondition_context(metadata, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    metadata
    |> encode_value.()
    |> Map.take([
      "spacecraft_available",
      "payload_available",
      "antenna_available",
      "degraded",
      "resource_blocking_dimension",
      "incompatible_activity_types",
      "suppressed_activity_types",
      "command_authorized",
      "command_authority_status",
      "authority_status",
      "required_authority",
      "required_escalation_authority",
      "command_safety_status",
      "safety_status",
      "command_safety_checked",
      "safety_checked",
      "activity_template",
      "activity_context"
    ])
    |> compact_map.()
  end

  defp activity_resource_projection_context(metadata, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    metadata
    |> encode_value.()
    |> Map.take([
      "estimated_storage_mb",
      "planned_data_volume_mb",
      "data_volume_mb",
      "estimated_data_volume_mb",
      "estimated_energy_used_wh",
      "battery_energy_consumed_wh",
      "battery_energy_generated_wh"
    ])
    |> compact_map.()
  end

  defp contact_candidate_direction(type) when type in ["command", "tracking", "health_check"],
    do: type

  defp contact_candidate_direction(_type), do: "downlink"

  defp contact_candidate_cadence_import_type("command"), do: "command"
  defp contact_candidate_cadence_import_type(_type), do: "contact"

  defp duration_seconds(starts_at_s, ends_at_s) do
    with :ok <- validate_number(:starts_at_s, starts_at_s),
         :ok <- validate_number(:ends_at_s, ends_at_s) do
      duration_s = ends_at_s - starts_at_s

      cond do
        not finite_number?(duration_s) -> {:error, {:invalid_option, :duration_s}}
        duration_s < 0.0 -> {:error, {:invalid_timing, :negative_duration_s}}
        true -> {:ok, duration_s}
      end
    end
  end

  defp observation_overlap_duration(overlap_duration, interval, intervals) do
    case overlap_duration.(interval, intervals) do
      value when is_integer(value) or is_float(value) ->
        if finite_number?(value) do
          {:ok, value}
        else
          raise ArgumentError, "overlap_duration callback returned invalid eclipse_overlap_s"
        end
    end
  end

  defp lighting_summary(duration_s, eclipse_overlap_s) do
    case Eclipses.lighting_summary(duration_s, eclipse_overlap_s) do
      %{} = summary ->
        {:ok, summary}

      {:error, {:invalid_option, field}} when field in [:duration_s, :eclipse_overlap_s] ->
        {:error, {:invalid_option, field}}
    end
  end

  defp validate_lighting_inputs(duration_s, eclipse_overlap_s) do
    cond do
      eclipse_overlap_s < 0.0 ->
        {:error, {:invalid_timing, :negative_eclipse_overlap_s}}

      eclipse_overlap_s > duration_s ->
        {:error, {:invalid_timing, :eclipse_overlap_exceeds_duration_s}}

      true ->
        :ok
    end
  end

  defp validate_eclipse_intervals(intervals) do
    with {:ok, intervals} <-
           bounded_list_items(intervals, :eclipse_intervals, @max_eclipse_intervals) do
      Enum.reduce_while(intervals, {:ok, []}, fn
        {starts_at_s, ends_at_s} = interval, {:ok, accepted} ->
          with :ok <- validate_number(:eclipse_intervals, starts_at_s),
               :ok <- validate_number(:eclipse_intervals, ends_at_s) do
            interval_duration_s = ends_at_s - starts_at_s

            cond do
              not finite_number?(interval_duration_s) ->
                {:halt, {:error, {:invalid_option, :eclipse_intervals}}}

              interval_duration_s < 0.0 ->
                {:halt, {:error, {:invalid_timing, :negative_eclipse_interval_duration_s}}}

              true ->
                {:cont, {:ok, [interval | accepted]}}
            end
          else
            {:error, reason} -> {:halt, {:error, reason}}
          end

        _interval, _accepted ->
          {:halt, {:error, {:invalid_option, :eclipse_intervals}}}
      end)
      |> case do
        {:ok, accepted} -> {:ok, Enum.reverse(accepted)}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp validate_number(field, value) when is_integer(value) or is_float(value) do
    if finite_number?(value) do
      :ok
    else
      {:error, {:invalid_option, field}}
    end
  end

  defp validate_number(field, _value), do: {:error, {:invalid_option, field}}

  defp bounded_list_items(list, field, limit) when is_list(list) do
    bounded_list_items(list, [], 0, field, limit)
  end

  defp bounded_list_items(_not_list, field, _limit), do: {:error, {:invalid_container, field}}

  defp bounded_list_items(_list, _acc, count, field, limit) when count > limit,
    do: {:error, {:container_limit_exceeded, field}}

  defp bounded_list_items([], acc, _count, _field, _limit), do: {:ok, Enum.reverse(acc)}

  defp bounded_list_items([head | tail], acc, count, field, limit) do
    bounded_list_items(tail, [head | acc], count + 1, field, limit)
  end

  defp bounded_list_items(_improper_tail, _acc, _count, field, _limit),
    do: {:error, {:invalid_container, field}}

  defp finite_number?(value) when is_integer(value), do: abs(value) <= @safe_number_limit

  defp finite_number?(value) when is_float(value) do
    value == value and value - value == 0.0 and abs(value) <= @safe_number_limit
  end

  defp maybe_add_downlink_throughput(activity, "downlink", duration_s, downlink_rate_mb_s) do
    activity
    |> Map.put("estimated_throughput_mb", duration_s * downlink_rate_mb_s)
    |> Map.put("throughput_model", %{
      "model" => "fixed_rate_from_campaign_policy",
      "downlink_rate_mb_s" => downlink_rate_mb_s
    })
  end

  defp maybe_add_downlink_throughput(activity, _type, _duration_s, _downlink_rate_mb_s) do
    activity
  end

  defp callbacks,
    do: [
      encode_value: &ValueEncoding.encode_value/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      numeric_policy_value: &numeric_policy_value/3,
      boolean_policy_value: &boolean_policy_value/3,
      normalized_status_token: &ScalarValues.normalized_status_token/1,
      overlap_duration: &ActivityTiming.overlap_duration/2,
      activity_id: &ActivityIdentity.activity_id/4,
      window_id: &ActivityIdentity.window_id/4,
      score: &score/1,
      compact_map: &ValueEncoding.compact_map/1
    ]

  defp numeric_policy_value(policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key, default)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp boolean_policy_value(policy, key, default) do
    case ScalarValues.json_boolean_value(Map.get(policy, key, default)) do
      value when is_boolean(value) -> value
      _value -> default
    end
  end

  defp score(score_terms) do
    score_terms
    |> Map.values()
    |> Enum.sum()
  end
end
