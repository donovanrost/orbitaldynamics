defmodule OrbitalDynamics.Schema.CampaignRepairRealizedStateSnapshotHandoffContracts do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.RealizedStateSnapshot

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source "campaign_repair.source_realized_state_snapshot"
  @row_source @source <> ".activities"

  def validate(issues, artifact) when is_map(artifact) do
    expected_rows = source_rows(artifact)
    expected_sources = Enum.map(expected_rows, &Map.get(&1, "source"))
    realized_activities = Enum.map(expected_rows, &Map.get(&1, "realized_activity"))

    source_snapshots =
      Enum.map(expected_rows, &Map.get(&1, "source_realized_state_snapshot"))

    issues
    |> validate_operator_handoff(
      artifact,
      expected_sources,
      realized_activities,
      source_snapshots
    )
    |> validate_cadence_handoff(
      artifact,
      expected_sources,
      realized_activities,
      source_snapshots
    )
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         expected_sources,
         realized_activities,
         source_snapshots
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_snapshot_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(expected_sources),
      "must contain one Repair source realized-feedback row per reconciled snapshot activity"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source realized-state-snapshot identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      realized_activities,
      [["realized_activity"]],
      "must match the corresponding reconciled Repair source realized activity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_snapshots,
      [["source_realized_state_snapshot"]],
      "must match the enclosing Repair source realized-state snapshot"
    )
  end

  defp validate_operator_handoff(
         issues,
         _artifact,
         _expected_sources,
         _realized_activities,
         _source_snapshots
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         expected_sources,
         realized_activities,
         source_snapshots
       ) do
    import_rows = indexed_rows(Map.get(manifest, "rows"), &cadence_snapshot_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(expected_sources),
      "must contain one Repair source realized-feedback import row per reconciled snapshot activity"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source realized-state-snapshot identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      realized_activities,
      [["realized_activity"], ["source_review_row", "realized_activity"]],
      "must match the corresponding reconciled Repair source realized activity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_snapshots,
      [
        ["source_realized_state_snapshot"],
        ["source_review_row", "source_realized_state_snapshot"]
      ],
      "must match the enclosing Repair source realized-state snapshot"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _expected_sources,
         _realized_activities,
         _source_snapshots
       ),
       do: issues

  defp source_rows(%{"source_realized_state_snapshot" => snapshot}) do
    RealizedStateSnapshot.source_rows(snapshot, @source)
  end

  defp source_rows(_artifact), do: []

  defp operator_snapshot_row?(row) do
    Map.get(row, "review_type") == "realized_feedback" and snapshot_source?(row_source(row))
  end

  defp cadence_snapshot_row?(row) do
    (Map.get(row, "source_review_type") == "realized_feedback" or
       Map.get(row, "import_action") in [
         "record_realized_feedback",
         "review_realized_feedback"
       ]) and snapshot_source?(row_source(row))
  end

  defp snapshot_source?(source) when is_binary(source),
    do: String.starts_with?(source, @row_source)

  defp snapshot_source?(_source), do: false
end
