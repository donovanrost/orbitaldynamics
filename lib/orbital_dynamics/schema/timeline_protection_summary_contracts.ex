defmodule OrbitalDynamics.Schema.TimelineProtectionSummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation
  alias OrbitalDynamics.Schema.StableIdValidation

  @count_fields [
    "preserved_locked_or_approved_count",
    "preserved_executed_count",
    "changed_locked_or_approved_count",
    "changed_executed_count"
  ]

  @activity_id_fields [
    "preserved_locked_or_approved_activity_ids",
    "preserved_executed_activity_ids",
    "changed_locked_or_approved_activity_ids",
    "changed_executed_activity_ids"
  ]

  def validate_optional_summary(issues, path, map, field) when is_map(map) do
    case Map.get(map, field) do
      %{} = protection -> validate_summary(issues, "#{path}.#{field}", protection)
      _value -> issues
    end
  end

  def validate_summary(issues, path, protection) do
    issues
    |> validate_counts(path, protection)
    |> validate_activity_ids(path, protection)
  end

  defp validate_counts(issues, path, protection) do
    Enum.reduce(@count_fields, issues, fn field, acc ->
      acc
      |> PrimitiveValidation.expect_optional_integer(path, protection, field)
      |> PrimitiveValidation.expect_field_at_least(path, protection, field, 0)
    end)
  end

  defp validate_activity_ids(issues, path, protection) do
    Enum.reduce(@activity_id_fields, issues, fn field, acc ->
      acc
      |> PrimitiveValidation.expect_optional_type(path, protection, field, :list)
      |> StableIdValidation.validate_optional_stable_id_list(path, protection, field)
    end)
  end
end
