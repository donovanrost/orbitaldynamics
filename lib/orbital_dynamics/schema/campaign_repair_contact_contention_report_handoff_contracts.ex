defmodule OrbitalDynamics.Schema.CampaignRepairContactContentionReportHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @surfaces [
    %{
      field: "invalid_contact_inputs",
      source: "campaign_repair.source_contact_contention_report.invalid_contact_inputs",
      copy_field: "source_invalid_contact_input",
      label: "invalid-input"
    },
    %{
      field: "conflict_groups",
      source: "campaign_repair.source_contact_contention_report.conflict_groups",
      copy_field: "source_contention_group",
      label: "conflict-group"
    }
  ]

  def validate(issues, artifact) when is_map(artifact) do
    Enum.reduce(@surfaces, issues, fn surface, acc ->
      source_rows = source_rows(artifact, surface)
      expected_sources = List.duplicate(surface.source, length(source_rows))

      acc
      |> validate_operator_handoff(artifact, source_rows, expected_sources, surface)
      |> validate_cadence_handoff(artifact, source_rows, expected_sources, surface)
    end)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         source_rows,
         expected_sources,
         surface
       ) do
    review_rows =
      indexed_rows(Map.get(package, "rows"), &operator_surface_row?(&1, surface))

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(source_rows),
      "must contain one source contention-report #{surface.label} review row per producer row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing source contention-report #{surface.label} identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_rows,
      [[surface.copy_field]],
      "must match the corresponding enclosing source contention-report #{surface.label} row"
    )
  end

  defp validate_operator_handoff(
         issues,
         _artifact,
         _source_rows,
         _expected_sources,
         _surface
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         source_rows,
         expected_sources,
         surface
       ) do
    import_rows =
      indexed_rows(Map.get(manifest, "rows"), &cadence_surface_row?(&1, surface))

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(source_rows),
      "must contain one source contention-report #{surface.label} import row per producer row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing source contention-report #{surface.label} identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_rows,
      [[surface.copy_field], ["source_review_row", surface.copy_field]],
      "must match the corresponding enclosing source contention-report #{surface.label} row"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _source_rows,
         _expected_sources,
         _surface
       ),
       do: issues

  defp source_rows(artifact, surface) do
    case Map.get(artifact, "source_contact_contention_report") do
      %{} = report ->
        report
        |> Map.get(surface.field, [])
        |> List.wrap()
        |> Enum.filter(&is_map/1)

      _report ->
        []
    end
  end

  defp operator_surface_row?(row, surface) do
    Map.get(row, "review_type") == "contact_contention_review" and
      surface_source?(row_source(row), surface)
  end

  defp cadence_surface_row?(row, surface) do
    (Map.get(row, "source_review_type") == "contact_contention_review" or
       Map.get(row, "import_action") == "review_contact_contention") and
      surface_source?(row_source(row), surface)
  end

  defp surface_source?(source, surface) when is_binary(source),
    do: String.starts_with?(source, surface.source)

  defp surface_source?(_source, _surface), do: false
end
