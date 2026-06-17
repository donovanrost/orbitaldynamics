Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyStationReservationReviewPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy derives station-reservation review summaries as branch pressure" do
    reservation_review_summary = fn prefix, station_id, direction ->
      reservation_id = "#{prefix}_reservation_review"
      provider_reservation_id = "#{prefix}_provider_reservation"
      contact_id = "#{prefix}_contact"
      provider_group_id = "#{prefix}_provider_contention"

      %{
        "schema_contract" => "station_reservation_review_summary.v1",
        "model" => "artifact_only_station_reservation_review_summary",
        "source_artifact_type" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "reservation_count" => 2,
        "affected_contact_reservation_count" => 1,
        "provider_calendar_contention_group_count" => 1,
        "reservation_review_status" => "review_required",
        "reservation_expiration_count" => 1,
        "earliest_reservation_expires_at_s" => 240.0,
        "reservation_expiration_status_counts" => %{"expired" => 1, "missing" => 1},
        "reservation_ids_by_expiration_status" => %{
          "expired" => [reservation_id],
          "missing" => [provider_reservation_id]
        },
        "review_reservation_ids" => [reservation_id, provider_reservation_id],
        "review_rows" => [
          %{
            "reservation_review_row_type" => "affected_contact",
            "contact_id" => contact_id,
            "ground_station_id" => station_id,
            "direction" => direction,
            "station_reservation_match_status" => "overlap",
            "reservation_ids" => [reservation_id],
            "reservation_statuses" => ["held"],
            "reserved_by" => ["#{prefix}_ops_calendar"],
            "reservation_expires_at_s" => [240.0],
            "station_reservation_expiration_status" => "expired",
            "required_operator_action" => "review_station_reservation_overlap",
            "trust_boundary" => "#{prefix}_reservation_review_contact_boundary"
          },
          %{
            "reservation_review_row_type" => "provider_calendar_contention_group",
            "id" => provider_group_id,
            "ground_station_id" => station_id,
            "directions" => [direction],
            "provider_calendar_contention_status" => "contention",
            "reservation_ids" => [provider_reservation_id],
            "reservation_statuses" => ["held"],
            "reserved_by" => ["#{prefix}_partner_calendar"],
            "station_reservation_expiration_status" => "missing",
            "required_operator_action" => "review_station_provider_contention",
            "trust_boundary" => "#{prefix}_reservation_review_provider_boundary"
          }
        ],
        "assumptions" => %{
          "execution_boundary" => "artifact_only_no_provider_reservation",
          "source" => "station_reservation_report.v1",
          "operator_authority" => "not_granted_by_summary"
        },
        "provenance" => %{"trust_boundary" => "#{prefix}_reservation_review_boundary"}
      }
    end

    direct_summary = reservation_review_summary.("direct", "dss_14", "downlink")
    canonical_summary = reservation_review_summary.("canonical", "dss_35", "uplink")
    wrapped_summary = reservation_review_summary.("wrapped", "dss_54", "tracking")

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_station_reservation_review_summary", direct_summary)
      |> Map.put("station_reservation_review_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_station_reservation_review_summary" => Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_reservation_review_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    direct_branch = branch(artifact, "derived_station_calendar_pressure_reserved_direct_contact")

    canonical_branch =
      branch(artifact, "derived_station_calendar_pressure_reserved_canonical_contact")

    wrapped_branch =
      branch(artifact, "derived_station_calendar_pressure_reserved_wrapped_contact")

    direct_provider_branch =
      branch(artifact, "derived_station_calendar_provider_contention_direct_provider_contention")

    assert %{
             "type" => "ground_station_reserved",
             "ground_station_id" => "dss_14",
             "station_calendar_directions" => ["downlink"],
             "station_reservation_id" => "direct_reservation_review",
             "station_reserved_by" => "direct_ops_calendar",
             "station_reservation_status" => "held",
             "station_reservation_match_status" => "overlap",
             "station_reservation_expires_at_s" => 240.0,
             "station_reservation_expiration_status" => "expired",
             "required_operator_action" => "review_station_reservation_overlap",
             "feedback_source" => "mission_state.source_station_reservation_review_summary",
             "feedback_scope" => "station_calendar",
             "trust_boundary" => "direct_reservation_review_contact_boundary"
           } = List.first(direct_branch["events"])

    assert "review_station_reservation_overlap" in List.first(direct_branch["events"])[
             "derivation_reasons"
           ]

    assert %{
             "type" => "ground_station_reserved",
             "severity" => "high",
             "station_reservation_id" => "direct_reservation_review",
             "station_reservation_expiration_status" => "expired",
             "required_operator_action" => "review_station_reservation_overlap",
             "feedback_source" => "mission_state.source_station_reservation_review_summary",
             "trust_boundary" => "direct_reservation_review_contact_boundary"
           } =
             Enum.find(
               direct_branch["risk_indicators"],
               &(&1["type"] == "ground_station_reserved")
             )

    assert_station_reservation_expiration_pressure_score_terms(direct_branch, artifact)
    assert_station_reservation_expiration_pressure_score_terms(canonical_branch, artifact)
    assert_station_reservation_expiration_pressure_score_terms(wrapped_branch, artifact)

    assert List.first(canonical_branch["events"])["feedback_source"] ==
             "mission_state.station_reservation_review_summary"

    assert List.first(wrapped_branch["events"])["feedback_source"] ==
             "mission_state.source_result_artifact.source_station_reservation_review_summary"

    assert %{
             "type" => "ground_station_reserved",
             "ground_station_id" => "dss_14",
             "provider_calendar_contention_group_id" => "direct_provider_contention",
             "provider_calendar_contention_status" => "contention",
             "provider_calendar_contention_reservation_ids" => ["direct_provider_reservation"],
             "station_reservation_id" => "direct_provider_reservation",
             "station_reserved_by" => "direct_partner_calendar",
             "station_reservation_status" => "held",
             "feedback_source" =>
               "mission_state.source_station_reservation_review_summary.review_rows",
             "trust_boundary" => "direct_reservation_review_provider_boundary"
           } = List.first(direct_provider_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = direct_branch["assumptions"]["candidate_source"]

    for source_path <- [
          "mission_state.source_station_reservation_review_summary",
          "mission_state.station_reservation_review_summary",
          "mission_state.source_result_artifact.source_station_reservation_review_summary"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]
    end

    assert %{
             "contract" => "station_reservation_report.v1",
             "source_report_count" => 3,
             "source_report_row_count" => 6,
             "source_report_paths" => replay_source_paths,
             "reservation_review_count" => 6,
             "station_reservation_evidence_row_count" => 6,
             "station_reservation_expiration_evidence_row_count" => 3,
             "affected_contact_ids" => [
               "canonical_contact",
               "direct_contact",
               "wrapped_contact"
             ],
             "branch_local_station_reservation_pressure" => true,
             "branch_local_reservation_review_pressure" => true,
             "branch_local_provider_contention_pressure" => true,
             "branch_local_reservation_expiration_pressure" => true
           } = CandidateRefresh.station_reservation_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.source_station_reservation_review_summary",
          "mission_state.station_reservation_review_summary",
          "mission_state.source_result_artifact.source_station_reservation_review_summary"
        ] do
      assert source_path in replay_source_paths
    end

    reservation_pressure_rows =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.filter(
        &(Map.get(&1, "branch_id") in [
            "derived_station_calendar_pressure_reserved_direct_contact",
            "derived_station_calendar_pressure_reserved_canonical_contact",
            "derived_station_calendar_pressure_reserved_wrapped_contact",
            "derived_station_calendar_provider_contention_direct_provider_contention"
          ])
      )

    assert Enum.all?(reservation_pressure_rows, &("ground_station_reserved" in &1["risk_types"]))

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores stale station-reservation review summary aggregates when deriving pressure" do
    summary = %{
      "schema_contract" => "station_reservation_review_summary.v1",
      "model" => "artifact_only_station_reservation_review_summary",
      "source_artifact_type" => "station_reservation_report.v1",
      "source" => "station_calendar_report.reservation_evidence",
      "reservation_count" => 99,
      "affected_contact_reservation_count" => 99,
      "provider_calendar_contention_group_count" => 99,
      "reservation_review_status" => "ready",
      "reservation_expiration_count" => 99,
      "earliest_reservation_expires_at_s" => 99_999.0,
      "reservation_expiration_status_counts" => %{"stale_expiration" => 99},
      "reservation_ids_by_expiration_status" => %{
        "stale_expiration" => ["stale_reservation"]
      },
      "review_reservation_ids" => ["stale_reservation"],
      "review_rows" => [
        %{
          "reservation_review_row_type" => "affected_contact",
          "contact_id" => "stale_res_contact",
          "ground_station_id" => "dss_43",
          "direction" => "downlink",
          "station_reservation_match_status" => "overlap",
          "reservation_ids" => ["row_reservation_43"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["ops_row_owner"],
          "reservation_expires_at_s" => [240.0],
          "station_reservation_expiration_status" => "expired",
          "required_operator_action" => "review_station_reservation_overlap",
          "trust_boundary" => "stale_reservation_review_row_boundary"
        }
      ],
      "station_reservation_match_status_counts" => %{"stale_match" => 99},
      "reservation_status_counts" => %{"stale_status" => 99},
      "direction_counts" => %{"tracking" => 99},
      "contact_ids_by_direction" => %{"tracking" => ["stale_contact"]},
      "reservation_ids_by_status" => %{"stale_status" => ["stale_reservation"]},
      "reserved_by_counts" => %{"stale_owner" => 99},
      "contact_ids_by_reserved_by" => %{"stale_owner" => ["stale_contact"]},
      "reservation_ids_by_reserved_by" => %{"stale_owner" => ["stale_reservation"]},
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "source" => "station_reservation_report.v1",
        "operator_authority" => "not_granted_by_summary"
      },
      "provenance" => %{"trust_boundary" => "stale_reservation_review_summary_boundary"}
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put("source_station_reservation_review_summary", summary),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    reserved_branch =
      branch(artifact, "derived_station_calendar_pressure_reserved_stale_res_contact")

    candidate_source =
      assert_candidate_source_report_path(
        reserved_branch,
        "mission_state.source_station_reservation_review_summary"
      )

    source_summary = candidate_source["candidate_refresh_request_source_report_summary"]

    assert source_summary["source_report_station_reservation_affected_contact_count"] == 1
    assert source_summary["source_report_station_reservation_reservation_review_count"] == 1
    assert source_summary["source_report_station_reservation_evidence_row_count"] == 1

    assert source_summary[
             "source_report_station_reservation_expiration_evidence_row_count"
           ] == 1

    assert source_summary["source_report_station_reservation_affected_contact_ids"] == [
             "stale_res_contact"
           ]

    assert source_summary["source_report_station_reservation_contact_ids_by_match_status"] == %{
             "overlap" => ["stale_res_contact"]
           }

    assert source_summary["source_report_station_reservation_match_status_counts"] == %{
             "overlap" => 1
           }

    assert source_summary["source_report_station_reservation_contact_ids_by_status"] == %{
             "held" => ["stale_res_contact"]
           }

    assert source_summary[
             "source_report_station_reservation_provider_calendar_contention_group_count"
           ] == 0

    assert source_summary["source_report_station_reservation_direction_counts"] == %{
             "downlink" => 1
           }

    assert source_summary["source_report_station_reservation_contact_ids_by_direction"] == %{
             "downlink" => ["stale_res_contact"]
           }

    assert source_summary["source_report_station_reservation_direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["stale_res_contact"],
               "reservation_hold_ids" => [],
               "reservation_hold_contact_ids" => []
             }
           }

    assert source_summary["source_report_station_reservation_expires_at_s"] == [240.0]
    assert source_summary["source_report_station_reservation_earliest_expires_at_s"] == 240.0
    assert source_summary["source_report_station_reservation_status_counts"] == %{"held" => 1}
    assert source_summary["source_report_station_reservation_ids"] == ["row_reservation_43"]

    assert source_summary["source_report_station_reservation_ids_by_match_status"] == %{
             "overlap" => ["row_reservation_43"]
           }

    assert source_summary["source_report_station_reservation_ids_by_status"] == %{
             "held" => ["row_reservation_43"]
           }

    assert source_summary["source_report_station_reservation_reserved_by_counts"] == %{
             "ops_row_owner" => 1
           }

    assert source_summary["source_report_station_reservation_contact_ids_by_reserved_by"] == %{
             "ops_row_owner" => ["stale_res_contact"]
           }

    assert source_summary["source_report_station_reservation_ids_by_reserved_by"] == %{
             "ops_row_owner" => ["row_reservation_43"]
           }

    replay_summary = CandidateRefresh.station_reservation_replay_summary(candidate_source)

    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 1

    assert replay_summary["source_report_paths"] == [
             "mission_state.source_station_reservation_review_summary"
           ]

    assert replay_summary["affected_contact_count"] == 1
    assert replay_summary["provider_calendar_contention_group_count"] == 0
    assert replay_summary["affected_contact_ids"] == ["stale_res_contact"]
    assert replay_summary["contact_ids_by_match_status"] == %{"overlap" => ["stale_res_contact"]}
    assert replay_summary["station_reservation_match_status_counts"] == %{"overlap" => 1}
    assert replay_summary["contact_ids_by_status"] == %{"held" => ["stale_res_contact"]}
    assert replay_summary["direction_counts"] == %{"downlink" => 1}
    assert replay_summary["contact_ids_by_direction"] == %{"downlink" => ["stale_res_contact"]}

    assert replay_summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["stale_res_contact"],
               "reservation_hold_ids" => [],
               "reservation_hold_contact_ids" => []
             }
           }

    assert replay_summary["reservation_expires_at_s"] == [240.0]
    assert replay_summary["earliest_reservation_expires_at_s"] == 240.0
    assert replay_summary["reservation_status_counts"] == %{"held" => 1}
    assert replay_summary["reservation_ids"] == ["row_reservation_43"]

    assert replay_summary["reservation_ids_by_match_status"] == %{
             "overlap" => ["row_reservation_43"]
           }

    assert replay_summary["reservation_ids_by_status"] == %{"held" => ["row_reservation_43"]}
    assert replay_summary["reserved_by_counts"] == %{"ops_row_owner" => 1}

    assert replay_summary["contact_ids_by_reserved_by"] == %{
             "ops_row_owner" => ["stale_res_contact"]
           }

    assert replay_summary["reservation_ids_by_reserved_by"] == %{
             "ops_row_owner" => ["row_reservation_43"]
           }

    assert replay_summary["branch_local_station_reservation_pressure"] == true
    assert replay_summary["branch_local_reservation_review_pressure"] == true
    assert replay_summary["branch_local_reservation_owner_pressure"] == true
    assert replay_summary["branch_local_reservation_expiration_pressure"] == true

    assert [
             %{
               "type" => "ground_station_reserved",
               "ground_station_id" => "dss_43",
               "station_calendar_directions" => ["downlink"],
               "station_reservation_id" => "row_reservation_43",
               "station_reserved_by" => "ops_row_owner",
               "station_reservation_status" => "held",
               "station_reservation_match_status" => "overlap",
               "station_reservation_expires_at_s" => 240.0,
               "station_reservation_expiration_status" => "expired",
               "required_operator_action" => "review_station_reservation_overlap",
               "feedback_source" => "mission_state.source_station_reservation_review_summary",
               "feedback_scope" => "station_calendar",
               "trust_boundary" => "stale_reservation_review_row_boundary"
             }
           ] = reserved_branch["events"]

    reserved_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_station_calendar_pressure_reserved_stale_res_contact")
      )

    assert reserved_row["branch_station_reservation_ids"] == ["row_reservation_43"]
    assert reserved_row["branch_station_reserved_by"] == ["ops_row_owner"]
    assert reserved_row["branch_station_reservation_statuses"] == ["held"]

    assert_station_reservation_expiration_pressure_score_terms(reserved_branch, artifact)

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
