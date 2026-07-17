defmodule OrbitalDynamics.Validation.DecisionSupportFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.DecisionSupportFixtures,
    only: [
      maneuver_review_report_fixture_observations: 0,
      maneuver_review_report_fixture: 0,
      monte_carlo_reproducibility_report_fixture_observations: 0,
      monte_carlo_reproducibility_report_fixture: 0,
      pareto_frontier_report_fixture_observations: 0,
      pareto_frontier_report_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated maneuver review report reference fixtures" do
    fixture_id = "fixture.artifact.maneuver_review_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.maneuver_review_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = maneuver_review_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               maneuver_review_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      maneuver_review_report_fixture_observations()
      |> Map.put("execution_uncertainty_missing_count", 0)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "execution_uncertainty_missing_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "maneuver_review_report.v1")

    stale_model = Map.put(report, "model", "stale_maneuver_review_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "maneuver_review_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"artifact_only_maneuver_review_report\"")
           )

    stale_total_delta_v = Map.put(report, "total_delta_v_km_s", 0.0)

    assert {:error, stale_total_delta_v_report} =
             Schema.validate_artifact(stale_total_delta_v,
               schema_contract: "maneuver_review_report.v1"
             )

    assert Enum.any?(
             stale_total_delta_v_report["errors"],
             &(&1["path"] == "$.total_delta_v_km_s")
           )

    stale_model_limits = Map.put(report, "model_limits", ["no_command_execution"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "maneuver_review_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_operator_action_counts =
      Map.put(report, "required_operator_action_counts", %{"review_maneuver_recommendation" => 0})

    assert {:error, stale_operator_action_counts_report} =
             Schema.validate_artifact(stale_operator_action_counts,
               schema_contract: "maneuver_review_report.v1"
             )

    assert Enum.any?(
             stale_operator_action_counts_report["errors"],
             &(&1["path"] == "$.required_operator_action_counts")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "maneuver_review_report.v1",
             report
           ) == Validation.artifact_observations("maneuver_review_report.v1", report)
  end

  test "verifies curated Monte Carlo reproducibility report reference fixtures" do
    fixture_id = "fixture.artifact.monte_carlo_reproducibility_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.monte_carlo_reproducibility_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = monte_carlo_reproducibility_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               monte_carlo_reproducibility_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      monte_carlo_reproducibility_report_fixture_observations()
      |> Map.put("generated_scenario_count", 19)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "generated_scenario_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "monte_carlo_reproducibility_report.v1",
             report
           ) ==
             Validation.artifact_observations("monte_carlo_reproducibility_report.v1", report)

    assert {:ok, %{"schema_contract" => "monte_carlo_reproducibility_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "monte_carlo_reproducibility_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_monte_carlo_dispersion_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "monte_carlo_reproducibility_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"seeded_independent_normal_cartesian_dispersion\"")
           )

    stale_generated_scenario_count = Map.put(report, "generated_scenario_count", 19)

    assert {:error, stale_generated_scenario_count_report} =
             Schema.validate_artifact(stale_generated_scenario_count,
               schema_contract: "monte_carlo_reproducibility_report.v1"
             )

    assert Enum.any?(
             stale_generated_scenario_count_report["errors"],
             &(&1["path"] == "$.generated_scenario_count")
           )

    duplicate_generated_scenario_ids =
      report
      |> Map.fetch!("generated_scenario_ids")
      |> List.replace_at(1, "dispersion_1")

    stale_generated_scenario_ids =
      Map.put(report, "generated_scenario_ids", duplicate_generated_scenario_ids)

    assert {:error, stale_generated_scenario_ids_report} =
             Schema.validate_artifact(stale_generated_scenario_ids,
               schema_contract: "monte_carlo_reproducibility_report.v1"
             )

    assert Enum.any?(
             stale_generated_scenario_ids_report["errors"],
             &(&1["path"] == "$.generated_scenario_ids")
           )

    stale_known_limits =
      Map.put(report, "known_limits", Enum.drop(Map.fetch!(report, "known_limits"), 1))

    assert {:error, stale_known_limits_report} =
             Schema.validate_artifact(stale_known_limits,
               schema_contract: "monte_carlo_reproducibility_report.v1"
             )

    assert Enum.any?(
             stale_known_limits_report["errors"],
             &(&1["path"] == "$.known_limits")
           )
  end

  test "verifies curated Pareto frontier report reference fixtures" do
    fixture_id = "fixture.artifact.pareto_frontier_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.pareto_frontier_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = pareto_frontier_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               pareto_frontier_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      pareto_frontier_report_fixture_observations()
      |> Map.put("frontier_count", 2)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "frontier_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "pareto_frontier_report.v1",
             report
           ) == Validation.artifact_observations("pareto_frontier_report.v1", report)

    assert {:ok, %{"schema_contract" => "pareto_frontier_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "pareto_frontier_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_pareto_frontier_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "pareto_frontier_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"objective_vector_pareto_frontier\"")
           )

    stale_count_fields = [
      {"alternative_count", 3},
      {"frontier_count", 2},
      {"dominated_count", 0},
      {"objective_count", 1}
    ]

    Enum.each(stale_count_fields, fn {field, stale_value} ->
      stale_report = Map.put(report, field, stale_value)

      assert {:error, stale_validation_report} =
               Schema.validate_artifact(stale_report,
                 schema_contract: "pareto_frontier_report.v1"
               )

      assert Enum.any?(stale_validation_report["errors"], &(&1["path"] == "$.#{field}"))
    end)

    stale_frontier_ids = Map.put(report, "frontier_ids", ["balanced"])

    assert {:error, stale_frontier_ids_report} =
             Schema.validate_artifact(stale_frontier_ids,
               schema_contract: "pareto_frontier_report.v1"
             )

    assert Enum.any?(
             stale_frontier_ids_report["errors"],
             &(&1["path"] == "$.frontier_ids")
           )

    stale_dominated_ids = Map.put(report, "dominated_ids", [])

    assert {:error, stale_dominated_ids_report} =
             Schema.validate_artifact(stale_dominated_ids,
               schema_contract: "pareto_frontier_report.v1"
             )

    assert Enum.any?(
             stale_dominated_ids_report["errors"],
             &(&1["path"] == "$.dominated_ids")
           )

    stale_objective_keys = put_in(report, ["rows", Access.at(0), "objective_keys"], ["coverage"])

    assert {:error, stale_objective_keys_report} =
             Schema.validate_artifact(stale_objective_keys,
               schema_contract: "pareto_frontier_report.v1"
             )

    assert Enum.any?(
             stale_objective_keys_report["errors"],
             &(&1["path"] == "$.rows[0].objective_keys")
           )
  end
end
