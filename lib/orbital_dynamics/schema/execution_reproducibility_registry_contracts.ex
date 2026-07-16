defmodule OrbitalDynamics.Schema.ExecutionReproducibilityRegistryContracts do
  @moduledoc false

  def contracts do
    %{
      "execution_report.v1" => %{
        "schema_contract" => "execution_report.v1",
        "artifact_family" => "execution_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "study_id",
          "status",
          "execution_mode",
          "scenario_count",
          "completed_scenario_count",
          "failed_scenario_count",
          "event_result_count",
          "failed_scenarios",
          "assumptions"
        ],
        "optional_fields" => [
          "run_id",
          "backend",
          "node",
          "model_limits",
          "batch_propagation",
          "task_chunk_size",
          "timeout",
          "effective_task_concurrency",
          "task_supervisor_node",
          "task_supervisor_nodes",
          "execution_plan",
          "phase_timings_ms",
          "node_distribution"
        ],
        "nested_contracts" => []
      },
      "monte_carlo_reproducibility_report.v1" => %{
        "schema_contract" => "monte_carlo_reproducibility_report.v1",
        "artifact_family" => "monte_carlo_reproducibility_report",
        "schema_version" => 1,
        "required_fields" => [
          "schema_contract",
          "model",
          "source",
          "generator",
          "rng",
          "sampling_method",
          "deterministic_seed",
          "seed",
          "requested_count",
          "generated_scenario_count",
          "generated_scenario_ids",
          "position_sigma_km",
          "velocity_sigma_km_s",
          "seed_manifest",
          "assumptions",
          "known_limits"
        ],
        "optional_fields" => ["id_prefix", "model_limits"],
        "nested_contracts" => []
      }
    }
  end
end
