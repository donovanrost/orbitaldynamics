defmodule OrbitalDynamics.CandidateRefresh.ResourceFilterReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, CandidateRefresh, OperatorReview, ResourceFilter, Schema}

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

  test "resource filter replay treats preserved suppression maps and invalid IDs as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_resource_filter_report"],
            "suppressed_candidate_count" => 0,
            "invalid_resource_summary_input_count" => 0,
            "invalid_resource_summary_input_ids" => ["bad_resource_summary"],
            "suppressed_reason_counts" => %{"storage_margin_below_observe_policy" => 1},
            "resource_filter_spacecraft_counts" => %{"leo_1" => 1},
            "candidate_ids_by_spacecraft" => %{"leo_1" => ["dl_pressure_1"]},
            "resource_filter_resource_counts" => %{"battery_main" => 1},
            "candidate_ids_by_resource" => %{"battery_main" => ["dl_pressure_1"]},
            "resource_filter_blocking_dimension_counts" => %{"power" => 1},
            "candidate_ids_by_blocking_dimension" => %{"power" => ["dl_pressure_1"]},
            "direction_counts" => %{"downlink" => 1},
            "candidate_ids_by_suppressed_reason" => %{
              "storage_margin_below_observe_policy" => ["dl_pressure_1"]
            },
            "candidate_ids_by_direction" => %{"downlink" => ["dl_pressure_1"]}
          }
        }
      }
    }

    summary = CandidateRefresh.resource_filter_replay_summary(artifact)

    assert summary["suppressed_candidate_count"] == 0
    assert summary["invalid_resource_summary_input_count"] == 0
    assert summary["invalid_resource_summary_input_ids"] == ["bad_resource_summary"]
    assert summary["suppressed_reason_counts"] == %{"storage_margin_below_observe_policy" => 1}
    assert summary["resource_filter_spacecraft_counts"] == %{"leo_1" => 1}
    assert summary["candidate_ids_by_spacecraft"] == %{"leo_1" => ["dl_pressure_1"]}
    assert summary["resource_filter_resource_counts"] == %{"battery_main" => 1}
    assert summary["candidate_ids_by_resource"] == %{"battery_main" => ["dl_pressure_1"]}
    assert summary["resource_filter_blocking_dimension_counts"] == %{"power" => 1}
    assert summary["candidate_ids_by_blocking_dimension"] == %{"power" => ["dl_pressure_1"]}
    assert summary["direction_counts"] == %{"downlink" => 1}

    assert summary["candidate_ids_by_suppressed_reason"] == %{
             "storage_margin_below_observe_policy" => ["dl_pressure_1"]
           }

    assert summary["candidate_ids_by_direction"] == %{"downlink" => ["dl_pressure_1"]}
    assert summary["branch_local_resource_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_invalid_resource_summary_pressure"]
    assert summary["branch_local_resource_blocking_pressure"]
  end

  test "resource filter replay treats preserved blocking candidate maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_resource_filter_report"],
            "suppressed_candidate_count" => 0,
            "invalid_resource_summary_input_count" => 0,
            "candidate_ids_by_spacecraft" => %{"leo_1" => ["payload_block_1"]},
            "candidate_ids_by_resource" => %{"payload_1" => ["payload_block_1"]},
            "candidate_ids_by_blocking_dimension" => %{"payload" => ["payload_block_1"]}
          }
        }
      }
    }

    summary = CandidateRefresh.resource_filter_replay_summary(artifact)

    assert summary["candidate_ids_by_spacecraft"] == %{"leo_1" => ["payload_block_1"]}
    assert summary["candidate_ids_by_resource"] == %{"payload_1" => ["payload_block_1"]}

    assert summary["candidate_ids_by_blocking_dimension"] == %{
             "payload" => ["payload_block_1"]
           }

    assert summary["branch_local_resource_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_resource_blocking_pressure"]
    refute summary["branch_local_invalid_resource_summary_pressure"]
  end

  test "resource filter replay treats preserved invalid IDs as family pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_resource_filter_report"],
            "suppressed_candidate_count" => 0,
            "invalid_resource_summary_input_count" => 0,
            "invalid_resource_summary_input_ids" => ["resource_summary_map_only"]
          }
        }
      }
    }

    summary = CandidateRefresh.resource_filter_replay_summary(artifact)

    assert summary["suppressed_candidate_count"] == 0
    assert summary["invalid_resource_summary_input_count"] == 0
    assert summary["invalid_resource_summary_input_ids"] == ["resource_summary_map_only"]
    assert summary["branch_local_resource_filter_pressure"]
    refute summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_invalid_resource_summary_pressure"]
    refute summary["branch_local_resource_blocking_pressure"]
  end

  test "resource filter replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.resource_filter_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_resource_filter_contract")
    refute Map.has_key?(source_summary, "source_report_resource_filter_count")
    refute Map.has_key?(source_summary, "source_report_resource_filter_row_count")
    refute Map.has_key?(source_summary, "source_report_resource_filter_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_resource_filter_pressure"]
  end

  test "resource filter source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "resource_filter_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.resource_filter_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.resource_filter_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "resource_filter_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_resource_filter_contract"] ==
                 "resource_filter_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_resource_filter_contract")
      end

      refute Map.has_key?(source_summary, "source_report_resource_filter_count")
      refute Map.has_key?(source_summary, "source_report_resource_filter_row_count")
      refute Map.has_key?(source_summary, "source_report_resource_filter_paths")
    end
  end

  test "resource filter source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.resource_filter_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_resource_filter_contract"] ==
             "resource_filter_report.v1"

    assert source_summary["source_report_resource_filter_count"] == 0
    assert source_summary["source_report_resource_filter_row_count"] == 0

    assert source_summary["source_report_resource_filter_paths"] == [
             "provenance.source_reports.resource_filter_report"
           ]
  end

  test "resource filter source summary omits missing identity paths after preserving counts" do
    partial_summaries = [
      %{
        "contract" => "resource_filter_report.v1",
        "count" => 1,
        "row_count" => 2
      },
      %{
        "contract" => "resource_filter_report.v1",
        "count" => 1,
        "row_count" => 2,
        "paths" => nil
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "resource_filter_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)
      replay_summary = CandidateRefresh.resource_filter_replay_summary(artifact)

      assert source_summary["source_report_resource_filter_contract"] ==
               "resource_filter_report.v1"

      assert source_summary["source_report_resource_filter_count"] == 1
      assert source_summary["source_report_resource_filter_row_count"] == 2
      refute Map.has_key?(source_summary, "source_report_resource_filter_paths")

      assert replay_summary["contract"] == "resource_filter_report.v1"
      assert replay_summary["source_report_count"] == 1
      assert replay_summary["source_report_row_count"] == 2
      assert replay_summary["source_report_paths"] == []
    end
  end

  test "resource filter replay preserves suppression and resource maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 1,
            "suppressed_reason_counts" => %{"payload_unavailable" => 1},
            "candidate_ids_by_suppressed_reason" => %{
              "payload_unavailable" => ["filtered_candidate"]
            },
            "invalid_resource_summary_input_ids" => ["invalid_summary"],
            "resource_filter_spacecraft_counts" => %{"leo_1" => 1},
            "candidate_ids_by_spacecraft" => %{"leo_1" => ["filtered_candidate"]},
            "resource_filter_resource_counts" => %{"payload_1" => 1},
            "candidate_ids_by_resource" => %{"payload_1" => ["filtered_candidate"]},
            "resource_filter_blocking_dimension_counts" => %{"payload" => 1},
            "candidate_ids_by_blocking_dimension" => %{
              "payload" => ["filtered_candidate"]
            },
            "direction_counts" => %{"downlink" => 1},
            "directions" => ["downlink"],
            "candidate_ids_by_direction" => %{"downlink" => ["filtered_candidate"]},
            "direction_routing" => %{
              "downlink" => %{
                "candidate_count" => 1,
                "candidate_ids" => ["filtered_candidate"]
              }
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.resource_filter_replay_summary(artifact)

    assert source_summary["source_report_resource_filter_contract"] ==
             "resource_filter_report.v1"

    refute Map.has_key?(source_summary, "source_report_resource_filter_count")
    refute Map.has_key?(source_summary, "source_report_resource_filter_row_count")
    refute Map.has_key?(source_summary, "source_report_resource_filter_paths")

    assert source_summary["source_report_resource_filter_suppressed_reason_counts"] == %{
             "payload_unavailable" => 1
           }

    assert source_summary["source_report_resource_filter_candidate_ids_by_suppressed_reason"] ==
             %{"payload_unavailable" => ["filtered_candidate"]}

    assert source_summary["source_report_resource_filter_invalid_resource_summary_input_ids"] == [
             "invalid_summary"
           ]

    assert source_summary["source_report_resource_filter_spacecraft_counts"] == %{"leo_1" => 1}

    assert source_summary["source_report_resource_filter_candidate_ids_by_spacecraft"] == %{
             "leo_1" => ["filtered_candidate"]
           }

    assert source_summary["source_report_resource_filter_resource_counts"] == %{
             "payload_1" => 1
           }

    assert source_summary["source_report_resource_filter_candidate_ids_by_resource"] == %{
             "payload_1" => ["filtered_candidate"]
           }

    assert source_summary["source_report_resource_filter_blocking_dimension_counts"] == %{
             "payload" => 1
           }

    assert source_summary["source_report_resource_filter_candidate_ids_by_blocking_dimension"] ==
             %{"payload" => ["filtered_candidate"]}

    assert source_summary["source_report_resource_filter_direction_counts"] == %{"downlink" => 1}
    assert source_summary["source_report_resource_filter_directions"] == ["downlink"]

    assert source_summary["source_report_resource_filter_candidate_ids_by_direction"] == %{
             "downlink" => ["filtered_candidate"]
           }

    assert source_summary["source_report_resource_filter_direction_routing"] == %{
             "downlink" => %{
               "candidate_count" => 1,
               "candidate_ids" => ["filtered_candidate"]
             }
           }

    assert replay_summary["contract"] == "resource_filter_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 0
    assert replay_summary["source_report_paths"] == []
    assert replay_summary["suppressed_reason_counts"] == %{"payload_unavailable" => 1}

    assert replay_summary["candidate_ids_by_suppressed_reason"] == %{
             "payload_unavailable" => ["filtered_candidate"]
           }

    assert replay_summary["invalid_resource_summary_input_ids"] == ["invalid_summary"]
    assert replay_summary["resource_filter_spacecraft_counts"] == %{"leo_1" => 1}
    assert replay_summary["candidate_ids_by_spacecraft"] == %{"leo_1" => ["filtered_candidate"]}
    assert replay_summary["resource_filter_resource_counts"] == %{"payload_1" => 1}
    assert replay_summary["candidate_ids_by_resource"] == %{"payload_1" => ["filtered_candidate"]}
    assert replay_summary["resource_filter_blocking_dimension_counts"] == %{"payload" => 1}

    assert replay_summary["candidate_ids_by_blocking_dimension"] == %{
             "payload" => ["filtered_candidate"]
           }

    assert replay_summary["direction_counts"] == %{"downlink" => 1}
    assert replay_summary["directions"] == ["downlink"]
    assert replay_summary["candidate_ids_by_direction"] == %{"downlink" => ["filtered_candidate"]}

    assert replay_summary["direction_routing"] == %{
             "downlink" => %{
               "candidate_count" => 1,
               "candidate_ids" => ["filtered_candidate"]
             }
           }

    assert replay_summary["branch_local_resource_filter_pressure"]
    assert replay_summary["branch_local_candidate_suppression_pressure"]
    assert replay_summary["branch_local_invalid_resource_summary_pressure"]
    assert replay_summary["branch_local_resource_blocking_pressure"]
  end

  test "resource filter source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_resource_filter_contract"] ==
             "resource_filter_report.v1"

    assert source_summary["source_report_resource_filter_count"] == 1
    assert source_summary["source_report_resource_filter_row_count"] == 2
    assert source_summary["source_report_resource_filter_paths"] == []
  end

  test "resource filter replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_filter_report" => %{
              "contract" => "resource_filter_report.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_resource_filter_report"
              ],
              "suppressed_candidate_count" => 2,
              "invalid_resource_summary_input_count" => 1,
              "invalid_resource_summary_input_ids" => ["bad_branch_resource_summary"],
              "suppressed_reason_counts" => %{"payload_unavailable" => 2},
              "candidate_ids_by_suppressed_reason" => %{
                "payload_unavailable" => ["branch_obs", "branch_downlink"]
              },
              "resource_filter_spacecraft_counts" => %{"leo_1" => 2},
              "candidate_ids_by_spacecraft" => %{
                "leo_1" => ["branch_downlink", "branch_obs"]
              },
              "resource_filter_resource_counts" => %{"payload_1" => 2},
              "candidate_ids_by_resource" => %{
                "payload_1" => ["branch_downlink", "branch_obs"]
              },
              "resource_filter_blocking_dimension_counts" => %{"payload" => 2},
              "candidate_ids_by_blocking_dimension" => %{
                "payload" => ["branch_downlink", "branch_obs"]
              },
              "direction_counts" => %{"downlink" => 1},
              "directions" => ["downlink"],
              "candidate_ids_by_direction" => %{"downlink" => ["branch_downlink"]},
              "direction_routing" => %{
                "downlink" => %{
                  "candidate_count" => 1,
                  "candidate_ids" => ["branch_downlink"]
                }
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_resource_filter"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_resource_filter_report"],
            "suppressed_candidate_count" => 99,
            "candidate_ids_by_resource" => %{"provenance_resource" => ["provenance_candidate"]}
          }
        }
      }
    }

    summary = CandidateRefresh.resource_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_filter_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_resource_filter_report"
           ]

    assert summary["suppressed_candidate_count"] == 2
    assert summary["invalid_resource_summary_input_count"] == 1
    assert summary["invalid_resource_summary_input_ids"] == ["bad_branch_resource_summary"]
    assert summary["suppressed_reason_counts"] == %{"payload_unavailable" => 2}

    assert summary["candidate_ids_by_suppressed_reason"] == %{
             "payload_unavailable" => ["branch_obs", "branch_downlink"]
           }

    assert summary["resource_filter_spacecraft_counts"] == %{"leo_1" => 2}

    assert summary["candidate_ids_by_spacecraft"] == %{
             "leo_1" => ["branch_downlink", "branch_obs"]
           }

    assert summary["resource_filter_resource_counts"] == %{"payload_1" => 2}

    assert summary["candidate_ids_by_resource"] == %{
             "payload_1" => ["branch_downlink", "branch_obs"]
           }

    assert summary["resource_filter_blocking_dimension_counts"] == %{"payload" => 2}

    assert summary["candidate_ids_by_blocking_dimension"] == %{
             "payload" => ["branch_downlink", "branch_obs"]
           }

    assert summary["direction_counts"] == %{"downlink" => 1}
    assert summary["directions"] == ["downlink"]
    assert summary["candidate_ids_by_direction"] == %{"downlink" => ["branch_downlink"]}

    assert summary["direction_routing"] == %{
             "downlink" => %{
               "candidate_count" => 1,
               "candidate_ids" => ["branch_downlink"]
             }
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_resource_filter"]
    assert summary["branch_local_resource_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_invalid_resource_summary_pressure"]
    assert summary["branch_local_resource_blocking_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_filter_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_resource_filter_replay_summary(artifact) ==
             summary
  end

  test "resource filter replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_resource_filter_report"
            ],
            "candidate_ids_by_resource" => %{
              "payload_1" => ["direct_branch_candidate"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.resource_filter_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_filter_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_resource_filter_report"
           ]

    assert summary["candidate_ids_by_resource"] == %{
             "payload_1" => ["direct_branch_candidate"]
           }

    assert summary["branch_local_resource_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_resource_blocking_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_filter_candidate_source_report_summary_only"
  end

  test "resource filter replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_filter_report" => %{},
            "resource_projection_report" => %{
              "contract" => "resource_projection_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_resource_filter_report"],
            "invalid_resource_summary_input_count" => 1,
            "invalid_resource_summary_input_ids" => ["provenance_bad_resource_summary"]
          }
        }
      }
    }

    summary = CandidateRefresh.resource_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.resource_filter_report"

    assert summary["source_report_paths"] == ["source_resource_filter_report"]
    assert summary["invalid_resource_summary_input_count"] == 1

    assert summary["invalid_resource_summary_input_ids"] == [
             "provenance_bad_resource_summary"
           ]

    assert summary["branch_local_resource_filter_pressure"]
    assert summary["branch_local_invalid_resource_summary_pressure"]
    refute summary["branch_local_candidate_suppression_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_filter_source_report_provenance_only"
  end

  test "resource filter replay falls back when branch family is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_projection_report" => %{
              "contract" => "resource_projection_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 1,
            "paths" => ["source_resource_filter_report"],
            "candidate_ids_by_resource" => %{
              "payload_1" => ["provenance_candidate"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.resource_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.resource_filter_report"

    assert summary["source_report_paths"] == ["source_resource_filter_report"]

    assert summary["candidate_ids_by_resource"] == %{
             "payload_1" => ["provenance_candidate"]
           }

    assert summary["branch_local_resource_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_resource_blocking_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_filter_source_report_provenance_only"
  end

  test "resource filter replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_filter_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_resource_filter_report"
              ],
              "candidate_ids_by_blocking_dimension" => %{
                "payload" => ["partial_branch_candidate"]
              }
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_filter_report" => %{
            "contract" => "resource_filter_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_resource_filter_report"],
            "suppressed_candidate_count" => 9,
            "candidate_ids_by_blocking_dimension" => %{
              "power" => ["provenance_candidate"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.resource_filter_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_filter_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_resource_filter_report"
           ]

    assert summary["suppressed_candidate_count"] == 0

    assert summary["candidate_ids_by_blocking_dimension"] == %{
             "payload" => ["partial_branch_candidate"]
           }

    assert summary["branch_local_resource_filter_pressure"]
    assert summary["branch_local_candidate_suppression_pressure"]
    assert summary["branch_local_resource_blocking_pressure"]
    refute summary["branch_local_invalid_resource_summary_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_filter_candidate_source_report_summary_only"
  end

  test "source report summary replays compact resource filter summaries" do
    resource_filter_report = %{
      "schema_contract" => "resource_filter_report.v1",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "obs_payload_block",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "leo_1",
          "resource_id" => "payload_1",
          "suppressed_reason" => "payload_unavailable",
          "resource_blocking_dimension" => "payload",
          "resource_source_quality" => "operator_supplied",
          "resource_trust_boundary_status" => "declared"
        }
      ],
      "invalid_resource_summary_inputs" => [
        %{"resource_summary_id" => "bad_resource_summary"}
      ]
    }

    summary =
      resource_filter_report
      |> ResourceFilter.summary()
      |> Map.put("provenance", %{"trust_boundary" => "ops_resource_filter_summary"})

    assert {:ok, resource_filter_summary_schema} =
             Schema.json_schema("resource_filter_summary.v1")

    assert get_in(resource_filter_summary_schema, ["properties", "model", "const"]) ==
             "artifact_only_resource_filter_summary"

    refresh = %{
      "accepted_planning_state" => %{"resource_filter_summary" => summary},
      "mission_state" => %{"source_resource_filter_summary" => summary},
      "source_resource_filter_summary" => summary,
      "source_result_artifact" => %{"resource_filter_summary" => summary}
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_counts_by_contract" => %{"resource_filter_summary.v1" => 4},
             "source_report_row_counts_by_contract" => %{"resource_filter_summary.v1" => 8},
             "source_report_resource_filter_contract" => "resource_filter_summary.v1",
             "source_report_resource_filter_count" => 4,
             "source_report_resource_filter_row_count" => 8,
             "source_report_resource_filter_paths" => [
               "accepted_planning_state.resource_filter_summary",
               "mission_state.source_resource_filter_summary",
               "source_resource_filter_summary",
               "source_result_artifact.resource_filter_summary"
             ],
             "source_report_resource_filter_suppressed_candidate_count" => 4,
             "source_report_resource_filter_invalid_resource_summary_input_count" => 4,
             "source_report_resource_filter_invalid_resource_summary_input_ids" => [
               "bad_resource_summary"
             ],
             "source_report_resource_filter_suppressed_reason_counts" => %{
               "payload_unavailable" => 4
             },
             "source_report_resource_filter_candidate_ids_by_suppressed_reason" => %{
               "payload_unavailable" => ["obs_payload_block"]
             },
             "source_report_resource_filter_spacecraft_counts" => %{"leo_1" => 4},
             "source_report_resource_filter_candidate_ids_by_spacecraft" => %{
               "leo_1" => ["obs_payload_block"]
             },
             "source_report_resource_filter_resource_counts" => %{"payload_1" => 4},
             "source_report_resource_filter_candidate_ids_by_resource" => %{
               "payload_1" => ["obs_payload_block"]
             },
             "source_report_resource_filter_blocking_dimension_counts" => %{"payload" => 4},
             "source_report_resource_filter_candidate_ids_by_blocking_dimension" => %{
               "payload" => ["obs_payload_block"]
             },
             "source_report_resource_filter_branch_local_resource_filter_pressure" => true,
             "source_report_resource_filter_branch_local_candidate_suppression_pressure" => true,
             "source_report_resource_filter_branch_local_invalid_resource_summary_pressure" =>
               true,
             "source_report_resource_filter_branch_local_resource_blocking_pressure" => true,
             "source_reports" => %{
               "resource_filter_report" => %{
                 "paths" => [
                   "accepted_planning_state.resource_filter_summary",
                   "mission_state.source_resource_filter_summary",
                   "source_resource_filter_summary",
                   "source_result_artifact.resource_filter_summary"
                 ],
                 "contract" => "resource_filter_summary.v1",
                 "count" => 4,
                 "row_count" => 8,
                 "source_summary_model_counts" => %{
                   "artifact_only_resource_filter_summary" => 4
                 },
                 "source_summary_schema_contract_counts" => %{
                   "resource_filter_summary.v1" => 4
                 },
                 "source_artifact_type_counts" => %{"resource_filter_report.v1" => 4},
                 "suppressed_candidate_count" => 4,
                 "invalid_resource_summary_input_count" => 4,
                 "invalid_resource_summary_input_ids" => ["bad_resource_summary"],
                 "suppressed_reason_counts" => %{"payload_unavailable" => 4},
                 "candidate_ids_by_suppressed_reason" => %{
                   "payload_unavailable" => ["obs_payload_block"]
                 },
                 "resource_filter_spacecraft_counts" => %{"leo_1" => 4},
                 "candidate_ids_by_spacecraft" => %{"leo_1" => ["obs_payload_block"]},
                 "resource_filter_resource_counts" => %{"payload_1" => 4},
                 "candidate_ids_by_resource" => %{"payload_1" => ["obs_payload_block"]},
                 "resource_filter_blocking_dimension_counts" => %{"payload" => 4},
                 "candidate_ids_by_blocking_dimension" => %{
                   "payload" => ["obs_payload_block"]
                 },
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ops_resource_filter_summary"]
               }
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = CandidateRefresh.resource_filter_replay_summary(refresh)

    assert replay_summary["contract"] == "resource_filter_summary.v1"
    assert replay_summary["source_report_count"] == 4
    assert replay_summary["source_report_row_count"] == 8

    assert replay_summary["source_report_paths"] == [
             "accepted_planning_state.resource_filter_summary",
             "mission_state.source_resource_filter_summary",
             "source_resource_filter_summary",
             "source_result_artifact.resource_filter_summary"
           ]

    assert replay_summary["suppressed_candidate_count"] == 4
    assert replay_summary["invalid_resource_summary_input_count"] == 4
    assert replay_summary["invalid_resource_summary_input_ids"] == ["bad_resource_summary"]
    assert replay_summary["suppressed_reason_counts"] == %{"payload_unavailable" => 4}
    assert replay_summary["resource_filter_spacecraft_counts"] == %{"leo_1" => 4}
    assert replay_summary["resource_filter_resource_counts"] == %{"payload_1" => 4}
    assert replay_summary["resource_filter_blocking_dimension_counts"] == %{"payload" => 4}
    assert replay_summary["trust_boundary_status"] == "declared"
    assert replay_summary["trust_boundaries"] == ["ops_resource_filter_summary"]
    assert replay_summary["branch_local_resource_filter_pressure"]
    assert replay_summary["branch_local_candidate_suppression_pressure"]
    assert replay_summary["branch_local_invalid_resource_summary_pressure"]
    assert replay_summary["branch_local_resource_blocking_pressure"]

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.resource_filter_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_resource_filter_replay_summary(refresh) ==
             replay_summary
  end

  test "operator review and import lift resource filter summaries from candidate refresh artifacts" do
    resource_filter_summary = fn source, prefix ->
      %{
        "schema_contract" => "resource_filter_report.v1",
        "input_candidate_count" => 2,
        "kept_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "#{prefix}_obs_payload_block",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "leo_1",
            "resource_id" => "payload_1",
            "suppressed_reason" => "payload_unavailable",
            "resource_blocking_dimension" => "payload",
            "resource_source_quality" => "operator_supplied",
            "resource_trust_boundary_status" => "declared"
          }
        ],
        "invalid_resource_summary_inputs" => [
          %{
            "resource_summary_id" => "#{prefix}_bad_resource_summary",
            "spacecraft_id" => "leo_1",
            "invalid_resource_summary_input_reason" => "invalid_power_margin",
            "source_resource_summary" => %{"power_margin" => 1.2}
          }
        ]
      }
      |> ResourceFilter.summary()
      |> Map.put("provenance", %{"trust_boundary" => source})
    end

    direct_summary = resource_filter_summary.("unit_test.resource_filter.direct", "direct")

    canonical_summary =
      resource_filter_summary.("unit_test.resource_filter.canonical", "canonical")

    wrapped_summary = resource_filter_summary.("unit_test.resource_filter.wrapped", "wrapped")
    nested_summary = resource_filter_summary.("unit_test.resource_filter.nested", "nested")

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:resource_filter_summary_handoff",
      "source_resource_filter_summary" => [direct_summary],
      "resource_filter_summary" => canonical_summary,
      "source_result_artifact" => [
        wrapped_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "resource_filter_summary" => nested_summary
        }
      ]
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    suppression_rows =
      Enum.filter(review["rows"], &(&1["review_type"] == "resource_suppression"))

    assert length(suppression_rows) == 8

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:resource_filter_summary_handoff",
             "resource_suppression_count" => 8,
             "review_type_counts" => %{"resource_suppression" => 8}
           } = review

    assert Enum.sort(Enum.map(suppression_rows, & &1["source"])) == [
             "candidate_refresh.resource_filter_summary.invalid_resource_summary_inputs",
             "candidate_refresh.resource_filter_summary.review_rows",
             "candidate_refresh.source_resource_filter_summary[0].invalid_resource_summary_inputs",
             "candidate_refresh.source_resource_filter_summary[0].review_rows",
             "candidate_refresh.source_result_artifact[0].invalid_resource_summary_inputs",
             "candidate_refresh.source_result_artifact[0].review_rows",
             "candidate_refresh.source_result_artifact[1].resource_filter_summary.invalid_resource_summary_inputs",
             "candidate_refresh.source_result_artifact[1].resource_filter_summary.review_rows"
           ]

    assert Enum.count(
             suppression_rows,
             &(&1["required_operator_action"] == "review_invalid_resource_filter_summary")
           ) == 4

    assert Enum.count(
             suppression_rows,
             &(&1["required_operator_action"] == "review_suppressed_observation")
           ) == 4

    assert Enum.any?(
             suppression_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.resource_filter_summary.review_rows",
                 "subject_id" => "canonical_obs_payload_block",
                 "suppressed_reason" => "payload_unavailable",
                 "resource_blocking_dimension" => "payload",
                 "source_resource_suppression" => %{
                   "schema_contract" => "resource_filter_summary.v1",
                   "source_resource_filter_summary" => %{
                     "schema_contract" => "resource_filter_summary.v1",
                     "suppression_review_status" => "review_required"
                   }
                 }
               },
               &1
             )
           )

    assert Enum.any?(
             suppression_rows,
             &match?(
               %{
                 "source" =>
                   "candidate_refresh.resource_filter_summary.invalid_resource_summary_inputs",
                 "subject_id" => "canonical_bad_resource_summary",
                 "required_operator_action" => "review_invalid_resource_filter_summary",
                 "invalid_resource_summary_input_reason" => "invalid_power_margin",
                 "source_resource_suppression" => %{
                   "schema_contract" => "resource_filter_summary.v1",
                   "source_resource_filter_summary" => %{
                     "schema_contract" => "resource_filter_summary.v1"
                   }
                 },
                 "source_resource_summary" => %{"power_margin" => 1.2}
               },
               &1
             )
           )

    import_rows =
      Enum.filter(import["rows"], &(&1["source_review_type"] == "resource_suppression"))

    assert length(import_rows) == 8

    assert %{
             "import_action_counts" => %{"review_resource_suppression" => 8},
             "source_review_type_counts" => %{"resource_suppression" => 8}
           } = import

    assert Enum.all?(
             import_rows,
             &(&1["import_action"] == "review_resource_suppression" and
                 &1["source_review_row"]["source_resource_suppression"][
                   "source_resource_filter_summary"
                 ])
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end
end
