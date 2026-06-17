defmodule OrbitalDynamics.CampaignPlanner.CampaignContactContentionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CampaignPlanner, Epoch, ResultSet, Schema}

  test "campaign reports same-station contact contention without suppressing candidates" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          access_result(:leo_1, :equator_prime, 100.0, 200.0),
          access_result(:leo_2, :equator_prime, 150.0, 240.0),
          access_result(:leo_3, :deep_space_net, 150.0, 240.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "constraints" => %{},
          "scoring_policy" => %{"contact_value_weight" => 1.0}
        }
      )

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(artifact)

    assert %{
             "schema_contract" => "contact_contention_report.v1",
             "model" => "single_station_interval_overlap",
             "input_contact_count" => 3,
             "conflicted_contact_count" => 2,
             "conflict_group_count" => 1,
             "conflict_groups" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "contact_count" => 2,
                 "direction" => "downlink",
                 "required_operator_action" => "review_contact_contention",
                 "approval_status" => "operator_review_required",
                 "operator_action_reason" => "same_station_overlapping_contact_windows",
                 "contact_ids" => contact_ids,
                 "source_window_ids" => source_window_ids,
                 "scenario_ids" => ["leo_1", "leo_2"]
               }
             ]
           } = artifact["contact_contention_report"]

    assert Enum.sort(contact_ids) == [
             "leo_1_downlink_equator_prime_1",
             "leo_2_downlink_equator_prime_1"
           ]

    assert source_window_ids == [
             "window:leo_1:ground_station_access:equator_prime:1",
             "window:leo_2:ground_station_access:equator_prime:1"
           ]

    assert %{
             "schema_contract" => "contact_contention_resolution_report.v1",
             "model" => "deterministic_contact_contention_recommendation",
             "conflict_group_count" => 1,
             "recommendation_count" => 1,
             "recommendations" => [
               %{
                 "selected_contact_id" => "leo_1_downlink_equator_prime_1",
                 "deferred_contact_ids" => ["leo_2_downlink_equator_prime_1"],
                 "selection_reason" => "highest_score_earliest_start",
                 "action" => "recommend_preferred_contact_for_operator_review",
                 "review_status" => "operator_review_required"
               }
             ]
           } = artifact["contact_contention_resolution_report"]

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "model" => "deterministic_station_contact_allocation",
             "input_contact_count" => 3,
             "allocated_contact_count" => 2,
             "deferred_contact_count" => 1,
             "blocked_contact_count" => 0,
             "rows" => allocation_rows
           } = artifact["contact_allocation_report"]

    assert %{
             "contact_id" => "leo_2_downlink_equator_prime_1",
             "allocation_status" => "deferred",
             "allocation_reason" => "same_station_contention",
             "selected_contact_id" => "leo_1_downlink_equator_prime_1",
             "review_status" => "operator_review_required"
           } = Enum.find(allocation_rows, &(&1["contact_id"] == "leo_2_downlink_equator_prime_1"))

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(artifact["contact_allocation_report"])

    assert %{
             "schema_contract" => "operator_review_package.v1",
             "source_artifact_type" => "campaign_plan.v1",
             "contention_recommendation_count" => 1,
             "contention_review_count" => 1,
             "contact_allocation_review_count" => 3,
             "link_capacity_review_count" => 2,
             "score_term_review_count" => 21,
             "objective_tradeoff_review_count" => 3,
             "operational_timeline_count" => 1,
             "timeline_activity_precondition_review_count" => 1,
             "realized_feedback_count" => 0,
             "warning_count" => 1,
             "review_count" => 34,
             "rows" => review_rows
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "contact_contention_recommendation",
             "selected_contact_id" => "leo_1_downlink_equator_prime_1",
             "deferred_contact_ids" => ["leo_2_downlink_equator_prime_1"],
             "required_operator_action" => "recommend_preferred_contact_for_operator_review"
           } = Enum.find(review_rows, &(&1["review_type"] == "contact_contention_recommendation"))

    assert %{
             "review_type" => "contact_contention_review",
             "source" => "campaign_plan.contact_contention_report.conflict_groups",
             "ground_station_id" => "equator_prime",
             "contact_count" => 2,
             "contact_ids" => [
               "leo_1_downlink_equator_prime_1",
               "leo_2_downlink_equator_prime_1"
             ],
             "required_operator_action" => "review_contact_contention",
             "source_contention_group" => %{
               "id" => "station:equator_prime:contention:1"
             }
           } = Enum.find(review_rows, &(&1["review_type"] == "contact_contention_review"))

    assert %{
             "review_type" => "operational_timeline_review",
             "activity_id" => "leo_1_downlink_equator_prime_1",
             "required_operator_action" => "review_activity_approval",
             "approval_status" => "operator_review_required",
             "source_approval_status" => "not_evaluated"
           } = Enum.find(review_rows, &(&1["review_type"] == "operational_timeline_review"))

    assert %{
             "review_type" => "timeline_activity_precondition_review",
             "source" => "campaign_plan.timeline_activity_precondition_summaries[0].summary",
             "activity_id" => "leo_1_downlink_equator_prime_1",
             "precondition_status" => "clear",
             "required_operator_action" => "record_activity_precondition",
             "approval_status" => "not_required"
           } =
             Enum.find(
               review_rows,
               &(&1["review_type"] == "timeline_activity_precondition_review")
             )

    assert %{
             "review_type" => "contact_allocation_review",
             "contact_id" => "leo_2_downlink_equator_prime_1",
             "allocation_status" => "deferred",
             "required_operator_action" => "review_contact_allocation"
           } = Enum.find(review_rows, &(&1["contact_id"] == "leo_2_downlink_equator_prime_1"))

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "campaign_plan.link_capacity_report.rows",
             "ground_station_id" => "equator_prime",
             "selected_contact_ids" => ["leo_1_downlink_equator_prime_1"],
             "selected_capacity_adjusted_throughput_mb" => 100.0,
             "required_operator_action" => "review_link_capacity_summary"
           } =
             Enum.find(
               review_rows,
               &(&1["review_type"] == "link_capacity_review" and
                   &1["ground_station_id"] == "equator_prime")
             )

    assert %{
             "review_type" => "score_term_review",
             "source" => "campaign_plan.score_term_report.rows",
             "scenario_id" => "leo_1",
             "term_key" => "activity_score",
             "selected" => true,
             "source_score_term" => %{"term_key" => "activity_score"}
           } =
             Enum.find(
               review_rows,
               &(&1["review_type"] == "score_term_review" and
                   &1["scenario_id"] == "leo_1" and
                   &1["term_key"] == "activity_score")
             )

    assert %{
             "review_type" => "objective_tradeoff_review",
             "source" => "campaign_plan.objective_tradeoff_report.tradeoffs",
             "scenario_id" => "leo_1",
             "score_delta_from_selected" => contention_review_score_delta,
             "source_objective_tradeoff" => %{"scenario_id" => "leo_1"}
           } =
             Enum.find(
               review_rows,
               &(&1["review_type"] == "objective_tradeoff_review" and
                   &1["scenario_id"] == "leo_1")
             )

    assert contention_review_score_delta == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(artifact["operator_review_package"])

    assert %{
             "schema_contract" => "cadence_import_manifest.v1",
             "source_artifact_type" => "campaign_plan.v1",
             "source_artifact_id" => plan_id,
             "row_count" => 36,
             "ready_count" => 4,
             "review_required_count" => 32,
             "blocked_count" => 0,
             "missing_import_count" => 0,
             "rows" => import_rows
           } = artifact["cadence_import_manifest"]

    assert plan_id == artifact["plan_id"]

    assert %{
             "import_action" => "import_proposed_contact",
             "import_status" => "ready_for_import",
             "import_side" => "source",
             "source_review_type" => "proposed_contact",
             "cadence_import_status" => "present",
             "cadence_import_contract" => "proposed_contact.v1"
           } = hd(import_rows)

    import_starts = Enum.map(import_rows, & &1["starts_at_s"])

    assert Enum.take(import_starts, 3) == [100.0, 150.0, 150.0]

    assert Enum.reject(import_starts, &is_nil/1) == [
             100.0,
             150.0,
             150.0,
             100.0,
             100.0,
             100.0,
             150.0,
             100.0,
             150.0
           ]

    assert Enum.count(import_starts, &is_nil/1) == 27

    assert %{
             "import_action" => "review_contact_contention_resolution",
             "import_status" => "review_required_before_import",
             "source_review_type" => "contact_contention_recommendation",
             "selected_contact_id" => "leo_1_downlink_equator_prime_1",
             "deferred_contact_ids" => ["leo_2_downlink_equator_prime_1"],
             "cadence_import_status" => "not_applicable"
           } =
             Enum.find(
               import_rows,
               &(&1["source_review_type"] == "contact_contention_recommendation")
             )

    assert %{
             "import_action" => "review_contact_contention",
             "import_status" => "review_required_before_import",
             "source_review_type" => "contact_contention_review",
             "ground_station_id" => "equator_prime",
             "contact_ids" => [
               "leo_1_downlink_equator_prime_1",
               "leo_2_downlink_equator_prime_1"
             ],
             "source_contention_group" => %{
               "id" => "station:equator_prime:contention:1"
             }
           } =
             Enum.find(import_rows, &(&1["source_review_type"] == "contact_contention_review"))

    assert %{
             "import_action" => "review_operational_timeline",
             "import_status" => "review_required_before_import",
             "source_review_type" => "operational_timeline_review",
             "activity_id" => "leo_1_downlink_equator_prime_1",
             "cadence_import_status" => "present"
           } =
             Enum.find(import_rows, &(&1["source_review_type"] == "operational_timeline_review"))

    assert %{
             "import_action" => "review_timeline_precondition",
             "import_status" => "ready_for_import",
             "source_review_type" => "timeline_activity_precondition_review",
             "activity_id" => "leo_1_downlink_equator_prime_1",
             "precondition_status" => "clear"
           } =
             Enum.find(
               import_rows,
               &(&1["source_review_type"] == "timeline_activity_precondition_review")
             )

    assert %{
             "import_action" => "review_contact_allocation",
             "import_status" => "review_required_before_import",
             "source_review_type" => "contact_allocation_review",
             "contact_id" => "leo_2_downlink_equator_prime_1",
             "allocation_status" => "deferred",
             "cadence_import_status" => "present"
           } = Enum.find(import_rows, &(&1["contact_id"] == "leo_2_downlink_equator_prime_1"))

    assert %{
             "import_action" => "review_link_capacity",
             "import_status" => "review_required_before_import",
             "source_review_type" => "link_capacity_review",
             "ground_station_id" => "equator_prime",
             "selected_contact_ids" => ["leo_1_downlink_equator_prime_1"],
             "selected_capacity_adjusted_throughput_mb" => 100.0,
             "source_link_capacity" => %{"ground_station_id" => "equator_prime"}
           } =
             Enum.find(
               import_rows,
               &(&1["source_review_type"] == "link_capacity_review" and
                   &1["ground_station_id"] == "equator_prime")
             )

    assert %{
             "import_action" => "review_score_term",
             "source_review_type" => "score_term_review",
             "scenario_id" => "leo_1",
             "term_key" => "activity_score",
             "source_score_term" => %{"term_key" => "activity_score"}
           } =
             Enum.find(
               import_rows,
               &(&1["source_review_type"] == "score_term_review" and
                   &1["scenario_id"] == "leo_1" and
                   &1["term_key"] == "activity_score")
             )

    assert %{
             "import_action" => "review_objective_tradeoff",
             "source_review_type" => "objective_tradeoff_review",
             "scenario_id" => "leo_1",
             "score_delta_from_selected" => contention_import_score_delta,
             "source_objective_tradeoff" => %{"scenario_id" => "leo_1"}
           } =
             Enum.find(
               import_rows,
               &(&1["source_review_type"] == "objective_tradeoff_review" and
                   &1["scenario_id"] == "leo_1")
             )

    assert contention_import_score_delta == 0.0

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(artifact["cadence_import_manifest"])

    assert %{
             "schema_contract" => "operational_readiness_report.v1",
             "source_artifact_type" => "campaign_plan.v1",
             "source_artifact_id" => source_artifact_id,
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "evidence" => readiness_evidence
           } = artifact["operational_readiness_report"]

    assert source_artifact_id == artifact["plan_id"]
    assert readiness_evidence["review_type_counts"]["contact_allocation_review"] == 3
    assert readiness_evidence["import_action_counts"]["review_contact_allocation"] == 3

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(artifact["operational_readiness_report"])

    assert %{
             "schema_contract" => "quality_gate_report.v1",
             "source_artifact_type" => "campaign_plan.v1",
             "source_artifact_id" => ^source_artifact_id,
             "source_readiness_report_id" => source_readiness_report_id,
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "handoff_only" => true,
             "execution_allowed" => false,
             "cadence_write_allowed" => false,
             "operator_authority_granted" => false,
             "review_required_gate_ids" => review_required_gate_ids
           } = artifact["quality_gate_report"]

    assert source_readiness_report_id == artifact["operational_readiness_report"]["report_id"]
    assert "operator_review" in review_required_gate_ids
    assert "cadence_import" in review_required_gate_ids

    assert {:ok, %{"schema_contract" => "quality_gate_report.v1"}} =
             Schema.validate_artifact(artifact["quality_gate_report"])

    assert %{
             "schema_contract" => "link_capacity_report.v1",
             "model" => "fixed_rate_downlink_capacity_summary",
             "contact_count" => 3,
             "selected_contact_count" => 1,
             "estimated_throughput_mb" => 280.0,
             "selected_estimated_throughput_mb" => 100.0,
             "capacity_adjusted_throughput_mb" => 280.0,
             "selected_capacity_adjusted_throughput_mb" => 100.0,
             "rows" => link_rows
           } = artifact["link_capacity_report"]

    assert %{
             "ground_station_id" => "equator_prime",
             "contact_count" => 2,
             "selected_contact_count" => 1,
             "estimated_throughput_mb" => 190.0,
             "selected_estimated_throughput_mb" => 100.0,
             "capacity_adjusted_throughput_mb" => 190.0,
             "selected_capacity_adjusted_throughput_mb" => 100.0,
             "capacity_fraction_min" => 1.0,
             "capacity_fraction_max" => 1.0
           } = Enum.find(link_rows, &(&1["ground_station_id"] == "equator_prime"))

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(artifact["link_capacity_report"])

    conflicted =
      artifact["candidate_activities"]
      |> Enum.filter(&(&1["ground_station_id"] == "equator_prime"))

    assert Enum.all?(conflicted, &(&1["schedule_conflict_status"] == "contention_detected"))
    assert Enum.all?(conflicted, &(length(&1["contention_group_ids"]) == 1))

    assert Enum.any?(artifact["ranked_timelines"], fn timeline ->
             timeline["score_terms"]["contact_value"] > 0.0 and
               timeline["score_terms"]["selected_contact_count"] == 1
           end)

    refute artifact["candidate_activities"]
           |> Enum.find(&(&1["ground_station_id"] == "deep_space_net"))
           |> Map.has_key?("contention_group_ids")

    assert {:ok, %{"schema_contract" => "campaign_plan.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "campaign preserves mission-specific contact priority overrides in contention policy" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          access_result(:leo_1, :equator_prime, 100.0, 200.0),
          access_result(:leo_2, :equator_prime, 150.0, 240.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "constraints" => %{},
          "scoring_policy" => %{"contact_value_weight" => 1.0},
          "contact_contention_resolution_policy" => %{
            "selection_rule" => "highest_priority_highest_score",
            "priority_overrides" => %{
              "leo_1_downlink_equator_prime_1" => 1.0,
              "leo_2_downlink_equator_prime_1" => 10.0
            }
          }
        }
      )

    assert %{
             "policy" => %{
               "selection_rule" => "highest_priority_highest_score",
               "priority_fields" => ["policy_contact_priority" | _],
               "priority_override_count" => 2,
               "priority_override_contact_ids" => [
                 "leo_1_downlink_equator_prime_1",
                 "leo_2_downlink_equator_prime_1"
               ]
             },
             "recommendations" => [
               %{
                 "selected_contact_id" => "leo_2_downlink_equator_prime_1",
                 "selected_priority" => 10.0,
                 "selected_priority_source" => "policy_contact_priority",
                 "deferred_contact_ids" => ["leo_1_downlink_equator_prime_1"],
                 "resolution_priority_override_count" => 2
               }
             ]
           } = artifact["contact_contention_resolution_report"]

    assert %{
             "contact_id" => "leo_1_downlink_equator_prime_1",
             "allocation_status" => "deferred",
             "selected_contact_id" => "leo_2_downlink_equator_prime_1",
             "selected_priority_source" => "policy_contact_priority",
             "resolution_priority_override_count" => 2
           } =
             Enum.find(
               artifact["contact_allocation_report"]["rows"],
               &(&1["contact_id"] == "leo_1_downlink_equator_prime_1")
             )

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} = Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(artifact["contact_contention_resolution_report"])

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(artifact["contact_allocation_report"])
  end

  test "campaign reports same-spacecraft cross-station contention from scenario identity" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          access_result(:leo_1, :equator_prime, 100.0, 220.0),
          access_result(:leo_1, :deep_space_net, 120.0, 240.0),
          access_result(:leo_2, :polar_station, 300.0, 420.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "constraints" => %{},
          "scoring_policy" => %{"contact_value_weight" => 1.0}
        }
      )

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(artifact)

    assert %{
             "schema_contract" => "contact_contention_report.v1",
             "input_contact_count" => 3,
             "conflicted_contact_count" => 2,
             "conflict_group_count" => 1,
             "conflict_groups" => [
               %{
                 "id" => "spacecraft:leo_1:contention:1",
                 "resource_scope" => "spacecraft",
                 "ground_station_id" => "multi_station",
                 "ground_station_ids" => ["deep_space_net", "equator_prime"],
                 "spacecraft_id" => "leo_1",
                 "spacecraft_ids" => ["leo_1"],
                 "scenario_ids" => ["leo_1"],
                 "operator_action_reason" => "same_spacecraft_overlapping_contact_windows",
                 "contact_ids" => [
                   "leo_1_downlink_equator_prime_1",
                   "leo_1_downlink_deep_space_net_1"
                 ]
               }
             ]
           } = artifact["contact_contention_report"]

    assert %{
             "schema_contract" => "contact_contention_resolution_report.v1",
             "recommendations" => [
               %{
                 "group_id" => "spacecraft:leo_1:contention:1",
                 "resource_scope" => "spacecraft",
                 "spacecraft_id" => "leo_1",
                 "selected_contact_id" => "leo_1_downlink_equator_prime_1",
                 "deferred_contact_ids" => ["leo_1_downlink_deep_space_net_1"]
               }
             ]
           } = artifact["contact_contention_resolution_report"]

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "input_contact_count" => 3,
             "allocated_contact_count" => 2,
             "deferred_contact_count" => 1,
             "blocked_contact_count" => 0,
             "rows" => allocation_rows
           } = artifact["contact_allocation_report"]

    assert %{
             "contact_id" => "leo_1_downlink_deep_space_net_1",
             "spacecraft_id" => "leo_1",
             "allocation_status" => "deferred",
             "allocation_reason" => "same_spacecraft_contention",
             "selected_contact_id" => "leo_1_downlink_equator_prime_1",
             "contention_group_id" => "spacecraft:leo_1:contention:1"
           } =
             Enum.find(
               allocation_rows,
               &(&1["contact_id"] == "leo_1_downlink_deep_space_net_1")
             )

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(artifact["contact_contention_report"])

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(artifact["contact_contention_resolution_report"])

    assert {:ok, %{"schema_contract" => "contact_allocation_report.v1"}} =
             Schema.validate_artifact(artifact["contact_allocation_report"])
  end

  defp access_result(scenario_id, ground_station_id, starts_at_s, ends_at_s) do
    %{
      scenario_id: scenario_id,
      event_type: :ground_station_access,
      events: [
        %{
          type: :ground_station_access,
          starts_at: Epoch.new!(starts_at_s, :tdb),
          ends_at: Epoch.new!(ends_at_s, :tdb),
          metadata: %{
            max_elevation_deg: 45.0,
            minimum_elevation_deg: 5.0
          }
        }
      ],
      source: %{ground_station_id: ground_station_id}
    }
  end
end
