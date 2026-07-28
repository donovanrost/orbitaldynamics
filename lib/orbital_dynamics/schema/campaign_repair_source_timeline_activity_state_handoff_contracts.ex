defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelineActivityStateHandoffContracts do
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

  @repair_source_prefix "campaign_repair.source_timeline_activity_states"

  def validate(issues, artifact) when is_map(artifact) do
    states = source_states(artifact)
    expected_sources = indexed_sources(states, @repair_source_prefix, "state")

    issues
    |> validate_operator_review_handoff(artifact, states, expected_sources)
    |> validate_cadence_handoff(artifact, states, expected_sources)
  end

  def validate(issues, _artifact), do: issues

  defp source_states(%{"source_timeline_activity_states" => states}) when is_list(states),
    do: states

  defp source_states(_artifact), do: []

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         states,
         expected_sources
       ) do
    review_rows =
      indexed_rows(
        Map.get(package, "rows"),
        &operator_activity_state_row?/1
      )

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(states),
      "must contain one Repair source timeline activity-state review row per enclosing state"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the corresponding enclosing Repair source timeline activity-state index"
    )
    |> validate_state_copies(
      "$.operator_review_package.rows",
      review_rows,
      states,
      [[]]
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
        &cadence_activity_state_row?/1
      )

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(states),
      "must contain one Repair source timeline activity-state import row per enclosing state"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the corresponding enclosing Repair source timeline activity-state index"
    )
    |> validate_state_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      states,
      [[], ["source_review_row"]]
    )
  end

  defp validate_cadence_handoff(issues, _artifact, _states, _sources), do: issues

  defp validate_state_copies(issues, base_path, indexed_rows, states, copy_prefixes) do
    indexed_rows
    |> Enum.zip(states)
    |> Enum.reduce(issues, fn {indexed_row, state}, acc ->
      copy_field = source_copy_field(state)
      copy_paths = Enum.map(copy_prefixes, &(&1 ++ [copy_field]))

      validate_source_copies(
        acc,
        base_path,
        [indexed_row],
        [state],
        copy_paths,
        "must match the corresponding enclosing Repair source timeline activity state"
      )
    end)
  end

  defp source_copy_field(%{"schema_contract" => "timeline_activity_state.v1"}),
    do: "source_timeline_activity_state"

  defp source_copy_field(%{"model" => "artifact_only_timeline_activity_state"}),
    do: "source_timeline_activity_state"

  defp source_copy_field(_state), do: "source_timeline_lifecycle_state"

  defp operator_activity_state_row?(row) do
    Map.get(row, "review_type") == "timeline_lifecycle_state_review" and
      repair_activity_state_source?(row_source(row))
  end

  defp cadence_activity_state_row?(row) do
    (Map.get(row, "source_review_type") == "timeline_lifecycle_state_review" or
       Map.get(row, "import_action") == "review_timeline_lifecycle_state") and
      repair_activity_state_source?(row_source(row))
  end

  defp repair_activity_state_source?(source) when is_binary(source),
    do: String.starts_with?(source, @repair_source_prefix <> "[")

  defp repair_activity_state_source?(_source), do: false
end
