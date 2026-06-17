defmodule OrbitalDynamics.Schema.PlannedActivityContracts do
  @moduledoc false

  def validate(issues, path, activity, contract, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, activity, contract["required_fields"])
    |> require_activity_type_alias(callbacks, path, activity)
    |> validate_planned_activity(callbacks, path, activity)
  end

  defp validate_planned_activity(issues, callbacks, path, activity) do
    issues
    |> validate_base(callbacks, path, activity)
    |> validate_optional_schema_contract(callbacks, path, activity, "planned_activity.v1")
    |> validate_stable_ids(callbacks, path, activity, ["spacecraft_id", "resource_id"])
    |> validate_optional_stable_id_list(callbacks, path, activity, "product_ids")
    |> validate_optional_stable_id_list(callbacks, path, activity, "dependency_activity_ids")
    |> validate_optional_stable_id_list(callbacks, path, activity, "exclusive_with_timeline_ids")
    |> expect_optional_type(callbacks, path, activity, "resource_source_quality", :binary)
    |> expect_optional_type(callbacks, path, activity, "resource_trust_boundary", :binary)
    |> expect_optional_type(callbacks, path, activity, "resource_trust_boundary_status", :binary)
    |> expect_optional_type(callbacks, path, activity, "resource_provenance", :map)
    |> expect_optional_type(callbacks, path, activity, "resource_blocking_dimension", :binary)
    |> expect_optional_probability(callbacks, path, activity, "fuel_margin")
    |> expect_optional_probability(callbacks, path, activity, "power_margin")
    |> expect_optional_probability(callbacks, path, activity, "storage_margin")
    |> expect_optional_probability(callbacks, path, activity, "downlink_margin")
    |> expect_optional_type(callbacks, path, activity, "spacecraft_available", :boolean)
    |> expect_optional_type(callbacks, path, activity, "payload_available", :boolean)
    |> expect_optional_type(callbacks, path, activity, "degraded", :boolean)
    |> expect_optional_type(callbacks, path, activity, "mode", :binary)
    |> expect_optional_number(callbacks, path, activity, "data_volume_mb")
    |> expect_optional_number(callbacks, path, activity, "data_rate_mbps")
    |> expect_optional_number(callbacks, path, activity, "downlink_rate_mbps")
    |> expect_optional_number(callbacks, path, activity, "data_rate_mb_s")
    |> expect_optional_number(callbacks, path, activity, "downlink_rate_mb_s")
    |> expect_optional_number(callbacks, path, activity, "thermal_margin_c")
    |> expect_optional_probability(callbacks, path, activity, "contact_success_factor")
    |> expect_optional_type(callbacks, path, activity, "contact_success_factor_source", :binary)
    |> expect_optional_probability(callbacks, path, activity, "command_success_factor")
    |> expect_optional_type(callbacks, path, activity, "command_success_factor_source", :binary)
    |> expect_optional_probability(callbacks, path, activity, "observation_success_factor")
    |> expect_optional_type(
      callbacks,
      path,
      activity,
      "observation_success_factor_source",
      :binary
    )
    |> expect_optional_probability(callbacks, path, activity, "cloud_cover_fraction")
    |> expect_optional_probability(callbacks, path, activity, "blur_score")
    |> expect_optional_probability(callbacks, path, activity, "maneuver_success_factor")
    |> expect_optional_type(callbacks, path, activity, "maneuver_success_factor_source", :binary)
    |> expect_optional_type(callbacks, path, activity, "execution_uncertainty", :map)
    |> validate_optional_execution_uncertainty(callbacks, path, activity, "execution_uncertainty")
    |> expect_optional_list(callbacks, path, activity, "suppressed_activity_types")
    |> validate_string_list_items(callbacks, path, activity, "suppressed_activity_types")
  end

  defp validate_base(issues, callbacks, path, activity) do
    issues
    |> validate_stable_ids(callbacks, path, activity, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id",
      "source_window_id"
    ])
    |> expect_number(callbacks, path, activity, "starts_at_s")
    |> expect_number(callbacks, path, activity, "ends_at_s")
    |> expect_optional_type(callbacks, path, activity, "type", :binary)
    |> expect_optional_type(callbacks, path, activity, "activity_type", :binary)
    |> expect_optional_type(callbacks, path, activity, "timeline_identity", :map)
    |> validate_interval(callbacks, path, activity)
    |> validate_activity_type(callbacks, path, activity)
    |> validate_timeline_identity(callbacks, path, activity)
  end

  defp validate_timeline_identity(
         issues,
         callbacks,
         path,
         %{
           "timeline_identity" => %{} = identity
         } = activity
       ) do
    issues
    |> validate_stable_ids(callbacks, path <> ".timeline_identity", identity, [
      "activity_id",
      "scenario_id",
      "source_window_id",
      "subject_id",
      "timeline_id"
    ])
    |> expect_field_equals(
      callbacks,
      path <> ".timeline_identity",
      identity,
      "activity_id",
      Map.get(activity, "id"),
      "must match activity id"
    )
    |> expect_field_equals(
      callbacks,
      path <> ".timeline_identity",
      identity,
      "scenario_id",
      Map.get(activity, "scenario_id"),
      "must match activity scenario_id"
    )
    |> expect_field_equals(
      callbacks,
      path <> ".timeline_identity",
      identity,
      "source_window_id",
      Map.get(activity, "source_window_id"),
      "must match activity source_window_id"
    )
    |> expect_field_equals(
      callbacks,
      path <> ".timeline_identity",
      identity,
      "activity_type",
      effective_activity_type(activity),
      "must match activity type"
    )
  end

  defp validate_timeline_identity(issues, _callbacks, _path, _activity), do: issues

  defp require_activity_type_alias(issues, callbacks, path, activity) do
    cond do
      present_string?(Map.get(activity, "type")) ->
        issues

      present_string?(Map.get(activity, "activity_type")) ->
        issues

      true ->
        [error(callbacks, path, "must include type or activity_type") | issues]
    end
  end

  defp validate_activity_type(issues, callbacks, path, activity) do
    case effective_activity_type(activity) do
      "observe" ->
        require_fields(issues, callbacks, path, activity, ["target_id"])

      "downlink" ->
        issues
        |> require_fields(callbacks, path, activity, ["ground_station_id"])
        |> validate_contact_fields(callbacks, path, activity)

      _type ->
        issues
    end
  end

  defp effective_activity_type(%{} = activity) do
    cond do
      present_string?(Map.get(activity, "type")) -> Map.get(activity, "type")
      present_string?(Map.get(activity, "activity_type")) -> Map.get(activity, "activity_type")
      true -> nil
    end
  end

  defp present_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_optional_schema_contract(issues, callbacks, path, map, expected) do
    apply(Keyword.fetch!(callbacks, :validate_optional_schema_contract), [
      issues,
      path,
      map,
      expected
    ])
  end

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_number), [issues, path, map, field])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_probability(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_probability), [issues, path, map, field])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_list(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_list), [issues, path, map, field])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_interval(issues, callbacks, path, activity),
    do: apply(Keyword.fetch!(callbacks, :validate_interval), [issues, path, activity])

  defp validate_contact_fields(issues, callbacks, path, activity),
    do: apply(Keyword.fetch!(callbacks, :validate_contact_fields), [issues, path, activity])

  defp validate_optional_execution_uncertainty(issues, callbacks, path, activity, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_execution_uncertainty), [
      issues,
      path,
      activity,
      field
    ])
  end

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
