defmodule OrbitalDynamics.Validation.ContactContentionFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.ContactContentionFixtures,
    only: [
      contact_filter_report_fixture_observations: 0,
      contact_filter_report_fixture: 0,
      contact_contention_report_fixture_observations: 0,
      contact_contention_report_fixture: 0,
      contact_contention_cross_station_fixture_observations: 0,
      contact_contention_cross_station_fixture: 0,
      contact_contention_resolution_report_fixture_observations: 0,
      contact_contention_resolution_report_fixture: 0,
      contact_contention_resolution_summary_fixture_observations: 0,
      contact_contention_resolution_summary_fixture: 0,
      read_json!: 1
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated contact filter report reference fixtures" do
    fixture_id = "fixture.artifact.contact_filter_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_filter_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_filter_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_filter_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      contact_filter_report_fixture_observations()
      |> Map.put("suppressed_candidate_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "suppressed_candidate_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      contact_filter_report_fixture_observations()
      |> Map.put("row_derived_suppressed_candidate_count", 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_suppressed_candidate_count" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_filter_report.v1",
             report
           ) == Validation.artifact_observations("contact_filter_report.v1", report)

    assert {:ok, %{"schema_contract" => "contact_filter_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_filter_report.v1"
             )

    stale_suppressed_count = Map.put(report, "suppressed_candidate_count", 1)

    assert {:error, stale_suppressed_count_report} =
             Schema.validate_artifact(stale_suppressed_count,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             stale_suppressed_count_report["errors"],
             &(&1["path"] == "$.suppressed_candidate_count")
           )

    stale_kept_count = Map.put(report, "kept_candidate_count", 2)

    assert {:error, stale_kept_count_report} =
             Schema.validate_artifact(stale_kept_count,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             stale_kept_count_report["errors"],
             &(&1["path"] == "$.kept_candidate_count")
           )

    stale_reservation_match_status_counts =
      put_in(report, ["station_reservation_match_status_counts", "overlap"], 0)

    assert {:error, stale_reservation_match_status_counts_report} =
             Schema.validate_artifact(stale_reservation_match_status_counts,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             stale_reservation_match_status_counts_report["errors"],
             &(&1["path"] == "$.station_reservation_match_status_counts")
           )

    stale_invalid_contact_input_ids =
      Map.put(report, "invalid_contact_input_ids", ["leo_1_downlink_equator_prime_1"])

    assert {:error, stale_invalid_contact_input_ids_report} =
             Schema.validate_artifact(stale_invalid_contact_input_ids,
               schema_contract: "contact_filter_report.v1"
             )

    assert Enum.any?(
             stale_invalid_contact_input_ids_report["errors"],
             &(&1["path"] == "$.invalid_contact_input_ids")
           )
  end

  test "verifies curated contact contention report reference fixtures" do
    fixture_id = "fixture.artifact.contact_contention_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_contention_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_contention_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_contention_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      contact_contention_report_fixture_observations()
      |> Map.put("conflicted_contact_count", 3)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "conflicted_contact_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      contact_contention_report_fixture_observations()
      |> Map.put("row_derived_conflicted_contact_count", 3)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_conflicted_contact_count" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_contention_report.v1",
             report
           ) == Validation.artifact_observations("contact_contention_report.v1", report)

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_contention_report.v1"
             )

    stale_conflict_group_count = Map.put(report, "conflict_group_count", 1)

    assert {:error, stale_conflict_group_count_report} =
             Schema.validate_artifact(stale_conflict_group_count,
               schema_contract: "contact_contention_report.v1"
             )

    assert Enum.any?(
             stale_conflict_group_count_report["errors"],
             &(&1["path"] == "$.conflict_group_count")
           )

    stale_conflicted_contact_count = Map.put(report, "conflicted_contact_count", 3)

    assert {:error, stale_conflicted_contact_count_report} =
             Schema.validate_artifact(stale_conflicted_contact_count,
               schema_contract: "contact_contention_report.v1"
             )

    assert Enum.any?(
             stale_conflicted_contact_count_report["errors"],
             &(&1["path"] == "$.conflicted_contact_count")
           )
  end

  test "verifies cross-station contact contention challenge fixture" do
    fixture_id = "fixture.artifact.contact_contention_report.cross_station_spacecraft"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_contention_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_contention_cross_station_fixture()

    checked_in_report =
      read_json!("study_results/contact_contention_cross_station_spacecraft_v1.json")

    assert checked_in_report == report

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_contention_report.v1"
             )

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_contention_cross_station_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "resource_scope_counts" => %{"spacecraft" => 1},
             "conflict_group_ids_by_resource_scope" => %{
               "spacecraft" => ["spacecraft:sat_1:contention:1"]
             }
           } = contact_contention_cross_station_fixture_observations()

    stale_scope_counts =
      contact_contention_cross_station_fixture_observations()
      |> Map.put("resource_scope_counts", %{"ground_station" => 1})

    assert {:ok, stale_scope_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_scope_counts)

    assert stale_scope_verification["status"] == "fail"

    assert Enum.any?(
             stale_scope_verification["checks"],
             &(&1["field"] == "resource_scope_counts" and &1["status"] == "fail")
           )

    stale_row_count = Map.put(report, "conflict_group_count", 2)

    assert {:error, stale_row_count_report} =
             Schema.validate_artifact(stale_row_count,
               schema_contract: "contact_contention_report.v1"
             )

    assert Enum.any?(
             stale_row_count_report["errors"],
             &(&1["path"] == "$.conflict_group_count")
           )
  end

  test "verifies curated contact contention resolution report reference fixtures" do
    fixture_id = "fixture.artifact.contact_contention_resolution_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_contention_resolution_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_contention_resolution_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               contact_contention_resolution_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      contact_contention_resolution_report_fixture_observations()
      |> Map.put("selected_contact_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "selected_contact_count" and &1["status"] == "fail")
           )

    stale_row_derived_observations =
      contact_contention_resolution_report_fixture_observations()
      |> Map.put("row_derived_recommendation_count", 1)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_recommendation_count" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_contention_resolution_report.v1",
             report
           ) ==
             Validation.artifact_observations("contact_contention_resolution_report.v1", report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_contention_resolution_report.v1"
             )

    stale_recommendation_count = Map.put(report, "recommendation_count", 1)

    assert {:error, stale_recommendation_count_report} =
             Schema.validate_artifact(stale_recommendation_count,
               schema_contract: "contact_contention_resolution_report.v1"
             )

    assert Enum.any?(
             stale_recommendation_count_report["errors"],
             &(&1["path"] == "$.recommendation_count")
           )

    stale_conflict_group_count = Map.put(report, "conflict_group_count", 1)

    assert {:error, stale_conflict_group_count_report} =
             Schema.validate_artifact(stale_conflict_group_count,
               schema_contract: "contact_contention_resolution_report.v1"
             )

    assert Enum.any?(
             stale_conflict_group_count_report["errors"],
             &(&1["path"] == "$.conflict_group_count")
           )
  end

  test "verifies curated contact contention resolution summary reference fixtures" do
    fixture_id = "fixture.artifact.contact_contention_resolution_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.contact_contention_resolution_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = contact_contention_resolution_summary_fixture()
    observations = contact_contention_resolution_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "conflict_group_count" => 2,
             "recommendation_count" => 2,
             "recommendation_group_ids" =>
               "spacecraft:sat_1:contention:1|station:equator_prime:contention:1",
             "review_group_ids" =>
               "spacecraft:sat_1:contention:1|station:equator_prime:contention:1",
             "selected_contact_ids" => "dl_1|dl_3",
             "deferred_contact_ids" => "dl_2|dl_4",
             "review_contact_ids" => "dl_1|dl_2|dl_3|dl_4",
             "review_recommendation_count" => 2,
             "resource_scope_counts" => %{"ground_station" => 1, "spacecraft" => 1},
             "selected_contact_ids_by_resource_scope" => %{
               "ground_station" => ["dl_1"],
               "spacecraft" => ["dl_3"]
             },
             "deferred_contact_ids_by_resource_scope" => %{
               "ground_station" => ["dl_2"],
               "spacecraft" => ["dl_4"]
             },
             "selection_reason_counts" => %{"highest_score_earliest_start" => 2},
             "action_counts" => %{"recommend_preferred_contact_for_operator_review" => 2},
             "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
             "candidate_mutation" => "none",
             "operator_authority" => "not_granted_by_summary",
             "no_provider_reservation" => true,
             "no_candidate_suppression" => true,
             "no_schedule_mutation" => true
           } = observations

    assert OrbitalDynamics.validation_artifact_observations(
             "contact_contention_resolution_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "contact_contention_resolution_summary.v1",
               report
             )

    stale_count_observations = Map.put(observations, "recommendation_count", 1)

    assert {:ok, stale_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_count_observations)

    assert stale_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_count_verification["checks"],
             &(&1["field"] == "recommendation_count" and &1["status"] == "fail")
           )

    stale_routing_observations =
      put_in(observations, ["selected_contact_ids_by_resource_scope", "spacecraft"], [])

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "selected_contact_ids_by_resource_scope" and
                 &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "provider_reservation_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_summary.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "contact_contention_resolution_summary.v1"
             )
  end
end
