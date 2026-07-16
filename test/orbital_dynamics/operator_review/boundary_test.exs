defmodule OrbitalDynamics.OperatorReview.BoundaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "rejects unsupported review package source artifact types" do
    package =
      OperatorReview.from_constraint_report(constraint_report())
      |> Map.put("source_artifact_type", "provider_custom.v1")

    assert {:error, report} = Schema.validate_artifact(package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.source_artifact_type" and &1["message"] =~ "must be one of")
           )
  end

  test "rejects stale operator review package model identifiers" do
    package =
      OperatorReview.from_constraint_report(constraint_report())
      |> Map.put("model", "stale_operator_review_model")

    assert {:error, report} = Schema.validate_artifact(package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"artifact_only_operator_review_package\"")
           )
  end

  test "public facade rejects unsupported operator review inputs with boundary errors" do
    package = OperatorReview.from_constraint_report(constraint_report())

    assert OrbitalDynamics.operator_review_package(package) == package

    assert OrbitalDynamics.operator_review_package(%{
             schema_contract: "operator_review_package.v1",
             source_artifact_type: "constraint_report.v1",
             source_artifact_id: "constraint_report:test",
             rows: []
           }) == %{
             "schema_contract" => "operator_review_package.v1",
             "source_artifact_type" => "constraint_report.v1",
             "source_artifact_id" => "constraint_report:test",
             "rows" => []
           }

    assert_raise ArgumentError,
                 ~r/unsupported operator review artifact contract "unknown_contract.v1"/,
                 fn ->
                   OrbitalDynamics.operator_review_package(%{
                     "schema_contract" => "unknown_contract.v1"
                   })
                 end

    assert_raise ArgumentError,
                 ~r/supported contracts: .*campaign_plan\.v1.*execution_report\.v1/s,
                 fn ->
                   OrbitalDynamics.operator_review_package(%{schema_contract: :unknown_contract})
                 end

    assert_raise ArgumentError, ~r/operator review artifact must be a map/, fn ->
      OrbitalDynamics.operator_review_package(:not_an_artifact)
    end
  end

  defp constraint_report do
    %{
      "schema_contract" => "constraint_report.v1",
      "model" => "artifact_metric_threshold",
      "status" => "fail",
      "constraint_count" => 2,
      "row_count" => 3,
      "status_counts" => %{"fail" => 1, "pass" => 1, "warning" => 1},
      "assumptions" => %{
        "constraint_model" => "artifact_level_metric_thresholds",
        "missing_or_nil_values" => "fail",
        "source" => "study_metadata.constraints"
      },
      "rows" => [
        %{
          "constraint_id" => "minimum_operational_altitude",
          "metric" => "min_altitude_km",
          "operator" => ">=",
          "scenario_id" => "dispersion_1",
          "score" => 0.42,
          "status" => "pass",
          "threshold" => 621.5,
          "value" => 621.92
        },
        %{
          "constraint_id" => "minimum_operational_altitude",
          "metric" => "min_altitude_km",
          "operator" => ">=",
          "scenario_id" => "dispersion_2",
          "score" => -0.31,
          "status" => "fail",
          "threshold" => 621.5,
          "value" => 621.19
        },
        %{
          "constraint_id" => "downlink_margin",
          "metric" => "estimated_throughput_mb",
          "operator" => ">=",
          "scenario_id" => "dispersion_3",
          "status" => "warning",
          "threshold" => 120.0
        }
      ]
    }
  end
end
