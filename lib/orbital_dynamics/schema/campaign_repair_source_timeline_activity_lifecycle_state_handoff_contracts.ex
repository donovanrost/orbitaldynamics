defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelineActivityLifecycleStateHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      indexed_sources: 3,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_source_prefix "campaign_repair.source_timeline_activity_lifecycle_states"

  def validate(
        issues,
        %{"source_timeline_activity_lifecycle_states" => states} = artifact
      )
      when is_list(states) do
    expected_sources = indexed_sources(states, @repair_source_prefix, "state")

    issues
    |> validate_operator_review_handoff(artifact, states, expected_sources)
    |> validate_cadence_handoff(artifact, states, expected_sources)
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         states,
         expected_sources
       ) do
    review_rows =
      indexed_rows(
        Map.get(package, "rows"),
        &operator_lifecycle_row?(&1, expected_sources)
      )

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(states),
      "must contain one Repair source timeline activity-lifecycle-state review row per enclosing state"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the corresponding enclosing Repair source timeline activity-lifecycle-state index"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      states,
      [["source_timeline_lifecycle_state"]],
      "must match the corresponding enclosing Repair source timeline activity-lifecycle state"
    )
  end

  defp validate_operator_review_handoff(issues, _artifact, _states, _sources), do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         states,
         expected_sources
       ) do
    import_rows =
      indexed_rows(
        Map.get(manifest, "rows"),
        &cadence_lifecycle_row?(&1, expected_sources)
      )

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(states),
      "must contain one Repair source timeline activity-lifecycle-state import row per enclosing state"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the corresponding enclosing Repair source timeline activity-lifecycle-state index"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      states,
      [
        ["source_timeline_lifecycle_state"],
        ["source_review_row", "source_timeline_lifecycle_state"]
      ],
      "must match the corresponding enclosing Repair source timeline activity-lifecycle state"
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _states, _sources), do: issues

  defp operator_lifecycle_row?(row, expected_sources) do
    Map.get(row, "review_type") == "timeline_lifecycle_state_review" and
      row_source(row) in expected_sources
  end

  defp cadence_lifecycle_row?(row, expected_sources) do
    (Map.get(row, "source_review_type") == "timeline_lifecycle_state_review" or
       Map.get(row, "import_action") == "review_timeline_lifecycle_state") and
      row_source(row) in expected_sources
  end
end
