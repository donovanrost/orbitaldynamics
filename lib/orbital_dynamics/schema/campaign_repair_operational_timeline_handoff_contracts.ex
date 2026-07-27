defmodule OrbitalDynamics.Schema.CampaignRepairOperationalTimelineHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, row_source: 1, validate_equal: 5, validate_source_copies: 6]

  @repair_operational_timeline_source "operational_timeline_report.rows"
  @no_review_actions ~w(monitor_activity none_locked_activity none_terminal_activity)

  def validate(
        issues,
        %{"operational_timeline_report" => %{"rows" => timeline_rows}} = artifact
      )
      when is_list(timeline_rows) do
    source_rows = Enum.filter(timeline_rows, &reviewable_timeline_row?/1)

    issues
    |> validate_operator_review_handoff(artifact, source_rows)
    |> validate_cadence_handoff(artifact, source_rows)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         timeline_rows
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_timeline_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(timeline_rows),
      "must contain one Repair operational-timeline review row per enclosing reviewable timeline row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      timeline_rows,
      [["source_operational_timeline"]],
      "must match the corresponding enclosing Repair operational-timeline row"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _timeline_rows), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         timeline_rows
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_timeline_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(timeline_rows),
      "must contain one Repair operational-timeline import row per enclosing reviewable timeline row"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      timeline_rows,
      [
        ["source_operational_timeline"],
        ["source_review_row", "source_operational_timeline"]
      ],
      "must match the corresponding enclosing Repair operational-timeline row"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _timeline_rows), do: issues

  defp reviewable_timeline_row?(%{} = row),
    do: Map.get(row, "required_operator_action") not in @no_review_actions

  defp reviewable_timeline_row?(_row), do: false

  defp operator_timeline_row?(row) do
    Map.get(row, "review_type") == "operational_timeline_review" and
      Map.get(row, "source") == @repair_operational_timeline_source
  end

  defp cadence_timeline_row?(row) do
    (Map.get(row, "source_review_type") == "operational_timeline_review" or
       Map.get(row, "import_action") == "review_operational_timeline") and
      row_source(row) == @repair_operational_timeline_source
  end
end
