defmodule OrbitalDynamics.Study.Benchmark.ReportTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Study.Benchmark.Report

  import OrbitalDynamics.Validation.BenchmarkFixtures,
    only: [nx_study_benchmark_fixture: 0]

  test "declares study benchmark report capabilities" do
    assert %{
             report: :study_benchmark_summary,
             validation_level: :artifact_contract,
             public_facades: [:study_benchmark_summary],
             grouping: grouping,
             statistics: statistics,
             known_limits: known_limits
           } = Report.capabilities()

    assert :mode in grouping
    assert :max_concurrency in grouping
    assert :median_duration_ms in statistics
    assert :node_balance_ratio in statistics
    assert :speedup_vs_local in statistics
    assert :median_artifact_body_bytes in statistics
    assert :median_artifact_size_mb in statistics
    assert :median_artifact_bytes_per_scenario in statistics
    assert :median_task_batch_count in statistics
    assert :median_wave_count in statistics
    assert :backend_acceptance_status in statistics
    assert :trend_delta_percent in statistics
    assert :distributed_counts_depend_on_reported_node_telemetry in known_limits
    assert :backend_acceptance_uses_declared_policy in known_limits
    assert :trend_uses_artifact_generated_at_order in known_limits
    assert Report.model_limits() == Enum.map(known_limits, &Atom.to_string/1)
  end

  test "public facade interprets checked-in accelerator comparison evidence" do
    summary = OrbitalDynamics.study_benchmark_summary(nx_study_benchmark_fixture())

    assert summary.manifest["path"] == "studies/leo_dispersion_monte_carlo.json"

    assert summary.benchmark_options["propagators"] == [
             "two_body",
             "two_body_nx_compiled",
             "two_body_exla_cpu"
           ]

    assert length(summary.groups) == 6
    assert Enum.all?(summary.groups, &(&1.output_matches_baseline == true))

    assert %{
             backend_acceptance: %{
               tier: "reference_default",
               status: "accepted_reference_default",
               speedup_claim: "not_required_for_reference_default"
             }
           } = benchmark_group(summary, "two_body", 2_000)

    assert %{
             speedup_vs_local: speedup,
             backend_acceptance: %{
               tier: "experimental_accelerator",
               status: "accepted_accelerator_speedup_evidence",
               reference_match: true,
               benchmark_artifact_present: true,
               speedup_claim: "supported_for_this_benchmark_group",
               policy_contract: "backend_acceptance_policy.v1"
             }
           } = benchmark_group(summary, "two_body_exla_cpu", 2_000)

    assert speedup > 1.0

    assert %{
             backend_acceptance: %{
               tier: "experimental_accelerator",
               status: "correctness_only_no_speedup_claim",
               reference_match: true,
               speedup_claim: "not_supported_by_this_benchmark_group"
             }
           } = benchmark_group(summary, "two_body_nx_compiled", 2_000)
  end

  test "summarizes study benchmark medians by mode and monte carlo count" do
    summary = Report.summarize(artifact())

    assert summary.manifest["path"] == "studies/leo_dispersion_monte_carlo.json"
    assert summary.model_limits == Report.model_limits()
    assert summary.benchmark_options["monte_carlo_counts"] == [20]

    assert [
             %{
               mode: "distributed",
               propagator: "two_body",
               monte_carlo_count: 20,
               task_chunk_size: 100,
               max_concurrency: 8,
               effective_task_concurrency: 16,
               repetitions: 2,
               scenario_count: 20.0,
               median_duration_ms: 8.0,
               median_propagation_ms: 6.0,
               median_event_detection_ms: 1.0,
               median_artifact_build_ms: 2.0,
               median_overhead_ms: 1.0,
               median_overhead_percent: 12.5,
               median_artifact_body_bytes: 10_000.0,
               median_artifact_size_mb: 0.01,
               median_artifact_bytes_per_scenario: 500.0,
               median_scenarios_per_second: 2_500.0,
               median_task_batch_count: 2.0,
               median_wave_count: 1.0,
               execution_plan: %{
                 "batches_per_wave" => 16,
                 "effective_task_chunk_size" => 100,
                 "supervisor_count" => 2,
                 "task_batch_count" => 2,
                 "wave_count" => 1
               },
               speedup_vs_local: 2.0,
               backend_acceptance: %{
                 implementation: "OrbitalDynamics.Propagators.TwoBody",
                 tier: "reference_default",
                 status: "accepted_reference_default",
                 reference_match: true,
                 benchmark_artifact_present: true,
                 policy_contract: "backend_acceptance_policy.v1"
               },
               output_matches_baseline: true,
               node_count: 2,
               node_balance_ratio: 1.0,
               per_node_trajectory_counts: %{
                 "nonode@nohost" => 20,
                 "worker@127.0.0.1" => 20
               }
             },
             %{
               mode: "local",
               propagator: "two_body",
               monte_carlo_count: 20,
               task_chunk_size: 100,
               max_concurrency: 8,
               effective_task_concurrency: 8,
               median_duration_ms: 16.0,
               median_propagation_ms: 12.0,
               median_event_detection_ms: 2.0,
               median_artifact_build_ms: 3.0,
               median_overhead_ms: 2.0,
               median_overhead_percent: 12.5,
               median_artifact_body_bytes: 20_000.0,
               median_artifact_size_mb: 0.02,
               median_artifact_bytes_per_scenario: 1_000.0,
               median_scenarios_per_second: 1_250.0,
               median_task_batch_count: 1.0,
               median_wave_count: 1.0,
               execution_plan: %{
                 "batches_per_wave" => 8,
                 "effective_task_chunk_size" => 1,
                 "supervisor_count" => 0,
                 "task_batch_count" => 1,
                 "wave_count" => 1
               },
               speedup_vs_local: 1.0,
               backend_acceptance: %{
                 implementation: "OrbitalDynamics.Propagators.TwoBody",
                 tier: "reference_default",
                 status: "accepted_reference_default",
                 reference_match: true,
                 benchmark_artifact_present: true,
                 policy_contract: "backend_acceptance_policy.v1"
               },
               node_count: 1,
               node_balance_ratio: nil
             }
           ] = summary.groups
  end

  defp benchmark_group(summary, propagator, monte_carlo_count) do
    Enum.find(summary.groups, fn group ->
      group.propagator == propagator and group.monte_carlo_count == monte_carlo_count
    end)
  end

  test "attaches backend acceptance evidence for accelerator benchmark groups" do
    artifact =
      artifact()
      |> put_in(
        ["results"],
        rows("local", [15.0, 17.0], [1_300.0, 1_200.0], %{"nonode@nohost" => 20}) ++
          rows(
            "local",
            [9.0, 11.0],
            [2_300.0, 2_100.0],
            %{"nonode@nohost" => 20},
            "two_body_nx_compiled"
          )
      )

    assert %{
             propagator: "two_body_nx_compiled",
             speedup_vs_local: 1.6,
             backend_acceptance: %{
               implementation: "OrbitalDynamics.Propagators.TwoBodyNxCompiled",
               tier: "experimental_accelerator",
               status: "accepted_accelerator_speedup_evidence",
               reference_match: true,
               benchmark_artifact_present: true,
               requires_benchmark_artifact: true,
               speedup_claim: "supported_for_this_benchmark_group",
               policy_contract: "backend_acceptance_policy.v1"
             }
           } =
             Enum.find(
               Report.summarize(artifact).groups,
               &(&1.propagator == "two_body_nx_compiled")
             )
  end

  test "does not allow accelerator speedup claims when baseline outputs diverge" do
    artifact =
      artifact()
      |> put_in(
        ["results"],
        rows("local", [15.0, 17.0], [1_300.0, 1_200.0], %{"nonode@nohost" => 20}) ++
          (rows(
             "local",
             [9.0, 11.0],
             [2_300.0, 2_100.0],
             %{"nonode@nohost" => 20},
             "two_body_nx_compiled"
           )
           |> Enum.map(&Map.put(&1, "matches_baseline", false)))
      )

    assert %{
             backend_acceptance: %{
               status: "requires_reference_match",
               reference_match: false,
               speedup_claim: "not_claimed_reference_mismatch"
             }
           } =
             Enum.find(
               Report.summarize(artifact).groups,
               &(&1.propagator == "two_body_nx_compiled")
             )
  end

  test "reports distributed node balance from aggregated trajectory counts" do
    artifact =
      artifact()
      |> put_in(["results"], [
        row("distributed", 8.0, 2_500.0, %{
          "coordinator@127.0.0.1" => 15,
          "worker@127.0.0.1" => 5
        })
      ])

    assert [
             %{
               mode: "distributed",
               node_count: 2,
               node_balance_ratio: balance_ratio,
               per_node_trajectory_counts: %{
                 "coordinator@127.0.0.1" => 15,
                 "worker@127.0.0.1" => 5
               }
             }
           ] = Report.summarize(artifact).groups

    assert_in_delta balance_ratio, 1 / 3, 1.0e-12
  end

  test "can attach operational scale comparisons without treating distributed runtime as local" do
    summary = Report.summarize(artifact(), scale_target: "v1_campaign")

    assert summary.operational_scale_target == "v1_campaign"

    assert %{
             operational_scale_comparison: %{
               "status" => "within_target",
               "rows" => local_rows,
               "distribution_guidance" => %{"status" => "local_concurrency_target"}
             }
           } = Enum.find(summary.groups, &(&1.mode == "local"))

    assert %{"metric" => "local_runtime_s", "observed" => 0.016} =
             Enum.find(local_rows, &(&1["metric"] == "local_runtime_s"))

    assert %{
             operational_scale_comparison: %{
               "rows" => distributed_rows,
               "distribution_guidance" => %{"status" => "local_concurrency_target"}
             }
           } = Enum.find(summary.groups, &(&1.mode == "distributed"))

    refute Enum.any?(distributed_rows, &(&1["metric"] == "local_runtime_s"))
  end

  test "reads artifact JSON from disk" do
    path = Path.join(System.tmp_dir!(), "orbital_dynamics_study_benchmark_report_test.json")
    on_exit(fn -> File.rm(path) end)

    File.write!(path, :json.encode(artifact()))

    assert %{"schema_version" => 1} = Report.read_artifact!(path)
  end

  test "summarizes benchmark trends across generated artifacts" do
    first =
      artifact()
      |> Map.put("generated_at", "2026-05-14T00:00:00Z")

    latest =
      artifact()
      |> Map.put("generated_at", "2026-05-21T00:00:00Z")
      |> put_in(
        ["results"],
        rows("local", [10.0, 12.0], [1_800.0, 1_700.0], %{"nonode@nohost" => 20}) ++
          rows("distributed", [10.0, 12.0], [1_900.0, 1_800.0], %{
            "nonode@nohost" => 12,
            "worker@127.0.0.1" => 8
          })
      )

    assert %{
             artifact_count: 2,
             model_limits: model_limits,
             operational_scale_target: "v1_campaign",
             operational_scale_trend_comparison: %{
               "schema_contract" => "operational_scale_trend_comparison.v1",
               "status" => "trend_regressed",
               "group_count" => 2
             },
             groups: groups
           } = Report.trend_summary([first, latest], scale_target: "v1_campaign")

    assert Report.model_limits() == model_limits

    assert %{
             mode: "local",
             sample_count: 2,
             first_generated_at: "2026-05-14T00:00:00Z",
             latest_generated_at: "2026-05-21T00:00:00Z",
             first_median_duration_ms: 16.0,
             latest_median_duration_ms: 11.0,
             duration_delta_ms: -5.0,
             trend_status: "improved",
             latest_backend_acceptance_status: "accepted_reference_default",
             latest_operational_scale_status: "within_target",
             points: [first_point, latest_point]
           } = Enum.find(groups, &(&1.mode == "local"))

    assert_in_delta latest_point.median_duration_ms, 11.0, 1.0e-12
    assert first_point.generated_at == "2026-05-14T00:00:00Z"

    assert %{
             mode: "distributed",
             first_median_duration_ms: 8.0,
             latest_median_duration_ms: 11.0,
             trend_status: "regressed"
           } = Enum.find(groups, &(&1.mode == "distributed"))
  end

  defp artifact do
    %{
      "schema_version" => 1,
      "generated_at" => "2026-05-14T00:00:00Z",
      "manifest" => %{"path" => "studies/leo_dispersion_monte_carlo.json"},
      "benchmark_options" => %{
        "modes" => ["local", "distributed"],
        "propagators" => ["two_body"],
        "repetitions" => 2,
        "monte_carlo_counts" => [20],
        "task_chunk_sizes" => [100],
        "max_concurrencies" => [8],
        "task_supervisor_node" => "worker@127.0.0.1"
      },
      "results" =>
        rows("local", [15.0, 17.0], [1_300.0, 1_200.0], %{"nonode@nohost" => 20}) ++
          rows("distributed", [7.0, 9.0], [2_600.0, 2_400.0], %{
            "nonode@nohost" => 10,
            "worker@127.0.0.1" => 10
          })
    }
  end

  defp rows(
         mode,
         duration_ms_values,
         scenarios_per_second_values,
         per_node_counts,
         propagator \\ "two_body"
       ) do
    effective_task_concurrency = if mode == "local", do: 8, else: 16
    supervisor_count = if mode == "local", do: 0, else: 2
    task_batch_count = if mode == "local", do: 1, else: 2
    batches_per_wave = if mode == "local", do: 8, else: 16

    execution_plan = %{
      "batches_per_wave" => batches_per_wave,
      "effective_task_chunk_size" => if(mode == "local", do: 1, else: 100),
      "supervisor_count" => supervisor_count,
      "task_batch_count" => task_batch_count,
      "wave_count" => 1
    }

    duration_ms_values
    |> Enum.zip(scenarios_per_second_values)
    |> Enum.with_index(1)
    |> Enum.map(fn {{duration_ms, scenarios_per_second}, repetition} ->
      %{
        "id" => "leo_#{mode}_20_r#{repetition}",
        "mode" => mode,
        "propagator" => propagator,
        "monte_carlo_count" => 20,
        "task_chunk_size" => 100,
        "max_concurrency" => 8,
        "effective_task_concurrency" => effective_task_concurrency,
        "effective_task_chunk_size" => execution_plan["effective_task_chunk_size"],
        "task_batch_count" => task_batch_count,
        "batches_per_wave" => batches_per_wave,
        "wave_count" => 1,
        "supervisor_count" => supervisor_count,
        "execution_plan" => execution_plan,
        "repetition" => repetition,
        "repetitions" => 2,
        "duration_ms" => duration_ms,
        "propagation_ms" => if(mode == "local", do: 12.0, else: 6.0),
        "event_detection_ms" => if(mode == "local", do: 2.0, else: 1.0),
        "artifact_build_ms" => if(mode == "local", do: 3.0, else: 2.0),
        "overhead_ms" => if(mode == "local", do: 2.0, else: 1.0),
        "overhead_percent" => 12.5,
        "artifact_body_bytes" => if(mode == "local", do: 20_000, else: 10_000),
        "artifact_size_mb" => if(mode == "local", do: 0.02, else: 0.01),
        "artifact_bytes_per_scenario" => if(mode == "local", do: 1_000.0, else: 500.0),
        "payload_top_level_key_count" => 18,
        "scenario_count" => 20,
        "trajectory_count" => 20,
        "failure_count" => 0,
        "scenarios_per_second" => scenarios_per_second,
        "per_node_trajectory_counts" => per_node_counts,
        "matches_baseline" => true
      }
    end)
  end

  defp row(mode, duration_ms, scenarios_per_second, per_node_counts) do
    rows(mode, [duration_ms], [scenarios_per_second], per_node_counts)
    |> List.first()
  end
end
