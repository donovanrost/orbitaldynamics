defmodule OrbitalDynamics.ValidationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Validation

  alias OrbitalDynamics.Validation.DeterministicReferenceFixtureReport
  alias OrbitalDynamics.Validation.Level5ContractFixtures

  @campaign_search_fixture_id "fixture.artifact.campaign_plan_search_trace.v1"

  import OrbitalDynamics.Validation.OrbitalReferenceFixtures,
    only: [two_body_fixture_observations: 0]

  test "fails reference fixture verification outside declared tolerances" do
    observations =
      two_body_fixture_observations()
      |> Map.update!("final_position_km", fn [x, y, z] -> [x + 0.01, y, z] end)

    assert {:ok, %{"status" => "fail", "checks" => checks}} =
             Validation.verify_reference_fixture(
               "fixture.two_body.circular_leo_600s",
               observations
             )

    assert %{"status" => "fail", "max_abs_error" => error, "tolerance" => tolerance} =
             Enum.find(checks, &(&1["field"] == "final_position_km"))

    assert error > tolerance
  end

  test "campaign search fixture detects exact identity and plan binding counterfactuals" do
    trace = Level5ContractFixtures.campaign_plan_search_trace_fixture()
    expected_id = Map.fetch!(trace, "id")
    expected_plan_id = Map.fetch!(trace, "plan_id")
    counterfactual_plan_id = "campaign_plan:counterfactual:2026-08-20T12:00:00Z"
    counterfactual_id = "campaign_plan_search_trace:#{counterfactual_plan_id}"

    mismatched_id_observations =
      trace
      |> Map.put("id", counterfactual_id)
      |> then(&Validation.artifact_observations("campaign_plan_search_trace.v1", &1))

    assert {:ok, %{"status" => "fail", "checks" => mismatched_id_checks}} =
             Validation.verify_reference_fixture(
               @campaign_search_fixture_id,
               mismatched_id_observations
             )

    assert mismatched_id_checks
           |> Enum.filter(&(&1["status"] == "fail"))
           |> Enum.map(& &1["field"]) == ["id", "identity_matches_plan_id"]

    assert %{
             "status" => "fail",
             "expected" => ^expected_id,
             "observed" => ^counterfactual_id
           } = Enum.find(mismatched_id_checks, &(&1["field"] == "id"))

    assert %{"status" => "pass", "observed" => ^expected_plan_id} =
             Enum.find(mismatched_id_checks, &(&1["field"] == "plan_id"))

    assert %{"status" => "fail", "expected" => true, "observed" => false} =
             Enum.find(
               mismatched_id_checks,
               &(&1["field"] == "identity_matches_plan_id")
             )

    coherently_rebound_observations =
      trace
      |> Map.put("id", counterfactual_id)
      |> Map.put("plan_id", counterfactual_plan_id)
      |> then(&Validation.artifact_observations("campaign_plan_search_trace.v1", &1))

    assert {:ok, %{"status" => "fail", "checks" => coherently_rebound_checks}} =
             Validation.verify_reference_fixture(
               @campaign_search_fixture_id,
               coherently_rebound_observations
             )

    assert coherently_rebound_checks
           |> Enum.filter(&(&1["status"] == "fail"))
           |> Enum.map(& &1["field"]) == ["id", "plan_id"]

    assert %{
             "status" => "fail",
             "expected" => ^expected_id,
             "observed" => ^counterfactual_id
           } = Enum.find(coherently_rebound_checks, &(&1["field"] == "id"))

    assert %{
             "status" => "fail",
             "expected" => ^expected_plan_id,
             "observed" => ^counterfactual_plan_id
           } = Enum.find(coherently_rebound_checks, &(&1["field"] == "plan_id"))

    assert %{"status" => "pass", "expected" => true, "observed" => true} =
             Enum.find(
               coherently_rebound_checks,
               &(&1["field"] == "identity_matches_plan_id")
             )
  end

  test "counts malformed observations against the current source registry" do
    expected_fixture_count = map_size(Validation.reference_fixtures())

    invalid_observation_report =
      Validation.reference_fixture_report(%{
        "fixture.two_body.circular_leo_600s" => :not_an_observation_map
      })

    assert %{
             "status" => "fail",
             "fixture_count" => ^expected_fixture_count,
             "status_counts" => %{"fail" => ^expected_fixture_count},
             "reports" => invalid_observation_reports
           } = invalid_observation_report

    assert %{
             "schema_contract" => "validation_reference_report.v1",
             "fixture_id" => "fixture.two_body.circular_leo_600s",
             "status" => "fail",
             "checks" => [
               %{
                 "field" => "observations",
                 "status" => "fail",
                 "expected" => "valid observations map"
               }
             ]
           } =
             Enum.find(
               invalid_observation_reports,
               &(&1["fixture_id"] == "fixture.two_body.circular_leo_600s")
             )

    assert {:ok, %{"schema_contract" => "validation_reference_fixture_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(invalid_observation_report)
  end

  test "builds deterministic reference fixture reports" do
    report =
      DeterministicReferenceFixtureReport.build()

    expected_fixture_count = map_size(Validation.reference_fixtures())

    assert expected_fixture_count == 210

    assert %{
             "schema_contract" => "validation_reference_fixture_report.v1",
             "status" => "pass",
             "fixture_count" => ^expected_fixture_count,
             "status_counts" => %{"pass" => ^expected_fixture_count},
             "reports" => reports
           } = report

    live_bytes = report |> :json.encode() |> IO.iodata_to_binary() |> Kernel.<>("\n")

    checked_in_bytes = File.read!("study_results/validation_reference_fixtures.json")
    checked_in_report = :json.decode(checked_in_bytes)

    assert checked_in_bytes == live_bytes
    assert checked_in_report == report

    stale_checked_in_report =
      checked_in_report
      |> Map.update!("fixture_count", &(&1 - 1))

    refute stale_checked_in_report == report

    assert Enum.map(reports, & &1["fixture_id"]) ==
             Validation.reference_fixtures()
             |> Map.keys()
             |> Enum.sort()

    assert {:ok, %{"schema_contract" => "validation_reference_fixture_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(report)

    invalid_fixture_count = Map.put(report, "fixture_count", 99)

    assert {:error, fixture_count_report} =
             OrbitalDynamics.Schema.validate_artifact(invalid_fixture_count)

    assert Enum.any?(
             fixture_count_report["errors"],
             &(&1["path"] == "$.fixture_count")
           )

    inconsistent_status_report =
      report
      |> put_in(["reports", Access.at(0), "status"], "fail")
      |> Map.put("status", "pass")

    assert {:error, inconsistent_status_errors} =
             OrbitalDynamics.Schema.validate_artifact(inconsistent_status_report)

    assert Enum.any?(
             inconsistent_status_errors["errors"],
             &(&1["path"] == "$.status" and
                 &1["message"] == "must equal nested report statuses")
           )

    invalid_negative_fixture_count = Map.put(report, "fixture_count", -1)

    assert {:error, negative_fixture_count_report} =
             OrbitalDynamics.Schema.validate_artifact(invalid_negative_fixture_count)

    assert Enum.any?(
             negative_fixture_count_report["errors"],
             &(&1["path"] == "$.fixture_count")
           )

    stale_status_counts = put_in(report, ["status_counts", "pass"], 123)

    assert {:error, stale_status_counts_report} =
             OrbitalDynamics.Schema.validate_artifact(stale_status_counts)

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.status_counts" and
                 &1["message"] == "must equal nested report status counts")
           )
  end
end
