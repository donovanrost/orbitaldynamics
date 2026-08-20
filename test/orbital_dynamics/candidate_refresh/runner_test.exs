defmodule OrbitalDynamics.CandidateRefresh.RunnerTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.CandidateRefresh.{Build, ExecutionPolicy}
  alias OrbitalDynamics.{ResultSet, Schema}

  @generated_at ~U[2026-05-14 00:00:00Z]

  test "runs the fixed offline bundle and binds its captured policy into identity" do
    assert {:ok, artifact} = CandidateRefresh.run(refresh(), generated_at: @generated_at)

    policy =
      get_in(artifact, ["assumptions", "model_assumptions", ExecutionPolicy.reserved_key()])

    report = artifact["candidate_refresh_execution"]

    assert :ok = ExecutionPolicy.validate_serialized(policy)
    assert policy["policy_fingerprint"] == report["policy_fingerprint"]
    assert report["bundle_id"] == ExecutionPolicy.bundle_id()
    assert report["execution_mode"] == "offline_deterministic"
    assert report["snapshot_id"] == artifact["snapshot_id"]
    assert report["model_limits"] == ExecutionPolicy.model_limits()

    assert report["external_validation"] == %{
             "case_id" => "orekit_13_1_7_leo_j2_drag_access_eclipse",
             "validation_scope" => "exact_case_only",
             "status" => "referenced_not_evaluated_by_runner"
           }

    assert artifact["refreshed_windows"]["target_visibility_windows"] == []
    assert Enum.all?(artifact["candidate_activities"], &(&1["type"] == "downlink"))

    assert report["counts"]["candidate_activity_count"] ==
             length(artifact["candidate_activities"])

    assert report["counts"]["access_window_count"] ==
             length(artifact["refreshed_windows"]["access_windows"])

    assert report["counts"]["eclipse_interval_count"] ==
             length(artifact["refreshed_windows"]["eclipse_intervals"])

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(artifact)
  end

  test "preserves bracketed-bisection refinement metadata on regenerated access" do
    assert {:ok, artifact} = CandidateRefresh.run(refresh(), generated_at: @generated_at)
    assert [window | _rest] = artifact["refreshed_windows"]["access_windows"]

    assumptions = window["assumptions"]
    assert assumptions["boundary_refinement"] == "aos_los_bracketed_bisection"
    assert is_map(assumptions["start_boundary_detail"])
    assert is_map(assumptions["end_boundary_detail"])

    root_detail =
      Enum.find(
        [assumptions["start_boundary_detail"], assumptions["end_boundary_detail"]],
        &(&1["root_solved"] == true)
      )

    assert root_detail["root_solver"] == "bisection"
    assert root_detail["requested_root_tolerance_s"] == 1.0e-6
    assert root_detail["root_max_iterations"] == 64
    assert assumptions["confidence"] == "mixed_root_refined_and_sample_clipped"
  end

  test "is deterministic for the same input and generated_at and invariant to declared list order" do
    input =
      refresh()
      |> Map.put("targets", [%{"id" => "target_b"}, %{"id" => "target_a"}])
      |> Map.put("prior_candidate_activities", [
        %{"id" => "prior_b", "type" => "downlink", "scenario_id" => "scenario_a"},
        %{"id" => "prior_a", "type" => "downlink", "scenario_id" => "scenario_a"}
      ])

    reversed =
      input
      |> Map.update!("targets", &Enum.reverse/1)
      |> Map.update!("prior_candidate_activities", &Enum.reverse/1)

    assert {:ok, left} = CandidateRefresh.run(input, generated_at: @generated_at)
    assert {:ok, same} = CandidateRefresh.run(input, generated_at: @generated_at)
    assert {:ok, right} = CandidateRefresh.run(reversed, generated_at: @generated_at)

    assert left == same
    assert left == right
  end

  test "state, ballistic properties, and station geometry bind policy fingerprint and refresh id" do
    assert {:ok, base} = CandidateRefresh.run(refresh(), generated_at: @generated_at)

    changed_state =
      update_in(
        refresh(),
        [
          "accepted_planning_state",
          "spacecraft_states",
          Access.at(0),
          "state_vector",
          "position_km"
        ],
        fn [x, y, z] -> [x + 1.0, y, z] end
      )

    changed_ballistics = put_in(refresh(), ["spacecraft", "drag_area_m2"], 2.5)
    changed_station = put_in(refresh(), ["ground_station", "longitude_deg"], 1.0)

    for changed <- [changed_state, changed_ballistics, changed_station] do
      assert {:ok, artifact} = CandidateRefresh.run(changed, generated_at: @generated_at)
      refute fingerprint(artifact) == fingerprint(base)
      refute artifact["refresh_id"] == base["refresh_id"]
    end
  end

  test "provider or detector drift changes canonical material and is rejected as a captured policy" do
    assert {:ok, artifact} = CandidateRefresh.run(refresh(), generated_at: @generated_at)
    policy = execution_policy(artifact)
    base_refresh_id = refresh_id_for_policy(policy)

    for path <- [
          ["provider_revisions", "atmosphere"],
          ["access", "source_revision"],
          ["eclipse", "source_revision"]
        ] do
      tampered = put_in(policy, path, "tampered-revision")
      refute ExecutionPolicy.fingerprint(tampered) == policy["policy_fingerprint"]

      tampered =
        Map.put(tampered, "policy_fingerprint", ExecutionPolicy.fingerprint(tampered))

      refute refresh_id_for_policy(tampered) == base_refresh_id
      assert {:error, _reason} = ExecutionPolicy.validate_serialized(tampered)

      assert {:error, {:candidate_refresh_execution_failed, :capture_policy, _reason}} =
               CandidateRefresh.run(
                 refresh()
                 |> Map.drop(["spacecraft", "ground_station"])
                 |> Map.put("execution_policy", tampered),
                 generated_at: @generated_at
               )
    end
  end

  test "zero regenerated events and zero candidates are valid" do
    input =
      refresh()
      |> put_in(["ground_station", "latitude_deg"], 90.0)
      |> put_in(["ground_station", "minimum_elevation_deg"], 90.0)
      |> put_in(["remaining_horizon", "ends_at_s"], 10.0)

    assert {:ok, artifact} = CandidateRefresh.run(input, generated_at: @generated_at)
    assert artifact["candidate_activities"] == []
    assert artifact["refreshed_windows"]["access_windows"] == []
    assert artifact["candidate_refresh_execution"]["counts"]["access_window_count"] == 0
    assert {:ok, _report} = Schema.validate_artifact(artifact)
  end

  test "input contract and physical-boundary failures are typed and atomic" do
    cases = [
      Map.delete(refresh(), "accepted_planning_state"),
      put_in(refresh(), ["accepted_planning_state", "spacecraft_states"], []),
      update_in(refresh(), ["accepted_planning_state", "spacecraft_states"], fn [state] ->
        [state, Map.put(state, "spacecraft_id", "sat_b")]
      end),
      put_in(refresh(), ["spacecraft", "spacecraft_id"], "sat_b"),
      put_in(
        refresh(),
        ["accepted_planning_state", "spacecraft_states", Access.at(0), "frame"],
        "itrf"
      ),
      put_in(
        refresh(),
        ["accepted_planning_state", "spacecraft_states", Access.at(0), "epoch", "time_scale"],
        "utc"
      ),
      put_in(refresh(), ["remaining_horizon", "starts_at_s"], 1.0),
      put_in(refresh(), ["remaining_horizon", "output_step_s"], 60.0),
      put_in(refresh(), ["remaining_horizon", "ends_at_s"], 0.0),
      put_in(refresh(), ["remaining_horizon", "ends_at_s"], 86_401.0),
      put_in(refresh(), ["spacecraft", "dry_mass_kg"], -1.0),
      put_in(refresh(), ["spacecraft", "drag_coefficient"], 6.0),
      put_in(refresh(), ["ground_station", "latitude_deg"], 91.0)
    ]

    for invalid <- cases do
      result = CandidateRefresh.run(invalid, generated_at: @generated_at)
      assert {:error, {:candidate_refresh_execution_failed, :validate_input, _reason}} = result
      refute match?({:ok, %{"artifact_type" => "candidate_refresh"}}, result)
    end
  end

  test "rejects maneuvers, reserved collisions, custom modules, campaign providers, and network access" do
    cases = [
      put_in(refresh(), ["accepted_planning_state", "maneuver_execution_deltas"], [
        %{
          "activity_id" => "burn_a",
          "status" => "completed",
          "source" => %{"system" => "ops"},
          "provenance" => %{"trust_boundary" => "operator_supplied"},
          "quality" => %{"level" => "accepted"}
        }
      ]),
      put_in(
        refresh(),
        ["model_assumptions", ExecutionPolicy.reserved_key()],
        %{"collision" => true}
      ),
      Map.put(refresh(), "candidate_refresh_execution", %{}),
      Map.put(refresh(), "propagator", "Arbitrary.Propagator"),
      Map.put(refresh(), "campaign_environment", %{"provider" => "campaign"}),
      Map.put(refresh(), "network_access", true)
    ]

    for invalid <- cases do
      assert {:error, {:candidate_refresh_execution_failed, :validate_input, _reason}} =
               CandidateRefresh.run(invalid, generated_at: @generated_at)
    end
  end

  test "rejects duplicate aliases and conflicting ground-network geometry" do
    duplicate_aliases = Map.put(refresh(), "station", refresh()["ground_station"])

    conflicting_geometry =
      Map.put(refresh(), "ground_network", [
        refresh()["ground_station"]
        |> Map.put("longitude_deg", 20.0)
      ])

    for invalid <- [duplicate_aliases, conflicting_geometry] do
      assert {:error, {:candidate_refresh_execution_failed, :validate_input, _reason}} =
               CandidateRefresh.run(invalid, generated_at: @generated_at)
    end
  end

  test "public JSON boundary rejects lossy values, unsupported keys, and improper lists" do
    improper = ["valid" | "not-a-list"]

    invalid_values = [
      self(),
      fn -> :ok end,
      make_ref(),
      <<1::size(1)>>,
      %URI{scheme: "https", host: "example.test"},
      improper,
      {1.0, 2.0, 3.0},
      :atom_value,
      Integer.pow(10, 301)
    ]

    for value <- invalid_values do
      assert {:error, _reason} = ExecutionPolicy.normalize_json_input(%{"value" => value})

      assert {:error, {:candidate_refresh_execution_failed, :validate_input, _reason}} =
               CandidateRefresh.run(Map.put(refresh(), "audit_value", value),
                 generated_at: @generated_at
               )
    end

    assert {:error, _reason} = ExecutionPolicy.normalize_json_input(%{1 => "unsupported"})
  end

  test "rejects atom/string key collapse before normalization even when values agree" do
    for value <- [
          %{
            :bundle_id => ExecutionPolicy.bundle_id(),
            "bundle_id" => ExecutionPolicy.bundle_id()
          },
          %{:bundle_id => "one", "bundle_id" => "two"}
        ] do
      assert {:error, {:duplicate_normalized_key, "$", "bundle_id"}} =
               ExecutionPolicy.normalize_json_input(value)

      assert {:error, _reason} = ExecutionPolicy.validate_request(value)
    end

    assert {:error, {:duplicate_aliases, :bundle_id}} =
             ExecutionPolicy.validate_request(%{
               "bundle" => ExecutionPolicy.bundle_id(),
               "bundle_id" => ExecutionPolicy.bundle_id()
             })
  end

  test "legacy build facade remains exactly equal to the unchanged builder" do
    result_set =
      ResultSet.new!(%{
        study_id: :legacy_study,
        trajectory_results: [],
        event_results: [],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    opts = [candidate_refresh: legacy_refresh(), generated_at: @generated_at]
    assert CandidateRefresh.build(result_set, opts) == Build.build(result_set, opts)
  end

  defp refresh do
    %{
      "accepted_planning_state" => accepted_planning_state(),
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

  defp accepted_planning_state do
    %{
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
    }
  end

  defp legacy_refresh do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "snapshot_a",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [%{"spacecraft_id" => "sat_a", "scenario_id" => "scenario_a"}],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "test"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "test"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      }
    }
  end

  defp execution_policy(artifact) do
    get_in(artifact, ["assumptions", "model_assumptions", ExecutionPolicy.reserved_key()])
  end

  defp fingerprint(artifact), do: execution_policy(artifact)["policy_fingerprint"]

  defp refresh_id_for_policy(policy) do
    result_set =
      ResultSet.new!(%{
        study_id: :identity_probe,
        trajectory_results: [],
        event_results: [],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    refresh =
      Map.put(legacy_refresh(), "model_assumptions", %{
        ExecutionPolicy.reserved_key() => policy
      })

    result_set
    |> CandidateRefresh.build(candidate_refresh: refresh, generated_at: @generated_at)
    |> Map.fetch!("refresh_id")
  end
end
