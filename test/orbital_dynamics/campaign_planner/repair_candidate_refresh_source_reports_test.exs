Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRefreshSourceReportsTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair can use candidate_refresh.v1 candidates instead of stale prior candidates" do
    refreshed_candidate = refreshed_downlink("dl_refreshed", 500.0, 560.0)
    source_reports = passive_candidate_refresh_source_reports()

    source_link_capacity_report =
      "study_results/link_capacity_report_v1.json"
      |> File.read!()
      |> :json.decode()

    source_station_reservation_report =
      "study_results/station_calendar_report_v1.json"
      |> File.read!()
      |> :json.decode()
      |> OrbitalDynamics.station_reservation_report()

    source_constraint_report =
      "study_results/constraint_report_v1.json"
      |> File.read!()
      |> :json.decode()

    candidate_diff_report =
      candidate_diff_report()
      |> update_in(["invalidated_candidates", Access.at(0)], fn candidate ->
        candidate
        |> Map.put("semantic_change_reasons", ["contact_window_shifted"])
        |> Map.put("candidate_diff_changed_fields", ["starts_at_s", "ends_at_s"])
        |> Map.put("semantic_change_details", [
          %{
            "field" => "starts_at_s",
            "reason" => "contact_window_shifted",
            "prior_value" => 700.0,
            "refreshed_value" => 500.0
          }
        ])
      end)

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        scoring_policy: %{"risk_weight" => "2.5"},
        candidate_refresh:
          [refreshed_candidate]
          |> candidate_refresh_artifact(
            contact_intents: [
              %{
                "schema_contract" => "contact_intent.v1",
                "id" => "contact_intent:dl_refreshed",
                "activity_id" => "dl_refreshed",
                "scenario_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "direction" => "downlink",
                "starts_at_s" => 500.0,
                "ends_at_s" => 560.0
              }
            ],
            resource_summaries: [
              %{
                "schema_contract" => "resource_summary.v1",
                "spacecraft_id" => "leo_1",
                "antenna_available" => true,
                "payload_available" => true
              }
            ],
            candidate_diff_report: candidate_diff_report,
            freshness_report: freshness_report("stale"),
            contact_filter_report: contact_filter_report(),
            contact_allocation_report: contact_allocation_report(),
            resource_filter_report: resource_filter_report(),
            refresh_budget_report: refresh_budget_report()
          )
          |> Map.put(
            "source_operational_readiness_report",
            source_reports["source_operational_readiness_report"]
          )
          |> Map.put("source_link_capacity_report", source_link_capacity_report)
          |> Map.put("source_station_reservation_report", source_station_reservation_report)
          |> Map.put("source_constraint_report", source_constraint_report)
          |> Map.put("source_quality_gate_report", passive_quality_gate_report())
          |> Map.put("operational_feedback", %{
            "station_throughput_factor" => %{"equator_prime" => 0.5}
          })
          |> put_in(["provenance", "operational_feedback"], %{
            "trust_boundary_status" => "declared",
            "trust_boundary" => "candidate_refresh_feedback",
            "input_keys" => ["station_throughput_factor"],
            "source_path" => "operational_feedback"
          })
      )

    assert [%{"id" => "dl_refreshed", "repair" => repair}] = artifact["activities"]
    assert repair["action"] == "moved"
    assert artifact["source_candidate_activities"] == [refreshed_candidate]

    assert %{
             "type" => "candidate_refresh.v1",
             "refresh_id" => "candidate_refresh:test:abc",
             "snapshot_id" => "ops-state-1",
             "operational_feedback_input_keys" => ["station_throughput_factor"],
             "operational_feedback_trust_boundary_status" => "declared",
             "operational_feedback_trust_boundary" => "candidate_refresh_feedback"
           } = artifact["assumptions"]["candidate_source"]

    assert artifact["provenance"]["candidate_source"]["type"] == "candidate_refresh.v1"
    assert artifact["repair_metadata"]["candidate_source"]["candidate_count"] == 1

    assert [%{"activity_id" => "dl_refreshed", "direction" => "downlink"}] =
             artifact["source_contact_intents"]

    assert [%{"spacecraft_id" => "leo_1", "antenna_available" => true}] =
             artifact["source_resource_summaries"]

    assert %{
             "schema_contract" => "candidate_diff_report.v1",
             "new_candidate_count" => 1
           } = artifact["source_candidate_diff_report"]

    assert artifact["score_terms"]["candidate_diff_pressure_penalty"] == -2.5

    assert artifact["score"] == artifact["score_terms"] |> Map.values() |> Enum.sum()

    assert [
             %{
               "term_key" => "candidate_diff_pressure_penalty",
               "value" => -2.5,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "candidate_diff_pressure_penalty")
             )

    assert %{
             "candidate_diff_review_count" => 1
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "candidate_diff_review",
             "source" => "campaign_repair.source_candidate_diff_report.invalidated_candidates",
             "required_operator_action" => "review_candidate_diff",
             "invalidated_candidate_id" => "dl_stale",
             "invalidated_reason" => "not_present_in_refreshed_candidate_set",
             "semantic_change_reasons" => ["contact_window_shifted"],
             "candidate_diff_changed_fields" => ["ends_at_s", "starts_at_s"],
             "candidate_diff_changed_field_count" => 2,
             "source_candidate_diff" => %{
               "id" => "dl_stale",
               "invalidated_reason" => "not_present_in_refreshed_candidate_set",
               "semantic_change_reasons" => ["contact_window_shifted"],
               "candidate_diff_changed_fields" => ["starts_at_s", "ends_at_s"]
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "candidate_diff_review")
             )

    assert %{
             "import_action" => "review_candidate_diff",
             "source_review_type" => "candidate_diff_review",
             "invalidated_candidate_id" => "dl_stale",
             "invalidated_reason" => "not_present_in_refreshed_candidate_set",
             "semantic_change_reasons" => ["contact_window_shifted"],
             "candidate_diff_changed_fields" => ["ends_at_s", "starts_at_s"],
             "candidate_diff_changed_field_count" => 2,
             "refresh_gate" => "candidate_diff",
             "import_status" => "review_required_before_import",
             "source_candidate_diff" => %{
               "id" => "dl_stale",
               "semantic_change_reasons" => ["contact_window_shifted"]
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_candidate_diff")
             )

    assert %{
             "schema_contract" => "freshness_report.v1",
             "status" => "stale"
           } = artifact["source_freshness_report"]

    assert artifact["score_terms"]["refresh_freshness_pressure_penalty"] == -2.5

    assert [
             %{
               "term_key" => "refresh_freshness_pressure_penalty",
               "value" => -2.5,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "refresh_freshness_pressure_penalty")
             )

    assert artifact["source_operational_readiness_report"]["schema_contract"] ==
             "operational_readiness_report.v1"

    assert artifact["source_quality_gate_report"]["schema_contract"] ==
             "quality_gate_report.v1"

    assert %{
             "freshness_review_count" => 1
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "freshness_review",
             "source" => "campaign_repair.source_freshness_report",
             "required_operator_action" => "review_refresh_freshness",
             "freshness_status" => "stale",
             "source_freshness_report" => %{"schema_contract" => "freshness_report.v1"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "freshness_review")
             )

    assert %{
             "import_action" => "review_refresh_freshness",
             "source_review_type" => "freshness_review",
             "freshness_status" => "stale",
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_refresh_freshness")
             )

    assert %{
             "operational_readiness_review_count" => 2,
             "quality_gate_review_count" => 1
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "campaign_repair.source_operational_readiness_report",
             "required_operator_action" => "review_operational_readiness",
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_readiness_report.v1",
               "report_id" => "operational_readiness:planned_activity.v1:passive_source"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "operational_readiness_review")
             )

    assert %{
             "review_type" => "quality_gate_review",
             "source" => "campaign_repair.source_quality_gate_report.rows",
             "required_operator_action" => "review_quality_gate",
             "quality_gate_id" => "operator_review",
             "source_quality_gate_report" => %{
               "schema_contract" => "quality_gate_report.v1",
               "report_id" => "quality_gate:planned_activity.v1:passive_source"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "quality_gate_review")
             )

    assert %{
             "import_action" => "review_operational_readiness",
             "source_review_type" => "operational_readiness_review",
             "source" => "campaign_repair.source_operational_readiness_report",
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_readiness_report.v1"
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_operational_readiness")
             )

    assert %{
             "import_action" => "review_quality_gate",
             "source_review_type" => "quality_gate_review",
             "source" => "campaign_repair.source_quality_gate_report.rows",
             "source_quality_gate_report" => %{"schema_contract" => "quality_gate_report.v1"}
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_quality_gate")
             )

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "suppressed_candidate_count" => 1
           } = artifact["source_contact_filter_report"]

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "allocated_contact_count" => 1,
             "deferred_contact_count" => 1
           } = artifact["source_contact_allocation_report"]

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "source" => "campaign_repair.activities",
             "allocated_contact_count" => 1,
             "rows" => [
               %{
                 "contact_id" => "dl_refreshed",
                 "allocation_status" => "allocated",
                 "allocation_reason" => "available"
               }
             ]
           } = artifact["contact_allocation_report"]

    assert artifact["source_link_capacity_report"] == source_link_capacity_report

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "campaign_repair.source_link_capacity_report.rows",
             "subject_id" => "equator_prime",
             "contact_ids" => ["leo_1_downlink_equator_prime_1"],
             "capacity_adjusted_throughput_mb" => 172.71212086982393,
             "source_link_capacity" => %{
               "station_availability" => "reduced_capacity"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] == "campaign_repair.source_link_capacity_report.rows")
             )

    assert %{
             "import_action" => "review_link_capacity",
             "source_review_type" => "link_capacity_review",
             "source" => "campaign_repair.source_link_capacity_report.rows",
             "ground_station_id" => "equator_prime",
             "contact_ids" => ["leo_1_downlink_equator_prime_1"],
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] == "campaign_repair.source_link_capacity_report.rows")
             )

    assert artifact["source_station_reservation_report"] ==
             source_station_reservation_report

    assert %{
             "review_type" => "station_reservation_review",
             "source" => "campaign_repair.source_station_reservation_report.affected_contacts",
             "contact_id" => "cmd_1",
             "ground_station_id" => "equator_prime",
             "station_reservation_id" => "provider_reservation_42",
             "station_reserved_by" => "cadence_ops",
             "station_reservation_status" => "confirmed",
             "source_station_reservation" => %{
               "contact_id" => "cmd_1",
               "station_reservation_id" => "provider_reservation_42"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_station_reservation_report.affected_contacts")
             )

    assert %{
             "import_action" => "review_station_reservation",
             "source_review_type" => "station_reservation_review",
             "contact_id" => "cmd_1",
             "station_reservation_id" => "provider_reservation_42",
             "import_status" => "review_required_before_import",
             "source_review_row" => %{
               "source" => "campaign_repair.source_station_reservation_report.affected_contacts"
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(get_in(&1, ["source_review_row", "source"]) ==
                   "campaign_repair.source_station_reservation_report.affected_contacts")
             )

    assert artifact["source_constraint_report"] == source_constraint_report

    assert %{
             "review_type" => "constraint_review",
             "source" => "campaign_repair.source_constraint_report.rows",
             "scenario_id" => "dispersion_2",
             "constraint_id" => "minimum_operational_altitude",
             "metric" => "min_altitude_km",
             "operator" => ">=",
             "threshold" => 621.5,
             "value" => 621.19,
             "score" => -0.31,
             "constraint_status" => "fail",
             "source_constraint_row" => %{
               "scenario_id" => "dispersion_2",
               "status" => "fail"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] == "campaign_repair.source_constraint_report.rows" and
                   &1["scenario_id"] == "dispersion_2")
             )

    assert %{
             "import_action" => "review_constraint",
             "source_review_type" => "constraint_review",
             "source" => "campaign_repair.source_constraint_report.rows",
             "scenario_id" => "dispersion_2",
             "constraint_id" => "minimum_operational_altitude",
             "constraint_status" => "fail",
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] == "campaign_repair.source_constraint_report.rows" and
                   &1["scenario_id"] == "dispersion_2")
             )

    assert %{
             "contact_allocation_review_count" => 3
           } = artifact["operator_review_package"]

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_allocation_review" and
                 &1["source"] == "campaign_repair.source_contact_allocation_report.rows" and
                 &1["required_operator_action"] == "review_contact_allocation")
           )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_allocation_review" and
                 &1["source"] == "campaign_repair.contact_allocation_report.rows" and
                 &1["contact_id"] == "dl_refreshed")
           )

    assert %{
             "import_action" => "review_contact_allocation",
             "source_review_type" => "contact_allocation_review",
             "allocation_status" => "deferred",
             "contact_id" => "dl_deferred",
             "import_status" => "review_required_before_import"
           } =
             artifact["cadence_import_manifest"]["rows"]
             |> Enum.find(&(&1["contact_id"] == "dl_deferred"))

    assert artifact["cadence_import_manifest"]["assumptions"]["row_source"] ==
             "operator_review_package.rows"

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => 1
           } = artifact["source_resource_filter_report"]

    assert %{
             "schema_contract" => "refresh_budget_report.v1",
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "dropped_candidate_count" => 1,
             "kept_candidate_ids" => ["dl_refreshed"],
             "dropped_candidate_ids" => ["dl_deferred"]
           } = artifact["source_refresh_budget_report"]

    assert %{
             "refresh_budget_review_count" => 1
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "refresh_budget_review",
             "source" => "campaign_repair.source_refresh_budget_report",
             "required_operator_action" => "review_refresh_budget",
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["dl_deferred"],
             "source_refresh_budget_report" => %{"schema_contract" => "refresh_budget_report.v1"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "refresh_budget_review")
             )

    assert %{
             "import_action" => "review_refresh_budget",
             "source_review_type" => "refresh_budget_review",
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["dl_deferred"],
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_refresh_budget")
             )

    assert %{
             "schema_contract" => "operational_timeline_report.v1",
             "source" => "campaign_repair.activities",
             "activity_count" => 1,
             "row_count" => 1,
             "contact_count" => 1,
             "command_count" => 0,
             "rows" => [
               %{
                 "activity_id" => "dl_refreshed",
                 "activity_type" => "downlink",
                 "approval_status" => "not_evaluated",
                 "ground_station_id" => "equator_prime",
                 "timeline_identity" => %{
                   "activity_id" => "dl_refreshed",
                   "activity_type" => "downlink"
                 }
               }
             ]
           } = artifact["operational_timeline_report"]

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(artifact["operational_timeline_report"])

    assert "candidate refresh freshness policy marked the snapshot, horizon, or state quality stale" in artifact[
             "warnings"
           ]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair omits candidate diff pressure for empty and absent reports" do
    plan = %{"activities" => [], "candidate_activities" => []}

    common_opts = [
      realized_state: %{activities: []},
      current_epoch_s: 165.0,
      scoring_policy: %{"risk_weight" => "1.75"}
    ]

    empty_artifact =
      repair(
        plan,
        Keyword.put(
          common_opts,
          :candidate_refresh,
          candidate_refresh_artifact([], candidate_diff_report: empty_candidate_diff_report())
        )
      )

    absent_artifact =
      repair(
        plan,
        Keyword.put(
          common_opts,
          :candidate_refresh,
          candidate_refresh_artifact([], [])
        )
      )

    assert empty_artifact["source_candidate_diff_report"]["schema_contract"] ==
             "candidate_diff_report.v1"

    refute Map.has_key?(empty_artifact["score_terms"], "candidate_diff_pressure_penalty")

    refute "candidate_diff_pressure_penalty" in empty_artifact["score_term_report"][
             "score_term_keys"
           ]

    assert is_nil(absent_artifact["source_candidate_diff_report"])
    refute Map.has_key?(absent_artifact["score_terms"], "candidate_diff_pressure_penalty")

    refute "candidate_diff_pressure_penalty" in absent_artifact["score_term_report"][
             "score_term_keys"
           ]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(empty_artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(absent_artifact)
  end

  test "repair scores unknown freshness once and omits an absent freshness report" do
    plan = %{
      "activities" => [downlink("dl_1", 100.0, 160.0)],
      "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
    }

    common_opts = [
      realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
      current_epoch_s: 165.0,
      scoring_policy: %{"risk_weight" => "1.75"}
    ]

    unknown_artifact =
      repair(
        plan,
        Keyword.put(
          common_opts,
          :candidate_refresh,
          candidate_refresh_artifact(
            [refreshed_downlink("dl_unknown", 500.0, 560.0)],
            freshness_report: freshness_report("unknown")
          )
        )
      )

    absent_artifact =
      repair(
        plan,
        Keyword.put(
          common_opts,
          :candidate_refresh,
          candidate_refresh_artifact(
            [refreshed_downlink("dl_absent", 500.0, 560.0)],
            []
          )
        )
      )

    assert unknown_artifact["score_terms"]["refresh_freshness_pressure_penalty"] == -1.75
    assert unknown_artifact["source_freshness_report"]["status"] == "unknown"

    assert Enum.any?(
             unknown_artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "freshness_review" and
                 &1["freshness_status"] == "unknown")
           )

    assert Enum.any?(
             unknown_artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_refresh_freshness" and
                 &1["freshness_status"] == "unknown")
           )

    assert [
             %{
               "term_key" => "refresh_freshness_pressure_penalty",
               "value" => -1.75,
               "selected" => true
             }
           ] =
             Enum.filter(
               unknown_artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "refresh_freshness_pressure_penalty")
             )

    assert unknown_artifact["score"] ==
             unknown_artifact["score_terms"] |> Map.values() |> Enum.sum()

    refute Map.has_key?(absent_artifact["score_terms"], "refresh_freshness_pressure_penalty")

    refute "refresh_freshness_pressure_penalty" in absent_artifact["score_term_report"][
             "score_term_keys"
           ]

    assert is_nil(absent_artifact["source_freshness_report"])

    refute Enum.any?(
             absent_artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "freshness_review")
           )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(unknown_artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(absent_artifact)
  end

  test "repair preserves canonical candidate refresh readiness and quality source reports" do
    source_reports = passive_candidate_refresh_source_reports()

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        candidate_refresh:
          [refreshed_downlink("dl_ready", 500.0, 560.0)]
          |> candidate_refresh_artifact(freshness_report: freshness_report("current"))
          |> Map.put(
            "operational_readiness_report",
            source_reports["source_operational_readiness_report"]
          )
          |> Map.put("quality_gate_report", passive_quality_gate_report())
      )

    assert [%{"id" => "dl_ready", "repair" => %{"action" => "moved"}}] =
             artifact["activities"]

    assert artifact["source_operational_readiness_report"]["schema_contract"] ==
             "operational_readiness_report.v1"

    assert artifact["source_quality_gate_report"]["schema_contract"] ==
             "quality_gate_report.v1"

    assert artifact["source_freshness_report"]["status"] == "current"

    refute Map.has_key?(artifact["score_terms"], "refresh_freshness_pressure_penalty")

    refute "refresh_freshness_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    refute Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "freshness_review")
           )

    refute Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_refresh_freshness")
           )

    assert artifact["score_terms"]["operational_readiness_pressure_penalty"] == -2.0

    assert "operational_readiness_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert [
             %{
               "term_key" => "operational_readiness_pressure_penalty",
               "value" => -2.0,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "operational_readiness_pressure_penalty")
             )

    assert artifact["score_terms"]["quality_gate_pressure_penalty"] == -1.0

    assert "quality_gate_pressure_penalty" in artifact["score_term_report"]["score_term_keys"]

    assert [
             %{
               "term_key" => "quality_gate_pressure_penalty",
               "value" => -1.0,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "quality_gate_pressure_penalty")
             )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "campaign_repair.source_operational_readiness_report",
             "source_operational_readiness_report" => %{
               "report_id" => "operational_readiness:planned_activity.v1:passive_source"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "operational_readiness_review")
             )

    assert %{
             "review_type" => "quality_gate_review",
             "source" => "campaign_repair.source_quality_gate_report.rows",
             "source_quality_gate_report" => %{
               "report_id" => "quality_gate:planned_activity.v1:passive_source"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "quality_gate_review")
             )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_operational_readiness" and
                 &1["source"] == "campaign_repair.source_operational_readiness_report")
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_quality_gate" and
                 &1["source"] == "campaign_repair.source_quality_gate_report.rows")
           )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair scores each selected pressured contact intent once" do
    blocked_intent =
      contact_intent("dl_refreshed", %{"approval_status" => "blocked_by_policy"})

    artifact = repair_with_contact_intents([blocked_intent, blocked_intent])

    assert artifact["score_terms"]["contact_intent_pressure_penalty"] == -2.5
    assert artifact["score"] == artifact["score_terms"] |> Map.values() |> Enum.sum()

    assert [
             %{
               "term_key" => "contact_intent_pressure_penalty",
               "value" => -2.5,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "contact_intent_pressure_penalty")
             )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    tampered_score = artifact["score"] + 1.0

    mismatched_score_term =
      artifact
      |> put_in(["score_terms", "contact_intent_pressure_penalty"], -1.5)
      |> Map.put("score", tampered_score)
      |> update_in(["score_term_report", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          row = Map.put(row, "timeline_score", tampered_score)

          if row["term_key"] == "contact_intent_pressure_penalty",
            do: Map.put(row, "value", -1.5),
            else: row
        end)
      end)

    assert {:error, score_term_report} = Schema.validate_artifact(mismatched_score_term)

    assert Enum.any?(
             score_term_report["errors"],
             &(&1["path"] == "$.score_terms.contact_intent_pressure_penalty")
           )
  end

  test "repair keeps unrelated and nonblocking contact intents score-neutral" do
    contact_intents = [
      contact_intent("dl_refreshed", %{"approval_status" => "operator_review_required"}),
      contact_intent("dl_other", %{"approval_status" => "blocked_by_policy"}),
      contact_intent("dl_refreshed", %{
        "activity_type" => "command",
        "direction" => "command",
        "approval_status" => "blocked_by_policy"
      }),
      contact_intent("obs_1", %{"approval_status" => "blocked_by_policy"})
    ]

    artifact =
      repair_with_contact_intents(contact_intents, [
        observe("obs_1", "leo_1", "target_a", 200.0, 260.0, 10.0)
      ])

    refute Map.has_key?(artifact["score_terms"], "contact_intent_pressure_penalty")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair reuses every exact V3 contact-intent gate pressure status" do
    for pressure_fields <- [
          %{"cadence_import_status" => "missing"},
          %{"cadence_import_status" => "invalid"},
          %{
            "invalid_activity_input" => true,
            "invalid_activity_input_reason" => "invalid_activity_id"
          }
        ] do
      artifact =
        repair_with_contact_intents([
          contact_intent("dl_refreshed", pressure_fields)
        ])

      assert artifact["score_terms"]["contact_intent_pressure_penalty"] == -2.5
      assert artifact["score"] == artifact["score_terms"] |> Map.values() |> Enum.sum()
    end
  end

  test "repair rejects malformed contact-intent evidence before scoring" do
    assert_raise ArgumentError, ~r/invalid candidate_refresh.v1 artifact/, fn ->
      repair_with_contact_intents(["not-a-contact-intent"])
    end
  end

  test "repair replacement ranking prefers an unpressured lower-value downlink" do
    high = scored_refreshed_downlink("dl_high", 12.0)
    low = scored_refreshed_downlink("dl_low", 10.0)

    blocked = contact_intent("dl_high", %{"approval_status" => "blocked_by_policy"})
    invalid = contact_intent("dl_high", %{"cadence_import_status" => "invalid"})

    artifact =
      repair_with_ranked_contact_intents(
        [high, low],
        [blocked, invalid, blocked],
        5.0
      )

    assert [%{"id" => "dl_low", "repair" => %{"replacement_ranking" => ranking}}] =
             artifact["activities"]

    high_row = Enum.find(ranking["rows"], &(&1["candidate_id"] == "dl_high"))
    low_row = Enum.find(ranking["rows"], &(&1["candidate_id"] == "dl_low"))

    assert high_row["contact_intent_pressure_penalty"] == -5.0

    assert high_row["contact_intent_pressure_statuses"] == [
             "blocked_by_policy",
             "cadence_import_invalid"
           ]

    high_index = Enum.find_index(ranking["rows"], &(&1["candidate_id"] == "dl_high"))

    mismatched_statuses =
      put_in(
        artifact,
        [
          "activities",
          Access.at(0),
          "repair",
          "replacement_ranking",
          "rows",
          Access.at(high_index),
          "contact_intent_pressure_statuses"
        ],
        ["blocked_by_policy"]
      )

    assert {:error, mismatch_report} = Schema.validate_artifact(mismatched_statuses)

    assert Enum.any?(
             mismatch_report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[#{high_index}].contact_intent_pressure_statuses")
           )

    assert high_row["selected"] == false
    assert low_row["contact_intent_pressure_penalty"] == 0.0
    refute Map.has_key?(low_row, "contact_intent_pressure_statuses")
    assert low_row["selected"] == true
    refute Map.has_key?(artifact["score_terms"], "contact_intent_pressure_penalty")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair replacement ranking preserves zero-weight pressure evidence" do
    high = scored_refreshed_downlink("dl_high", 12.0)
    low = scored_refreshed_downlink("dl_low", 10.0)

    artifact =
      repair_with_ranked_contact_intents(
        [high, low],
        [contact_intent("dl_high", %{"approval_status" => "blocked_by_policy"})],
        0.0
      )

    assert [%{"id" => "dl_high", "repair" => %{"replacement_ranking" => ranking}}] =
             artifact["activities"]

    high_row = Enum.find(ranking["rows"], &(&1["candidate_id"] == "dl_high"))

    assert high_row["contact_intent_pressure_penalty"] == 0.0
    assert high_row["contact_intent_pressure_statuses"] == ["blocked_by_policy"]
    assert artifact["score_terms"]["contact_intent_pressure_penalty"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    legacy_ranking =
      update_in(
        artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows"],
        fn rows ->
          Enum.map(rows, fn row ->
            Map.drop(row, [
              "contact_intent_pressure_penalty",
              "contact_intent_pressure_statuses"
            ])
          end)
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(legacy_ranking)
  end

  test "repair replacement ranking keeps review-only intent evidence neutral" do
    high = scored_refreshed_downlink("dl_high", 12.0)
    low = scored_refreshed_downlink("dl_low", 10.0)

    artifact =
      repair_with_ranked_contact_intents(
        [high, low],
        [
          contact_intent("dl_high", %{
            "approval_status" => "operator_review_required"
          })
        ],
        5.0
      )

    assert [%{"id" => "dl_high", "repair" => %{"replacement_ranking" => ranking}}] =
             artifact["activities"]

    high_row = Enum.find(ranking["rows"], &(&1["candidate_id"] == "dl_high"))

    assert high_row["contact_intent_pressure_penalty"] == 0.0
    refute Map.has_key?(high_row, "contact_intent_pressure_statuses")
    refute Map.has_key?(artifact["score_terms"], "contact_intent_pressure_penalty")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  defp candidate_refresh_artifact(candidates, opts) do
    %{
      "schema_version" => 1,
      "schema_contract" => "candidate_refresh.v1",
      "artifact_type" => "candidate_refresh",
      "generated_at" => "2026-05-14T00:00:00Z",
      "planner" => "OrbitalDynamics.CandidateRefresh.V1",
      "refresh_id" => Keyword.get(opts, :refresh_id, "candidate_refresh:test:abc"),
      "study_id" => "candidate_refresh_test",
      "snapshot_id" => "ops-state-1",
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 1_000.0,
        "output_step_s" => 60.0
      },
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "spacecraft_state_count" => 1
      },
      "refreshed_windows" => %{
        "access_windows" => [],
        "target_visibility_windows" => [],
        "eclipse_intervals" => []
      },
      "candidate_activities" => candidates,
      "contact_intents" => Keyword.get(opts, :contact_intents, []),
      "resource_summaries" => Keyword.get(opts, :resource_summaries, []),
      "contact_filter_report" => Keyword.get(opts, :contact_filter_report),
      "contact_allocation_report" => Keyword.get(opts, :contact_allocation_report),
      "resource_filter_report" => Keyword.get(opts, :resource_filter_report),
      "refresh_budget_report" => Keyword.get(opts, :refresh_budget_report),
      "candidate_diff_report" => Keyword.get(opts, :candidate_diff_report),
      "freshness_report" => Keyword.get(opts, :freshness_report),
      "invalidated_candidates" => [],
      "validation_records" => [],
      "warnings" => [],
      "assumptions" => %{},
      "provenance" => %{},
      "source_window_lineage" =>
        Enum.map(candidates, fn candidate ->
          %{
            "candidate_activity_id" => candidate["id"],
            "source_window_id" => candidate["source_window_id"],
            "source_window_type" => get_in(candidate, ["source_window", "type"]),
            "scenario_id" => candidate["scenario_id"]
          }
        end)
    }
  end

  defp repair_with_contact_intents(contact_intents, additional_activities \\ []) do
    refreshed_candidate = refreshed_downlink("dl_refreshed", 500.0, 560.0)

    repair(
      %{
        "activities" => [downlink("dl_1", 100.0, 160.0)] ++ additional_activities,
        "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
      },
      realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
      current_epoch_s: 165.0,
      scoring_policy: %{"risk_weight" => "2.5"},
      candidate_refresh:
        candidate_refresh_artifact([refreshed_candidate],
          contact_intents: contact_intents
        )
    )
  end

  defp repair_with_ranked_contact_intents(candidates, contact_intents, risk_weight) do
    repair(
      %{
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
      },
      realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
      current_epoch_s: 165.0,
      scoring_policy: %{"risk_weight" => risk_weight},
      candidate_refresh:
        candidate_refresh_artifact(candidates,
          contact_intents: contact_intents
        )
    )
  end

  defp scored_refreshed_downlink(id, score) do
    id
    |> refreshed_downlink(500.0, 560.0)
    |> Map.put("score", score)
    |> put_in(["score_terms", "contact_value"], score)
  end

  defp contact_intent(activity_id, fields) do
    Map.merge(
      %{
        "schema_contract" => "contact_intent.v1",
        "id" => activity_id,
        "activity_id" => activity_id,
        "activity_type" => "downlink",
        "scenario_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "starts_at_s" => 500.0,
        "ends_at_s" => 560.0
      },
      fields
    )
  end

  defp candidate_diff_report do
    %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 1,
      "refreshed_candidate_count" => 1,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 1,
      "invalidated_candidate_count" => 1,
      "retained_candidates" => [],
      "new_candidates" => [
        %{
          "id" => "dl_refreshed",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "starts_at_s" => 500.0,
          "ends_at_s" => 560.0,
          "diff_reason" => "not_present_in_prior_candidate_set"
        }
      ],
      "invalidated_candidates" => [
        %{
          "id" => "dl_stale",
          "invalidated_reason" => "not_present_in_refreshed_candidate_set"
        }
      ]
    }
  end

  defp empty_candidate_diff_report do
    %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 0,
      "refreshed_candidate_count" => 0,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 0,
      "invalidated_candidate_count" => 0,
      "retained_candidates" => [],
      "new_candidates" => [],
      "invalidated_candidates" => []
    }
  end

  defp contact_filter_report do
    %{
      "schema_contract" => "contact_filter_report.v1",
      "model" => "thin_ground_network_availability_filter",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "dl_suppressed_contact",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "starts_at_s" => 400.0,
          "ends_at_s" => 460.0,
          "suppressed_reason" => "ground_station_unavailable"
        }
      ]
    }
  end

  defp contact_allocation_report do
    %{
      "schema_contract" => "contact_allocation_report.v1",
      "model" => "deterministic_station_contact_allocation",
      "source" => "candidate_refresh.candidate_activities",
      "input_contact_count" => 2,
      "allocated_contact_count" => 1,
      "deferred_contact_count" => 1,
      "blocked_contact_count" => 0,
      "effective_allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
      "rows" => [
        %{
          "id" => "contact_allocation:dl_refreshed",
          "contact_id" => "dl_refreshed",
          "allocation_status" => "allocated",
          "effective_allocation_status" => "allocated",
          "allocation_reason" => "selected_by_contention_resolution",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 500.0,
          "ends_at_s" => 560.0,
          "selected" => true,
          "contention_group_id" => "station:equator_prime:contention:1",
          "deferred_contact_ids" => ["dl_deferred"]
        },
        %{
          "id" => "contact_allocation:dl_deferred",
          "contact_id" => "dl_deferred",
          "allocation_status" => "deferred",
          "effective_allocation_status" => "deferred",
          "allocation_reason" => "same_station_contention",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 520.0,
          "ends_at_s" => 580.0,
          "selected" => false,
          "contention_group_id" => "station:equator_prime:contention:1",
          "selected_contact_id" => "dl_refreshed"
        }
      ],
      "contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "model" => "thin_ground_network_availability_filter",
        "input_candidate_count" => 2,
        "kept_candidate_count" => 2,
        "suppressed_candidate_count" => 0,
        "suppressed_candidates" => []
      },
      "contact_contention_report" => %{
        "schema_contract" => "contact_contention_report.v1",
        "model" => "single_station_interval_overlap",
        "input_contact_count" => 2,
        "conflicted_contact_count" => 2,
        "conflict_group_count" => 1,
        "conflict_groups" => [
          %{
            "id" => "station:equator_prime:contention:1",
            "ground_station_id" => "equator_prime",
            "contact_count" => 2,
            "starts_at_s" => 500.0,
            "ends_at_s" => 580.0,
            "direction" => "downlink",
            "required_operator_action" => "review_contact_contention",
            "approval_status" => "operator_review_required",
            "contact_ids" => ["dl_refreshed", "dl_deferred"],
            "source_window_ids" => [],
            "scenario_ids" => ["leo_1"]
          }
        ]
      },
      "contact_contention_resolution_report" => %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "model" => "deterministic_contact_contention_recommendation",
        "policy" => %{
          "selection_rule" => "highest_score_earliest_start",
          "tie_breakers" => ["starts_at_s", "id"],
          "action" => "recommend_preferred_contact_for_operator_review"
        },
        "conflict_group_count" => 1,
        "recommendation_count" => 1,
        "recommendations" => [
          %{
            "group_id" => "station:equator_prime:contention:1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 500.0,
            "ends_at_s" => 580.0,
            "selected_contact_id" => "dl_refreshed",
            "selected_scenario_id" => "leo_1",
            "deferred_contact_ids" => ["dl_deferred"],
            "candidate_count" => 2,
            "selection_reason" => "highest_score_earliest_start",
            "action" => "recommend_preferred_contact_for_operator_review",
            "review_status" => "operator_review_required"
          }
        ]
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation"
      }
    }
  end

  defp resource_filter_report do
    %{
      "schema_contract" => "resource_filter_report.v1",
      "model" => "resource_summary_availability_and_margin_filter",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "obs_suppressed_resource",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 300.0,
          "ends_at_s" => 360.0,
          "suppressed_reason" => "payload_unavailable"
        }
      ]
    }
  end

  defp refresh_budget_report do
    %{
      "schema_contract" => "refresh_budget_report.v1",
      "model" => "deterministic_candidate_limit_after_filters",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "dropped_candidate_count" => 1,
      "max_candidate_activities" => 1,
      "selection_order" => "score_descending_then_start_then_id",
      "kept_candidate_ids" => ["dl_refreshed"],
      "dropped_candidate_ids" => ["dl_deferred"],
      "assumptions" => %{
        "budget_stage" => "after_contact_resource_and_allocation_filters",
        "optimizer_search_performed" => false
      }
    }
  end

  defp freshness_report(status) do
    accepted_snapshot_age_s = if status == "stale", do: 3_600.0, else: 30.0
    accepted_at = if status == "stale", do: "2026-05-13T23:00:00Z", else: "2026-05-13T23:59:30Z"

    stale_reasons =
      if status == "stale",
        do: ["accepted_snapshot_older_than_policy"],
        else: []

    unknown_reasons =
      if status == "unknown",
        do: ["accepted_state_quality_unknown"],
        else: []

    report = %{
      "schema_contract" => "freshness_report.v1",
      "model" => "accepted_snapshot_horizon_and_quality_freshness",
      "generated_at" => "2026-05-14T00:00:00Z",
      "accepted_at" => accepted_at,
      "current_epoch_s" => 165.0,
      "horizon_starts_at_s" => 165.0,
      "accepted_snapshot_age_s" => accepted_snapshot_age_s,
      "horizon_start_offset_s" => 0.0,
      "max_snapshot_age_s" => 60.0,
      "max_horizon_start_offset_s" => 1.0,
      "status" => status,
      "stale_reasons" => stale_reasons,
      "unknown_reasons" => unknown_reasons
    }

    if status == "unknown",
      do: report,
      else: Map.put(report, "accepted_state_quality_level", "accepted")
  end

  defp passive_candidate_refresh_source_reports do
    %{
      "source_candidate_diff_report" => %{
        "schema_contract" => "candidate_diff_report.v1",
        "retained_candidates" => [],
        "new_candidates" => [],
        "invalidated_candidates" => []
      },
      "source_candidate_rejection_report" => %{
        "schema_contract" => "candidate_rejection_report.v1",
        "rows" => []
      },
      "source_schema_validation_report" => %{
        "schema_contract" => "schema_validation_report.v1",
        "validation_mode" => "artifact",
        "validated_contract" => "candidate_refresh.v1",
        "status" => "pass",
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "errors" => [],
        "warnings" => [],
        "remediation" => []
      },
      "source_freshness_report" => %{
        "schema_contract" => "freshness_report.v1",
        "status" => "fresh",
        "stale_reasons" => [],
        "unknown_reasons" => []
      },
      "source_refresh_budget_report" => %{
        "schema_contract" => "refresh_budget_report.v1",
        "input_candidate_count" => 1,
        "kept_candidate_count" => 1,
        "dropped_candidate_count" => 0
      },
      "source_operational_readiness_report" => passive_readiness_report(),
      "source_provider_counteroffer_report" => %{
        "schema_contract" => "provider_counteroffer_report.v1",
        "source" => "station_calendar_report.affected_contacts",
        "source_artifact_type" => "station_calendar_report.v1",
        "source_artifact_id" => "station_calendar_report",
        "counteroffer_count" => 1,
        "reviewable_count" => 1,
        "counteroffer_status_counts" => %{"proposed" => 1},
        "required_operator_action_counts" => %{"review_provider_counteroffer" => 1},
        "rows" => [
          %{
            "id" => "provider_counteroffer:1:provider_offer_1",
            "provider_counteroffer_id" => "provider_offer_1",
            "provider_counteroffer_status" => "proposed",
            "reviewable" => true,
            "required_operator_action" => "review_provider_counteroffer"
          }
        ],
        "assumptions" => %{},
        "model_limits" => ["artifact_only"]
      },
      "source_station_calendar_report" => %{
        "schema_contract" => "station_calendar_report.v1",
        "affected_contacts" => [],
        "provider_calendar_contention_groups" => []
      },
      "source_station_reservation_report" => %{
        "schema_contract" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "affected_contacts" => [
          %{
            "contact_id" => "dl_reserved_intruder",
            "station_reservation_match_status" => "overlap",
            "station_calendar_reservation_ids" => ["reservation_partner"],
            "station_calendar_reservation_statuses" => ["confirmed"],
            "station_calendar_reservation_expires_at_s" => [360.0],
            "required_operator_action" => "review_station_reservation_overlap",
            "trust_boundary" => "reservation_report_rows"
          }
        ],
        "provider_calendar_contention_groups" => [],
        "trust_boundary" => "reservation_report"
      },
      "source_station_reservation_hold_import_readiness_summary" => %{
        "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
        "source_artifact_type" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "reservation_hold_count" => 2,
        "import_readiness_status" => "review_required",
        "import_classification" => "review_only",
        "ready_for_import_count" => 0,
        "review_required_before_import_count" => 2,
        "no_import_required_count" => 0,
        "reservation_hold_import_status_counts" => %{
          "review_required_before_import" => 2
        },
        "required_import_action_counts" => %{
          "review_station_provider_contention" => 1,
          "review_station_reservation_overlap" => 1
        },
        "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
        "reservation_hold_ids_by_import_status" => %{
          "review_required_before_import" => ["reservation_expired", "reservation_missing"]
        },
        "reservation_hold_ids_by_required_import_action" => %{
          "review_station_provider_contention" => ["reservation_missing"],
          "review_station_reservation_overlap" => ["reservation_expired"]
        },
        "reservation_hold_contact_ids_by_import_status" => %{
          "review_required_before_import" => ["dl_reserved_intruder"]
        },
        "import_readiness_rows" => [
          %{
            "reservation_review_row_type" => "affected_contact",
            "contact_id" => "dl_reserved_intruder",
            "reservation_ids" => ["reservation_expired"],
            "reservation_statuses" => ["held"],
            "reserved_by" => ["ops_calendar"],
            "station_reservation_hold_import_status" => "review_required_before_import",
            "required_operator_action" => "review_station_reservation_overlap"
          },
          %{
            "reservation_review_row_type" => "provider_calendar_contention_group",
            "reservation_ids" => ["reservation_missing"],
            "reservation_statuses" => ["held"],
            "reserved_by" => ["partner_calendar"],
            "station_reservation_hold_import_status" => "review_required_before_import",
            "required_operator_action" => "review_station_provider_contention"
          }
        ],
        "assumptions" => %{
          "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
          "provider_write" => "not_performed_by_summary",
          "cadence_write" => "not_performed_by_summary",
          "reservation_acceptance" => "not_performed_by_summary"
        }
      },
      "source_contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "suppressed_candidates" => [],
        "invalid_contact_inputs" => []
      },
      "source_contact_allocation_report" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "rows" => []
      },
      "source_contact_contention_report" => %{
        "schema_contract" => "contact_contention_report.v1",
        "conflict_groups" => [],
        "invalid_contact_inputs" => []
      },
      "source_contact_contention_resolution_report" => %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "recommendations" => []
      },
      "source_link_capacity_report" => %{
        "schema_contract" => "link_capacity_report.v1",
        "rows" => []
      },
      "source_resource_projection_report" => %{
        "schema_contract" => "resource_projection_report.v1",
        "projected_resources" => []
      },
      "source_resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "suppressed_candidates" => [],
        "invalid_resource_summary_inputs" => []
      },
      "source_timeline_diff_report" => %{
        "schema_contract" => "timeline_diff_report.v1",
        "rows" => []
      },
      "source_constraint_report" => %{
        "schema_contract" => "constraint_report.v1",
        "rows" => []
      },
      "source_objective_satisfaction_report" => %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "rows" => []
      },
      "source_objective_tradeoff_report" => %{
        "schema_contract" => "objective_tradeoff_report.v1",
        "tradeoffs" => []
      },
      "source_score_term_report" => %{
        "schema_contract" => "score_term_report.v1",
        "rows" => []
      }
    }
  end

  defp passive_quality_gate_report do
    OrbitalDynamics.operational_quality_gate_report(passive_readiness_report())
  end

  defp passive_readiness_report do
    %{
      "schema_contract" => "operational_readiness_report.v1",
      "schema_version" => 1,
      "model" => "artifact_only_operational_readiness_classifier",
      "report_id" => "operational_readiness:planned_activity.v1:passive_source",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "passive_source",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 1,
      "passed_gate_count" => 0,
      "review_gate_count" => 1,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gates" => [
        %{
          "id" => "operator_review",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "operator review required"
        }
      ],
      "evidence" => %{},
      "assumptions" => [
        "classification_uses_declared_operator_review_and_cadence_import_manifest_evidence",
        "cadence_import_manifest_rows_are_adapter_handoff_not_external_import_writes"
      ],
      "model_limits" => [
        "artifact_only",
        "does_not_write_cadence",
        "does_not_approve_operator_actions",
        "does_not_execute_commands",
        "uses_declared_review_and_import_evidence"
      ]
    }
  end
end
