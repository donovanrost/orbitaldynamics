defmodule OrbitalDynamics.Constraints.ArtifactMetricTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Constraints.ArtifactMetric
  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.Schema

  test "declares constraint capabilities" do
    assert %{
             constraint: :artifact_metric,
             validation_level: :artifact_contract,
             operators: ["<", "<=", "==", ">=", ">"],
             supported_metrics: supported_metrics,
             known_limits: known_limits
           } = ArtifactMetric.capabilities()

    assert "total_delta_v_km_s" in supported_metrics
    assert :artifact_level_only in known_limits
    assert :missing_or_nil_values_fail in known_limits
    assert :numeric_threshold_violations_can_be_warnings in known_limits
  end

  test "evaluates artifact metric constraints per scenario" do
    constraints = [
      %{
        "id" => "delta_v_budget",
        "metric" => "total_delta_v_km_s",
        "operator" => "<=",
        "value" => 0.015
      },
      %{
        "id" => "minimum_altitude",
        "metric" => "min_altitude_km",
        "operator" => ">=",
        "value" => 650.0
      }
    ]

    assert {:ok, rows} = ArtifactMetric.evaluate_all(artifact(), constraints)

    assert [
             %{
               constraint_id: "delta_v_budget",
               scenario_id: "scenario_1",
               metric: "total_delta_v_km_s",
               status: :pass,
               violation_severity: "fail"
             },
             %{
               constraint_id: "delta_v_budget",
               scenario_id: "scenario_2",
               status: :fail
             },
             %{
               constraint_id: "minimum_altitude",
               scenario_id: "scenario_1",
               status: :fail
             },
             %{
               constraint_id: "minimum_altitude",
               scenario_id: "scenario_2",
               status: :pass
             }
           ] = rows
  end

  test "builds a schema-validated constraint report artifact" do
    constraints = [
      %{
        "id" => "delta_v_budget",
        "metric" => "total_delta_v_km_s",
        "operator" => "<=",
        "value" => 0.015
      }
    ]

    assert {:ok, report} = ArtifactMetric.report(artifact(), constraints)

    assert %{
             "schema_contract" => "constraint_report.v1",
             "model" => "artifact_metric_threshold",
             "model_limits" => model_limits,
             "constraint_count" => 1,
             "row_count" => 2,
             "status" => "fail",
             "status_counts" => %{"pass" => 1, "fail" => 1, "warning" => 0},
             "rows" => [
               %{"constraint_id" => "delta_v_budget", "scenario_id" => "scenario_1"},
               %{"constraint_id" => "delta_v_budget", "scenario_id" => "scenario_2"}
             ]
           } = report

    assert "artifact_level_only" in model_limits
    assert "missing_or_nil_values_fail" in model_limits
    assert "numeric_threshold_violations_can_be_warnings" in model_limits

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes clean numeric string constraint thresholds" do
    constraints = [
      %{
        "id" => "minimum_altitude_string_threshold",
        "metric" => "min_altitude_km",
        "operator" => ">=",
        "value" => "650.0",
        "severity" => "warning"
      }
    ]

    assert {:ok, report} = ArtifactMetric.report(artifact(), constraints)

    assert %{
             "constraint_count" => 1,
             "status" => "warning",
             "status_counts" => %{"pass" => 1, "fail" => 0, "warning" => 1}
           } = report

    assert %{
             "constraint_id" => "minimum_altitude_string_threshold",
             "scenario_id" => "scenario_1",
             "threshold" => 650.0,
             "value" => 621.0,
             "status" => "warning"
           } =
             Enum.find(
               report["rows"],
               &(&1["constraint_id"] == "minimum_altitude_string_threshold" and
                   &1["scenario_id"] == "scenario_1")
             )

    assert {:error, {:invalid_field, "value"}} =
             ArtifactMetric.report(artifact(), [
               %{
                 "id" => "bad_threshold",
                 "metric" => "min_altitude_km",
                 "operator" => ">=",
                 "value" => "six hundred"
               }
             ])

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "top-level public APIs expose artifact metric constraint behavior" do
    constraints = [
      %{
        "id" => "delta_v_budget",
        "metric" => "total_delta_v_km_s",
        "operator" => "<=",
        "value" => 0.015
      }
    ]

    assert {:ok, rows} =
             OrbitalDynamics.evaluate_artifact_metric_constraints(artifact(), constraints)

    assert Enum.map(rows, & &1.status) == [:pass, :fail]

    assert {:ok, report} =
             OrbitalDynamics.artifact_metric_constraint_report(artifact(), constraints)

    assert %{
             "schema_contract" => "constraint_report.v1",
             "status_counts" => %{"pass" => 1, "fail" => 1, "warning" => 0}
           } = report

    assert {:error, {:invalid_field, "constraints"}} =
             OrbitalDynamics.artifact_metric_constraint_report(artifact(), :bad_constraints)

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "warning severity downgrades numeric threshold violations but not missing metrics" do
    constraints = [
      %{
        id: :minimum_altitude_warning,
        metric: :min_altitude_km,
        operator: :>=,
        value: 650.0,
        severity: :warning
      },
      %{
        id: :unsupported_missing_metric,
        metric: :semi_major_axis_km,
        operator: :>=,
        value: 1.0,
        severity: :warning
      }
    ]

    assert {:ok, report} = ArtifactMetric.report(artifact(), constraints)

    assert report["status"] == "fail"
    assert report["status_counts"] == %{"pass" => 1, "fail" => 2, "warning" => 1}

    assert %{
             "constraint_id" => "minimum_altitude_warning",
             "scenario_id" => "scenario_1",
             "status" => "warning",
             "violation_severity" => "warning"
           } = Enum.find(report["rows"], &(&1["constraint_id"] == "minimum_altitude_warning"))

    assert %{
             "constraint_id" => "unsupported_missing_metric",
             "status" => "fail",
             "violation_severity" => "warning"
           } = Enum.find(report["rows"], &(&1["constraint_id"] == "unsupported_missing_metric"))

    assert {:ok, result} =
             ArtifactMetric.evaluate(artifact(),
               constraint: %{
                 id: :minimum_altitude_warning,
                 metric: :min_altitude_km,
                 operator: :>=,
                 value: 650.0,
                 severity: :warning
               }
             )

    assert result.status == :warning

    review = OperatorReview.from_constraint_report(report)
    import = CadenceImport.from_constraint_report(report)

    assert %{
             "constraint_status" => "warning",
             "violation_severity" => "warning"
           } = Enum.find(review["rows"], &(&1["constraint_id"] == "minimum_altitude_warning"))

    assert %{
             "constraint_status" => "warning",
             "violation_severity" => "warning"
           } = Enum.find(import["rows"], &(&1["constraint_id"] == "minimum_altitude_warning"))

    assert {:error, {:invalid_field, "severity"}} =
             ArtifactMetric.report(artifact(), [
               %{
                 id: :bad_severity,
                 metric: :min_altitude_km,
                 operator: :>=,
                 value: 650.0,
                 severity: :notice
               }
             ])

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "implements the constraint behaviour for one constraint" do
    assert {:ok, result} =
             ArtifactMetric.evaluate(artifact(),
               constraint: %{
                 "id" => "delta_v_budget",
                 "metric" => "total_delta_v_km_s",
                 "operator" => "<=",
                 "value" => 0.015
               }
             )

    assert result.status == :fail
    assert length(result.metadata.rows) == 2
  end

  defp artifact do
    %{
      "trajectories" => [
        %{
          "scenario_id" => "scenario_1",
          "final_radius_km" => 7_000.0,
          "final_speed_km_s" => 7.5,
          "min_altitude_km" => 621.0,
          "assumptions" => %{"total_delta_v_km_s" => 0.01}
        },
        %{
          "scenario_id" => "scenario_2",
          "final_radius_km" => 7_100.0,
          "final_speed_km_s" => 7.6,
          "min_altitude_km" => 721.0,
          "assumptions" => %{"total_delta_v_km_s" => 0.02}
        }
      ],
      "access_windows" => [],
      "eclipse_intervals" => []
    }
  end
end
