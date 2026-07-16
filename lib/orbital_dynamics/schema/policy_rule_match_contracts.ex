defmodule OrbitalDynamics.Schema.PolicyRuleMatchContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      validate_number_list_items: 4,
      validate_optional_boolean_fields: 4,
      validate_optional_integer_fields: 4,
      validate_optional_number_fields: 4,
      validate_optional_string_fields: 4,
      validate_optional_string_lists: 4,
      validate_optional_string_or_array_fields: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

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

  def validate(issues, path, match, field_groups) when is_list(field_groups) do
    issues
    |> validate_stable_ids(path, match, ["rule_id", "activity_id"])
    |> validate_optional_string_fields(
      path,
      match,
      Keyword.fetch!(field_groups, :string_fields)
    )
    |> validate_optional_string_lists(
      path,
      match,
      Keyword.fetch!(field_groups, :string_array_fields)
    )
    |> validate_optional_string_or_array_fields(
      path,
      match,
      Keyword.fetch!(field_groups, :string_or_array_fields)
    )
    |> validate_optional_number_fields(
      path,
      match,
      Keyword.fetch!(field_groups, :number_fields)
    )
    |> expect_optional_type(
      path,
      match,
      "station_calendar_reservation_expires_at_s",
      :list
    )
    |> validate_number_list_items(
      path,
      match,
      "station_calendar_reservation_expires_at_s"
    )
    |> validate_optional_integer_fields(
      path,
      match,
      Keyword.fetch!(field_groups, :integer_fields)
    )
    |> validate_optional_boolean_fields(
      path,
      match,
      Keyword.fetch!(field_groups, :boolean_fields)
    )
    |> expect_optional_one_of(
      path,
      match,
      "classification",
      [
        "auto_approvable",
        "operator_review_required",
        "blocked_by_policy"
      ]
    )
    |> validate_binary_fields(path, match, @binary_fields)
    |> validate_number_fields(path, match, @number_fields)
    |> validate_non_negative_integer_fields(path, match, @non_negative_integer_fields)
    |> validate_binary_fields(path, match, @status_binary_fields)
    |> validate_boolean_fields(path, match, @status_boolean_fields)
    |> OrbitalDynamics.Schema.PolicyEscalationContracts.validate(path, match)
  end

  defp validate_binary_fields(issues, path, map, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_type(acc, path, map, field, :binary)
    end)
  end

  defp validate_number_fields(issues, path, map, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_number(acc, path, map, field)
    end)
  end

  defp validate_non_negative_integer_fields(issues, path, map, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_non_negative_integer(acc, path, map, field)
    end)
  end

  defp validate_boolean_fields(issues, path, map, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_type(acc, path, map, field, :boolean)
    end)
  end
end
