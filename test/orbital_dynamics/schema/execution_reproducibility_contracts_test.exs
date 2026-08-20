defmodule OrbitalDynamics.Schema.ExecutionReproducibilityContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates standalone execution report contracts" do
    report = %{
      "schema_contract" => "execution_report.v1",
      "study_id" => "large_monte_carlo",
      "run_id" => "large_monte_carlo-1",
      "status" => "completed_with_errors",
      "execution_mode" => "distributed_task_supervisors",
      "scenario_count" => 2000,
      "completed_scenario_count" => 1999,
      "failed_scenario_count" => 1,
      "event_result_count" => 5997,
      "model_limits" => OrbitalDynamics.ResultSet.Artifact.execution_report_model_limits(),
      "backend" => "Elixir.OrbitalDynamics.Propagators.TwoBody",
      "batch_propagation" => false,
      "task_chunk_size" => 50,
      "timeout" => 30_000,
      "effective_task_concurrency" => 16,
      "task_supervisor_node" => "mission_ops@node_a",
      "task_supervisor_nodes" => ["mission_ops@node_a", "mission_ops@node_b"],
      "execution_plan" => %{
        "scenario_count" => 2000,
        "task_batch_count" => 40,
        "requested_task_chunk_size" => 50,
        "effective_task_chunk_size" => 50,
        "chunking_enabled" => true,
        "wave_count" => 2,
        "resumability" => "not_resumable"
      },
      "failed_scenarios" => [
        %{
          "scenario_id" => "trial_1842",
          "stage" => "propagation",
          "error" => ["task_timeout", 30_000]
        }
      ],
      "assumptions" => %{
        "source" => "study_run_metadata",
        "resumability" => "not_resumable"
      }
    }

    assert {:ok, %{"schema_contract" => "execution_report.v1"}} =
             Schema.validate_artifact(report)

    invalid = put_in(report, ["failed_scenarios", Access.at(0), "stage"], 12)

    assert {:error, validation_report} = Schema.validate_artifact(invalid)
    assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.failed_scenarios[0].stage"))

    invalid_limits = Map.put(report, "model_limits", ["artifact_level_execution_summary"])

    assert {:error, limits_report} = Schema.validate_artifact(invalid_limits)
    assert Enum.any?(limits_report["errors"], &(&1["path"] == "$.model_limits"))

    invalid_float_count = Map.put(report, "scenario_count", 2000.0)

    assert {:error, float_count_report} = Schema.validate_artifact(invalid_float_count)
    assert Enum.any?(float_count_report["errors"], &(&1["path"] == "$.scenario_count"))

    invalid_negative_count = Map.put(report, "failed_scenario_count", -1)

    assert {:error, negative_count_report} = Schema.validate_artifact(invalid_negative_count)
    assert Enum.any?(negative_count_report["errors"], &(&1["path"] == "$.failed_scenario_count"))
  end

  test "validates checked-in execution failure-isolation example" do
    report = read_json!("study_results/execution_report_v1.json")

    assert {:ok, %{"schema_contract" => "execution_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "execution_mode" => "distributed_task_supervisors",
             "backend" => "Elixir.OrbitalDynamics.Propagators.TwoBody",
             "batch_propagation" => false,
             "status" => "completed_with_errors",
             "model_limits" => [
               "artifact_level_execution_summary",
               "not_resumable",
               "no_persistent_queue",
               "failed_scenarios_are_reported_not_retried"
             ],
             "scenario_count" => 2000,
             "completed_scenario_count" => 1999,
             "failed_scenario_count" => 1,
             "effective_task_concurrency" => 16,
             "task_chunk_size" => 50,
             "task_supervisor_node" => "mission_ops@node_a",
             "task_supervisor_nodes" => ["mission_ops@node_a", "mission_ops@node_b"],
             "execution_plan" => %{
               "task_batch_count" => 40,
               "wave_count" => 2
             },
             "failed_scenarios" => [
               %{
                 "scenario_id" => "trial_1842",
                 "stage" => "propagation",
                 "error" => ["task_timeout", 30000]
               }
             ]
           } = report
  end

  test "validates explicit failed-scenario retry limits and assumptions" do
    report = %{
      "schema_contract" => "execution_report.v1",
      "study_id" => "retry_study",
      "run_id" => "retry-run",
      "status" => "completed",
      "execution_mode" => "local_tasks",
      "scenario_count" => 2,
      "completed_scenario_count" => 2,
      "failed_scenario_count" => 0,
      "event_result_count" => 0,
      "model_limits" => OrbitalDynamics.ResultSet.Artifact.retry_execution_report_model_limits(),
      "execution_plan" => %{
        "scenario_count" => 2,
        "resumability" => "failed_scenario_retry",
        "retry" => %{
          "mode" => "failed_scenario_retry",
          "scenario_indexes" => [0, 2]
        }
      },
      "failed_scenarios" => [],
      "assumptions" => %{
        "source" => "study_run_metadata",
        "resumability" => "failed_scenario_retry",
        "retry_scope" => "failed_scenarios_only",
        "checkpoint_resume" => false,
        "source_results_merged" => false,
        "persistent_queue" => false,
        "automatic_retry" => false
      }
    }

    assert {:ok, %{"schema_contract" => "execution_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_limits =
      Map.put(
        report,
        "model_limits",
        OrbitalDynamics.ResultSet.Artifact.execution_report_model_limits()
      )

    assert {:error, limits_report} = Schema.validate_artifact(invalid_limits)
    assert Enum.any?(limits_report["errors"], &(&1["path"] == "$.model_limits"))

    invalid_assumptions = put_in(report, ["assumptions", "resumability"], "not_resumable")

    assert {:error, assumptions_report} = Schema.validate_artifact(invalid_assumptions)

    assert Enum.any?(
             assumptions_report["errors"],
             &(&1["path"] == "$.assumptions.resumability")
           )

    invalid_plan = update_in(report, ["execution_plan"], &Map.delete(&1, "retry"))

    assert {:error, plan_report} = Schema.validate_artifact(invalid_plan)
    assert Enum.any?(plan_report["errors"], &(&1["path"] == "$.execution_plan.retry"))
  end

  test "exports nested execution failure row schema" do
    assert {:ok, schema} = Schema.json_schema("execution_report.v1")

    failure_schema = get_in(schema, ["properties", "failed_scenarios", "items"])

    assert failure_schema["required"] == ["scenario_id", "stage", "error"]

    assert get_in(failure_schema, ["properties", "scenario_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(failure_schema, ["properties", "stage", "type"]) == "string"
    assert get_in(schema, ["properties", "backend", "type"]) == "string"
    assert get_in(schema, ["properties", "batch_propagation", "type"]) == "boolean"
    assert get_in(schema, ["properties", "task_chunk_size", "type"]) == "integer"
    assert get_in(schema, ["properties", "effective_task_concurrency", "type"]) == "integer"

    assert get_in(schema, ["properties", "scenario_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "completed_scenario_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "failed_scenario_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "event_result_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "task_supervisor_nodes", "oneOf"]) == [
             %{"type" => "array", "items" => %{"type" => "string"}},
             %{"type" => "null"}
           ]

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.ResultSet.Artifact.execution_report_model_limit_values()

    assert Enum.all?(
             OrbitalDynamics.ResultSet.Artifact.retry_execution_report_model_limits(),
             &(&1 in get_in(schema, ["properties", "model_limits", "items", "enum"]))
           )

    assert get_in(schema, ["properties", "execution_plan", "type"]) == "object"
  end

  test "validates standalone monte carlo reproducibility report contracts" do
    report = %{
      "schema_contract" => "monte_carlo_reproducibility_report.v1",
      "model" => "seeded_independent_normal_cartesian_dispersion",
      "source" => "study_metadata.monte_carlo",
      "generator" => "state_vector_dispersion",
      "rng" => "rand_exsss",
      "sampling_method" => "box_muller_transform",
      "deterministic_seed" => true,
      "seed" => 12_345,
      "requested_count" => 3,
      "generated_scenario_count" => 3,
      "id_prefix" => "dispersion",
      "generated_scenario_ids" => ["dispersion_1", "dispersion_2", "dispersion_3"],
      "position_sigma_km" => [0.1, 0.1, 0.05],
      "velocity_sigma_km_s" => [0.0001, 0.0001, 0.00005],
      "seed_manifest" => %{"monte_carlo_seed" => 12_345},
      "assumptions" => %{
        "scenario_id_order" => "artifact.trajectories order",
        "distribution" => "independent normal per Cartesian component",
        "covariance_model" => "none"
      },
      "known_limits" =>
        OrbitalDynamics.Search.MonteCarlo.capabilities()
        |> Map.fetch!(:known_limits)
        |> Enum.map(&Atom.to_string/1),
      "model_limits" =>
        OrbitalDynamics.Search.MonteCarlo.capabilities()
        |> Map.fetch!(:known_limits)
        |> Enum.map(&Atom.to_string/1)
    }

    assert {:ok, %{"schema_contract" => "monte_carlo_reproducibility_report.v1"}} =
             Schema.validate_artifact(report)

    stale_model = Map.put(report, "model", "stale_monte_carlo_dispersion_model")

    assert {:error, stale_model_report} = Schema.validate_artifact(stale_model)

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"seeded_independent_normal_cartesian_dispersion\"")
           )

    invalid = put_in(report, ["generated_scenario_ids"], ["bad id"])

    assert {:error, validation_report} = Schema.validate_artifact(invalid)
    assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.generated_scenario_ids[0]"))

    stale_limits = Map.put(report, "model_limits", ["no_covariance_matrix"])

    assert {:error, limits_report} = Schema.validate_artifact(stale_limits)
    assert Enum.any?(limits_report["errors"], &(&1["path"] == "$.model_limits"))

    stale_known_limits = Map.put(report, "known_limits", ["no_covariance_matrix"])

    assert {:error, known_limits_report} = Schema.validate_artifact(stale_known_limits)
    assert Enum.any?(known_limits_report["errors"], &(&1["path"] == "$.known_limits"))

    invalid_float_count = Map.put(report, "requested_count", 3.0)

    assert {:error, float_count_report} = Schema.validate_artifact(invalid_float_count)
    assert Enum.any?(float_count_report["errors"], &(&1["path"] == "$.requested_count"))

    invalid_negative_count = Map.put(report, "generated_scenario_count", -1)

    assert {:error, negative_count_report} = Schema.validate_artifact(invalid_negative_count)

    assert Enum.any?(
             negative_count_report["errors"],
             &(&1["path"] == "$.generated_scenario_count")
           )
  end

  test "exports nested monte carlo reproducibility array schemas" do
    assert {:ok, schema} = Schema.json_schema("monte_carlo_reproducibility_report.v1")

    assert get_in(schema, ["properties", "generated_scenario_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    expected_limits =
      OrbitalDynamics.Search.MonteCarlo.capabilities()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&Atom.to_string/1)

    assert get_in(schema, ["properties", "source", "type"]) == "string"

    assert get_in(schema, ["properties", "model", "const"]) ==
             "seeded_independent_normal_cartesian_dispersion"

    assert get_in(schema, ["properties", "known_limits", "items", "enum"]) == expected_limits
    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) == expected_limits

    assert get_in(schema, ["properties", "requested_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "generated_scenario_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "position_sigma_km", "items", "type"]) == "number"
    assert get_in(schema, ["properties", "position_sigma_km", "minItems"]) == 3
    assert get_in(schema, ["properties", "position_sigma_km", "maxItems"]) == 3

    assert get_in(schema, ["properties", "velocity_sigma_km_s", "items", "type"]) == "number"
    assert get_in(schema, ["properties", "velocity_sigma_km_s", "minItems"]) == 3
    assert get_in(schema, ["properties", "velocity_sigma_km_s", "maxItems"]) == 3
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
