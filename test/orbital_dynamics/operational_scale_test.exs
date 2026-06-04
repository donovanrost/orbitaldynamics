defmodule OrbitalDynamics.OperationalScaleTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.OperationalScale

  test "declares operational scale targets by maturity level" do
    targets = OperationalScale.targets()

    assert %{
             "schema_contract" => "operational_scale_target.v1",
             "maturity_level" => "v1_campaign",
             "spacecraft_count" => 4,
             "planning_horizon_s" => 86_400.0,
             "distributed_execution_threshold_scenarios" => 2_000,
             "known_limits" => known_limits
           } = targets["v1_campaign"]

    assert "target does not imply flight certification" in known_limits

    assert {:ok, %{"maturity_level" => "v3_strategy", "scenario_count" => 5_000}} =
             OperationalScale.target(:v3_strategy)
  end

  test "compares observed metrics against a target" do
    assert {:ok,
            %{
              "schema_contract" => "operational_scale_comparison.v1",
              "maturity_level" => "v1_campaign",
              "status" => "within_target",
              "rows" => rows
            }} =
             OperationalScale.compare(:v1_campaign, %{
               spacecraft_count: 3,
               scenario_count: 100,
               local_runtime_s: 12.5,
               artifact_size_mb: 10.0
             })

    assert Enum.all?(rows, &(&1["status"] == "within_target"))
  end

  test "reports over-target and invalid observations" do
    assert {:ok, %{"status" => "over_target", "rows" => rows}} =
             OperationalScale.compare("v1_campaign", %{
               "scenario_count" => 1_000,
               "local_runtime_s" => 45.0,
               "artifact_size_mb" => "large"
             })

    assert %{"metric" => "scenario_count", "status" => "over_target"} =
             Enum.find(rows, &(&1["metric"] == "scenario_count"))

    assert %{"metric" => "artifact_size_mb", "status" => "not_evaluated"} =
             Enum.find(rows, &(&1["metric"] == "artifact_size_mb"))
  end

  test "extracts benchmark groups into operational scale comparisons" do
    assert {:ok,
            %{
              "maturity_level" => "v1_campaign",
              "status" => "within_target",
              "rows" => rows,
              "distribution_guidance" => %{
                "status" => "local_concurrency_target",
                "distributed_execution_threshold_scenarios" => 2_000
              }
            }} =
             OperationalScale.compare_benchmark_group(:v1_campaign, %{
               mode: "local",
               monte_carlo_count: 200,
               median_duration_ms: 12_500.0
             })

    assert %{"metric" => "scenario_count", "observed" => 200.0} =
             Enum.find(rows, &(&1["metric"] == "scenario_count"))

    assert %{"metric" => "local_runtime_s", "observed" => 12.5} =
             Enum.find(rows, &(&1["metric"] == "local_runtime_s"))
  end

  test "does not treat distributed benchmark runtime as local runtime" do
    assert {:ok,
            %{
              "rows" => rows,
              "distribution_guidance" => %{"status" => "distributed_evidence"}
            }} =
             OperationalScale.compare_benchmark_group("v1_campaign", %{
               mode: "distributed",
               scenario_count: 2_000,
               median_duration_ms: 5_000.0,
               task_chunk_size: 100,
               node_count: 2
             })

    refute Enum.any?(rows, &(&1["metric"] == "local_runtime_s"))
  end

  test "compares result artifact execution and payload metrics against scale targets" do
    assert {:ok,
            %{
              "maturity_level" => "v1_campaign",
              "status" => "within_target",
              "source" => %{
                "study_id" => "long_running_checkout",
                "execution_mode" => "local_tasks",
                "artifact_body_bytes" => 12_500_000
              },
              "distribution_guidance" => %{
                "status" => "local_concurrency_target",
                "mode" => "local_tasks"
              },
              "rows" => rows
            }} =
             OperationalScale.compare_result_artifact(:v1_campaign, %{
               "study_id" => "long_running_checkout",
               "execution_report" => %{
                 "schema_contract" => "execution_report.v1",
                 "study_id" => "long_running_checkout",
                 "run_id" => "run-1",
                 "status" => "completed",
                 "execution_mode" => "local_tasks",
                 "backend" => "Elixir.OrbitalDynamics.Propagators.TwoBody",
                 "scenario_count" => 150,
                 "task_chunk_size" => 100,
                 "failed_scenario_count" => 0,
                 "phase_timings_ms" => %{"propagation" => 20_000, "event_detection" => 5_000}
               },
               "payload_metrics" => %{
                 "schema_contract" => "result_payload_metrics.v1",
                 "artifact_body_bytes" => 12_500_000
               }
             })

    assert %{"metric" => "scenario_count", "observed" => 150.0} =
             Enum.find(rows, &(&1["metric"] == "scenario_count"))

    assert %{"metric" => "local_runtime_s", "observed" => 25.0} =
             Enum.find(rows, &(&1["metric"] == "local_runtime_s"))

    assert %{"metric" => "artifact_size_mb", "observed" => 12.5} =
             Enum.find(rows, &(&1["metric"] == "artifact_size_mb"))
  end

  test "does not treat distributed result artifact runtime as local runtime" do
    assert {:ok,
            %{
              "distribution_guidance" => %{"status" => "distributed_evidence"},
              "rows" => rows
            }} =
             OperationalScale.compare_result_artifact("v1_campaign", %{
               "execution_report" => %{
                 "execution_mode" => "distributed_task_supervisors",
                 "scenario_count" => 2_000,
                 "phase_timings_ms" => %{"propagation" => 5_000}
               },
               "payload_metrics" => %{"artifact_body_bytes" => 1_000_000}
             })

    refute Enum.any?(rows, &(&1["metric"] == "local_runtime_s"))
  end

  test "compares benchmark trend summaries against scale targets" do
    trend_summary = %{
      artifact_count: 2,
      groups: [
        %{
          mode: "local",
          propagator: "two_body",
          monte_carlo_count: 200,
          task_chunk_size: 100,
          max_concurrency: 8,
          sample_count: 2,
          latest_median_duration_ms: 12_000.0,
          trend_status: "improved",
          duration_delta_percent: -20.0
        },
        %{
          mode: "local",
          propagator: "j2",
          monte_carlo_count: 200,
          task_chunk_size: 100,
          max_concurrency: 8,
          sample_count: 2,
          latest_median_duration_ms: 18_000.0,
          trend_status: "regressed",
          duration_delta_percent: 25.0
        }
      ]
    }

    assert {:ok,
            %{
              "schema_contract" => "operational_scale_trend_comparison.v1",
              "maturity_level" => "v1_campaign",
              "status" => "trend_regressed",
              "artifact_count" => 2,
              "group_count" => 2,
              "rows" => rows
            }} = OperationalScale.compare_benchmark_trend(:v1_campaign, trend_summary)

    assert %{
             "mode" => "local",
             "scale_status" => "within_target",
             "trend_status" => "improved",
             "scale_rows" => local_scale_rows
           } = Enum.find(rows, &(&1["mode"] == "local"))

    assert %{"metric" => "local_runtime_s", "observed" => 12.0} =
             Enum.find(local_scale_rows, &(&1["metric"] == "local_runtime_s"))

    assert %{
             "mode" => "local",
             "propagator" => "j2",
             "scale_status" => "within_target",
             "trend_status" => "regressed"
           } = Enum.find(rows, &(&1["propagator"] == "j2"))

    assert OrbitalDynamics.operational_scale_benchmark_trend_comparison(
             :v1_campaign,
             trend_summary
           ) == OperationalScale.compare_benchmark_trend(:v1_campaign, trend_summary)
  end
end
