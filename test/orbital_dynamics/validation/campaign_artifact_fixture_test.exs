defmodule OrbitalDynamics.Validation.CampaignArtifactFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.CampaignArtifactFixtures,
    only: [
      campaign_plan_fixture_observations: 0,
      result_artifact_fixture_observations: 0,
      result_artifact_fixture: 0,
      leo_access_result_artifact_fixture_observations: 0,
      leo_access_result_artifact_fixture: 0,
      leo_access_manifest_result_artifact_fixture_observations: 0,
      leo_access_manifest_result_artifact_fixture: 0,
      ground_track_result_artifact_fixture_observations: 0,
      ground_track_result_artifact_fixture: 0,
      raise_apogee_result_artifact_fixture_observations: 0,
      raise_apogee_result_artifact_fixture: 0,
      candidate_refresh_result_artifact_fixture_observations: 0,
      candidate_refresh_result_artifact_fixture: 0,
      candidate_refresh_orbit_data_result_artifact_fixture_observations: 0,
      candidate_refresh_orbit_data_result_artifact_fixture: 0,
      monte_carlo_result_artifact_fixture_observations: 0,
      monte_carlo_result_artifact_fixture: 0,
      mission_plan_checkout_result_artifact_fixture_observations: 0,
      mission_plan_checkout_result_artifact_fixture: 0,
      campaign_repair_fixture_observations: 0,
      campaign_strategy_fixture_observations: 0,
      read_json!: 1
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated campaign artifact reference fixtures" do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.artifact.campaign_plan.leo_constellation_v1")

    assert fixture["model_id"] == "artifact.campaign_plan.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.campaign_plan.leo_constellation_v1",
               campaign_plan_fixture_observations()
             )

    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))

    assert OrbitalDynamics.validation_artifact_observations("campaign_plan.v1", artifact) ==
             Validation.artifact_observations("campaign_plan.v1", artifact)
  end

  test "verifies curated result artifact reference fixtures" do
    assert {:ok, fixture} =
             Validation.reference_fixture(
               "fixture.artifact.result_artifact.leo_constellation_campaign"
             )

    assert fixture["model_id"] == "artifact.result_artifact.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.result_artifact.leo_constellation_campaign",
               result_artifact_fixture_observations()
             )

    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))

    stale_observations =
      result_artifact_fixture_observations()
      |> Map.put("payload_metrics_section_count", 14)

    assert {:ok, stale_report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.result_artifact.leo_constellation_campaign",
               stale_observations
             )

    assert stale_report["status"] == "fail"

    assert Enum.any?(
             stale_report["checks"],
             &(&1["field"] == "payload_metrics_section_count" and &1["status"] == "fail")
           )

    artifact = result_artifact_fixture()

    assert OrbitalDynamics.validation_artifact_observations("result_artifact.v1", artifact) ==
             Validation.artifact_observations("result_artifact.v1", artifact)

    assert {:ok, %{"schema_contract" => "result_artifact.v1"}} =
             Schema.validate_artifact(artifact,
               schema_contract: "result_artifact.v1"
             )

    stale_payload_top_level_count =
      put_in(artifact, ["payload_metrics", "top_level_key_count"], 14)

    assert {:error, stale_payload_top_level_count_report} =
             Schema.validate_artifact(stale_payload_top_level_count,
               schema_contract: "result_artifact.v1"
             )

    assert Enum.any?(
             stale_payload_top_level_count_report["errors"],
             &(&1["path"] == "$.payload_metrics.top_level_key_count")
           )

    stale_payload_sections =
      update_in(artifact, ["payload_metrics", "sections"], &Map.delete(&1, "errors"))

    assert {:error, stale_payload_sections_report} =
             Schema.validate_artifact(stale_payload_sections,
               schema_contract: "result_artifact.v1"
             )

    assert Enum.any?(
             stale_payload_sections_report["errors"],
             &(&1["path"] == "$.payload_metrics.sections")
           )

    invalid_payload_section_bytes =
      put_in(artifact, ["payload_metrics", "sections", "errors", "bytes"], -1)

    assert {:error, invalid_payload_section_bytes_report} =
             Schema.validate_artifact(invalid_payload_section_bytes,
               schema_contract: "result_artifact.v1"
             )

    assert Enum.any?(
             invalid_payload_section_bytes_report["errors"],
             &(&1["path"] == "$.payload_metrics.sections.errors.bytes")
           )
  end

  test "verifies curated result artifact variant reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.result_artifact.leo_access_demo",
        leo_access_result_artifact_fixture(),
        leo_access_result_artifact_fixture_observations(),
        "access_window_count",
        2
      },
      {
        "fixture.artifact.result_artifact.leo_access_demo_manifest",
        leo_access_manifest_result_artifact_fixture(),
        leo_access_manifest_result_artifact_fixture_observations(),
        "payload_metrics_artifact_body_bytes",
        21_802
      },
      {
        "fixture.artifact.result_artifact.ground_track_crossings",
        ground_track_result_artifact_fixture(),
        ground_track_result_artifact_fixture_observations(),
        "ground_track_crossing_count",
        11
      },
      {
        "fixture.artifact.result_artifact.raise_apogee_search",
        raise_apogee_result_artifact_fixture(),
        raise_apogee_result_artifact_fixture_observations(),
        "maneuver_recommendation_count",
        3
      },
      {
        "fixture.artifact.result_artifact.candidate_refresh_v1",
        candidate_refresh_result_artifact_fixture(),
        candidate_refresh_result_artifact_fixture_observations(),
        "candidate_refresh_refreshed_window_count",
        2
      },
      {
        "fixture.artifact.result_artifact.candidate_refresh_orbit_data_v1",
        candidate_refresh_orbit_data_result_artifact_fixture(),
        candidate_refresh_orbit_data_result_artifact_fixture_observations(),
        "payload_metrics_artifact_body_bytes",
        81_234
      },
      {
        "fixture.artifact.result_artifact.leo_dispersion_monte_carlo",
        monte_carlo_result_artifact_fixture(),
        monte_carlo_result_artifact_fixture_observations(),
        "trajectory_count",
        19
      },
      {
        "fixture.artifact.result_artifact.mission_plan_checkout",
        mission_plan_checkout_result_artifact_fixture(),
        mission_plan_checkout_result_artifact_fixture_observations(),
        "maneuver_recommendation_count",
        0
      }
    ]

    for {fixture_id, artifact, observations, stale_field, stale_value} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == "artifact.result_artifact.v1"
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      stale_observations = Map.put(observations, stale_field, stale_value)

      assert {:ok, stale_verification} =
               Validation.verify_reference_fixture(fixture_id, stale_observations)

      assert stale_verification["status"] == "fail"

      assert Enum.any?(
               stale_verification["checks"],
               &(&1["field"] == stale_field and &1["status"] == "fail")
             )

      assert OrbitalDynamics.validation_artifact_observations("result_artifact.v1", artifact) ==
               Validation.artifact_observations("result_artifact.v1", artifact)
    end
  end

  test "verifies curated repair artifact reference fixtures" do
    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.artifact.campaign_repair.leo_constellation_v2")

    assert fixture["model_id"] == "artifact.campaign_repair.v2"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.campaign_repair.leo_constellation_v2",
               campaign_repair_fixture_observations()
             )

    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))
  end

  test "verifies curated strategy artifact reference fixtures" do
    assert {:ok, fixture} =
             Validation.reference_fixture(
               "fixture.artifact.campaign_strategy.leo_constellation_v3"
             )

    assert fixture["model_id"] == "artifact.campaign_strategy.v3"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    artifact = read_json!("study_results/leo_constellation_campaign_strategy_v3.json")

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.campaign_strategy.leo_constellation_v3",
               campaign_strategy_fixture_observations()
             )

    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))

    observations = campaign_strategy_fixture_observations()

    assert observations["score_term_report_row_count"] == 1674
    assert observations["score_term_report_key_count"] == 62

    assert observations["score_term_report_row_derived_key_counts"][
             "resource_availability_pressure_penalty"
           ] == 27

    assert observations["score_term_report_row_derived_key_counts"][
             "resource_filter_pressure_penalty"
           ] == 27

    assert observations["score_term_report_row_derived_key_counts"][
             "resource_projection_pressure_penalty"
           ] == 27

    assert observations["score_term_report_row_derived_key_counts"][
             "timeline_transition_application_pressure_penalty"
           ] == 27

    assert observations["score_term_report_validation_refresh_pressure_row_count"] == 27

    stale_score_term_key_observations =
      observations
      |> put_in(
        ["score_term_report_row_derived_key_counts", "resource_availability_pressure_penalty"],
        0
      )

    assert {:ok, stale_score_term_key_report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.campaign_strategy.leo_constellation_v3",
               stale_score_term_key_observations
             )

    assert stale_score_term_key_report["status"] == "fail"

    assert Enum.any?(
             stale_score_term_key_report["checks"],
             &(&1["field"] == "score_term_report_row_derived_key_counts" and
                 &1["status"] == "fail")
           )

    stale_validation_refresh_pressure_observations =
      Map.put(observations, "score_term_report_validation_refresh_pressure_row_count", 0)

    assert {:ok, stale_validation_refresh_pressure_report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.campaign_strategy.leo_constellation_v3",
               stale_validation_refresh_pressure_observations
             )

    assert stale_validation_refresh_pressure_report["status"] == "fail"

    assert Enum.any?(
             stale_validation_refresh_pressure_report["checks"],
             &(&1["field"] == "score_term_report_validation_refresh_pressure_row_count" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "campaign_strategy.v3",
             artifact
           ) == Validation.artifact_observations("campaign_strategy.v3", artifact)

    assert {:ok, _valid_report} =
             Schema.validate_artifact(artifact, schema_contract: "campaign_strategy.v3")

    stale_policy_decision_count =
      put_in(
        artifact,
        ["branches", Access.at(2), "policy_decision", "approval_requirement_count"],
        3
      )

    assert {:error, stale_count_report} =
             Schema.validate_artifact(stale_policy_decision_count,
               schema_contract: "campaign_strategy.v3"
             )

    assert Enum.any?(
             stale_count_report["errors"],
             &(&1["path"] == "$.branches[2].policy_decision.approval_requirement_count")
           )

    stale_validation_safety_case_event =
      update_in(artifact, ["branches", Access.at(2), "events"], fn events ->
        [
          %{
            "type" => "validation_safety_case_pressure",
            "validation_safety_case_status" => "blocked",
            "evidence_status" => "blocked",
            "input_contract" => "model_acceptance_report.v1",
            "evidence_ref" => "model_acceptance_report.v1:model.blocked",
            "required_operator_action" => "review_blocked_validation_safety_case",
            "evidence_status_counts" => %{"blocked" => -1}
          }
          | List.wrap(events)
        ]
      end)

    assert {:error, stale_safety_case_event_report} =
             Schema.validate_artifact(stale_validation_safety_case_event,
               schema_contract: "campaign_strategy.v3"
             )

    assert Enum.any?(
             stale_safety_case_event_report["errors"],
             &(&1["path"] == "$.branches[2].events[0].evidence_status_counts.blocked" and
                 &1["message"] == "must be a non-negative integer")
           )

    stale_validation_safety_case_action =
      update_in(artifact, ["branches", Access.at(2), "events"], fn events ->
        [
          %{
            "type" => "validation_safety_case_pressure",
            "validation_safety_case_status" => "blocked",
            "evidence_status" => "blocked",
            "input_contract" => "model_acceptance_report.v1",
            "evidence_ref" => "model_acceptance_report.v1:model.blocked",
            "required_operator_action" => "review_validation_safety_case"
          }
          | List.wrap(events)
        ]
      end)

    assert {:error, stale_safety_case_action_report} =
             Schema.validate_artifact(stale_validation_safety_case_action,
               schema_contract: "campaign_strategy.v3"
             )

    assert Enum.any?(
             stale_safety_case_action_report["errors"],
             &(&1["path"] ==
                 "$.branches[2].events[0].required_operator_action" and
                 &1["message"] ==
                   "must equal \"review_blocked_validation_safety_case\"")
           )

    stale_validation_safety_case_status =
      update_in(artifact, ["branches", Access.at(2), "events"], fn events ->
        [
          %{
            "type" => "validation_safety_case_pressure",
            "validation_safety_case_status" => "accepted_for_use",
            "evidence_status" => "accepted_for_use",
            "input_contract" => "model_acceptance_report.v1",
            "evidence_ref" => "model_acceptance_report.v1:model.accepted",
            "required_operator_action" => "review_validation_safety_case"
          }
          | List.wrap(events)
        ]
      end)

    assert {:error, stale_safety_case_status_report} =
             Schema.validate_artifact(stale_validation_safety_case_status,
               schema_contract: "campaign_strategy.v3"
             )

    assert Enum.any?(
             stale_safety_case_status_report["errors"],
             &(&1["path"] ==
                 "$.branches[2].events[0].validation_safety_case_status" and
                 &1["message"] =~ "must be one of")
           )

    assert Enum.any?(
             stale_safety_case_status_report["errors"],
             &(&1["path"] == "$.branches[2].events[0].evidence_status" and
                 &1["message"] =~ "must be one of")
           )

    missing_validation_safety_case_evidence_status =
      update_in(artifact, ["branches", Access.at(2), "events"], fn events ->
        [
          %{
            "type" => "validation_safety_case_pressure",
            "validation_safety_case_status" => "review_required",
            "input_contract" => "model_acceptance_report.v1",
            "evidence_ref" => "model_acceptance_report.v1:model.review",
            "required_operator_action" => "review_validation_safety_case"
          }
          | List.wrap(events)
        ]
      end)

    assert {:error, missing_safety_case_evidence_status_report} =
             Schema.validate_artifact(missing_validation_safety_case_evidence_status,
               schema_contract: "campaign_strategy.v3"
             )

    assert Enum.any?(
             missing_safety_case_evidence_status_report["errors"],
             &(&1["path"] == "$.branches[2].events[0].evidence_status" and
                 &1["message"] == "is required")
           )
  end
end
