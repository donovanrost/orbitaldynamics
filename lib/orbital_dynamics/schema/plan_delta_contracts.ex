defmodule OrbitalDynamics.Schema.PlanDeltaContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_field_equals: 6,
      expect_number: 4,
      expect_optional_number: 4,
      expect_optional_number_vector: 4,
      expect_optional_type: 5,
      require_fields: 4,
      validate_interval: 3
    ]

  alias OrbitalDynamics.Schema.{
    ActivityContextContracts,
    ExecutionMetricContracts,
    RealizedActivityContracts,
    SchemaContractField,
    TimelineIdentityContracts
  }

  def validate(issues, path, delta) do
    issues
    |> require_fields(path, delta, [
      "activity_id",
      "activity_type",
      "status",
      "repair_action"
    ])
    |> validate_stable_ids(path, delta, [
      "activity_id",
      "replacement_activity_id",
      "source_timeline_id",
      "replacement_timeline_id"
    ])
    |> validate_optional_schema_contract(path, delta, "plan_delta.v1")
    |> expect_optional_type(path, delta, "timeline_link", :map)
    |> validate_optional_timeline_link(path, delta, "timeline_link")
    |> expect_optional_type(path, delta, "reason", :binary)
    |> expect_optional_type(path, delta, "requires_approval", :boolean)
    |> expect_optional_type(path, delta, "planned", :map)
    |> expect_optional_type(path, delta, "realized", :map)
    |> expect_optional_type(path, delta, "source_activity_context", :map)
    |> expect_optional_type(path, delta, "replacement_activity_context", :map)
    |> validate_optional_activity_context(path, delta, "source_activity_context")
    |> validate_optional_activity_context(path, delta, "replacement_activity_context")
    |> expect_optional_type(path, delta, "execution_uncertainty", :map)
    |> expect_optional_type(path, delta, "maneuver_execution_uncertainty", :map)
    |> validate_optional_execution_uncertainty(path, delta, "execution_uncertainty")
    |> validate_optional_execution_uncertainty(
      path,
      delta,
      "maneuver_execution_uncertainty"
    )
    |> expect_optional_type(path, delta, "execution_uncertainty_status", :binary)
    |> expect_optional_number(path, delta, "timing_3sigma_s")
    |> expect_optional_number_vector(path, delta, "delta_v_3sigma_km_s")
    |> expect_optional_number(path, delta, "delta_v_3sigma_magnitude_km_s")
    |> expect_optional_type(path, delta, "execution_uncertainty_source", :binary)
    |> validate_optional_planned_delta_activity(path, delta)
    |> validate_optional_realized_delta_activity(path, delta)
    |> validate_source_identity(path, delta)
    |> validate_replacement_identity(path, delta)
    |> validate_timeline_link_identity(path, delta)
  end

  defp validate_source_identity(
         issues,
         path,
         %{
           "source_activity_context" => %{"timeline_identity" => %{} = identity}
         } = delta
       ) do
    issues
    |> expect_field_equals(
      path <> ".source_activity_context.timeline_identity",
      identity,
      "activity_id",
      Map.get(delta, "activity_id"),
      "must match top-level activity_id"
    )
    |> expect_field_equals(
      path <> ".source_activity_context.timeline_identity",
      identity,
      "activity_type",
      Map.get(delta, "activity_type"),
      "must match top-level activity_type"
    )
    |> expect_field_equals(
      path <> ".source_activity_context.timeline_identity",
      identity,
      "timeline_id",
      Map.get(delta, "source_timeline_id"),
      "must match source_timeline_id"
    )
    |> expect_field_equals(
      path <> ".source_activity_context",
      Map.get(delta, "source_activity_context", %{}),
      "source_window_id",
      Map.get(identity, "source_window_id"),
      "must match timeline_identity.source_window_id"
    )
  end

  defp validate_source_identity(issues, _path, _delta), do: issues

  defp validate_replacement_identity(
         issues,
         path,
         %{
           "replacement_activity_context" => %{"timeline_identity" => %{} = identity}
         } = delta
       ) do
    issues
    |> validate_optional_replacement_identity_field(
      path,
      delta,
      "replacement_activity_id",
      identity,
      "activity_id"
    )
    |> validate_optional_replacement_identity_field(
      path,
      delta,
      "replacement_timeline_id",
      identity,
      "timeline_id"
    )
  end

  defp validate_replacement_identity(issues, _path, _delta), do: issues

  defp validate_optional_replacement_identity_field(
         issues,
         path,
         delta,
         delta_field,
         identity,
         identity_field
       ) do
    case {Map.get(delta, delta_field), Map.get(identity, identity_field)} do
      {actual, expected} when is_binary(actual) and is_binary(expected) ->
        expect_field_equals(
          issues,
          path,
          delta,
          delta_field,
          expected,
          "must match replacement_activity_context.timeline_identity.#{identity_field}"
        )

      _unreplayable ->
        issues
    end
  end

  defp validate_timeline_link_identity(
         issues,
         path,
         %{"timeline_link" => %{} = timeline_link} = delta
       ) do
    [
      {"source_activity_id", "activity_id"},
      {"replacement_activity_id", "replacement_activity_id"},
      {"source_timeline_id", "source_timeline_id"},
      {"replacement_timeline_id", "replacement_timeline_id"}
    ]
    |> Enum.reduce(issues, fn {link_field, delta_field}, acc ->
      validate_optional_timeline_link_identity_field(
        acc,
        path <> ".timeline_link",
        timeline_link,
        link_field,
        delta,
        delta_field
      )
    end)
  end

  defp validate_timeline_link_identity(issues, _path, _delta), do: issues

  defp validate_optional_timeline_link_identity_field(
         issues,
         path,
         timeline_link,
         link_field,
         delta,
         delta_field
       ) do
    case {Map.get(timeline_link, link_field), Map.get(delta, delta_field)} do
      {actual, expected} when is_binary(actual) and is_binary(expected) ->
        expect_field_equals(
          issues,
          path,
          timeline_link,
          link_field,
          expected,
          "must match enclosing PlanDelta #{delta_field}"
        )

      _unreplayable ->
        issues
    end
  end

  defp validate_optional_planned_delta_activity(issues, path, %{"planned" => planned})
       when is_map(planned) do
    validate_planned_snapshot(issues, path <> ".planned", planned)
  end

  defp validate_optional_planned_delta_activity(issues, _path, _delta), do: issues

  defp validate_planned_snapshot(issues, path, planned) do
    issues
    |> require_fields(path, planned, [
      "id",
      "type",
      "scenario_id",
      "starts_at_s",
      "ends_at_s"
    ])
    |> validate_stable_ids(path, planned, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id",
      "source_window_id",
      "timeline_id",
      "spacecraft_id",
      "resource_id"
    ])
    |> expect_number(path, planned, "starts_at_s")
    |> expect_number(path, planned, "ends_at_s")
    |> validate_interval(path, planned)
    |> expect_optional_type(path, planned, "timeline_identity", :map)
    |> expect_optional_type(path, planned, "cadence_import", :map)
  end

  defp validate_optional_realized_delta_activity(issues, path, %{
         "realized" => realized
       })
       when is_map(realized) do
    validate_realized_activity(issues, path <> ".realized", realized)
  end

  defp validate_optional_realized_delta_activity(issues, _path, _delta), do: issues

  defp validate_optional_schema_contract(issues, path, map, contract),
    do: SchemaContractField.validate_optional(issues, path, map, contract)

  defp validate_optional_timeline_link(issues, path, map, field),
    do: TimelineIdentityContracts.validate_optional_link(issues, path, map, field)

  defp validate_optional_activity_context(issues, path, map, field),
    do: ActivityContextContracts.validate_optional(issues, path, map, field)

  defp validate_optional_execution_uncertainty(issues, path, map, field),
    do: ExecutionMetricContracts.validate_optional_execution_uncertainty(issues, path, map, field)

  defp validate_realized_activity(issues, path, activity),
    do: RealizedActivityContracts.validate(issues, path, activity)
end
