defmodule OrbitalDynamics.Schema.CampaignStrategyCadenceImportContracts do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.ReviewTypePolicy

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate(
        issues,
        %{
          "cadence_import_manifest" => %{"rows" => rows} = manifest,
          "branch_comparison_report" => %{"rows" => comparison_rows}
        } = artifact
      )
      when is_list(rows) and is_list(comparison_rows) do
    if Enum.all?(rows, &is_map/1) and Enum.all?(comparison_rows, &is_map/1) do
      branch_rows =
        Enum.filter(rows, &(Map.get(&1, "source_review_type") == "strategy_branch_comparison"))

      issues
      |> validate_manifest_fields(manifest, artifact, comparison_rows)
      |> validate_branch_comparison_sources(branch_rows, comparison_rows)
      |> validate_recommendation_sources(branch_rows, Map.get(artifact, "recommendation"))
      |> validate_operator_review_sources(rows, Map.get(artifact, "operator_review_package"))
    else
      issues
    end
  end

  def validate(issues, _artifact), do: issues

  defp validate_manifest_fields(issues, manifest, artifact, comparison_rows) do
    provenance =
      case Map.get(manifest, "provenance") do
        %{} = value -> value
        _value -> %{}
      end

    issues
    |> validate_equal(
      "$.cadence_import_manifest.source_artifact_type",
      manifest["source_artifact_type"],
      "campaign_strategy.v3",
      "must identify the enclosing CampaignStrategy artifact type"
    )
    |> validate_equal(
      "$.cadence_import_manifest.source_artifact_id",
      manifest["source_artifact_id"],
      get_in(artifact, ["strategy_metadata", "strategy_id"]),
      "must match the enclosing CampaignStrategy strategy ID"
    )
    |> validate_equal(
      "$.cadence_import_manifest.provenance.source_artifact_type",
      provenance["source_artifact_type"],
      "campaign_strategy.v3",
      "must identify the enclosing CampaignStrategy artifact type"
    )
    |> validate_equal(
      "$.cadence_import_manifest.provenance.source_artifact_id",
      provenance["source_artifact_id"],
      get_in(artifact, ["strategy_metadata", "strategy_id"]),
      "must match the enclosing CampaignStrategy strategy ID"
    )
    |> validate_optional_provenance_copy(
      provenance,
      Map.get(artifact, "provenance"),
      "source_plan_id",
      "$.cadence_import_manifest.provenance.source_plan_id",
      "must match the enclosing CampaignStrategy source plan ID"
    )
    |> validate_optional_provenance_copy(
      provenance,
      Map.get(artifact, "provenance"),
      "source_repair_id",
      "$.cadence_import_manifest.provenance.source_repair_id",
      "must match the enclosing CampaignStrategy source repair ID"
    )
    |> validate_equal(
      "$.cadence_import_manifest.provenance.recommended_branch_id",
      provenance["recommended_branch_id"],
      get_in(artifact, ["recommendation", "recommended_branch_id"]),
      "must match the enclosing CampaignStrategy recommended branch ID"
    )
    |> validate_equal(
      "$.cadence_import_manifest.provenance.source_branch_count",
      provenance["source_branch_count"],
      length(comparison_rows),
      "must match the enclosing CampaignStrategy branch comparison row count"
    )
    |> validate_embedded_package_fields(provenance, Map.get(artifact, "operator_review_package"))
  end

  defp validate_optional_provenance_copy(
         issues,
         manifest_provenance,
         %{} = source_provenance,
         field,
         path,
         message
       ) do
    if Map.has_key?(source_provenance, field) do
      validate_equal(issues, path, manifest_provenance[field], source_provenance[field], message)
    else
      issues
    end
  end

  defp validate_optional_provenance_copy(
         issues,
         _manifest_provenance,
         _source_provenance,
         _field,
         _path,
         _message
       ),
       do: issues

  defp validate_embedded_package_fields(
         issues,
         provenance,
         %{"rows" => rows} = package
       )
       when is_list(rows) do
    issues
    |> validate_equal(
      "$.cadence_import_manifest.provenance.source_review_count",
      provenance["source_review_count"],
      package["review_count"] || length(rows),
      "must match the enclosing CampaignStrategy operator-review count"
    )
    |> validate_equal(
      "$.cadence_import_manifest.provenance.operator_review_package_source",
      provenance["operator_review_package_source"],
      "embedded",
      "must identify the enclosing CampaignStrategy operator-review package"
    )
  end

  defp validate_embedded_package_fields(issues, _provenance, _package), do: issues

  defp validate_branch_comparison_sources(issues, branch_rows, comparison_rows) do
    expected =
      Enum.sort_by(comparison_rows, &{Map.get(&1, "rank", 0), Map.get(&1, "branch_id", "")})

    validate_equal(
      issues,
      "$.cadence_import_manifest.rows",
      Enum.map(branch_rows, &Map.get(&1, "source_branch_comparison")),
      expected,
      "must preserve the complete ordered CampaignStrategy branch comparison rows"
    )
  end

  defp validate_recommendation_sources(issues, branch_rows, %{} = recommendation) do
    validate_equal(
      issues,
      "$.cadence_import_manifest.rows",
      Enum.map(branch_rows, &Map.get(&1, "source_recommendation")),
      List.duplicate(recommendation, length(branch_rows)),
      "must preserve the CampaignStrategy recommendation in every branch comparison row"
    )
  end

  defp validate_recommendation_sources(issues, _branch_rows, _recommendation), do: issues

  defp validate_operator_review_sources(
         issues,
         manifest_rows,
         %{"rows" => review_rows}
       )
       when is_list(review_rows) do
    if Enum.all?(review_rows, &is_map/1) do
      expected = Enum.filter(review_rows, &ReviewTypePolicy.strategy_manifest?/1)

      actual =
        manifest_rows
        |> Enum.filter(&is_map(Map.get(&1, "source_review_row")))
        |> Enum.map(&Map.get(&1, "source_review_row"))

      validate_equal(
        issues,
        "$.cadence_import_manifest.rows",
        actual,
        expected,
        "must preserve the complete ordered eligible CampaignStrategy operator-review rows"
      )
    else
      issues
    end
  end

  defp validate_operator_review_sources(issues, _manifest_rows, _package), do: issues

  defp validate_equal(issues, path, actual, expected, message) do
    if values_equal?(actual, expected) do
      issues
    else
      [error(path, message) | issues]
    end
  end

  defp values_equal?(actual, expected) when actual == expected, do: true

  defp values_equal?(actual, expected) do
    normalize_nulls(actual) == normalize_nulls(expected)
  end

  defp normalize_nulls(:null), do: nil

  defp normalize_nulls(%{} = value) do
    Map.new(value, fn {key, nested} -> {key, normalize_nulls(nested)} end)
  end

  defp normalize_nulls(value) when is_list(value), do: Enum.map(value, &normalize_nulls/1)
  defp normalize_nulls(value), do: value
end
