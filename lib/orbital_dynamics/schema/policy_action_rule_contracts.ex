defmodule OrbitalDynamics.Schema.PolicyActionRuleContracts do
  @moduledoc false

  @selector_binary_fields [
    "action",
    "activity_type",
    "requirement_type",
    "risk_type",
    "event_type",
    "feasibility_status",
    "direction",
    "ground_station_id",
    "station_id",
    "station_availability",
    "station_contention_status",
    "station_reservation_status",
    "status",
    "approval_status"
  ]

  @selector_string_list_fields [
    "activity_types",
    "spacecraft_ids",
    "target_ids",
    "requirement_types",
    "risk_types",
    "event_types",
    "directions",
    "ground_station_ids",
    "station_ids",
    "station_availabilities",
    "station_contention_statuses",
    "station_reservation_statuses",
    "statuses",
    "approval_statuses"
  ]

  @selector_list_only_fields ["actions"]

  @result_boolean_fields [
    "locked",
    "degraded",
    "payload_available",
    "antenna_available",
    "command_success",
    "contact_success"
  ]

  @result_binary_fields [
    "command_result",
    "contact_result",
    "observation_result",
    "maneuver_result"
  ]

  @result_string_list_fields [
    "command_results",
    "contact_results",
    "observation_results",
    "maneuver_results"
  ]

  @threshold_number_fields [
    "capacity_fraction_max",
    "actual_completion_fraction_max"
  ]

  @threshold_probability_fields [
    "command_success_factor_max",
    "contact_success_factor_max",
    "observation_success_factor_max",
    "maneuver_success_factor_min"
  ]

  @threshold_non_negative_number_fields [
    "contention_window_s_min",
    "total_contact_duration_s_min",
    "overlap_duration_s_min"
  ]

  @threshold_non_negative_integer_fields [
    "max_concurrent_contacts_min",
    "overlap_contact_pair_count_min",
    "priority_fields_without_numeric_evidence_count_min"
  ]

  @escalation_binary_fields [
    "station_calendar_trust_boundary_status",
    "escalation_level",
    "escalation_queue",
    "escalation_role",
    "required_authority"
  ]

  def validate_unique_ids(issues, path, rules, callbacks)
      when is_list(rules) and is_list(callbacks) do
    {_seen_ids, issues} =
      rules
      |> Enum.with_index()
      |> Enum.reduce({MapSet.new(), issues}, fn
        {%{} = rule, index}, {seen_ids, acc} ->
          case Map.get(rule, "id") do
            id when is_binary(id) ->
              if MapSet.member?(seen_ids, id) do
                {seen_ids,
                 [
                   error("#{path}[#{index}].id", "must be unique within action_rules", callbacks)
                   | acc
                 ]}
              else
                {MapSet.put(seen_ids, id), acc}
              end

            _id ->
              {seen_ids, acc}
          end

        {_rule, _index}, acc ->
          acc
      end)

    issues
  end

  def validate_unique_ids(issues, _path, _rules, _callbacks), do: issues

  def validate_approval_policy(issues, path, policy, field_groups, callbacks)
      when is_map(policy) and is_list(field_groups) and is_list(callbacks) do
    issues
    |> expect_optional_number(path, policy, "auto_approvable_risk_limit", callbacks)
    |> expect_optional_number(path, policy, "auto_approvable_approval_count_limit", callbacks)
    |> expect_optional_number(path, policy, "operator_review_risk_limit", callbacks)
    |> expect_optional_list(path, policy, "blocked_risk_types", callbacks)
    |> expect_optional_list(path, policy, "action_rules", callbacks)
    |> validate_optional_rows(
      path <> ".action_rules",
      Map.get(policy, "action_rules"),
      fn acc, row_path, rule ->
        validate_action_rule(acc, row_path, rule, field_groups, callbacks)
      end,
      callbacks
    )
    |> validate_unique_ids(path <> ".action_rules", Map.get(policy, "action_rules"), callbacks)
  end

  def validate_approval_policy(issues, path, _policy, _field_groups, callbacks),
    do: [error(path, "must be an object", callbacks) | issues]

  def validate_action_rule(issues, path, rule, field_groups, callbacks)
      when is_list(field_groups) and is_list(callbacks) do
    issues
    |> validate_context_fields(path, rule, field_groups, callbacks)
    |> validate_selector_fields(path, rule, callbacks)
    |> validate_result_fields(path, rule, callbacks)
    |> validate_threshold_fields(path, rule, callbacks)
    |> validate_escalation_fields(path, rule, callbacks)
    |> validate_escalation_authority(path, rule, callbacks)
  end

  def validate_context_fields(issues, path, rule, field_groups, callbacks)
      when is_list(field_groups) and is_list(callbacks) do
    issues
    |> require_fields(path, rule, ["id", "classification", "reason"], callbacks)
    |> validate_stable_ids(path, rule, ["id"], callbacks)
    |> validate_optional_string_fields(
      path,
      rule,
      Keyword.fetch!(field_groups, :string_fields),
      callbacks
    )
    |> validate_optional_string_lists(
      path,
      rule,
      Keyword.fetch!(field_groups, :string_array_fields),
      callbacks
    )
    |> validate_optional_string_or_array_fields(
      path,
      rule,
      Keyword.fetch!(field_groups, :string_or_array_fields),
      callbacks
    )
    |> validate_optional_number_fields(
      path,
      rule,
      Keyword.fetch!(field_groups, :number_fields),
      callbacks
    )
    |> validate_optional_integer_fields(
      path,
      rule,
      Keyword.fetch!(field_groups, :integer_fields),
      callbacks
    )
    |> validate_optional_boolean_fields(
      path,
      rule,
      Keyword.fetch!(field_groups, :boolean_fields),
      callbacks
    )
    |> expect_optional_one_of(
      path,
      rule,
      "classification",
      [
        "auto_approvable",
        "operator_review_required",
        "blocked_by_policy"
      ],
      callbacks
    )
  end

  def validate_selector_fields(issues, path, rule, callbacks) when is_list(callbacks) do
    issues
    |> validate_binary_fields(path, rule, @selector_binary_fields, callbacks)
    |> validate_list_only_fields(path, rule, @selector_list_only_fields, callbacks)
    |> validate_string_list_fields(path, rule, @selector_string_list_fields, callbacks)
  end

  def validate_result_fields(issues, path, rule, callbacks) when is_list(callbacks) do
    issues
    |> validate_boolean_fields(path, rule, @result_boolean_fields, callbacks)
    |> validate_binary_fields(path, rule, @result_binary_fields, callbacks)
    |> validate_string_list_fields(path, rule, @result_string_list_fields, callbacks)
  end

  def validate_threshold_fields(issues, path, rule, callbacks) when is_list(callbacks) do
    issues
    |> validate_number_fields(path, rule, @threshold_number_fields, callbacks)
    |> validate_probability_fields(path, rule, @threshold_probability_fields, callbacks)
    |> validate_non_negative_number_fields(
      path,
      rule,
      @threshold_non_negative_number_fields,
      callbacks
    )
    |> validate_non_negative_integer_fields(
      path,
      rule,
      @threshold_non_negative_integer_fields,
      callbacks
    )
    |> expect_optional_type(
      path,
      rule,
      "priority_field_without_numeric_evidence",
      :binary,
      callbacks
    )
    |> expect_optional_type(
      path,
      rule,
      "priority_fields_without_numeric_evidence",
      :list,
      callbacks
    )
    |> validate_string_list_items(
      path,
      rule,
      "priority_fields_without_numeric_evidence",
      callbacks
    )
  end

  def validate_escalation_fields(issues, path, rule, callbacks) when is_list(callbacks) do
    issues
    |> validate_binary_fields(path, rule, @escalation_binary_fields, callbacks)
    |> expect_optional_number(path, rule, "sla_s", callbacks)
  end

  def validate_escalation_authority(issues, path, rule, callbacks) when is_list(callbacks) do
    escalation_fields = [
      "escalation_level",
      "escalation_queue",
      "escalation_role",
      "sla_s"
    ]

    has_escalation_metadata? = Enum.any?(escalation_fields, &Map.has_key?(rule, &1))

    if has_escalation_metadata? and not is_binary(Map.get(rule, "required_authority")) do
      [
        error(
          path <> ".required_authority",
          "is required when escalation metadata is present",
          callbacks
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_binary_fields(issues, path, rule, fields, callbacks) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_type(acc, path, rule, field, :binary, callbacks)
    end)
  end

  defp validate_list_only_fields(issues, path, rule, fields, callbacks) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_type(acc, path, rule, field, :list, callbacks)
    end)
  end

  defp validate_boolean_fields(issues, path, rule, fields, callbacks) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_type(acc, path, rule, field, :boolean, callbacks)
    end)
  end

  defp validate_string_list_fields(issues, path, rule, fields, callbacks) do
    Enum.reduce(fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(path, rule, field, :list, callbacks)
      |> validate_string_list_items(path, rule, field, callbacks)
    end)
  end

  defp validate_number_fields(issues, path, rule, fields, callbacks) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_number(acc, path, rule, field, callbacks)
    end)
  end

  defp validate_probability_fields(issues, path, rule, fields, callbacks) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_probability(acc, path, rule, field, callbacks)
    end)
  end

  defp validate_non_negative_number_fields(issues, path, rule, fields, callbacks) do
    Enum.reduce(fields, issues, fn field, acc ->
      acc
      |> expect_optional_number(path, rule, field, callbacks)
      |> expect_field_at_least(path, rule, field, 0, callbacks)
    end)
  end

  defp validate_non_negative_integer_fields(issues, path, rule, fields, callbacks) do
    Enum.reduce(fields, issues, fn field, acc ->
      acc
      |> expect_optional_integer(path, rule, field, callbacks)
      |> expect_field_at_least(path, rule, field, 0, callbacks)
    end)
  end

  defp require_fields(issues, path, map, fields, callbacks),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, path, map, fields, callbacks),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_optional_string_fields(issues, path, map, fields, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_string_fields), [
        issues,
        path,
        map,
        fields
      ])

  defp validate_optional_string_lists(issues, path, map, fields, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_string_lists), [
        issues,
        path,
        map,
        fields
      ])

  defp validate_optional_string_or_array_fields(issues, path, map, fields, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_string_or_array_fields), [
        issues,
        path,
        map,
        fields
      ])

  defp validate_optional_number_fields(issues, path, map, fields, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_number_fields), [
        issues,
        path,
        map,
        fields
      ])

  defp validate_optional_integer_fields(issues, path, map, fields, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_integer_fields), [
        issues,
        path,
        map,
        fields
      ])

  defp validate_optional_boolean_fields(issues, path, map, fields, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_boolean_fields), [
        issues,
        path,
        map,
        fields
      ])

  defp expect_optional_one_of(issues, path, map, field, allowed, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_optional_type(issues, path, map, field, type, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [
        issues,
        path,
        map,
        field,
        type
      ])

  defp expect_optional_number(issues, path, map, field, callbacks),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_list(issues, path, map, field, callbacks),
    do: apply(require_callback(callbacks, :expect_optional_list), [issues, path, map, field])

  defp validate_optional_rows(issues, path, rows, callback, callbacks),
    do:
      apply(require_callback(callbacks, :validate_optional_rows), [issues, path, rows, callback])

  defp expect_optional_probability(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_probability), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_integer(issues, path, map, field, callbacks),
    do: apply(require_callback(callbacks, :expect_optional_integer), [issues, path, map, field])

  defp expect_field_at_least(issues, path, map, field, minimum, callbacks),
    do:
      apply(require_callback(callbacks, :expect_field_at_least), [
        issues,
        path,
        map,
        field,
        minimum
      ])

  defp validate_string_list_items(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [
        issues,
        path,
        map,
        field
      ])

  defp error(path, message, callbacks),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
