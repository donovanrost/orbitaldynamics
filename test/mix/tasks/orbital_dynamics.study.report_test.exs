defmodule Mix.Tasks.OrbitalDynamics.Study.ReportTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "prints a study artifact summary" do
    input_path = Path.join(System.tmp_dir!(), "orbital_dynamics_study_report_task_input.json")

    on_exit(fn ->
      File.rm(input_path)
      Mix.Task.reenable("orbital_dynamics.study.report")
    end)

    File.write!(input_path, :json.encode(artifact("report_task", 100.0, 160.0)))

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.report", ["--input", input_path])
      end)

    assert output =~ "OrbitalDynamics study report"
    assert output =~ "study: report_task"
    assert output =~ "run duration: 12ms"
    assert output =~ "execution: local_tasks"
    assert output =~ "task supervisor node: nonode@nohost"
    assert output =~ "access windows: 1"
    assert output =~ "access duration: count 1, min 60.000s"
    assert output =~ "constraints: pass 1, fail 0, warning 0"
    assert output =~ "best feasible ranked scenario: scenario_1"
    assert output =~ "declared ranking: final_radius_km (maximize)"
  end

  test "prints a study artifact comparison" do
    left_path = Path.join(System.tmp_dir!(), "orbital_dynamics_study_report_task_left.json")
    right_path = Path.join(System.tmp_dir!(), "orbital_dynamics_study_report_task_right.json")

    on_exit(fn ->
      File.rm(left_path)
      File.rm(right_path)
      Mix.Task.reenable("orbital_dynamics.study.report")
    end)

    File.write!(left_path, :json.encode(artifact("report_task", 100.0, 160.0)))
    File.write!(right_path, :json.encode(artifact("report_task", 101.0, 162.0)))

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.report", [
          "--input",
          left_path,
          "--compare",
          right_path
        ])
      end)

    assert output =~ "OrbitalDynamics study comparison"
    assert output =~ "same study id: true"
    assert output =~ "access windows: matched 1"
    assert output =~ "max_start_delta 1.000s"
    assert output =~ "max_end_delta 2.000s"
    assert output =~ "ranking comparison: final_radius_km (maximize)"
    assert output =~ "winner changed: false"
    assert output =~ "ranking rows: 1, matched 1, left-only 0, right-only 0"
  end

  test "prints a study artifact ranking" do
    input_path = Path.join(System.tmp_dir!(), "orbital_dynamics_study_report_task_rank.json")

    on_exit(fn ->
      File.rm(input_path)
      Mix.Task.reenable("orbital_dynamics.study.report")
    end)

    File.write!(input_path, :json.encode(artifact("report_task", 100.0, 160.0)))

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.study.report", [
          "--input",
          input_path,
          "--rank",
          "final_radius_km",
          "--limit",
          "1"
        ])
      end)

    assert output =~ "OrbitalDynamics study ranking"
    assert output =~ "objective: final_radius_km"
    assert output =~ "scenario_1"
  end

  defp artifact(study_id, starts_at_s, ends_at_s) do
    %{
      "schema_version" => 1,
      "generated_at" => "2026-05-13T00:00:00Z",
      "study_id" => study_id,
      "run" => %{
        "status" => "completed",
        "node" => "nonode@nohost",
        "duration_ms" => 12,
        "options" => %{"max_concurrency" => 8},
        "metadata" => %{
          "execution_mode" => "local_tasks",
          "task_supervisor_node" => "nonode@nohost",
          "scheduler_count" => 8,
          "scenario_count" => 1
        }
      },
      "errors" => [],
      "trajectories" => [
        %{
          "scenario_id" => "scenario_1",
          "final_radius_km" => 7000.0,
          "final_speed_km_s" => 7.5,
          "assumptions" => %{"total_delta_v_km_s" => 0.01}
        }
      ],
      "access_windows" => [
        %{
          "scenario_id" => "scenario_1",
          "ground_station_id" => "gs_1",
          "starts_at_s" => starts_at_s,
          "ends_at_s" => ends_at_s,
          "assumptions" => %{"interpolation" => "linear_sample_crossing"}
        }
      ],
      "eclipse_intervals" => [],
      "scenario_rankings" => %{
        "objective" => "final_radius_km",
        "objective_direction" => "maximize",
        "rank_limit" => 1,
        "rows" => [
          %{
            "scenario_id" => "scenario_1",
            "objective" => "final_radius_km",
            "value" => 7000.0,
            "total_delta_v_km_s" => 0.01
          }
        ]
      },
      "constraint_results" => [
        %{
          "constraint_id" => "delta_v_budget",
          "scenario_id" => "scenario_1",
          "metric" => "total_delta_v_km_s",
          "operator" => "<=",
          "threshold" => 0.02,
          "value" => 0.01,
          "status" => "pass",
          "score" => 0.01
        }
      ],
      "assumptions" => %{
        "outputs" => ["trajectories", "access_windows"],
        "propagator" => "Elixir.OrbitalDynamics.Propagators.J2",
        "central_body" => "earth"
      }
    }
  end
end
