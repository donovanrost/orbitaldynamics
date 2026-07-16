defmodule OrbitalDynamics.CampaignPlanner.DownlinkCompletionStaging do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ActivityTiming,
    DownlinkActivityNormalization,
    DownlinkCompletionAddition,
    DownlinkCompletionCandidates,
    DownlinkObjectiveRequirements,
    PriorActivityContext,
    ProviderResultValues,
    RepairCandidateDiff,
    ScoreTermIdentifiers
  }

  def stage(
        candidate_plan,
        warnings,
        event,
        request,
        source_candidate_activities,
        candidate_diff_by_replacement_id
      ) do
    stage(
      candidate_plan,
      warnings,
      event,
      request,
      source_candidate_activities,
      candidate_diff_by_replacement_id,
      callbacks()
    )
  end

  def stage(
        candidate_plan,
        warnings,
        event,
        request,
        source_candidate_activities,
        candidate_diff_by_replacement_id,
        candidate_callbacks
      ) do
    required_downlink_mb = required_downlink_mb(event, request)

    current_downlink_mb =
      case Map.get(event, "planned_downlink_mb") do
        value when is_number(value) -> value
        _value -> planned_downlink_mb(candidate_plan["activities"], event, candidate_callbacks)
      end

    required_contacts =
      event
      |> Map.get(
        "required_contacts",
        required_downlink_contacts(request, candidate_callbacks)
      )
      |> ceil_count()

    current_contacts =
      case Map.get(event, "planned_contacts") do
        value when is_number(value) -> ceil_count(value)
        _value -> current_contacts(candidate_plan["activities"], event, candidate_callbacks)
      end

    needed_contacts = max(required_contacts - current_contacts, 0)

    needed_downlink_mb =
      case required_downlink_mb do
        value when is_number(value) -> max(value - current_downlink_mb, 0.0)
        _value -> 0.0
      end

    if needed_contacts == 0 and needed_downlink_mb <= 0.0 do
      {candidate_plan, warnings}
    else
      source_candidate_activities
      |> select(
        event,
        request,
        candidate_plan,
        needed_contacts,
        needed_downlink_mb,
        candidate_callbacks
      )
      |> apply_selection(
        candidate_plan,
        warnings,
        event,
        candidate_diff_by_replacement_id,
        %{
          "required_downlink_mb" => required_downlink_mb,
          "planned_downlink_mb" => current_downlink_mb
        },
        candidate_callbacks
      )
    end
  end

  defp current_contacts(activities, event, candidate_callbacks) do
    activities
    |> Enum.map(&stringify_keys/1)
    |> Enum.count(
      &(downlink_activity?(&1, candidate_callbacks) and
          downlink_completion_event_match?(&1, event, candidate_callbacks))
    )
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_struct{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values), do: Enum.map(values, &encode_value/1)
  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp ceil_count(value) when is_integer(value), do: max(value, 0)
  defp ceil_count(value) when is_float(value), do: value |> Float.ceil() |> trunc() |> max(0)
  defp ceil_count(_value), do: 0

  defp select(
         source_candidate_activities,
         event,
         request,
         candidate_plan,
         needed_contacts,
         needed_downlink_mb,
         candidate_callbacks
       ) do
    source_candidate_activities
    |> DownlinkCompletionCandidates.candidates(
      event,
      request,
      candidate_callbacks
    )
    |> select_candidates(
      occupied_activities(candidate_plan["activities"], event, candidate_callbacks),
      needed_contacts,
      needed_downlink_mb,
      candidate_callbacks
    )
  end

  defp apply_selection(
         [],
         candidate_plan,
         warnings,
         _event,
         _candidate_diffs,
         _context,
         _callbacks
       ) do
    {candidate_plan,
     ["downlink completion gap not staged: no_validated_candidate_window" | warnings]}
  end

  defp apply_selection(
         downlinks,
         candidate_plan,
         warnings,
         event,
         candidate_diff_by_replacement_id,
         throughput_context,
         candidate_callbacks
       ) do
    staged_downlink_mb = planned_downlink_mb(downlinks, event, candidate_callbacks)
    throughput_context = Map.put(throughput_context, "staged_downlink_mb", staged_downlink_mb)

    additions =
      Enum.map(
        downlinks,
        &addition(&1, event, candidate_diff_by_replacement_id, throughput_context)
      )

    candidate_plan =
      candidate_plan
      |> Map.update!("activities", &(additions ++ &1))
      |> Map.update!("strategic_additions", &(additions ++ &1))

    {candidate_plan, warnings}
  end

  defp occupied_activities(activities, event, candidate_callbacks) do
    ignored_ids = provider_failed_downlink_activity_ids(event, candidate_callbacks)

    if MapSet.size(ignored_ids) == 0 do
      activities
    else
      Enum.reject(activities, &MapSet.member?(ignored_ids, activity_id(&1)))
    end
  end

  defp provider_failed_downlink_activity_ids(
         %{"contact_result" => result} = event,
         candidate_callbacks
       ) do
    if provider_result_failure_value?(result) do
      [
        event["missed_downlink_activity_id"],
        event["missed_downlink_activity_ids"],
        event["source_activity_id"],
        event["source_activity_ids"],
        event["missed_downlink"],
        event["missed_downlinks"],
        event["source_contact"],
        event["source_contacts"]
      ]
      |> Enum.flat_map(&split_activity_ids(&1, candidate_callbacks))
      |> MapSet.new()
    else
      MapSet.new()
    end
  end

  defp provider_failed_downlink_activity_ids(_event, _callbacks), do: MapSet.new()

  defp split_activity_ids(value, _callbacks) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp split_activity_ids(values, candidate_callbacks) when is_list(values) do
    Enum.flat_map(values, &split_activity_ids(&1, candidate_callbacks))
  end

  defp split_activity_ids(%{} = value, candidate_callbacks) do
    value
    |> ScoreTermIdentifiers.activity_id_values(score_term_identifier_callbacks())
    |> Enum.flat_map(&split_activity_ids(&1, candidate_callbacks))
  end

  defp split_activity_ids(_value, _callbacks), do: []

  defp select_candidates(candidates, occupied_activities, needed_count, needed_mb, _callbacks) do
    candidates
    |> Enum.reduce_while({[], occupied_activities, 0.0}, fn candidate, {selected, occupied, mb} ->
      cond do
        requirement_met?(selected, mb, needed_count, needed_mb) ->
          {:halt, {selected, occupied, mb}}

        Enum.any?(occupied, &ActivityTiming.overlaps?(&1, candidate)) ->
          {:cont, {selected, occupied, mb}}

        true ->
          {:cont,
           {
             [candidate | selected],
             [candidate | occupied],
             mb + downlink_activity_mb(candidate)
           }}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  defp requirement_met?(selected, mb, needed_count, needed_mb) do
    count_met? = needed_count <= 0 or length(selected) >= needed_count
    mb_met? = needed_mb <= 0.0 or mb >= needed_mb

    count_met? and mb_met?
  end

  defp addition(candidate, event, candidate_diff_by_replacement_id, throughput_context) do
    candidate_diff =
      candidate_diff_by_replacement_id
      |> Map.get(activity_id(candidate))
      |> candidate_diff_match("replacement")

    DownlinkCompletionAddition.build(
      candidate,
      event,
      candidate_diff,
      throughput_context,
      downlink_activity_mb(candidate)
    )
  end

  defp candidate_diff_match(nil, _scope), do: nil
  defp candidate_diff_match([], _scope), do: nil
  defp candidate_diff_match(%{} = row, _scope), do: row
  defp candidate_diff_match([row], _scope), do: row

  defp candidate_diff_match(rows, scope) when is_list(rows) do
    RepairCandidateDiff.match(rows, scope)
  end

  defp callbacks do
    [
      normalize_downlink_activity: &DownlinkActivityNormalization.normalize/1,
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      within_remaining_horizon?: &ActivityTiming.within_remaining_horizon?/2,
      default_strategy_horizon: &default_strategy_horizon/1,
      candidate_score: &candidate_score/1,
      activity_start: &ActivityTiming.activity_start/1,
      activity_end: &ActivityTiming.activity_end/1,
      activity_id: &ActivityIdentity.activity_id/1,
      event_ground_station_id: &event_ground_station_id/1,
      activity_ground_station_id: &ActivityIdentity.ground_station_id/1
    ]
  end

  defp default_strategy_horizon(request) do
    ActivityTiming.remaining_horizon(
      request.prior_plan,
      request.remaining_horizon,
      request.current_epoch_s
    )
  end

  defp candidate_score(candidate),
    do: numeric_or_nil(Map.get(candidate, "score")) || 0.0

  defp event_ground_station_id(event) do
    case encode_value(
           Map.get(event, "ground_station_id") || Map.get(event, "station_id") ||
             DownlinkActivityNormalization.nested_ground_station_id(event)
         ) do
      value when is_binary(value) and value != "" -> value
      _value -> nil
    end
  end

  defp activity_id(activity),
    do: ActivityIdentity.activity_id(activity, encode_value: &encode_value/1)

  defp provider_result_failure_value?(result),
    do: ProviderResultValues.success_value(result) == :failure

  defp score_term_identifier_callbacks,
    do: [
      stringify_keys: &stringify_keys/1,
      encode_value: &encode_value/1
    ]

  defp downlink_activity_mb(activity) do
    activity_capacity = numeric_or_nil(Map.get(activity, "capacity_adjusted_throughput_mb"))

    model_capacity =
      numeric_or_nil(get_in(activity, ["throughput_model", "capacity_adjusted_throughput_mb"]))

    cond do
      is_number(activity_capacity) ->
        activity_capacity * 1.0

      is_number(model_capacity) ->
        model_capacity * 1.0

      true ->
        throughput_mb =
          numeric_or_nil(Map.get(activity, "estimated_throughput_mb")) ||
            numeric_or_nil(Map.get(activity, "planned_throughput_mb")) || 0.0

        station_capacity_fraction =
          numeric_or_nil(get_in(activity, ["throughput_model", "station_capacity_fraction"])) ||
            numeric_or_nil(Map.get(activity, "station_capacity_fraction")) || 1.0

        throughput_mb * station_capacity_fraction
    end
  end

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp downlink_activity?(activity, candidate_callbacks) do
    downlink_activity? = Keyword.fetch!(candidate_callbacks, :downlink_activity?)

    downlink_activity?.(activity)
  end

  defp downlink_completion_event_match?(candidate, event, candidate_callbacks) do
    DownlinkCompletionCandidates.event_match?(
      candidate,
      event,
      candidate_callbacks
    )
  end

  defp required_downlink_contacts(request, candidate_callbacks) do
    DownlinkObjectiveRequirements.required_contacts(
      request.mission_state,
      request.prior_plan,
      downlink_objective_requirement_callbacks(candidate_callbacks)
    )
  end

  defp required_downlink_mb(%{} = event, request) do
    objective_required_downlink_mb(event) || mission_required_downlink_mb(request.mission_state)
  end

  defp objective_required_downlink_mb(%{} = objective) do
    DownlinkObjectiveRequirements.required_mb(
      objective,
      downlink_objective_requirement_callbacks()
    )
  end

  defp objective_required_downlink_mb(_objective), do: nil

  defp mission_required_downlink_mb(mission_state) do
    mission_state
    |> downlink_completion_objectives()
    |> Enum.map(&objective_required_downlink_mb/1)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp downlink_completion_objectives(mission_state) do
    DownlinkObjectiveRequirements.objectives(
      mission_state,
      downlink_objective_requirement_callbacks()
    )
  end

  defp objective_number_from_fields(objective, fields) do
    Enum.find_value(fields, fn field ->
      case numeric_or_nil(Map.get(objective, field)) do
        value when is_number(value) -> value
        _value -> nil
      end
    end)
  end

  defp planned_downlink_mb(activities, objective, candidate_callbacks) do
    DownlinkObjectiveRequirements.planned_mb(
      activities,
      objective,
      downlink_objective_requirement_callbacks(candidate_callbacks)
    )
  end

  defp downlink_objective_requirement_callbacks(candidate_callbacks) do
    downlink_objective_requirement_callbacks() ++
      [
        prior_plan_activities: &prior_plan_activities/1,
        downlink_activity?: &downlink_activity?(&1, candidate_callbacks),
        downlink_completion_event_match?:
          &downlink_completion_event_match?(&1, &2, candidate_callbacks),
        downlink_activity_mb: &downlink_activity_mb/1
      ]
  end

  defp downlink_objective_requirement_callbacks,
    do: [
      stringify_keys: &stringify_keys/1,
      encode_value: &encode_value/1,
      objective_number_from_fields: &objective_number_from_fields/2
    ]

  defp prior_plan_activities(prior_plan), do: PriorActivityContext.activities(prior_plan)
end
