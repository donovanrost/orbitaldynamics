defmodule OrbitalDynamics.Schema.ResourceSummaryContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_optional_non_negative_number: 4,
      expect_optional_number: 4,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate(issues, path, summary) do
    issues
    |> require_fields(path, summary, ["schema_contract", "spacecraft_id"])
    |> validate_stable_ids(path, summary, ["spacecraft_id"])
    |> expect_equal(path, summary, "schema_contract", "resource_summary.v1")
    |> expect_optional_type(path, summary, "mode", :binary)
    |> expect_optional_probability(path, summary, "fuel_margin")
    |> expect_optional_probability(path, summary, "power_margin")
    |> expect_optional_non_negative_number(path, summary, "battery_capacity_wh")
    |> expect_optional_non_negative_number(path, summary, "battery_energy_used_wh")
    |> expect_optional_non_negative_number(
      path,
      summary,
      "battery_energy_generated_wh"
    )
    |> expect_optional_probability(path, summary, "battery_state_of_charge")
    |> expect_optional_number(path, summary, "thermal_margin_c")
    |> expect_optional_non_negative_number(path, summary, "storage_capacity_mb")
    |> expect_optional_non_negative_number(path, summary, "storage_used_mb")
    |> expect_optional_probability(path, summary, "storage_margin")
    |> expect_optional_non_negative_number(path, summary, "downlink_capacity_mb")
    |> expect_optional_probability(path, summary, "downlink_margin")
    |> expect_optional_type(path, summary, "spacecraft_available", :boolean)
    |> expect_optional_type(path, summary, "source_quality", :binary)
    |> expect_optional_type(path, summary, "trust_boundary", :binary)
    |> expect_optional_type(path, summary, "suppressed_activity_types", :list)
    |> validate_string_list_items(path, summary, "suppressed_activity_types")
    |> expect_optional_type(path, summary, "incompatible_activity_types", :list)
    |> validate_string_list_items(path, summary, "incompatible_activity_types")
    |> expect_optional_type(path, summary, "payload_available", :boolean)
    |> expect_optional_type(path, summary, "antenna_available", :boolean)
    |> expect_optional_type(path, summary, "degraded", :boolean)
    |> expect_optional_type(path, summary, "assumptions", :map)
    |> expect_optional_type(path, summary, "provenance", :map)
    |> validate_derived_margins(path, summary)
  end

  defp validate_derived_margins(issues, path, summary) do
    issues
    |> validate_derived_margin(
      path,
      summary,
      "battery_state_of_charge",
      "battery_capacity_wh",
      "battery_energy_used_wh"
    )
    |> validate_derived_margin(
      path,
      summary,
      "storage_margin",
      "storage_capacity_mb",
      "storage_used_mb"
    )
  end

  defp validate_derived_margin(
         issues,
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
end
