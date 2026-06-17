Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyStationReservationHoldImportReadinessSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state station-reservation hold import-readiness summaries into branch refresh requests" do
    hold_import_readiness_summary = fn prefix, affected_direction, provider_direction ->
      expired_hold_id = "#{prefix}_reservation_expired"
      missing_hold_id = "#{prefix}_reservation_missing"
      contact_id = "#{prefix}_contact"

      %{
        "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
        "schema_contract" => "station_reservation_hold_import_readiness_summary.v1",
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
        "reservation_hold_status_counts" => %{"held" => 2},
        "reservation_hold_expiration_status_counts" => %{"expired" => 1, "missing" => 1},
        "required_import_action_counts" => %{
          "review_station_provider_contention" => 1,
          "review_station_reservation_overlap" => 1
        },
        "reservation_hold_ids" => [expired_hold_id, missing_hold_id],
        "reservation_hold_ids_by_import_status" => %{
          "review_required_before_import" => [expired_hold_id, missing_hold_id]
        },
        "reservation_hold_ids_by_required_import_action" => %{
          "review_station_provider_contention" => [missing_hold_id],
          "review_station_reservation_overlap" => [expired_hold_id]
        },
        "reservation_hold_contact_ids_by_import_status" => %{
          "review_required_before_import" => [contact_id]
        },
        "import_readiness_rows" => [
          %{
            "reservation_review_row_type" => "affected_contact",
            "contact_id" => contact_id,
            "ground_station_id" => "#{prefix}_contact_station",
            "direction" => affected_direction,
            "reservation_ids" => [expired_hold_id],
            "reservation_statuses" => ["held"],
            "reserved_by" => ["#{prefix}_ops_calendar"],
            "station_reservation_expiration_status" => "expired",
            "station_reservation_hold_import_status" => "review_required_before_import",
            "required_operator_action" => "review_station_reservation_overlap",
            "trust_boundary" => "#{prefix}_hold_import_readiness_contact_row"
          },
          %{
            "reservation_review_row_type" => "provider_calendar_contention_group",
            "ground_station_id" => "#{prefix}_provider_station",
            "directions" => [provider_direction],
            "reservation_ids" => [missing_hold_id],
            "reservation_statuses" => ["held"],
            "reserved_by" => ["#{prefix}_partner_calendar"],
            "station_reservation_expiration_status" => "missing",
            "station_reservation_hold_import_status" => "review_required_before_import",
            "required_operator_action" => "review_station_provider_contention",
            "trust_boundary" => "#{prefix}_hold_import_readiness_provider_row"
          }
        ],
        "assumptions" => %{
          "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
          "provider_write" => "not_performed_by_summary",
          "cadence_write" => "not_performed_by_summary",
          "reservation_acceptance" => "not_performed_by_summary"
        },
        "provenance" => %{
          "trust_boundary" => "#{prefix}_hold_import_readiness_boundary"
        }
      }
    end

    direct_summary = hold_import_readiness_summary.("direct", "downlink", "uplink")
    canonical_summary = hold_import_readiness_summary.("canonical", "health_check", "command")
    wrapped_summary = hold_import_readiness_summary.("wrapped", "command", "tracking")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_station_reservation_hold_import_readiness_summary", direct_summary)
      |> Map.put("station_reservation_hold_import_readiness_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_station_reservation_hold_import_readiness_summary" =>
          Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_hold_import_readiness_boundary"}
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

    for source_path <- [
          "mission_state.source_station_reservation_hold_import_readiness_summary",
          "mission_state.station_reservation_hold_import_readiness_summary",
          "mission_state.source_result_artifact.source_station_reservation_hold_import_readiness_summary"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_station_reservation_hold_count" => 8,
             "source_report_station_reservation_hold_import_readiness_status_counts" => %{
               "review_required" => 4
             },
             "source_report_station_reservation_hold_import_classification_counts" => %{
               "review_only" => 4
             },
             "source_report_station_reservation_hold_review_required_before_import_count" => 8,
             "source_report_station_reservation_hold_import_status_counts" => %{
               "review_required_before_import" => 8
             },
             "source_report_station_reservation_hold_required_import_action_counts" => %{
               "review_station_provider_contention" => 4,
               "review_station_reservation_overlap" => 4
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_paths" => replay_source_paths,
             "source_summary_model_counts" => %{
               "artifact_only_station_reservation_hold_import_readiness_summary" => 4
             },
             "source_summary_schema_contract_counts" => %{
               "station_reservation_hold_import_readiness_summary.v1" => 4
             },
             "source_artifact_type_counts" => %{"station_reservation_report.v1" => 4},
             "reservation_hold_count" => 8,
             "reservation_hold_import_readiness_status_counts" => %{
               "review_required" => 4
             },
             "reservation_hold_import_classification_counts" => %{"review_only" => 4},
             "reservation_hold_review_required_before_import_count" => 8,
             "reservation_hold_import_status_counts" => %{
               "review_required_before_import" => 8
             },
             "reservation_hold_required_import_action_counts" => %{
               "review_station_provider_contention" => 4,
               "review_station_reservation_overlap" => 4
             },
             "reservation_hold_ids_by_direction" => %{
               "command" => [
                 "wrapped_reservation_expired",
                 "canonical_reservation_missing"
               ],
               "downlink" => ["direct_reservation_expired"],
               "health_check" => ["canonical_reservation_expired"],
               "tracking" => ["wrapped_reservation_missing"],
               "uplink" => ["direct_reservation_missing"]
             },
             "reservation_hold_contact_ids_by_direction" => %{
               "command" => ["wrapped_contact"],
               "downlink" => ["direct_contact"],
               "health_check" => ["canonical_contact"]
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_station_reservation_pressure" => true,
             "branch_local_reservation_hold_import_readiness_pressure" => true,
             "assumptions" => %{
               "provider_reservation" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.station_reservation_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.source_result_artifact.source_station_reservation_hold_import_readiness_summary",
             "mission_state.source_station_reservation_hold_import_readiness_summary[0]",
             "mission_state.source_station_reservation_hold_import_readiness_summary[1]",
             "mission_state.station_reservation_hold_import_readiness_summary"
           ]

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_hold_import_readiness_boundary",
             "canonical_hold_import_readiness_contact_row",
             "canonical_hold_import_readiness_provider_row",
             "direct_hold_import_readiness_boundary",
             "direct_hold_import_readiness_contact_row",
             "direct_hold_import_readiness_provider_row",
             "wrapped_hold_import_readiness_boundary",
             "wrapped_hold_import_readiness_contact_row",
             "wrapped_hold_import_readiness_provider_row"
           ]

    direct_hold_import_branch =
      branch(artifact, "derived_station_calendar_pressure_reserved_direct_contact")

    assert %{
             "type" => "ground_station_reserved",
             "ground_station_id" => "direct_contact_station",
             "station_reservation_id" => "direct_reservation_expired",
             "station_reservation_hold_import_status" => "review_required_before_import",
             "station_reservation_hold_import_readiness_summary_model" =>
               "artifact_only_station_reservation_hold_import_readiness_summary",
             "station_reservation_hold_import_readiness_status" => "review_required",
             "station_reservation_hold_import_classification" => "review_only",
             "station_reservation_hold_import_execution_boundary" =>
               "artifact_only_no_provider_or_cadence_writes",
             "station_reservation_hold_provider_write" => "not_performed_by_summary",
             "station_reservation_hold_cadence_write" => "not_performed_by_summary",
             "station_reservation_hold_reservation_acceptance" => "not_performed_by_summary",
             "required_operator_action" => "review_station_reservation_overlap",
             "feedback_source" =>
               "mission_state.source_station_reservation_hold_import_readiness_summary",
             "feedback_scope" => "station_calendar",
             "trust_boundary" => "direct_hold_import_readiness_contact_row"
           } = List.first(direct_hold_import_branch["events"])

    direct_provider_branch =
      branch(
        artifact,
        "derived_station_calendar_provider_contention_direct_reservation_missing"
      )

    assert Enum.any?(
             direct_provider_branch["events"],
             &(&1["station_reservation_id"] == "direct_reservation_missing" and
                 &1["required_operator_action"] == "review_station_provider_contention" and
                 &1["feedback_source"] ==
                   "mission_state.source_station_reservation_hold_import_readiness_summary.import_readiness_rows" and
                 &1["station_reservation_hold_import_status"] ==
                   "review_required_before_import")
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    station_calendar_pressure_count =
      Enum.count(
        direct_hold_import_branch["risk_indicators"],
        &(&1["type"] == "ground_station_reserved" and
            &1["station_reservation_hold_import_status"] ==
              "review_required_before_import")
      )

    assert station_calendar_pressure_count == 1

    assert direct_hold_import_branch["score_terms"]["station_calendar_pressure_penalty"] == 0.0

    assert direct_hold_import_branch["score_terms"][
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
    assert comparison_row["branch_station_reservation_ids"] == ["direct_reservation_expired"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
