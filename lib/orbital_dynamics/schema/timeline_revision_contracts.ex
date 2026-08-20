defmodule OrbitalDynamics.Schema.TimelineRevisionContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [error: 2, expect_equal: 5, expect_type: 5]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  @schema_contract "timeline_revision.v1"
  @identity_scheme "sha256_canonical_json"
  @canonicalization "timeline_revision_content.v1"
  @revision_id_prefix "timeline_revision.sha256:"
  @batch_id_prefix "timeline_transition_batch.sha256:"

  def validate_optional(issues, _path, value) when value in [nil, :null], do: issues

  def validate_optional(issues, path, %{} = evidence),
    do: validate(issues, path, evidence)

  def validate_optional(issues, path, _evidence),
    do: [error(path, "must be an object") | issues]

  def validate(issues, path, evidence) do
    issues
    |> expect_equal(path, evidence, "schema_contract", @schema_contract)
    |> expect_equal(path, evidence, "identity_scheme", @identity_scheme)
    |> expect_equal(path, evidence, "canonicalization", @canonicalization)
    |> expect_type(path, evidence, "prior_revision_id", :binary)
    |> expect_type(path, evidence, "transition_batch_id", :binary)
    |> expect_type(path, evidence, "replacement_revision_id", :binary)
    |> validate_stable_ids(path, evidence, [
      "prior_revision_id",
      "transition_batch_id",
      "replacement_revision_id"
    ])
    |> validate_content_id(
      path <> ".prior_revision_id",
      Map.get(evidence, "prior_revision_id"),
      @revision_id_prefix
    )
    |> validate_content_id(
      path <> ".transition_batch_id",
      Map.get(evidence, "transition_batch_id"),
      @batch_id_prefix
    )
    |> validate_content_id(
      path <> ".replacement_revision_id",
      Map.get(evidence, "replacement_revision_id"),
      @revision_id_prefix
    )
  end

  def validate_row_copies(issues, path, report, row_field) do
    evidence = Map.get(report, "timeline_revision")

    report
    |> Map.get(row_field, [])
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{} = row, index}, acc ->
        validate_row_copy(
          acc,
          "#{path}.#{row_field}[#{index}].timeline_revision",
          Map.get(row, "timeline_revision"),
          evidence
        )

      {_row, _index}, acc ->
        acc
    end)
  end

  def json_schema do
    stable_id_pattern = OrbitalDynamics.Schema.StableIdValidation.pattern()

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "schema_contract",
        "identity_scheme",
        "canonicalization",
        "prior_revision_id",
        "transition_batch_id",
        "replacement_revision_id"
      ],
      "properties" => %{
        "schema_contract" => %{"type" => "string", "const" => @schema_contract},
        "identity_scheme" => %{"type" => "string", "const" => @identity_scheme},
        "canonicalization" => %{"type" => "string", "const" => @canonicalization},
        "prior_revision_id" => content_id_schema(@revision_id_prefix, stable_id_pattern),
        "transition_batch_id" => content_id_schema(@batch_id_prefix, stable_id_pattern),
        "replacement_revision_id" => content_id_schema(@revision_id_prefix, stable_id_pattern)
      }
    }
  end

  defp validate_row_copy(issues, _path, nil, nil), do: issues

  defp validate_row_copy(issues, path, nil, %{}),
    do: [error(path, "must equal report timeline_revision evidence") | issues]

  defp validate_row_copy(issues, path, %{}, nil),
    do: [error(path, "must be omitted when report timeline_revision evidence is absent") | issues]

  defp validate_row_copy(issues, _path, evidence, evidence), do: issues

  defp validate_row_copy(issues, path, _row_evidence, _report_evidence),
    do: [error(path, "must equal report timeline_revision evidence") | issues]

  defp validate_content_id(issues, path, value, prefix) when is_binary(value) do
    digest_size = 64

    if String.starts_with?(value, prefix) and byte_size(value) == byte_size(prefix) + digest_size and
         String.match?(binary_part(value, byte_size(prefix), digest_size), ~r/^[0-9a-f]{64}$/) do
      issues
    else
      [error(path, "must be a canonical SHA-256 content identity") | issues]
    end
  end

  defp validate_content_id(issues, _path, _value, _prefix), do: issues

  defp content_id_schema(prefix, stable_id_pattern) do
    %{
      "type" => "string",
      "pattern" => "^(?:#{Regex.escape(prefix)})[0-9a-f]{64}$",
      "x-stable-id-pattern" => stable_id_pattern
    }
  end
end
