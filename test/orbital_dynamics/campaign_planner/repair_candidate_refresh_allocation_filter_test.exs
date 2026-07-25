Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRefreshAllocationFilterTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair excludes supplied candidate refresh contacts unusable by allocation report" do
    deferred_candidate =
      "dl_deferred"
      |> refreshed_downlink(520.0, 580.0)
      |> Map.put("score", 100.0)
      |> put_in(["score_terms", "contact_value"], 100.0)

    blocked_candidate =
      "dl_blocked"
      |> refreshed_downlink(620.0, 680.0)
      |> Map.put("score", 90.0)
      |> put_in(["score_terms", "contact_value"], 90.0)

    policy_blocked_candidate =
      "dl_policy_blocked"
      |> refreshed_downlink(720.0, 780.0)
      |> Map.put("score", 80.0)
      |> put_in(["score_terms", "contact_value"], 80.0)

    allocated_candidate = refreshed_downlink("dl_refreshed", 500.0, 560.0)

    allocation_report =
      contact_allocation_report()
      |> Map.merge(%{
        "input_contact_count" => 4,
        "allocated_contact_count" => 2,
        "effective_allocated_contact_count" => 1,
        "effective_policy_blocked_contact_count" => 1,
        "deferred_contact_count" => 1,
        "blocked_contact_count" => 1,
        "effective_allocation_status_counts" => %{
          "allocated" => 1,
          "blocked" => 1,
          "deferred" => 1,
          "policy_blocked" => 1
        }
      })
      |> update_in(["rows"], fn rows ->
        rows ++
          [
            %{
              "id" => "contact_allocation:dl_blocked",
              "contact_id" => "dl_blocked",
              "allocation_status" => "blocked",
              "effective_allocation_status" => "blocked",
              "allocation_reason" => "ground_station_unavailable",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 620.0,
              "ends_at_s" => 680.0,
              "selected" => false
            },
            %{
              "id" => "contact_allocation:dl_policy_blocked",
              "contact_id" => "dl_policy_blocked",
              "allocation_status" => "allocated",
              "effective_allocation_status" => "policy_blocked",
              "allocation_reason" => "available",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 720.0,
              "ends_at_s" => 780.0,
              "selected" => true,
              "policy_decision" => %{
                "schema_contract" => "policy_decision.v1",
                "classification" => "blocked_by_policy",
                "policy_bundle_id" => "contact_allocation_policy_v1"
              }
            }
          ]
      end)

    contention_resolution_summary =
      "study_results/contact_contention_resolution_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        candidate_refresh:
          [deferred_candidate, blocked_candidate, policy_blocked_candidate, allocated_candidate]
          |> candidate_refresh_artifact(contact_allocation_report: allocation_report)
          |> Map.put(
            "source_contact_contention_resolution_summary",
            [contention_resolution_summary]
          )
      )

    assert [%{"id" => "dl_refreshed", "repair" => %{"action" => "moved"}}] =
             artifact["activities"]

    assert Enum.map(artifact["source_candidate_activities"], & &1["id"]) == ["dl_refreshed"]

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "deferred_contact_count" => 1,
             "blocked_contact_count" => 1,
             "rows" => allocation_rows
           } = artifact["source_contact_allocation_report"]

    assert %{
             "schema_contract" => "contact_contention_resolution_report.v1",
             "recommendations" => [
               %{
                 "group_id" => "station:equator_prime:contention:1",
                 "selected_contact_id" => "dl_refreshed",
                 "deferred_contact_ids" => ["dl_deferred"],
                 "review_status" => "operator_review_required"
               }
             ]
           } = artifact["source_contact_contention_resolution_report"]

    assert artifact["source_contact_contention_resolution_summary"] ==
             contention_resolution_summary

    assert %{
             "schema_contract" => "contact_contention_report.v1",
             "conflict_groups" => [
               %{
                 "id" => "station:equator_prime:contention:1",
                 "contact_ids" => ["dl_refreshed", "dl_deferred"],
                 "required_operator_action" => "review_contact_contention"
               }
             ]
           } = artifact["source_contact_contention_report"]

    assert %{
             "contact_id" => "dl_deferred",
             "allocation_status" => "deferred",
             "effective_allocation_status" => "deferred"
           } = Enum.find(allocation_rows, &(&1["contact_id"] == "dl_deferred"))

    assert %{
             "contact_id" => "dl_blocked",
             "allocation_status" => "blocked",
             "effective_allocation_status" => "blocked"
           } = Enum.find(allocation_rows, &(&1["contact_id"] == "dl_blocked"))

    assert %{
             "contact_id" => "dl_policy_blocked",
             "allocation_status" => "allocated",
             "effective_allocation_status" => "policy_blocked"
           } = Enum.find(allocation_rows, &(&1["contact_id"] == "dl_policy_blocked"))

    assert artifact["score_terms"]["contact_allocation_pressure_penalty"] == -3.0

    assert "contact_allocation_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert [
             %{
               "term_key" => "contact_allocation_pressure_penalty",
               "value" => -3.0,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "contact_allocation_pressure_penalty")
             )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_allocation_review" and
                 &1["source"] == "campaign_repair.source_contact_allocation_report.rows" and
                 &1["contact_id"] == "dl_deferred" and
                 &1["allocation_status"] == "deferred")
           )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_allocation_review" and
                 &1["source"] == "campaign_repair.source_contact_allocation_report.rows" and
                 &1["contact_id"] == "dl_blocked" and
                 &1["allocation_status"] == "blocked")
           )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_allocation_review" and
                 &1["source"] == "campaign_repair.source_contact_allocation_report.rows" and
                 &1["contact_id"] == "dl_policy_blocked" and
                 &1["effective_allocation_status"] == "policy_blocked")
           )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_contention_review" and
                 &1["source"] ==
                   "campaign_repair.source_contact_contention_report.conflict_groups" and
                 &1["subject_id"] == "station:equator_prime:contention:1" and
                 &1["contact_ids"] == ["dl_refreshed", "dl_deferred"])
           )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_contention_recommendation" and
                 &1["source"] ==
                   "campaign_repair.source_contact_contention_resolution_report.recommendations" and
                 &1["selected_contact_id"] == "dl_refreshed" and
                 &1["deferred_contact_ids"] == ["dl_deferred"])
           )

    assert %{
             "review_type" => "contact_contention_recommendation",
             "source" =>
               "campaign_repair.source_contact_contention_resolution_summary.summary_recommendations",
             "subject_id" => "station:equator_prime:contention:1",
             "selected_contact_id" => "dl_1",
             "selected_contact_ids" => ["dl_1"],
             "deferred_contact_ids" => ["dl_2"],
             "source_summary_schema_contract" => "contact_contention_resolution_summary.v1",
             "source_contact_contention_resolution_summary" => %{
               "schema_contract" => "contact_contention_resolution_summary.v1",
               "recommendation_group_ids" => [
                 "spacecraft:sat_1:contention:1",
                 "station:equator_prime:contention:1"
               ],
               "selected_contact_ids" => ["dl_1", "dl_3"],
               "deferred_contact_ids" => ["dl_2", "dl_4"],
               "assumptions" => %{
                 "candidate_mutation" => "none",
                 "execution_boundary" =>
                   "artifact_only_no_provider_reservation_or_schedule_mutation",
                 "operator_authority" => "not_granted_by_summary"
               }
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_contact_contention_resolution_summary.summary_recommendations" and
                   &1["subject_id"] == "station:equator_prime:contention:1")
             )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_contact_allocation" and
                 &1["source_review_type"] == "contact_allocation_review" and
                 &1["contact_id"] == "dl_deferred" and
                 &1["allocation_status"] == "deferred")
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_contact_allocation" and
                 &1["source_review_type"] == "contact_allocation_review" and
                 &1["contact_id"] == "dl_blocked" and
                 &1["allocation_status"] == "blocked")
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_contact_allocation" and
                 &1["source_review_type"] == "contact_allocation_review" and
                 &1["contact_id"] == "dl_policy_blocked" and
                 &1["effective_allocation_status"] == "policy_blocked")
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_contact_contention" and
                 &1["source_review_type"] == "contact_contention_review" and
                 &1["subject_id"] == "station:equator_prime:contention:1" and
                 &1["contact_ids"] == ["dl_refreshed", "dl_deferred"] and
                 &1["import_status"] == "review_required_before_import")
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_contact_contention_resolution" and
                 &1["source_review_type"] == "contact_contention_recommendation" and
                 &1["selected_contact_id"] == "dl_refreshed" and
                 &1["deferred_contact_ids"] == ["dl_deferred"] and
                 &1["import_status"] == "review_required_before_import")
           )

    assert %{
             "import_action" => "review_contact_contention_resolution",
             "source_review_type" => "contact_contention_recommendation",
             "selected_contact_id" => "dl_1",
             "selected_contact_ids" => ["dl_1"],
             "deferred_contact_ids" => ["dl_2"],
             "has_cadence_import" => false,
             "source_review_row" => %{
               "source" =>
                 "campaign_repair.source_contact_contention_resolution_summary.summary_recommendations",
               "source_contact_contention_resolution_summary" => %{
                 "schema_contract" => "contact_contention_resolution_summary.v1"
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(get_in(&1, ["source_review_row", "source"]) ==
                   "campaign_repair.source_contact_contention_resolution_summary.summary_recommendations" and
                   &1["subject_id"] == "station:equator_prime:contention:1")
             )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair replacement ranking internalizes exact reduced-capacity allocation evidence" do
    reduced_candidate =
      "dl_reduced"
      |> refreshed_downlink(500.0, 560.0)
      |> Map.put("score", 10.0)
      |> put_in(["score_terms", "contact_value"], 10.0)

    nominal_candidate =
      "dl_nominal"
      |> refreshed_downlink(570.0, 630.0)
      |> Map.put("score", 9.8)
      |> put_in(["score_terms", "contact_value"], 9.8)

    allocation_report =
      OrbitalDynamics.contact_allocation_report(
        [reduced_candidate, nominal_candidate],
        [
          %{
            id: "equator_reduced_capacity",
            ground_station_id: "equator_prime",
            status: "available",
            capacity_fraction: 0.5,
            starts_at_s: 490.0,
            ends_at_s: 565.0
          }
        ]
      )

    plan = %{
      "activities" => [downlink("dl_1", 100.0, 160.0)],
      "candidate_activities" => []
    }

    candidate_refresh =
      [reduced_candidate, nominal_candidate]
      |> candidate_refresh_artifact(contact_allocation_report: allocation_report)

    common_opts = [
      realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
      current_epoch_s: 165.0,
      candidate_refresh: candidate_refresh
    ]

    nominal_artifact =
      repair(plan, Keyword.put(common_opts, :scoring_policy, %{"risk_weight" => "1.0"}))

    pressured_artifact =
      repair(plan, Keyword.put(common_opts, :scoring_policy, %{"risk_weight" => "0.5"}))

    deduplicated_artifact =
      repair(
        plan,
        common_opts
        |> Keyword.put(:scoring_policy, %{"risk_weight" => "0.5"})
        |> Keyword.put(:ground_network, [
          %{
            id: "equator_reduced_capacity",
            ground_station_id: "equator_prime",
            status: "available",
            capacity_fraction: 0.5,
            starts_at_s: 490.0,
            ends_at_s: 565.0
          }
        ])
      )

    assert [%{"id" => "dl_nominal", "repair" => %{"action" => "moved"}}] =
             nominal_artifact["activities"]

    assert %{
             "selected_candidate_id" => "dl_nominal",
             "rows" => [
               %{
                 "candidate_id" => "dl_nominal",
                 "station_calendar_pressure_penalty" => nominal_station_penalty,
                 "selected" => true
               } = nominal_ranking_row,
               %{
                 "candidate_id" => "dl_reduced",
                 "station_calendar_pressure_penalty" => -1.0,
                 "station_calendar_pressure_sources" => [
                   "campaign_repair.source_contact_allocation_report.rows"
                 ],
                 "selected" => false
               }
             ]
           } =
             get_in(nominal_artifact, [
               "activities",
               Access.at(0),
               "repair",
               "replacement_ranking"
             ])

    assert nominal_station_penalty == 0.0
    refute Map.has_key?(nominal_ranking_row, "station_calendar_pressure_sources")

    refute Map.has_key?(
             nominal_artifact["score_terms"],
             "station_calendar_pressure_penalty"
           )

    assert [%{"id" => "dl_reduced", "repair" => %{"action" => "moved"}}] =
             pressured_artifact["activities"]

    assert %{
             "selected_candidate_id" => "dl_reduced",
             "rows" => [
               %{
                 "candidate_id" => "dl_reduced",
                 "station_calendar_pressure_penalty" => -0.5,
                 "station_calendar_pressure_sources" => [
                   "campaign_repair.source_contact_allocation_report.rows"
                 ],
                 "selected" => true
               },
               %{"candidate_id" => "dl_nominal", "selected" => false}
             ]
           } =
             get_in(pressured_artifact, [
               "activities",
               Access.at(0),
               "repair",
               "replacement_ranking"
             ])

    assert pressured_artifact["score_terms"]["station_calendar_pressure_penalty"] == -0.5
    assert pressured_artifact["source_station_calendar_report"] == nil

    assert [%{"id" => "dl_reduced", "repair" => %{"action" => "moved"}}] =
             deduplicated_artifact["activities"]

    assert deduplicated_artifact["score_terms"]["station_calendar_pressure_penalty"] == -0.5

    assert %{
             "selected_candidate_id" => "dl_reduced",
             "rows" => [
               %{
                 "candidate_id" => "dl_reduced",
                 "station_calendar_pressure_penalty" => -0.5,
                 "station_calendar_pressure_sources" => [
                   "campaign_repair.source_contact_allocation_report.rows",
                   "campaign_repair.source_station_calendar_report.affected_contacts"
                 ],
                 "selected" => true
               },
               %{"candidate_id" => "dl_nominal", "selected" => false}
             ]
           } =
             get_in(deduplicated_artifact, [
               "activities",
               Access.at(0),
               "repair",
               "replacement_ranking"
             ])

    assert %{
             "contact_id" => "dl_reduced",
             "effective_allocation_status" => "allocated",
             "station_availability" => "reduced_capacity",
             "capacity_fraction" => 0.5
           } =
             Enum.find(
               pressured_artifact["source_contact_allocation_report"]["rows"],
               &(&1["contact_id"] == "dl_reduced")
             )

    assert Enum.any?(
             pressured_artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_allocation_review" and
                 &1["source"] == "campaign_repair.source_contact_allocation_report.rows" and
                 &1["contact_id"] == "dl_reduced" and
                 &1["station_availability"] == "reduced_capacity")
           )

    assert Enum.any?(
             pressured_artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_contact_allocation" and
                 &1["source_review_type"] == "contact_allocation_review" and
                 &1["contact_id"] == "dl_reduced" and
                 &1["station_availability"] == "reduced_capacity")
           )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(nominal_artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(pressured_artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(deduplicated_artifact)

    wrong_source_artifact =
      put_in(
        nominal_artifact,
        [
          "activities",
          Access.at(0),
          "repair",
          "replacement_ranking",
          "rows",
          Access.at(1),
          "station_calendar_pressure_sources"
        ],
        ["campaign_repair.source_station_calendar_report.affected_contacts"]
      )

    assert {:error, wrong_source_report} = Schema.validate_artifact(wrong_source_artifact)

    assert Enum.any?(
             wrong_source_report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[1].station_calendar_pressure_sources")
           )
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
end
