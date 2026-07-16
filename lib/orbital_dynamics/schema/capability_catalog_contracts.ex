defmodule OrbitalDynamics.Schema.CapabilityCatalogContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_type: 5,
      require_fields: 4
    ]

  alias OrbitalDynamics.Schema.Registry

  def validate(issues, path, artifact, contracts) when is_map(contracts) do
    issues
    |> expect_equal(path, artifact, "schema_contract", "capability_catalog.v1")
    |> expect_equal(path, artifact, "schema_version", 1)
    |> expect_equal(path, artifact, "model", "public_capability_catalog")
    |> expect_type(path, artifact, "analysis", :map)
    |> expect_type(path, artifact, "planning", :map)
    |> expect_type(path, artifact, "operations", :map)
    |> expect_type(path, artifact, "environment", :map)
    |> expect_type(path, artifact, "constraints", :map)
    |> expect_type(path, artifact, "validation", :map)
    |> expect_type(path, artifact, "reporting", :map)
    |> validate_schema_section(artifact, contracts)
  end

  defp validate_schema_section(issues, artifact, contracts) do
    schema = get_in(artifact, ["validation", "schema"])

    issues =
      if is_map(schema) do
        artifact_contract_count = length(Map.get(schema, "artifact_contracts", []))

        issues
        |> require_fields("$.validation.schema", schema, [
          "artifact_contracts",
          "artifact_contract_count",
          "compatibility_policy_version",
          "identity_policy_version",
          "known_limits"
        ])
        |> expect_type("$.validation.schema", schema, "artifact_contracts", :list)
        |> expect_type("$.validation.schema", schema, "artifact_contract_count", :integer)
        |> expect_type("$.validation.schema", schema, "compatibility_policy_version", :integer)
        |> expect_type("$.validation.schema", schema, "identity_policy_version", :integer)
        |> expect_type("$.validation.schema", schema, "known_limits", :list)
        |> expect_field_equals(
          "$.validation.schema",
          schema,
          "artifact_contract_count",
          artifact_contract_count,
          "must equal #{artifact_contract_count}"
        )
      else
        [error("$.validation.schema", "must be an object") | issues]
      end

    validate_contract_list(issues, schema, contracts)
  end

  defp validate_contract_list(issues, %{} = schema, contracts) do
    case Map.get(schema, "artifact_contracts") do
      contract_names when is_list(contract_names) ->
        issues =
          contract_names
          |> Enum.with_index()
          |> Enum.reduce(issues, fn {contract, index}, acc ->
            cond do
              not is_binary(contract) ->
                [
                  error(
                    "$.validation.schema.artifact_contracts[#{index}]",
                    "must be a string"
                  )
                  | acc
                ]

              not Registry.known?(contracts, contract) ->
                [
                  error(
                    "$.validation.schema.artifact_contracts[#{index}]",
                    "must be a known executable contract"
                  )
                  | acc
                ]

              true ->
                acc
            end
          end)

        expect_field_equals(
          issues,
          "$.validation.schema",
          schema,
          "artifact_contracts",
          Registry.names(contracts),
          "must match executable contract registry"
        )

      _contract_names ->
        issues
    end
  end

  defp validate_contract_list(issues, _schema, _contracts), do: issues
end
