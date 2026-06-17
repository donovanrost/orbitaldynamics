Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyStationReservationHoldSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state station-reservation hold summaries into branch refresh requests" do
    hold_summary = fn prefix, expiration_status, direction, expires_at_s ->
      hold_id = "#{prefix}_reservation_hold"
      contact_id = "#{prefix}_contact"
      reserved_by = "#{prefix}_calendar"

      %{
        "schema_contract" => "station_reservation_hold_summary.v1",
        "model" => "artifact_only_station_reservation_hold_summary",
        "source_artifact_type" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "reservation_hold_count" => 1,
        "affected_contact_reservation_hold_count" => 1,
        "provider_calendar_contention_hold_count" => 0,
        "reservation_hold_review_status" => "review_required",
        "reservation_hold_expiration_count" => 1,
        "earliest_reservation_hold_expires_at_s" => expires_at_s,
        "reservation_hold_expiration_status_counts" => %{expiration_status => 1},
        "reservation_hold_status_counts" => %{"held" => 1},
        "reservation_hold_ids" => [hold_id],
        "reservation_hold_ids_by_expiration_status" => %{expiration_status => [hold_id]},
        "reservation_hold_ids_by_status" => %{"held" => [hold_id]},
        "reservation_hold_ids_by_reserved_by" => %{reserved_by => [hold_id]},
        "reservation_hold_ids_by_row_type" => %{"affected_contact" => [hold_id]},
        "reservation_hold_contact_ids_by_expiration_status" => %{
          expiration_status => [contact_id]
        },
        "review_contact_ids" => [contact_id],
        "review_rows" => [
          %{
            "reservation_review_row_type" => "affected_contact",
            "contact_id" => contact_id,
            "ground_station_id" => "#{prefix}_station",
            "direction" => direction,
            "reservation_ids" => [hold_id],
            "reservation_statuses" => ["held"],
            "reserved_by" => [reserved_by],
            "reservation_expires_at_s" => [expires_at_s],
            "station_reservation_expiration_status" => expiration_status,
            "trust_boundary" => "#{prefix}_station_reservation_hold_row_boundary"
          }
        ],
        "assumptions" => %{
          "execution_boundary" => "artifact_only_no_provider_reservation",
          "source" => "station_reservation_report.v1",
          "operator_authority" => "not_granted_by_summary"
        },
        "provenance" => %{
          "trust_boundary" => "#{prefix}_station_reservation_hold_boundary"
        }
      }
    end

    direct_summary = hold_summary.("direct", "expired", "downlink", 240.0)
    canonical_summary = hold_summary.("canonical", "missing", "tracking", 120.0)
    wrapped_summary = hold_summary.("wrapped", "active", "uplink", 480.0)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_station_reservation_hold_summary", direct_summary)
      |> Map.put("station_reservation_hold_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "station_reservation_hold_summary" => Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_station_reservation_hold_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
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

    for source_path <- [
          "mission_state.source_station_reservation_hold_summary",
          "mission_state.station_reservation_hold_summary",
          "mission_state.source_result_artifact.station_reservation_hold_summary"
        ] do
      assert source_path in source_report_input_paths

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_station_reservation_hold_count" => 4,
             "source_report_station_reservation_affected_contact_hold_count" => 4,
             "source_report_station_reservation_hold_review_status_counts" => %{
               "review_required" => 4
             },
             "source_report_station_reservation_hold_expiration_count" => 4,
             "source_report_station_reservation_earliest_hold_expires_at_s" => 120.0,
             "source_report_station_reservation_hold_expiration_status_counts" => %{
               "active" => 2,
               "expired" => 1,
               "missing" => 1
             },
             "source_report_station_reservation_hold_status_counts" => %{"held" => 4},
             "source_report_station_reservation_hold_ids" => [
               "canonical_reservation_hold",
               "direct_reservation_hold",
               "wrapped_reservation_hold"
             ],
             "source_report_station_reservation_hold_ids_by_expiration_status" => %{
               "active" => ["wrapped_reservation_hold"],
               "expired" => ["direct_reservation_hold"],
               "missing" => ["canonical_reservation_hold"]
             },
             "source_report_station_reservation_hold_ids_by_direction" => %{
               "downlink" => ["direct_reservation_hold"],
               "tracking" => ["canonical_reservation_hold"],
               "uplink" => ["wrapped_reservation_hold"]
             },
             "source_report_station_reservation_hold_contact_ids_by_direction" => %{
               "downlink" => ["direct_contact"],
               "tracking" => ["canonical_contact"],
               "uplink" => ["wrapped_contact"]
             },
             "source_report_station_reservation_hold_review_contact_ids" => [
               "canonical_contact",
               "direct_contact",
               "wrapped_contact"
             ]
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_summary" => 4
             },
             "source_summary_schema_contract_counts" => %{
               "station_reservation_hold_summary.v1" => 4
             },
             "source_artifact_type_counts" => %{"station_reservation_report.v1" => 4},
             "reservation_hold_count" => 4,
             "affected_contact_reservation_hold_count" => 4,
             "reservation_hold_review_status_counts" => %{"review_required" => 4},
             "reservation_hold_expiration_count" => 4,
             "earliest_reservation_hold_expires_at_s" => 120.0,
             "reservation_hold_expiration_status_counts" => %{
               "active" => 2,
               "expired" => 1,
               "missing" => 1
             },
             "reservation_hold_status_counts" => %{"held" => 4},
             "reservation_hold_ids" => [
               "canonical_reservation_hold",
               "direct_reservation_hold",
               "wrapped_reservation_hold"
             ],
             "reservation_hold_ids_by_expiration_status" => %{
               "active" => ["wrapped_reservation_hold"],
               "expired" => ["direct_reservation_hold"],
               "missing" => ["canonical_reservation_hold"]
             },
             "reservation_hold_ids_by_status" => %{
               "held" => [
                 "direct_reservation_hold",
                 "wrapped_reservation_hold",
                 "canonical_reservation_hold"
               ]
             },
             "reservation_hold_ids_by_reserved_by" => %{
               "canonical_calendar" => ["canonical_reservation_hold"],
               "direct_calendar" => ["direct_reservation_hold"],
               "wrapped_calendar" => ["wrapped_reservation_hold"]
             },
             "reservation_hold_ids_by_row_type" => %{
               "affected_contact" => [
                 "direct_reservation_hold",
                 "wrapped_reservation_hold",
                 "canonical_reservation_hold"
               ]
             },
             "reservation_hold_ids_by_direction" => %{
               "downlink" => ["direct_reservation_hold"],
               "tracking" => ["canonical_reservation_hold"],
               "uplink" => ["wrapped_reservation_hold"]
             },
             "reservation_hold_contact_ids_by_expiration_status" => %{
               "active" => ["wrapped_contact"],
               "expired" => ["direct_contact"],
               "missing" => ["canonical_contact"]
             },
             "reservation_hold_contact_ids_by_direction" => %{
               "downlink" => ["direct_contact"],
               "tracking" => ["canonical_contact"],
               "uplink" => ["wrapped_contact"]
             },
             "reservation_hold_review_contact_ids" => [
               "canonical_contact",
               "direct_contact",
               "wrapped_contact"
             ],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_station_reservation_pressure" => true,
             "branch_local_reservation_hold_pressure" => true,
             "assumptions" => %{
               "provider_reservation" => "not_performed_by_summary",
               "station_calendar_mutation" => "not_performed_by_summary",
               "schedule_mutation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.station_reservation_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.source_result_artifact.station_reservation_hold_summary",
             "mission_state.source_station_reservation_hold_summary[0]",
             "mission_state.source_station_reservation_hold_summary[1]",
             "mission_state.station_reservation_hold_summary"
           ]

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_station_reservation_hold_boundary",
             "canonical_station_reservation_hold_row_boundary",
             "direct_station_reservation_hold_boundary",
             "direct_station_reservation_hold_row_boundary",
             "wrapped_station_reservation_hold_boundary",
             "wrapped_station_reservation_hold_row_boundary"
           ]

    direct_hold_branch =
      branch(artifact, "derived_station_calendar_pressure_reserved_direct_contact")

    assert %{
             "type" => "ground_station_reserved",
             "ground_station_id" => "direct_station",
             "station_reservation_id" => "direct_reservation_hold",
             "station_reserved_by" => "direct_calendar",
             "station_reservation_status" => "held",
             "station_reservation_expiration_status" => "expired",
             "required_operator_action" => "review_station_reservation_hold",
             "station_reservation_hold_summary_model" =>
               "artifact_only_station_reservation_hold_summary",
             "station_reservation_hold_review_status" => "review_required",
             "station_reservation_hold_count" => 1,
             "station_reservation_hold_ids" => ["direct_reservation_hold"],
             "station_reservation_hold_summary_source_artifact_type" =>
               "station_reservation_report.v1",
             "feedback_source" => "mission_state.source_station_reservation_hold_summary",
             "feedback_scope" => "station_calendar",
             "trust_boundary" => "direct_station_reservation_hold_row_boundary"
           } = List.first(direct_hold_branch["events"])

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    station_calendar_pressure_count =
      Enum.count(
        direct_hold_branch["risk_indicators"],
        &(&1["type"] == "ground_station_reserved" and
            &1["feedback_source"] == "mission_state.source_station_reservation_hold_summary")
      )

    assert station_calendar_pressure_count == 1

    assert direct_hold_branch["score_terms"]["station_calendar_pressure_penalty"] == 0.0

    assert direct_hold_branch["score_terms"][
             "station_reservation_expiration_pressure_penalty"
           ] == -station_calendar_pressure_count * risk_weight

    assert "station_reservation_expiration_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_station_calendar_pressure_reserved_direct_contact")
      )

    assert "ground_station_reserved" in comparison_row["risk_types"]
    assert comparison_row["branch_station_reservation_ids"] == ["direct_reservation_hold"]

    assert comparison_row["branch_station_reservation_conflict_reservation_ids"] == [
             "direct_reservation_hold"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores stale station-reservation hold summary aggregates when deriving pressure" do
    summary = %{
      "schema_contract" => "station_reservation_hold_summary.v1",
      "model" => "artifact_only_station_reservation_hold_summary",
      "source_artifact_type" => "station_reservation_report.v1",
      "source" => "station_calendar_report.reservation_evidence",
      "reservation_hold_count" => 99,
      "affected_contact_reservation_hold_count" => 99,
      "provider_calendar_contention_hold_count" => 99,
      "reservation_hold_review_status" => "ready",
      "reservation_hold_expiration_count" => 99,
      "earliest_reservation_hold_expires_at_s" => 99_999.0,
      "reservation_hold_expiration_status_counts" => %{"stale_expiration" => 99},
      "reservation_hold_status_counts" => %{"stale_status" => 99},
      "reservation_hold_ids" => ["stale_hold"],
      "reservation_hold_ids_by_expiration_status" => %{"stale_expiration" => ["stale_hold"]},
      "reservation_hold_ids_by_status" => %{"stale_status" => ["stale_hold"]},
      "reservation_hold_ids_by_reserved_by" => %{"stale_owner" => ["stale_hold"]},
      "reservation_hold_ids_by_row_type" => %{"stale_row" => ["stale_hold"]},
      "reservation_hold_contact_ids_by_expiration_status" => %{
        "stale_expiration" => ["stale_contact"]
      },
      "review_contact_ids" => ["stale_contact"],
      "review_rows" => [
        %{
          "reservation_review_row_type" => "affected_contact",
          "contact_id" => "row_hold_contact",
          "ground_station_id" => "dss_14",
          "direction" => "downlink",
          "reservation_ids" => ["row_hold_id"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["ops_hold_owner"],
          "reservation_expires_at_s" => [180.0],
          "station_reservation_expiration_status" => "expired",
          "trust_boundary" => "stale_hold_row_boundary"
        },
        %{
          "reservation_review_row_type" => "provider_calendar_contention_group",
          "id" => "row_provider_group",
          "ground_station_id" => "dss_43",
          "directions" => ["uplink"],
          "provider_calendar_contention_status" => "contention",
          "reservation_ids" => ["row_provider_hold_id"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["provider_hold_owner"],
          "station_reservation_expiration_status" => "missing",
          "trust_boundary" => "stale_hold_provider_row_boundary"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "source" => "station_reservation_report.v1",
        "operator_authority" => "not_granted_by_summary"
      },
      "provenance" => %{"trust_boundary" => "stale_hold_summary_boundary"}
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put("source_station_reservation_hold_summary", summary),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    hold_branch = branch(artifact, "derived_station_calendar_pressure_reserved_row_hold_contact")

    provider_branch =
      branch(artifact, "derived_station_calendar_provider_contention_row_provider_group")

    candidate_source =
      assert_candidate_source_report_path(
        hold_branch,
        "mission_state.source_station_reservation_hold_summary"
      )

    source_summary = candidate_source["candidate_refresh_request_source_report_summary"]

    assert source_summary["source_report_station_reservation_hold_count"] == 2
    assert source_summary["source_report_station_reservation_affected_contact_hold_count"] == 1

    assert source_summary[
             "source_report_station_reservation_provider_calendar_contention_hold_count"
           ] == 1

    assert source_summary["source_report_station_reservation_hold_review_status_counts"] == %{
             "review_required" => 1
           }

    assert source_summary["source_report_station_reservation_hold_expiration_count"] == 1
    assert source_summary["source_report_station_reservation_earliest_hold_expires_at_s"] == 180.0

    assert source_summary["source_report_station_reservation_hold_expiration_status_counts"] == %{
             "expired" => 1,
             "missing" => 1
           }

    assert source_summary["source_report_station_reservation_hold_status_counts"] == %{
             "held" => 2
           }

    assert source_summary["source_report_station_reservation_hold_ids"] == [
             "row_hold_id",
             "row_provider_hold_id"
           ]

    assert source_summary["source_report_station_reservation_hold_ids_by_expiration_status"] ==
             %{
               "expired" => ["row_hold_id"],
               "missing" => ["row_provider_hold_id"]
             }

    assert source_summary["source_report_station_reservation_hold_ids_by_status"] == %{
             "held" => ["row_hold_id", "row_provider_hold_id"]
           }

    assert source_summary["source_report_station_reservation_hold_ids_by_reserved_by"] == %{
             "ops_hold_owner" => ["row_hold_id"],
             "provider_hold_owner" => ["row_provider_hold_id"]
           }

    assert source_summary["source_report_station_reservation_hold_ids_by_row_type"] == %{
             "affected_contact" => ["row_hold_id"],
             "provider_calendar_contention_group" => ["row_provider_hold_id"]
           }

    assert source_summary["source_report_station_reservation_hold_ids_by_direction"] == %{
             "downlink" => ["row_hold_id"],
             "uplink" => ["row_provider_hold_id"]
           }

    assert source_summary["source_report_station_reservation_hold_contact_ids_by_direction"] == %{
             "downlink" => ["row_hold_contact"]
           }

    assert source_summary[
             "source_report_station_reservation_hold_contact_ids_by_expiration_status"
           ] == %{"expired" => ["row_hold_contact"]}

    assert source_summary["source_report_station_reservation_hold_review_contact_ids"] == [
             "row_hold_contact"
           ]

    replay_summary = CandidateRefresh.station_reservation_replay_summary(candidate_source)

    assert replay_summary["reservation_hold_count"] == 2
    assert replay_summary["affected_contact_reservation_hold_count"] == 1
    assert replay_summary["provider_calendar_contention_hold_count"] == 1
    assert replay_summary["reservation_hold_review_status_counts"] == %{"review_required" => 1}
    assert replay_summary["reservation_hold_expiration_count"] == 1
    assert replay_summary["earliest_reservation_hold_expires_at_s"] == 180.0

    assert replay_summary["reservation_hold_expiration_status_counts"] == %{
             "expired" => 1,
             "missing" => 1
           }

    assert replay_summary["reservation_hold_status_counts"] == %{"held" => 2}

    assert replay_summary["reservation_hold_ids"] == [
             "row_hold_id",
             "row_provider_hold_id"
           ]

    assert replay_summary["reservation_hold_ids_by_expiration_status"] == %{
             "expired" => ["row_hold_id"],
             "missing" => ["row_provider_hold_id"]
           }

    assert replay_summary["reservation_hold_ids_by_status"] == %{
             "held" => ["row_hold_id", "row_provider_hold_id"]
           }

    assert replay_summary["reservation_hold_ids_by_reserved_by"] == %{
             "ops_hold_owner" => ["row_hold_id"],
             "provider_hold_owner" => ["row_provider_hold_id"]
           }

    assert replay_summary["reservation_hold_ids_by_row_type"] == %{
             "affected_contact" => ["row_hold_id"],
             "provider_calendar_contention_group" => ["row_provider_hold_id"]
           }

    assert replay_summary["reservation_hold_ids_by_direction"] == %{
             "downlink" => ["row_hold_id"],
             "uplink" => ["row_provider_hold_id"]
           }

    assert replay_summary["reservation_hold_contact_ids_by_direction"] == %{
             "downlink" => ["row_hold_contact"]
           }

    assert replay_summary["reservation_hold_contact_ids_by_expiration_status"] == %{
             "expired" => ["row_hold_contact"]
           }

    assert replay_summary["reservation_hold_review_contact_ids"] == ["row_hold_contact"]
    assert replay_summary["branch_local_station_reservation_pressure"] == true
    assert replay_summary["branch_local_reservation_hold_pressure"] == true

    assert [
             %{
               "type" => "ground_station_reserved",
               "ground_station_id" => "dss_14",
               "station_reservation_id" => "row_hold_id",
               "station_reserved_by" => "ops_hold_owner",
               "station_reservation_status" => "held",
               "station_reservation_expiration_status" => "expired",
               "required_operator_action" => "review_station_reservation_hold",
               "station_reservation_hold_summary_model" =>
                 "artifact_only_station_reservation_hold_summary",
               "station_reservation_hold_summary_source" =>
                 "station_calendar_report.reservation_evidence",
               "station_reservation_hold_summary_source_artifact_type" =>
                 "station_reservation_report.v1",
               "station_reservation_hold_review_status" => "review_required",
               "station_reservation_hold_count" => 1,
               "station_reservation_hold_ids" => ["row_hold_id"],
               "station_reservation_hold_ids_by_direction" => %{
                 "downlink" => ["row_hold_id"]
               },
               "station_reservation_hold_contact_ids_by_expiration_status" => %{
                 "expired" => ["row_hold_contact"]
               },
               "station_reservation_hold_contact_ids_by_direction" => %{
                 "downlink" => ["row_hold_contact"]
               },
               "feedback_source" => "mission_state.source_station_reservation_hold_summary",
               "feedback_scope" => "station_calendar",
               "trust_boundary" => "stale_hold_row_boundary"
             }
           ] = hold_branch["events"]

    assert [
             %{
               "type" => "ground_station_reserved",
               "ground_station_id" => "dss_43",
               "station_reservation_id" => "row_provider_hold_id",
               "station_reserved_by" => "provider_hold_owner",
               "station_reservation_status" => "held",
               "station_reservation_expiration_status" => "missing",
               "required_operator_action" => "review_station_reservation_hold",
               "station_reservation_hold_summary_model" =>
                 "artifact_only_station_reservation_hold_summary",
               "station_reservation_hold_summary_source" =>
                 "station_calendar_report.reservation_evidence",
               "station_reservation_hold_summary_source_artifact_type" =>
                 "station_reservation_report.v1",
               "station_reservation_hold_review_status" => "review_required",
               "station_reservation_hold_count" => 1,
               "station_reservation_hold_ids" => ["row_provider_hold_id"],
               "station_reservation_hold_ids_by_direction" => %{
                 "uplink" => ["row_provider_hold_id"]
               },
               "provider_calendar_contention_group_id" => "row_provider_group",
               "provider_calendar_contention_status" => "contention",
               "provider_calendar_contention_reservation_ids" => ["row_provider_hold_id"],
               "provider_calendar_contention_reserved_by" => ["provider_hold_owner"],
               "provider_calendar_contention_reservation_statuses" => ["held"],
               "feedback_source" =>
                 "mission_state.source_station_reservation_hold_summary.review_rows",
               "feedback_scope" => "station_calendar",
               "trust_boundary" => "stale_hold_provider_row_boundary"
             }
           ] = provider_branch["events"]

    comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_station_calendar_pressure_reserved_row_hold_contact")
      )

    assert comparison_row["branch_station_reservation_ids"] == ["row_hold_id"]
    assert comparison_row["branch_station_reserved_by"] == ["ops_hold_owner"]
    assert comparison_row["branch_station_reservation_statuses"] == ["held"]

    provider_comparison_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_station_calendar_provider_contention_row_provider_group")
      )

    assert provider_comparison_row["branch_station_reservation_ids"] == ["row_provider_hold_id"]
    assert provider_comparison_row["branch_station_reserved_by"] == ["provider_hold_owner"]
    assert provider_comparison_row["branch_station_reservation_statuses"] == ["held"]

    assert provider_comparison_row["branch_station_reservation_expiration_statuses"] == [
             "missing"
           ]

    assert_station_reservation_expiration_pressure_score_terms(hold_branch, artifact)
    assert_station_reservation_expiration_pressure_score_terms(provider_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_candidate_source_report_path(branch, expected_path) do
    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = branch["assumptions"]["candidate_source"]

    assert expected_path in candidate_source["source_report_input_paths"]
    candidate_source
  end

  defp assert_station_reservation_expiration_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    station_reservation_expiration_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["station_reservation_expiration_status"] in ["expired", "missing"])
      )

    assert station_reservation_expiration_pressure_count > 0

    assert branch["score_terms"]["station_calendar_pressure_penalty"] == 0.0

    assert branch["score_terms"]["station_reservation_expiration_pressure_penalty"] ==
             -station_reservation_expiration_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) -
                 station_reservation_expiration_pressure_count) * risk_weight

    assert "station_reservation_expiration_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "station_reservation_expiration_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end
end
