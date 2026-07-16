defmodule OrbitalDynamics.Schema.CandidateRefreshContracts do
  @moduledoc false

  def validate(issues, artifact, required_fields, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, "$", artifact, required_fields)
    |> validate_stable_ids(callbacks, "$", artifact, ["refresh_id", "study_id", "snapshot_id"])
    |> expect_equal(callbacks, "$", artifact, "schema_version", 1)
    |> expect_equal(callbacks, "$", artifact, "schema_contract", "candidate_refresh.v1")
    |> expect_equal(callbacks, "$", artifact, "artifact_type", "candidate_refresh")
    |> expect_equal(callbacks, "$", artifact, "planner", "OrbitalDynamics.CandidateRefresh.V1")
    |> expect_number(callbacks, "$", artifact, "current_epoch_s")
    |> expect_type(callbacks, "$", artifact, "remaining_horizon", :map)
    |> expect_type(callbacks, "$", artifact, "accepted_planning_state", :map)
    |> expect_type(callbacks, "$", artifact, "refreshed_windows", :map)
    |> expect_type(callbacks, "$", artifact, "candidate_activities", :list)
    |> expect_type(callbacks, "$", artifact, "contact_intents", :list)
    |> expect_type(callbacks, "$", artifact, "resource_summaries", :list)
    |> expect_type(callbacks, "$", artifact, "invalidated_candidates", :list)
    |> expect_type(callbacks, "$", artifact, "validation_records", :list)
    |> expect_type(callbacks, "$", artifact, "warnings", :list)
    |> expect_type(callbacks, "$", artifact, "assumptions", :map)
    |> expect_type(callbacks, "$", artifact, "provenance", :map)
    |> expect_optional_type(callbacks, "$", artifact, "model_limits", :list)
    |> validate_string_list_items(callbacks, "$", artifact, "model_limits")
    |> call(callbacks, :validate_candidate_refresh_publication_lineage_fields, [artifact])
    |> call(callbacks, :validate_optional_exact_model_limits, [
      "$",
      artifact,
      OrbitalDynamics.CandidateRefresh.model_limits(),
      "must match candidate refresh model limits"
    ])
    |> call(callbacks, :validate_candidate_refresh_source_report_provenance, [artifact])
    |> call(callbacks, :validate_operational_feedback, [
      "$",
      Map.get(artifact, "operational_feedback")
    ])
    |> expect_type(callbacks, "$", artifact, "source_window_lineage", :list)
    |> require_nested(
      callbacks,
      "$.remaining_horizon",
      Map.get(artifact, "remaining_horizon", %{}),
      [
        "output_step_s"
      ]
    )
    |> require_nested(
      callbacks,
      "$.accepted_planning_state",
      Map.get(artifact, "accepted_planning_state", %{}),
      ["snapshot_id", "spacecraft_state_count"]
    )
    |> call(callbacks, :validate_refreshed_windows, [
      Map.get(artifact, "refreshed_windows", %{})
    ])
    |> validate_rows(
      callbacks,
      "$.candidate_activities",
      Map.get(artifact, "candidate_activities", []),
      callback(callbacks, :validate_candidate_activity)
    )
    |> validate_rows(
      callbacks,
      "$.contact_intents",
      Map.get(artifact, "contact_intents", []),
      callback(callbacks, :validate_contact_intent)
    )
    |> call(callbacks, :validate_optional_contact_allocation_report, [
      Map.get(artifact, "contact_allocation_report")
    ])
    |> call(callbacks, :validate_optional_contact_filter_report, [
      Map.get(artifact, "contact_filter_report")
    ])
    |> validate_rows(
      callbacks,
      "$.resource_summaries",
      Map.get(artifact, "resource_summaries", []),
      callback(callbacks, :validate_resource_summary)
    )
    |> call(callbacks, :validate_optional_resource_filter_report, [
      Map.get(artifact, "resource_filter_report")
    ])
    |> call(callbacks, :validate_optional_candidate_diff_report, [
      "$.candidate_diff_report",
      Map.get(artifact, "candidate_diff_report")
    ])
    |> call(callbacks, :validate_optional_candidate_rejection_report, [
      "$.candidate_rejection_report",
      Map.get(artifact, "candidate_rejection_report")
    ])
    |> call(callbacks, :validate_optional_candidate_rejection_report, [
      "$.source_candidate_rejection_report",
      Map.get(artifact, "source_candidate_rejection_report")
    ])
    |> call(callbacks, :validate_optional_freshness_report, [
      "$.freshness_report",
      Map.get(artifact, "freshness_report")
    ])
    |> call(callbacks, :validate_optional_refresh_budget_report, [
      "$.refresh_budget_report",
      Map.get(artifact, "refresh_budget_report")
    ])
    |> validate_rows(
      callbacks,
      "$.invalidated_candidates",
      Map.get(artifact, "invalidated_candidates", []),
      callback(callbacks, :validate_invalidated_candidate)
    )
    |> validate_rows(
      callbacks,
      "$.validation_records",
      Map.get(artifact, "validation_records", []),
      callback(callbacks, :validate_embedded_validation_record)
    )
    |> validate_string_list_items(callbacks, "$", artifact, "warnings")
    |> validate_rows(
      callbacks,
      "$.source_window_lineage",
      Map.get(artifact, "source_window_lineage", []),
      callback(callbacks, :validate_source_window_lineage)
    )
  end

  defp require_fields(issues, callbacks, path, artifact, required_fields),
    do: call(issues, callbacks, :require_fields, [path, artifact, required_fields])

  defp validate_stable_ids(issues, callbacks, path, artifact, fields),
    do: call(issues, callbacks, :validate_stable_ids, [path, artifact, fields])

  defp expect_equal(issues, callbacks, path, artifact, field, expected),
    do: call(issues, callbacks, :expect_equal, [path, artifact, field, expected])

  defp expect_number(issues, callbacks, path, artifact, field),
    do: call(issues, callbacks, :expect_number, [path, artifact, field])

  defp expect_type(issues, callbacks, path, artifact, field, type),
    do: call(issues, callbacks, :expect_type, [path, artifact, field, type])

  defp expect_optional_type(issues, callbacks, path, artifact, field, type),
    do: call(issues, callbacks, :expect_optional_type, [path, artifact, field, type])

  defp validate_string_list_items(issues, callbacks, path, artifact, field),
    do: call(issues, callbacks, :validate_string_list_items, [path, artifact, field])

  defp require_nested(issues, callbacks, path, artifact, fields),
    do: call(issues, callbacks, :require_nested, [path, artifact, fields])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: call(issues, callbacks, :validate_rows, [path, rows, validator])

  defp callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp call(issues, callbacks, name, args),
    do: apply(callback(callbacks, name), [issues | args])
end
