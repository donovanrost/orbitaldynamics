defmodule OrbitalDynamics.Schema.CandidateRefreshExecutionContracts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ExecutionPolicy

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [error: 2, expect_non_negative_integer: 4, expect_type: 5, require_fields: 4]

  @report_fields ~w(
    schema_contract
    bundle_id
    execution_mode
    policy_fingerprint
    snapshot_id
    counts
    policies
    external_validation
    model_limits
  )

  @count_fields ~w(
    spacecraft_state_count
    ground_station_count
    trajectory_count
    trajectory_sample_count
    event_result_count
    access_window_count
    eclipse_interval_count
    candidate_activity_count
    downlink_candidate_count
  )

  @policy_fields ~w(propagation environment access eclipse)
  @external_validation_fields ~w(case_id validation_scope status)

  def validate_optional(issues, artifact) when is_map(artifact) do
    report = Map.get(artifact, "candidate_refresh_execution")
    policy = execution_policy(artifact)

    case {report, policy} do
      {nil, nil} ->
        issues

      {%{} = report, %{} = policy} ->
        validate(issues, artifact, report, policy)

      {nil, _policy} ->
        [
          error("$.candidate_refresh_execution", "is required when execution policy is present")
          | issues
        ]

      {_report, nil} ->
        [
          error(
            "$.assumptions.model_assumptions.#{ExecutionPolicy.reserved_key()}",
            "is required when candidate_refresh_execution is present"
          )
          | issues
        ]

      {_report, _policy} ->
        [error("$.candidate_refresh_execution", "must be an object") | issues]
    end
  end

  def validate_optional(issues, _artifact), do: issues

  defp validate(issues, artifact, report, policy) do
    issues
    |> require_fields("$.candidate_refresh_execution", report, @report_fields)
    |> reject_unknown_fields("$.candidate_refresh_execution", report, @report_fields)
    |> expect_exact(
      "$.candidate_refresh_execution.schema_contract",
      report["schema_contract"],
      "candidate_refresh_execution.v1"
    )
    |> expect_exact(
      "$.candidate_refresh_execution.bundle_id",
      report["bundle_id"],
      ExecutionPolicy.bundle_id()
    )
    |> expect_exact(
      "$.candidate_refresh_execution.execution_mode",
      report["execution_mode"],
      ExecutionPolicy.execution_mode()
    )
    |> validate_fingerprint(report)
    |> expect_exact(
      "$.candidate_refresh_execution.snapshot_id",
      report["snapshot_id"],
      artifact["snapshot_id"]
    )
    |> validate_policy(policy, report)
    |> validate_counts(artifact, report)
    |> validate_policies(policy, report)
    |> validate_external_validation(report)
    |> expect_exact(
      "$.candidate_refresh_execution.model_limits",
      report["model_limits"],
      ExecutionPolicy.model_limits()
    )
    |> validate_access_only_candidates(artifact)
  end

  defp validate_policy(issues, policy, report) do
    issues =
      case ExecutionPolicy.validate_serialized(policy) do
        :ok ->
          issues

        {:error, _reason} ->
          [error(policy_path(), "must be a valid captured execution policy") | issues]
      end

    issues
    |> expect_exact(
      "$.candidate_refresh_execution.policy_fingerprint",
      report["policy_fingerprint"],
      policy["policy_fingerprint"]
    )
    |> expect_exact(
      "$.candidate_refresh_execution.bundle_id",
      report["bundle_id"],
      policy["bundle_id"]
    )
    |> expect_exact(
      "$.candidate_refresh_execution.execution_mode",
      report["execution_mode"],
      policy["execution_mode"]
    )
  end

  defp validate_fingerprint(issues, report) do
    fingerprint = report["policy_fingerprint"]

    if is_binary(fingerprint) and Regex.match?(~r/\A[0-9a-f]{64}\z/, fingerprint),
      do: issues,
      else: [
        error(
          "$.candidate_refresh_execution.policy_fingerprint",
          "must be a lowercase SHA-256 fingerprint"
        )
        | issues
      ]
  end

  defp validate_counts(issues, artifact, report) do
    counts = Map.get(report, "counts")

    issues = expect_type(issues, "$.candidate_refresh_execution", report, "counts", :map)

    if is_map(counts) do
      candidates = list_at(artifact, ["candidate_activities"])
      access_windows = list_at(artifact, ["refreshed_windows", "access_windows"])
      eclipse_intervals = list_at(artifact, ["refreshed_windows", "eclipse_intervals"])

      issues
      |> require_fields("$.candidate_refresh_execution.counts", counts, @count_fields)
      |> reject_unknown_fields("$.candidate_refresh_execution.counts", counts, @count_fields)
      |> validate_non_negative_counts(counts)
      |> expect_count(counts, "spacecraft_state_count", 1)
      |> expect_count(counts, "ground_station_count", 1)
      |> expect_count(counts, "trajectory_count", 1)
      |> expect_count(counts, "event_result_count", 2)
      |> expect_count(counts, "access_window_count", length(access_windows))
      |> expect_count(counts, "eclipse_interval_count", length(eclipse_intervals))
      |> expect_count(counts, "candidate_activity_count", length(candidates))
      |> expect_count(
        counts,
        "downlink_candidate_count",
        Enum.count(candidates, &(&1["type"] == "downlink"))
      )
      |> validate_trajectory_sample_count(counts)
    else
      issues
    end
  end

  defp validate_non_negative_counts(issues, counts) do
    Enum.reduce(@count_fields, issues, fn field, acc ->
      expect_non_negative_integer(acc, "$.candidate_refresh_execution.counts", counts, field)
    end)
  end

  defp expect_count(issues, counts, field, expected) do
    expect_exact(issues, "$.candidate_refresh_execution.counts.#{field}", counts[field], expected)
  end

  defp validate_trajectory_sample_count(issues, counts) do
    case counts["trajectory_sample_count"] do
      value when is_integer(value) and value >= 2 ->
        issues

      _value ->
        [
          error(
            "$.candidate_refresh_execution.counts.trajectory_sample_count",
            "must be at least 2"
          )
          | issues
        ]
    end
  end

  defp validate_policies(issues, policy, report) do
    policies = Map.get(report, "policies")
    issues = expect_type(issues, "$.candidate_refresh_execution", report, "policies", :map)

    if is_map(policies) do
      issues =
        issues
        |> require_fields("$.candidate_refresh_execution.policies", policies, @policy_fields)
        |> reject_unknown_fields(
          "$.candidate_refresh_execution.policies",
          policies,
          @policy_fields
        )

      Enum.reduce(@policy_fields, issues, fn field, acc ->
        expect_exact(
          acc,
          "$.candidate_refresh_execution.policies.#{field}",
          policies[field],
          policy[field]
        )
      end)
    else
      issues
    end
  end

  defp validate_external_validation(issues, report) do
    validation = Map.get(report, "external_validation")

    issues =
      expect_type(
        issues,
        "$.candidate_refresh_execution",
        report,
        "external_validation",
        :map
      )

    if is_map(validation) do
      issues
      |> require_fields(
        "$.candidate_refresh_execution.external_validation",
        validation,
        @external_validation_fields
      )
      |> reject_unknown_fields(
        "$.candidate_refresh_execution.external_validation",
        validation,
        @external_validation_fields
      )
      |> expect_exact(
        "$.candidate_refresh_execution.external_validation.case_id",
        validation["case_id"],
        ExecutionPolicy.external_case_id()
      )
      |> expect_exact(
        "$.candidate_refresh_execution.external_validation.validation_scope",
        validation["validation_scope"],
        "exact_case_only"
      )
      |> expect_exact(
        "$.candidate_refresh_execution.external_validation.status",
        validation["status"],
        "referenced_not_evaluated_by_runner"
      )
    else
      issues
    end
  end

  defp validate_access_only_candidates(issues, artifact) do
    candidates = list_at(artifact, ["candidate_activities"])

    candidates
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {candidate, index}, acc ->
      if is_map(candidate) and candidate["type"] == "downlink" do
        acc
      else
        [
          error(
            "$.candidate_activities[#{index}].type",
            "must equal downlink for executable refresh"
          )
          | acc
        ]
      end
    end)
  end

  defp reject_unknown_fields(issues, path, map, allowed) do
    allowed = MapSet.new(allowed)

    map
    |> Map.keys()
    |> Enum.reject(&MapSet.member?(allowed, &1))
    |> Enum.sort()
    |> Enum.reduce(issues, fn field, acc ->
      [error("#{path}.#{field}", "is not supported") | acc]
    end)
  end

  defp expect_exact(issues, _path, value, value), do: issues

  defp expect_exact(issues, path, _actual, _expected),
    do: [error(path, "does not match captured execution") | issues]

  defp execution_policy(%{
         "assumptions" => %{
           "model_assumptions" => %{} = assumptions
         }
       }) do
    Map.get(assumptions, ExecutionPolicy.reserved_key())
  end

  defp execution_policy(_artifact), do: nil

  defp policy_path do
    "$.assumptions.model_assumptions.#{ExecutionPolicy.reserved_key()}"
  end

  defp list_at(map, path) do
    case get_in(map, path) do
      values when is_list(values) -> values
      _value -> []
    end
  end
end
