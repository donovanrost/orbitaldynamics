defmodule OrbitalDynamics.Schema.ContactIntentContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.ApprovalRequirementContracts
  alias OrbitalDynamics.Schema.PolicyDecisionContracts
  alias OrbitalDynamics.Schema.PolicyFieldGroups
  alias OrbitalDynamics.Schema.StationCalendarContactCountContracts

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_non_negative_integer: 4,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      require_nested: 4,
      validate_interval: 3,
      validate_string_list_allowed: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  @directions [
    "downlink",
    "uplink",
    "command",
    "tracking",
    "health_check"
  ]

  def validate(issues, path, intent) do
    issues
    |> require_fields(path, intent, [
      "schema_contract",
      "id",
      "activity_id",
      "scenario_id",
      "ground_station_id",
      "direction",
      "starts_at_s",
      "ends_at_s"
    ])
    |> validate_stable_ids(path, intent, [
      "id",
      "activity_id",
      "scenario_id",
      "spacecraft_id",
      "timeline_id",
      "ground_station_id",
      "source_window_id"
    ])
    |> expect_equal(path, intent, "schema_contract", "contact_intent.v1")
    |> expect_one_of(path, intent, "direction", @directions)
    |> expect_number(path, intent, "starts_at_s")
    |> expect_number(path, intent, "ends_at_s")
    |> expect_optional_probability(path, intent, "capacity_fraction")
    |> expect_optional_probability(path, intent, "capacity_fraction_min")
    |> expect_optional_probability(path, intent, "capacity_fraction_max")
    |> expect_optional_non_negative_integer(path, intent, "station_calendar_overlap_count")
    |> expect_optional_type(path, intent, "station_calendar_overlap_entry_ids", :list)
    |> validate_optional_stable_id_list(path, intent, "station_calendar_overlap_entry_ids")
    |> expect_optional_non_negative_integer(
      path,
      intent,
      "station_calendar_ambiguous_entry_count"
    )
    |> expect_optional_type(path, intent, "station_calendar_ambiguous_entry_ids", :list)
    |> validate_optional_stable_id_list(path, intent, "station_calendar_ambiguous_entry_ids")
    |> expect_optional_non_negative_integer(
      path,
      intent,
      "station_calendar_reservation_overlap_count"
    )
    |> expect_optional_type(path, intent, "station_calendar_reservation_ids", :list)
    |> validate_optional_stable_id_list(path, intent, "station_calendar_reservation_ids")
    |> expect_optional_non_negative_integer(path, intent, "timeline_integrity_issue_count")
    |> expect_optional_type(path, intent, "timeline_integrity_issue_types", :list)
    |> validate_string_list_allowed(
      path,
      intent,
      "timeline_integrity_issue_types",
      timeline_capability().timeline_integrity_issue_types
    )
    |> expect_optional_type(path, intent, "timeline_identity", :map)
    |> expect_optional_type(path, intent, "model_limits", :list)
    |> validate_string_list_items(path, intent, "model_limits")
    |> validate_model_limits(path, intent)
    |> validate_optional_cadence_import(path, intent)
    |> validate_cadence_identity(path, intent)
    |> validate_optional_policy(path, intent)
    |> StationCalendarContactCountContracts.validate(path, intent)
    |> validate_interval(path, intent)
  end

  defp validate_model_limits(issues, path, intent) do
    case Map.get(intent, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if Enum.sort(limits) == contact_intent_model_limits() do
          issues
        else
          [error("#{path}.model_limits", "must match contact intent model limits") | issues]
        end

      _value ->
        issues
    end
  end

  defp validate_optional_policy(
         issues,
         path,
         %{"policy_decision" => policy_decision} = intent
       ) do
    issues
    |> expect_one_of(path, intent, "approval_status", [
      "auto_approvable",
      "operator_review_required",
      "blocked_by_policy"
    ])
    |> expect_type(path, intent, "approval_requirements", :list)
    |> expect_type(path, intent, "approval_rule_matches", :list)
    |> validate_rows(
      path <> ".approval_requirements",
      Map.get(intent, "approval_requirements", []),
      &validate_approval_requirement/3
    )
    |> validate_policy_decision(path <> ".policy_decision", policy_decision)
    |> validate_policy_identity(path, intent)
  end

  defp validate_optional_policy(issues, path, intent) do
    issues
    |> expect_optional_type(path, intent, "approval_requirements", :list)
    |> expect_optional_type(path, intent, "approval_rule_matches", :list)
  end

  defp validate_optional_cadence_import(
         issues,
         path,
         %{"cadence_import" => cadence_import}
       ) do
    issues
    |> expect_type(path, %{"cadence_import" => cadence_import}, "cadence_import", :map)
    |> require_nested(path <> ".cadence_import", cadence_import, [
      "external_id",
      "activity_type"
    ])
    |> validate_stable_ids(path <> ".cadence_import", cadence_import, ["external_id"])
  end

  defp validate_optional_cadence_import(issues, _path, _intent), do: issues

  defp validate_cadence_identity(
         issues,
         path,
         %{"cadence_import" => %{} = cadence_import} = intent
       ) do
    expect_field_equals(
      issues,
      path <> ".cadence_import",
      cadence_import,
      "external_id",
      Map.get(intent, "id"),
      "must match contact intent id"
    )
  end

  defp validate_cadence_identity(issues, _path, _intent), do: issues

  defp validate_policy_identity(issues, path, intent) do
    issues
    |> validate_policy_decision_identity(path, intent)
    |> validate_approval_requirement_activity_ids(path, intent)
  end

  defp validate_policy_decision_identity(
         issues,
         path,
         %{"policy_decision" => %{} = decision} = intent
       ) do
    expect_field_equals(
      issues,
      path <> ".policy_decision",
      decision,
      "classification",
      Map.get(intent, "approval_status"),
      "must match approval_status"
    )
  end

  defp validate_policy_decision_identity(issues, _path, _intent), do: issues

  defp validate_approval_requirement_activity_ids(
         issues,
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

  defp validate_approval_requirement_activity_ids(issues, _path, _intent), do: issues

  defp validate_approval_requirement(issues, path, requirement) do
    ApprovalRequirementContracts.validate(
      issues,
      path,
      requirement,
      policy_model_limits(),
      PolicyFieldGroups.rule_match()
    )
  end

  defp validate_policy_decision(issues, path, decision) do
    PolicyDecisionContracts.validate(
      issues,
      path,
      decision,
      policy_model_limits(),
      PolicyFieldGroups.rule_match()
    )
  end

  defp contact_intent_model_limits do
    OrbitalDynamics.Communications.ContactIntent.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
    |> Enum.sort()
  end

  defp policy_model_limits do
    OrbitalDynamics.Policy.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp timeline_capability, do: OrbitalDynamics.Timeline.capabilities()
end
