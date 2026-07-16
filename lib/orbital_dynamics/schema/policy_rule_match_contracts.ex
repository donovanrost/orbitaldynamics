defmodule OrbitalDynamics.Schema.PolicyRuleMatchContracts do
  @moduledoc false

  @binary_fields [
    "reason",
    "action",
    "activity_type",
    "requirement_type",
    "direction",
    "ground_station_id",
    "station_contention_status",
    "station_reservation_status"
  ]

  @number_fields [
    "contention_window_s",
    "total_contact_duration_s",
    "overlap_duration_s"
  ]

  @non_negative_integer_fields [
    "max_concurrent_contacts",
    "overlap_contact_pair_count",
    "station_calendar_ambiguous_entry_count",
    "priority_fields_without_numeric_evidence_count"
  ]

  @status_binary_fields [
    "status",
    "approval_status",
    "risk_type",
    "risk_reason",
    "event_type",
    "feasibility_status"
  ]

  @status_boolean_fields [
    "locked",
    "degraded",
    "payload_available"
  ]

  def validate(issues, path, match, field_groups, callbacks)
      when is_list(field_groups) and is_list(callbacks) do
    issues
    |> validate_stable_ids(path, match, ["rule_id", "activity_id"], callbacks)
    |> validate_optional_string_fields(
      path,
      match,
      Keyword.fetch!(field_groups, :string_fields),
      callbacks
    )
    |> validate_optional_string_lists(
      path,
      match,
      Keyword.fetch!(field_groups, :string_array_fields),
      callbacks
    )
    |> validate_optional_string_or_array_fields(
      path,
      match,
      Keyword.fetch!(field_groups, :string_or_array_fields),
      callbacks
    )
    |> validate_optional_number_fields(
      path,
      match,
      Keyword.fetch!(field_groups, :number_fields),
      callbacks
    )
    |> expect_optional_type(
      path,
      match,
      "station_calendar_reservation_expires_at_s",
      :list,
      callbacks
    )
    |> validate_number_list_items(
      path,
      match,
      "station_calendar_reservation_expires_at_s",
      callbacks
    )
    |> validate_optional_integer_fields(
      path,
      match,
      Keyword.fetch!(field_groups, :integer_fields),
      callbacks
    )
    |> validate_optional_boolean_fields(
      path,
      match,
      Keyword.fetch!(field_groups, :boolean_fields),
      callbacks
    )
    |> expect_optional_one_of(
      path,
      match,
      "classification",
      [
        "auto_approvable",
        "operator_review_required",
        "blocked_by_policy"
      ],
      callbacks
    )
    |> validate_binary_fields(path, match, @binary_fields, callbacks)
    |> validate_number_fields(path, match, @number_fields, callbacks)
    |> validate_non_negative_integer_fields(path, match, @non_negative_integer_fields, callbacks)
    |> validate_binary_fields(path, match, @status_binary_fields, callbacks)
    |> validate_boolean_fields(path, match, @status_boolean_fields, callbacks)
    |> validate_policy_escalation(path, match, callbacks)
  end

  defp validate_binary_fields(issues, path, map, fields, callbacks) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_type(acc, path, map, field, :binary, callbacks)
    end)
  end

  defp validate_number_fields(issues, path, map, fields, callbacks) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_number(acc, path, map, field, callbacks)
    end)
  end

  defp validate_non_negative_integer_fields(issues, path, map, fields, callbacks) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_non_negative_integer(acc, path, map, field, callbacks)
    end)
  end

  defp validate_boolean_fields(issues, path, map, fields, callbacks) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_type(acc, path, map, field, :boolean, callbacks)
    end)
  end

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

  defp expect_optional_type(issues, path, map, field, type, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_one_of(issues, path, map, field, allowed, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_optional_number(issues, path, map, field, callbacks),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_non_negative_integer(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp validate_number_list_items(issues, path, map, field, callbacks),
    do:
      apply(require_callback(callbacks, :validate_number_list_items), [
        issues,
        path,
        map,
        field
      ])

  defp validate_policy_escalation(issues, path, match, callbacks),
    do: apply(require_callback(callbacks, :validate_policy_escalation), [issues, path, match])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
