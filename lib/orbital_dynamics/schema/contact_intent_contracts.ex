defmodule OrbitalDynamics.Schema.ContactIntentContracts do
  @moduledoc false

  @directions [
    "downlink",
    "uplink",
    "command",
    "tracking",
    "health_check"
  ]

  def validate(issues, path, intent, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, intent, [
      "schema_contract",
      "id",
      "activity_id",
      "scenario_id",
      "ground_station_id",
      "direction",
      "starts_at_s",
      "ends_at_s"
    ])
    |> validate_stable_ids(callbacks, path, intent, [
      "id",
      "activity_id",
      "scenario_id",
      "spacecraft_id",
      "timeline_id",
      "ground_station_id",
      "source_window_id"
    ])
    |> expect_equal(callbacks, path, intent, "schema_contract", "contact_intent.v1")
    |> expect_one_of(callbacks, path, intent, "direction", @directions)
    |> expect_number(callbacks, path, intent, "starts_at_s")
    |> expect_number(callbacks, path, intent, "ends_at_s")
    |> expect_optional_probability(callbacks, path, intent, "capacity_fraction")
    |> expect_optional_probability(callbacks, path, intent, "capacity_fraction_min")
    |> expect_optional_probability(callbacks, path, intent, "capacity_fraction_max")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      intent,
      "station_calendar_overlap_count"
    )
    |> expect_optional_type(callbacks, path, intent, "station_calendar_overlap_entry_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      intent,
      "station_calendar_overlap_entry_ids"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      intent,
      "station_calendar_ambiguous_entry_count"
    )
    |> expect_optional_type(
      callbacks,
      path,
      intent,
      "station_calendar_ambiguous_entry_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      intent,
      "station_calendar_ambiguous_entry_ids"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      intent,
      "station_calendar_reservation_overlap_count"
    )
    |> expect_optional_type(callbacks, path, intent, "station_calendar_reservation_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      intent,
      "station_calendar_reservation_ids"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      intent,
      "timeline_integrity_issue_count"
    )
    |> expect_optional_type(callbacks, path, intent, "timeline_integrity_issue_types", :list)
    |> validate_string_list_allowed(
      callbacks,
      path,
      intent,
      "timeline_integrity_issue_types",
      timeline_capability().timeline_integrity_issue_types
    )
    |> expect_optional_type(callbacks, path, intent, "timeline_identity", :map)
    |> expect_optional_type(callbacks, path, intent, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, intent, "model_limits")
    |> validate_model_limits(callbacks, path, intent)
    |> validate_optional_cadence_import(callbacks, path, intent)
    |> validate_cadence_identity(callbacks, path, intent)
    |> validate_optional_policy(callbacks, path, intent)
    |> validate_station_calendar_contact_counts(callbacks, path, intent)
    |> validate_interval(callbacks, path, intent)
  end

  defp validate_model_limits(issues, callbacks, path, intent) do
    case Map.get(intent, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if Enum.sort(limits) == contact_intent_model_limits(callbacks) do
          issues
        else
          [
            error(callbacks, "#{path}.model_limits", "must match contact intent model limits")
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_optional_policy(
         issues,
         callbacks,
         path,
         %{"policy_decision" => policy_decision} = intent
       ) do
    issues
    |> expect_one_of(callbacks, path, intent, "approval_status", [
      "auto_approvable",
      "operator_review_required",
      "blocked_by_policy"
    ])
    |> expect_type(callbacks, path, intent, "approval_requirements", :list)
    |> expect_type(callbacks, path, intent, "approval_rule_matches", :list)
    |> validate_rows(
      callbacks,
      path <> ".approval_requirements",
      Map.get(intent, "approval_requirements", []),
      :validate_approval_requirement
    )
    |> validate_policy_decision(callbacks, path <> ".policy_decision", policy_decision)
    |> validate_policy_identity(callbacks, path, intent)
  end

  defp validate_optional_policy(issues, callbacks, path, intent) do
    issues
    |> expect_optional_type(callbacks, path, intent, "approval_requirements", :list)
    |> expect_optional_type(callbacks, path, intent, "approval_rule_matches", :list)
  end

  defp validate_optional_cadence_import(
         issues,
         callbacks,
         path,
         %{"cadence_import" => cadence_import}
       ) do
    issues
    |> expect_type(callbacks, path, %{"cadence_import" => cadence_import}, "cadence_import", :map)
    |> require_nested(callbacks, path <> ".cadence_import", cadence_import, [
      "external_id",
      "activity_type"
    ])
    |> validate_stable_ids(callbacks, path <> ".cadence_import", cadence_import, ["external_id"])
  end

  defp validate_optional_cadence_import(issues, _callbacks, _path, _intent), do: issues

  defp validate_cadence_identity(
         issues,
         callbacks,
         path,
         %{"cadence_import" => %{} = cadence_import} = intent
       ) do
    expect_field_equals(
      issues,
      callbacks,
      path <> ".cadence_import",
      cadence_import,
      "external_id",
      Map.get(intent, "id"),
      "must match contact intent id"
    )
  end

  defp validate_cadence_identity(issues, _callbacks, _path, _intent), do: issues

  defp validate_policy_identity(issues, callbacks, path, intent) do
    issues
    |> validate_policy_decision_identity(callbacks, path, intent)
    |> validate_approval_requirement_activity_ids(callbacks, path, intent)
  end

  defp validate_policy_decision_identity(
         issues,
         callbacks,
         path,
         %{"policy_decision" => %{} = decision} = intent
       ) do
    expect_field_equals(
      issues,
      callbacks,
      path <> ".policy_decision",
      decision,
      "classification",
      Map.get(intent, "approval_status"),
      "must match approval_status"
    )
  end

  defp validate_policy_decision_identity(issues, _callbacks, _path, _intent), do: issues

  defp validate_approval_requirement_activity_ids(
         issues,
         callbacks,
         path,
         %{"approval_requirements" => requirements} = intent
       )
       when is_list(requirements) do
    requirements
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = requirement, index}, acc ->
        expect_field_equals(
          acc,
          callbacks,
          "#{path}.approval_requirements[#{index}]",
          requirement,
          "activity_id",
          Map.get(intent, "activity_id"),
          "must match contact intent activity_id"
        )

      {_requirement, _index}, acc ->
        acc
    end)
  end

  defp validate_approval_requirement_activity_ids(issues, _callbacks, _path, _intent),
    do: issues

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()

  defp contact_intent_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_intent_model_limits), [])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])

  defp expect_equal(issues, callbacks, path, intent, field, expected) do
    callback!(callbacks, :expect_equal).(issues, path, intent, field, expected)
  end

  defp expect_field_equals(issues, callbacks, path, intent, field, expected, message) do
    callback!(callbacks, :expect_field_equals).(issues, path, intent, field, expected, message)
  end

  defp expect_number(issues, callbacks, path, intent, field) do
    callback!(callbacks, :expect_number).(issues, path, intent, field)
  end

  defp expect_one_of(issues, callbacks, path, intent, field, values) do
    callback!(callbacks, :expect_one_of).(issues, path, intent, field, values)
  end

  defp expect_optional_non_negative_integer(issues, callbacks, path, intent, field) do
    callback!(callbacks, :expect_optional_non_negative_integer).(issues, path, intent, field)
  end

  defp expect_optional_probability(issues, callbacks, path, intent, field) do
    callback!(callbacks, :expect_optional_probability).(issues, path, intent, field)
  end

  defp expect_optional_type(issues, callbacks, path, intent, field, type) do
    callback!(callbacks, :expect_optional_type).(issues, path, intent, field, type)
  end

  defp expect_type(issues, callbacks, path, intent, field, type) do
    callback!(callbacks, :expect_type).(issues, path, intent, field, type)
  end

  defp require_fields(issues, callbacks, path, intent, fields) do
    callback!(callbacks, :require_fields).(issues, path, intent, fields)
  end

  defp require_nested(issues, callbacks, path, intent, fields) do
    callback!(callbacks, :require_nested).(issues, path, intent, fields)
  end

  defp validate_interval(issues, callbacks, path, intent) do
    callback!(callbacks, :validate_interval).(issues, path, intent)
  end

  defp validate_optional_stable_id_list(issues, callbacks, path, intent, field) do
    callback!(callbacks, :validate_optional_stable_id_list).(issues, path, intent, field)
  end

  defp validate_policy_decision(issues, callbacks, path, decision) do
    callback!(callbacks, :validate_policy_decision).(issues, path, decision)
  end

  defp validate_rows(issues, callbacks, path, rows, callback_name) do
    callback!(callbacks, :validate_rows).(issues, path, rows, callback!(callbacks, callback_name))
  end

  defp validate_stable_ids(issues, callbacks, path, intent, fields) do
    callback!(callbacks, :validate_stable_ids).(issues, path, intent, fields)
  end

  defp validate_station_calendar_contact_counts(issues, callbacks, path, intent) do
    callback!(callbacks, :validate_station_calendar_contact_counts).(issues, path, intent)
  end

  defp validate_string_list_allowed(issues, callbacks, path, intent, field, values) do
    callback!(callbacks, :validate_string_list_allowed).(issues, path, intent, field, values)
  end

  defp validate_string_list_items(issues, callbacks, path, intent, field) do
    callback!(callbacks, :validate_string_list_items).(issues, path, intent, field)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
