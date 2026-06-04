defmodule OrbitalDynamics.Communications.ContactIntent do
  @moduledoc """
  Cadence-facing contact intent rows derived from planned contact activities.

  The intent is an artifact boundary only. It does not schedule contacts,
  reserve provider assets, or execute commands.
  """

  alias OrbitalDynamics.{Policy, Timeline}

  @schema_contract "contact_intent.v1"
  @summary_schema_contract "contact_intent_summary.v1"
  @directions ["downlink", "uplink", "command", "tracking", "health_check"]
  @source_activity_types [
    "downlink",
    "planned_contact",
    "contact",
    "command",
    "tracking",
    "health_check"
  ]
  @default_direction_by_activity_type %{
    "downlink" => "downlink",
    "command" => "command",
    "tracking" => "tracking",
    "health_check" => "health_check"
  }
  @provider_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "up" => "uplink",
    "up_link" => "uplink",
    "dl" => "downlink",
    "down" => "downlink",
    "down_link" => "downlink",
    "downlinking" => "downlink",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check"
  }
  @station_calendar_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "uplink" => "command",
    "up" => "command",
    "up_link" => "command",
    "dl" => "downlink",
    "down" => "downlink",
    "down_link" => "downlink",
    "downlinking" => "downlink",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check"
  }
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @unavailable_aliases ["outage", "down", "offline"]
  @station_availability_severity %{
    "unavailable" => 5,
    "maintenance" => 5,
    "reserved" => 4,
    "reduced_capacity" => 3,
    "available" => 1
  }
  @station_capacity_fraction_paths [
    ["availability"],
    ["capacity_pack_capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_fraction"],
    ["throughput_model", "availability"],
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "availability"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "availability"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"]
  ]
  @station_capacity_percent_paths [
    ["station_capacity_percent"],
    ["capacity_percent"],
    ["throughput_model", "station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["activity_context", "station_capacity_percent"],
    ["activity_context", "capacity_percent"]
  ]
  @station_capacity_value_paths [
    {:fraction, ["availability"]},
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:percent, ["station_capacity_percent"]},
    {:percent, ["capacity_percent"]},
    {:fraction, ["throughput_model", "availability"]},
    {:fraction, ["throughput_model", "station_capacity_fraction"]},
    {:fraction, ["throughput_model", "capacity_fraction"]},
    {:percent, ["throughput_model", "station_capacity_percent"]},
    {:percent, ["throughput_model", "capacity_percent"]},
    {:fraction, ["capacity_model", "availability"]},
    {:fraction, ["capacity_model", "station_capacity_fraction"]},
    {:fraction, ["capacity_model", "capacity_fraction"]},
    {:percent, ["capacity_model", "station_capacity_percent"]},
    {:percent, ["capacity_model", "capacity_percent"]},
    {:fraction, ["activity_context", "availability"]},
    {:fraction, ["activity_context", "station_capacity_fraction"]},
    {:fraction, ["activity_context", "capacity_fraction"]},
    {:percent, ["activity_context", "station_capacity_percent"]},
    {:percent, ["activity_context", "capacity_percent"]}
  ]
  @required_capacity_fraction_paths [
    ["required_capacity_fraction"],
    ["required_station_capacity_fraction"],
    ["station_capacity_requirement"],
    ["throughput_model", "required_capacity_fraction"],
    ["throughput_model", "required_station_capacity_fraction"],
    ["throughput_model", "station_capacity_requirement"],
    ["capacity_model", "required_capacity_fraction"],
    ["capacity_model", "required_station_capacity_fraction"],
    ["capacity_model", "station_capacity_requirement"],
    ["activity_context", "required_capacity_fraction"],
    ["activity_context", "required_station_capacity_fraction"],
    ["activity_context", "station_capacity_requirement"]
  ]
  @required_capacity_percent_paths [
    ["required_capacity_percent"],
    ["required_station_capacity_percent"],
    ["station_capacity_requirement_percent"],
    ["throughput_model", "required_capacity_percent"],
    ["throughput_model", "required_station_capacity_percent"],
    ["throughput_model", "station_capacity_requirement_percent"],
    ["capacity_model", "required_capacity_percent"],
    ["capacity_model", "required_station_capacity_percent"],
    ["capacity_model", "station_capacity_requirement_percent"],
    ["activity_context", "required_capacity_percent"],
    ["activity_context", "required_station_capacity_percent"],
    ["activity_context", "station_capacity_requirement_percent"]
  ]
  @required_capacity_value_paths [
    {:fraction, ["required_capacity_fraction"]},
    {:fraction, ["required_station_capacity_fraction"]},
    {:fraction, ["station_capacity_requirement"]},
    {:percent, ["required_capacity_percent"]},
    {:percent, ["required_station_capacity_percent"]},
    {:percent, ["station_capacity_requirement_percent"]},
    {:fraction, ["throughput_model", "required_capacity_fraction"]},
    {:fraction, ["throughput_model", "required_station_capacity_fraction"]},
    {:fraction, ["throughput_model", "station_capacity_requirement"]},
    {:percent, ["throughput_model", "required_capacity_percent"]},
    {:percent, ["throughput_model", "required_station_capacity_percent"]},
    {:percent, ["throughput_model", "station_capacity_requirement_percent"]},
    {:fraction, ["capacity_model", "required_capacity_fraction"]},
    {:fraction, ["capacity_model", "required_station_capacity_fraction"]},
    {:fraction, ["capacity_model", "station_capacity_requirement"]},
    {:percent, ["capacity_model", "required_capacity_percent"]},
    {:percent, ["capacity_model", "required_station_capacity_percent"]},
    {:percent, ["capacity_model", "station_capacity_requirement_percent"]},
    {:fraction, ["activity_context", "required_capacity_fraction"]},
    {:fraction, ["activity_context", "required_station_capacity_fraction"]},
    {:fraction, ["activity_context", "station_capacity_requirement"]},
    {:percent, ["activity_context", "required_capacity_percent"]},
    {:percent, ["activity_context", "required_station_capacity_percent"]},
    {:percent, ["activity_context", "station_capacity_requirement_percent"]}
  ]
  @required_capacity_fraction_source_values ~w(
    contact_required_capacity_fraction
    throughput_model
    capacity_model
    activity_context
  )
  @station_calendar_id_list_fields [
    "station_calendar_overlap_entry_ids",
    "station_calendar_ambiguous_entry_ids",
    "station_calendar_reservation_ids"
  ]
  @station_reservation_expiration_fields [
    "station_reservation_expires_at_s",
    "reservation_expires_at_s",
    "reservation_hold_expires_at_s",
    "hold_expires_at_s",
    "expires_at_s",
    "expires_at"
  ]
  @station_calendar_reservation_expiration_fields [
    "station_calendar_reservation_expires_at_s"
    | @station_reservation_expiration_fields
  ]
  @activity_stable_identity_fields ~w(
    id
    scenario_id
    spacecraft_id
    ground_station_id
    source_window_id
    station_calendar_entry_id
    station_reservation_id
  )
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)

  @doc """
  Declares the contact-intent artifact model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      summary_artifact_contract: @summary_schema_contract,
      model: :artifact_only_contact_intent,
      validation_level: :artifact_contract,
      directions: @directions,
      source_activity_types: @source_activity_types,
      default_direction_by_activity_type: @default_direction_by_activity_type,
      provider_direction_aliases: @provider_direction_aliases,
      station_calendar_direction_aliases: @station_calendar_direction_aliases,
      provider_result_map_value_keys: @provider_result_map_value_keys,
      station_unavailable_aliases: @unavailable_aliases,
      station_availability_precedence: @station_availability_severity,
      station_capacity_fraction_paths: @station_capacity_fraction_paths,
      station_capacity_percent_paths: @station_capacity_percent_paths,
      station_capacity_value_paths: capacity_value_path_metadata(@station_capacity_value_paths),
      required_capacity_fraction_paths: @required_capacity_fraction_paths,
      required_capacity_percent_paths: @required_capacity_percent_paths,
      required_capacity_value_paths: capacity_value_path_metadata(@required_capacity_value_paths),
      required_capacity_fraction_source_values: @required_capacity_fraction_source_values,
      source_station_capacity_fraction_paths: @station_capacity_fraction_paths,
      source_station_capacity_percent_paths: @station_capacity_percent_paths,
      source_station_capacity_value_paths:
        capacity_value_path_metadata(@station_capacity_value_paths),
      activity_stable_identity_fields: @activity_stable_identity_fields,
      station_calendar_id_list_fields: @station_calendar_id_list_fields,
      station_reservation_expiration_fields: @station_reservation_expiration_fields,
      station_calendar_reservation_expiration_fields:
        @station_calendar_reservation_expiration_fields,
      policy_gate_statuses: ["auto_approvable", "operator_review_required", "blocked_by_policy"],
      row_semantics: [
        :artifact_only_contact_request,
        :timeline_identity,
        :activity_stable_identity_fields,
        :station_calendar_id_list_fields,
        :station_reservation_context,
        :station_reservation_match_status,
        :station_availability_precedence,
        :station_calendar_overlap_count,
        :station_calendar_ambiguous_entry_count,
        :station_calendar_reservation_overlap_count,
        :station_calendar_counts_derive_from_id_sets,
        :station_calendar_overlap_id_sets,
        :station_calendar_reservation_id_sets,
        :station_calendar_reservation_statuses,
        :station_calendar_reservation_expiration_context,
        :station_reservation_expiration_aliases,
        :station_calendar_reservation_expiration_aliases,
        :station_calendar_trust_evidence_preservation,
        :station_calendar_entry_identity_preservation,
        :station_calendar_availability_status_normalization,
        :station_calendar_capacity_fraction_context,
        :station_calendar_capacity_percent_aliases,
        :station_capacity_value_paths,
        :required_capacity_value_paths,
        :source_station_capacity_value_paths,
        :capacity_pack_required_capacity_summary,
        :station_calendar_direction_context,
        :station_calendar_direction_aliases,
        :provider_direction_aliases,
        :provider_result_map_value_keys,
        :spacecraft_identity_context,
        :invalid_activity_input_review,
        :feedback_unit_interval_input_validation,
        :optional_policy_decision_v1
      ],
      approval_policy_boundary: :optional_policy_decision_v1,
      known_limits: [
        :no_link_budget_model,
        :no_provider_reservation,
        :no_schedule_mutation,
        :no_command_execution,
        :station_availability_is_declared_or_not_evaluated
      ]
    }
  end

  defp capacity_value_path_metadata(paths) do
    Enum.map(paths, fn {unit, path} -> %{unit: unit, path: path} end)
  end

  @doc """
  Converts downlink/contact-like activity maps into `contact_intent.v1` rows.
  """
  def from_activities(activities, opts \\ []) when is_list(activities) do
    approval_policy = Keyword.get(opts, :approval_policy)
    normalized_activities = Enum.map(activities, &normalize_activity/1)

    normalized_timeline_rows =
      Timeline.normalize_activities(normalized_activities,
        validate_missing_dependencies?: Keyword.get(opts, :validate_missing_dependencies?, false)
      )

    intents =
      normalized_activities
      |> Enum.zip(normalized_timeline_rows)
      |> Enum.filter(fn {activity, timeline_row} ->
        contact_activity?(activity) or invalid_contact_activity?(activity, timeline_row)
      end)
      |> Enum.map(fn {activity, timeline_row} -> from_activity!(activity, timeline_row) end)
      |> Enum.sort_by(&{&1["scenario_id"], &1["starts_at_s"], &1["id"]})

    if is_nil(approval_policy) do
      intents
    else
      with_policy_decisions(intents, approval_policy)
    end
  end

  @doc """
  Builds a compact artifact-only contact-intent capacity-demand summary.

  The summary derives required-capacity totals, source counts, and station maps
  from the supplied intent rows instead of trusting caller-provided aggregates.
  """
  def summary(contact_intents)

  def summary(contact_intents) when is_list(contact_intents) do
    contact_intents
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
    |> contact_intent_summary()
  end

  def summary(_contact_intents), do: raise(ArgumentError, "contact intents must be a list")

  def summary(activities, opts) when is_list(activities) do
    activities
    |> from_activities(opts)
    |> summary()
  end

  def summary(_activities, _opts), do: raise(ArgumentError, "activities must be a list")

  defp contact_intent_summary(rows) do
    rows = Enum.map(rows, &Map.merge(required_capacity_context(&1), &1))
    capacity_demand_rows = Enum.filter(rows, &is_number(&1["required_capacity_fraction"]))

    %{
      "schema_contract" => @summary_schema_contract,
      "model" => "artifact_only_contact_intent_summary",
      "model_limits" => model_limits(),
      "source_artifact_type" => @schema_contract,
      "contact_intent_count" => length(rows),
      "capacity_pack_required_contact_count" => length(capacity_demand_rows),
      "capacity_pack_required_capacity_fraction" =>
        required_capacity_fraction_total(capacity_demand_rows),
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        required_capacity_fraction_by_field(capacity_demand_rows, "ground_station_id"),
      "capacity_pack_required_capacity_fraction_by_direction" =>
        required_capacity_fraction_by_direction(capacity_demand_rows),
      "required_capacity_fraction_source_counts" =>
        count_by(capacity_demand_rows, "required_capacity_fraction_source"),
      "required_capacity_fraction_contact_ids_by_source" =>
        row_ids_by_field(capacity_demand_rows, "required_capacity_fraction_source", "id"),
      "contact_ids_by_ground_station_id" => row_ids_by_field(rows, "ground_station_id", "id"),
      "contact_ids_by_direction" => row_ids_by_direction(rows, "id"),
      "capacity_pack_contact_ids_by_ground_station_id" =>
        row_ids_by_field(capacity_demand_rows, "ground_station_id", "id"),
      "capacity_pack_contact_ids_by_direction" =>
        row_ids_by_direction(capacity_demand_rows, "id"),
      "ground_station_ids" => row_values(rows, "ground_station_id"),
      "directions" => row_values(rows, "direction"),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source_artifact_type" => @schema_contract
      }
    }
  end

  defp required_capacity_fraction_total(rows) do
    rows
    |> Enum.map(& &1["required_capacity_fraction"])
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp required_capacity_fraction_by_field(rows, field) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      key = row[field]
      required_fraction = row["required_capacity_fraction"]

      if is_binary(key) and is_number(required_fraction) do
        Map.update(totals, key, required_fraction, &(&1 + required_fraction))
      else
        totals
      end
    end)
    |> empty_map_to_nil()
  end

  defp required_capacity_fraction_by_direction(rows) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      direction = normalize_contact_direction(row["direction"])
      required_fraction = row["required_capacity_fraction"]

      if is_binary(direction) and is_number(required_fraction) do
        Map.update(totals, direction, required_fraction, &(&1 + required_fraction))
      else
        totals
      end
    end)
    |> empty_map_to_nil()
  end

  defp row_ids_by_field(rows, field, id_field) do
    rows
    |> Enum.reduce(%{}, fn row, groups ->
      key = row[field]
      id = row[id_field]

      if is_binary(key) and is_binary(id) do
        Map.update(groups, key, [id], &[id | &1])
      else
        groups
      end
    end)
    |> Map.new(fn {key, values} -> {key, Enum.sort(values)} end)
    |> empty_map_to_nil()
  end

  defp row_ids_by_direction(rows, id_field) do
    rows
    |> Enum.reduce(%{}, fn row, groups ->
      direction = normalize_contact_direction(row["direction"])
      id = row[id_field]

      if is_binary(direction) and is_binary(id) do
        Map.update(groups, direction, [id], &[id | &1])
      else
        groups
      end
    end)
    |> Map.new(fn {key, values} -> {key, Enum.sort(values)} end)
    |> empty_map_to_nil()
  end

  defp count_by(rows, field) do
    rows
    |> Enum.reduce(%{}, fn row, counts ->
      case row[field] do
        value when is_binary(value) -> Map.update(counts, value, 1, &(&1 + 1))
        _value -> counts
      end
    end)
    |> empty_map_to_nil()
  end

  defp row_values(rows, field) do
    rows
    |> Enum.map(& &1[field])
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp empty_map_to_nil(values) when values == %{}, do: nil
  defp empty_map_to_nil(values), do: values

  @doc """
  Adds artifact-only policy decisions to contact intents.

  This classifies operator review boundaries; it does not reserve station time,
  mutate schedules, or execute commands.
  """
  def with_policy_decisions(intents, approval_policy) when is_list(intents) do
    intents
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&with_policy_decision(&1, approval_policy))
  end

  def from_activity!(activity) when is_map(activity) do
    activity = normalize_activity(activity)
    [timeline_row] = Timeline.normalize_activities([activity])

    from_activity!(activity, timeline_row)
  end

  def from_activity!(_activity), do: raise(ArgumentError, "contact activity must be a map")

  defp from_activity!(activity, timeline_row) do
    direction = Map.get(activity, "direction") || default_direction(activity)
    id = contact_intent_id(activity, timeline_row)
    starts_at_s = interval_start!(activity)
    ends_at_s = interval_end!(activity)
    timeline_identity = Map.get(timeline_row, "timeline_identity")
    scenario_id = contact_intent_scenario_id(activity, timeline_row, id)
    ground_station_id = contact_intent_ground_station_id(activity, timeline_row, id)

    station_calendar_directions =
      contact_intent_station_calendar_directions(activity, timeline_row)

    station_availability = station_availability(activity)
    capacity_context = station_capacity_context(activity)
    required_capacity_context = required_capacity_context(activity)
    reservation_expiration_context = station_reservation_expiration_context(activity)

    unless direction in @directions do
      raise ArgumentError, "contact direction must be one of #{inspect(@directions)}"
    end

    %{
      "schema_contract" => "contact_intent.v1",
      "id" => id,
      "activity_id" => id,
      "activity_type" => Map.get(activity, "type"),
      "scenario_id" => scenario_id,
      "spacecraft_id" => contact_intent_spacecraft_id(activity, timeline_row),
      "timeline_id" => Map.get(timeline_identity, "timeline_id"),
      "timeline_identity" => timeline_identity,
      "ground_station_id" => ground_station_id,
      "direction" => direction,
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "estimated_throughput_mb" => Map.get(activity, "estimated_throughput_mb"),
      "station_availability" => station_availability,
      "capacity_fraction" => capacity_context["capacity_fraction"],
      "capacity_fraction_min" => capacity_context["capacity_fraction_min"],
      "capacity_fraction_max" => capacity_context["capacity_fraction_max"],
      "required_capacity_fraction" => required_capacity_context["required_capacity_fraction"],
      "required_capacity_fraction_source" =>
        required_capacity_context["required_capacity_fraction_source"],
      "station_contention_status" => Map.get(activity, "station_contention_status"),
      "station_calendar_entry_id" =>
        contact_intent_station_calendar_entry_id(activity, timeline_row),
      "station_calendar_directions" => station_calendar_directions,
      "station_calendar_provider_id" =>
        contact_intent_station_calendar_provider_id(activity, timeline_row),
      "station_calendar_provider_entry_id" =>
        contact_intent_station_calendar_provider_entry_id(activity, timeline_row),
      "station_calendar_status" => Map.get(activity, "station_calendar_status"),
      "station_calendar_overlap_count" => Map.get(activity, "station_calendar_overlap_count"),
      "station_calendar_overlap_entry_ids" =>
        Map.get(activity, "station_calendar_overlap_entry_ids"),
      "station_calendar_overlap_availabilities" =>
        Map.get(activity, "station_calendar_overlap_availabilities"),
      "station_calendar_entry_ambiguous" => Map.get(activity, "station_calendar_entry_ambiguous"),
      "station_calendar_ambiguous_entry_count" =>
        Map.get(activity, "station_calendar_ambiguous_entry_count"),
      "station_calendar_ambiguous_entry_ids" =>
        Map.get(activity, "station_calendar_ambiguous_entry_ids"),
      "station_calendar_reservation_overlap_count" =>
        Map.get(activity, "station_calendar_reservation_overlap_count"),
      "station_calendar_reservation_ids" => Map.get(activity, "station_calendar_reservation_ids"),
      "station_calendar_reserved_by" => Map.get(activity, "station_calendar_reserved_by"),
      "station_calendar_reservation_statuses" =>
        Map.get(activity, "station_calendar_reservation_statuses"),
      "station_calendar_reservation_expires_at_s" =>
        reservation_expiration_context["station_calendar_reservation_expires_at_s"],
      "station_calendar_trust_boundary_status" =>
        Map.get(activity, "station_calendar_trust_boundary_status"),
      "trust_boundary" => Map.get(activity, "trust_boundary"),
      "provenance" => Map.get(activity, "provenance"),
      "source_station_calendar_entry" => Map.get(activity, "source_station_calendar_entry"),
      "source_station_calendar_overlaps" => Map.get(activity, "source_station_calendar_overlaps"),
      "station_reservation_id" => stable_id_or_nil(Map.get(activity, "station_reservation_id")),
      "station_reservation_expires_at_s" =>
        reservation_expiration_context["station_reservation_expires_at_s"],
      "station_reserved_by" => Map.get(activity, "station_reserved_by"),
      "station_reservation_status" => Map.get(activity, "station_reservation_status"),
      "station_reservation_match_status" => Map.get(activity, "station_reservation_match_status"),
      "schedule_conflict_status" =>
        Map.get(activity, "schedule_conflict_status", "not_evaluated"),
      "contact_success" => activity_boolean(activity, "contact_success"),
      "contact_result" =>
        provider_result_artifact_value(activity_value(activity, "contact_result")),
      "contact_success_factor" => unit_interval_factor(activity, "contact_success_factor"),
      "contact_success_factor_source" =>
        activity_value(activity, "contact_success_factor_source"),
      "command_success" => activity_boolean(activity, "command_success"),
      "command_result" =>
        provider_result_artifact_value(activity_value(activity, "command_result")),
      "command_success_factor" => unit_interval_factor(activity, "command_success_factor"),
      "command_success_factor_source" =>
        activity_value(activity, "command_success_factor_source"),
      "dependency_activity_ids" => Map.get(timeline_row, "dependency_activity_ids"),
      "dependency_timeline_ids" => Map.get(timeline_row, "dependency_timeline_ids"),
      "exclusive_with_activity_ids" => Map.get(timeline_row, "exclusive_with_activity_ids"),
      "exclusive_with_timeline_ids" => Map.get(timeline_row, "exclusive_with_timeline_ids"),
      "timeline_integrity_status" => Map.get(timeline_row, "timeline_integrity_status"),
      "timeline_integrity_issue_count" => Map.get(timeline_row, "timeline_integrity_issue_count"),
      "timeline_integrity_issue_types" => Map.get(timeline_row, "timeline_integrity_issue_types"),
      "timeline_integrity_issues" => Map.get(timeline_row, "timeline_integrity_issues"),
      "missing_dependency_activity_ids" =>
        Map.get(timeline_row, "missing_dependency_activity_ids"),
      "missing_dependency_timeline_ids" =>
        Map.get(timeline_row, "missing_dependency_timeline_ids"),
      "dependency_order_violation_activity_ids" =>
        Map.get(timeline_row, "dependency_order_violation_activity_ids"),
      "dependency_order_violation_timeline_ids" =>
        Map.get(timeline_row, "dependency_order_violation_timeline_ids"),
      "exclusivity_violation_activity_ids" =>
        Map.get(timeline_row, "exclusivity_violation_activity_ids"),
      "exclusivity_violation_timeline_ids" =>
        Map.get(timeline_row, "exclusivity_violation_timeline_ids"),
      "exclusivity_violation_group" => Map.get(timeline_row, "exclusivity_violation_group"),
      "source_window_id" =>
        stable_id_or_nil(Map.get(activity, "source_window_id")) ||
          stable_id_or_nil(get_in(activity, ["source_window", "id"])),
      "activity_context" =>
        contact_intent_activity_context(
          timeline_row,
          activity,
          station_calendar_directions,
          station_availability,
          capacity_context,
          required_capacity_context,
          reservation_expiration_context
        ),
      "model_limits" => model_limits(),
      "cadence_import" => cadence_import(activity, id, direction)
    }
    |> normalize_station_calendar_id_lists()
    |> derive_station_calendar_counts()
    |> Map.merge(invalid_activity_input_context(timeline_row, id, direction))
    |> Map.merge(invalid_feedback_factor_context(activity, timeline_row, id, direction))
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp with_policy_decision(%{"invalid_activity_input" => true} = intent, approval_policy) do
    requirements =
      intent
      |> Map.get("approval_requirements", [])
      |> List.wrap()
      |> Enum.map(&stringify_keys/1)

    classify_intent_requirements(intent, requirements, approval_policy)
  end

  defp with_policy_decision(intent, approval_policy) do
    classify_intent_requirements(intent, [approval_requirement(intent)], approval_policy)
  end

  defp classify_intent_requirements(intent, requirements, approval_policy) do
    {status, requirements, rule_matches, decision} =
      Policy.decide(requirements, [], %{"events" => []}, %{}, approval_policy)

    intent
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", rule_matches)
    |> Map.put("policy_decision", decision)
  end

  defp contact_intent_station_calendar_entry_id(activity, timeline_row) do
    stable_id_or_nil(Map.get(activity, "station_calendar_entry_id")) ||
      stable_id_or_nil(get_in(timeline_row, ["activity_context", "station_calendar_entry_id"])) ||
      stable_id_or_nil(
        get_in(activity, ["source_station_calendar_entry", "station_calendar_entry_id"])
      ) ||
      stable_id_or_nil(get_in(activity, ["source_station_calendar_entry", "id"]))
  end

  defp contact_intent_station_calendar_directions(activity, timeline_row) do
    [
      Map.get(activity, "station_calendar_directions"),
      get_in(timeline_row, ["activity_context", "station_calendar_directions"]),
      get_in(activity, ["source_station_calendar_entry", "station_calendar_directions"]),
      get_in(activity, ["source_station_calendar_entry", "directions"]),
      get_in(activity, ["source_station_calendar_entry", "direction"])
    ]
    |> List.flatten()
    |> Enum.map(&normalize_station_calendar_direction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      directions -> directions
    end
  end

  defp normalize_station_calendar_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_station_calendar_direction(direction) do
    direction
    |> stringify_keys()
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      alias when is_map_key(@station_calendar_direction_aliases, alias) ->
        Map.fetch!(@station_calendar_direction_aliases, alias)

      value when value in @directions ->
        value

      _unknown ->
        nil
    end
  end

  defp contact_intent_station_calendar_provider_id(activity, timeline_row) do
    stable_id_or_nil(Map.get(activity, "station_calendar_provider_id")) ||
      stable_id_or_nil(get_in(timeline_row, ["activity_context", "station_calendar_provider_id"])) ||
      stable_id_or_nil(get_in(activity, ["source_station_calendar_entry", "provider_id"])) ||
      stable_id_or_nil(
        get_in(activity, ["source_station_calendar_entry", "provenance", "provider_id"])
      ) ||
      stable_id_or_nil(get_in(activity, ["provenance", "provider_id"]))
  end

  defp contact_intent_station_calendar_provider_entry_id(activity, timeline_row) do
    stable_id_or_nil(Map.get(activity, "station_calendar_provider_entry_id")) ||
      stable_id_or_nil(
        get_in(timeline_row, ["activity_context", "station_calendar_provider_entry_id"])
      ) ||
      stable_id_or_nil(get_in(activity, ["source_station_calendar_entry", "provider_entry_id"])) ||
      stable_id_or_nil(get_in(activity, ["source_station_calendar_entry", "id"]))
  end

  defp approval_requirement(intent) do
    activity_type = intent["activity_type"] || contact_activity_type(intent["direction"])

    %{
      "schema_contract" => "approval_requirement.v1",
      "id" => "approval:#{intent["id"]}",
      "activity_id" => intent["activity_id"],
      "activity_type" => activity_type,
      "action" => approval_action(intent["direction"]),
      "requirement_type" => approval_requirement_type(intent["direction"]),
      "reason" => approval_reason(intent["direction"]),
      "activity_context" =>
        %{
          "direction" => intent["direction"],
          "spacecraft_id" => intent["spacecraft_id"],
          "ground_station_id" => intent["ground_station_id"],
          "station_availability" => intent["station_availability"],
          "capacity_fraction" => intent["capacity_fraction"],
          "capacity_fraction_min" => intent["capacity_fraction_min"],
          "capacity_fraction_max" => intent["capacity_fraction_max"],
          "required_capacity_fraction" => intent["required_capacity_fraction"],
          "required_capacity_fraction_source" => intent["required_capacity_fraction_source"],
          "station_contention_status" => intent["station_contention_status"],
          "station_calendar_entry_id" => intent["station_calendar_entry_id"],
          "station_calendar_directions" => intent["station_calendar_directions"],
          "station_calendar_provider_id" => intent["station_calendar_provider_id"],
          "station_calendar_provider_entry_id" => intent["station_calendar_provider_entry_id"],
          "station_calendar_status" => intent["station_calendar_status"],
          "station_calendar_overlap_count" => intent["station_calendar_overlap_count"],
          "station_calendar_overlap_entry_ids" => intent["station_calendar_overlap_entry_ids"],
          "station_calendar_overlap_availabilities" =>
            intent["station_calendar_overlap_availabilities"],
          "station_calendar_entry_ambiguous" => intent["station_calendar_entry_ambiguous"],
          "station_calendar_ambiguous_entry_count" =>
            intent["station_calendar_ambiguous_entry_count"],
          "station_calendar_ambiguous_entry_ids" =>
            intent["station_calendar_ambiguous_entry_ids"],
          "station_calendar_reservation_overlap_count" =>
            intent["station_calendar_reservation_overlap_count"],
          "station_calendar_reservation_ids" => intent["station_calendar_reservation_ids"],
          "station_calendar_reserved_by" => intent["station_calendar_reserved_by"],
          "station_calendar_reservation_statuses" =>
            intent["station_calendar_reservation_statuses"],
          "station_calendar_reservation_expires_at_s" =>
            intent["station_calendar_reservation_expires_at_s"],
          "station_calendar_trust_boundary_status" =>
            intent["station_calendar_trust_boundary_status"],
          "trust_boundary" => intent["trust_boundary"],
          "provenance" => intent["provenance"],
          "source_station_calendar_entry" => intent["source_station_calendar_entry"],
          "source_station_calendar_overlaps" => intent["source_station_calendar_overlaps"],
          "station_reservation_id" => intent["station_reservation_id"],
          "station_reservation_expires_at_s" => intent["station_reservation_expires_at_s"],
          "station_reserved_by" => intent["station_reserved_by"],
          "station_reservation_status" => intent["station_reservation_status"],
          "station_reservation_match_status" => intent["station_reservation_match_status"],
          "contact_success" => intent["contact_success"],
          "contact_result" => provider_result_artifact_value(intent["contact_result"]),
          "contact_success_factor" => intent["contact_success_factor"],
          "contact_success_factor_source" => intent["contact_success_factor_source"],
          "command_success" => intent["command_success"],
          "command_result" => provider_result_artifact_value(intent["command_result"]),
          "command_success_factor" => intent["command_success_factor"],
          "command_success_factor_source" => intent["command_success_factor_source"],
          "dependency_activity_ids" => intent["dependency_activity_ids"],
          "dependency_timeline_ids" => intent["dependency_timeline_ids"],
          "exclusive_with_activity_ids" => intent["exclusive_with_activity_ids"],
          "exclusive_with_timeline_ids" => intent["exclusive_with_timeline_ids"],
          "timeline_integrity_status" => intent["timeline_integrity_status"],
          "timeline_integrity_issue_count" => intent["timeline_integrity_issue_count"],
          "timeline_integrity_issue_types" => intent["timeline_integrity_issue_types"],
          "missing_dependency_activity_ids" => intent["missing_dependency_activity_ids"],
          "missing_dependency_timeline_ids" => intent["missing_dependency_timeline_ids"],
          "dependency_order_violation_activity_ids" =>
            intent["dependency_order_violation_activity_ids"],
          "dependency_order_violation_timeline_ids" =>
            intent["dependency_order_violation_timeline_ids"],
          "exclusivity_violation_activity_ids" => intent["exclusivity_violation_activity_ids"],
          "exclusivity_violation_timeline_ids" => intent["exclusivity_violation_timeline_ids"],
          "exclusivity_violation_group" => intent["exclusivity_violation_group"],
          "timeline_identity" => intent["timeline_identity"]
        }
        |> compact_map()
    }
  end

  defp contact_activity_type("command"), do: "command"
  defp contact_activity_type("tracking"), do: "tracking"
  defp contact_activity_type("health_check"), do: "health_check"
  defp contact_activity_type(_direction), do: "planned_contact"

  defp approval_action("command"), do: "review_command_contact"
  defp approval_action("uplink"), do: "review_command_contact"
  defp approval_action(_direction), do: "review_contact_intent"

  defp approval_requirement_type("command"), do: "command_review"
  defp approval_requirement_type("uplink"), do: "command_review"
  defp approval_requirement_type("health_check"), do: "health_check_review"
  defp approval_requirement_type(_direction), do: "contact_schedule_change"

  defp approval_reason("command"), do: "command contact intents require policy classification"

  defp approval_reason("uplink"),
    do: "uplink contact intents require command policy classification"

  defp approval_reason("health_check"),
    do: "health-check contact intents require command policy classification"

  defp approval_reason(_direction), do: "contact schedule intents require policy classification"

  defp contact_activity?(%{"type" => type} = activity)
       when type in [
              "downlink",
              "planned_contact",
              "contact",
              "command",
              "tracking",
              "health_check"
            ] do
    contact_shape?(activity)
  end

  defp contact_activity?(_activity), do: false

  defp invalid_contact_activity?(activity, %{"invalid_activity_input" => true} = timeline_row) do
    source = Map.get(timeline_row, "source_activity", activity)

    contact_activity_intent?(source) and contact_shape?(source)
  end

  defp invalid_contact_activity?(_activity, _timeline_row), do: false

  defp contact_activity_intent?(%{"type" => type}) when type in @source_activity_types,
    do: true

  defp contact_activity_intent?(%{"direction" => direction}) when direction in @directions,
    do: true

  defp contact_activity_intent?(_activity), do: false

  defp contact_shape?(activity) do
    present?(Map.get(activity, "ground_station_id")) and
      number?(Map.get(activity, "starts_at_s") || Map.get(activity, "start_s")) and
      number?(Map.get(activity, "ends_at_s") || Map.get(activity, "end_s"))
  end

  defp normalize_activity(activity) do
    activity
    |> stringify_keys()
    |> normalize_station_id()
    |> normalize_activity_time("starts_at_s", "start_s")
    |> normalize_activity_time("ends_at_s", "end_s")
    |> normalize_number_field("estimated_throughput_mb")
    |> normalize_integer_field("station_calendar_overlap_count")
    |> normalize_integer_field("station_calendar_ambiguous_entry_count")
    |> normalize_integer_field("station_calendar_reservation_overlap_count")
    |> normalize_station_calendar_status_fields()
    |> normalize_direction_field("direction")
    |> normalize_number_field("contact_success_factor")
    |> normalize_number_field("command_success_factor")
    |> normalize_activity_type_alias()
    |> normalize_provider_downlink_activity()
    |> normalize_direction_contact_activity()
  end

  defp normalize_activity_time(activity, _canonical_key, _alternate_key)
       when not is_map(activity),
       do: activity

  defp normalize_activity_time(activity, canonical_key, alternate_key) do
    canonical_value = numeric_value(Map.get(activity, canonical_key))
    alternate_value = numeric_value(Map.get(activity, alternate_key))

    cond do
      is_number(canonical_value) -> Map.put(activity, canonical_key, canonical_value)
      is_number(alternate_value) -> Map.put(activity, canonical_key, alternate_value)
      true -> activity
    end
  end

  defp normalize_number_field(activity, _field) when not is_map(activity), do: activity

  defp normalize_number_field(%{} = activity, field) do
    case numeric_value(Map.get(activity, field)) do
      nil -> activity
      number -> Map.put(activity, field, number)
    end
  end

  defp normalize_integer_field(activity, _field) when not is_map(activity), do: activity

  defp normalize_integer_field(%{} = activity, field) do
    case integer_value(Map.get(activity, field)) do
      nil -> activity
      integer -> Map.put(activity, field, integer)
    end
  end

  defp normalize_station_id(%{"ground_station_id" => station_id} = activity)
       when not is_nil(station_id),
       do: activity

  defp normalize_station_id(%{"station_id" => station_id} = activity) when not is_nil(station_id),
    do: Map.put(activity, "ground_station_id", station_id)

  defp normalize_station_id(activity) when not is_map(activity), do: activity

  defp normalize_station_id(activity) do
    case nested_station_id(activity) do
      nil -> activity
      station_id -> Map.put(activity, "ground_station_id", station_id)
    end
  end

  defp nested_station_id(activity) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(activity, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp normalize_activity_type_alias(%{"type" => type} = activity) when not is_nil(type),
    do: activity

  defp normalize_activity_type_alias(%{"activity_type" => type} = activity)
       when is_binary(type) and type != "",
       do: Map.put(activity, "type", type)

  defp normalize_activity_type_alias(activity), do: activity

  defp normalize_provider_downlink_activity(activity) when not is_map(activity), do: activity

  defp normalize_provider_downlink_activity(activity) do
    if provider_downlink_activity_input?(activity) do
      activity
      |> Map.put_new("type", "downlink")
      |> Map.put_new("direction", "downlink")
    else
      activity
    end
  end

  defp normalize_direction_contact_activity(activity) when not is_map(activity), do: activity

  defp normalize_direction_contact_activity(activity) do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")
    direction = Map.get(activity, "direction")

    if direction_contact_activity_input?(type, direction, activity) do
      Map.put_new(activity, "type", "planned_contact")
    else
      activity
    end
  end

  defp direction_contact_activity_input?(type, direction, activity) do
    type in [nil, "contact", "planned_contact"] and
      direction in @directions and
      contact_shape?(activity)
  end

  defp provider_downlink_activity_input?(activity) do
    Map.get(activity, "type") in [nil, "contact", "planned_contact"] and
      Map.get(activity, "direction") in [nil, "downlink"] and
      contact_shape?(activity)
  end

  defp station_availability(activity) do
    activity
    |> station_availability_candidates()
    |> Enum.filter(&station_availability_value?/1)
    |> case do
      [] -> "not_evaluated"
      values -> Enum.max_by(values, &station_availability_severity/1)
    end
    |> canonical_station_availability()
  end

  defp station_availability_candidates(activity) do
    [
      activity["station_availability"],
      activity["availability"],
      activity["station_calendar_status"],
      activity["status"]
    ] ++
      source_station_calendar_availability_candidates(activity["source_station_calendar_entry"]) ++
      source_station_calendar_availability_candidates(
        activity["source_station_calendar_overlaps"]
      )
  end

  defp source_station_calendar_availability_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_availability_candidates/1)

  defp source_station_calendar_availability_candidates(%{} = source) do
    [
      source["station_availability"],
      source["availability"],
      source["station_calendar_status"],
      source["status"]
    ]
  end

  defp source_station_calendar_availability_candidates(_source), do: []

  defp station_capacity_context(activity) do
    case station_capacity_fractions(activity) do
      [] ->
        %{}

      fractions ->
        %{
          "capacity_fraction" => Enum.min(fractions),
          "capacity_fraction_min" => Enum.min(fractions),
          "capacity_fraction_max" => Enum.max(fractions)
        }
    end
  end

  defp station_capacity_fractions(activity) do
    activity
    |> station_capacity_fraction_candidates()
    |> Enum.map(&unit_interval_number/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp station_capacity_fraction_candidates(activity) do
    capacity_value_candidates(activity, @station_capacity_value_paths) ++
      source_station_capacity_fraction_candidates(activity["source_station_calendar_entry"]) ++
      source_station_capacity_fraction_candidates(activity["source_station_calendar_overlaps"])
  end

  defp required_capacity_context(activity) do
    case required_capacity_fraction(activity) do
      nil ->
        %{}

      required_capacity_fraction ->
        compact_map(%{
          "required_capacity_fraction" => required_capacity_fraction,
          "required_capacity_fraction_source" => required_capacity_fraction_source(activity)
        })
    end
  end

  defp required_capacity_fraction(activity) do
    activity
    |> capacity_value_candidates(@required_capacity_value_paths)
    |> Enum.find_value(&unit_interval_number/1)
  end

  defp required_capacity_fraction_source(activity) do
    cond do
      valid_capacity_value_declared?(activity["required_capacity_fraction"]) or
        valid_capacity_value_declared?(activity["required_station_capacity_fraction"]) or
        valid_capacity_value_declared?(activity["station_capacity_requirement"]) or
        valid_capacity_percent_declared?(activity["required_capacity_percent"]) or
        valid_capacity_percent_declared?(activity["required_station_capacity_percent"]) or
          valid_capacity_percent_declared?(activity["station_capacity_requirement_percent"]) ->
        "contact_required_capacity_fraction"

      nested_required_capacity_declared?(activity, "throughput_model") ->
        "throughput_model"

      nested_required_capacity_declared?(activity, "capacity_model") ->
        "capacity_model"

      nested_required_capacity_declared?(activity, "activity_context") ->
        "activity_context"

      true ->
        nil
    end
  end

  defp nested_required_capacity_declared?(activity, key) do
    valid_capacity_value_declared?(get_in(activity, [key, "required_capacity_fraction"])) or
      valid_capacity_value_declared?(
        get_in(activity, [key, "required_station_capacity_fraction"])
      ) or
      valid_capacity_value_declared?(get_in(activity, [key, "station_capacity_requirement"])) or
      valid_capacity_percent_declared?(get_in(activity, [key, "required_capacity_percent"])) or
      valid_capacity_percent_declared?(
        get_in(activity, [key, "required_station_capacity_percent"])
      ) or
      valid_capacity_percent_declared?(
        get_in(activity, [key, "station_capacity_requirement_percent"])
      )
  end

  defp valid_capacity_value_declared?(value), do: is_number(unit_interval_number(value))

  defp valid_capacity_percent_declared?(value), do: is_number(capacity_percent_fraction(value))

  defp source_station_capacity_fraction_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_capacity_fraction_candidates/1)

  defp source_station_capacity_fraction_candidates(%{} = source) do
    capacity_value_candidates(source, @station_capacity_value_paths)
  end

  defp source_station_capacity_fraction_candidates(_source), do: []

  defp capacity_value_candidates(value, paths) do
    Enum.map(paths, fn
      {:fraction, path} ->
        path_value(value, path)

      {:percent, path} ->
        capacity_percent_fraction(path_value(value, path))
    end)
  end

  defp path_value(value, [field]), do: Map.get(value, field)
  defp path_value(value, path), do: get_in(value, path)

  defp capacity_percent_fraction(value) do
    case numeric_value(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end

  defp unit_interval_number(value) do
    case numeric_value(value) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
    end
  end

  defp station_reservation_expiration_context(activity) do
    [
      {"station_reservation_expires_at_s", station_reservation_expires_at_s(activity)},
      {
        "station_calendar_reservation_expires_at_s",
        station_calendar_reservation_expires_at_s(activity)
      }
    ]
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp station_reservation_expires_at_s(activity) do
    ([
       activity["station_reservation_expires_at_s"],
       activity["reservation_expires_at_s"],
       activity["reservation_hold_expires_at_s"],
       activity["hold_expires_at_s"],
       activity["expires_at_s"],
       activity["expires_at"]
     ] ++
       source_station_calendar_number_values(activity["source_station_calendar_entry"], [
         "station_reservation_expires_at_s",
         "reservation_expires_at_s",
         "reservation_hold_expires_at_s",
         "hold_expires_at_s",
         "expires_at_s",
         "expires_at"
       ]))
    |> Enum.find_value(&numeric_value/1)
  end

  defp station_calendar_reservation_expires_at_s(activity) do
    ([
       activity["station_calendar_reservation_expires_at_s"],
       activity["station_reservation_expires_at_s"],
       activity["reservation_expires_at_s"],
       activity["reservation_hold_expires_at_s"],
       activity["hold_expires_at_s"],
       activity["expires_at_s"],
       activity["expires_at"]
     ] ++
       source_station_calendar_number_values(activity["source_station_calendar_entry"], [
         "station_calendar_reservation_expires_at_s",
         "station_reservation_expires_at_s",
         "reservation_expires_at_s",
         "reservation_hold_expires_at_s",
         "hold_expires_at_s",
         "expires_at_s",
         "expires_at"
       ]) ++
       source_station_calendar_number_values(activity["source_station_calendar_overlaps"], [
         "station_calendar_reservation_expires_at_s",
         "station_reservation_expires_at_s",
         "reservation_expires_at_s",
         "reservation_hold_expires_at_s",
         "hold_expires_at_s",
         "expires_at_s",
         "expires_at"
       ]))
    |> normalized_number_values()
  end

  defp source_station_calendar_number_values(sources, fields) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_number_values(&1, fields))

  defp source_station_calendar_number_values(%{} = source, fields) do
    fields
    |> Enum.flat_map(fn field -> List.wrap(Map.get(source, field)) end)
  end

  defp source_station_calendar_number_values(_source, _fields), do: []

  defp normalized_number_values(values) do
    values
    |> List.flatten()
    |> Enum.map(&numeric_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  defp station_availability_value?(value)
       when value in [
              "available",
              "unavailable",
              "maintenance",
              "reserved",
              "reduced_capacity",
              "not_evaluated"
            ],
       do: true

  defp station_availability_value?(value) when value in @unavailable_aliases, do: true
  defp station_availability_value?(_value), do: false

  defp station_availability_severity(value) when value in @unavailable_aliases,
    do: @station_availability_severity["unavailable"]

  defp station_availability_severity("not_evaluated"), do: 0

  defp station_availability_severity(value), do: Map.get(@station_availability_severity, value, 0)

  defp canonical_station_availability(value)
       when value in ["unavailable", "maintenance" | @unavailable_aliases],
       do: "unavailable"

  defp canonical_station_availability(value), do: value

  defp default_direction(%{"type" => type}),
    do: Map.get(@default_direction_by_activity_type, type)

  defp default_direction(_activity), do: nil

  defp interval_start!(activity),
    do: Map.get(activity, "starts_at_s") || Map.fetch!(activity, "start_s")

  defp interval_end!(activity),
    do: Map.get(activity, "ends_at_s") || Map.fetch!(activity, "end_s")

  defp cadence_import(%{"cadence_import" => %{} = cadence_import}, _id, _direction) do
    cadence_import
  end

  defp cadence_import(%{"type" => type}, id, direction) do
    %{
      "external_id" => id,
      "activity_type" => cadence_activity_type(type, direction)
    }
  end

  defp cadence_import(_activity, id, direction) do
    %{
      "external_id" => id,
      "activity_type" => cadence_activity_type(nil, direction)
    }
  end

  defp invalid_activity_input_context(
         %{"invalid_activity_input" => true} = timeline_row,
         id,
         direction
       ) do
    reason = Map.get(timeline_row, "invalid_activity_input_reason")
    source_activity = Map.get(timeline_row, "source_activity")

    %{
      "invalid_activity_input" => true,
      "invalid_activity_input_reason" => reason,
      "source_activity" => source_activity,
      "approval_status" => "operator_review_required",
      "approval_requirements" => [
        %{
          "schema_contract" => "approval_requirement.v1",
          "id" => "approval:invalid_contact_intent:#{id}",
          "activity_id" => id,
          "activity_type" => "invalid_activity_input",
          "action" => "review_invalid_activity_input",
          "requirement_type" => "operator_review",
          "reason" => "contact intent input requires review: #{reason}",
          "activity_context" =>
            %{
              "direction" => direction,
              "invalid_activity_input" => true,
              "invalid_activity_input_reason" => reason,
              "source_activity" => source_activity,
              "timeline_identity" => Map.get(timeline_row, "timeline_identity")
            }
            |> compact_map()
        }
        |> compact_map()
      ]
    }
  end

  defp invalid_activity_input_context(_timeline_row, _id, _direction), do: %{}

  defp invalid_feedback_factor_context(
         _activity,
         %{"invalid_activity_input" => true},
         _id,
         _direction
       ),
       do: %{}

  defp invalid_feedback_factor_context(activity, timeline_row, id, direction) do
    case activity_feedback_factor_issue(activity) do
      nil ->
        %{}

      reason ->
        %{
          "invalid_activity_input" => true,
          "invalid_activity_input_reason" => reason,
          "source_activity" => activity,
          "approval_status" => "operator_review_required",
          "approval_requirements" => [
            %{
              "schema_contract" => "approval_requirement.v1",
              "id" => "approval:invalid_contact_intent:#{id}",
              "activity_id" => id,
              "activity_type" => "invalid_activity_input",
              "action" => "review_invalid_activity_input",
              "requirement_type" => "operator_review",
              "reason" => "contact intent input requires review: #{reason}",
              "activity_context" =>
                %{
                  "direction" => direction,
                  "invalid_activity_input" => true,
                  "invalid_activity_input_reason" => reason,
                  "source_activity" => activity,
                  "timeline_identity" => Map.get(timeline_row, "timeline_identity")
                }
                |> compact_map()
            }
            |> compact_map()
          ]
        }
    end
  end

  defp activity_feedback_factor_issue(activity) do
    Enum.find_value(["contact_success_factor", "command_success_factor"], fn field ->
      case activity_value(activity, field) do
        nil ->
          nil

        value ->
          case numeric_value(value) do
            number when is_number(number) ->
              if number >= 0.0 and number <= 1.0, do: nil, else: "invalid_#{field}"

            _value ->
              "invalid_#{field}"
          end
      end
    end)
  end

  defp contact_intent_id(_activity, %{"invalid_activity_input" => true} = timeline_row) do
    Map.fetch!(timeline_row, "activity_id")
  end

  defp contact_intent_id(activity, timeline_row) do
    stable_id_or_nil(Map.get(activity, "id")) || Map.fetch!(timeline_row, "activity_id")
  end

  defp contact_intent_scenario_id(activity, timeline_row, id) do
    stable_id_or_nil(Map.get(activity, "scenario_id")) ||
      stable_id_or_nil(get_in(timeline_row, ["timeline_identity", "scenario_id"])) ||
      "missing_scenario_id:#{id}"
  end

  defp contact_intent_spacecraft_id(activity, timeline_row) do
    spacecraft_identity_value(Map.get(activity, "spacecraft_id")) ||
      spacecraft_identity_value(Map.get(activity, "satellite_id")) ||
      spacecraft_identity_value(Map.get(activity, "spacecraft")) ||
      spacecraft_identity_value(Map.get(activity, "satellite")) ||
      stable_id_or_nil(Map.get(timeline_row, "spacecraft_id")) ||
      stable_id_or_nil(get_in(timeline_row, ["activity_context", "spacecraft_id"]))
  end

  defp spacecraft_identity_value(%{} = spacecraft) do
    Enum.find_value(["spacecraft_id", "satellite_id", "id"], fn field ->
      spacecraft_identity_value(Map.get(spacecraft, field))
    end)
  end

  defp spacecraft_identity_value(value), do: stable_id_or_nil(value)

  defp contact_intent_ground_station_id(activity, timeline_row, id) do
    stable_id_or_nil(Map.get(activity, "ground_station_id")) ||
      stable_id_or_nil(Map.get(timeline_row, "ground_station_id")) ||
      "missing_ground_station_id:#{id}"
  end

  defp normalize_station_calendar_id_lists(context) do
    Enum.reduce(@station_calendar_id_list_fields, context, fn field, acc ->
      case normalize_id_list(Map.get(acc, field)) do
        nil -> Map.delete(acc, field)
        ids -> Map.put(acc, field, ids)
      end
    end)
  end

  defp normalize_id_list(nil), do: nil

  defp normalize_id_list(values) when is_list(values) do
    values
    |> Enum.flat_map(&id_values/1)
    |> Enum.flat_map(&stable_id_value/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp normalize_id_list(value), do: normalize_id_list([value])

  defp derive_station_calendar_counts(context) do
    context
    |> derive_station_calendar_count(
      "station_calendar_overlap_count",
      "station_calendar_overlap_entry_ids"
    )
    |> derive_station_calendar_count(
      "station_calendar_ambiguous_entry_count",
      "station_calendar_ambiguous_entry_ids"
    )
    |> derive_station_calendar_count(
      "station_calendar_reservation_overlap_count",
      "station_calendar_reservation_ids"
    )
  end

  defp derive_station_calendar_count(context, count_field, id_field) do
    case Map.get(context, id_field) do
      ids when is_list(ids) -> Map.put(context, count_field, length(ids))
      _ids -> context
    end
  end

  defp id_values(%{} = value) do
    ["id", "station_calendar_entry_id", "station_reservation_id", "reservation_id"]
    |> Enum.flat_map(fn key ->
      case Map.get(value, key) do
        nil -> []
        nested when is_list(nested) -> nested
        nested -> [nested]
      end
    end)
  end

  defp id_values(value), do: [value]

  defp stable_id_value(nil), do: []
  defp stable_id_value(value) when is_boolean(value), do: []

  defp stable_id_value(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_value()

  defp stable_id_value("nil"), do: []

  defp stable_id_value(value) when is_binary(value),
    do: if(stable_id?(value), do: [value], else: [])

  defp stable_id_value(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_value()

  defp stable_id_value(_value), do: []

  defp stable_id_or_nil(nil), do: nil
  defp stable_id_or_nil("nil"), do: nil
  defp stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  defp stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(_value), do: nil

  defp stable_id?(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id?()
  end

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  defp stable_id?(_value), do: false

  defp cadence_activity_type("command", _direction), do: "command"
  defp cadence_activity_type("tracking", _direction), do: "tracking"
  defp cadence_activity_type("health_check", _direction), do: "health_check"
  defp cadence_activity_type("planned_contact", direction), do: "#{direction}_contact"
  defp cadence_activity_type(_type, _direction), do: "contact"

  defp model_limits do
    capabilities().known_limits
    |> Enum.map(&Atom.to_string/1)
    |> Enum.sort()
  end

  defp present?(value), do: value not in [nil, ""]
  defp number?(value), do: is_number(numeric_value(value))

  defp unit_interval_factor(activity, field) do
    value = activity_value(activity, field)

    case numeric_value(value) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      nil -> nil
      _value -> nil
    end
  end

  defp activity_value(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, nil} -> get_in(activity, ["metadata", field])
      {:ok, value} -> value
      :error -> get_in(activity, ["metadata", field])
    end
  end

  defp activity_boolean(activity, field) do
    case boolean_value(activity_value(activity, field)) do
      value when is_boolean(value) -> value
      nil -> nil
    end
  end

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
      "true" -> true
      "1" -> true
      "false" -> false
      "0" -> false
      _value -> nil
    end
  end

  defp boolean_value(_value), do: nil

  defp numeric_value(value) when is_integer(value) or is_float(value), do: value

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp integer_value(value) when is_integer(value), do: value

  defp integer_value(value) do
    case numeric_value(value) do
      number when is_number(number) and number >= 0 and trunc(number) == number -> trunc(number)
      _value -> nil
    end
  end

  defp normalize_station_calendar_status_fields(activity) when not is_map(activity), do: activity

  defp normalize_station_calendar_status_fields(activity) do
    activity
    |> normalize_status_field("availability")
    |> normalize_status_field("status")
    |> normalize_status_field("station_availability")
    |> normalize_status_field("station_calendar_status")
    |> normalize_status_list_field("station_calendar_overlap_availabilities")
    |> normalize_source_station_calendar_field("source_station_calendar_entry")
    |> normalize_source_station_calendar_field("source_station_calendar_overlaps")
  end

  defp normalize_status_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, value} when value in [nil, ""] ->
        activity

      {:ok, value} ->
        Map.put(activity, field, normalized_status_token(value))

      :error ->
        activity
    end
  end

  defp normalize_status_list_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, values} when is_list(values) ->
        values =
          values
          |> Enum.map(&normalized_status_token/1)
          |> Enum.reject(&(&1 in [nil, ""]))

        Map.put(activity, field, values)

      {:ok, value} when value not in [nil, ""] ->
        Map.put(activity, field, [normalized_status_token(value)])

      _missing_or_empty ->
        activity
    end
  end

  defp normalize_source_station_calendar_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, values} when is_list(values) ->
        Map.put(activity, field, Enum.map(values, &normalize_source_station_calendar/1))

      {:ok, value} ->
        Map.put(activity, field, normalize_source_station_calendar(value))

      :error ->
        activity
    end
  end

  defp normalize_source_station_calendar(%{} = source),
    do: normalize_station_calendar_status_fields(source)

  defp normalize_source_station_calendar(value), do: value

  defp normalize_direction_field(activity, _field) when not is_map(activity), do: activity

  defp normalize_direction_field(activity, field) do
    case Map.fetch(activity, field) do
      {:ok, value} when value in [nil, ""] ->
        activity

      {:ok, value} ->
        case normalize_contact_direction(value) do
          nil -> activity
          direction -> Map.put(activity, field, direction)
        end

      :error ->
        activity
    end
  end

  defp normalize_contact_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_contact_direction(direction) do
    direction
    |> stringify_keys()
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      alias when is_map_key(@provider_direction_aliases, alias) ->
        Map.fetch!(@provider_direction_aliases, alias)

      value when value in @directions ->
        value

      _unknown ->
        nil
    end
  end

  defp normalized_status_token(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> canonical_status_token()
  end

  defp normalized_status_token(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalized_status_token()
  end

  defp normalized_status_token(value), do: value

  defp canonical_status_token(value) when value in @unavailable_aliases, do: "unavailable"
  defp canonical_status_token(value), do: value

  defp contact_intent_activity_context(
         timeline_row,
         activity,
         station_calendar_directions,
         station_availability,
         capacity_context,
         required_capacity_context,
         reservation_expiration_context
       ) do
    case Map.get(timeline_row, "activity_context") do
      %{} = context ->
        context
        |> maybe_put_station_calendar_directions(station_calendar_directions)
        |> Map.put("station_availability", station_availability)
        |> Map.merge(capacity_context)
        |> Map.merge(required_capacity_context)
        |> Map.merge(reservation_expiration_context)
        |> maybe_put_activity_boolean(activity, "contact_success")
        |> maybe_put_activity_provider_result(activity, "contact_result")
        |> maybe_put_unit_interval_factor(activity, "contact_success_factor")
        |> maybe_put_activity_value(activity, "contact_success_factor_source")
        |> maybe_put_activity_boolean(activity, "command_success")
        |> maybe_put_activity_provider_result(activity, "command_result")
        |> maybe_put_unit_interval_factor(activity, "command_success_factor")
        |> maybe_put_activity_value(activity, "command_success_factor_source")

      context ->
        context
    end
  end

  defp maybe_put_station_calendar_directions(context, nil), do: context

  defp maybe_put_station_calendar_directions(context, station_calendar_directions),
    do: Map.put(context, "station_calendar_directions", station_calendar_directions)

  defp maybe_put_unit_interval_factor(context, activity, field) do
    case unit_interval_factor(activity, field) do
      value when is_number(value) -> Map.put(context, field, value)
      _value -> context
    end
  end

  defp maybe_put_activity_value(context, activity, field) do
    case activity_value(activity, field) do
      nil -> context
      value -> Map.put(context, field, value)
    end
  end

  defp maybe_put_activity_provider_result(context, activity, field) do
    case activity |> activity_value(field) |> provider_result_artifact_value() do
      nil -> context
      value -> Map.put(context, field, value)
    end
  end

  defp maybe_put_activity_boolean(context, activity, field) do
    case activity_boolean(activity, field) do
      value when is_boolean(value) -> Map.put(context, field, value)
      nil -> context
    end
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp provider_result_values(result) when is_binary(result) do
    result
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(values) when is_list(values) do
    Enum.flat_map(values, &provider_result_values/1)
  end

  defp provider_result_values(%{} = result) do
    Enum.flat_map(@provider_result_map_value_keys, fn key ->
      result
      |> Map.get(key)
      |> provider_result_values()
    end)
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_values()
  end

  defp provider_result_values(result)
       when is_integer(result) or is_float(result) or is_boolean(result) do
    result
    |> to_string()
    |> provider_result_values()
  end

  defp provider_result_values(_result), do: []

  defp provider_result_artifact_value(nil), do: nil

  defp provider_result_artifact_value(result) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  defp provider_result_artifact_value(results) when is_list(results) do
    case provider_result_values(results) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(%{} = result) do
    case provider_result_values(result) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(result) when is_integer(result),
    do: Integer.to_string(result)

  defp provider_result_artifact_value(result) when is_float(result), do: Float.to_string(result)
  defp provider_result_artifact_value(result) when is_boolean(result), do: Atom.to_string(result)

  defp provider_result_artifact_value(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_artifact_value()
  end

  defp provider_result_artifact_value(_result), do: nil

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
