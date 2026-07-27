defmodule OrbitalDynamics.Schema.CampaignRepairTimelineTransitionHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [indexed_rows: 2, row_source: 1, validate_equal: 5, validate_source_copies: 6]

  @repair_transition_source "campaign_repair.timeline_transition_application_report.applications"

  def validate(
        issues,
        %{"timeline_transition_application_report" => %{"applications" => applications}} =
          artifact
      )
      when is_list(applications) do
    source_rows = Enum.filter(applications, &review_application?/1)

    issues
    |> validate_operator_review_handoff(artifact, source_rows)
    |> validate_cadence_handoff(artifact, source_rows)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         applications
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_transition_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(applications),
      "must contain one Repair timeline-transition review row per enclosing application"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      applications,
      [["source_timeline_application"]],
      "must match the corresponding enclosing Repair timeline-transition application"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _applications), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         applications
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_transition_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(applications),
      "must contain one Repair timeline-transition import row per enclosing application"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      applications,
      [
        ["source_timeline_application"],
        ["source_review_row", "source_timeline_application"]
      ],
      "must match the corresponding enclosing Repair timeline-transition application"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _applications), do: issues

  defp review_application?(%{} = application),
    do: Map.get(application, "requires_operator_review", false)

  defp review_application?(_application), do: false

  defp operator_transition_row?(row) do
    Map.get(row, "review_type") == "timeline_diff_review" and
      row_source(row) == @repair_transition_source
  end

  defp cadence_transition_row?(row) do
    (Map.get(row, "source_review_type") == "timeline_diff_review" or
       Map.get(row, "import_action") == "review_timeline_diff") and
      row_source(row) == @repair_transition_source
  end
end
