defmodule OrbitalDynamics.CandidateRefresh.StationReservationReviewSummaryReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "station reservation replay accepts review summaries" do
    summary = %{
      "model" => "artifact_only_station_reservation_review_summary",
      "schema_contract" => "station_reservation_review_summary.v1",
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
        "expired" => ["reservation_expired"],
        "missing" => ["reservation_missing"]
      },
      "review_reservation_ids" => ["reservation_expired", "reservation_missing"],
      "review_rows" => [
        %{
          "reservation_review_row_type" => "affected_contact",
          "contact_id" => "dl_source_reserved",
          "direction" => "downlink",
          "station_reservation_match_status" => "overlap",
          "reservation_ids" => ["reservation_expired"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["ops_calendar"],
          "reservation_expires_at_s" => [240.0],
          "station_reservation_expiration_status" => "expired",
          "required_operator_action" => "review_station_reservation_overlap"
        },
        %{
          "reservation_review_row_type" => "provider_calendar_contention_group",
          "directions" => ["uplink"],
          "provider_calendar_contention_status" => "contention",
          "reservation_ids" => ["reservation_missing"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["partner_calendar"],
          "station_reservation_expiration_status" => "missing",
          "required_operator_action" => "review_station_provider_contention"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "source" => "station_reservation_report.v1",
        "operator_authority" => "not_granted_by_summary",
        "deadline_evaluation" => "relative_to_now_s",
        "now_s" => 300.0
      }
    }

    refresh = %{"source_station_reservation_review_summary" => summary}

    expected_direction_routing = %{
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["dl_source_reserved"],
        "reservation_hold_ids" => [],
        "reservation_hold_contact_ids" => []
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_station_reservation_contract" => "station_reservation_report.v1",
             "source_report_station_reservation_count" => 1,
             "source_report_station_reservation_row_count" => 2,
             "source_report_station_reservation_paths" => [
               "source_station_reservation_review_summary"
             ],
             "source_report_station_reservation_reservation_review_count" => 2,
             "source_report_station_reservation_evidence_row_count" => 2,
             "source_report_station_reservation_expiration_evidence_row_count" => 1,
             "source_report_station_reservation_affected_contact_count" => 1,
             "source_report_station_reservation_provider_calendar_contention_group_count" => 1,
             "source_report_station_reservation_source_summary_model_counts" => %{
               "artifact_only_station_reservation_review_summary" => 1
             },
             "source_report_station_reservation_source_summary_schema_contract_counts" => %{
               "station_reservation_review_summary.v1" => 1
             },
             "source_report_station_reservation_source_artifact_type_counts" => %{
               "station_reservation_report.v1" => 1
             },
             "source_report_station_reservation_affected_contact_ids" => [
               "dl_source_reserved"
             ],
             "source_report_station_reservation_contact_ids_by_match_status" => %{
               "overlap" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_contact_ids_by_status" => %{
               "held" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_direction_counts" => %{"downlink" => 1},
             "source_report_station_reservation_contact_ids_by_direction" => %{
               "downlink" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_direction_routing" => ^expected_direction_routing,
             "source_report_station_reservation_expires_at_s" => [240.0],
             "source_report_station_reservation_earliest_expires_at_s" => 240.0,
             "source_report_station_reservation_status_counts" => %{"held" => 2},
             "source_report_station_reservation_ids" => [
               "reservation_expired",
               "reservation_missing"
             ],
             "source_report_station_reservation_ids_by_status" => %{
               "held" => ["reservation_expired", "reservation_missing"]
             },
             "source_report_station_reservation_reserved_by_counts" => %{
               "ops_calendar" => 1,
               "partner_calendar" => 1
             },
             "source_report_station_reservation_contact_ids_by_reserved_by" => %{
               "ops_calendar" => ["dl_source_reserved"]
             },
             "source_report_station_reservation_ids_by_reserved_by" => %{
               "ops_calendar" => ["reservation_expired"],
               "partner_calendar" => ["reservation_missing"]
             },
             "source_reports" => %{
               "station_reservation_report" => %{
                 "paths" => ["source_station_reservation_review_summary"],
                 "contract" => "station_reservation_report.v1",
                 "count" => 1,
                 "row_count" => 2,
                 "source_summary_model_counts" => %{
                   "artifact_only_station_reservation_review_summary" => 1
                 },
                 "source_summary_schema_contract_counts" => %{
                   "station_reservation_review_summary.v1" => 1
                 },
                 "source_artifact_type_counts" => %{
                   "station_reservation_report.v1" => 1
                 },
                 "affected_contact_count" => 1,
                 "provider_calendar_contention_group_count" => 1,
                 "reservation_review_count" => 2,
                 "station_reservation_evidence_row_count" => 2,
                 "station_reservation_expiration_evidence_row_count" => 1,
                 "affected_contact_ids" => ["dl_source_reserved"],
                 "contact_ids_by_match_status" => %{
                   "overlap" => ["dl_source_reserved"]
                 },
                 "contact_ids_by_status" => %{"held" => ["dl_source_reserved"]},
                 "direction_counts" => %{"downlink" => 1},
                 "contact_ids_by_direction" => %{"downlink" => ["dl_source_reserved"]},
                 "direction_routing" => ^expected_direction_routing,
                 "reservation_expires_at_s" => [240.0],
                 "earliest_reservation_expires_at_s" => 240.0,
                 "reservation_status_counts" => %{"held" => 2},
                 "reservation_ids" => ["reservation_expired", "reservation_missing"],
                 "reservation_ids_by_status" => %{
                   "held" => ["reservation_expired", "reservation_missing"]
                 },
                 "reserved_by_counts" => %{
                   "ops_calendar" => 1,
                   "partner_calendar" => 1
                 },
                 "contact_ids_by_reserved_by" => %{
                   "ops_calendar" => ["dl_source_reserved"]
                 },
                 "reservation_ids_by_reserved_by" => %{
                   "ops_calendar" => ["reservation_expired"],
                   "partner_calendar" => ["reservation_missing"]
                 }
               }
             }
           } = source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_paths" => ["source_station_reservation_review_summary"],
             "source_summary_model_counts" => %{
               "artifact_only_station_reservation_review_summary" => 1
             },
             "source_summary_schema_contract_counts" => %{
               "station_reservation_review_summary.v1" => 1
             },
             "source_artifact_type_counts" => %{"station_reservation_report.v1" => 1},
             "reservation_review_count" => 2,
             "station_reservation_evidence_row_count" => 2,
             "station_reservation_expiration_evidence_row_count" => 1,
             "affected_contact_count" => 1,
             "provider_calendar_contention_group_count" => 1,
             "affected_contact_ids" => ["dl_source_reserved"],
             "contact_ids_by_status" => %{"held" => ["dl_source_reserved"]},
             "direction_routing" => ^expected_direction_routing,
             "reservation_expires_at_s" => [240.0],
             "earliest_reservation_expires_at_s" => 240.0,
             "reservation_status_counts" => %{"held" => 2},
             "reservation_ids" => ["reservation_expired", "reservation_missing"],
             "reserved_by_counts" => %{
               "ops_calendar" => 1,
               "partner_calendar" => 1
             },
             "branch_local_station_reservation_pressure" => true,
             "branch_local_reservation_review_pressure" => true,
             "branch_local_provider_contention_pressure" => true,
             "branch_local_reservation_expiration_pressure" => true,
             "assumptions" => %{
               "provider_reservation" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = replay_summary = CandidateRefresh.station_reservation_replay_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_report_summary["source_reports"]}
    }

    assert CandidateRefresh.station_reservation_replay_summary(artifact) == replay_summary

    wrapped_summary =
      CandidateRefresh.source_report_summary(%{
        "source_result_artifact" => [
          %{"source_station_reservation_review_summary" => summary}
        ]
      })

    assert get_in(wrapped_summary, [
             "source_reports",
             "station_reservation_report",
             "paths"
           ]) == [
             "source_result_artifact[0].source_station_reservation_review_summary"
           ]
  end
end
