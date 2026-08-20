defmodule OrbitalDynamics.Schema.CandidateRefreshExecutionContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.CandidateRefresh.ExecutionPolicy
  alias OrbitalDynamics.Schema

  @generated_at ~U[2026-05-14 00:00:00Z]

  test "registers and exports the nested execution report contract with typed fields" do
    assert {:ok, contract} = Schema.contract("candidate_refresh_execution.v1")
    assert contract["artifact_family"] == "candidate_refresh_execution"

    assert {:ok, refresh_schema} = Schema.json_schema("candidate_refresh.v1")
    report = refresh_schema["properties"]["candidate_refresh_execution"]

    assert report["additionalProperties"] == false

    assert get_in(report, ["properties", "schema_contract", "const"]) ==
             "candidate_refresh_execution.v1"

    assert get_in(report, ["properties", "bundle_id", "const"]) ==
             ExecutionPolicy.bundle_id()

    assert get_in(report, ["properties", "policy_fingerprint", "pattern"]) ==
             "^[0-9a-f]{64}$"

    assert get_in(report, ["properties", "counts", "properties", "access_window_count"]) ==
             %{"type" => "integer", "minimum" => 0}

    assert get_in(report, ["properties", "external_validation", "properties", "case_id", "const"]) ==
             ExecutionPolicy.external_case_id()
  end

  test "validates all execution report bindings on a runner artifact" do
    artifact = run!()

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    policy = execution_policy(artifact)
    report = artifact["candidate_refresh_execution"]

    assert report["policies"] == Map.take(policy, ~w(propagation environment access eclipse))
    assert report["model_limits"] == ExecutionPolicy.model_limits()
  end

  test "keeps the execution report optional for legacy candidate-refresh artifacts" do
    artifact = run!()

    legacy_shape =
      artifact
      |> Map.delete("candidate_refresh_execution")
      |> update_in(["assumptions", "model_assumptions"], fn assumptions ->
        Map.delete(assumptions, ExecutionPolicy.reserved_key())
      end)

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(legacy_shape)
  end

  test "rejects orphaned execution policy or report" do
    artifact = run!()

    without_report = Map.delete(artifact, "candidate_refresh_execution")

    assert_error_path(without_report, "$.candidate_refresh_execution")

    without_policy =
      update_in(artifact, ["assumptions", "model_assumptions"], fn assumptions ->
        Map.delete(assumptions, ExecutionPolicy.reserved_key())
      end)

    assert_error_path(
      without_policy,
      "$.assumptions.model_assumptions.#{ExecutionPolicy.reserved_key()}"
    )
  end

  test "rejects tampered fingerprints, snapshots, counts, policies, validation scope, and limits" do
    artifact = run!()

    invalid_cases = [
      {put_in(
         artifact,
         ["candidate_refresh_execution", "policy_fingerprint"],
         String.duplicate("0", 64)
       ), "$.candidate_refresh_execution.policy_fingerprint"},
      {put_in(artifact, ["candidate_refresh_execution", "snapshot_id"], "another_snapshot"),
       "$.candidate_refresh_execution.snapshot_id"},
      {update_in(
         artifact,
         ["candidate_refresh_execution", "counts", "candidate_activity_count"],
         &(&1 + 1)
       ), "$.candidate_refresh_execution.counts.candidate_activity_count"},
      {put_in(
         artifact,
         ["candidate_refresh_execution", "policies", "access", "root_tolerance_s"],
         1.0
       ), "$.candidate_refresh_execution.policies.access"},
      {put_in(
         artifact,
         ["candidate_refresh_execution", "external_validation", "validation_scope"],
         "generalized"
       ), "$.candidate_refresh_execution.external_validation.validation_scope"},
      {put_in(artifact, ["candidate_refresh_execution", "model_limits"], []),
       "$.candidate_refresh_execution.model_limits"}
    ]

    for {invalid, path} <- invalid_cases, do: assert_error_path(invalid, path)
  end

  test "rejects a tampered serialized policy even when its displayed fingerprint is recomputed" do
    artifact = run!()
    policy = execution_policy(artifact)

    changed =
      policy
      |> put_in(["provider_revisions", "earth_rotation"], "untrusted-revision")
      |> then(fn value ->
        Map.put(value, "policy_fingerprint", ExecutionPolicy.fingerprint(value))
      end)

    tampered =
      artifact
      |> put_in(
        ["assumptions", "model_assumptions", ExecutionPolicy.reserved_key()],
        changed
      )
      |> put_in(
        ["candidate_refresh_execution", "policy_fingerprint"],
        changed["policy_fingerprint"]
      )

    assert_error_path(
      tampered,
      "$.assumptions.model_assumptions.#{ExecutionPolicy.reserved_key()}"
    )
  end

  defp run! do
    assert {:ok, artifact} = CandidateRefresh.run(refresh(), generated_at: @generated_at)
    artifact
  end

  defp assert_error_path(artifact, path) do
    assert {:error, report} = Schema.validate_artifact(artifact)
    assert Enum.any?(report["errors"], &(&1["path"] == path))
  end

  defp execution_policy(artifact) do
    get_in(artifact, ["assumptions", "model_assumptions", ExecutionPolicy.reserved_key()])
  end

  defp refresh do
    %{
      "accepted_planning_state" => %{
        "schema_version" => 1,
        "schema_contract" => "accepted_planning_state.v1",
        "artifact_type" => "accepted_planning_state",
        "snapshot_id" => "snapshot_a",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [
          %{
            "spacecraft_id" => "sat_a",
            "scenario_id" => "scenario_a",
            "epoch" => %{"seconds_since_j2000" => 0.0, "time_scale" => "tdb"},
            "frame" => "earth_inertial_j2000",
            "state_vector" => %{
              "position_km" => [7_000.0, 0.0, 0.0],
              "velocity_km_s" => [0.0, 7.5, 0.0]
            },
            "source" => %{"system" => "operator_import", "source_id" => "state_a"},
            "provenance" => %{"trust_boundary" => "operator_supplied"},
            "quality" => %{"level" => "accepted"}
          }
        ],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "cadence_snapshot", "source_id" => "snapshot_a"},
        "quality" => %{"level" => "planning_accepted"},
        "provenance" => %{"created_by" => "test"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 10.0
      },
      "spacecraft" => %{
        "spacecraft_id" => "sat_a",
        "scenario_id" => "scenario_a",
        "dry_mass_kg" => 100.0,
        "propellant_mass_kg" => 5.0,
        "drag_area_m2" => 2.0,
        "drag_coefficient" => 2.2
      },
      "ground_station" => %{
        "ground_station_id" => "station_a",
        "latitude_deg" => 0.0,
        "longitude_deg" => 0.0,
        "altitude_km" => 0.0,
        "minimum_elevation_deg" => 5.0
      },
      "constraints" => %{"avoid_eclipse" => true},
      "scoring_policy" => %{
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{}
    }
  end
end
