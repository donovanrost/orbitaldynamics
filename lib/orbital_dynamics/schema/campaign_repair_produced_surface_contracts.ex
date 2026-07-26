defmodule OrbitalDynamics.Schema.CampaignRepairProducedSurfaceContracts do
  @moduledoc false

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
