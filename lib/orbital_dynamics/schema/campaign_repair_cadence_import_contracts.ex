defmodule OrbitalDynamics.Schema.CampaignRepairCadenceImportContracts do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.ReviewTypePolicy
  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate(issues, artifact) when is_map(artifact) do
    validate_manifest(
      issues,
      artifact,
      Map.get(artifact, "operator_review_package"),
      Map.get(artifact, "cadence_import_manifest")
    )
  end

  defp validate_manifest(issues, _artifact, _review_package, nil), do: issues
  defp validate_manifest(issues, _artifact, _review_package, :null), do: issues

  defp validate_manifest(issues, artifact, review_package, %{} = manifest) do
    issues
    |> validate_equal(
      "$.cadence_import_manifest.source_artifact_type",
      Map.get(manifest, "source_artifact_type"),
      "campaign_repair.v2",
      "must identify campaign_repair.v2"
    )
    |> validate_equal(
      "$.cadence_import_manifest.source_artifact_id",
      Map.get(manifest, "source_artifact_id"),
      repair_id(artifact),
      "must match the containing campaign repair ID"
    )
    |> validate_equal(
      "$.cadence_import_manifest.assumptions.row_source",
      assumption(manifest, "row_source"),
      "operator_review_package.rows",
      "must identify operator_review_package.rows"
    )
    |> validate_review_package(review_package, manifest)
  end

  defp validate_manifest(issues, _artifact, _review_package, _manifest), do: issues

  defp validate_review_package(issues, %{} = review_package, manifest) do
    review_rows = Map.get(review_package, "rows")
    import_review_rows = import_review_rows(review_rows)
    manifest_rows = Map.get(manifest, "rows")

    issues
    |> validate_equal(
      "$.cadence_import_manifest.row_count",
      Map.get(manifest, "row_count"),
      length(import_review_rows),
      "must match the import-eligible operator review count"
    )
    |> validate_equal(
      "$.cadence_import_manifest.provenance.source_review_count",
      provenance(manifest, "source_review_count"),
      Map.get(review_package, "review_count"),
      "must match the enclosing operator review count"
    )
    |> validate_review_row_ids(import_review_rows, manifest_rows)
  end

  defp validate_review_package(issues, _review_package, _manifest) do
    [
      PrimitiveValidation.error(
        "$.operator_review_package",
        "must be present when cadence_import_manifest sources operator_review_package.rows"
      )
      | issues
    ]
  end

  defp validate_review_row_ids(issues, review_rows, manifest_rows)
       when is_list(review_rows) and is_list(manifest_rows) do
    review_rows
    |> Enum.zip(manifest_rows)
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {{review_row, manifest_row}, index}, acc ->
      if is_map(review_row) and is_map(manifest_row) do
        validate_equal(
          acc,
          "$.cadence_import_manifest.rows[#{index}].source_review_row_id",
          Map.get(manifest_row, "source_review_row_id"),
          Map.get(review_row, "id"),
          "must match the operator review row at the same position"
        )
      else
        acc
      end
    end)
  end

  defp validate_review_row_ids(issues, _review_rows, _manifest_rows), do: issues

  defp import_review_rows(rows) when is_list(rows),
    do: Enum.filter(rows, &ReviewTypePolicy.import_manifest?/1)

  defp import_review_rows(_rows), do: []

  defp repair_id(%{"repair_metadata" => metadata}) when is_map(metadata),
    do: Map.get(metadata, "repair_id")

  defp repair_id(_artifact), do: nil

  defp assumption(%{"assumptions" => assumptions}, field) when is_map(assumptions),
    do: Map.get(assumptions, field)

  defp assumption(_manifest, _field), do: nil

  defp provenance(%{"provenance" => provenance}, field) when is_map(provenance),
    do: Map.get(provenance, field)

  defp provenance(_manifest, _field), do: nil

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [PrimitiveValidation.error(path, message) | issues]
end
