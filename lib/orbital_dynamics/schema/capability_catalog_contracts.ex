defmodule OrbitalDynamics.Schema.CapabilityCatalogContracts do
  @moduledoc false

  def validate(issues, path, artifact, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, artifact, "schema_contract", "capability_catalog.v1")
    |> expect_equal(callbacks, path, artifact, "schema_version", 1)
    |> expect_equal(callbacks, path, artifact, "model", "public_capability_catalog")
    |> expect_type(callbacks, path, artifact, "analysis", :map)
    |> expect_type(callbacks, path, artifact, "planning", :map)
    |> expect_type(callbacks, path, artifact, "operations", :map)
    |> expect_type(callbacks, path, artifact, "environment", :map)
    |> expect_type(callbacks, path, artifact, "constraints", :map)
    |> expect_type(callbacks, path, artifact, "validation", :map)
    |> expect_type(callbacks, path, artifact, "reporting", :map)
    |> validate_schema_section(callbacks, artifact)
  end

  defp validate_schema_section(issues, callbacks, artifact) do
    schema = get_in(artifact, ["validation", "schema"])

    issues =
      if is_map(schema) do
        issues
        |> require_fields(callbacks, "$.validation.schema", schema, [
          "artifact_contracts",
          "artifact_contract_count",
          "compatibility_policy_version",
          "identity_policy_version",
          "known_limits"
        ])
        |> expect_type(callbacks, "$.validation.schema", schema, "artifact_contracts", :list)
        |> expect_type(
          callbacks,
          "$.validation.schema",
          schema,
          "artifact_contract_count",
          :integer
        )
        |> expect_type(
          callbacks,
          "$.validation.schema",
          schema,
          "compatibility_policy_version",
          :integer
        )
        |> expect_type(
          callbacks,
          "$.validation.schema",
          schema,
          "identity_policy_version",
          :integer
        )
        |> expect_type(callbacks, "$.validation.schema", schema, "known_limits", :list)
        |> expect_field_equals(
          callbacks,
          "$.validation.schema",
          schema,
          "artifact_contract_count",
          length(Map.get(schema, "artifact_contracts", []))
        )
      else
        [error(callbacks, "$.validation.schema", "must be an object") | issues]
      end

    validate_contract_list(issues, callbacks, schema)
  end

  defp validate_contract_list(issues, callbacks, %{} = schema) do
    case Map.get(schema, "artifact_contracts") do
      contracts when is_list(contracts) ->
        issues =
          contracts
          |> Enum.with_index()
          |> Enum.reduce(issues, fn {contract, index}, acc ->
            cond do
              not is_binary(contract) ->
                [
                  error(
                    callbacks,
                    "$.validation.schema.artifact_contracts[#{index}]",
                    "must be a string"
                  )
                  | acc
                ]

              not known_contract?(callbacks, contract) ->
                [
                  error(
                    callbacks,
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
          callbacks,
          "$.validation.schema",
          schema,
          "artifact_contracts",
          contract_names(callbacks),
          "must match executable contract registry"
        )

      _contracts ->
        issues
    end
  end

  defp validate_contract_list(issues, _callbacks, _schema), do: issues

  defp contract_names(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contract_names), [])

  defp known_contract?(callbacks, contract),
    do: apply(Keyword.fetch!(callbacks, :known_contract?), [contract])

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals), [issues, path, map, field, expected])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
