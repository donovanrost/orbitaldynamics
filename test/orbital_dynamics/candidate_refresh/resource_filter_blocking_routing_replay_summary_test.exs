defmodule OrbitalDynamics.CandidateRefresh.ResourceFilterBlockingRoutingReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates resource filter blocking routing maps" do
    refresh = %{
      "source_resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "suppressed_candidates" => [
          %{
            "id" => "obs_payload_block",
            "spacecraft_id" => "leo_1",
            "resource_id" => "payload_1",
            "suppressed_reason" => "payload_unavailable",
            "resource_blocking_dimension" => "payload"
          },
          %{
            "id" => "downlink_margin_block",
            "direction" => "Down Link",
            "spacecraft_id" => "leo_1",
            "resource_summary_id" => "downlink_budget",
            "suppressed_reason" => "downlink_margin_low",
            "resource_blocking_dimension" => "communications"
          },
          %{
            "id" => "power_block",
            "activity_context" => %{"direction" => "s-band command"},
            "spacecraft_id" => "leo_2",
            "battery_id" => "battery_main",
            "suppressed_reason" => "power_margin_low",
            "resource_blocking_dimension" => "power"
          }
        ],
        "invalid_resource_summary_inputs" => [%{"resource_summary_id" => "bad_summary"}],
        "suppressed_reason_counts" => %{"stale_reason" => 99},
        "resource_filter_spacecraft_counts" => %{"stale_spacecraft" => 99},
        "candidate_ids_by_spacecraft" => %{"stale_spacecraft" => ["stale_candidate"]},
        "resource_filter_resource_counts" => %{"stale_resource" => 99},
        "candidate_ids_by_resource" => %{"stale_resource" => ["stale_candidate"]},
        "resource_filter_blocking_dimension_counts" => %{"stale_dimension" => 99},
        "candidate_ids_by_blocking_dimension" => %{"stale_dimension" => ["stale_candidate"]},
        "direction_counts" => %{"stale_direction" => 99},
        "candidate_ids_by_direction" => %{"stale_direction" => ["stale_candidate"]},
        "candidate_ids_by_suppressed_reason" => %{"stale_reason" => ["stale_candidate"]},
        "provenance" => %{"trust_boundary" => "ops_resource_filter"}
      }
    }

    expected_direction_routing = %{
      "command" => %{
        "candidate_count" => 1,
        "candidate_ids" => ["power_block"]
      },
      "downlink" => %{
        "candidate_count" => 1,
        "candidate_ids" => ["downlink_margin_block"]
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_resource_filter_contract" => "resource_filter_report.v1",
             "source_report_resource_filter_count" => 1,
             "source_report_resource_filter_row_count" => 4,
             "source_report_resource_filter_paths" => ["source_resource_filter_report"],
             "source_report_resource_filter_suppressed_candidate_count" => 3,
             "source_report_resource_filter_invalid_resource_summary_input_count" => 1,
             "source_report_resource_filter_invalid_resource_summary_input_ids" => [
               "bad_summary"
             ],
             "source_report_resource_filter_suppressed_reason_counts" => %{
               "downlink_margin_low" => 1,
               "payload_unavailable" => 1,
               "power_margin_low" => 1
             },
             "source_report_resource_filter_candidate_ids_by_suppressed_reason" => %{
               "downlink_margin_low" => ["downlink_margin_block"],
               "payload_unavailable" => ["obs_payload_block"],
               "power_margin_low" => ["power_block"]
             },
             "source_report_resource_filter_spacecraft_counts" => %{
               "leo_1" => 2,
               "leo_2" => 1
             },
             "source_report_resource_filter_candidate_ids_by_spacecraft" => %{
               "leo_1" => ["downlink_margin_block", "obs_payload_block"],
               "leo_2" => ["power_block"]
             },
             "source_report_resource_filter_resource_counts" => %{
               "battery_main" => 1,
               "downlink_budget" => 1,
               "payload_1" => 1
             },
             "source_report_resource_filter_candidate_ids_by_resource" => %{
               "battery_main" => ["power_block"],
               "downlink_budget" => ["downlink_margin_block"],
               "payload_1" => ["obs_payload_block"]
             },
             "source_report_resource_filter_blocking_dimension_counts" => %{
               "communications" => 1,
               "payload" => 1,
               "power" => 1
             },
             "source_report_resource_filter_candidate_ids_by_blocking_dimension" => %{
               "communications" => ["downlink_margin_block"],
               "payload" => ["obs_payload_block"],
               "power" => ["power_block"]
             },
             "source_report_resource_filter_direction_counts" => %{
               "command" => 1,
               "downlink" => 1
             },
             "source_report_resource_filter_directions" => ["command", "downlink"],
             "source_report_resource_filter_candidate_ids_by_direction" => %{
               "command" => ["power_block"],
               "downlink" => ["downlink_margin_block"]
             },
             "source_report_resource_filter_direction_routing" => ^expected_direction_routing,
             "source_report_resource_filter_branch_local_resource_filter_pressure" => true,
             "source_report_resource_filter_branch_local_candidate_suppression_pressure" => true,
             "source_report_resource_filter_branch_local_invalid_resource_summary_pressure" =>
               true,
             "source_report_resource_filter_branch_local_resource_blocking_pressure" => true,
             "source_reports" => %{
               "resource_filter_report" => %{
                 "suppressed_candidate_count" => 3,
                 "invalid_resource_summary_input_count" => 1,
                 "invalid_resource_summary_input_ids" => ["bad_summary"],
                 "direction_counts" => %{
                   "command" => 1,
                   "downlink" => 1
                 },
                 "directions" => ["command", "downlink"],
                 "candidate_ids_by_direction" => %{
                   "command" => ["power_block"],
                   "downlink" => ["downlink_margin_block"]
                 },
                 "direction_routing" => ^expected_direction_routing,
                 "candidate_ids_by_suppressed_reason" => %{
                   "downlink_margin_low" => ["downlink_margin_block"],
                   "payload_unavailable" => ["obs_payload_block"],
                   "power_margin_low" => ["power_block"]
                 },
                 "candidate_ids_by_spacecraft" => %{
                   "leo_1" => ["downlink_margin_block", "obs_payload_block"],
                   "leo_2" => ["power_block"]
                 },
                 "candidate_ids_by_resource" => %{
                   "battery_main" => ["power_block"],
                   "downlink_budget" => ["downlink_margin_block"],
                   "payload_1" => ["obs_payload_block"]
                 },
                 "resource_filter_blocking_dimension_counts" => %{
                   "communications" => 1,
                   "payload" => 1,
                   "power" => 1
                 },
                 "candidate_ids_by_blocking_dimension" => %{
                   "communications" => ["downlink_margin_block"],
                   "payload" => ["obs_payload_block"],
                   "power" => ["power_block"]
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_resource_filter_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.resource_filter_report",
      "contract" => "resource_filter_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 4,
      "source_report_paths" => ["source_resource_filter_report"],
      "suppressed_candidate_count" => 3,
      "invalid_resource_summary_input_count" => 1,
      "invalid_resource_summary_input_ids" => ["bad_summary"],
      "suppressed_reason_counts" => %{
        "downlink_margin_low" => 1,
        "payload_unavailable" => 1,
        "power_margin_low" => 1
      },
      "candidate_ids_by_suppressed_reason" => %{
        "downlink_margin_low" => ["downlink_margin_block"],
        "payload_unavailable" => ["obs_payload_block"],
        "power_margin_low" => ["power_block"]
      },
      "resource_filter_spacecraft_counts" => %{
        "leo_1" => 2,
        "leo_2" => 1
      },
      "candidate_ids_by_spacecraft" => %{
        "leo_1" => ["downlink_margin_block", "obs_payload_block"],
        "leo_2" => ["power_block"]
      },
      "resource_filter_resource_counts" => %{
        "battery_main" => 1,
        "downlink_budget" => 1,
        "payload_1" => 1
      },
      "candidate_ids_by_resource" => %{
        "battery_main" => ["power_block"],
        "downlink_budget" => ["downlink_margin_block"],
        "payload_1" => ["obs_payload_block"]
      },
      "resource_filter_blocking_dimension_counts" => %{
        "communications" => 1,
        "payload" => 1,
        "power" => 1
      },
      "candidate_ids_by_blocking_dimension" => %{
        "communications" => ["downlink_margin_block"],
        "payload" => ["obs_payload_block"],
        "power" => ["power_block"]
      },
      "direction_counts" => %{
        "command" => 1,
        "downlink" => 1
      },
      "directions" => ["command", "downlink"],
      "candidate_ids_by_direction" => %{
        "command" => ["power_block"],
        "downlink" => ["downlink_margin_block"]
      },
      "direction_routing" => expected_direction_routing,
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_resource_filter"],
      "branch_local_resource_filter_pressure" => true,
      "branch_local_candidate_suppression_pressure" => true,
      "branch_local_invalid_resource_summary_pressure" => true,
      "branch_local_resource_blocking_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "resource_filter_source_report_provenance_only",
        "operator_authority" => "not_granted_by_resource_filter_replay_summary",
        "resource_filter" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_resource_filter_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.resource_filter_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_resource_filter_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_resource_filter_contract" => "resource_filter_report.v1",
             "source_report_resource_filter_count" => 1,
             "source_report_resource_filter_row_count" => 4,
             "source_report_resource_filter_paths" => ["source_resource_filter_report"],
             "source_report_resource_filter_suppressed_candidate_count" => 3,
             "source_report_resource_filter_invalid_resource_summary_input_ids" => [
               "bad_summary"
             ],
             "source_report_resource_filter_resource_counts" => %{
               "battery_main" => 1,
               "downlink_budget" => 1,
               "payload_1" => 1
             },
             "source_report_resource_filter_candidate_ids_by_resource" => %{
               "battery_main" => ["power_block"],
               "downlink_budget" => ["downlink_margin_block"],
               "payload_1" => ["obs_payload_block"]
             },
             "source_report_resource_filter_blocking_dimension_counts" => %{
               "communications" => 1,
               "payload" => 1,
               "power" => 1
             },
             "source_report_resource_filter_candidate_ids_by_blocking_dimension" => %{
               "communications" => ["downlink_margin_block"],
               "payload" => ["obs_payload_block"],
               "power" => ["power_block"]
             },
             "source_report_resource_filter_direction_counts" => %{
               "command" => 1,
               "downlink" => 1
             },
             "source_report_resource_filter_directions" => ["command", "downlink"],
             "source_report_resource_filter_candidate_ids_by_suppressed_reason" => %{
               "downlink_margin_low" => ["downlink_margin_block"],
               "payload_unavailable" => ["obs_payload_block"],
               "power_margin_low" => ["power_block"]
             },
             "source_report_resource_filter_candidate_ids_by_spacecraft" => %{
               "leo_1" => ["downlink_margin_block", "obs_payload_block"],
               "leo_2" => ["power_block"]
             },
             "source_report_resource_filter_candidate_ids_by_direction" => %{
               "command" => ["power_block"],
               "downlink" => ["downlink_margin_block"]
             },
             "source_report_resource_filter_direction_routing" => ^expected_direction_routing
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.resource_filter_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_resource_filter_replay_summary(artifact) ==
             replay_summary
  end
end
