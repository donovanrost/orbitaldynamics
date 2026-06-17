Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyContactAllocationSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema}

  test "strategy carries mission-state contact-allocation summaries into branch refresh requests" do
    direct_summary = contact_allocation_summary_fixture("direct")
    canonical_summary = contact_allocation_summary_fixture("canonical")
    wrapped_summary = contact_allocation_summary_fixture("wrapped")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_contact_allocation_summary", direct_summary)
      |> Map.put("contact_allocation_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_contact_allocation_summary" => Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_contact_allocation_summary_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    source_report_input_paths = candidate_source["source_report_input_paths"]

    assert "mission_state.source_contact_allocation_summary" in source_report_input_paths
    assert "mission_state.contact_allocation_summary" in source_report_input_paths

    assert "mission_state.source_result_artifact.source_contact_allocation_summary" in source_report_input_paths

    assert "mission_state.source_contact_allocation_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.contact_allocation_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert "mission_state.source_result_artifact.source_contact_allocation_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_contact_allocation_allocated_contact_count" => 4,
             "source_report_contact_allocation_returned_allocated_contact_count" => 4,
             "source_report_contact_allocation_deferred_contact_count" => 4,
             "source_report_contact_allocation_allocation_status_counts" => %{
               "allocated" => 4,
               "deferred" => 4
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_paths" => replay_source_paths,
             "allocated_contact_count" => 4,
             "returned_allocated_contact_count" => 4,
             "deferred_contact_count" => 4,
             "allocation_status_counts" => %{"allocated" => 4, "deferred" => 4},
             "contact_allocation_summary_schema_contract" => "contact_allocation_summary.v1",
             "branch_local_contact_allocation_pressure" => true,
             "assumptions" => %{
               "contact_allocation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary"
             }
           } = CandidateRefresh.contact_allocation_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.source_contact_allocation_summary[0]",
          "mission_state.source_contact_allocation_summary[1]",
          "mission_state.contact_allocation_summary",
          "mission_state.source_result_artifact.source_contact_allocation_summary"
        ] do
      assert source_path in replay_source_paths
    end
  end

  test "strategy scores contact-allocation summaries from row-local stale aggregate evidence" do
    stale_summary =
      "stale"
      |> contact_allocation_summary_fixture()
      |> Map.update!("rows", fn rows ->
        Enum.map(rows, fn row ->
          row
          |> Map.put("type", "contact")
          |> Map.put("starts_at_s", 640.0)
          |> Map.put("ends_at_s", 700.0)
          |> Map.put("required_downlink_mb", 60.0)
        end)
      end)
      |> Map.update!("review_rows", fn rows ->
        Enum.map(rows, fn row ->
          row
          |> Map.put("type", "contact")
          |> Map.put("starts_at_s", 640.0)
          |> Map.put("ends_at_s", 700.0)
          |> Map.put("required_downlink_mb", 60.0)
        end)
      end)
      |> Map.merge(%{
        "allocated_contact_count" => 2,
        "returned_allocated_contact_count" => 2,
        "deferred_contact_count" => 0,
        "allocation_status_counts" => %{"allocated" => 2},
        "effective_allocation_status_counts" => %{"allocated" => 2},
        "allocation_reason_counts" => %{"selected_by_contention_resolution" => 2},
        "allocated_contact_ids" => ["stale_dl_allocated", "stale_top_level_allocated"],
        "returned_allocated_contact_ids" => [
          "stale_dl_allocated",
          "stale_top_level_allocated"
        ],
        "deferred_contact_ids" => ["stale_top_level_deferred"],
        "review_contact_ids" => ["stale_top_level_deferred"],
        "contact_ids_by_allocation_reason" => %{
          "selected_by_contention_resolution" => [
            "stale_dl_allocated",
            "stale_top_level_allocated"
          ]
        }
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_contact_allocation_summary", stale_summary)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    matching_branches =
      artifact["branches"]
      |> Enum.filter(fn branch ->
        branch
        |> Map.get("events", [])
        |> Enum.any?(
          &(&1["feedback_scope"] == "contact_allocation" and
              &1["contact_id"] == "stale_dl_deferred")
        )
      end)

    assert [pressure_branch] = matching_branches

    assert [pressure_event] =
             pressure_branch["events"]
             |> Enum.filter(
               &(&1["feedback_scope"] == "contact_allocation" and
                   &1["contact_id"] == "stale_dl_deferred")
             )

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "stale_dl_deferred",
             "allocation_status" => "deferred",
             "effective_allocation_status" => "deferred",
             "allocation_reason" => "same_station_contention",
             "feedback_source" => "mission_state.source_contact_allocation_summary",
             "feedback_scope" => "contact_allocation",
             "trust_boundary" => "stale_contact_allocation_summary_fixture"
           } = pressure_event

    candidate_source = get_in(pressure_branch, ["assumptions", "candidate_source"])
    replay_summary = CandidateRefresh.contact_allocation_replay_summary(candidate_source)

    assert replay_summary["allocated_contact_count"] == 1
    assert replay_summary["returned_allocated_contact_count"] == 1
    assert replay_summary["deferred_contact_count"] == 1
    assert replay_summary["allocated_contact_ids"] == ["stale_dl_allocated"]
    assert replay_summary["returned_allocated_contact_ids"] == ["stale_dl_allocated"]
    assert replay_summary["deferred_contact_ids"] == ["stale_dl_deferred"]
    assert replay_summary["review_contact_ids"] == ["stale_dl_deferred"]
    assert replay_summary["allocation_status_counts"] == %{"allocated" => 1, "deferred" => 1}

    assert replay_summary["effective_allocation_status_counts"] == %{
             "allocated" => 1,
             "deferred" => 1
           }

    refute "stale_top_level_allocated" in replay_summary["allocated_contact_ids"]
    refute "stale_top_level_deferred" in replay_summary["deferred_contact_ids"]
    refute "stale_top_level_deferred" in replay_summary["review_contact_ids"]

    assert_contact_allocation_pressure_score_terms(
      pressure_branch,
      artifact,
      "downlink_completion_gap",
      "contact_allocation"
    )

    comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == pressure_branch["branch_id"]))

    assert comparison_row["branch_source_activity_ids"] == ["stale_dl_deferred"]
    assert "downlink_completion_gap" in comparison_row["risk_types"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy carries mission-state contact-allocation reports into branch refresh requests" do
    direct_report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "model" => "deterministic_station_contact_allocation",
      "rows" => [
        %{
          "contact_id" => "direct_allocated_contact",
          "direction" => "downlink",
          "allocation_status" => "allocated",
          "effective_allocation_status" => "allocated",
          "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
          "ground_station_id" => "equator_prime",
          "required_capacity_fraction" => 0.25,
          "required_capacity_fraction_source" => "contact_required_capacity_fraction"
        }
      ],
      "provenance" => %{"trust_boundary" => "direct_contact_allocation_report_boundary"}
    }

    canonical_report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "model" => "deterministic_station_contact_allocation",
      "rows" => [
        %{
          "contact_id" => "canonical_deferred_contact",
          "direction" => "imaging",
          "allocation_status" => "deferred",
          "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
          "ground_station_id" => "dss_14",
          "required_capacity_fraction" => 0.15,
          "required_capacity_fraction_source" => "capacity_model"
        }
      ],
      "provenance" => %{"trust_boundary" => "canonical_contact_allocation_report_boundary"}
    }

    source_wrapped_report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "model" => "deterministic_station_contact_allocation",
      "rows" => [
        %{
          "contact_id" => "source_wrapped_deferred_contact",
          "direction" => "s-band command",
          "allocation_status" => "deferred",
          "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
          "ground_station_id" => "dss_43",
          "required_capacity_fraction" => 0.35,
          "required_capacity_fraction_source" => "capacity_model"
        }
      ],
      "provenance" => %{"trust_boundary" => "source_wrapped_contact_allocation_fixture"}
    }

    result_wrapped_report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "model" => "deterministic_station_contact_allocation",
      "rows" => [
        %{
          "contact_id" => "result_wrapped_blocked_contact",
          "direction" => "tracking",
          "allocation_status" => "blocked",
          "ground_station_id" => "polar_prime",
          "review_status" => "operator_review_required",
          "station_calendar_overlap_count" => 1,
          "station_calendar_overlap_availabilities" => ["reserved"],
          "station_calendar_precedence_availability" => "reduced_capacity",
          "station_calendar_precedence_rank" => 2
        }
      ],
      "provenance" => %{"trust_boundary" => "result_wrapped_contact_allocation_fixture"}
    }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_contact_allocation_report", direct_report)
      |> Map.put("contact_allocation_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "contact_allocation_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_contact_allocation_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_contact_allocation_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_contact_allocation_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    for source_path <- [
          "mission_state.source_contact_allocation_report",
          "mission_state.contact_allocation_report",
          "mission_state.source_result_artifact.contact_allocation_report",
          "mission_state.result_artifact.source_contact_allocation_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_contact_allocation_blocked_row_count" => 1,
             "source_report_contact_allocation_deferred_row_count" => 2,
             "source_report_contact_allocation_capacity_pack_required_capacity_fraction" => 0.75,
             "source_report_contact_allocation_capacity_pack_selected_required_capacity_fraction" =>
               0.25,
             "source_report_contact_allocation_capacity_pack_deferred_required_capacity_fraction" =>
               0.5,
             "source_report_contact_allocation_direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "imaging" => 1,
               "tracking" => 1
             },
             "source_report_contact_allocation_allocation_status_counts" => %{
               "allocated" => 1,
               "blocked" => 1,
               "deferred" => 2
             },
             "source_report_contact_allocation_station_pressure_contact_count" => 1,
             "source_report_contact_allocation_station_pressure_review_contact_count" => 1,
             "source_report_contact_allocation_station_pressure_ground_station_counts" => %{
               "polar_prime" => 1
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "contact_allocation_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "blocked_row_count" => 1,
             "deferred_row_count" => 2,
             "allocation_status_counts" => %{
               "allocated" => 1,
               "blocked" => 1,
               "deferred" => 2
             },
             "capacity_pack_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 2,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "capacity_pack_required_capacity_fraction" => 0.75,
             "capacity_pack_selected_required_capacity_fraction" => 0.25,
             "capacity_pack_deferred_required_capacity_fraction" => 0.5,
             "capacity_pack_required_capacity_fraction_by_ground_station" => %{
               "dss_14" => 0.15,
               "dss_43" => 0.35,
               "equator_prime" => 0.25
             },
             "capacity_pack_selected_contact_ids_by_ground_station" => %{
               "equator_prime" => ["direct_allocated_contact"]
             },
             "capacity_pack_deferred_contact_ids_by_ground_station" => %{
               "dss_14" => ["canonical_deferred_contact"],
               "dss_43" => ["source_wrapped_deferred_contact"]
             },
             "direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "imaging" => 1,
               "tracking" => 1
             },
             "contact_ids_by_direction" => %{
               "command" => ["source_wrapped_deferred_contact"],
               "downlink" => ["direct_allocated_contact"],
               "imaging" => ["canonical_deferred_contact"],
               "tracking" => ["result_wrapped_blocked_contact"]
             },
             "station_pressure_contact_count" => 1,
             "station_pressure_review_contact_count" => 1,
             "station_pressure_review_contact_ids" => ["result_wrapped_blocked_contact"],
             "station_pressure_ground_station_counts" => %{"polar_prime" => 1},
             "station_pressure_contact_ids_by_ground_station" => %{
               "polar_prime" => ["result_wrapped_blocked_contact"]
             },
             "station_pressure_availability_counts" => %{"reserved" => 1},
             "station_pressure_contact_ids_by_availability" => %{
               "reserved" => ["result_wrapped_blocked_contact"]
             },
             "station_pressure_precedence_availability_counts" => %{"reduced_capacity" => 1},
             "station_pressure_contact_ids_by_precedence_availability" => %{
               "reduced_capacity" => ["result_wrapped_blocked_contact"]
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "canonical_contact_allocation_report_boundary",
               "direct_contact_allocation_report_boundary",
               "result_wrapped_contact_allocation_boundary",
               "source_wrapped_contact_allocation_boundary"
             ],
             "branch_local_contact_allocation_pressure" => true,
             "branch_local_blocked_allocation_pressure" => true,
             "branch_local_deferred_allocation_pressure" => true,
             "branch_local_station_pressure" => true,
             "branch_local_capacity_pack_pressure" => true
           } = CandidateRefresh.contact_allocation_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.contact_allocation_report",
             "mission_state.result_artifact.source_contact_allocation_report",
             "mission_state.source_contact_allocation_report",
             "mission_state.source_result_artifact.contact_allocation_report"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp contact_allocation_summary_fixture(prefix) do
    allocated_row = %{
      "contact_id" => "#{prefix}_dl_allocated",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink"
    }

    deferred_row = %{
      "contact_id" => "#{prefix}_dl_deferred",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "same_station_contention",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink"
    }

    %{
      "schema_contract" => "contact_allocation_summary.v1",
      "model" => "artifact_only_contact_allocation_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "campaign_planner_test.#{prefix}.contact_allocation_summary",
      "input_contact_count" => 2,
      "allocated_contact_count" => 1,
      "returned_allocated_contact_count" => 1,
      "policy_blocked_allocated_contact_count" => 0,
      "deferred_contact_count" => 1,
      "blocked_contact_count" => 0,
      "invalid_contact_input_count" => 0,
      "status_blocked_contact_count" => 0,
      "resource_blocked_contact_count" => 0,
      "duplicate_contact_id_count" => 0,
      "allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
      "effective_allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
      "allocation_reason_counts" => %{
        "same_station_contention" => 1,
        "selected_by_contention_resolution" => 1
      },
      "contact_ids_by_allocation_reason" => %{
        "same_station_contention" => ["#{prefix}_dl_deferred"],
        "selected_by_contention_resolution" => ["#{prefix}_dl_allocated"]
      },
      "allocated_contact_ids" => ["#{prefix}_dl_allocated"],
      "returned_allocated_contact_ids" => ["#{prefix}_dl_allocated"],
      "deferred_contact_ids" => ["#{prefix}_dl_deferred"],
      "blocked_contact_ids" => [],
      "review_contact_ids" => ["#{prefix}_dl_deferred"],
      "rows" => [allocated_row, deferred_row],
      "review_rows" => [deferred_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation"
      },
      "provenance" => %{"trust_boundary" => "#{prefix}_contact_allocation_summary_fixture"}
    }
  end

  defp assert_contact_allocation_pressure_score_terms(
         branch,
         artifact,
         risk_type,
         feedback_scope,
         expected_pressure_count \\ 1
       ) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    contact_pressure_risk_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == risk_type and &1["feedback_scope"] == feedback_scope)
      )

    assert contact_pressure_risk_count == expected_pressure_count
    assert branch["score_terms"]["contact_allocation_pressure_penalty"] < 0.0

    assert branch["score_terms"]["contact_allocation_pressure_penalty"] ==
             -contact_pressure_risk_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - contact_pressure_risk_count) * risk_weight

    assert "contact_allocation_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "contact_allocation_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end
end
