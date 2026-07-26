defmodule OrbitalDynamics.Schema.CampaignRepairProducedSurfaceContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.RepairMetadata

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [error: 2, validate_non_negative_integer_count_map: 3]

  @preserved_actions ~w(preserved preserved_executed)

  def validate(issues, artifact) do
    issues
    |> validate_change_summary(artifact)
    |> validate_preserved_activities(artifact)
    |> validate_repair_metadata(artifact)
  end

  defp validate_repair_metadata(issues, %{"repair_metadata" => %{} = metadata} = artifact) do
    issues
    |> validate_equal(
      "$.repair_metadata.source_plan_id",
      Map.get(metadata, "source_plan_id"),
      Map.get(artifact, "source_plan_id"),
      "must match enclosing Repair source_plan_id"
    )
    |> validate_required_row_count(metadata, "delta_count", Map.get(artifact, "deltas"))
    |> validate_required_row_count(
      metadata,
      "approval_required_count",
      Map.get(artifact, "approval_requirements")
    )
    |> validate_optional_row_count(
      metadata,
      "candidate_window_count",
      Map.get(artifact, "source_candidate_activities")
    )
    |> validate_optional_row_count(
      metadata,
      "repaired_activity_count",
      Map.get(artifact, "activities")
    )
    |> validate_optional_provenance_source_plan(artifact)
    |> validate_candidate_source_copies(artifact, Map.get(metadata, "candidate_source"))
    |> validate_candidate_refresh_summary(artifact, Map.get(metadata, "candidate_source"))
    |> validate_repair_id(artifact, metadata, Map.get(metadata, "candidate_source"))
  end

  defp validate_repair_metadata(issues, _artifact), do: issues

  defp validate_required_row_count(issues, metadata, field, rows) when is_list(rows) do
    validate_equal(
      issues,
      "$.repair_metadata.#{field}",
      Map.get(metadata, field),
      length(rows),
      "must match enclosing Repair row count"
    )
  end

  defp validate_required_row_count(issues, _metadata, _field, _rows), do: issues

  defp validate_optional_row_count(issues, metadata, field, rows) when is_list(rows) do
    if Map.has_key?(metadata, field) do
      validate_equal(
        issues,
        "$.repair_metadata.#{field}",
        Map.get(metadata, field),
        length(rows),
        "must match enclosing Repair row count"
      )
    else
      issues
    end
  end

  defp validate_optional_row_count(issues, _metadata, _field, _rows), do: issues

  defp validate_optional_provenance_source_plan(
         issues,
         %{"provenance" => %{} = provenance} = artifact
       ) do
    validate_optional_copy(
      issues,
      "$.provenance.source_plan_id",
      provenance,
      "source_plan_id",
      Map.get(artifact, "source_plan_id"),
      "must match enclosing Repair source_plan_id"
    )
  end

  defp validate_optional_provenance_source_plan(issues, _artifact), do: issues

  defp validate_candidate_source_copies(issues, artifact, %{} = candidate_source) do
    issues
    |> validate_optional_candidate_source_copy(
      "$.assumptions.candidate_source",
      Map.get(artifact, "assumptions"),
      candidate_source
    )
    |> validate_optional_candidate_source_copy(
      "$.provenance.candidate_source",
      Map.get(artifact, "provenance"),
      candidate_source
    )
  end

  defp validate_candidate_source_copies(issues, _artifact, _candidate_source), do: issues

  defp validate_candidate_refresh_summary(
         issues,
         artifact,
         %{"type" => "candidate_refresh.v1"} = candidate_source
       ) do
    issues
    |> validate_candidate_diff_summary(
      candidate_source,
      Map.get(artifact, "source_candidate_diff_report")
    )
    |> validate_accepted_planning_state_summary(
      candidate_source,
      Map.get(artifact, "source_candidate_refresh_accepted_planning_state")
    )
    |> validate_freshness_summary(
      candidate_source,
      Map.get(artifact, "source_freshness_report")
    )
  end

  defp validate_candidate_refresh_summary(issues, _artifact, _candidate_source), do: issues

  defp validate_candidate_diff_summary(issues, candidate_source, %{} = report) do
    issues
    |> validate_candidate_source_field(
      candidate_source,
      "candidate_count",
      Map.get(report, "refreshed_candidate_count"),
      "source_candidate_diff_report.refreshed_candidate_count"
    )
    |> validate_candidate_source_field(
      candidate_source,
      "invalidated_candidate_count",
      Map.get(report, "invalidated_candidate_count"),
      "source_candidate_diff_report.invalidated_candidate_count"
    )
  end

  defp validate_candidate_diff_summary(issues, _candidate_source, _report), do: issues

  defp validate_accepted_planning_state_summary(issues, candidate_source, %{} = state) do
    issues
    |> validate_candidate_source_field(
      candidate_source,
      "snapshot_id",
      Map.get(state, "snapshot_id"),
      "source_candidate_refresh_accepted_planning_state.snapshot_id"
    )
    |> validate_optional_candidate_source_field(
      candidate_source,
      "maneuver_execution_delta_count",
      state,
      "source_candidate_refresh_accepted_planning_state.maneuver_execution_delta_count"
    )
  end

  defp validate_accepted_planning_state_summary(issues, _candidate_source, _state), do: issues

  defp validate_freshness_summary(issues, candidate_source, %{} = report) do
    validate_candidate_source_field(
      issues,
      candidate_source,
      "generated_at",
      Map.get(report, "generated_at"),
      "source_freshness_report.generated_at"
    )
  end

  defp validate_freshness_summary(issues, _candidate_source, _report), do: issues

  defp validate_candidate_source_field(issues, candidate_source, field, expected, source_path) do
    validate_equal(
      issues,
      "$.repair_metadata.candidate_source.#{field}",
      Map.get(candidate_source, field),
      expected,
      "must match preserved #{source_path}"
    )
  end

  defp validate_optional_candidate_source_field(
         issues,
         candidate_source,
         field,
         source,
         source_path
       ) do
    if Map.has_key?(source, field) do
      validate_candidate_source_field(
        issues,
        candidate_source,
        field,
        Map.get(source, field),
        source_path
      )
    else
      issues
    end
  end

  defp validate_optional_candidate_source_copy(
         issues,
         path,
         %{} = container,
         candidate_source
       ) do
    validate_optional_copy(
      issues,
      path,
      container,
      "candidate_source",
      candidate_source,
      "must match repair_metadata.candidate_source"
    )
  end

  defp validate_optional_candidate_source_copy(issues, _path, _container, _candidate_source),
    do: issues

  defp validate_optional_copy(issues, path, container, field, expected, message) do
    if Map.has_key?(container, field) do
      validate_equal(issues, path, Map.get(container, field), expected, message)
    else
      issues
    end
  end

  defp validate_repair_id(
         issues,
         %{
           "source_plan_id" => source_plan_id,
           "realized_state_snapshot" => %{} = realized_state,
           "current_epoch_s" => current_epoch_s
         } = artifact,
         %{"repair_id" => repair_id},
         %{} = candidate_source
       )
       when is_binary(source_plan_id) and is_number(current_epoch_s) and is_binary(repair_id) do
    expected =
      RepairMetadata.id(
        %{"plan_id" => source_plan_id},
        realized_state,
        current_epoch_s,
        candidate_source
      )

    validate_equal(
      issues,
      "$.repair_metadata.repair_id",
      repair_id,
      expected,
      "must reproduce from preserved Repair identity inputs"
    )
    |> validate_optional_repair_id_copy(
      "$.operator_review_package.source_artifact_id",
      Map.get(artifact, "operator_review_package"),
      "source_artifact_id",
      expected
    )
    |> validate_optional_cadence_repair_id_copies(artifact, expected)
  end

  defp validate_repair_id(issues, _artifact, _metadata, _candidate_source), do: issues

  defp validate_optional_cadence_repair_id_copies(
         issues,
         %{"cadence_import_manifest" => %{"provenance" => %{} = provenance}},
         expected
       ) do
    issues
    |> validate_optional_repair_id_copy(
      "$.cadence_import_manifest.provenance.source_artifact_id",
      provenance,
      "source_artifact_id",
      expected
    )
    |> validate_optional_repair_id_copy(
      "$.cadence_import_manifest.provenance.source_repair_id",
      provenance,
      "source_repair_id",
      expected
    )
  end

  defp validate_optional_cadence_repair_id_copies(issues, _artifact, _expected), do: issues

  defp validate_optional_repair_id_copy(issues, path, %{} = container, field, expected) do
    validate_optional_copy(
      issues,
      path,
      container,
      field,
      expected,
      "must match reproduced Repair ID"
    )
  end

  defp validate_optional_repair_id_copy(issues, _path, _container, _field, _expected),
    do: issues

  defp validate_change_summary(issues, artifact) do
    summary = Map.get(artifact, "change_summary")
    deltas = Map.get(artifact, "deltas")

    issues =
      validate_non_negative_integer_count_map(issues, "$.change_summary", summary)

    if is_map(summary) and is_list(deltas) do
      expected =
        deltas
        |> Enum.filter(&is_map/1)
        |> Enum.map(&Map.get(&1, "repair_action"))
        |> Enum.reject(&is_nil/1)
        |> Enum.frequencies()

      if summary == expected do
        issues
      else
        [error("$.change_summary", "must equal row-derived delta repair-action counts") | issues]
      end
    else
      issues
    end
  end

  defp validate_preserved_activities(issues, artifact) do
    preserved = Map.get(artifact, "preserved_activities")
    activities = Map.get(artifact, "activities")

    if is_list(preserved) and is_list(activities) do
      expected =
        Enum.filter(activities, fn activity ->
          is_map(activity) and get_in(activity, ["repair", "action"]) in @preserved_actions
        end)

      if preserved == expected do
        issues
      else
        [
          error(
            "$.preserved_activities",
            "must equal row-derived preserved activities in repaired activity order"
          )
          | issues
        ]
      end
    else
      issues
    end
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]
end
