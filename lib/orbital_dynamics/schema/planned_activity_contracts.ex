defmodule OrbitalDynamics.Schema.PlannedActivityContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_field_equals: 6,
      expect_number: 4,
      expect_optional_list: 4,
      expect_optional_number: 4,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      require_fields: 4,
      validate_interval: 3,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  def validate(issues, path, activity, contract) do
    issues
    |> require_fields(path, activity, contract["required_fields"])
    |> require_activity_type_alias(path, activity)
    |> validate_planned_activity(path, activity)
  end

  defp validate_planned_activity(issues, path, activity) do
    issues
    |> validate_base(path, activity)
    |> OrbitalDynamics.Schema.SchemaContractField.validate_optional(
      path,
      activity,
      "planned_activity.v1"
    )
    |> validate_stable_ids(path, activity, ["spacecraft_id", "resource_id"])
    |> validate_optional_stable_id_list(path, activity, "product_ids")
    |> validate_optional_stable_id_list(path, activity, "dependency_activity_ids")
    |> validate_optional_stable_id_list(path, activity, "exclusive_with_timeline_ids")
    |> expect_optional_type(path, activity, "resource_source_quality", :binary)
    |> expect_optional_type(path, activity, "resource_trust_boundary", :binary)
    |> expect_optional_type(path, activity, "resource_trust_boundary_status", :binary)
    |> expect_optional_type(path, activity, "resource_provenance", :map)
    |> expect_optional_type(path, activity, "resource_blocking_dimension", :binary)
    |> expect_optional_probability(path, activity, "fuel_margin")
    |> expect_optional_probability(path, activity, "power_margin")
    |> expect_optional_probability(path, activity, "storage_margin")
    |> expect_optional_probability(path, activity, "downlink_margin")
    |> expect_optional_type(path, activity, "spacecraft_available", :boolean)
    |> expect_optional_type(path, activity, "payload_available", :boolean)
    |> expect_optional_type(path, activity, "degraded", :boolean)
    |> expect_optional_type(path, activity, "mode", :binary)
    |> expect_optional_number(path, activity, "data_volume_mb")
    |> expect_optional_number(path, activity, "data_rate_mbps")
    |> expect_optional_number(path, activity, "downlink_rate_mbps")
    |> expect_optional_number(path, activity, "data_rate_mb_s")
    |> expect_optional_number(path, activity, "downlink_rate_mb_s")
    |> expect_optional_number(path, activity, "thermal_margin_c")
    |> expect_optional_probability(path, activity, "contact_success_factor")
    |> expect_optional_type(path, activity, "contact_success_factor_source", :binary)
    |> expect_optional_probability(path, activity, "command_success_factor")
    |> expect_optional_type(path, activity, "command_success_factor_source", :binary)
    |> expect_optional_probability(path, activity, "observation_success_factor")
    |> expect_optional_type(
      path,
      activity,
      "observation_success_factor_source",
      :binary
    )
    |> expect_optional_probability(path, activity, "cloud_cover_fraction")
    |> expect_optional_probability(path, activity, "blur_score")
    |> expect_optional_probability(path, activity, "maneuver_success_factor")
    |> expect_optional_type(path, activity, "maneuver_success_factor_source", :binary)
    |> expect_optional_type(path, activity, "execution_uncertainty", :map)
    |> OrbitalDynamics.Schema.ExecutionMetricContracts.validate_optional_execution_uncertainty(
      path,
      activity,
      "execution_uncertainty"
    )
    |> expect_optional_list(path, activity, "suppressed_activity_types")
    |> validate_string_list_items(path, activity, "suppressed_activity_types")
  end

  defp validate_base(issues, path, activity) do
    issues
    |> validate_stable_ids(path, activity, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id",
      "source_window_id"
    ])
    |> expect_number(path, activity, "starts_at_s")
    |> expect_number(path, activity, "ends_at_s")
    |> expect_optional_type(path, activity, "type", :binary)
    |> expect_optional_type(path, activity, "activity_type", :binary)
    |> expect_optional_type(path, activity, "timeline_identity", :map)
    |> validate_interval(path, activity)
    |> validate_activity_type(path, activity)
    |> validate_timeline_identity(path, activity)
  end

  defp validate_timeline_identity(
         issues,
         path,
         %{
           "timeline_identity" => %{} = identity
         } = activity
       ) do
    issues
    |> validate_stable_ids(path <> ".timeline_identity", identity, [
      "activity_id",
      "scenario_id",
      "source_window_id",
      "subject_id",
      "timeline_id"
    ])
    |> expect_field_equals(
      path <> ".timeline_identity",
      identity,
      "activity_id",
      Map.get(activity, "id"),
      "must match activity id"
    )
    |> expect_field_equals(
      path <> ".timeline_identity",
      identity,
      "scenario_id",
      Map.get(activity, "scenario_id"),
      "must match activity scenario_id"
    )
    |> expect_field_equals(
      path <> ".timeline_identity",
      identity,
      "source_window_id",
      Map.get(activity, "source_window_id"),
      "must match activity source_window_id"
    )
    |> expect_field_equals(
      path <> ".timeline_identity",
      identity,
      "activity_type",
      effective_activity_type(activity),
      "must match activity type"
    )
  end

  defp validate_timeline_identity(issues, _path, _activity), do: issues

  defp require_activity_type_alias(issues, path, activity) do
    cond do
      present_string?(Map.get(activity, "type")) ->
        issues

      present_string?(Map.get(activity, "activity_type")) ->
        issues

      true ->
        [error(path, "must include type or activity_type") | issues]
    end
  end

  defp validate_activity_type(issues, path, activity) do
    case effective_activity_type(activity) do
      "observe" ->
        require_fields(issues, path, activity, ["target_id"])

      "downlink" ->
        issues
        |> require_fields(path, activity, ["ground_station_id"])
        |> OrbitalDynamics.Schema.ActivityContracts.validate_contact_fields(path, activity)

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
end
