defmodule OrbitalDynamics.Schema.ResourceSummaryContracts do
  @moduledoc false

  def validate(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, summary, ["schema_contract", "spacecraft_id"])
    |> validate_stable_ids(callbacks, path, summary, ["spacecraft_id"])
    |> expect_equal(callbacks, path, summary, "schema_contract", "resource_summary.v1")
    |> expect_optional_type(callbacks, path, summary, "mode", :binary)
    |> expect_optional_probability(callbacks, path, summary, "fuel_margin")
    |> expect_optional_probability(callbacks, path, summary, "power_margin")
    |> expect_optional_non_negative_number(callbacks, path, summary, "battery_capacity_wh")
    |> expect_optional_non_negative_number(callbacks, path, summary, "battery_energy_used_wh")
    |> expect_optional_non_negative_number(
      callbacks,
      path,
      summary,
      "battery_energy_generated_wh"
    )
    |> expect_optional_probability(callbacks, path, summary, "battery_state_of_charge")
    |> expect_optional_number(callbacks, path, summary, "thermal_margin_c")
    |> expect_optional_non_negative_number(callbacks, path, summary, "storage_capacity_mb")
    |> expect_optional_non_negative_number(callbacks, path, summary, "storage_used_mb")
    |> expect_optional_probability(callbacks, path, summary, "storage_margin")
    |> expect_optional_non_negative_number(callbacks, path, summary, "downlink_capacity_mb")
    |> expect_optional_probability(callbacks, path, summary, "downlink_margin")
    |> expect_optional_type(callbacks, path, summary, "spacecraft_available", :boolean)
    |> expect_optional_type(callbacks, path, summary, "source_quality", :binary)
    |> expect_optional_type(callbacks, path, summary, "trust_boundary", :binary)
    |> expect_optional_type(callbacks, path, summary, "suppressed_activity_types", :list)
    |> validate_string_list_items(callbacks, path, summary, "suppressed_activity_types")
    |> expect_optional_type(callbacks, path, summary, "incompatible_activity_types", :list)
    |> validate_string_list_items(callbacks, path, summary, "incompatible_activity_types")
    |> expect_optional_type(callbacks, path, summary, "payload_available", :boolean)
    |> expect_optional_type(callbacks, path, summary, "antenna_available", :boolean)
    |> expect_optional_type(callbacks, path, summary, "degraded", :boolean)
    |> expect_optional_type(callbacks, path, summary, "assumptions", :map)
    |> expect_optional_type(callbacks, path, summary, "provenance", :map)
    |> validate_derived_margins(callbacks, path, summary)
  end

  defp validate_derived_margins(issues, callbacks, path, summary) do
    issues
    |> validate_derived_margin(
      callbacks,
      path,
      summary,
      "battery_state_of_charge",
      "battery_capacity_wh",
      "battery_energy_used_wh"
    )
    |> validate_derived_margin(
      callbacks,
      path,
      summary,
      "storage_margin",
      "storage_capacity_mb",
      "storage_used_mb"
    )
  end

  defp validate_derived_margin(
         issues,
         callbacks,
         path,
         summary,
         margin_field,
         capacity_field,
         used_field
       ) do
    margin = Map.get(summary, margin_field)
    capacity = Map.get(summary, capacity_field)
    used = Map.get(summary, used_field)

    if is_number(margin) and is_number(capacity) and capacity > 0 and is_number(used) do
      expected = max((capacity - used) / capacity, 0.0)

      if abs(margin - expected) <= 1.0e-9 do
        issues
      else
        [
          error(
            callbacks,
            path <> "." <> margin_field,
            "must equal #{capacity_field}/#{used_field}-derived #{margin_field}"
          )
          | issues
        ]
      end
    else
      issues
    end
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

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

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])
end
