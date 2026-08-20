defmodule Mix.Tasks.OrbitalDynamics.Study.RunTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "runs a study manifest and writes an artifact" do
    manifest_path = Path.join(System.tmp_dir!(), "orbital_dynamics_manifest_task_test.json")
    output_path = Path.join(System.tmp_dir!(), "orbital_dynamics_manifest_task_result.json")

    on_exit(fn ->
      File.rm(manifest_path)
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.study.run")
    end)

    File.write!(manifest_path, json_manifest())

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.run", [
          "--manifest",
          manifest_path,
          "--output",
          output_path,
          "--run-id",
          "task_manifest-fixed-run",
          "--generated-at",
          "2026-05-14T00:00:00Z"
        ])
      end)

    assert output =~ "OrbitalDynamics manifest study"
    assert output =~ "study: task_manifest"
    assert output =~ "run: task_manifest-fixed-run"
    assert File.read!(output_path) =~ ~s("study_id":"task_manifest")
    assert File.read!(output_path) =~ ~s("eclipse_intervals")

    artifact = output_path |> File.read!() |> :json.decode()

    assert artifact["generated_at"] == "2026-05-14T00:00:00Z"
    assert artifact["run"]["id"] == "task_manifest-fixed-run"
    assert artifact["run"]["metadata"]["manifest"]["path"] == manifest_path
    assert artifact["run"]["metadata"]["manifest"]["sha256"] == sha256(json_manifest())
    assert artifact["run"]["metadata"]["external_provider_policy"]["network_access"] == "none"
    assert artifact["assumptions"]["external_provider_policy"]["hidden_network_calls"] == false

    assert artifact["run"]["metadata"]["backend_selection_policy"]["policy"] ==
             "reference_default"

    assert artifact["assumptions"]["backend_selection_policy"]["performance_claim"] =~
             "benchmark artifacts"
  end

  test "prints a machine-readable JSON summary" do
    manifest_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_manifest_task_json_#{System.unique_integer([:positive])}.json"
      )

    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_manifest_task_json_result_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(manifest_path)
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.study.run")
    end)

    File.write!(manifest_path, json_manifest())

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.run", [
          "--manifest",
          manifest_path,
          "--output",
          output_path,
          "--run-id",
          "task_manifest-json-run",
          "--generated-at",
          "2026-05-14T00:00:00Z",
          "--format",
          "json"
        ])
      end)

    assert %{
             "manifest" => ^manifest_path,
             "output" => ^output_path,
             "study" => "task_manifest",
             "run_id" => "task_manifest-json-run",
             "generated_at" => "2026-05-14T00:00:00Z",
             "trajectory_count" => 1,
             "event_result_group_count" => 2,
             "access_window_count" => 1,
             "eclipse_interval_count" => 0,
             "error_count" => 0
           } = output |> String.trim() |> :json.decode()

    assert File.exists?(output_path)
  end

  test "resumes from a matching checked result artifact without rewriting output" do
    unique = System.unique_integer([:positive])
    manifest_path = Path.join(System.tmp_dir!(), "orbital_dynamics_resume_#{unique}.json")
    output_path = Path.join(System.tmp_dir!(), "orbital_dynamics_resume_result_#{unique}.json")

    on_exit(fn ->
      File.rm(manifest_path)
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.study.run")
    end)

    File.write!(manifest_path, json_manifest())

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.study.run", [
        "--manifest",
        manifest_path,
        "--output",
        output_path,
        "--run-id",
        "task_manifest-resume-run",
        "--generated-at",
        "2026-05-14T00:00:00Z"
      ])
    end)

    original = output_path |> File.read!() |> :json.decode()
    Mix.Task.reenable("orbital_dynamics.study.run")

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.run", [
          "--manifest",
          manifest_path,
          "--output",
          output_path,
          "--run-id",
          "task_manifest-resume-run",
          "--generated-at",
          "2026-05-15T00:00:00Z",
          "--resume",
          "--format",
          "json"
        ])
      end)

    assert %{
             "study" => "task_manifest",
             "run_id" => "task_manifest-resume-run",
             "generated_at" => "2026-05-14T00:00:00Z",
             "resumed" => true,
             "output_action" => "reused"
           } = output |> String.trim() |> :json.decode()

    assert output_path |> File.read!() |> :json.decode() == original
  end

  test "resume rejects an existing artifact with the wrong requested run id" do
    unique = System.unique_integer([:positive])
    manifest_path = Path.join(System.tmp_dir!(), "orbital_dynamics_resume_reject_#{unique}.json")

    output_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_resume_reject_result_#{unique}.json")

    on_exit(fn ->
      File.rm(manifest_path)
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.study.run")
    end)

    File.write!(manifest_path, json_manifest())

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.study.run", [
        "--manifest",
        manifest_path,
        "--output",
        output_path,
        "--run-id",
        "task_manifest-original-run",
        "--generated-at",
        "2026-05-14T00:00:00Z"
      ])
    end)

    Mix.Task.reenable("orbital_dynamics.study.run")

    assert_raise Mix.Error, ~r/cannot resume from study artifact run/, fn ->
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.run", [
          "--manifest",
          manifest_path,
          "--output",
          output_path,
          "--run-id",
          "task_manifest-different-run",
          "--resume"
        ])
      end)
    end
  end

  test "resumes an interrupted local checkpoint and matches uninterrupted semantic output" do
    unique = System.unique_integer([:positive])
    manifest_path = Path.join(System.tmp_dir!(), "orbital_dynamics_checkpoint_#{unique}.json")
    checkpoint_path = Path.join(System.tmp_dir!(), "orbital_dynamics_checkpoint_#{unique}.state")
    output_path = Path.join(System.tmp_dir!(), "orbital_dynamics_checkpoint_#{unique}.result")

    uninterrupted_path =
      Path.join(System.tmp_dir!(), "orbital_dynamics_checkpoint_#{unique}.uninterrupted")

    on_exit(fn ->
      File.rm(manifest_path)
      File.rm(checkpoint_path)
      File.rm(output_path)
      File.rm(uninterrupted_path)
      Mix.Task.reenable("orbital_dynamics.study.run")
    end)

    File.write!(manifest_path, checkpoint_json_manifest())
    {:ok, manifest} = OrbitalDynamics.Study.Manifest.from_file(manifest_path)
    parent = self()

    interruption =
      Task.async(fn ->
        OrbitalDynamics.StudyRunner.run(
          manifest.study,
          manifest.run_opts ++
            [
              run_id: "task-checkpoint-run",
              checkpoint: %{path: checkpoint_path, mode: :create},
              checkpoint_test_hook: fn event ->
                send(parent, {:checkpoint_chunk_published, event})

                receive do
                  :interrupt_checkpoint -> {:error, :planned_after_first_chunk}
                after
                  5_000 -> {:error, :checkpoint_barrier_timeout}
                end
              end
            ]
        )
      end)

    assert_receive {:checkpoint_chunk_published,
                    %{
                      chunk_number: 1,
                      completed_scenario_indexes: [0, 1],
                      published_completed_scenario_count: 2
                    }},
                   5_000

    send(interruption.pid, :interrupt_checkpoint)

    assert {:error, {:checkpoint_test_interruption, :planned_after_first_chunk}} =
             Task.await(interruption, 5_000)

    partial_checkpoint = checkpoint_path |> File.read!() |> :json.decode()
    assert partial_checkpoint["schema_contract"] == "study_checkpoint.v1"
    assert partial_checkpoint["schema_version"] == 1
    assert partial_checkpoint["completed_scenario_count"] == 2

    assert Enum.map(partial_checkpoint["completed_scenarios"], & &1["scenario_index"]) == [
             0,
             1
           ]

    resume_output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.run", [
          "--manifest",
          manifest_path,
          "--output",
          output_path,
          "--resume-checkpoint",
          checkpoint_path,
          "--run-id",
          "task-checkpoint-run",
          "--generated-at",
          "2026-08-20T12:00:00Z",
          "--format",
          "json"
        ])
      end)

    assert %{
             "checkpoint_execution" => true,
             "checkpoint_path" => ^checkpoint_path,
             "checkpoint_mode" => "resume",
             "checkpoint_reused_scenario_count" => 2,
             "checkpoint_run_scenario_count" => 2,
             "checkpoint_reused_scenario_indexes" => [0, 1],
             "checkpoint_run_scenario_indexes" => [2, 3]
           } = resume_output |> String.trim() |> :json.decode()

    resumed_artifact = output_path |> File.read!() |> :json.decode()
    checkpoint_plan = resumed_artifact["execution_report"]["execution_plan"]["checkpoint"]

    assert checkpoint_plan["reused_scenario_count"] == 2
    assert checkpoint_plan["run_scenario_count"] == 2
    assert checkpoint_plan["ordering"] == "source_manifest_scenario_order"

    assert resumed_artifact["execution_report"]["model_limits"] ==
             OrbitalDynamics.ResultSet.Artifact.checkpoint_execution_report_model_limits()

    assert {:ok, %{"schema_contract" => "result_artifact.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(resumed_artifact,
               contract: "result_artifact.v1"
             )

    Mix.Task.reenable("orbital_dynamics.study.run")

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.study.run", [
        "--manifest",
        manifest_path,
        "--output",
        uninterrupted_path,
        "--run-id",
        "task-uninterrupted-run",
        "--generated-at",
        "2026-08-20T12:00:00Z"
      ])
    end)

    uninterrupted_artifact = uninterrupted_path |> File.read!() |> :json.decode()

    assert semantic_artifact(resumed_artifact) == semantic_artifact(uninterrupted_artifact)

    complete_checkpoint = checkpoint_path |> File.read!() |> :json.decode()
    assert complete_checkpoint["completed_scenario_count"] == 4
    assert complete_checkpoint["write_sequence"] == 2
  end

  test "rejects output and checkpoint path aliases" do
    unique = System.unique_integer([:positive])
    manifest_path = Path.join(System.tmp_dir!(), "orbital_dynamics_alias_#{unique}.json")
    output_path = Path.join(System.tmp_dir!(), "orbital_dynamics_alias_#{unique}.result")
    alias_root = Path.join(System.tmp_dir!(), "orbital_dynamics_alias_root_#{unique}")
    real_parent = Path.join(alias_root, "real")
    symlink_parent = Path.join(alias_root, "linked")

    on_exit(fn ->
      File.rm(manifest_path)
      File.rm(output_path)
      File.rm(symlink_parent)
      File.rmdir(real_parent)
      File.rmdir(alias_root)
      Mix.Task.reenable("orbital_dynamics.study.run")
    end)

    File.write!(manifest_path, checkpoint_json_manifest())
    File.mkdir_p!(real_parent)
    File.ln_s!(real_parent, symlink_parent)

    assert_raise Mix.Error, ~r/checkpoint path must differ from --output/, fn ->
      Mix.Task.run("orbital_dynamics.study.run", [
        "--manifest",
        manifest_path,
        "--output",
        output_path,
        "--checkpoint",
        Path.relative_to_cwd(output_path)
      ])
    end

    Mix.Task.reenable("orbital_dynamics.study.run")

    assert_raise Mix.Error, ~r/checkpoint path must differ from --output/, fn ->
      Mix.Task.run("orbital_dynamics.study.run", [
        "--manifest",
        manifest_path,
        "--output",
        Path.join(real_parent, "result.json"),
        "--checkpoint",
        Path.join(symlink_parent, "result.json")
      ])
    end

    Mix.Task.reenable("orbital_dynamics.study.run")

    assert_raise Mix.Error, ~r/checkpoint path must differ from --output/, fn ->
      Mix.Task.run("orbital_dynamics.study.run", [
        "--manifest",
        manifest_path,
        "--output",
        Path.join(real_parent, "CaseSensitiveResult.json"),
        "--checkpoint",
        Path.join(real_parent, "casesensitiveresult.json")
      ])
    end
  end

  test "retries only failed manifest scenarios into a separate provenance-linked artifact" do
    unique = System.unique_integer([:positive])
    manifest_path = Path.join(System.tmp_dir!(), "orbital_dynamics_retry_#{unique}.json")
    source_path = Path.join(System.tmp_dir!(), "orbital_dynamics_failed_#{unique}.json")
    output_path = Path.join(System.tmp_dir!(), "orbital_dynamics_retried_#{unique}.json")

    on_exit(fn ->
      File.rm(manifest_path)
      File.rm(source_path)
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.study.run")
    end)

    manifest_json = partial_failure_json_manifest()
    File.write!(manifest_path, manifest_json)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.study.run", [
        "--manifest",
        manifest_path,
        "--output",
        source_path,
        "--run-id",
        "task-manifest-source-run",
        "--generated-at",
        "2026-05-14T00:00:00Z"
      ])
    end)

    source_json = File.read!(source_path)
    source_artifact = :json.decode(source_json)

    assert source_artifact["execution_report"]["status"] == "completed_with_errors"

    assert Enum.map(
             source_artifact["execution_report"]["failed_scenarios"],
             & &1["scenario_index"]
           ) == [1, 3]

    Mix.Task.reenable("orbital_dynamics.study.run")

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.run", [
          "--manifest",
          manifest_path,
          "--retry-failed-from",
          source_path,
          "--output",
          output_path,
          "--run-id",
          "task-manifest-retry-run",
          "--generated-at",
          "2026-05-15T00:00:00Z",
          "--format",
          "json"
        ])
      end)

    assert %{
             "study" => "task_retry_manifest",
             "run_id" => "task-manifest-retry-run",
             "retry_failed" => true,
             "retry_source" => ^source_path,
             "retried_scenario_count" => 2,
             "retried_scenario_indexes" => [1, 3],
             "trajectory_count" => 0,
             "error_count" => 2,
             "output_action" => "wrote"
           } = output |> String.trim() |> :json.decode()

    retry_artifact = output_path |> File.read!() |> :json.decode()
    retry = retry_artifact["assumptions"]["retry"]

    assert retry_artifact["run"]["id"] == "task-manifest-retry-run"
    assert retry_artifact["assumptions"]["seed_manifest"] == %{"seed" => 42}
    assert retry["scenario_indexes"] == [1, 3]
    assert retry["scenario_ids"] == ["retry_2", "retry_4"]
    assert retry["ordering"] == "source_manifest_scenario_order"
    assert retry["source_run_id"] == "task-manifest-source-run"
    assert retry["source_artifact"]["path"] == source_path
    assert retry["source_artifact"]["sha256"] == sha256(source_json)

    assert retry_artifact["execution_report"]["scenario_count"] == 2
    assert retry_artifact["execution_report"]["failed_scenario_count"] == 2

    assert retry_artifact["execution_report"]["model_limits"] ==
             OrbitalDynamics.ResultSet.Artifact.retry_execution_report_model_limits()

    assert retry_artifact["execution_report"]["assumptions"]
           |> Map.take([
             "resumability",
             "retry_scope",
             "checkpoint_resume",
             "source_results_merged",
             "persistent_queue",
             "automatic_retry"
           ]) == %{
             "resumability" => "failed_scenario_retry",
             "retry_scope" => "failed_scenarios_only",
             "checkpoint_resume" => false,
             "source_results_merged" => false,
             "persistent_queue" => false,
             "automatic_retry" => false
           }

    assert Enum.map(
             retry_artifact["execution_report"]["failed_scenarios"],
             & &1["scenario_index"]
           ) == [1, 3]

    assert retry_artifact["execution_report"]["execution_plan"]["resumability"] ==
             "failed_scenario_retry"

    assert retry_artifact["execution_report"]["execution_plan"]["retry"][
             "scenario_indexes"
           ] == [1, 3]

    assert {:ok, %{"schema_contract" => "result_artifact.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(retry_artifact,
               contract: "result_artifact.v1"
             )

    assert File.read!(source_path) == source_json
  end

  test "rejects conflicting resume and failed-scenario retry modes" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.study.run") end)

    assert_raise Mix.Error, ~r/--resume and --retry-failed-from cannot be used together/, fn ->
      Mix.Task.run("orbital_dynamics.study.run", [
        "--manifest",
        "unused.json",
        "--resume",
        "--retry-failed-from",
        "failed.json"
      ])
    end
  end

  test "keeps whole-artifact resume, checkpoint resume, and failed retry mutually exclusive" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.study.run") end)

    assert_raise Mix.Error,
                 ~r/--checkpoint and --resume-checkpoint cannot be used together/,
                 fn ->
                   Mix.Task.run("orbital_dynamics.study.run", [
                     "--manifest",
                     "unused.json",
                     "--checkpoint",
                     "fresh.json",
                     "--resume-checkpoint",
                     "prior.json"
                   ])
                 end

    Mix.Task.reenable("orbital_dynamics.study.run")

    assert_raise Mix.Error, ~r/--resume cannot be combined with local checkpoint execution/, fn ->
      Mix.Task.run("orbital_dynamics.study.run", [
        "--manifest",
        "unused.json",
        "--resume",
        "--resume-checkpoint",
        "prior.json"
      ])
    end

    Mix.Task.reenable("orbital_dynamics.study.run")

    assert_raise Mix.Error,
                 ~r/--retry-failed-from cannot be combined with local checkpoint execution/,
                 fn ->
                   Mix.Task.run("orbital_dynamics.study.run", [
                     "--manifest",
                     "unused.json",
                     "--retry-failed-from",
                     "failed.json",
                     "--checkpoint",
                     "fresh.json"
                   ])
                 end
  end

  test "rejects unsupported summary formats" do
    on_exit(fn -> Mix.Task.reenable("orbital_dynamics.study.run") end)

    assert_raise Mix.Error, ~r/--format must be text or json/, fn ->
      Mix.Task.run("orbital_dynamics.study.run", [
        "--manifest",
        "unused.json",
        "--format",
        "yaml"
      ])
    end
  end

  defp json_manifest do
    %{
      "schema_version" => 1,
      "study_id" => "task_manifest",
      "central_body" => "earth",
      "propagator" => "j2",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories", "access_windows", "eclipses"],
      "sun_direction" => [1.0, 0.0, 0.0],
      "scenarios" => [
        %{
          "generator" => "circular_leo",
          "count" => 1,
          "duration_s" => 600.0,
          "output_step_s" => 60.0,
          "id_prefix" => "task_manifest"
        }
      ],
      "ground_stations" => [
        %{
          "id" => "equator_prime",
          "latitude_deg" => 0.0,
          "longitude_deg" => 0.0,
          "minimum_elevation_deg" => 5.0
        }
      ]
    }
    |> :json.encode()
    |> IO.iodata_to_binary()
  end

  defp partial_failure_json_manifest do
    %{
      "schema_version" => 1,
      "study_id" => "task_retry_manifest",
      "central_body" => "earth",
      "propagator" => "two_body",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories"],
      "seed_manifest" => %{"seed" => 42},
      "metadata" => %{"assumption_set" => "retry-task-v1"},
      "scenarios" => [
        explicit_scenario("retry_1", [7000.0, 0.0, 0.0]),
        explicit_scenario("retry_2", [0.0, 0.0, 0.0]),
        explicit_scenario("retry_3", [0.0, 7000.0, 0.0]),
        explicit_scenario("retry_4", [0.0, 0.0, 0.0])
      ]
    }
    |> :json.encode()
    |> IO.iodata_to_binary()
  end

  defp checkpoint_json_manifest do
    %{
      "schema_version" => 1,
      "study_id" => "task_checkpoint_manifest",
      "central_body" => "earth",
      "propagator" => "two_body",
      "propagator_opts" => %{"max_step_s" => 10.0},
      "outputs" => ["trajectories", "eclipses"],
      "sun_direction" => [1.0, 0.0, 0.0],
      "run_options" => %{"max_concurrency" => 2, "task_chunk_size" => 2},
      "scenarios" =>
        for scenario_number <- 1..4 do
          explicit_scenario("checkpoint_#{scenario_number}", [7_000.0, 0.0, 0.0])
        end
    }
    |> :json.encode()
    |> IO.iodata_to_binary()
  end

  defp semantic_artifact(artifact) do
    artifact
    |> Map.take([
      "study_id",
      "trajectories",
      "maneuver_recommendations",
      "access_windows",
      "eclipse_intervals",
      "target_visibility_windows",
      "ground_track_crossings",
      "errors"
    ])
    |> Map.put("assumptions", Map.drop(artifact["assumptions"], ["checkpoint"]))
  end

  defp explicit_scenario(id, position_km) do
    %{
      "id" => id,
      "spacecraft" => %{"id" => "sat_#{id}", "dry_mass_kg" => 250.0},
      "initial_state" => %{
        "position_km" => position_km,
        "velocity_km_s" => [0.0, 7.5, 0.0],
        "epoch" => %{"seconds_since_j2000" => 0.0, "scale" => "tdb"},
        "frame" => "earth_inertial_j2000"
      },
      "duration_s" => 120.0,
      "output_step_s" => 60.0
    }
  end

  defp sha256(content) do
    :crypto.hash(:sha256, content)
    |> Base.encode16(case: :lower)
  end
end
