defmodule OrbitalDynamics.ResultSet.ReportTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{ResultSet.Report, Schema}

  test "declares report capabilities" do
    assert %{
             report: :result_set_summary,
             validation_level: :artifact_contract,
             supported_objectives: supported_objectives,
             ranking_directions: ranking_directions,
             known_limits: known_limits
           } = Report.capabilities()

    assert "final_radius_km" in supported_objectives
    assert "total_delta_v_km_s" in supported_objectives
    assert ranking_directions["final_radius_km"] == "maximize"
    assert ranking_directions["total_delta_v_km_s"] == "minimize"
    assert :artifact_level_only in known_limits
    assert :missing_metric_rows_are_excluded_from_rankings in known_limits
  end

  test "summarizes study artifact counts, assumptions, and durations" do
    summary = Report.summarize(artifact())

    assert summary.study_id == "leo_report"

    assert summary.counts == %{
             trajectories: 2,
             access_windows: 2,
             eclipse_intervals: 1,
             errors: 0
           }

    assert summary.scenario_ids == ["scenario_1", "scenario_2"]
    assert summary.assumptions["propagator"] == "Elixir.OrbitalDynamics.Propagators.J2"
    assert summary.interpolation_modes == ["linear_sample_crossing"]

    assert summary.maneuvers == %{
             scenario_count_with_maneuvers: 2,
             maneuver_count: 2,
             total_delta_v_km_s: 0.03
           }

    assert summary.durations.access_windows.count == 2
    assert summary.durations.access_windows.min_s == 60.0
    assert summary.durations.access_windows.max_s == 120.0
    assert summary.durations.access_windows.mean_s == 90.0
    assert summary.durations.eclipse_intervals.mean_s == 300.0
    assert summary.monte_carlo == nil
    assert summary.run["metadata"]["execution_mode"] == "local_tasks"
    assert summary.scenario_rankings["objective"] == "final_radius_km"
    assert summary.constraints.fail == 1
    assert summary.constraints.failing_scenarios == ["scenario_2"]
    assert summary.best_feasible_ranking["scenario_id"] == "scenario_1"
  end

  test "compares matching artifacts and reports zero boundary deltas" do
    comparison = Report.compare(artifact(), artifact())

    assert comparison.same_study_id
    assert comparison.scenario_ids.same
    assert comparison.outputs.same

    assert comparison.count_deltas == %{
             trajectories: 0,
             access_windows: 0,
             eclipse_intervals: 0,
             errors: 0
           }

    assert comparison.boundary_deltas.access_windows.matched_count == 2

    assert Enum.all?(comparison.boundary_deltas.access_windows.rows, fn row ->
             row.starts_at_delta_s == 0.0 and row.ends_at_delta_s == 0.0
           end)

    assert %{
             "schema_contract" => "ranking_comparison_report.v1",
             "source" => "result_set.compare.scenario_rankings",
             "matched_count" => 2,
             "winner" => %{"changed" => false}
           } = comparison.ranking_comparison_report

    assert {:ok, %{"schema_contract" => "ranking_comparison_report.v1"}} =
             Schema.validate_artifact(comparison.ranking_comparison_report)
  end

  test "compares declared artifact rankings and reports winner changes" do
    right =
      artifact()
      |> put_in(["scenario_rankings", "rows"], [
        %{
          "scenario_id" => "scenario_1",
          "objective" => "final_radius_km",
          "value" => 7_200.0,
          "total_delta_v_km_s" => 0.01
        },
        %{
          "scenario_id" => "scenario_2",
          "objective" => "final_radius_km",
          "value" => 7_100.0,
          "total_delta_v_km_s" => 0.02
        }
      ])

    comparison = Report.compare(artifact(), right)

    assert %{
             "winner" => %{
               "left_scenario_id" => "scenario_2",
               "right_scenario_id" => "scenario_1",
               "changed" => true
             }
           } = comparison.ranking_comparison_report

    assert %{
             "scenario_id" => "scenario_1",
             "left_rank" => 2,
             "right_rank" => 1,
             "rank_delta" => 1,
             "value_delta" => 200.0
           } =
             Enum.find(
               comparison.ranking_comparison_report["rows"],
               &(&1["scenario_id"] == "scenario_1")
             )
  end

  test "skips ranking comparison report for incompatible declared rankings" do
    right = put_in(artifact(), ["scenario_rankings", "objective"], "total_delta_v_km_s")

    assert %{ranking_comparison_report: nil} = Report.compare(artifact(), right)
  end

  test "ranks scenarios by objective" do
    assert [
             %{scenario_id: "scenario_2", value: 7_100.0},
             %{scenario_id: "scenario_1", value: 7_000.0}
           ] = Report.rank(artifact(), "final_radius_km", limit: 2)

    assert [
             %{scenario_id: "scenario_1", value: 0.01},
             %{scenario_id: "scenario_2", value: 0.02}
           ] = Report.rank(artifact(), "total_delta_v_km_s", limit: 2)

    assert [
             %{scenario_id: "scenario_2", value: 721.0},
             %{scenario_id: "scenario_1", value: 621.0}
           ] = Report.rank(artifact(), "min_altitude_km", limit: 2)
  end

  test "normalizes clean numeric string report metrics and event durations" do
    string_artifact =
      artifact()
      |> update_in(["trajectories"], fn trajectories ->
        Enum.map(trajectories, fn trajectory ->
          trajectory
          |> Map.update!("final_radius_km", &to_string/1)
          |> Map.update!("min_altitude_km", &to_string/1)
          |> Map.update!("max_altitude_km", &to_string/1)
          |> update_in(["assumptions", "maneuver_count"], &to_string/1)
          |> update_in(["assumptions", "total_delta_v_km_s"], &to_string/1)
        end)
      end)
      |> update_in(["access_windows"], &stringify_event_times/1)
      |> update_in(["eclipse_intervals"], &stringify_event_times/1)

    summary = Report.summarize(string_artifact)

    assert summary.maneuvers == %{
             scenario_count_with_maneuvers: 2,
             maneuver_count: 2,
             total_delta_v_km_s: 0.03
           }

    assert summary.durations.access_windows.min_s == 60.0
    assert summary.durations.eclipse_intervals.mean_s == 300.0

    assert [
             %{scenario_id: "scenario_2", value: 7_100.0},
             %{scenario_id: "scenario_1", value: 7_000.0}
           ] = Report.rank(string_artifact, "final_radius_km", limit: 2)

    assert [
             %{scenario_id: "scenario_2", value: 721.0},
             %{scenario_id: "scenario_1", value: 621.0}
           ] = Report.rank(string_artifact, "min_altitude_km", limit: 2)

    [boundary_delta | _rest] =
      Report.compare(string_artifact, string_artifact).boundary_deltas.access_windows.rows

    assert boundary_delta.starts_at_delta_s == 0.0
    assert boundary_delta.ends_at_delta_s == 0.0

    malformed =
      update_in(string_artifact, ["trajectories"], fn [first | rest] ->
        [Map.put(first, "max_altitude_km", "not_available") | rest]
      end)

    assert [%{scenario_id: "scenario_2", value: 723.0}] =
             Report.rank(malformed, "max_altitude_km", limit: 2)
  end

  test "summarizes monte carlo metric distributions and pass probability" do
    summary =
      artifact()
      |> put_in(["assumptions", "study_metadata"], %{})
      |> put_in(["assumptions", "study_metadata", "monte_carlo"], %{
        "generator" => "state_vector_dispersion",
        "seed" => 12_345,
        "count" => 2,
        "position_sigma_km" => [0.1, 0.1, 0.05],
        "velocity_sigma_km_s" => [0.0001, 0.0001, 0.00005]
      })
      |> Report.summarize()

    assert summary.monte_carlo.generator == "state_vector_dispersion"
    assert summary.monte_carlo.seed == 12_345
    assert summary.monte_carlo.sample_count == 2
    assert summary.monte_carlo.metrics.final_radius_km.min == 7_000.0
    assert summary.monte_carlo.metrics.final_radius_km.mean == 7_050.0
    assert summary.monte_carlo.metrics.final_radius_km.max == 7_100.0
    assert summary.monte_carlo.metrics.min_altitude_km.min == 621.0
    assert summary.monte_carlo.metrics.min_altitude_km.mean == 671.0
    assert summary.monte_carlo.metrics.perigee_altitude_km.max == 720.0
    assert summary.monte_carlo.metrics.eccentricity.mean == 0.015
    assert summary.monte_carlo.constraints.passed_scenarios == 1
    assert summary.monte_carlo.constraints.failed_scenarios == ["scenario_2"]
    assert summary.monte_carlo.constraints.pass_probability == 0.5
  end

  test "compares changed event boundaries and counts" do
    changed =
      artifact()
      |> update_in(["access_windows"], fn [_first, second] ->
        [Map.merge(second, %{"starts_at_s" => 220.0, "ends_at_s" => 360.0})]
      end)
      |> update_in(["errors"], fn errors -> [%{"stage" => "propagation"} | errors] end)

    comparison = Report.compare(artifact(), changed)

    assert comparison.count_deltas.access_windows == -1
    assert comparison.count_deltas.errors == 1
    assert comparison.boundary_deltas.access_windows.matched_count == 1

    assert comparison.boundary_deltas.access_windows.missing_right == [
             %{
               event_type: "access_window",
               scenario_id: "scenario_1",
               ground_station_id: "gs_1",
               ordinal: 1
             }
           ]

    assert [
             %{
               starts_at_delta_s: 20.0,
               ends_at_delta_s: 40.0
             }
           ] = comparison.boundary_deltas.access_windows.rows
  end

  test "reads artifact JSON from disk" do
    path = Path.join(System.tmp_dir!(), "orbital_dynamics_study_report_test.json")
    on_exit(fn -> File.rm(path) end)

    File.write!(path, :json.encode(artifact()))

    assert %{"schema_version" => 1} = Report.read_artifact!(path)
  end

  defp artifact do
    %{
      "schema_version" => 1,
      "generated_at" => "2026-05-13T00:00:00Z",
      "study_id" => "leo_report",
      "metadata" => %{"output_count" => %{"errors" => 0}},
      "run" => %{
        "status" => "completed",
        "node" => "nonode@nohost",
        "duration_ms" => 12,
        "options" => %{"max_concurrency" => 8},
        "metadata" => %{
          "execution_mode" => "local_tasks",
          "scheduler_count" => 8,
          "scenario_count" => 2
        }
      },
      "errors" => [],
      "trajectories" => [
        %{
          "scenario_id" => "scenario_1",
          "sample_count" => 10,
          "final_radius_km" => 7_000.0,
          "final_speed_km_s" => 7.5,
          "min_radius_km" => 6_999.0,
          "max_radius_km" => 7_001.0,
          "min_altitude_km" => 621.0,
          "max_altitude_km" => 623.0,
          "semi_major_axis_km" => 7_000.0,
          "eccentricity" => 0.01,
          "perigee_radius_km" => 6_999.0,
          "apogee_radius_km" => 7_001.0,
          "perigee_altitude_km" => 620.0,
          "apogee_altitude_km" => 622.0,
          "assumptions" => %{
            "maneuver_count" => 1,
            "total_delta_v_km_s" => 0.01
          }
        },
        %{
          "scenario_id" => "scenario_2",
          "sample_count" => 10,
          "final_radius_km" => 7_100.0,
          "final_speed_km_s" => 7.6,
          "min_radius_km" => 7_099.0,
          "max_radius_km" => 7_101.0,
          "min_altitude_km" => 721.0,
          "max_altitude_km" => 723.0,
          "semi_major_axis_km" => 7_100.0,
          "eccentricity" => 0.02,
          "perigee_radius_km" => 7_099.0,
          "apogee_radius_km" => 7_101.0,
          "perigee_altitude_km" => 720.0,
          "apogee_altitude_km" => 722.0,
          "assumptions" => %{
            "maneuver_count" => 1,
            "total_delta_v_km_s" => 0.02
          }
        }
      ],
      "access_windows" => [
        access_window("scenario_1", "gs_1", 100.0, 160.0),
        access_window("scenario_2", "gs_2", 200.0, 320.0)
      ],
      "eclipse_intervals" => [
        %{
          "scenario_id" => "scenario_1",
          "starts_at_s" => 400.0,
          "ends_at_s" => 700.0,
          "assumptions" => %{
            "interpolation" => "linear_sample_crossing",
            "shadow_model" => "cylindrical_central_body_shadow"
          }
        }
      ],
      "scenario_rankings" => %{
        "objective" => "final_radius_km",
        "objective_direction" => "maximize",
        "rank_limit" => 2,
        "rows" => [
          %{
            "scenario_id" => "scenario_2",
            "objective" => "final_radius_km",
            "value" => 7_100.0,
            "total_delta_v_km_s" => 0.02
          },
          %{
            "scenario_id" => "scenario_1",
            "objective" => "final_radius_km",
            "value" => 7_000.0,
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
          "threshold" => 0.015,
          "value" => 0.01,
          "status" => "pass",
          "score" => 0.005
        },
        %{
          "constraint_id" => "delta_v_budget",
          "scenario_id" => "scenario_2",
          "metric" => "total_delta_v_km_s",
          "operator" => "<=",
          "threshold" => 0.015,
          "value" => 0.02,
          "status" => "fail",
          "score" => -0.005
        }
      ],
      "assumptions" => %{
        "outputs" => ["trajectories", "access_windows", "eclipses"],
        "propagator" => "Elixir.OrbitalDynamics.Propagators.J2",
        "central_body" => "earth"
      }
    }
  end

  defp access_window(scenario_id, ground_station_id, starts_at_s, ends_at_s) do
    %{
      "scenario_id" => scenario_id,
      "ground_station_id" => ground_station_id,
      "starts_at_s" => starts_at_s,
      "ends_at_s" => ends_at_s,
      "assumptions" => %{
        "interpolation" => "linear_sample_crossing",
        "geometry_model" => "simplified_spherical_earth_rotation"
      }
    }
  end

  defp stringify_event_times(rows) do
    Enum.map(rows, fn row ->
      row
      |> Map.update!("starts_at_s", &to_string/1)
      |> Map.update!("ends_at_s", &to_string/1)
    end)
  end
end
