defmodule OrbitalDynamics.Schema.CampaignRepairResourceProjectionHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.ResourceProjection

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_projection_source "campaign_repair.source_resource_projection_report.projected_resources"

  def validate(issues, artifact) when is_map(artifact) do
    expected_rows =
      artifact
      |> Map.get("source_resource_projection_report")
      |> ResourceProjection.projected_resource_rows()
      |> ResourceProjection.rows(@repair_projection_source)

    validate_expected_rows(issues, artifact, expected_rows, @repair_projection_source)
  end

  def validate(issues, _artifact), do: issues

  def validate_flow_summary(issues, artifact, source_field, source) when is_map(artifact) do
    expected_rows =
      case Map.get(artifact, source_field) do
        %{} = summary -> ResourceProjection.flow_summary_rows(summary, source)
        _summary -> []
      end

    validate_expected_rows(issues, artifact, expected_rows, source)
  end

  def validate_flow_summary(issues, _artifact, _source_field, _source), do: issues

  defp validate_expected_rows(issues, artifact, expected_rows, source) do
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))
    projections = Enum.map(expected_rows, &Map.get(&1, "source_resource_projection"))

    issues
    |> validate_operator_review_handoff(artifact, expected_sources, projections, source)
    |> validate_cadence_handoff(artifact, expected_sources, projections, source)
  end

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         projections,
         source
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_projection_row?(&1, source))

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain one Repair resource-projection review row per enclosing report row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair resource-projection source identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      projections,
      [["source_resource_projection"]],
      "must match the corresponding enclosing Repair resource-projection report row"
    )
  end

  defp validate_operator_review_handoff(
         issues,
         _artifact,
         _expected_sources,
         _projections,
         _source
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         projections,
         source
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_projection_row?(&1, source))

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain one Repair resource-projection import row per enclosing report row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair resource-projection source identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      projections,
      [
        ["source_resource_projection"],
        ["source_review_row", "source_resource_projection"]
      ],
      "must match the corresponding enclosing Repair resource-projection report row"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _expected_sources,
         _projections,
         _source
       ),
       do: issues

  defp operator_projection_row?(row, source) do
    Map.get(row, "review_type") == "resource_projection_review" and
      projection_source?(row_source(row), source)
  end

  defp cadence_projection_row?(row, source) do
    (Map.get(row, "source_review_type") == "resource_projection_review" or
       Map.get(row, "import_action") == "review_resource_projection") and
      projection_source?(row_source(row), source)
  end

  defp projection_source?(row_source, source) when is_binary(row_source),
    do: String.starts_with?(row_source, source)

  defp projection_source?(_row_source, _source), do: false
end
