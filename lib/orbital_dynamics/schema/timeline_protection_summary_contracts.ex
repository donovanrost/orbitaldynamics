defmodule OrbitalDynamics.Schema.TimelineProtectionSummaryContracts do
  @moduledoc false

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

  def validate_optional_summary(issues, path, map, field, callbacks)
      when is_map(map) and is_list(callbacks) do
    case Map.get(map, field) do
      %{} = protection -> validate_summary(issues, "#{path}.#{field}", protection, callbacks)
      _value -> issues
    end
  end

  def validate_summary(issues, path, protection, callbacks) when is_list(callbacks) do
    issues
    |> validate_counts(path, protection, callbacks)
    |> validate_activity_ids(path, protection, callbacks)
  end

  defp validate_counts(issues, path, protection, callbacks) do
    Enum.reduce(@count_fields, issues, fn field, acc ->
      acc
      |> expect_optional_integer(callbacks, path, protection, field)
      |> expect_field_at_least(callbacks, path, protection, field, 0)
    end)
  end

  defp validate_activity_ids(issues, path, protection, callbacks) do
    Enum.reduce(@activity_id_fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(callbacks, path, protection, field, :list)
      |> validate_optional_stable_id_list(callbacks, path, protection, field)
    end)
  end

  defp expect_optional_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_at_least(issues, callbacks, path, map, field, minimum),
    do:
      apply(require_callback(callbacks, :expect_field_at_least), [
        issues,
        path,
        map,
        field,
        minimum
      ])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [
        issues,
        path,
        map,
        field,
        type
      ])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
