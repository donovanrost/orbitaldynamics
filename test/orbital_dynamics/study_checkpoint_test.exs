defmodule OrbitalDynamics.StudyCheckpointTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CentralBody, Epoch, Frame, Scenario, Spacecraft, StateVector, Study}
  alias OrbitalDynamics.Propagators.TwoBodyNxCompiled

  test "rejects checkpoint corruption and duplicate, missing, or mismatched rows" do
    unique = System.unique_integer([:positive])
    source_path = checkpoint_path(unique, "source")

    variant_names = [
      "content",
      "null",
      "payload",
      "invalid_term",
      "entry_hash",
      "duplicate",
      "missing",
      "mismatched",
      "manifest"
    ]

    variant_paths = Map.new(variant_names, &{&1, checkpoint_path(unique, &1)})

    on_exit(fn ->
      File.rm(source_path)
      Enum.each(variant_paths, fn {_name, path} -> File.rm(path) end)
    end)

    study = checkpoint_study()
    opts = run_opts(unique)

    assert {:ok, _result_set} =
             OrbitalDynamics.StudyRunner.run(
               study,
               Keyword.put(opts, :checkpoint, %{path: source_path, mode: :create})
             )

    checkpoint = source_path |> File.read!() |> :json.decode()
    assert checkpoint["completed_scenario_count"] == 3
    assert checkpoint["write_sequence"] == 2

    content_corruption = Map.put(checkpoint, "content_sha256", String.duplicate("0", 64))
    write_checkpoint!(variant_paths["content"], content_corruption)

    assert {:error, {:checkpoint_content_hash_mismatch, _expected, _actual}} =
             resume(study, opts, variant_paths["content"])

    null_entry =
      checkpoint
      |> put_in(["completed_scenarios", Access.at(0)], :null)
      |> seal_checkpoint()

    write_checkpoint!(variant_paths["null"], null_entry)

    assert {:error, {:invalid_checkpoint_entry, 0}} =
             resume(study, opts, variant_paths["null"])

    payload_corruption =
      checkpoint
      |> update_in(["completed_scenarios", Access.at(0), "payload"], fn payload ->
        {:ok, decoded} = Base.decode64(payload)
        <<first, rest::binary>> = decoded
        Base.encode64(<<Bitwise.bxor(first, 1), rest::binary>>)
      end)
      |> seal_checkpoint()

    write_checkpoint!(variant_paths["payload"], payload_corruption)

    assert {:error, {:checkpoint_entry_hash_mismatch, 0, _expected, _actual}} =
             resume(study, opts, variant_paths["payload"])

    invalid_term_payload = "corrupt external term payload"

    invalid_term =
      checkpoint
      |> update_in(["completed_scenarios", Access.at(0)], fn entry ->
        entry
        |> Map.put("payload", Base.encode64(invalid_term_payload))
        |> Map.put("payload_sha256", sha256(invalid_term_payload))
      end)
      |> seal_checkpoint()

    write_checkpoint!(variant_paths["invalid_term"], invalid_term)

    assert {:error, {:checkpoint_entry_invalid_term, 0, _message}} =
             resume(study, opts, variant_paths["invalid_term"])

    entry_hash_corruption =
      checkpoint
      |> update_in(["completed_scenarios", Access.at(0), "payload_sha256"], fn _hash ->
        String.duplicate("0", 64)
      end)
      |> seal_checkpoint()

    write_checkpoint!(variant_paths["entry_hash"], entry_hash_corruption)

    assert {:error, {:checkpoint_entry_hash_mismatch, 0, _expected, _actual}} =
             resume(study, opts, variant_paths["entry_hash"])

    [first | rest] = checkpoint["completed_scenarios"]

    duplicate =
      checkpoint
      |> Map.put("completed_scenarios", [first, first | rest])
      |> Map.put("completed_scenario_count", 4)
      |> seal_checkpoint()

    write_checkpoint!(variant_paths["duplicate"], duplicate)

    assert {:error, {:duplicate_checkpoint_scenario_index, 0}} =
             resume(study, opts, variant_paths["duplicate"])

    missing =
      checkpoint
      |> update_in(["completed_scenarios", Access.at(0)], &Map.delete(&1, "payload"))
      |> seal_checkpoint()

    write_checkpoint!(variant_paths["missing"], missing)

    assert {:error, {:checkpoint_entry_missing_fields, 0, ["payload"]}} =
             resume(study, opts, variant_paths["missing"])

    mismatched =
      checkpoint
      |> put_in(["completed_scenarios", Access.at(0), "scenario_id"], "wrong-scenario")
      |> seal_checkpoint()

    write_checkpoint!(variant_paths["mismatched"], mismatched)

    assert {:error, {:checkpoint_entry_scenario_id_mismatch, 0, "checkpoint_1", "wrong-scenario"}} =
             resume(study, opts, variant_paths["mismatched"])

    missing_manifest_row =
      checkpoint
      |> update_in(["identity", "scenario_manifest"], &Enum.drop(&1, -1))
      |> seal_checkpoint()

    write_checkpoint!(variant_paths["manifest"], missing_manifest_row)

    assert {:error, {:checkpoint_identity_mismatch, "scenario_manifest", _expected, _actual}} =
             resume(study, opts, variant_paths["manifest"])
  end

  test "concurrent checkpoint creators publish once without replacing the winner" do
    unique = System.unique_integer([:positive])
    checkpoint_path = checkpoint_path(unique, "concurrent_create")

    on_exit(fn ->
      File.rm(checkpoint_path)

      checkpoint_path
      |> Path.dirname()
      |> Path.join(Path.basename(checkpoint_path) <> ".tmp-*")
      |> Path.wildcard()
      |> Enum.each(&File.rm/1)
    end)

    parent = self()
    study = checkpoint_study()
    base_opts = run_opts(unique)

    start_creator = fn label, run_id ->
      Task.async(fn ->
        OrbitalDynamics.StudyRunner.run(
          study,
          base_opts
          |> Keyword.put(:run_id, run_id)
          |> Keyword.put(:checkpoint, %{path: checkpoint_path, mode: :create})
          |> Keyword.put(:checkpoint_initial_publish_test_hook, fn event ->
            send(parent, {:initial_checkpoint_ready, label, self(), event})

            receive do
              {:publish_initial_checkpoint, ^label} -> :ok
            after
              5_000 -> {:error, :initial_publish_barrier_timeout}
            end
          end)
        )
      end)
    end

    winner = start_creator.(:winner, "checkpoint-winner-#{unique}")
    loser = start_creator.(:loser, "checkpoint-loser-#{unique}")

    assert_receive {:initial_checkpoint_ready, :winner, winner_pid,
                    %{publication_mode: :create, temporary_file_synced: true}},
                   5_000

    assert_receive {:initial_checkpoint_ready, :loser, loser_pid,
                    %{publication_mode: :create, temporary_file_synced: true}},
                   5_000

    send(winner_pid, {:publish_initial_checkpoint, :winner})
    assert {:ok, _result_set} = Task.await(winner, 5_000)
    winner_checkpoint = File.read!(checkpoint_path)

    send(loser_pid, {:publish_initial_checkpoint, :loser})

    assert {:error, {:checkpoint_already_exists, ^checkpoint_path}} =
             Task.await(loser, 5_000)

    assert File.read!(checkpoint_path) == winner_checkpoint

    assert {:ok, _result_set} =
             resume(
               study,
               Keyword.put(base_opts, :run_id, "checkpoint-winner-#{unique}"),
               checkpoint_path
             )

    assert {:error, {:checkpoint_identity_mismatch, "run_options", _expected, _actual}} =
             resume(
               study,
               Keyword.put(base_opts, :run_id, "checkpoint-loser-#{unique}"),
               checkpoint_path
             )

    assert Path.wildcard(checkpoint_path <> ".tmp-*") == []
  end

  test "rejects stale manifest, model, and run-option identities before reuse" do
    unique = System.unique_integer([:positive])
    checkpoint_path = checkpoint_path(unique, "identity")
    on_exit(fn -> File.rm(checkpoint_path) end)

    study = checkpoint_study()
    opts = run_opts(unique)

    assert {:ok, created_result_set} =
             OrbitalDynamics.StudyRunner.run(
               study,
               Keyword.put(opts, :checkpoint, %{path: checkpoint_path, mode: :create})
             )

    created_artifact = OrbitalDynamics.ResultSet.Artifact.build(created_result_set)
    assert created_artifact.execution_report.assumptions.checkpoint_resume == false
    assert created_artifact.execution_report.assumptions.checkpoint_results_reused == false

    assert {:ok, resumed_result_set} = resume(study, opts, checkpoint_path)
    resumed_artifact = OrbitalDynamics.ResultSet.Artifact.build(resumed_result_set)
    checkpoint_plan = resumed_artifact.execution_report.execution_plan["checkpoint"]

    assert checkpoint_plan["reused_scenario_count"] == 3
    assert checkpoint_plan["run_scenario_count"] == 0
    assert resumed_artifact.execution_report.assumptions.checkpoint_resume == true
    assert resumed_artifact.execution_report.assumptions.checkpoint_results_reused == true

    assert {:ok, %{"schema_contract" => "result_artifact.v1"}} =
             resumed_artifact
             |> :json.encode()
             |> IO.iodata_to_binary()
             |> :json.decode()
             |> OrbitalDynamics.Schema.validate_artifact(contract: "result_artifact.v1")

    stale_manifest_opts =
      Keyword.put(opts, :manifest, %{
        path: opts[:manifest][:path],
        sha256: sha256("stale-manifest")
      })

    assert {:error, {:checkpoint_identity_mismatch, "manifest", _expected, _actual}} =
             resume(study, stale_manifest_opts, checkpoint_path)

    stale_model = %{study | propagator_opts: [max_step_s: 5.0]}

    assert {:error, {:checkpoint_identity_mismatch, "model", _expected, _actual}} =
             resume(stale_model, opts, checkpoint_path)

    stale_options = Keyword.put(opts, :max_concurrency, 1)

    assert {:error, {:checkpoint_identity_mismatch, "run_options", _expected, _actual}} =
             resume(study, stale_options, checkpoint_path)

    assert {:error, {:checkpoint_already_exists, ^checkpoint_path}} =
             OrbitalDynamics.StudyRunner.run(
               study,
               Keyword.put(opts, :checkpoint, %{path: checkpoint_path, mode: :create})
             )
  end

  test "rejects distributed, batch, retry, and identity-free checkpoint modes" do
    unique = System.unique_integer([:positive])
    checkpoint_path = checkpoint_path(unique, "unsupported")
    on_exit(fn -> File.rm(checkpoint_path) end)

    study = checkpoint_study()
    opts = run_opts(unique)
    checkpoint = %{path: checkpoint_path, mode: :create}

    assert {:error, {:unsupported_checkpoint_mode, :task_supervisors}} =
             OrbitalDynamics.StudyRunner.run(
               study,
               opts ++
                 [
                   checkpoint: checkpoint,
                   task_supervisors: [OrbitalDynamics.ScenarioSupervisor]
                 ]
             )

    assert {:error, {:unsupported_checkpoint_mode, :distributed_task_supervisor}} =
             OrbitalDynamics.StudyRunner.run(
               study,
               opts ++
                 [
                   checkpoint: checkpoint,
                   task_supervisor: {OrbitalDynamics.ScenarioSupervisor, node()}
                 ]
             )

    batch_study = %{
      study
      | propagator: TwoBodyNxCompiled,
        propagator_opts: [max_step_s: 10.0]
    }

    assert {:error, {:unsupported_checkpoint_mode, :batch_propagation}} =
             OrbitalDynamics.StudyRunner.run(
               batch_study,
               Keyword.put(opts, :checkpoint, checkpoint)
             )

    assert {:error, {:unsupported_checkpoint_mode, :failed_scenario_retry}} =
             OrbitalDynamics.StudyRunner.run(
               study,
               opts ++ [checkpoint: checkpoint, scenario_indexes: [0, 1, 2]]
             )

    assert {:error, {:checkpoint_identity_required, :manifest}} =
             OrbitalDynamics.StudyRunner.run(study, checkpoint: checkpoint)
  end

  defp resume(study, opts, path) do
    OrbitalDynamics.StudyRunner.run(
      study,
      Keyword.put(opts, :checkpoint, %{path: path, mode: :resume})
    )
  end

  defp run_opts(unique) do
    [
      manifest: %{
        path: Path.join(System.tmp_dir!(), "checkpoint_manifest_#{unique}.json"),
        sha256: sha256("manifest-#{unique}")
      },
      central_body: CentralBody.earth(),
      max_concurrency: 2,
      task_chunk_size: 2,
      run_id: "checkpoint-run-#{unique}"
    ]
  end

  defp checkpoint_study do
    earth = CentralBody.earth()

    scenarios =
      for scenario_number <- 1..3 do
        scenario_id = "checkpoint_#{scenario_number}"

        Scenario.new!(
          scenario_id,
          Spacecraft.new!("sat_checkpoint_#{scenario_number}", 250.0),
          state(earth),
          duration_s: 120.0,
          output_step_s: 60.0,
          central_body: earth
        )
      end

    Study.new!(:checkpoint_contract, scenarios,
      outputs: [:trajectories],
      propagator_opts: [max_step_s: 10.0]
    )
  end

  defp state(earth) do
    StateVector.new!(
      {7_000.0, 0.0, 0.0},
      {0.0, :math.sqrt(earth.mu_km3_s2 / 7_000.0), 0.0},
      Epoch.new!(0.0, :tdb),
      Frame.earth_inertial_j2000()
    )
  end

  defp checkpoint_path(unique, name),
    do: Path.join(System.tmp_dir!(), "orbital_dynamics_checkpoint_#{unique}_#{name}.json")

  defp write_checkpoint!(path, checkpoint) do
    json = checkpoint |> :json.encode() |> IO.iodata_to_binary()
    File.write!(path, json <> "\n")
  end

  defp seal_checkpoint(checkpoint) do
    body = Map.delete(checkpoint, "content_sha256")
    Map.put(body, "content_sha256", term_sha256(body))
  end

  defp term_sha256(term) do
    term
    |> :erlang.term_to_binary([:deterministic])
    |> sha256()
  end

  defp sha256(content) do
    :crypto.hash(:sha256, content)
    |> Base.encode16(case: :lower)
  end
end
