defmodule OrbitalDynamics.Schema.PlanDeltaContracts do
  @moduledoc false

  def validate(issues, path, delta, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, delta, [
      "activity_id",
      "activity_type",
      "status",
      "repair_action"
    ])
    |> validate_stable_ids(callbacks, path, delta, [
      "activity_id",
      "replacement_activity_id",
      "source_timeline_id",
      "replacement_timeline_id"
    ])
    |> validate_optional_schema_contract(callbacks, path, delta, "plan_delta.v1")
    |> expect_optional_type(callbacks, path, delta, "timeline_link", :map)
    |> validate_optional_timeline_link(callbacks, path, delta, "timeline_link")
    |> expect_optional_type(callbacks, path, delta, "reason", :binary)
    |> expect_optional_type(callbacks, path, delta, "requires_approval", :boolean)
    |> expect_optional_type(callbacks, path, delta, "planned", :map)
    |> expect_optional_type(callbacks, path, delta, "realized", :map)
    |> expect_optional_type(callbacks, path, delta, "source_activity_context", :map)
    |> expect_optional_type(callbacks, path, delta, "replacement_activity_context", :map)
    |> validate_optional_activity_context(callbacks, path, delta, "source_activity_context")
    |> validate_optional_activity_context(callbacks, path, delta, "replacement_activity_context")
    |> expect_optional_type(callbacks, path, delta, "execution_uncertainty", :map)
    |> expect_optional_type(callbacks, path, delta, "maneuver_execution_uncertainty", :map)
    |> validate_optional_execution_uncertainty(callbacks, path, delta, "execution_uncertainty")
    |> validate_optional_execution_uncertainty(
      callbacks,
      path,
      delta,
      "maneuver_execution_uncertainty"
    )
    |> expect_optional_type(callbacks, path, delta, "execution_uncertainty_status", :binary)
    |> expect_optional_number(callbacks, path, delta, "timing_3sigma_s")
    |> expect_optional_number_vector(callbacks, path, delta, "delta_v_3sigma_km_s")
    |> expect_optional_number(callbacks, path, delta, "delta_v_3sigma_magnitude_km_s")
    |> expect_optional_type(callbacks, path, delta, "execution_uncertainty_source", :binary)
    |> validate_optional_planned_delta_activity(callbacks, path, delta)
    |> validate_optional_realized_delta_activity(callbacks, path, delta)
    |> validate_source_identity(callbacks, path, delta)
  end

  defp validate_source_identity(
         issues,
         callbacks,
         path,
         %{
           "source_activity_context" => %{"timeline_identity" => %{} = identity}
         } = delta
       ) do
    issues
    |> expect_field_equals(
      callbacks,
      path <> ".source_activity_context.timeline_identity",
      identity,
      "activity_id",
      Map.get(delta, "activity_id"),
      "must match top-level activity_id"
    )
    |> expect_field_equals(
      callbacks,
      path <> ".source_activity_context.timeline_identity",
      identity,
      "activity_type",
      Map.get(delta, "activity_type"),
      "must match top-level activity_type"
    )
    |> expect_field_equals(
      callbacks,
      path <> ".source_activity_context.timeline_identity",
      identity,
      "timeline_id",
      Map.get(delta, "source_timeline_id"),
      "must match source_timeline_id"
    )
    |> expect_field_equals(
      callbacks,
      path <> ".source_activity_context",
      Map.get(delta, "source_activity_context", %{}),
      "source_window_id",
      Map.get(identity, "source_window_id"),
      "must match timeline_identity.source_window_id"
    )
  end

  defp validate_source_identity(issues, _callbacks, _path, _delta), do: issues

  defp validate_optional_planned_delta_activity(issues, callbacks, path, %{"planned" => planned})
       when is_map(planned) do
    validate_planned_snapshot(issues, callbacks, path <> ".planned", planned)
  end

  defp validate_optional_planned_delta_activity(issues, _callbacks, _path, _delta), do: issues

  defp validate_planned_snapshot(issues, callbacks, path, planned) do
    issues
    |> require_fields(callbacks, path, planned, [
      "id",
      "type",
      "scenario_id",
      "starts_at_s",
      "ends_at_s"
    ])
    |> validate_stable_ids(callbacks, path, planned, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id",
      "source_window_id",
      "timeline_id",
      "spacecraft_id",
      "resource_id"
    ])
    |> expect_number(callbacks, path, planned, "starts_at_s")
    |> expect_number(callbacks, path, planned, "ends_at_s")
    |> validate_interval(callbacks, path, planned)
    |> expect_optional_type(callbacks, path, planned, "timeline_identity", :map)
    |> expect_optional_type(callbacks, path, planned, "cadence_import", :map)
  end

  defp validate_optional_realized_delta_activity(issues, callbacks, path, %{
         "realized" => realized
       })
       when is_map(realized) do
    validate_realized_activity(callbacks, issues, path <> ".realized", realized)
  end

  defp validate_optional_realized_delta_activity(issues, _callbacks, _path, _delta), do: issues

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_optional_schema_contract(issues, callbacks, path, map, contract),
    do:
      apply(require_callback(callbacks, :validate_optional_schema_contract), [
        issues,
        path,
        map,
        contract
      ])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp validate_optional_timeline_link(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_timeline_link), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_activity_context(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_activity_context), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_execution_uncertainty(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_execution_uncertainty), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_number_vector(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_number_vector), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_number), [issues, path, map, field])

  defp validate_interval(issues, callbacks, path, map),
    do: apply(require_callback(callbacks, :validate_interval), [issues, path, map])

  defp validate_realized_activity(callbacks, issues, path, activity),
    do: apply(require_callback(callbacks, :validate_realized_activity), [issues, path, activity])
end
