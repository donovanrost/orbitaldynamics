defmodule OrbitalDynamics.CampaignPlanner.DownlinkConstrainedBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityTiming,
    CollectionLatencyIdentity,
    DownlinkActivityNormalization,
    DownlinkCompletionCandidates,
    DownlinkConstrainedBranchIds,
    DownlinkObjectiveRequirements,
    MissionStateResourceSources,
    ObjectiveWindowBounds,
    OperationalFeedbackNormalization,
    PriorActivityContext,
    ProviderResultValues,
    RealizedDownlinkEvents,
    ResourceMarginPressureEvents,
    RepairRealizedState
  }

  @realized_completion_statuses ~w(completed executed)
  @realized_failure_statuses ~w(missed failed canceled cancelled rejected)
  @realized_statuses @realized_completion_statuses ++ @realized_failure_statuses ++ ~w(delayed)
  @realized_feedback_match_statuses ~w(matched)
  @resource_availability_true_tokens ~w(true 1 yes y available nominal operational enabled)
  @resource_availability_false_tokens ~w(false 0 no n unavailable offline down outage maintenance disabled)

  def build(mission_state, prior_plan, policy) do
    mission_state
    |> downlink_completion_objectives()
    |> DownlinkConstrainedBranchIds.objective_entries()
    |> Enum.map(fn {objective, multiple_objectives?, index} ->
      branch(mission_state, prior_plan, policy, objective, multiple_objectives?, index)
    end)
    |> Enum.reject(&is_nil/1)
    |> DownlinkConstrainedBranchIds.disambiguate(downlink_constrained_branch_id_callbacks())
  end

  defp downlink_completion_objectives(mission_state) do
    DownlinkObjectiveRequirements.objectives(
      mission_state,
      downlink_objective_requirement_callbacks()
    )
  end

  defp objective_required_downlink_mb(%{} = objective) do
    DownlinkObjectiveRequirements.required_mb(
      objective,
      downlink_objective_requirement_callbacks()
    )
  end

  defp objective_required_downlink_mb(_objective), do: nil

  defp branch(
         mission_state,
         prior_plan,
         policy,
         objective,
         multiple_objectives?,
         index
       ) do
    required_contacts = required_downlink_contacts(objective, prior_plan)

    planned_contacts = effective_planned_downlink_count(prior_plan, mission_state, objective)

    realized_downlink_gap = realized_downlink_gap(mission_state, prior_plan, objective)

    downlink_sources = mission_state_resource_margin_sources(mission_state, "downlink_margin")
    storage_sources = mission_state_resource_margin_sources(mission_state, "storage_margin")
    downlink_source = List.first(downlink_sources)
    storage_source = List.first(storage_sources)

    downlink_margin = downlink_source && downlink_source["downlink_margin"]
    storage_margin = storage_source && storage_source["storage_margin"]
    required_downlink_mb = objective_required_downlink_mb(objective || %{})

    planned_downlink_mb =
      effective_planned_downlink_mb(prior_plan, mission_state, objective)

    completion_gap? =
      planned_contacts < required_contacts or
        (is_number(required_downlink_mb) and planned_downlink_mb < required_downlink_mb)

    capacity_constrained? =
      is_number(downlink_margin) and downlink_margin <= policy["downlink_margin_threshold"]

    storage_constrained? =
      is_number(storage_margin) and storage_margin <= policy["storage_margin_threshold"]

    base_events =
      base_events(
        prior_plan,
        policy,
        objective,
        %{
          required_contacts: required_contacts,
          planned_contacts: planned_contacts,
          realized_downlink_gap: realized_downlink_gap,
          downlink_margin: downlink_margin,
          storage_margin: storage_margin,
          required_downlink_mb: required_downlink_mb,
          planned_downlink_mb: planned_downlink_mb,
          completion_gap?: completion_gap?,
          capacity_constrained?: capacity_constrained?,
          storage_constrained?: storage_constrained?
        }
      )

    events =
      base_events ++
        resource_margin_pressure_events(
          mission_state,
          downlink_sources,
          policy,
          "downlink_margin",
          "downlink_margin_threshold",
          "downlink_margin_low"
        ) ++
        resource_margin_pressure_events(
          mission_state,
          storage_sources,
          policy,
          "storage_margin",
          "storage_margin_threshold",
          "storage_margin_low"
        )

    if events != [] do
      %{
        "id" =>
          DownlinkConstrainedBranchIds.branch_id(
            objective,
            multiple_objectives?,
            index,
            downlink_constrained_branch_id_callbacks()
          ),
        "label" =>
          DownlinkConstrainedBranchIds.branch_label(objective, multiple_objectives?, index),
        "events" => events,
        "metadata" => %{
          "derived_source" => mission_state_resource_source_path(mission_state, "downlink_margin")
        }
      }
    end
  end

  defp base_events(prior_plan, policy, objective, context) do
    event_required_contacts =
      if context.storage_constrained? do
        max(context.required_contacts, context.planned_contacts + 1)
      else
        context.required_contacts
      end

    []
    |> maybe_append_branch_event(
      context.completion_gap? or context.storage_constrained?,
      %{
        "type" => "downlink_completion_gap",
        "objective_id" => objective && objective["id"],
        "objective_type" => objective && objective["type"],
        "required_contacts" => event_required_contacts,
        "planned_contacts" => context.planned_contacts,
        "required_downlink_mb" => context.required_downlink_mb,
        "planned_downlink_mb" => context.planned_downlink_mb,
        "scenario_id" => objective && objective["scenario_id"],
        "ground_station_id" => objective && objective_ground_station_id(objective),
        "collection_id" =>
          CollectionLatencyIdentity.objective_only_value(objective, "collection_id"),
        "collection_ids" =>
          CollectionLatencyIdentity.objective_only_values(objective, "collection_id"),
        "product_id" => CollectionLatencyIdentity.objective_only_value(objective, "product_id"),
        "product_ids" => CollectionLatencyIdentity.product_ids(objective || %{}, %{}),
        "payload_id" => CollectionLatencyIdentity.objective_only_value(objective, "payload_id"),
        "payload_ids" => CollectionLatencyIdentity.objective_only_values(objective, "payload_id"),
        "instrument_id" =>
          CollectionLatencyIdentity.objective_only_value(objective, "instrument_id"),
        "instrument_ids" =>
          CollectionLatencyIdentity.objective_only_values(objective, "instrument_id"),
        "starts_at_s" => objective_window_start(objective, 0.0),
        "ends_at_s" =>
          objective_window_end(
            objective,
            planning_horizon_duration_s(prior_plan, 0.0)
          ),
        "derivation_reasons" =>
          derivation_reasons(
            context.completion_gap?,
            context.storage_constrained?,
            context.capacity_constrained?,
            context.realized_downlink_gap["statuses"],
            context.realized_downlink_gap["contact_results"]
          ),
        "storage_margin" => context.storage_margin,
        "storage_margin_threshold" => policy["storage_margin_threshold"],
        "source_activity_id" => context.realized_downlink_gap["source_activity_id"],
        "source_activity_ids" => context.realized_downlink_gap["source_activity_ids"],
        "realized_status" => context.realized_downlink_gap["realized_status"],
        "contact_result" => context.realized_downlink_gap["contact_result"]
      }
      |> compact_map()
    )
    |> maybe_append_branch_event(context.capacity_constrained?, %{
      "type" => "reduced_downlink_capacity",
      "capacity_fraction" => min(context.downlink_margin || 0.5, 1.0),
      "starts_at_s" => 0.0,
      "ends_at_s" => planning_horizon_duration_s(prior_plan, 0.0)
    })
    |> Enum.reverse()
  end

  defp realized_downlink_gap(mission_state, prior_plan, objective) do
    realized =
      mission_state
      |> realized_downlink_events(prior_plan)
      |> Enum.filter(&downlink_completion_event_match?(&1, objective || %{}))

    source_activity_ids =
      realized
      |> Enum.map(& &1["id"])
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()
      |> Enum.sort()

    statuses =
      realized
      |> Enum.map(& &1["status"])
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()
      |> Enum.sort()

    contact_results =
      realized
      |> Enum.flat_map(&ProviderResultValues.values(&1["contact_result"]))
      |> Enum.uniq()
      |> Enum.sort()

    %{
      "source_activity_id" => List.first(source_activity_ids),
      "source_activity_ids" => source_activity_ids,
      "realized_status" => join_or_nil(statuses),
      "statuses" => statuses,
      "contact_result" => join_or_nil(contact_results),
      "contact_results" => contact_results
    }
  end

  defp effective_planned_downlink_count(prior_plan, mission_state, objective) do
    missed_count =
      mission_state
      |> missed_realized_downlink_ids(prior_plan, objective)
      |> length()

    prior_plan
    |> planned_downlink_count(objective)
    |> Kernel.-(missed_count)
    |> max(0)
  end

  defp required_downlink_contacts(objective, prior_plan) do
    DownlinkObjectiveRequirements.required_contacts(
      objective,
      prior_plan,
      downlink_objective_requirement_callbacks()
    )
  end

  defp planned_downlink_count(prior_plan, objective) do
    DownlinkObjectiveRequirements.planned_count(
      prior_plan,
      objective,
      downlink_objective_requirement_callbacks()
    )
  end

  defp effective_planned_downlink_mb(prior_plan, mission_state, objective) do
    missed_ids =
      mission_state
      |> missed_realized_downlink_ids(prior_plan, objective)
      |> MapSet.new()

    prior_plan
    |> prior_plan_activities()
    |> Enum.map(&stringify_keys/1)
    |> Enum.reject(&MapSet.member?(missed_ids, &1["id"]))
    |> planned_downlink_mb(objective)
  end

  defp planned_downlink_mb(activities, objective) do
    DownlinkObjectiveRequirements.planned_mb(
      activities,
      objective,
      downlink_objective_requirement_callbacks()
    )
  end

  defp missed_realized_downlink_ids(mission_state, prior_plan, objective) do
    mission_state
    |> realized_downlink_events(prior_plan)
    |> Enum.filter(&downlink_completion_event_match?(&1, objective || %{}))
    |> Enum.map(& &1["id"])
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp realized_downlink_events(mission_state, prior_plan) do
    RealizedDownlinkEvents.events(
      mission_state,
      prior_plan,
      realized_downlink_event_callbacks()
    )
  end

  defp realized_downlink_event_callbacks,
    do: [
      downlink_activity?: &downlink_activity?/1,
      normalize_realized_status_value: &normalize_realized_status_value/1,
      normalize_realized_activity_status: &normalize_realized_activity_status/2,
      provider_result_success_value: &ProviderResultValues.success_value/1,
      realized_failure_statuses: @realized_failure_statuses,
      realized_completion_statuses: @realized_completion_statuses
    ]

  defp normalize_realized_status_value(status),
    do: RepairRealizedState.normalize_status_value(status)

  defp normalize_realized_activity_status(status, realized_status) do
    RepairRealizedState.activity_status(
      status,
      realized_status,
      realized_activity_status_callbacks()
    )
  end

  defp realized_activity_status_callbacks,
    do: [
      realized_statuses: @realized_statuses,
      feedback_match_statuses: @realized_feedback_match_statuses
    ]

  defp mission_state_resource_margin_sources(mission_state, field) do
    MissionStateResourceSources.margin_sources(
      mission_state,
      field,
      mission_state_resource_source_callbacks()
    )
  end

  defp mission_state_resource_source_path(mission_state, field) do
    MissionStateResourceSources.source_path(mission_state, field)
  end

  defp mission_state_resource_spacecraft_id(mission_state) do
    MissionStateResourceSources.spacecraft_id(
      mission_state,
      mission_state_resource_source_callbacks()
    )
  end

  defp mission_state_resource_source_callbacks,
    do: [
      stringify_keys: &stringify_keys/1,
      normalize_resource_margin_aliases: &normalize_resource_margin_aliases/1,
      normalize_resource_availability_aliases: &normalize_resource_availability_aliases/1,
      numeric_or_nil: &numeric_or_nil/1
    ]

  defp normalize_resource_margin_aliases(value) do
    OperationalFeedbackNormalization.normalize_resource_margin_aliases(
      value,
      resource_normalization_callbacks()
    )
  end

  defp normalize_resource_availability_aliases(value) do
    OperationalFeedbackNormalization.normalize_resource_availability_aliases(
      value,
      resource_normalization_callbacks()
    )
  end

  defp resource_normalization_callbacks,
    do: [
      stringify_keys: &stringify_keys/1,
      numeric_or_nil: &numeric_or_nil/1,
      resource_availability_boolean_value: &resource_availability_boolean_value/1,
      resource_availability_true_tokens: @resource_availability_true_tokens,
      resource_availability_false_tokens: @resource_availability_false_tokens
    ]

  defp resource_availability_boolean_value(value) do
    OperationalFeedbackNormalization.resource_availability_boolean_value(
      value,
      resource_normalization_callbacks()
    )
  end

  defp resource_margin_pressure_events(
         mission_state,
         sources,
         policy,
         field,
         threshold_key,
         reason
       ) do
    ResourceMarginPressureEvents.build(
      mission_state,
      sources,
      policy,
      field,
      threshold_key,
      reason,
      resource_margin_pressure_event_callbacks()
    )
  end

  defp resource_margin_pressure_event_callbacks,
    do: [
      resource_spacecraft_id: &mission_state_resource_spacecraft_id/1,
      compact_map: &compact_map/1
    ]

  defp downlink_completion_event_match?(candidate, event) do
    DownlinkCompletionCandidates.event_match?(
      candidate,
      event,
      downlink_completion_candidate_callbacks()
    )
  end

  defp downlink_completion_candidate_callbacks,
    do: [
      event_ground_station_id: &event_ground_station_id/1,
      activity_ground_station_id: &activity_ground_station_id/1,
      activity_start: &activity_start/1,
      activity_end: &activity_end/1
    ]

  defp downlink_constrained_branch_id_callbacks,
    do: [
      objective_ground_station_id: &objective_ground_station_id/1
    ]

  defp objective_ground_station_id(objective), do: activity_ground_station_id(objective)

  defp objective_window_start(objective, default),
    do: ObjectiveWindowBounds.start(objective, default)

  defp objective_window_end(objective, default),
    do: ObjectiveWindowBounds.finish(objective, default)

  defp planning_horizon_duration_s(prior_plan, default) do
    ActivityTiming.planning_horizon_duration_s(prior_plan, default, activity_timing_callbacks())
  end

  defp event_ground_station_id(event) do
    case encode_value(
           Map.get(event, "ground_station_id") || Map.get(event, "station_id") ||
             DownlinkActivityNormalization.nested_ground_station_id(event)
         ) do
      value when is_binary(value) and value != "" -> value
      _value -> nil
    end
  end

  defp activity_ground_station_id(activity) do
    Map.get(activity, "ground_station_id") || Map.get(activity, "station_id") ||
      DownlinkActivityNormalization.nested_ground_station_id(activity)
  end

  defp downlink_activity?(activity) do
    DownlinkActivityNormalization.downlink?(
      activity,
      downlink_activity_normalization_callbacks()
    )
  end

  defp downlink_activity_normalization_callbacks,
    do: [
      activity_ground_station_id: &activity_ground_station_id/1,
      activity_raw_start: &activity_raw_start/1,
      activity_raw_end: &activity_raw_end/1,
      numeric_or_nil: &numeric_or_nil/1
    ]

  defp activity_start(activity) do
    ActivityTiming.activity_start(activity, activity_timing_callbacks())
  end

  defp activity_end(activity) do
    ActivityTiming.activity_end(activity, activity_timing_callbacks())
  end

  defp activity_raw_start(activity) do
    ActivityTiming.activity_raw_start(activity, activity_timing_callbacks())
  end

  defp activity_raw_end(activity) do
    ActivityTiming.activity_raw_end(activity, activity_timing_callbacks())
  end

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

  defp activity_timing_callbacks,
    do: [
      numeric_or_nil: &numeric_or_nil/1
    ]

  defp derivation_reasons(
         completion_gap?,
         storage_constrained?,
         capacity_constrained?,
         statuses,
         contact_results
       ) do
    []
    |> maybe_append_reason(completion_gap?, "downlink_completion_gap")
    |> maybe_append_reason(storage_constrained?, "storage_margin_low")
    |> maybe_append_reason(capacity_constrained?, "downlink_margin_low")
    |> Enum.reverse()
    |> Kernel.++(Enum.map(statuses, &"realized_downlink_#{&1}"))
    |> Kernel.++(Enum.map(contact_results, &"realized_downlink_contact_result_#{&1}"))
  end

  defp maybe_append_branch_event(events, true, event), do: [event | events]
  defp maybe_append_branch_event(events, false, _event), do: events

  defp maybe_append_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_append_reason(reasons, false, _reason), do: reasons

  defp join_or_nil([]), do: nil
  defp join_or_nil(values), do: Enum.join(values, ",")

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp downlink_objective_requirement_callbacks,
    do: [
      stringify_keys: &stringify_keys/1,
      encode_value: &encode_value/1,
      objective_number_from_fields: &objective_number_from_fields/2,
      prior_plan_activities: &prior_plan_activities/1,
      downlink_activity?: &downlink_activity?/1,
      downlink_completion_event_match?: &downlink_completion_event_match?/2,
      downlink_activity_mb: &downlink_activity_mb/1
    ]

  defp objective_number_from_fields(objective, fields) do
    Enum.find_value(fields, fn field ->
      case numeric_or_nil(Map.get(objective, field)) do
        value when is_number(value) -> value
        _value -> nil
      end
    end)
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

  defp prior_plan_activities(prior_plan), do: PriorActivityContext.activities(prior_plan)

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
end
