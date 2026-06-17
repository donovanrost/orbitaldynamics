defmodule OrbitalDynamics.CandidateRefresh.ObjectiveGapReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates objective gap routing maps" do
    refresh = %{
      "source_objective_satisfaction_report" => %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "rows" => [
          %{
            "objective" => "downlink_completion",
            "status" => "partial",
            "required_downlink_mb" => 30.0,
            "ground_station_id" => "equator_prime",
            "source_activity_id" => "dl_gap_activity",
            "trust_boundary" => "ops_objective_rows"
          },
          %{
            "objective" => "target_coverage",
            "status" => "unmet",
            "target_id" => "target_a",
            "required_revisits" => 1.0,
            "source_activity_ids" => ["target_gap_activity"],
            "trust_boundary" => "ops_objective_rows"
          },
          %{
            "objective" => "collection_latency",
            "status" => "partial",
            "collection_id" => "collection_alpha",
            "max_latency_s" => 600.0,
            "missed_downlink_activity_ids" => ["collection_latency_activity"],
            "trust_boundary" => "ops_objective_rows"
          }
        ],
        "source_activity_id_counts" => %{"stale_objective_activity" => 99},
        "provenance" => %{"trust_boundary" => "ops_objective_report"}
      },
      "source_objective_tradeoff_report" => %{
        "schema_contract" => "objective_tradeoff_report.v1",
        "tradeoffs" => [
          %{
            "tradeoff_id" => "tradeoff_downlink",
            "required_downlink_mb" => 20.0,
            "ground_station_id" => "equator_prime",
            "activity_ids" => ["tradeoff_downlink_activity"],
            "trust_boundary" => "ops_tradeoff_rows"
          },
          %{
            "tradeoff_id" => "tradeoff_target",
            "target_id" => "target_a",
            "required_revisits" => 1.0,
            "source_activity_ids" => ["tradeoff_target_activity"],
            "trust_boundary" => "ops_tradeoff_rows"
          },
          %{
            "tradeoff_id" => "tradeoff_latency",
            "collection_id" => "collection_alpha",
            "collection_latency_gap_s" => 300.0,
            "source_activity_id" => "tradeoff_latency_activity",
            "trust_boundary" => "ops_tradeoff_rows"
          }
        ],
        "source_activity_id_counts" => %{"stale_tradeoff_activity" => 99},
        "provenance" => %{"trust_boundary" => "ops_tradeoff_report"}
      },
      "source_score_term_report" => %{
        "schema_contract" => "score_term_report.v1",
        "rows" => [
          %{
            "term_key" => "downlink_shortfall_mb",
            "value" => 20.0,
            "ground_station_id" => "equator_prime",
            "source_activity_id" => "score_downlink_activity",
            "trust_boundary" => "ops_score_rows"
          },
          %{
            "term_key" => "target_gap_count",
            "value" => 1.0,
            "target_id" => "target_a",
            "source_activity_id" => "score_target_activity",
            "trust_boundary" => "ops_score_rows"
          },
          %{
            "term_key" => "collection_latency_gap_s",
            "value" => 300.0,
            "collection_id" => "collection_alpha",
            "selected_contact" => %{"contact_id" => "score_collection_activity"},
            "trust_boundary" => "ops_score_rows"
          }
        ],
        "source_activity_id_counts" => %{"stale_score_activity" => 99},
        "provenance" => %{"trust_boundary" => "ops_score_report"}
      }
    }

    assert %{
             "source_report_family_count" => 3,
             "source_report_objective_satisfaction_gap_row_count" => 3,
             "source_report_objective_satisfaction_downlink_gap_row_count" => 1,
             "source_report_objective_satisfaction_target_gap_row_count" => 1,
             "source_report_objective_satisfaction_collection_latency_gap_row_count" => 1,
             "source_report_objective_satisfaction_status_counts" => %{
               "partial" => 2,
               "unmet" => 1
             },
             "source_report_objective_satisfaction_objective_type_counts" => %{
               "collection_latency" => 1,
               "downlink_completion" => 1,
               "target_coverage" => 1
             },
             "source_report_objective_satisfaction_ground_station_counts" => %{
               "equator_prime" => 1
             },
             "source_report_objective_satisfaction_target_counts" => %{"target_a" => 1},
             "source_report_objective_satisfaction_collection_counts" => %{
               "collection_alpha" => 1
             },
             "source_report_objective_satisfaction_source_activity_id_counts" => %{
               "collection_latency_activity" => 1,
               "dl_gap_activity" => 1,
               "target_gap_activity" => 1
             },
             "source_report_objective_tradeoff_downlink_gap_row_count" => 1,
             "source_report_objective_tradeoff_target_gap_row_count" => 1,
             "source_report_objective_tradeoff_collection_latency_gap_row_count" => 2,
             "source_report_objective_tradeoff_ground_station_counts" => %{
               "equator_prime" => 1
             },
             "source_report_objective_tradeoff_target_counts" => %{"target_a" => 1},
             "source_report_objective_tradeoff_collection_counts" => %{
               "collection_alpha" => 1
             },
             "source_report_objective_tradeoff_source_activity_id_counts" => %{
               "tradeoff_downlink_activity" => 1,
               "tradeoff_latency_activity" => 1,
               "tradeoff_target_activity" => 1
             },
             "source_report_score_term_downlink_gap_row_count" => 1,
             "source_report_score_term_target_gap_row_count" => 1,
             "source_report_score_term_collection_latency_gap_row_count" => 1,
             "source_report_score_term_term_key_counts" => %{
               "collection_latency_gap_s" => 1,
               "downlink_shortfall_mb" => 1,
               "target_gap_count" => 1
             },
             "source_report_score_term_ground_station_counts" => %{"equator_prime" => 1},
             "source_report_score_term_target_counts" => %{"target_a" => 1},
             "source_report_score_term_collection_counts" => %{"collection_alpha" => 1},
             "source_report_score_term_source_activity_id_counts" => %{
               "score_collection_activity" => 1,
               "score_downlink_activity" => 1,
               "score_target_activity" => 1
             },
             "source_report_objective_gap_contracts" => [
               "objective_satisfaction_report.v1",
               "objective_tradeoff_report.v1",
               "score_term_report.v1"
             ],
             "source_report_objective_gap_count" => 3,
             "source_report_objective_gap_row_count" => 9,
             "source_report_objective_gap_paths" => [
               "source_objective_satisfaction_report",
               "source_objective_tradeoff_report",
               "source_score_term_report"
             ],
             "source_report_objective_gap_routed_gap_signal_count" => 10,
             "source_report_objective_gap_downlink_gap_row_count" => 3,
             "source_report_objective_gap_target_gap_row_count" => 3,
             "source_report_objective_gap_collection_latency_gap_row_count" => 4,
             "source_report_objective_gap_ground_station_counts" => %{
               "equator_prime" => 3
             },
             "source_report_objective_gap_target_counts" => %{"target_a" => 3},
             "source_report_objective_gap_collection_counts" => %{"collection_alpha" => 3},
             "source_report_objective_gap_source_activity_id_counts" => %{
               "collection_latency_activity" => 1,
               "dl_gap_activity" => 1,
               "score_collection_activity" => 1,
               "score_downlink_activity" => 1,
               "score_target_activity" => 1,
               "target_gap_activity" => 1,
               "tradeoff_downlink_activity" => 1,
               "tradeoff_latency_activity" => 1,
               "tradeoff_target_activity" => 1
             },
             "source_report_objective_gap_branch_local_objective_gap_pressure" => true,
             "source_report_objective_gap_branch_local_downlink_gap_pressure" => true,
             "source_report_objective_gap_branch_local_target_gap_pressure" => true,
             "source_report_objective_gap_branch_local_collection_latency_gap_pressure" => true,
             "source_report_objective_gap_branch_local_objective_status_pressure" => true,
             "source_report_objective_gap_branch_local_score_term_pressure" => true,
             "source_report_objective_gap_branch_local_routing_pressure" => true
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_objective_gap_replay_summary",
      "source" => "candidate_refresh.source_report_provenance.objective_gap_reports",
      "contracts" => [
        "objective_satisfaction_report.v1",
        "objective_tradeoff_report.v1",
        "score_term_report.v1"
      ],
      "source_report_count" => 3,
      "source_report_row_count" => 9,
      "source_report_paths" => [
        "source_objective_satisfaction_report",
        "source_objective_tradeoff_report",
        "source_score_term_report"
      ],
      "routed_gap_signal_count" => 10,
      "downlink_gap_row_count" => 3,
      "target_gap_row_count" => 3,
      "collection_latency_gap_row_count" => 4,
      "objective_satisfaction_gap_row_count" => 3,
      "objective_satisfaction_status_counts" => %{
        "partial" => 2,
        "unmet" => 1
      },
      "objective_satisfaction_objective_type_counts" => %{
        "collection_latency" => 1,
        "downlink_completion" => 1,
        "target_coverage" => 1
      },
      "objective_tradeoff_downlink_gap_row_count" => 1,
      "objective_tradeoff_target_gap_row_count" => 1,
      "objective_tradeoff_collection_latency_gap_row_count" => 2,
      "score_term_downlink_gap_row_count" => 1,
      "score_term_target_gap_row_count" => 1,
      "score_term_collection_latency_gap_row_count" => 1,
      "score_term_key_counts" => %{
        "collection_latency_gap_s" => 1,
        "downlink_shortfall_mb" => 1,
        "target_gap_count" => 1
      },
      "ground_station_counts" => %{"equator_prime" => 3},
      "target_counts" => %{"target_a" => 3},
      "collection_counts" => %{"collection_alpha" => 3},
      "source_activity_id_counts" => %{
        "collection_latency_activity" => 1,
        "dl_gap_activity" => 1,
        "score_collection_activity" => 1,
        "score_downlink_activity" => 1,
        "score_target_activity" => 1,
        "target_gap_activity" => 1,
        "tradeoff_downlink_activity" => 1,
        "tradeoff_latency_activity" => 1,
        "tradeoff_target_activity" => 1
      },
      "trust_boundary_status_counts" => %{"declared" => 3},
      "trust_boundaries" => [
        "ops_objective_report",
        "ops_objective_rows",
        "ops_score_report",
        "ops_score_rows",
        "ops_tradeoff_report",
        "ops_tradeoff_rows"
      ],
      "branch_local_objective_gap_pressure" => true,
      "branch_local_downlink_gap_pressure" => true,
      "branch_local_target_gap_pressure" => true,
      "branch_local_collection_latency_gap_pressure" => true,
      "branch_local_objective_status_pressure" => true,
      "branch_local_score_term_pressure" => true,
      "branch_local_routing_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "objective_gap_source_report_provenance_only",
        "operator_authority" => "not_granted_by_objective_gap_replay_summary",
        "objective_generation" => "not_performed_by_summary",
        "score_recalculation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_objective_gap_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.objective_gap_replay_summary(refresh) == replay_summary

    assert OrbitalDynamics.candidate_refresh_objective_gap_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_objective_satisfaction_gap_row_count" => 3,
             "source_report_objective_tradeoff_collection_latency_gap_row_count" => 2,
             "source_report_score_term_term_key_counts" => %{
               "collection_latency_gap_s" => 1,
               "downlink_shortfall_mb" => 1,
               "target_gap_count" => 1
             },
             "source_report_score_term_collection_counts" => %{"collection_alpha" => 1},
             "source_report_objective_gap_routed_gap_signal_count" => 10,
             "source_report_objective_gap_ground_station_counts" => %{
               "equator_prime" => 3
             },
             "source_report_objective_gap_target_counts" => %{"target_a" => 3},
             "source_report_objective_gap_collection_counts" => %{"collection_alpha" => 3},
             "source_report_objective_gap_source_activity_id_counts" => %{
               "collection_latency_activity" => 1,
               "dl_gap_activity" => 1,
               "score_collection_activity" => 1,
               "score_downlink_activity" => 1,
               "score_target_activity" => 1,
               "target_gap_activity" => 1,
               "tradeoff_downlink_activity" => 1,
               "tradeoff_latency_activity" => 1,
               "tradeoff_target_activity" => 1
             },
             "source_report_objective_gap_branch_local_objective_gap_pressure" => true,
             "source_report_objective_gap_branch_local_downlink_gap_pressure" => true,
             "source_report_objective_gap_branch_local_target_gap_pressure" => true,
             "source_report_objective_gap_branch_local_collection_latency_gap_pressure" => true,
             "source_report_objective_gap_branch_local_objective_status_pressure" => true,
             "source_report_objective_gap_branch_local_score_term_pressure" => true,
             "source_report_objective_gap_branch_local_routing_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.objective_gap_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_objective_gap_replay_summary(artifact) ==
             replay_summary
  end

  test "objective gap replay summary lists only present source-report contracts" do
    refresh = %{
      "source_score_term_report" => %{
        "schema_contract" => "score_term_report.v1",
        "rows" => [
          %{
            "term_key" => "downlink_shortfall_mb",
            "value" => 20.0,
            "ground_station_id" => "equator_prime",
            "trust_boundary" => "ops_score_rows"
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_score_report"}
      }
    }

    assert %{
             "contracts" => ["score_term_report.v1"],
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "source_report_paths" => ["source_score_term_report"],
             "score_term_downlink_gap_row_count" => 1,
             "score_term_key_counts" => %{"downlink_shortfall_mb" => 1},
             "trust_boundary_status_counts" => %{"declared" => 1},
             "trust_boundaries" => ["ops_score_report", "ops_score_rows"],
             "branch_local_score_term_pressure" => true
           } = CandidateRefresh.objective_gap_replay_summary(refresh)
  end

  test "objective gap replay treats objective status maps as family pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "objective_satisfaction_report" => %{
            "contract" => "objective_satisfaction_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_objective_satisfaction_report"],
            "gap_row_count" => 0,
            "downlink_gap_row_count" => 0,
            "target_gap_row_count" => 0,
            "collection_latency_gap_row_count" => 0,
            "status_counts" => %{"review_required" => 1},
            "objective_type_counts" => %{"downlink_completion" => 1},
            "ground_station_counts" => %{},
            "target_counts" => %{},
            "collection_counts" => %{},
            "source_activity_id_counts" => %{},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_objective_rows"]
          }
        }
      }
    }

    summary = CandidateRefresh.objective_gap_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["routed_gap_signal_count"] == 0
    assert summary["objective_satisfaction_status_counts"] == %{"review_required" => 1}

    assert summary["objective_satisfaction_objective_type_counts"] == %{
             "downlink_completion" => 1
           }

    assert summary["branch_local_objective_gap_pressure"]
    assert summary["branch_local_objective_status_pressure"]
    refute summary["branch_local_downlink_gap_pressure"]
    refute summary["branch_local_target_gap_pressure"]
    refute summary["branch_local_collection_latency_gap_pressure"]
    refute summary["branch_local_score_term_pressure"]
    refute summary["branch_local_routing_pressure"]
  end

  test "objective gap source summary keeps declared contracts without partial aggregate identity placeholders" do
    placeholder_fields = [
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.objective_satisfaction_report"]},
      %{"count" => nil, "row_count" => 2},
      %{"count" => 1, "row_count" => nil}
    ]

    for placeholder <- placeholder_fields do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "objective_satisfaction_report" =>
              Map.put(
                placeholder,
                "contract",
                "objective_satisfaction_report.v1"
              )
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_objective_gap_contracts"] ==
               ["objective_satisfaction_report.v1"]

      refute Map.has_key?(source_summary, "source_report_objective_gap_count")
      refute Map.has_key?(source_summary, "source_report_objective_gap_row_count")
      refute Map.has_key?(source_summary, "source_report_objective_gap_paths")
    end
  end

  test "objective gap source summary preserves non-identity rollups with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "objective_satisfaction_report" => %{
            "contract" => "objective_satisfaction_report.v1",
            "count" => 1,
            "status_counts" => %{"review_required" => 1},
            "ground_station_counts" => %{"equator_prime" => 1}
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_objective_gap_contracts"] ==
             ["objective_satisfaction_report.v1"]

    refute Map.has_key?(source_summary, "source_report_objective_gap_count")
    refute Map.has_key?(source_summary, "source_report_objective_gap_row_count")
    refute Map.has_key?(source_summary, "source_report_objective_gap_paths")

    assert source_summary["source_report_objective_satisfaction_status_counts"] ==
             %{"review_required" => 1}

    assert source_summary["source_report_objective_gap_ground_station_counts"] ==
             %{"equator_prime" => 1}
  end

  test "objective gap source summary aggregates identity from complete families only" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "objective_satisfaction_report" => %{
            "contract" => "objective_satisfaction_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => ["provenance.source_reports.objective_satisfaction_report"]
          },
          "score_term_report" => %{
            "contract" => "score_term_report.v1",
            "count" => 1,
            "term_key_counts" => %{"downlink_shortfall_mb" => 1},
            "ground_station_counts" => %{"equator_prime" => 1},
            "source_activity_id_counts" => %{"score_downlink_activity" => 1}
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_objective_gap_contracts"] == [
             "objective_satisfaction_report.v1",
             "score_term_report.v1"
           ]

    assert source_summary["source_report_objective_gap_count"] == 1
    assert source_summary["source_report_objective_gap_row_count"] == 2

    assert source_summary["source_report_objective_gap_paths"] == [
             "provenance.source_reports.objective_satisfaction_report"
           ]

    assert source_summary["source_report_score_term_term_key_counts"] == %{
             "downlink_shortfall_mb" => 1
           }

    assert source_summary["source_report_objective_gap_ground_station_counts"] ==
             %{"equator_prime" => 1}

    assert source_summary["source_report_objective_gap_source_activity_id_counts"] ==
             %{"score_downlink_activity" => 1}
  end

  test "objective gap source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "score_term_report" => %{
            "contract" => "score_term_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.score_term_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_objective_gap_contracts"] == ["score_term_report.v1"]
    assert source_summary["source_report_objective_gap_count"] == 0
    assert source_summary["source_report_objective_gap_row_count"] == 0

    assert source_summary["source_report_objective_gap_paths"] == [
             "provenance.source_reports.score_term_report"
           ]
  end

  test "objective gap source summary omits missing aggregate paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "objective_tradeoff_report" => %{
            "contract" => "objective_tradeoff_report.v1",
            "count" => 1,
            "row_count" => 2
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_objective_gap_contracts"] ==
             ["objective_tradeoff_report.v1"]

    assert source_summary["source_report_objective_gap_count"] == 1
    assert source_summary["source_report_objective_gap_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_objective_gap_paths")
  end

  test "objective gap source summary omits nil aggregate paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "objective_tradeoff_report" => %{
            "contract" => "objective_tradeoff_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => nil
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_objective_gap_contracts"] ==
             ["objective_tradeoff_report.v1"]

    assert source_summary["source_report_objective_gap_count"] == 1
    assert source_summary["source_report_objective_gap_row_count"] == 2
    refute Map.has_key?(source_summary, "source_report_objective_gap_paths")
  end

  test "objective gap source summary preserves empty aggregate paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "objective_tradeoff_report" => %{
            "contract" => "objective_tradeoff_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_objective_gap_contracts"] ==
             ["objective_tradeoff_report.v1"]

    assert source_summary["source_report_objective_gap_count"] == 1
    assert source_summary["source_report_objective_gap_row_count"] == 2
    assert source_summary["source_report_objective_gap_paths"] == []
  end

  test "objective gap replay preserves routing pressure with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "objective_satisfaction_report" => %{
            "contract" => "objective_satisfaction_report.v1",
            "count" => 1,
            "paths" => ["source_objective_satisfaction_report"],
            "gap_row_count" => 0,
            "downlink_gap_row_count" => 0,
            "target_gap_row_count" => 0,
            "collection_latency_gap_row_count" => 0,
            "status_counts" => %{"review_required" => 1},
            "objective_type_counts" => %{"downlink_completion" => 1},
            "ground_station_counts" => %{"equator_prime" => 1},
            "target_counts" => %{},
            "collection_counts" => %{},
            "source_activity_id_counts" => %{"dl_gap_activity" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.objective_gap_replay_summary(artifact)

    assert summary["contracts"] == ["objective_satisfaction_report.v1"]
    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == ["source_objective_satisfaction_report"]
    assert summary["objective_satisfaction_status_counts"] == %{"review_required" => 1}
    assert summary["ground_station_counts"] == %{"equator_prime" => 1}
    assert summary["source_activity_id_counts"] == %{"dl_gap_activity" => 1}
    assert summary["branch_local_objective_gap_pressure"]
    assert summary["branch_local_objective_status_pressure"]
    assert summary["branch_local_routing_pressure"]
  end
end
