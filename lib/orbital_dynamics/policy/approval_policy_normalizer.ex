defmodule OrbitalDynamics.Policy.ApprovalPolicyNormalizer do
  @moduledoc false

  alias OrbitalDynamics.Policy.RequirementContext

  @classifications ["auto_approvable", "operator_review_required", "blocked_by_policy"]
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @unit_interval_rule_fields ~w(
    capacity_fraction_min
    capacity_fraction_max
    actual_completion_fraction_min
    actual_completion_fraction_max
    contact_success_factor_min
    contact_success_factor_max
    command_success_factor_min
    command_success_factor_max
    observation_success_factor_min
    observation_success_factor_max
    maneuver_success_factor_min
    maneuver_success_factor_max
  )
  @non_negative_number_rule_fields ~w(
    contention_window_s_min
    total_contact_duration_s_min
    overlap_duration_s_min
  )
  @non_negative_integer_rule_fields ~w(
    station_calendar_ambiguous_entry_count_min
    station_calendar_ambiguous_entry_count_max
    max_concurrent_contacts_min
    overlap_contact_pair_count_min
    priority_fields_without_numeric_evidence_count_min
  )
  @boolean_rule_fields ~w(
    contact_success
    command_success
    station_calendar_entry_ambiguous
    locked
    degraded
    payload_available
    antenna_available
  )
  @string_rule_fields ~w(
    action
    activity_type
    requirement_type
    risk_type
    spacecraft_id
    target_id
    event_type
    feasibility_status
    direction
    ground_station_id
    station_id
    station_availability
    station_contention_status
    station_reservation_id
    station_reserved_by
    station_reservation_status
    station_reservation_match_status
    station_calendar_entry_id
    station_calendar_reserved_by
    station_calendar_reservation_status
    station_calendar_status
    station_calendar_ambiguous_entry_id
    station_calendar_trust_boundary_status
    station_calendar_direction
    resource_scope
    selection_reason
    selected_priority_source
    contact_result
    command_result
    observation_result
    maneuver_result
    priority_field_without_numeric_evidence
    resolution_status
    resolution_issue
    station_calendar_provider_id
    station_calendar_provider_entry_id
    station_calendar_reservation_id
    required_operator_action
    operator_action_reason
    allocation_status
    effective_allocation_status
    allocation_reason
    suppressed_reason
    resource_blocking_dimension
    transition_decision
    application_status
    planned_protection_decision
    planned_protection_category
    timeline_integrity_status
    timeline_integrity_issue_type
    source_timeline_integrity_status
    source_timeline_integrity_issue_type
    replacement_timeline_integrity_status
    replacement_timeline_integrity_issue_type
    source_protection_decision
    source_protection_category
    replacement_protection_decision
    replacement_protection_category
    review_queue
    review_queue_key
    cadence_import_status
    status
    approval_status
    policy_classification
    resource_pressure_status
    resource_pressure_type
    resource_source_quality
    resource_trust_boundary
    resource_trust_boundary_status
    first_resource_pressure_kind
    feedback_source
    feedback_scope
    trust_boundary
    source_event_type
    escalation_level
    escalation_queue
    escalation_role
    required_authority
    reason
  )
  @string_list_rule_fields ~w(
    actions
    activity_types
    requirement_types
    risk_types
    spacecraft_ids
    target_ids
    event_types
    directions
    ground_station_ids
    station_ids
    station_availabilities
    station_contention_statuses
    station_reservation_ids
    station_reserved_bys
    station_reservation_statuses
    station_reservation_match_statuses
    station_calendar_entry_ids
    station_calendar_reserved_bys
    station_calendar_reservation_statuses
    station_calendar_statuses
    station_calendar_ambiguous_entry_ids
    station_calendar_trust_boundary_statuses
    station_calendar_directions
    resource_scopes
    selection_reasons
    selected_priority_sources
    contact_results
    command_results
    observation_results
    maneuver_results
    priority_fields_without_numeric_evidence
    resolution_statuses
    resolution_issues
    station_calendar_provider_ids
    station_calendar_provider_entry_ids
    station_calendar_reservation_ids
    required_operator_actions
    operator_action_reasons
    allocation_statuses
    effective_allocation_statuses
    allocation_reasons
    suppressed_reasons
    resource_blocking_dimensions
    transition_decisions
    application_statuses
    planned_protection_decisions
    planned_protection_categories
    timeline_integrity_statuses
    timeline_integrity_issue_types
    source_timeline_integrity_statuses
    source_timeline_integrity_issue_types
    replacement_timeline_integrity_statuses
    replacement_timeline_integrity_issue_types
    source_protection_decisions
    source_protection_categories
    replacement_protection_decisions
    replacement_protection_categories
    review_queues
    review_queue_keys
    cadence_import_statuses
    statuses
    approval_statuses
    policy_classifications
    resource_pressure_statuses
    resource_pressure_types
    resource_source_qualities
    resource_trust_boundaries
    resource_trust_boundary_statuses
    first_resource_pressure_kinds
    feedback_sources
    feedback_scopes
    trust_boundaries
    source_event_types
  )
  def normalize(policy, bundle_resolver, default_blocked_risk_types) do
    policy = stringify_keys(policy || %{})
    bundle = policy_bundle(policy, bundle_resolver)
    bundle_policy = Map.get(bundle || %{}, "approval_policy", %{})
    explicit_rules = Map.get(policy, "action_rules")
    policy = Map.merge(bundle_policy, Map.drop(policy, ["bundle", "policy_bundle_id"]))
    action_rules = Map.get(bundle_policy, "action_rules", []) ++ List.wrap(explicit_rules || [])

    %{
      "policy_bundle_id" => Map.get(bundle || %{}, "id"),
      "policy_bundle_provenance" => Map.get(bundle || %{}, "provenance"),
      "auto_approvable_risk_limit" =>
        normalize_non_negative_integer_field(policy, "auto_approvable_risk_limit", 0),
      "auto_approvable_approval_count_limit" =>
        normalize_non_negative_integer_field(policy, "auto_approvable_approval_count_limit", 0),
      "operator_review_risk_limit" =>
        normalize_non_negative_integer_field(policy, "operator_review_risk_limit", 3),
      "blocked_risk_types" => Map.get(policy, "blocked_risk_types", default_blocked_risk_types),
      "action_rules" => normalize_action_rules(action_rules)
    }
    |> validate_approval_policy!()
  end

  defp policy_bundle(%{"policy_bundle" => %{} = bundle}, _bundle_resolver) do
    normalize_inline_policy_bundle(bundle)
  end

  defp policy_bundle(%{"policy_bundle" => id}, bundle_resolver) when id not in [nil, ""],
    do: bundle_resolver.(id)

  defp policy_bundle(%{"policy_bundle_id" => id}, bundle_resolver) when id not in [nil, ""],
    do: bundle_resolver.(id)

  defp policy_bundle(%{"bundle" => id}, bundle_resolver) when id not in [nil, ""],
    do: bundle_resolver.(id)

  defp policy_bundle(_policy, _bundle_resolver), do: nil

  defp normalize_inline_policy_bundle(bundle) do
    bundle = stringify_keys(bundle)

    unless Map.get(bundle, "schema_contract", "policy_bundle.v1") == "policy_bundle.v1" do
      raise ArgumentError, "inline policy bundle must use schema_contract policy_bundle.v1"
    end

    unless is_binary(Map.get(bundle, "id")) and Map.get(bundle, "id") != "" do
      raise ArgumentError, "inline policy bundle requires a non-empty id"
    end

    unless is_map(Map.get(bundle, "approval_policy")) do
      raise ArgumentError, "inline policy bundle requires an approval_policy map"
    end

    Map.put_new(bundle, "schema_contract", "policy_bundle.v1")
  end

  defp normalize_action_rules(rules) when is_list(rules) do
    rules
    |> Enum.with_index()
    |> Enum.map(fn {rule_input, index} ->
      unless is_map(rule_input) do
        raise ArgumentError, "policy action rule #{index + 1} must be a map"
      end

      rule = stringify_keys(rule_input)

      classification =
        Map.get(rule, "classification", Map.get(rule, "status", "operator_review_required"))

      unless classification in @classifications do
        raise ArgumentError, "policy classification must be one of #{inspect(@classifications)}"
      end

      rule
      |> normalize_rule_station_aliases()
      |> normalize_rule_station_status_fields()
      |> normalize_rule_direction_fields()
      |> normalize_action_rule_numeric_fields()
      |> Map.put_new("id", "approval_rule_#{index + 1}")
      |> Map.put("classification", classification)
      |> Map.put_new("reason", "approval_policy_action_rule")
      |> validate_action_rule!()
    end)
    |> validate_unique_action_rule_ids!()
    |> Enum.sort_by(& &1["id"])
  end

  defp normalize_action_rules(_rules), do: []

  defp validate_unique_action_rule_ids!(rules) do
    duplicate_ids =
      rules
      |> Enum.map(& &1["id"])
      |> Enum.frequencies()
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> Enum.map(fn {id, _count} -> id end)

    if duplicate_ids != [] do
      raise ArgumentError,
            "policy action rule ids must be unique: #{Enum.join(Enum.sort(duplicate_ids), ", ")}"
    end

    rules
  end

  defp validate_approval_policy!(policy) do
    Enum.each(
      [
        "auto_approvable_risk_limit",
        "auto_approvable_approval_count_limit",
        "operator_review_risk_limit"
      ],
      fn field ->
        unless non_negative_integer?(policy[field]) do
          raise ArgumentError, "approval policy #{field} must be a non-negative integer"
        end
      end
    )

    case policy["blocked_risk_types"] do
      values when is_list(values) ->
        unless Enum.all?(values, &(is_binary(&1) and &1 != "")) do
          raise ArgumentError, "approval policy blocked_risk_types must be a list of strings"
        end

      _value ->
        raise ArgumentError, "approval policy blocked_risk_types must be a list of strings"
    end

    policy
  end

  defp non_negative_integer?(value), do: is_integer(value) and value >= 0

  defp normalize_non_negative_integer_field(policy, field, default) do
    value = Map.get(policy, field, default)

    case non_negative_integer_value(value) do
      nil -> value
      integer -> integer
    end
  end

  defp normalize_action_rule_numeric_fields(rule) do
    rule =
      Enum.reduce(@unit_interval_rule_fields, rule, fn field, rule ->
        normalize_numeric_field(rule, field)
      end)

    rule =
      Enum.reduce(@non_negative_number_rule_fields, rule, fn field, rule ->
        normalize_numeric_field(rule, field)
      end)

    rule =
      Enum.reduce(@non_negative_integer_rule_fields, rule, fn field, rule ->
        normalize_non_negative_integer_rule_field(rule, field)
      end)

    normalize_numeric_field(rule, "sla_s")
  end

  defp normalize_numeric_field(rule, field) do
    case Map.fetch(rule, field) do
      {:ok, value} ->
        case numeric_value(value) do
          nil -> rule
          number -> Map.put(rule, field, number)
        end

      :error ->
        rule
    end
  end

  defp normalize_non_negative_integer_rule_field(rule, field) do
    case Map.fetch(rule, field) do
      {:ok, value} ->
        case non_negative_integer_value(value) do
          nil -> rule
          integer -> Map.put(rule, field, integer)
        end

      :error ->
        rule
    end
  end

  defp non_negative_integer_value(value) when is_integer(value) and value >= 0, do: value

  defp non_negative_integer_value(value) when is_float(value) and value >= 0.0 do
    rounded = round(value)

    if rounded == value, do: rounded
  end

  defp non_negative_integer_value(value) when is_binary(value) do
    value
    |> numeric_value()
    |> non_negative_integer_value()
  end

  defp non_negative_integer_value(_value), do: nil

  defp numeric_value(value) when is_integer(value) or is_float(value), do: value

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp validate_action_rule!(rule) do
    unless stable_id?(rule["id"]) do
      raise ArgumentError, "policy action rule id must be a stable identifier"
    end

    Enum.each(@unit_interval_rule_fields, fn field ->
      case Map.get(rule, field) do
        nil ->
          :ok

        value when is_number(value) and value >= 0.0 and value <= 1.0 ->
          :ok

        _value ->
          raise ArgumentError, "policy action rule #{field} must be a number from 0.0 to 1.0"
      end
    end)

    Enum.each(@boolean_rule_fields, fn field ->
      case Map.get(rule, field) do
        nil ->
          :ok

        value when is_boolean(value) ->
          :ok

        _value ->
          raise ArgumentError, "policy action rule #{field} must be a boolean"
      end
    end)

    Enum.each(@non_negative_number_rule_fields, fn field ->
      case Map.get(rule, field) do
        nil ->
          :ok

        value when is_number(value) and value >= 0.0 ->
          :ok

        _value ->
          raise ArgumentError,
                "policy action rule #{field} must be a non-negative number"
      end
    end)

    Enum.each(@non_negative_integer_rule_fields, fn field ->
      case Map.get(rule, field) do
        nil ->
          :ok

        value when is_integer(value) and value >= 0 ->
          :ok

        _value ->
          raise ArgumentError,
                "policy action rule #{field} must be a non-negative integer"
      end
    end)

    Enum.each(@string_rule_fields, fn field ->
      case Map.get(rule, field) do
        nil ->
          :ok

        value when is_binary(value) and value != "" ->
          :ok

        _value ->
          raise ArgumentError, "policy action rule #{field} must be a non-empty string"
      end
    end)

    Enum.each(@string_list_rule_fields, fn field ->
      case Map.get(rule, field) do
        nil ->
          :ok

        values when is_list(values) ->
          unless Enum.all?(values, &(is_binary(&1) and &1 != "")) do
            raise ArgumentError,
                  "policy action rule #{field} must be a list of non-empty strings"
          end

        _value ->
          raise ArgumentError, "policy action rule #{field} must be a list of non-empty strings"
      end
    end)

    validate_cadence_import_status_rule!(rule)
    validate_policy_classification_rule!(rule)

    case Map.get(rule, "sla_s") do
      nil ->
        :ok

      value when is_number(value) ->
        :ok

      _value ->
        raise ArgumentError, "policy action rule sla_s must be a number"
    end

    rule
  end

  defp validate_cadence_import_status_rule!(rule) do
    allowed = cadence_import_statuses()

    case Map.get(rule, "cadence_import_status") do
      nil ->
        :ok

      value when is_binary(value) ->
        unless value in allowed do
          raise ArgumentError,
                "policy action rule cadence_import_status must be one of #{inspect(allowed)}"
        end

      _value ->
        :ok
    end

    case Map.get(rule, "cadence_import_statuses") do
      nil ->
        :ok

      values when is_list(values) ->
        unless Enum.all?(values, &(&1 in allowed)) do
          raise ArgumentError,
                "policy action rule cadence_import_statuses must use values from #{inspect(allowed)}"
        end

      _value ->
        :ok
    end
  end

  defp validate_policy_classification_rule!(rule) do
    case Map.get(rule, "policy_classification") do
      nil ->
        :ok

      value when is_binary(value) ->
        unless value in @classifications do
          raise ArgumentError,
                "policy action rule policy_classification must be one of #{inspect(@classifications)}"
        end

      _value ->
        :ok
    end

    case Map.get(rule, "policy_classifications") do
      nil ->
        :ok

      values when is_list(values) ->
        unless Enum.all?(values, &(&1 in @classifications)) do
          raise ArgumentError,
                "policy action rule policy_classifications must use values from #{inspect(@classifications)}"
        end

      _value ->
        :ok
    end
  end

  defp cadence_import_statuses do
    OrbitalDynamics.CadenceImport.capability().cadence_import_statuses
  end

  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(_value), do: false

  defp normalize_rule_station_aliases(rule) do
    rule
    |> put_alias_if_missing("ground_station_id", "station_id")
    |> put_alias_if_missing("ground_station_ids", "station_ids")
  end

  defp put_alias_if_missing(rule, canonical, alias_field) do
    case {Map.get(rule, canonical), Map.get(rule, alias_field)} do
      {nil, alias_value} when not is_nil(alias_value) -> Map.put(rule, canonical, alias_value)
      _other -> rule
    end
  end

  defp normalize_rule_station_status_fields(rule) do
    rule
    |> normalize_status_field("station_availability")
    |> normalize_status_field("station_availabilities")
    |> normalize_status_field("station_contention_status")
    |> normalize_status_field("station_contention_statuses")
    |> normalize_status_field("station_reservation_status")
    |> normalize_status_field("station_reservation_statuses")
    |> normalize_status_field("station_reservation_match_status")
    |> normalize_status_field("station_reservation_match_statuses")
    |> normalize_status_field("station_calendar_reservation_status")
    |> normalize_status_field("station_calendar_reservation_statuses")
    |> normalize_status_field("station_calendar_status")
    |> normalize_status_field("station_calendar_statuses")
  end

  defp normalize_rule_direction_fields(rule) do
    rule
    |> normalize_direction_field("direction")
    |> normalize_direction_field("directions")
    |> normalize_direction_field("station_calendar_direction")
    |> normalize_direction_field("station_calendar_directions")
  end

  defp normalize_status_field(map, field) do
    case Map.fetch(map, field) do
      {:ok, value} -> Map.put(map, field, normalize_station_status_value(value))
      :error -> map
    end
  end

  defp normalize_station_status_value(value),
    do: RequirementContext.normalize_station_status(value)

  defp normalize_direction_field(map, field),
    do: RequirementContext.normalize_direction_field(map, field)

  defp stringify_keys(%_struct{} = struct) do
    struct
    |> Map.from_struct()
    |> stringify_keys()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
