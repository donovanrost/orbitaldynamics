defmodule OrbitalDynamics.Schema.CandidateRefreshContracts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ExecutionPolicy

  alias OrbitalDynamics.Schema.CandidateActivityContracts
  alias OrbitalDynamics.Schema.CandidateDiffContracts
  alias OrbitalDynamics.Schema.CandidateRefreshAcceptedPlanningStateContracts
  alias OrbitalDynamics.Schema.CandidateRefreshExecutionContracts
  alias OrbitalDynamics.Schema.CandidateRefreshModelLimitContracts
  alias OrbitalDynamics.Schema.CandidateRefreshRegistryContracts
  alias OrbitalDynamics.Schema.CandidateRefreshReportContracts
  alias OrbitalDynamics.Schema.CandidateRefreshWindowContracts
  alias OrbitalDynamics.Schema.ContactFilterReportContracts
  alias OrbitalDynamics.Schema.ContactIntentContracts
  alias OrbitalDynamics.Schema.FreshnessReportContracts
  alias OrbitalDynamics.Schema.OperationalFeedbackContracts
  alias OrbitalDynamics.Schema.RefreshBudgetReportContracts
  alias OrbitalDynamics.Schema.ResourceFilterReportContracts
  alias OrbitalDynamics.Schema.ResourceSummaryContracts
  alias OrbitalDynamics.Schema.SuppressedCandidateContracts
  alias OrbitalDynamics.Schema.ValidationRecordContracts

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_number: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_non_negative_integer_count_map: 3,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3,
      validate_stable_ids: 4
    ]

  def validate(
        issues,
        artifact,
        required_fields,
        contact_allocation_report_validator,
        candidate_rejection_report_validator
      )
      when is_function(contact_allocation_report_validator, 2) and
             is_function(candidate_rejection_report_validator, 3) do
    case validate_json_term(artifact) do
      :ok ->
        validate_safe(
          issues,
          artifact,
          required_fields,
          contact_allocation_report_validator,
          candidate_rejection_report_validator
        )

      {:error, reason} ->
        [
          error(json_safety_path(reason), "must be a bounded recursively JSON-safe value")
          | issues
        ]
    end
  end

  defp validate_json_term(artifact) do
    if executable_refresh_artifact?(artifact),
      do: ExecutionPolicy.validate_serialized_json_term(artifact),
      else: ExecutionPolicy.validate_json_term(artifact)
  end

  defp executable_refresh_artifact?(artifact) do
    Map.has_key?(artifact, "candidate_refresh_execution") or
      Map.has_key?(artifact, :candidate_refresh_execution) or
      Enum.any?(
        [Map.get(artifact, "assumptions"), Map.get(artifact, :assumptions)],
        &execution_policy_assumptions?/1
      )
  end

  defp execution_policy_assumptions?(%{} = assumptions) do
    Enum.any?(
      [Map.get(assumptions, "model_assumptions"), Map.get(assumptions, :model_assumptions)],
      fn
        %{} = model_assumptions ->
          Map.has_key?(model_assumptions, "candidate_refresh_execution_policy") or
            Map.has_key?(model_assumptions, :candidate_refresh_execution_policy)

        _value ->
          false
      end
    )
  end

  defp execution_policy_assumptions?(_assumptions), do: false

  defp validate_safe(
         issues,
         artifact,
         required_fields,
         contact_allocation_report_validator,
         candidate_rejection_report_validator
       ) do
    issues
    |> require_fields("$", artifact, required_fields)
    |> validate_stable_ids("$", artifact, ["refresh_id", "study_id", "snapshot_id"])
    |> expect_equal("$", artifact, "schema_version", 1)
    |> expect_equal("$", artifact, "schema_contract", "candidate_refresh.v1")
    |> expect_equal("$", artifact, "artifact_type", "candidate_refresh")
    |> expect_equal("$", artifact, "planner", "OrbitalDynamics.CandidateRefresh.V1")
    |> expect_number("$", artifact, "current_epoch_s")
    |> expect_type("$", artifact, "remaining_horizon", :map)
    |> expect_type("$", artifact, "accepted_planning_state", :map)
    |> expect_type("$", artifact, "refreshed_windows", :map)
    |> expect_type("$", artifact, "candidate_activities", :list)
    |> expect_type("$", artifact, "contact_intents", :list)
    |> expect_type("$", artifact, "resource_summaries", :list)
    |> expect_type("$", artifact, "invalidated_candidates", :list)
    |> expect_type("$", artifact, "validation_records", :list)
    |> expect_type("$", artifact, "warnings", :list)
    |> expect_type("$", artifact, "assumptions", :map)
    |> expect_type("$", artifact, "provenance", :map)
    |> expect_optional_type("$", artifact, "model_limits", :list)
    |> validate_string_list_items("$", artifact, "model_limits")
    |> validate_publication_lineage_fields(artifact)
    |> CandidateRefreshModelLimitContracts.validate(
      "$.model_limits",
      Map.get(artifact, "model_limits")
    )
    |> CandidateRefreshReportContracts.validate_source_report_provenance(artifact)
    |> OperationalFeedbackContracts.validate("$", Map.get(artifact, "operational_feedback"))
    |> expect_type("$", artifact, "source_window_lineage", :list)
    |> CandidateRefreshWindowContracts.validate_optional_embedded_remaining_horizon(
      "$.remaining_horizon",
      Map.get(artifact, "remaining_horizon", %{})
    )
    |> CandidateRefreshAcceptedPlanningStateContracts.validate(
      "$.accepted_planning_state",
      Map.get(artifact, "accepted_planning_state", %{})
    )
    |> CandidateRefreshWindowContracts.validate_refreshed_windows(
      Map.get(artifact, "refreshed_windows", %{})
    )
    |> validate_rows(
      "$.candidate_activities",
      Map.get(artifact, "candidate_activities", []),
      &CandidateActivityContracts.validate/3
    )
    |> validate_rows(
      "$.contact_intents",
      Map.get(artifact, "contact_intents", []),
      &ContactIntentContracts.validate/3
    )
    |> contact_allocation_report_validator.(Map.get(artifact, "contact_allocation_report"))
    |> validate_optional_contact_filter_report(Map.get(artifact, "contact_filter_report"))
    |> validate_rows(
      "$.resource_summaries",
      Map.get(artifact, "resource_summaries", []),
      &ResourceSummaryContracts.validate/3
    )
    |> validate_optional_resource_filter_report(Map.get(artifact, "resource_filter_report"))
    |> CandidateDiffContracts.validate_optional_report(
      "$.candidate_diff_report",
      Map.get(artifact, "candidate_diff_report")
    )
    |> candidate_rejection_report_validator.(
      "$.candidate_rejection_report",
      Map.get(artifact, "candidate_rejection_report")
    )
    |> candidate_rejection_report_validator.(
      "$.source_candidate_rejection_report",
      Map.get(artifact, "source_candidate_rejection_report")
    )
    |> FreshnessReportContracts.validate_optional(
      "$.freshness_report",
      Map.get(artifact, "freshness_report")
    )
    |> RefreshBudgetReportContracts.validate_optional(
      "$.refresh_budget_report",
      Map.get(artifact, "refresh_budget_report")
    )
    |> validate_rows(
      "$.invalidated_candidates",
      Map.get(artifact, "invalidated_candidates", []),
      &CandidateDiffContracts.validate_invalidated_candidate/3
    )
    |> validate_rows(
      "$.validation_records",
      Map.get(artifact, "validation_records", []),
      &ValidationRecordContracts.validate_embedded/3
    )
    |> validate_string_list_items("$", artifact, "warnings")
    |> validate_rows(
      "$.source_window_lineage",
      Map.get(artifact, "source_window_lineage", []),
      &CandidateDiffContracts.validate_source_window_lineage/3
    )
    |> CandidateRefreshExecutionContracts.validate_optional(artifact)
  end

  defp json_safety_path({:normalization_limit_exceeded, path, _limit, _maximum}), do: path
  defp json_safety_path({:duplicate_normalized_key, path, _key}), do: path
  defp json_safety_path({:unsupported_json_value, path, _type}), do: path
  defp json_safety_path({:invalid_utf8_string, path}), do: path
  defp json_safety_path({:invalid_utf8_key, path}), do: path
  defp json_safety_path({:unsupported_map_key, path}), do: path
  defp json_safety_path({:non_finite_number, path}), do: path
  defp json_safety_path({:noncanonical_null, path}), do: path
  defp json_safety_path(_reason), do: "$"

  defp validate_publication_lineage_fields(issues, artifact) do
    issues =
      Enum.reduce(
        CandidateRefreshRegistryContracts.publication_lineage_id_array_fields(),
        issues,
        fn field, acc ->
          acc
          |> expect_optional_type("$", artifact, field, :list)
          |> validate_optional_stable_id_list("$", artifact, field)
        end
      )

    issues =
      Enum.reduce(
        CandidateRefreshRegistryContracts.publication_lineage_count_map_fields(),
        issues,
        fn field, acc ->
          acc
          |> expect_optional_type("$", artifact, field, :map)
          |> validate_non_negative_integer_count_map("$.#{field}", Map.get(artifact, field))
        end
      )

    Enum.reduce(
      CandidateRefreshRegistryContracts.publication_lineage_stable_id_array_map_fields(),
      issues,
      fn field, acc ->
        acc
        |> expect_optional_type("$", artifact, field, :map)
        |> validate_stable_id_array_map("$.#{field}", Map.get(artifact, field))
      end
    )
  end

  defp validate_optional_contact_filter_report(issues, nil), do: issues

  defp validate_optional_contact_filter_report(issues, %{} = report) do
    ContactFilterReportContracts.validate(
      issues,
      "$.contact_filter_report",
      report,
      &SuppressedCandidateContracts.validate/3
    )
  end

  defp validate_optional_contact_filter_report(issues, _report),
    do: [error("$.contact_filter_report", "must be an object") | issues]

  defp validate_optional_resource_filter_report(issues, nil), do: issues

  defp validate_optional_resource_filter_report(issues, %{} = report) do
    ResourceFilterReportContracts.validate(
      issues,
      "$.resource_filter_report",
      report,
      &validate_invalid_resource_summary_input/3,
      &SuppressedCandidateContracts.validate/3
    )
  end

  defp validate_optional_resource_filter_report(issues, _report),
    do: [error("$.resource_filter_report", "must be an object") | issues]

  defp validate_invalid_resource_summary_input(issues, path, row) do
    expect_optional_one_of(issues, path, row, "review_status", [
      "operator_review_required",
      "review_required",
      "pending_operator_review",
      "ready_for_review"
    ])
  end
end
