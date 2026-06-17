defmodule OrbitalDynamics.Schema.RealizedActivityContracts do
  @moduledoc false

  @stable_id_fields [
    "id",
    "planned_activity_id",
    "timeline_id",
    "ground_station_id",
    "station_id",
    "target_id",
    "spacecraft_id",
    "satellite_id",
    "source_window_id",
    "resource_id",
    "collection_id",
    "product_id",
    "payload_id",
    "instrument_id",
    "pointing_target_id",
    "attitude_target_id",
    "thermal_zone_id"
  ]

  @binary_fields [
    "type",
    "activity_type",
    "direction",
    "resource_source_quality",
    "resource_trust_boundary",
    "resource_trust_boundary_status",
    "resource_blocking_dimension",
    "mode",
    "downlink_requirement_status",
    "downlink_completion_source",
    "contact_result",
    "contact_success_factor_source",
    "command_success_factor_source",
    "command_authority_status",
    "required_authority",
    "command_safety_status",
    "observation_result",
    "observation_success_factor_source",
    "image_quality_status",
    "image_quality_source",
    "maneuver_result",
    "maneuver_success_factor_source",
    "feedback_weight_source",
    "execution_uncertainty_status",
    "execution_uncertainty_source",
    "pointing_mode",
    "boresight_axis",
    "pointing_status",
    "pointing_model",
    "pointing_source",
    "attitude_mode",
    "attitude_status",
    "attitude_model",
    "attitude_source",
    "thermal_status",
    "thermal_model",
    "thermal_source",
    "lighting_condition",
    "lighting_condition_detail",
    "lighting_condition_model",
    "lighting_detail_model",
    "link_protocol",
    "frequency_band",
    "modulation",
    "coding_scheme",
    "polarization",
    "link_quality_status",
    "command_result",
    "reason",
    "provider",
    "adapter",
    "adapter_version",
    "trust_boundary",
    "received_at",
    "ingested_at"
  ]

  @boolean_fields [
    "spacecraft_available",
    "payload_available",
    "antenna_available",
    "degraded",
    "command_authorized",
    "command_safety_checked",
    "observation_success",
    "maneuver_success",
    "carrier_lock",
    "symbol_lock",
    "contact_success",
    "command_success"
  ]

  @map_fields [
    "resource_provenance",
    "execution_uncertainty",
    "maneuver_execution_uncertainty",
    "source",
    "provenance",
    "metadata"
  ]

  @string_list_fields [
    "incompatible_activity_types",
    "suppressed_activity_types",
    "downlink_completion_sources"
  ]

  @probability_fields [
    "fuel_margin",
    "power_margin",
    "storage_margin",
    "downlink_margin",
    "battery_state_of_charge",
    "contact_success_factor",
    "command_success_factor",
    "observation_success_factor",
    "image_quality_score",
    "cloud_cover_fraction",
    "blur_score",
    "maneuver_success_factor",
    "pointing_confidence",
    "attitude_confidence",
    "thermal_confidence",
    "eclipse_overlap_fraction",
    "bit_error_rate",
    "packet_loss_rate",
    "frame_loss_rate",
    "completed_fraction"
  ]

  @non_negative_number_fields [
    "battery_capacity_wh",
    "battery_energy_used_wh",
    "battery_energy_generated_wh"
  ]

  @number_fields [
    "data_volume_mb",
    "planned_data_volume_mb",
    "planned_volume_mb",
    "actual_data_volume_mb",
    "actual_volume_mb",
    "estimated_data_volume_mb",
    "estimated_storage_mb",
    "estimated_downlink_mb",
    "required_downlink_mb",
    "required_volume_mb",
    "required_data_volume_mb",
    "target_downlink_mb",
    "target_volume_mb",
    "target_data_volume_mb",
    "min_downlink_mb",
    "selected_downlink_mb",
    "selected_data_volume_mb",
    "selected_volume_mb",
    "delivered_data_volume_mb",
    "received_data_volume_mb",
    "selected_downlink_shortfall_mb",
    "selected_data_volume_shortfall_mb",
    "data_volume_shortfall_mb",
    "actual_data_volume_shortfall_mb",
    "missing_data_volume_mb",
    "required_data_volume_gap_mb",
    "collection_ends_at_s",
    "planned_delivery_at_s",
    "actual_delivery_at_s",
    "max_latency_s",
    "planned_latency_s",
    "actual_latency_s",
    "planned_estimated_throughput_mb",
    "target_priority",
    "feedback_weight",
    "delta_v_magnitude_km_s",
    "timing_3sigma_s",
    "delta_v_3sigma_magnitude_km_s",
    "off_nadir_angle_deg",
    "slew_angle_deg",
    "slew_rate_deg_s",
    "pointing_error_deg",
    "roll_deg",
    "pitch_deg",
    "yaw_deg",
    "attitude_error_deg",
    "temperature_c",
    "planned_temperature_c",
    "actual_temperature_c",
    "min_operating_temperature_c",
    "max_operating_temperature_c",
    "thermal_margin_c",
    "eclipse_overlap_s",
    "data_rate_mbps",
    "downlink_rate_mbps",
    "data_rate_mb_s",
    "downlink_rate_mb_s",
    "actual_data_rate_mbps",
    "actual_downlink_rate_mbps",
    "actual_data_rate_mb_s",
    "actual_downlink_rate_mb_s",
    "delivered_rate_mbps",
    "received_rate_mbps",
    "delivered_rate_mb_s",
    "received_rate_mb_s",
    "link_margin_db",
    "snr_db",
    "eb_no_db",
    "actual_starts_at_s",
    "actual_ends_at_s",
    "actual_duration_s",
    "actual_contact_duration_s",
    "contact_duration_s",
    "actual_throughput_mb"
  ]

  @number_vector_fields [
    "delta_v_km_s",
    "actual_delta_v_km_s",
    "executed_delta_v_km_s",
    "delta_v_3sigma_km_s"
  ]

  def validate(issues, path, activity, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, activity, ["schema_contract", "id", "status"])
    |> validate_stable_ids(callbacks, path, activity, @stable_id_fields)
    |> validate_identity_objects(callbacks, path, activity)
    |> expect_equal(callbacks, path, activity, "schema_contract", "realized_activity.v1")
    |> expect_one_of(callbacks, path, activity, "status", [
      "completed",
      "executed",
      "partial",
      "missed",
      "failed",
      "delayed",
      "canceled",
      "cancelled",
      "rejected"
    ])
    |> validate_optional_types(callbacks, path, activity, @binary_fields, :binary)
    |> validate_optional_types(callbacks, path, activity, @boolean_fields, :boolean)
    |> validate_optional_types(callbacks, path, activity, @map_fields, :map)
    |> validate_optional_lists(callbacks, path, activity, @string_list_fields)
    |> expect_optional_list(callbacks, path, activity, "product_ids")
    |> validate_optional_stable_id_list(callbacks, path, activity, "product_ids")
    |> validate_optional_probabilities(callbacks, path, activity, @probability_fields)
    |> validate_optional_non_negative_numbers(
      callbacks,
      path,
      activity,
      @non_negative_number_fields
    )
    |> validate_optional_numbers(callbacks, path, activity, @number_fields)
    |> validate_optional_number_vectors(callbacks, path, activity, @number_vector_fields)
    |> validate_optional_execution_uncertainty(callbacks, path, activity, "execution_uncertainty")
    |> validate_optional_execution_uncertainty(
      callbacks,
      path,
      activity,
      "maneuver_execution_uncertainty"
    )
    |> expect_optional_number_or_string(callbacks, path, activity, "lighting_confidence")
    |> validate_stable_ids(callbacks, path, activity, ["external_id"])
    |> validate_metadata_identity(callbacks, path, activity)
    |> require_provider_trust_boundary(callbacks, path, activity)
  end

  defp validate_optional_types(issues, callbacks, path, map, fields, type) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_type(acc, callbacks, path, map, field, type)
    end)
  end

  defp validate_optional_lists(issues, callbacks, path, map, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      acc
      |> expect_optional_list(callbacks, path, map, field)
      |> validate_string_list_items(callbacks, path, map, field)
    end)
  end

  defp validate_optional_probabilities(issues, callbacks, path, map, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_probability(acc, callbacks, path, map, field)
    end)
  end

  defp validate_optional_non_negative_numbers(issues, callbacks, path, map, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_non_negative_number(acc, callbacks, path, map, field)
    end)
  end

  defp validate_optional_numbers(issues, callbacks, path, map, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_number(acc, callbacks, path, map, field)
    end)
  end

  defp validate_optional_number_vectors(issues, callbacks, path, map, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_number_vector(acc, callbacks, path, map, field)
    end)
  end

  defp validate_metadata_identity(
         issues,
         callbacks,
         path,
         %{"metadata" => %{} = metadata} = activity
       ) do
    issues
    |> expect_field_equals_with_message(
      callbacks,
      path <> ".metadata",
      metadata,
      "planned_activity_id",
      Map.get(activity, "planned_activity_id"),
      "must match top-level planned_activity_id"
    )
    |> expect_field_equals_with_message(
      callbacks,
      path <> ".metadata",
      metadata,
      "planned_timeline_id",
      Map.get(activity, "timeline_id"),
      "must match top-level timeline_id"
    )
  end

  defp validate_metadata_identity(issues, _callbacks, _path, _activity), do: issues

  defp require_provider_trust_boundary(issues, callbacks, path, activity) do
    provider_context_fields = ["provider", "adapter", "adapter_version", "external_id"]

    provider_context? =
      Enum.any?(provider_context_fields, fn field ->
        case Map.get(activity, field) do
          value when is_binary(value) -> value != ""
          _value -> false
        end
      end)

    trust_boundary = Map.get(activity, "trust_boundary")
    provenance_trust_boundary = get_in(activity, ["provenance", "trust_boundary"])

    cond do
      not provider_context? ->
        issues

      Map.get(activity, "external_id") in [nil, ""] ->
        [
          error(callbacks, path <> ".external_id", "is required for provider realized feedback")
          | issues
        ]

      is_binary(trust_boundary) and trust_boundary != "" ->
        issues

      is_binary(provenance_trust_boundary) and provenance_trust_boundary != "" ->
        issues

      true ->
        [
          error(
            callbacks,
            path <> ".trust_boundary",
            "provider realized feedback requires trust_boundary or provenance.trust_boundary"
          )
          | issues
        ]
    end
  end

  defp validate_identity_objects(issues, callbacks, path, activity) do
    issues
    |> validate_identity_object(callbacks, path, activity, "target", ["id", "target_id"])
    |> validate_identity_object(callbacks, path, activity, "station", [
      "id",
      "station_id",
      "ground_station_id"
    ])
    |> validate_identity_object(callbacks, path, activity, "ground_station", [
      "id",
      "station_id",
      "ground_station_id"
    ])
    |> validate_identity_object(callbacks, path, activity, "spacecraft", [
      "id",
      "spacecraft_id",
      "satellite_id"
    ])
    |> validate_identity_object(callbacks, path, activity, "satellite", [
      "id",
      "spacecraft_id",
      "satellite_id"
    ])
  end

  defp validate_identity_object(issues, callbacks, path, activity, field, identity_fields) do
    case Map.get(activity, field) do
      nil ->
        issues

      %{} = identity ->
        validate_stable_ids(issues, callbacks, "#{path}.#{field}", identity, identity_fields)

      _value ->
        [error(callbacks, "#{path}.#{field}", "must be a map") | issues]
    end
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_list(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_list), [issues, path, map, field])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_probability(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_probability), [issues, path, map, field])

  defp expect_optional_non_negative_number(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_number), [
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

  defp validate_optional_execution_uncertainty(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_execution_uncertainty), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_number_or_string(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_number_or_string), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_equals_with_message(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])
end
