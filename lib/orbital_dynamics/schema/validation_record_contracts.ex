defmodule OrbitalDynamics.Schema.ValidationRecordContracts do
  @moduledoc false

  def validate(issues, path, record, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, record, "schema_contract", "validation_record.v1")
    |> validate_record_fields(callbacks, path, record)
  end

  def validate_embedded(issues, path, record, callbacks) when is_list(callbacks) do
    issues
    |> validate_optional_schema_contract(callbacks, path, record, "validation_record.v1")
    |> validate_record_fields(callbacks, path, record)
  end

  defp validate_record_fields(issues, callbacks, path, record) do
    issues
    |> validate_stable_ids(callbacks, path, record, ["id"])
    |> expect_type(callbacks, path, record, "model", :binary)
    |> expect_type(callbacks, path, record, "implementation", :binary)
    |> expect_type(callbacks, path, record, "validation_level", :binary)
    |> expect_one_of(
      callbacks,
      path,
      record,
      "validation_level",
      validation_level_names(callbacks)
    )
    |> expect_type(callbacks, path, record, "covered_regime", :binary)
    |> expect_type(callbacks, path, record, "evidence", :list)
    |> expect_type(callbacks, path, record, "known_limits", :list)
    |> expect_type(callbacks, path, record, "tolerances", :map)
    |> validate_tolerances(callbacks, path <> ".tolerances", Map.get(record, "tolerances"))
    |> validate_string_list_items(callbacks, path, record, "evidence")
    |> validate_string_list_items(callbacks, path, record, "known_limits")
    |> validate_registered_fields(callbacks, path, record)
  end

  defp validate_registered_fields(issues, callbacks, path, record) do
    case OrbitalDynamics.Validation.record(Map.get(record, "id")) do
      {:ok, expected} ->
        issues
        |> expect_field_equals(
          callbacks,
          path,
          record,
          "model",
          expected["model"],
          "must match registered validation record model"
        )
        |> expect_field_equals(
          callbacks,
          path,
          record,
          "known_limits",
          expected["known_limits"],
          "must match registered validation record known limits"
        )

      :error ->
        issues
    end
  end

  defp validate_tolerances(issues, callbacks, path, tolerances) when is_map(tolerances) do
    Enum.reduce(tolerances, issues, fn {field, value}, acc ->
      if (is_number(value) and value >= 0.0) or is_binary(value) do
        acc
      else
        [error(callbacks, "#{path}.#{field}", "must be a non-negative number or string") | acc]
      end
    end)
  end

  defp validate_tolerances(issues, _callbacks, _path, _tolerances), do: issues

  defp validate_optional_schema_contract(issues, callbacks, path, map, expected) do
    apply(Keyword.fetch!(callbacks, :validate_optional_schema_contract), [
      issues,
      path,
      map,
      expected
    ])
  end

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

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

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validation_level_names(callbacks),
    do: apply(Keyword.fetch!(callbacks, :validation_tolerance_policy_level_names), [])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
