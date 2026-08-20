defmodule OrbitalDynamics.Schema.CandidateRefreshExecutionContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  alias OrbitalDynamics.CandidateRefresh.{
    BuildGroundNetwork,
    BuildRefreshId,
    ExecutionPolicy,
    SourceObjectives
  }

  alias OrbitalDynamics.Schema

  @generated_at ~U[2026-05-14 00:00:00Z]
  @execution_report_fields ~w(
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

    assert get_in(report, ["properties", "evidence", "additionalProperties"]) == false

    assert get_in(report, [
             "properties",
             "evidence",
             "properties",
             "access_windows_sha256",
             "pattern"
           ]) ==
             "^[0-9a-f]{64}$"

    assert get_in(report, [
             "properties",
             "evidence",
             "properties",
             "candidate_source_windows_sha256",
             "pattern"
           ]) == "^[0-9a-f]{64}$"

    assert get_in(report, ["properties", "external_validation", "properties", "case_id", "const"]) ==
             ExecutionPolicy.external_case_id()

    assert {:ok, standalone_schema} = Schema.json_schema("candidate_refresh_execution.v1")

    assert Map.take(standalone_schema, [
             "type",
             "additionalProperties",
             "required",
             "properties"
           ]) == report

    assert standalone_schema["properties"]["bundle_id"]["type"] == "string"
    assert standalone_schema["properties"]["policy_fingerprint"]["type"] == "string"
  end

  test "validates a real runner execution report as a standalone artifact" do
    report = run!()["candidate_refresh_execution"]

    assert {:ok,
            %{
              "schema_contract" => "candidate_refresh_execution.v1",
              "artifact_family" => "candidate_refresh_execution",
              "status" => "pass"
            }} = Schema.validate_artifact(report)
  end

  test "standalone validation rejects the exact all-nil required-field probe" do
    all_nil =
      @execution_report_fields
      |> Map.new(&{&1, nil})
      |> Map.put("schema_contract", "candidate_refresh_execution.v1")

    assert {:error, %{"status" => "fail", "errors" => [_first | _rest]}} =
             Schema.validate_artifact(all_nil)
  end

  test "standalone validation rejects nil, wrong-type, unknown, and unsafe fields without raising" do
    report = run!()["candidate_refresh_execution"]

    for field <- @execution_report_fields do
      report
      |> Map.put(field, nil)
      |> assert_standalone_error("$.#{field}")
    end

    invalid_cases = [
      {Map.put(report, "bundle_id", %{}), "$.bundle_id"},
      {Map.put(report, "unexpected", true), "$.unexpected"},
      {Map.put(report, "policies", []), "$.policies"},
      {put_in(report, ["evidence", "access_windows_sha256"], String.duplicate("A", 64)),
       "$.evidence.access_windows_sha256"},
      {put_in(report, ["counts", "access_window_count"], -1), "$.counts.access_window_count"},
      {put_in(report, ["external_validation", "case_id"], []), "$.external_validation.case_id"},
      {put_in(report, ["policies", "access", "capability"], []), "$.policies.access.capability"},
      {Map.put(report, "policy_fingerprint", self()), "$.policy_fingerprint"}
    ]

    for {invalid, path} <- invalid_cases, do: assert_standalone_error(invalid, path)
  end

  test "standalone validation rejects static and report-internal nested contradictions" do
    report = run!()["candidate_refresh_execution"]

    invalid_cases = [
      {Map.put(report, "schema_contract", "candidate_refresh_execution.v2"), "$.schema_contract"},
      {Map.put(report, "bundle_id", "candidate_refresh.other.v1"), "$.bundle_id"},
      {Map.put(report, "execution_mode", "online"), "$.execution_mode"},
      {Map.put(report, "refresh_id", "not a stable id"), "$.refresh_id"},
      {put_in(report, ["evidence", "scenario_id"], "scenario_other"), "$.evidence.scenario_id"},
      {put_in(report, ["evidence", "trajectory_sample_count"], 1),
       "$.evidence.trajectory_sample_count"},
      {put_in(report, ["counts", "spacecraft_state_count"], 2),
       "$.counts.spacecraft_state_count"},
      {put_in(report, ["counts", "downlink_candidate_count"], 99),
       "$.counts.downlink_candidate_count"},
      {put_in(report, ["counts", "trajectory_sample_count"], 99),
       "$.counts.trajectory_sample_count"},
      {put_in(report, ["policies", "propagation", "max_step_s"], 20.0),
       "$.policies.propagation.max_step_s"},
      {put_in(report, ["policies", "access", "root_tolerance_s"], 1.0),
       "$.policies.access.root_tolerance_s"},
      {put_in(report, ["policies", "eclipse", "candidate_source"], true),
       "$.policies.eclipse.candidate_source"},
      {put_in(report, ["external_validation", "validation_scope"], "generalized"),
       "$.external_validation.validation_scope"},
      {Map.put(report, "model_limits", []), "$.model_limits"},
      {update_in(report, ["evidence"], &Map.put(&1, "unexpected", true)),
       "$.evidence.unexpected"},
      {update_in(report, ["counts"], &Map.put(&1, "unexpected", 0)), "$.counts.unexpected"},
      {update_in(report, ["policies"], &Map.put(&1, "unexpected", %{})), "$.policies.unexpected"},
      {update_in(report, ["policies", "access"], &Map.put(&1, "unexpected", true)),
       "$.policies.access.unexpected"},
      {update_in(report, ["external_validation"], &Map.put(&1, "unexpected", true)),
       "$.external_validation.unexpected"}
    ]

    for {invalid, path} <- invalid_cases, do: assert_standalone_error(invalid, path)
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
        assumptions
        |> Map.delete(ExecutionPolicy.reserved_key())
        |> Map.delete(ExecutionPolicy.evidence_key())
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

    without_evidence =
      update_in(artifact, ["assumptions", "model_assumptions"], fn assumptions ->
        Map.delete(assumptions, ExecutionPolicy.evidence_key())
      end)

    assert_error_path(
      without_evidence,
      "$.assumptions.model_assumptions.#{ExecutionPolicy.evidence_key()}"
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

  test "rejects coherent count and identity substitutions across execution surfaces" do
    artifact = run!()

    forged_count =
      artifact
      |> put_in(["candidate_refresh_execution", "counts", "trajectory_sample_count"], 999)
      |> put_in(["candidate_refresh_execution", "evidence", "trajectory_sample_count"], 999)
      |> put_in(
        [
          "assumptions",
          "model_assumptions",
          ExecutionPolicy.evidence_key(),
          "trajectory_sample_count"
        ],
        999
      )

    substituted_snapshot =
      artifact
      |> Map.put("snapshot_id", "snapshot_other")
      |> put_in(["accepted_planning_state", "snapshot_id"], "snapshot_other")
      |> put_in(["provenance", "accepted_planning_state", "snapshot_id"], "snapshot_other")
      |> put_in(["candidate_refresh_execution", "snapshot_id"], "snapshot_other")

    substituted_scenario =
      artifact
      |> put_in(["candidate_refresh_execution", "scenario_id"], "scenario_other")
      |> put_in(["candidate_refresh_execution", "evidence", "scenario_id"], "scenario_other")
      |> put_in(
        ["assumptions", "model_assumptions", ExecutionPolicy.evidence_key(), "scenario_id"],
        "scenario_other"
      )

    substituted_station =
      artifact
      |> put_in(["candidate_refresh_execution", "ground_station_id"], "station_other")
      |> put_in(
        ["candidate_refresh_execution", "evidence", "ground_station_id"],
        "station_other"
      )
      |> put_in(
        [
          "assumptions",
          "model_assumptions",
          ExecutionPolicy.evidence_key(),
          "ground_station_id"
        ],
        "station_other"
      )

    forged_refresh_id =
      artifact
      |> Map.put("refresh_id", "candidate_refresh:scenario_a:0000000000000000")
      |> put_in(
        ["candidate_refresh_execution", "refresh_id"],
        "candidate_refresh:scenario_a:0000000000000000"
      )

    for invalid <- [
          forged_count,
          substituted_snapshot,
          substituted_scenario,
          substituted_station,
          forged_refresh_id
        ] do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert report["errors"] != []
    end
  end

  test "rejects shifted or reidentified access even when dependent evidence is updated coherently" do
    artifact = run!()
    [window | _rest] = get_in(artifact, ["refreshed_windows", "access_windows"])
    source_window_id = window["id"]

    shifted =
      artifact
      |> update_in(["refreshed_windows", "access_windows"], fn [first | rest] ->
        [
          first
          |> Map.update!("starts_at_s", &(&1 + 1.0))
          |> Map.update!("sample_count", &max(&1 - 1, 0))
          | rest
        ]
      end)
      |> update_in(["candidate_activities"], fn candidates ->
        Enum.map(candidates, fn candidate ->
          if candidate["source_window_id"] == source_window_id do
            candidate
            |> Map.update!("starts_at_s", &(&1 + 1.0))
            |> Map.update!("duration_s", &(&1 - 1.0))
          else
            candidate
          end
        end)
      end)

    shifted = put_in(shifted, ["source_window_lineage"], recomputed_lineage(shifted))

    {:ok, shifted_digest} =
      ExecutionPolicy.canonical_sha256(get_in(shifted, ["refreshed_windows", "access_windows"]))

    shifted = put_evidence_value(shifted, "access_windows_sha256", shifted_digest)

    assert_error_path(shifted, "$.refresh_id")

    wrong_station =
      artifact
      |> update_in(["refreshed_windows", "access_windows"], fn windows ->
        Enum.map(windows, &Map.put(&1, "ground_station_id", "station_other"))
      end)
      |> update_in(["candidate_activities"], fn candidates ->
        Enum.map(candidates, &Map.put(&1, "ground_station_id", "station_other"))
      end)

    assert_error_path(
      wrong_station,
      "$.refreshed_windows.access_windows[0].ground_station_id"
    )

    tampered_window_id = source_window_id <> ":tampered"

    reidentified =
      artifact
      |> update_in(["refreshed_windows", "access_windows"], fn [first | rest] ->
        [Map.put(first, "id", tampered_window_id) | rest]
      end)
      |> update_in(["candidate_activities"], fn candidates ->
        Enum.map(candidates, fn candidate ->
          if candidate["source_window_id"] == source_window_id,
            do: Map.put(candidate, "source_window_id", tampered_window_id),
            else: candidate
        end)
      end)

    reidentified =
      put_in(reidentified, ["source_window_lineage"], recomputed_lineage(reidentified))

    {:ok, reidentified_digest} =
      ExecutionPolicy.canonical_sha256(
        get_in(reidentified, ["refreshed_windows", "access_windows"])
      )

    reidentified =
      put_evidence_value(reidentified, "access_windows_sha256", reidentified_digest)

    assert_error_path(reidentified, "$.refreshed_windows.access_windows[0].id")
  end

  test "binds every retained candidate source-window field to regenerated access evidence" do
    artifact = run!()
    evidence = artifact["candidate_refresh_execution"]["evidence"]
    access_windows = get_in(artifact, ["refreshed_windows", "access_windows"])

    assert {:ok, bindings} =
             ExecutionPolicy.candidate_source_window_bindings(access_windows)

    assert {:ok, expected_digest} = ExecutionPolicy.canonical_sha256(bindings)
    assert evidence["candidate_source_windows_sha256"] == expected_digest

    [candidate | _rest] = artifact["candidate_activities"]
    original_refresh_id = artifact["refresh_id"]

    tampered =
      artifact
      |> update_in(["candidate_activities"], fn candidates ->
        Enum.map(candidates, fn row ->
          if row["id"] == candidate["id"] do
            put_in(row, ["source_window", "confidence"], "forged_confidence")
          else
            row
          end
        end)
      end)
      |> then(&put_in(&1, ["source_window_lineage"], recomputed_lineage(&1)))

    assert tampered["refresh_id"] == original_refresh_id
    assert_error_path(tampered, "$.candidate_activities[0].source_window")
  end

  test "rejects repinned persisted-policy body, frame, time, epoch, and horizon contradictions" do
    artifact = run!()

    mutators = [
      fn policy ->
        put_in(
          policy,
          [
            "refresh_identity_input",
            "accepted_planning_state",
            "spacecraft_states",
            Access.at(0),
            "metadata"
          ],
          %{"body" => "mars"}
        )
      end,
      fn policy ->
        put_in(
          policy,
          [
            "refresh_identity_input",
            "accepted_planning_state",
            "spacecraft_states",
            Access.at(0),
            "metadata"
          ],
          %{"frame" => "itrf"}
        )
      end,
      fn policy ->
        put_in(
          policy,
          [
            "refresh_identity_input",
            "accepted_planning_state",
            "spacecraft_states",
            Access.at(0),
            "metadata"
          ],
          %{"time_scale" => "utc"}
        )
      end,
      &put_in(
        &1,
        ["refresh_identity_input", "accepted_planning_state", "current_epoch_s"],
        10.0
      ),
      &put_in(
        &1,
        ["refresh_identity_input", "accepted_planning_state", "remaining_horizon"],
        %{"starts_at_s" => 0.0, "ends_at_s" => 610.0, "output_step_s" => 10.0}
      )
    ]

    for mutate <- mutators do
      invalid =
        artifact
        |> execution_policy()
        |> mutate.()
        |> repin_policy(artifact)

      assert_error_path(
        invalid,
        "$.assumptions.model_assumptions.#{ExecutionPolicy.reserved_key()}"
      )
    end
  end

  test "rejects a fully repinned contradictory propagator identity at its exact persisted path" do
    artifact = run!()

    policy =
      artifact
      |> execution_policy()
      |> put_in(
        ["refresh_identity_input", "propagator"],
        "Untrusted.Propagator"
      )
      |> repin_policy_document()

    assert {:error,
            {:conflicting_execution_identity, "$.refresh_identity_input.propagator",
             "OrbitalDynamics.Propagators.J2Drag", "Untrusted.Propagator"}} =
             ExecutionPolicy.validate_serialized(policy)

    repinned = repin_policy(policy, artifact)

    assert_error_path(
      repinned,
      "$.assumptions.model_assumptions.#{ExecutionPolicy.reserved_key()}.refresh_identity_input.propagator"
    )
  end

  test "rejects every persisted module and evaluator contradiction including secondary aliases" do
    policy = run!() |> execution_policy()

    fixed_surface_mutators = [
      {~w(propagation module), "Untrusted.Propagator"},
      {~w(environment atmosphere_provider module), ""},
      {~w(environment atmosphere_provider evaluation_api), false},
      {~w(environment earth_rotation_provider module), true},
      {~w(access module), :null},
      {~w(eclipse module), "Untrusted.Detector"}
    ]

    for {path, value} <- fixed_surface_mutators do
      expected_path = "$." <> Enum.join(path, ".")
      invalid = put_in(policy, path, value)

      assert {:error, {:conflicting_execution_identity, ^expected_path, _expected, ^value}} =
               ExecutionPolicy.validate_serialized(invalid)
    end

    aliases = [
      {"propagator", "OrbitalDynamics.Propagators.J2Drag"},
      {"atmosphere_provider", "OrbitalDynamics.Environment.ExponentialAtmosphereProvider"},
      {"earth_rotation_provider", "OrbitalDynamics.Environment.ConstantEarthRotationProvider"},
      {"sun_direction_provider", "OrbitalDynamics.Environment.FixedSunProvider"},
      {"access_detector", "OrbitalDynamics.EventDetectors.AccessWindows"},
      {"eclipse_detector", "OrbitalDynamics.EventDetectors.Eclipses"}
    ]

    for {{field, _expected}, value} <-
          Enum.zip(aliases, ["", :null, false, true, "Untrusted.Access", "Untrusted.Eclipse"]) do
      invalid =
        policy
        |> update_in(["refresh_identity_input"], fn refresh_identity ->
          Map.update(
            refresh_identity,
            "mission_state",
            %{field => value},
            &Map.put(&1, field, value)
          )
        end)
        |> repin_policy_document()

      expected_path = "$.refresh_identity_input.mission_state.#{field}"

      assert {:error, {:conflicting_execution_identity, ^expected_path, _expected, ^value}} =
               ExecutionPolicy.validate_serialized(invalid)
    end

    nil_policy = put_in(policy, ["refresh_identity_input", "propagator"], nil)

    assert {:error, {:noncanonical_null, "$.refresh_identity_input.propagator"}} =
             ExecutionPolicy.validate_serialized(nil_policy)

    collision =
      update_in(policy, ["refresh_identity_input"], fn refresh_identity ->
        refresh_identity
        |> Map.put("propagator", "OrbitalDynamics.Propagators.J2Drag")
        |> Map.put(:propagator, "OrbitalDynamics.Propagators.J2Drag")
      end)

    assert {:error, {:duplicate_normalized_key, "$.refresh_identity_input", "propagator"}} =
             ExecutionPolicy.validate_serialized(collision)
  end

  test "runner artifact is nil-free and survives the repository OTP JSON stack identically" do
    artifact = run!()
    policy = execution_policy(artifact)

    assert nil_paths(artifact) == []
    assert get_in(policy, ["provider_coverage", "atmosphere", "starts_at_s"]) == :null
    assert get_in(policy, ["provider_coverage", "atmosphere", "ends_at_s"]) == :null
    assert get_in(policy, ["network_access"]) == false

    decoded = artifact |> :json.encode() |> IO.iodata_to_binary() |> :json.decode()

    assert decoded == artifact
    assert nil_paths(decoded) == []
    assert execution_policy(decoded)["policy_fingerprint"] == policy["policy_fingerprint"]
    assert decoded["refresh_id"] == artifact["refresh_id"]
    assert decoded["candidate_refresh_execution"]["refresh_id"] == artifact["refresh_id"]
    assert :ok = ExecutionPolicy.validate_serialized(execution_policy(decoded))
    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(decoded)
  end

  test "whole candidate-refresh preflight rejects unsafe terms and improper containers without raises" do
    artifact = run!()
    policy = execution_policy(artifact)
    improper = [%{"id" => "row"} | %{"not" => "a list"}]

    invalid_cases = [
      Map.put(artifact, :refresh_id, artifact["refresh_id"]),
      update_in(artifact, ["assumptions", "model_assumptions"], fn assumptions ->
        Map.put(assumptions, :candidate_refresh_execution_policy, policy)
      end),
      put_in(artifact, ["assumptions", "model_assumptions", "unsafe"], self()),
      put_in(artifact, ["assumptions", "model_assumptions", "unsafe"], fn -> :unsafe end),
      put_in(artifact, ["assumptions", "model_assumptions", "unsafe"], {1, 2}),
      put_in(artifact, ["assumptions", "model_assumptions", "unsafe"], %URI{}),
      put_in(artifact, ["assumptions", "model_assumptions", "unsafe"], nil),
      put_in(artifact, ["assumptions", "model_assumptions", "unsafe"], <<1::size(1)>>),
      put_in(artifact, ["assumptions", "model_assumptions", "unsafe"], <<255>>),
      update_in(artifact, ["assumptions", "model_assumptions"], &Map.put(&1, 1, "bad key")),
      Map.put(artifact, "candidate_activities", improper)
    ]

    for invalid <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert is_list(report["errors"]) and report["errors"] != []
    end

    canonical_null =
      put_in(artifact, ["assumptions", "model_assumptions", "optional_review_value"], :null)

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(canonical_null)
  end

  test "public validation returns errors rather than raising for hostile execution values" do
    artifact = run!()

    invalid_cases = [
      put_in(artifact, ["candidate_refresh_execution", "evidence"], %{"value" => self()}),
      put_in(
        artifact,
        ["assumptions", "model_assumptions", ExecutionPolicy.reserved_key()],
        %{"policy_fingerprint" => fn -> :not_json end}
      ),
      put_in(
        artifact,
        ["candidate_refresh_execution", "policies", "access"],
        Enum.reduce(1..34, "leaf", fn _index, acc -> %{"child" => acc} end)
      )
    ]

    for invalid <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert is_list(report["errors"]) and report["errors"] != []
    end
  end

  defp run! do
    assert {:ok, artifact} = CandidateRefresh.run(refresh(), generated_at: @generated_at)
    artifact
  end

  defp assert_error_path(artifact, path) do
    assert {:error, report} = Schema.validate_artifact(artifact)
    assert Enum.any?(report["errors"], &(&1["path"] == path))
  end

  defp assert_standalone_error(report, path) do
    assert {:error, validation} =
             Schema.validate_artifact(report, schema_contract: "candidate_refresh_execution.v1")

    assert Enum.any?(validation["errors"], &(&1["path"] == path))
  end

  defp execution_policy(artifact) do
    get_in(artifact, ["assumptions", "model_assumptions", ExecutionPolicy.reserved_key()])
  end

  defp put_evidence_value(artifact, field, value) do
    artifact
    |> put_in(["candidate_refresh_execution", "evidence", field], value)
    |> put_in(
      ["assumptions", "model_assumptions", ExecutionPolicy.evidence_key(), field],
      value
    )
  end

  defp recomputed_lineage(artifact) do
    OrbitalDynamics.CandidateRefresh.SourceWindowLineage.build(artifact["candidate_activities"])
  end

  defp repin_policy(policy, artifact) do
    policy = repin_policy_document(policy)
    evidence = artifact["candidate_refresh_execution"]["evidence"]

    refresh =
      update_in(policy["refresh_identity_input"], [Access.key("model_assumptions", %{})], fn
        assumptions ->
          assumptions
          |> Map.put(ExecutionPolicy.reserved_key(), policy)
          |> Map.put(ExecutionPolicy.evidence_key(), evidence)
      end)

    refresh_id =
      BuildRefreshId.build(
        refresh,
        artifact["study_id"],
        &BuildGroundNetwork.build/1,
        &SourceObjectives.objectives/1
      )

    artifact
    |> put_in(
      ["assumptions", "model_assumptions", ExecutionPolicy.reserved_key()],
      policy
    )
    |> put_in(["candidate_refresh_execution", "policy_fingerprint"], policy["policy_fingerprint"])
    |> Map.put("refresh_id", refresh_id)
    |> put_in(["candidate_refresh_execution", "refresh_id"], refresh_id)
  end

  defp repin_policy_document(policy) do
    Map.put(policy, "policy_fingerprint", ExecutionPolicy.fingerprint(policy))
  end

  defp nil_paths(value, path \\ "$")

  defp nil_paths(nil, path), do: [path]

  defp nil_paths(%{} = map, path) do
    Enum.flat_map(map, fn {key, value} -> nil_paths(value, path <> "." <> to_string(key)) end)
  end

  defp nil_paths(values, path) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.flat_map(fn {value, index} -> nil_paths(value, "#{path}[#{index}]") end)
  end

  defp nil_paths(_value, _path), do: []

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
