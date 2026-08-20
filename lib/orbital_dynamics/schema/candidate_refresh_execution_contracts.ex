defmodule OrbitalDynamics.Schema.CandidateRefreshExecutionContracts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{
    BuildGroundNetwork,
    BuildRefreshId,
    CandidateActivityFields,
    ExecutionPolicy,
    SourceObjectives,
    SourceWindowLineage
  }

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [error: 2, expect_non_negative_integer: 4, expect_type: 5, require_fields: 4]

  @report_fields ~w(
    schema_contract
    bundle_id
    execution_mode
    policy_fingerprint
    refresh_id
    study_id
    snapshot_id
    spacecraft_id
    scenario_id
    ground_station_id
    evidence
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
  @evidence_fields ~w(
    scenario_id
    ground_station_id
    trajectory_sample_count
    access_windows_sha256
    eclipse_intervals_sha256
  )

  def validate_optional(issues, artifact) when is_map(artifact) do
    try do
      do_validate_optional(issues, artifact)
    rescue
      _error -> [error("$.candidate_refresh_execution", "could not be validated safely") | issues]
    catch
      _kind, _reason ->
        [error("$.candidate_refresh_execution", "could not be validated safely") | issues]
    end
  end

  def validate_optional(issues, _artifact), do: issues

  defp do_validate_optional(issues, artifact) do
    report = Map.get(artifact, "candidate_refresh_execution")
    policy = execution_policy(artifact)
    evidence = execution_evidence(artifact)

    case {report, policy, evidence} do
      {nil, nil, nil} ->
        issues

      {%{} = report, %{} = policy, %{} = _evidence} ->
        validate(issues, artifact, report, policy)

      {nil, _policy, _evidence} ->
        [
          error("$.candidate_refresh_execution", "is required when execution policy is present")
          | issues
        ]

      {_report, nil, _evidence} ->
        [
          error(
            "$.assumptions.model_assumptions.#{ExecutionPolicy.reserved_key()}",
            "is required when candidate_refresh_execution is present"
          )
          | issues
        ]

      {_report, _policy, nil} ->
        [error(assumptions_evidence_path(), "is required for executable refresh") | issues]

      {_report, _policy, _evidence} ->
        [error("$.candidate_refresh_execution", "must be an object") | issues]
    end
  end

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
    |> validate_identity_surfaces(artifact, policy, report)
    |> validate_evidence(artifact, policy, report)
    |> validate_counts(artifact, policy, report)
    |> validate_policies(policy, report)
    |> validate_external_validation(report)
    |> expect_exact(
      "$.candidate_refresh_execution.model_limits",
      report["model_limits"],
      ExecutionPolicy.model_limits()
    )
    |> validate_access_only_candidates(artifact)
    |> validate_window_and_candidate_causality(artifact, policy)
    |> validate_refresh_id(artifact, policy, report)
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

  defp validate_identity_surfaces(issues, artifact, policy, report) do
    initial_state = map_at(policy, ["initial_state"])
    station = map_at(policy, ["ground_station"])
    coverage = map_at(policy, ["coverage"])
    refresh_input = map_at(policy, ["refresh_identity_input"])

    snapshot_id = initial_state["snapshot_id"]
    spacecraft_id = initial_state["spacecraft_id"]
    scenario_id = initial_state["scenario_id"]
    ground_station_id = station["ground_station_id"]

    issues
    |> expect_exact("$.snapshot_id", artifact["snapshot_id"], snapshot_id)
    |> expect_exact(
      "$.accepted_planning_state.snapshot_id",
      get_in(artifact, ["accepted_planning_state", "snapshot_id"]),
      snapshot_id
    )
    |> expect_exact(
      "$.accepted_planning_state.spacecraft_state_count",
      get_in(artifact, ["accepted_planning_state", "spacecraft_state_count"]),
      1
    )
    |> expect_exact(
      "$.accepted_planning_state.maneuver_execution_delta_count",
      get_in(artifact, ["accepted_planning_state", "maneuver_execution_delta_count"]),
      0
    )
    |> expect_exact(
      "$.provenance.accepted_planning_state.snapshot_id",
      get_in(artifact, ["provenance", "accepted_planning_state", "snapshot_id"]),
      snapshot_id
    )
    |> expect_exact(
      "$.candidate_refresh_execution.snapshot_id",
      report["snapshot_id"],
      snapshot_id
    )
    |> expect_exact(
      "$.candidate_refresh_execution.spacecraft_id",
      report["spacecraft_id"],
      spacecraft_id
    )
    |> expect_exact(
      "$.candidate_refresh_execution.scenario_id",
      report["scenario_id"],
      scenario_id
    )
    |> expect_exact(
      "$.candidate_refresh_execution.ground_station_id",
      report["ground_station_id"],
      ground_station_id
    )
    |> expect_exact(
      "$.candidate_refresh_execution.study_id",
      report["study_id"],
      artifact["study_id"]
    )
    |> expect_exact(
      "$.candidate_refresh_execution.refresh_id",
      report["refresh_id"],
      artifact["refresh_id"]
    )
    |> expect_exact("$.current_epoch_s", artifact["current_epoch_s"], initial_state["epoch_s"])
    |> expect_exact("$.remaining_horizon", artifact["remaining_horizon"], coverage)
    |> expect_exact(
      "$.accepted_planning_state.snapshot_id",
      get_in(refresh_input, ["accepted_planning_state", "snapshot_id"]),
      snapshot_id
    )
  end

  defp validate_evidence(issues, artifact, policy, report) do
    evidence = Map.get(report, "evidence")
    assumption_evidence = execution_evidence(artifact)
    initial_state = map_at(policy, ["initial_state"])
    station = map_at(policy, ["ground_station"])
    coverage = map_at(policy, ["coverage"])

    issues = expect_type(issues, "$.candidate_refresh_execution", report, "evidence", :map)

    if is_map(evidence) do
      access_windows = list_at(artifact, ["refreshed_windows", "access_windows"])
      eclipse_intervals = list_at(artifact, ["refreshed_windows", "eclipse_intervals"])

      issues
      |> require_fields("$.candidate_refresh_execution.evidence", evidence, @evidence_fields)
      |> reject_unknown_fields(
        "$.candidate_refresh_execution.evidence",
        evidence,
        @evidence_fields
      )
      |> expect_exact(
        assumptions_evidence_path(),
        assumption_evidence,
        evidence
      )
      |> expect_exact(
        "$.candidate_refresh_execution.evidence.scenario_id",
        evidence["scenario_id"],
        initial_state["scenario_id"]
      )
      |> expect_exact(
        "$.candidate_refresh_execution.evidence.ground_station_id",
        evidence["ground_station_id"],
        station["ground_station_id"]
      )
      |> expect_exact(
        "$.candidate_refresh_execution.evidence.trajectory_sample_count",
        evidence["trajectory_sample_count"],
        expected_trajectory_sample_count(coverage)
      )
      |> expect_digest(
        "$.candidate_refresh_execution.evidence.access_windows_sha256",
        evidence["access_windows_sha256"],
        access_windows
      )
      |> expect_digest(
        "$.candidate_refresh_execution.evidence.eclipse_intervals_sha256",
        evidence["eclipse_intervals_sha256"],
        eclipse_intervals
      )
    else
      issues
    end
  end

  defp expect_digest(issues, path, actual, value) do
    case ExecutionPolicy.canonical_sha256(value) do
      {:ok, expected} -> expect_exact(issues, path, actual, expected)
      {:error, _reason} -> [error(path, "could not be recomputed") | issues]
    end
  end

  defp expected_trajectory_sample_count(%{
         "starts_at_s" => starts_at_s,
         "ends_at_s" => ends_at_s,
         "output_step_s" => output_step_s
       })
       when is_number(starts_at_s) and is_number(ends_at_s) and is_number(output_step_s) and
              output_step_s > 0.0 do
    duration_s = ends_at_s - starts_at_s
    full_steps = trunc(Float.floor(duration_s / output_step_s))
    final_sample_s = full_steps * output_step_s

    if abs(final_sample_s - duration_s) <= 1.0e-12,
      do: full_steps + 1,
      else: full_steps + 2
  end

  defp expected_trajectory_sample_count(_coverage), do: nil

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

  defp validate_counts(issues, artifact, policy, report) do
    counts = Map.get(report, "counts")

    issues = expect_type(issues, "$.candidate_refresh_execution", report, "counts", :map)

    if is_map(counts) do
      candidates = list_at(artifact, ["candidate_activities"])
      access_windows = list_at(artifact, ["refreshed_windows", "access_windows"])
      eclipse_intervals = list_at(artifact, ["refreshed_windows", "eclipse_intervals"])

      trajectory_sample_count =
        policy
        |> map_at(["coverage"])
        |> expected_trajectory_sample_count()

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
      |> expect_count(counts, "trajectory_sample_count", trajectory_sample_count)
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

  defp validate_window_and_candidate_causality(issues, artifact, policy) do
    initial_state = map_at(policy, ["initial_state"])
    station = map_at(policy, ["ground_station"])
    coverage = map_at(policy, ["coverage"])
    scenario_id = initial_state["scenario_id"]
    ground_station_id = station["ground_station_id"]
    access_windows = list_at(artifact, ["refreshed_windows", "access_windows"])
    eclipse_intervals = list_at(artifact, ["refreshed_windows", "eclipse_intervals"])
    target_windows = list_at(artifact, ["refreshed_windows", "target_visibility_windows"])
    candidates = list_at(artifact, ["candidate_activities"])

    access_by_id =
      access_windows
      |> Enum.with_index(1)
      |> Map.new(fn {window, index} -> {window["id"], {window, index}} end)

    issues
    |> expect_exact(
      "$.refreshed_windows.target_visibility_windows",
      target_windows,
      []
    )
    |> validate_access_windows(access_windows, scenario_id, ground_station_id, coverage)
    |> validate_eclipse_intervals(eclipse_intervals, scenario_id, coverage)
    |> validate_candidates(candidates, access_by_id, scenario_id, ground_station_id)
    |> expect_exact(
      "$.source_window_lineage",
      list_at(artifact, ["source_window_lineage"]),
      SourceWindowLineage.build(candidates)
    )
    |> validate_identity_rows(
      "$.contact_intents",
      list_at(artifact, ["contact_intents"]),
      scenario_id,
      ground_station_id
    )
  end

  defp validate_access_windows(issues, windows, scenario_id, ground_station_id, coverage) do
    windows
    |> Enum.with_index(1)
    |> Enum.reduce(issues, fn {window, index}, acc ->
      path = "$.refreshed_windows.access_windows[#{index - 1}]"

      expected_id =
        CandidateActivityFields.window_id(
          scenario_id,
          "ground_station_access",
          ground_station_id,
          index
        )

      acc
      |> expect_exact(path <> ".id", window["id"], expected_id)
      |> expect_exact(path <> ".type", window["type"], "ground_station_access")
      |> expect_exact(path <> ".scenario_id", window["scenario_id"], scenario_id)
      |> expect_exact(
        path <> ".ground_station_id",
        window["ground_station_id"],
        ground_station_id
      )
      |> validate_window_bounds(path, window, coverage)
    end)
  end

  defp validate_eclipse_intervals(issues, intervals, scenario_id, coverage) do
    intervals
    |> Enum.with_index(1)
    |> Enum.reduce(issues, fn {interval, index}, acc ->
      path = "$.refreshed_windows.eclipse_intervals[#{index - 1}]"

      expected_id =
        CandidateActivityFields.window_id(
          scenario_id,
          "eclipse",
          "central_body_shadow",
          index
        )

      acc
      |> expect_exact(path <> ".id", interval["id"], expected_id)
      |> expect_exact(path <> ".type", interval["type"], "eclipse")
      |> expect_exact(path <> ".scenario_id", interval["scenario_id"], scenario_id)
      |> validate_window_bounds(path, interval, coverage)
    end)
  end

  defp validate_window_bounds(issues, path, window, coverage) do
    starts_at_s = window["starts_at_s"]
    ends_at_s = window["ends_at_s"]
    horizon_start_s = coverage["starts_at_s"]
    horizon_end_s = coverage["ends_at_s"]

    cond do
      not is_number(starts_at_s) or not is_number(ends_at_s) or
        not is_number(horizon_start_s) or not is_number(horizon_end_s) ->
        [error(path, "must have numeric captured-horizon boundaries") | issues]

      starts_at_s < horizon_start_s or ends_at_s > horizon_end_s ->
        [error(path, "must remain inside captured coverage") | issues]

      true ->
        issues
    end
  end

  defp validate_candidates(issues, candidates, access_by_id, scenario_id, ground_station_id) do
    candidates
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {candidate, candidate_index}, acc ->
      path = "$.candidate_activities[#{candidate_index}]"

      case Map.get(access_by_id, candidate["source_window_id"]) do
        {%{} = window, window_index} ->
          expected_id =
            CandidateActivityFields.activity_id(
              scenario_id,
              "downlink",
              ground_station_id,
              window_index
            )

          acc
          |> expect_exact(path <> ".id", candidate["id"], expected_id)
          |> expect_exact(path <> ".scenario_id", candidate["scenario_id"], scenario_id)
          |> expect_exact(
            path <> ".ground_station_id",
            candidate["ground_station_id"],
            ground_station_id
          )
          |> expect_exact(path <> ".starts_at_s", candidate["starts_at_s"], window["starts_at_s"])
          |> expect_exact(path <> ".ends_at_s", candidate["ends_at_s"], window["ends_at_s"])
          |> expect_exact(
            path <> ".duration_s",
            candidate["duration_s"],
            window["ends_at_s"] - window["starts_at_s"]
          )
          |> expect_exact(
            path <> ".source_window.type",
            get_in(candidate, ["source_window", "type"]),
            "ground_station_access"
          )

        nil ->
          [error(path <> ".source_window_id", "must reference regenerated access evidence") | acc]
      end
    end)
  end

  defp validate_identity_rows(issues, path, rows, scenario_id, ground_station_id) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      row_path = "#{path}[#{index}]"

      acc
      |> expect_optional_exact(row_path <> ".scenario_id", row["scenario_id"], scenario_id)
      |> expect_optional_exact(
        row_path <> ".ground_station_id",
        row["ground_station_id"],
        ground_station_id
      )
    end)
  end

  defp expect_optional_exact(issues, _path, nil, _expected), do: issues

  defp expect_optional_exact(issues, path, actual, expected),
    do: expect_exact(issues, path, actual, expected)

  defp validate_refresh_id(issues, artifact, policy, report) do
    refresh_input = map_at(policy, ["refresh_identity_input"])
    evidence = Map.get(report, "evidence")

    if is_map(evidence) and is_binary(artifact["study_id"]) do
      assumptions =
        refresh_input
        |> Map.get("model_assumptions", %{})
        |> Map.put(ExecutionPolicy.reserved_key(), policy)
        |> Map.put(ExecutionPolicy.evidence_key(), evidence)

      refresh = Map.put(refresh_input, "model_assumptions", assumptions)

      expected_refresh_id =
        BuildRefreshId.build(
          refresh,
          artifact["study_id"],
          &BuildGroundNetwork.build/1,
          &SourceObjectives.objectives/1
        )

      issues
      |> expect_exact("$.refresh_id", artifact["refresh_id"], expected_refresh_id)
      |> expect_exact(
        "$.candidate_refresh_execution.refresh_id",
        report["refresh_id"],
        expected_refresh_id
      )
    else
      [error("$.refresh_id", "could not be recomputed from captured inputs") | issues]
    end
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

  defp execution_evidence(%{
         "assumptions" => %{
           "model_assumptions" => %{} = assumptions
         }
       }) do
    Map.get(assumptions, ExecutionPolicy.evidence_key())
  end

  defp execution_evidence(_artifact), do: nil

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

  defp assumptions_evidence_path do
    "$.assumptions.model_assumptions.#{ExecutionPolicy.evidence_key()}"
  end

  defp map_at(map, path) do
    case get_in(map, path) do
      %{} = value -> value
      _value -> %{}
    end
  end

  defp list_at(map, path) do
    case get_in(map, path) do
      values when is_list(values) -> values
      _value -> []
    end
  end
end
