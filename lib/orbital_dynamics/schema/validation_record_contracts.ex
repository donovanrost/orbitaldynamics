defmodule OrbitalDynamics.Schema.ValidationRecordContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation
  alias OrbitalDynamics.Schema.SchemaContractField
  alias OrbitalDynamics.Schema.StableIdValidation
  alias OrbitalDynamics.Schema.ValidationPolicyContracts

  def validate(issues, path, record) do
    issues
    |> PrimitiveValidation.expect_equal(path, record, "schema_contract", "validation_record.v1")
    |> validate_record_fields(path, record)
  end

  def validate_embedded(issues, path, record) do
    issues
    |> SchemaContractField.validate_optional(path, record, "validation_record.v1")
    |> validate_record_fields(path, record)
  end

  defp validate_record_fields(issues, path, record) do
    issues
    |> StableIdValidation.validate_stable_ids(path, record, ["id"])
    |> PrimitiveValidation.expect_type(path, record, "model", :binary)
    |> PrimitiveValidation.expect_type(path, record, "implementation", :binary)
    |> PrimitiveValidation.expect_type(path, record, "validation_level", :binary)
    |> PrimitiveValidation.expect_one_of(
      path,
      record,
      "validation_level",
      ValidationPolicyContracts.level_names()
    )
    |> PrimitiveValidation.expect_type(path, record, "covered_regime", :binary)
    |> PrimitiveValidation.expect_type(path, record, "evidence", :list)
    |> PrimitiveValidation.expect_type(path, record, "known_limits", :list)
    |> PrimitiveValidation.expect_type(path, record, "tolerances", :map)
    |> validate_tolerances(path <> ".tolerances", Map.get(record, "tolerances"))
    |> PrimitiveValidation.validate_string_list_items(path, record, "evidence")
    |> PrimitiveValidation.validate_string_list_items(path, record, "known_limits")
    |> validate_registered_fields(path, record)
  end

  defp validate_registered_fields(issues, path, record) do
    case OrbitalDynamics.Validation.record(Map.get(record, "id")) do
      {:ok, expected} ->
        issues
        |> PrimitiveValidation.expect_field_equals(
          path,
          record,
          "model",
          expected["model"],
          "must match registered validation record model"
        )
        |> PrimitiveValidation.expect_field_equals(
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

  defp validate_tolerances(issues, path, tolerances) when is_map(tolerances) do
    Enum.reduce(tolerances, issues, fn {field, value}, acc ->
      if (is_number(value) and value >= 0.0) or is_binary(value) do
        acc
      else
        [
          PrimitiveValidation.error("#{path}.#{field}", "must be a non-negative number or string")
          | acc
        ]
      end
    end)
  end

  defp validate_tolerances(issues, _path, _tolerances), do: issues
end
