defmodule OrbitalDynamics.CandidateRefresh.ContactContentionResolutionReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  alias OrbitalDynamics.Communications.ContactContention

  test "contact contention resolution replay preserves direct compact summaries as source provenance" do
    resolution_summary = %{
      "schema_contract" => "contact_contention_resolution_summary.v1",
      "model" => "artifact_only_contact_contention_resolution_summary",
      "source_artifact_type" => "contact_contention_resolution_report.v1",
      "policy" => %{"selection_rule" => "highest_score_earliest_start"},
      "conflict_group_count" => 1,
      "recommendation_count" => 1,
      "recommendation_group_ids" => ["station:equator_prime:contention:1"],
      "review_group_ids" => ["station:equator_prime:contention:1"],
      "selected_contact_ids" => ["selected_contact"],
      "selected_contact_ids_by_group_id" => %{
        "station:equator_prime:contention:1" => ["selected_contact"]
      },
      "deferred_contact_ids" => ["deferred_contact"],
      "deferred_contact_ids_by_group_id" => %{
        "station:equator_prime:contention:1" => ["deferred_contact"]
      },
      "ambiguous_group_ids" => [],
      "ambiguous_duplicate_contact_ids" => [],
      "ambiguous_duplicate_contact_ids_by_group_id" => %{},
      "review_contact_ids" => ["deferred_contact", "selected_contact"],
      "review_contact_ids_by_group_id" => %{
        "station:equator_prime:contention:1" => ["deferred_contact", "selected_contact"]
      },
      "review_recommendation_count" => 1,
      "resource_scope_counts" => %{"ground_station" => 1},
      "selected_contact_ids_by_resource_scope" => %{"ground_station" => ["selected_contact"]},
      "deferred_contact_ids_by_resource_scope" => %{"ground_station" => ["deferred_contact"]},
      "review_contact_ids_by_resource_scope" => %{
        "ground_station" => ["deferred_contact", "selected_contact"]
      },
      "selection_reason_counts" => %{"highest_score_earliest_start" => 1},
      "selected_contact_ids_by_selection_reason" => %{
        "highest_score_earliest_start" => ["selected_contact"]
      },
      "action_counts" => %{"recommend_preferred_contact_for_operator_review" => 1},
      "review_contact_ids_by_action" => %{
        "recommend_preferred_contact_for_operator_review" => [
          "deferred_contact",
          "selected_contact"
        ]
      },
      "capacity_pack_required_capacity_fraction" => 0.55,
      "capacity_pack_selected_required_capacity_fraction" => 0.2,
      "capacity_pack_deferred_required_capacity_fraction" => 0.35,
      "capacity_pack_required_capacity_fraction_by_status" => %{
        "deferred" => 0.35,
        "selected" => 0.2
      },
      "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.55
      },
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.2
      },
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.35
      },
      "required_capacity_fraction_source_counts" => %{
        "source_contact_candidate.required_capacity_fraction" => 2
      },
      "required_capacity_fraction_contact_ids_by_source" => %{
        "source_contact_candidate.required_capacity_fraction" => [
          "deferred_contact",
          "selected_contact"
        ]
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "candidate_mutation" => "none",
        "operator_authority" => "not_granted_by_summary",
        "source" => "contact_contention_resolution_report.v1"
      },
      "provenance" => %{"trust_boundary" => "ops_resolution_summary"}
    }

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_summary.v1"}} =
             Schema.validate_artifact(resolution_summary)

    assert :contact_contention_resolution_summary in ContactContention.capabilities().public_facades

    refresh = %{
      "accepted_planning_state" => %{
        "contact_contention_resolution_summary" => resolution_summary
      },
      "mission_state" => %{
        "source_contact_contention_resolution_summary" => resolution_summary
      },
      "source_contact_contention_resolution_summary" => resolution_summary,
      "source_result_artifact" => %{
        "schema_contract" => "candidate_refresh.v1",
        "contact_contention_resolution_summary" => resolution_summary,
        "provenance" => %{"trust_boundary" => "artifact_resolution_summary"}
      }
    }

    assert %{
             "source_report_contact_contention_resolution_recommendation_count" => 4,
             "source_report_contact_contention_resolution_conflict_group_count" => 4,
             "source_report_contact_contention_resolution_review_recommendation_count" => 4,
             "source_report_contact_contention_resolution_source_summary_model_counts" => %{
               "artifact_only_contact_contention_resolution_summary" => 4
             },
             "source_report_contact_contention_resolution_source_summary_schema_contract_counts" =>
               %{
                 "contact_contention_resolution_summary.v1" => 4
               },
             "source_report_contact_contention_resolution_source_artifact_type_counts" => %{
               "contact_contention_resolution_report.v1" => 4
             },
             "source_report_contact_contention_resolution_recommendation_group_ids" => [
               "station:equator_prime:contention:1"
             ],
             "source_report_contact_contention_resolution_review_group_ids" => [
               "station:equator_prime:contention:1"
             ],
             "source_report_contact_contention_resolution_deferred_contact_count" => 4,
             "source_report_contact_contention_resolution_selected_contact_ids" => [
               "selected_contact"
             ],
             "source_report_contact_contention_resolution_deferred_contact_ids" => [
               "deferred_contact"
             ],
             "source_report_contact_contention_resolution_selected_contact_ids_by_group_id" => %{
               "station:equator_prime:contention:1" => ["selected_contact"]
             },
             "source_report_contact_contention_resolution_deferred_contact_ids_by_group_id" => %{
               "station:equator_prime:contention:1" => ["deferred_contact"]
             },
             "source_report_contact_contention_resolution_review_contact_ids" => [
               "deferred_contact",
               "selected_contact"
             ],
             "source_report_contact_contention_resolution_resource_scope_counts" => %{
               "ground_station" => 4
             },
             "source_report_contact_contention_resolution_selection_reason_counts" => %{
               "highest_score_earliest_start" => 4
             },
             "source_report_contact_contention_resolution_selected_contact_ids_by_selection_reason" =>
               %{
                 "highest_score_earliest_start" => ["selected_contact"]
               },
             "source_report_contact_contention_resolution_required_operator_action_counts" => %{
               "recommend_preferred_contact_for_operator_review" => 4
             },
             "source_report_contact_contention_capacity_pack_required_capacity_fraction" => 2.2,
             "source_report_contact_contention_capacity_pack_selected_required_capacity_fraction" =>
               0.8,
             "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction" =>
               1.4,
             "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_ground_station" =>
               %{"equator_prime" => 2.2},
             "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_status" =>
               %{"deferred" => 1.4, "selected" => 0.8},
             "source_reports" => %{
               "contact_contention_resolution_report" => resolution_source_summary
             }
           } = source_summary = CandidateRefresh.source_report_summary(refresh)

    assert resolution_source_summary["contract"] == "contact_contention_resolution_summary.v1"
    assert resolution_source_summary["count"] == 4
    assert resolution_source_summary["row_count"] == 4

    assert resolution_source_summary["paths"] == [
             "accepted_planning_state.contact_contention_resolution_summary",
             "mission_state.source_contact_contention_resolution_summary",
             "source_contact_contention_resolution_summary",
             "source_result_artifact.contact_contention_resolution_summary"
           ]

    assert resolution_source_summary["trust_boundary_status"] == "declared"
    assert resolution_source_summary["trust_boundaries"] == ["ops_resolution_summary"]

    replay_summary = CandidateRefresh.contact_contention_resolution_replay_summary(refresh)

    assert replay_summary["contract"] == "contact_contention_resolution_summary.v1"
    assert replay_summary["source_report_count"] == 4
    assert replay_summary["source_report_row_count"] == 4
    assert replay_summary["source_report_paths"] == resolution_source_summary["paths"]

    assert replay_summary["source_summary_model_counts"] == %{
             "artifact_only_contact_contention_resolution_summary" => 4
           }

    assert replay_summary["source_summary_schema_contract_counts"] == %{
             "contact_contention_resolution_summary.v1" => 4
           }

    assert replay_summary["conflict_group_count"] == 4
    assert replay_summary["recommendation_count"] == 4
    assert replay_summary["review_recommendation_count"] == 4
    assert replay_summary["deferred_contact_count"] == 4
    assert replay_summary["recommendation_group_ids"] == ["station:equator_prime:contention:1"]
    assert replay_summary["review_group_ids"] == ["station:equator_prime:contention:1"]
    assert replay_summary["selected_contact_ids"] == ["selected_contact"]
    assert replay_summary["deferred_contact_ids"] == ["deferred_contact"]
    assert replay_summary["review_contact_ids"] == ["deferred_contact", "selected_contact"]
    assert replay_summary["resource_scope_counts"] == %{"ground_station" => 4}

    assert replay_summary["selected_contact_ids_by_selection_reason"] == %{
             "highest_score_earliest_start" => ["selected_contact"]
           }

    assert replay_summary["required_operator_action_counts"] == %{
             "recommend_preferred_contact_for_operator_review" => 4
           }

    assert replay_summary["capacity_pack_required_capacity_fraction"] == 2.2
    assert replay_summary["capacity_pack_selected_required_capacity_fraction"] == 0.8
    assert replay_summary["capacity_pack_deferred_required_capacity_fraction"] == 1.4

    assert replay_summary["capacity_pack_required_capacity_fraction_by_status"] == %{
             "deferred" => 1.4,
             "selected" => 0.8
           }

    assert replay_summary["capacity_pack_required_capacity_fraction_by_ground_station"] == %{
             "equator_prime" => 2.2
           }

    assert replay_summary["trust_boundaries"] == ["ops_resolution_summary"]
    assert replay_summary["branch_local_contact_contention_resolution_pressure"]
    assert replay_summary["branch_local_deferred_contact_pressure"]
    assert replay_summary["branch_local_capacity_pack_pressure"]
    assert replay_summary["branch_local_contact_contention_resolution_action_pressure"]

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_summary["source_reports"]}
    }

    assert CandidateRefresh.contact_contention_resolution_replay_summary(artifact) ==
             replay_summary
  end

  test "contact contention resolution replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_contract")
    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_count")
    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_contact_contention_resolution_pressure"]
  end

  test "contact contention resolution source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "contact_contention_resolution_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.contact_contention_resolution_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.contact_contention_resolution_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "contact_contention_resolution_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_contact_contention_resolution_contract"] ==
                 "contact_contention_resolution_report.v1"
      else
        refute Map.has_key?(
                 source_summary,
                 "source_report_contact_contention_resolution_contract"
               )
      end

      refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_count")
      refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_row_count")
      refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_paths")
    end
  end

  test "contact contention resolution source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" => %{
            "contract" => "contact_contention_resolution_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.contact_contention_resolution_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_contact_contention_resolution_contract"] ==
             "contact_contention_resolution_report.v1"

    assert source_summary["source_report_contact_contention_resolution_count"] == 0
    assert source_summary["source_report_contact_contention_resolution_row_count"] == 0

    assert source_summary["source_report_contact_contention_resolution_paths"] == [
             "provenance.source_reports.contact_contention_resolution_report"
           ]
  end

  test "contact contention resolution source summary omits missing identity paths after preserving counts" do
    partial_summaries = [
      %{
        "contract" => "contact_contention_resolution_report.v1",
        "count" => 1,
        "row_count" => 2
      },
      %{
        "contract" => "contact_contention_resolution_report.v1",
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
            "contact_contention_resolution_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)
      replay_summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

      assert source_summary["source_report_contact_contention_resolution_contract"] ==
               "contact_contention_resolution_report.v1"

      assert source_summary["source_report_contact_contention_resolution_count"] == 1
      assert source_summary["source_report_contact_contention_resolution_row_count"] == 2
      refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_paths")

      assert replay_summary["contract"] == "contact_contention_resolution_report.v1"
      assert replay_summary["source_report_count"] == 1
      assert replay_summary["source_report_row_count"] == 2
      assert replay_summary["source_report_paths"] == []
    end
  end

  test "contact contention resolution source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" => %{
            "contract" => "contact_contention_resolution_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

    assert source_summary["source_report_contact_contention_resolution_contract"] ==
             "contact_contention_resolution_report.v1"

    assert source_summary["source_report_contact_contention_resolution_count"] == 1
    assert source_summary["source_report_contact_contention_resolution_row_count"] == 2
    assert Map.has_key?(source_summary, "source_report_contact_contention_resolution_paths")
    assert source_summary["source_report_contact_contention_resolution_paths"] == []

    assert replay_summary["contract"] == "contact_contention_resolution_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 2
    assert replay_summary["source_report_paths"] == []
  end

  test "contact contention resolution replay preserves pressure maps with partial identity" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" => %{
            "contract" => "contact_contention_resolution_report.v1",
            "count" => 1,
            "resolution_status_counts" => %{"deferred" => 1},
            "selection_reason_counts" => %{"highest_score" => 1},
            "selected_contact_ids" => ["selected_contact"],
            "deferred_contact_ids" => ["deferred_contact"],
            "selected_contact_ids_by_ground_station" => %{
              "equator_prime" => ["selected_contact"]
            },
            "deferred_contact_ids_by_ground_station" => %{
              "equator_prime" => ["deferred_contact"]
            },
            "direction_counts" => %{"downlink" => 1},
            "contact_ids_by_direction" => %{"downlink" => ["selected_contact"]},
            "direction_routing" => %{
              "downlink" => %{
                "contact_count" => 1,
                "contact_ids" => ["selected_contact"]
              }
            },
            "required_operator_action_counts" => %{
              "review_contact_contention_resolution" => 1
            }
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    replay_summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

    assert source_summary["source_report_contact_contention_resolution_contract"] ==
             "contact_contention_resolution_report.v1"

    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_count")
    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_contention_resolution_paths")

    assert source_summary["source_report_contact_contention_resolution_status_counts"] == %{
             "deferred" => 1
           }

    assert source_summary["source_report_contact_contention_resolution_selection_reason_counts"] ==
             %{"highest_score" => 1}

    assert source_summary["source_report_contact_contention_resolution_selected_contact_ids"] == [
             "selected_contact"
           ]

    assert source_summary["source_report_contact_contention_resolution_deferred_contact_ids"] == [
             "deferred_contact"
           ]

    assert source_summary[
             "source_report_contact_contention_resolution_selected_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["selected_contact"]}

    assert source_summary[
             "source_report_contact_contention_resolution_deferred_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["deferred_contact"]}

    assert source_summary["source_report_contact_contention_resolution_direction_counts"] == %{
             "downlink" => 1
           }

    assert source_summary["source_report_contact_contention_resolution_contact_ids_by_direction"] ==
             %{"downlink" => ["selected_contact"]}

    assert source_summary["source_report_contact_contention_resolution_direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["selected_contact"]
             }
           }

    assert source_summary[
             "source_report_contact_contention_resolution_required_operator_action_counts"
           ] == %{"review_contact_contention_resolution" => 1}

    assert replay_summary["contract"] == "contact_contention_resolution_report.v1"
    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 0
    assert replay_summary["source_report_paths"] == []
    assert replay_summary["resolution_status_counts"] == %{"deferred" => 1}
    assert replay_summary["selection_reason_counts"] == %{"highest_score" => 1}
    assert replay_summary["selected_contact_ids"] == ["selected_contact"]
    assert replay_summary["deferred_contact_ids"] == ["deferred_contact"]

    assert replay_summary["selected_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["selected_contact"]
           }

    assert replay_summary["deferred_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["deferred_contact"]
           }

    assert replay_summary["direction_counts"] == %{"downlink" => 1}
    assert replay_summary["contact_ids_by_direction"] == %{"downlink" => ["selected_contact"]}

    assert replay_summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["selected_contact"]
             }
           }

    assert replay_summary["required_operator_action_counts"] == %{
             "review_contact_contention_resolution" => 1
           }

    assert replay_summary["branch_local_contact_contention_resolution_pressure"]
    assert replay_summary["branch_local_deferred_contact_pressure"]
    assert replay_summary["branch_local_contact_contention_resolution_action_pressure"]
  end

  test "contact contention resolution replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_contention_resolution_report" => %{
              "contract" => "contact_contention_resolution_report.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_contention_resolution_report"
              ],
              "source_summary_model_counts" => %{"artifact_only_contact_contention_summary" => 1},
              "source_summary_schema_contract_counts" => %{
                "contact_contention_summary.v1" => 1
              },
              "source_artifact_type_counts" => %{"contact_contention_report.v1" => 1},
              "conflict_group_count" => 1,
              "recommendation_count" => 2,
              "review_recommendation_count" => 1,
              "deferred_contact_count" => 1,
              "resolution_status_counts" => %{"deferred" => 1},
              "selection_reason_counts" => %{"highest_score" => 1},
              "recommendation_group_ids" => ["branch_group"],
              "review_group_ids" => ["branch_group"],
              "ambiguous_group_ids" => ["ambiguous_group"],
              "ambiguous_duplicate_contact_ids" => ["ambiguous_contact"],
              "ambiguous_duplicate_contact_ids_by_group_id" => %{
                "ambiguous_group" => ["ambiguous_contact"]
              },
              "capacity_pack_required_capacity_fraction" => 0.55,
              "capacity_pack_selected_required_capacity_fraction" => 0.2,
              "capacity_pack_deferred_required_capacity_fraction" => 0.35,
              "capacity_pack_required_capacity_fraction_by_ground_station" => %{
                "equator_prime" => 0.55
              },
              "capacity_pack_selected_required_capacity_fraction_by_ground_station" => %{
                "equator_prime" => 0.2
              },
              "capacity_pack_deferred_required_capacity_fraction_by_ground_station" => %{
                "equator_prime" => 0.35
              },
              "capacity_pack_required_capacity_fraction_by_status" => %{
                "deferred" => 0.35,
                "selected" => 0.2
              },
              "required_capacity_fraction_source_counts" => %{"capacity_model" => 2},
              "required_capacity_fraction_contact_ids_by_source" => %{
                "capacity_model" => ["branch_deferred", "branch_selected"]
              },
              "selected_contact_ids" => ["branch_selected"],
              "deferred_contact_ids" => ["branch_deferred"],
              "review_contact_ids" => ["branch_deferred", "branch_selected"],
              "selected_contact_ids_by_group_id" => %{
                "branch_group" => ["branch_selected"]
              },
              "deferred_contact_ids_by_group_id" => %{
                "branch_group" => ["branch_deferred"]
              },
              "review_contact_ids_by_group_id" => %{
                "branch_group" => ["branch_deferred", "branch_selected"]
              },
              "selected_contact_ids_by_selection_reason" => %{
                "highest_score" => ["branch_selected"]
              },
              "selected_contact_ids_by_ground_station" => %{
                "equator_prime" => ["branch_selected"]
              },
              "deferred_contact_ids_by_ground_station" => %{
                "equator_prime" => ["branch_deferred"]
              },
              "resource_scope_counts" => %{"ground_station" => 1},
              "selected_contact_ids_by_resource_scope" => %{
                "ground_station" => ["branch_selected"]
              },
              "deferred_contact_ids_by_resource_scope" => %{
                "ground_station" => ["branch_deferred"]
              },
              "review_contact_ids_by_resource_scope" => %{
                "ground_station" => ["branch_deferred", "branch_selected"]
              },
              "direction_counts" => %{"command" => 1, "downlink" => 1},
              "contact_ids_by_direction" => %{
                "command" => ["branch_deferred"],
                "downlink" => ["branch_selected"]
              },
              "direction_routing" => %{
                "command" => %{
                  "contact_count" => 1,
                  "contact_ids" => ["branch_deferred"]
                },
                "downlink" => %{
                  "contact_count" => 1,
                  "contact_ids" => ["branch_selected"]
                }
              },
              "required_operator_action_counts" => %{
                "review_contact_contention_resolution" => 1
              },
              "review_contact_ids_by_action" => %{
                "review_contact_contention_resolution" => [
                  "branch_deferred",
                  "branch_selected"
                ]
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_contention_resolution"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" => %{
            "contract" => "contact_contention_resolution_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["source_contact_contention_resolution_report"],
            "recommendation_count" => 0,
            "deferred_contact_count" => 0,
            "selected_contact_ids" => [],
            "deferred_contact_ids" => [],
            "resolution_status_counts" => %{},
            "selection_reason_counts" => %{},
            "required_operator_action_counts" => %{}
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_resolution_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_contention_resolution_report"
           ]

    assert summary["source_summary_model_counts"] == %{
             "artifact_only_contact_contention_summary" => 1
           }

    assert summary["source_summary_schema_contract_counts"] == %{
             "contact_contention_summary.v1" => 1
           }

    assert summary["source_artifact_type_counts"] == %{
             "contact_contention_report.v1" => 1
           }

    assert summary["conflict_group_count"] == 1
    assert summary["recommendation_count"] == 2
    assert summary["review_recommendation_count"] == 1
    assert summary["deferred_contact_count"] == 1
    assert summary["resolution_status_counts"] == %{"deferred" => 1}
    assert summary["selection_reason_counts"] == %{"highest_score" => 1}
    assert summary["recommendation_group_ids"] == ["branch_group"]
    assert summary["review_group_ids"] == ["branch_group"]
    assert summary["ambiguous_group_ids"] == ["ambiguous_group"]
    assert summary["ambiguous_duplicate_contact_ids"] == ["ambiguous_contact"]

    assert summary["ambiguous_duplicate_contact_ids_by_group_id"] == %{
             "ambiguous_group" => ["ambiguous_contact"]
           }

    assert summary["capacity_pack_required_capacity_fraction"] == 0.55
    assert summary["capacity_pack_selected_required_capacity_fraction"] == 0.2
    assert summary["capacity_pack_deferred_required_capacity_fraction"] == 0.35

    assert summary["capacity_pack_required_capacity_fraction_by_ground_station"] == %{
             "equator_prime" => 0.55
           }

    assert summary["capacity_pack_selected_required_capacity_fraction_by_ground_station"] == %{
             "equator_prime" => 0.2
           }

    assert summary["capacity_pack_deferred_required_capacity_fraction_by_ground_station"] == %{
             "equator_prime" => 0.35
           }

    assert summary["capacity_pack_required_capacity_fraction_by_status"] == %{
             "deferred" => 0.35,
             "selected" => 0.2
           }

    assert summary["required_capacity_fraction_source_counts"] == %{"capacity_model" => 2}

    assert summary["required_capacity_fraction_contact_ids_by_source"] == %{
             "capacity_model" => ["branch_deferred", "branch_selected"]
           }

    assert summary["selected_contact_ids"] == ["branch_selected"]
    assert summary["deferred_contact_ids"] == ["branch_deferred"]
    assert summary["review_contact_ids"] == ["branch_deferred", "branch_selected"]

    assert summary["selected_contact_ids_by_group_id"] == %{
             "branch_group" => ["branch_selected"]
           }

    assert summary["deferred_contact_ids_by_group_id"] == %{
             "branch_group" => ["branch_deferred"]
           }

    assert summary["review_contact_ids_by_group_id"] == %{
             "branch_group" => ["branch_deferred", "branch_selected"]
           }

    assert summary["selected_contact_ids_by_selection_reason"] == %{
             "highest_score" => ["branch_selected"]
           }

    assert summary["selected_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_selected"]
           }

    assert summary["deferred_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_deferred"]
           }

    assert summary["resource_scope_counts"] == %{"ground_station" => 1}

    assert summary["selected_contact_ids_by_resource_scope"] == %{
             "ground_station" => ["branch_selected"]
           }

    assert summary["deferred_contact_ids_by_resource_scope"] == %{
             "ground_station" => ["branch_deferred"]
           }

    assert summary["review_contact_ids_by_resource_scope"] == %{
             "ground_station" => ["branch_deferred", "branch_selected"]
           }

    assert summary["direction_counts"] == %{"command" => 1, "downlink" => 1}

    assert summary["contact_ids_by_direction"] == %{
             "command" => ["branch_deferred"],
             "downlink" => ["branch_selected"]
           }

    assert summary["direction_routing"] == %{
             "command" => %{
               "contact_count" => 1,
               "contact_ids" => ["branch_deferred"]
             },
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["branch_selected"]
             }
           }

    assert summary["required_operator_action_counts"] == %{
             "review_contact_contention_resolution" => 1
           }

    assert summary["review_contact_ids_by_action"] == %{
             "review_contact_contention_resolution" => [
               "branch_deferred",
               "branch_selected"
             ]
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_contention_resolution"]
    assert summary["branch_local_contact_contention_resolution_pressure"]
    assert summary["branch_local_deferred_contact_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]
    assert summary["branch_local_contact_contention_resolution_action_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_resolution_candidate_source_report_summary_only"

    assert %{
             "source_report_contact_contention_resolution_branch_local_contact_contention_resolution_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_deferred_contact_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_capacity_pack_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_action_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert OrbitalDynamics.candidate_refresh_contact_contention_resolution_replay_summary(
             artifact
           ) == summary
  end

  test "contact contention resolution replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" => %{
            "contract" => "contact_contention_resolution_report.v1",
            "count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_contact_contention_resolution_report"
            ],
            "deferred_contact_ids" => ["direct_branch_deferred"],
            "direction_counts" => %{"downlink" => 1},
            "contact_ids_by_direction" => %{"downlink" => ["direct_branch_deferred"]}
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_resolution_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_resolution_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_contention_resolution_report"
           ]

    assert summary["deferred_contact_ids"] == ["direct_branch_deferred"]
    assert summary["direction_counts"] == %{"downlink" => 1}
    assert summary["contact_ids_by_direction"] == %{"downlink" => ["direct_branch_deferred"]}
    assert summary["branch_local_contact_contention_resolution_pressure"]
    assert summary["branch_local_deferred_contact_pressure"]
    refute summary["branch_local_capacity_pack_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_resolution_candidate_source_report_summary_only"
  end

  test "contact contention resolution replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_contention_resolution_report" => %{},
            "contact_contention_report" => %{
              "contract" => "contact_contention_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" => %{
            "contract" => "contact_contention_resolution_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_contact_contention_resolution_report"],
            "recommendation_count" => 1,
            "selected_contact_ids" => ["provenance_selected"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.contact_contention_resolution_report"

    assert summary["source_report_paths"] == ["source_contact_contention_resolution_report"]
    assert summary["recommendation_count"] == 1
    assert summary["selected_contact_ids"] == ["provenance_selected"]
    assert summary["branch_local_contact_contention_resolution_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_resolution_source_report_provenance_only"
  end

  test "contact contention resolution replay falls back when branch family is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_contention_report" => %{
              "contract" => "contact_contention_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" => %{
            "contract" => "contact_contention_resolution_report.v1",
            "count" => 1,
            "paths" => ["source_contact_contention_resolution_report"],
            "deferred_contact_ids" => ["provenance_deferred"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.contact_contention_resolution_report"

    assert summary["source_report_paths"] == ["source_contact_contention_resolution_report"]
    assert summary["deferred_contact_ids"] == ["provenance_deferred"]
    assert summary["branch_local_contact_contention_resolution_pressure"]
    assert summary["branch_local_deferred_contact_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_resolution_source_report_provenance_only"
  end

  test "contact contention resolution replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_contention_resolution_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_contention_resolution_report"
              ],
              "resource_scope_counts" => %{"ground_station" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" => %{
            "contract" => "contact_contention_resolution_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_contact_contention_resolution_report"],
            "recommendation_count" => 9,
            "resource_scope_counts" => %{"provenance_scope" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_resolution_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_contention_resolution_report"
           ]

    assert summary["recommendation_count"] == 0
    assert summary["resource_scope_counts"] == %{"ground_station" => 1}
    assert summary["branch_local_contact_contention_resolution_pressure"]
    refute summary["branch_local_deferred_contact_pressure"]
    refute summary["branch_local_capacity_pack_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_resolution_candidate_source_report_summary_only"
  end

  test "contact contention resolution replay treats preserved ID maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" => %{
            "paths" => ["provenance.source_reports.contact_contention_resolution_report"],
            "contract" => "contact_contention_resolution_report.v1",
            "count" => 1,
            "row_count" => 0,
            "recommendation_count" => 0,
            "deferred_contact_count" => 0,
            "capacity_pack_required_capacity_fraction" => 0.0,
            "capacity_pack_selected_required_capacity_fraction" => 0.0,
            "capacity_pack_deferred_required_capacity_fraction" => 0.0,
            "capacity_pack_required_capacity_fraction_by_ground_station" => %{
              "equator_prime" => 0.0
            },
            "capacity_pack_selected_required_capacity_fraction_by_ground_station" => %{
              "equator_prime" => 0.0
            },
            "capacity_pack_deferred_required_capacity_fraction_by_ground_station" => %{
              "equator_prime" => 0.0
            },
            "selected_contact_ids" => ["selected_contact"],
            "deferred_contact_ids" => ["deferred_contact"],
            "selected_contact_ids_by_ground_station" => %{
              "equator_prime" => ["selected_contact"]
            },
            "deferred_contact_ids_by_ground_station" => %{
              "equator_prime" => ["deferred_contact"]
            },
            "required_operator_action_counts" => %{
              "review_contact_contention_resolution" => 1
            },
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_contention_resolution"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_resolution_replay_summary(artifact)

    assert summary["recommendation_count"] == 0
    assert summary["deferred_contact_count"] == 0
    assert summary["selected_contact_ids"] == ["selected_contact"]
    assert summary["deferred_contact_ids"] == ["deferred_contact"]

    assert summary["selected_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["selected_contact"]
           }

    assert summary["deferred_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["deferred_contact"]
           }

    assert summary["branch_local_contact_contention_resolution_pressure"]
    assert summary["branch_local_deferred_contact_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]
    assert summary["branch_local_contact_contention_resolution_action_pressure"]
  end

  test "derives downlink completion objectives from source contact contention resolution reports" do
    report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "recommendations" => [
        %{
          "group_id" => "station:equator_prime:contention:prior",
          "ground_station_id" => "equator_prime",
          "selected_contact_id" => "dl_selected",
          "deferred_contact_ids" => ["dl_deferred"],
          "selection_reason" => "highest_score_earliest_start",
          "source_contact_candidates" => [
            %{
              "id" => "dl_deferred",
              "type" => "downlink",
              "spacecraft_id" => "sat_1",
              "ground_station_id" => "equator_prime",
              "required_downlink_mb" => 420.0,
              "source_window_id" => "window_deferred",
              "trust_boundary" => "cadence_ops"
            }
          ]
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_contact_contention_resolution_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays contact contention resolution pressure from result artifact wrappers" do
    report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "recommendations" => [
        %{
          "group_id" => "station:equator_prime:contention:prior",
          "ground_station_id" => "equator_prime",
          "selected_contact_id" => "dl_selected",
          "deferred_contact_ids" => ["dl_deferred"],
          "required_downlink_mb" => 420.0
        }
      ]
    }

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "contact_contention_resolution_report" => report,
      "provenance" => %{"trust_boundary" => "mission_planning"}
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_result_artifact", wrapper),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays contact contention resolution pressure from operator review packages" do
    report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "recommendations" => [
        %{
          "group_id" => "station:equator_prime:contention:prior",
          "ground_station_id" => "equator_prime",
          "selected_contact_id" => "dl_selected",
          "deferred_contact_ids" => ["dl_deferred"],
          "required_downlink_mb" => 420.0
        }
      ]
    }

    package = OperatorReview.from_contact_contention_resolution_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_operator_review_package", package),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays contact contention resolution pressure from Cadence import manifests" do
    report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "recommendations" => [
        %{
          "group_id" => "station:equator_prime:contention:prior",
          "ground_station_id" => "equator_prime",
          "selected_contact_id" => "dl_selected",
          "deferred_contact_ids" => ["dl_deferred"],
          "required_downlink_mb" => 420.0
        }
      ]
    }

    manifest = CadenceImport.from_contact_contention_resolution_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp result_set do
    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: [
        %{
          scenario_id: :leo_1,
          event_type: :target_visibility,
          events: [
            %{
              type: :target_visibility,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{
                target_id: :target_a,
                target_priority: 1.0,
                max_elevation_deg: 80.0,
                minimum_elevation_deg: 10.0,
                sample_count: 3,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :target_visibility_linear_margin_interpolation,
                start_boundary: :clipped_start,
                end_boundary: :visibility_end,
                start_boundary_detail: %{
                  boundary: :clipped_start,
                  interpolation: :clipped_to_sample,
                  interpolation_fraction: 0.0,
                  sample_index: 1,
                  elevation_deg: 80.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :visibility_end,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.5,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 10.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :target_visibility,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{target_id: :target_a}
        },
        %{
          scenario_id: :leo_1,
          event_type: :ground_station_access,
          events: [
            %{
              type: :ground_station_access,
              starts_at: Epoch.new!(300.0, :tdb),
              ends_at: Epoch.new!(420.0, :tdb),
              metadata: %{
                max_elevation_deg: 70.0,
                minimum_elevation_deg: 5.0,
                sample_count: 4,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :aos_los_linear_margin_interpolation,
                start_boundary: :aos,
                end_boundary: :los,
                start_boundary_detail: %{
                  edge: :start,
                  boundary: :aos,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.25,
                  before_sample_index: 2,
                  after_sample_index: 3,
                  before_elevation_deg: 0.0,
                  after_elevation_deg: 20.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :los,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.75,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :access_windows,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
        },
        %{
          scenario_id: :other,
          event_type: :eclipse,
          events: [
            %{
              type: :eclipse,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{sample_count: 3}
            }
          ],
          source: %{shadow_model: :cylindrical_central_body_shadow}
        }
      ],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp refresh_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [%{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"}],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "cadence"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "test"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [%{"id" => "target_a", "priority" => 2.0}],
      "constraints" => %{"avoid_eclipse" => true, "min_activity_duration_s" => 60.0},
      "scoring_policy" => %{
        "target_value_weight" => 1.0,
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "resource_summaries" => [
        %{
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.9,
          "storage_capacity_mb" => 1000.0,
          "storage_used_mb" => 200.0
        }
      ],
      "prior_candidate_activities" => [
        %{
          "id" => "stale_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0
        }
      ]
    }
  end

  test "operator review and import lift contact contention resolution summaries from candidate refresh artifacts" do
    resolution_summary = fn source,
                            group_id,
                            station_id,
                            selected_contact_id,
                            deferred_contact_id ->
      %{
        "schema_contract" => "contact_contention_resolution_summary.v1",
        "model" => "artifact_only_contact_contention_resolution_summary",
        "source_artifact_type" => "contact_contention_resolution_report.v1",
        "source" => source,
        "conflict_group_count" => 1,
        "recommendation_count" => 1,
        "recommendation_group_ids" => [group_id],
        "review_group_ids" => [group_id],
        "selected_contact_ids" => [selected_contact_id],
        "selected_contact_ids_by_group_id" => %{group_id => [selected_contact_id]},
        "deferred_contact_ids" => [deferred_contact_id],
        "deferred_contact_ids_by_group_id" => %{group_id => [deferred_contact_id]},
        "review_contact_ids" => [deferred_contact_id, selected_contact_id],
        "review_contact_ids_by_group_id" => %{
          group_id => [deferred_contact_id, selected_contact_id]
        },
        "review_recommendation_count" => 1,
        "ground_station_ids_by_group_id" => %{group_id => [station_id]},
        "resource_scopes_by_group_id" => %{group_id => ["ground_station"]},
        "selection_reason_counts" => %{"highest_score_earliest_start" => 1},
        "selection_reasons_by_group_id" => %{group_id => ["highest_score_earliest_start"]},
        "selected_contact_ids_by_selection_reason" => %{
          "highest_score_earliest_start" => [selected_contact_id]
        },
        "action_counts" => %{"recommend_preferred_contact_for_operator_review" => 1},
        "actions_by_group_id" => %{
          group_id => ["recommend_preferred_contact_for_operator_review"]
        },
        "review_contact_ids_by_action" => %{
          "recommend_preferred_contact_for_operator_review" => [
            deferred_contact_id,
            selected_contact_id
          ]
        },
        "capacity_pack_required_capacity_fraction" => 0.55,
        "capacity_pack_selected_required_capacity_fraction" => 0.2,
        "capacity_pack_deferred_required_capacity_fraction" => 0.35,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "deferred" => 0.35,
          "selected" => 0.2
        },
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          station_id => 0.55
        },
        "required_capacity_fraction_source_counts" => %{
          "source_contact_candidate.required_capacity_fraction" => 2
        },
        "assumptions" => %{
          "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
          "candidate_mutation" => "none",
          "operator_authority" => "not_granted_by_summary",
          "cadence_write" => "not_performed_by_summary"
        },
        "provenance" => %{"trust_boundary" => source}
      }
    end

    direct_summary =
      resolution_summary.(
        "unit_test.contact_contention_resolution.direct",
        "station:direct:contention:1",
        "direct_station",
        "direct_selected",
        "direct_deferred"
      )

    canonical_summary =
      resolution_summary.(
        "unit_test.contact_contention_resolution.canonical",
        "station:canonical:contention:1",
        "canonical_station",
        "canonical_selected",
        "canonical_deferred"
      )

    wrapped_summary =
      resolution_summary.(
        "unit_test.contact_contention_resolution.wrapped",
        "station:wrapped:contention:1",
        "wrapped_station",
        "wrapped_selected",
        "wrapped_deferred"
      )

    nested_summary =
      resolution_summary.(
        "unit_test.contact_contention_resolution.nested",
        "station:nested:contention:1",
        "nested_station",
        "nested_selected",
        "nested_deferred"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:contact_contention_resolution_summary_handoff",
      "source_contact_contention_resolution_summary" => [direct_summary],
      "contact_contention_resolution_summary" => canonical_summary,
      "source_result_artifact" => [
        wrapped_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "contact_contention_resolution_summary" => nested_summary
        }
      ]
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    recommendation_rows =
      Enum.filter(review["rows"], &(&1["review_type"] == "contact_contention_recommendation"))

    assert length(recommendation_rows) == 4

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:contact_contention_resolution_summary_handoff",
             "contention_recommendation_count" => 4,
             "review_type_counts" => %{"contact_contention_recommendation" => 4}
           } = review

    assert Enum.sort(Enum.map(recommendation_rows, & &1["source"])) == [
             "candidate_refresh.contact_contention_resolution_summary.summary_recommendations",
             "candidate_refresh.source_contact_contention_resolution_summary[0].summary_recommendations",
             "candidate_refresh.source_result_artifact[0].summary_recommendations",
             "candidate_refresh.source_result_artifact[1].contact_contention_resolution_summary.summary_recommendations"
           ]

    assert Enum.any?(
             recommendation_rows,
             &match?(
               %{
                 "source" =>
                   "candidate_refresh.contact_contention_resolution_summary.summary_recommendations",
                 "subject_id" => "station:canonical:contention:1",
                 "ground_station_id" => "canonical_station",
                 "selected_contact_id" => "canonical_selected",
                 "selected_contact_ids" => ["canonical_selected"],
                 "deferred_contact_ids" => ["canonical_deferred"],
                 "review_contact_ids" => ["canonical_deferred", "canonical_selected"],
                 "candidate_count" => 2,
                 "selection_reason" => "highest_score_earliest_start",
                 "capacity_pack_required_capacity_fraction" => 0.55,
                 "capacity_pack_selected_required_capacity_fraction" => 0.2,
                 "capacity_pack_deferred_required_capacity_fraction" => 0.35,
                 "source_summary_schema_contract" => "contact_contention_resolution_summary.v1",
                 "source_contact_contention_resolution_summary" => %{
                   "schema_contract" => "contact_contention_resolution_summary.v1",
                   "source" => "unit_test.contact_contention_resolution.canonical",
                   "recommendation_count" => 1
                 },
                 "source_recommendation" => %{
                   "schema_contract" => "contact_contention_resolution_summary.v1",
                   "source_contact_contention_resolution_summary" => %{
                     "schema_contract" => "contact_contention_resolution_summary.v1"
                   }
                 }
               },
               &1
             )
           )

    import_rows =
      Enum.filter(
        import["rows"],
        &(&1["source_review_type"] == "contact_contention_recommendation")
      )

    assert length(import_rows) == 4

    assert %{
             "import_action_counts" => %{"review_contact_contention_resolution" => 4},
             "source_review_type_counts" => %{"contact_contention_recommendation" => 4}
           } = import

    assert Enum.all?(
             import_rows,
             &(&1["import_action"] == "review_contact_contention_resolution" and
                 &1["source_contact_contention_resolution_summary"]["schema_contract"] ==
                   "contact_contention_resolution_summary.v1" and
                 &1["source_review_row"]["source_contact_contention_resolution_summary"][
                   "schema_contract"
                 ] == "contact_contention_resolution_summary.v1")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "source report summary aggregates contact contention capacity-pack demand" do
    refresh = %{
      "source_contact_contention_resolution_report" => %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "recommendations" => [
          %{
            "group_id" => "equator_prime:contention:1",
            "ground_station_id" => "equator_prime",
            "direction" => "mixed",
            "directions" => ["Down Link", "s-band command"],
            "selected_contact_id" => "selected_contact",
            "deferred_contact_ids" => ["deferred_contact"],
            "resolution_status" => "deferred",
            "selection_reason" => "highest_score",
            "required_operator_actions" => ["review_contact_contention_resolution"],
            "source_contact_candidates" => [
              %{
                "id" => "selected_contact",
                "direction" => "Down Link",
                "ground_station_id" => "equator_prime",
                "required_capacity_percent" => "20"
              },
              %{
                "id" => "deferred_contact",
                "direction" => "s-band command",
                "ground_station_id" => "equator_prime",
                "required_capacity_fraction" => 0.35
              }
            ]
          }
        ],
        "capacity_pack_required_capacity_fraction" => 99.0,
        "capacity_pack_selected_required_capacity_fraction" => 99.0,
        "capacity_pack_deferred_required_capacity_fraction" => 99.0,
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "stale_station" => 99.0
        },
        "direction_counts" => %{"stale_direction" => 99},
        "contact_ids_by_direction" => %{"stale_direction" => ["stale_contact"]},
        "required_operator_action_counts" => %{"stale_action" => 99},
        "provenance" => %{"trust_boundary" => "ops_contention_resolution"}
      }
    }

    expected_direction_routing = %{
      "command" => %{
        "contact_count" => 1,
        "contact_ids" => ["deferred_contact"]
      },
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["selected_contact"]
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_contact_contention_resolution_contract" =>
               "contact_contention_resolution_report.v1",
             "source_report_contact_contention_resolution_count" => 1,
             "source_report_contact_contention_resolution_row_count" => 1,
             "source_report_contact_contention_resolution_paths" => [
               "source_contact_contention_resolution_report"
             ],
             "source_report_contact_contention_resolution_recommendation_count" => 1,
             "source_report_contact_contention_resolution_deferred_contact_count" => 1,
             "source_report_contact_contention_resolution_status_counts" => %{"deferred" => 1},
             "source_report_contact_contention_resolution_selection_reason_counts" => %{
               "highest_score" => 1
             },
             "source_report_contact_contention_capacity_pack_required_capacity_fraction" => 0.55,
             "source_report_contact_contention_capacity_pack_selected_required_capacity_fraction" =>
               0.2,
             "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction" =>
               0.35,
             "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_ground_station" =>
               %{"equator_prime" => 0.55},
             "source_report_contact_contention_capacity_pack_selected_required_capacity_fraction_by_ground_station" =>
               %{"equator_prime" => 0.2},
             "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction_by_ground_station" =>
               %{"equator_prime" => 0.35},
             "source_report_contact_contention_resolution_selected_contact_ids" => [
               "selected_contact"
             ],
             "source_report_contact_contention_resolution_deferred_contact_ids" => [
               "deferred_contact"
             ],
             "source_report_contact_contention_resolution_selected_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["selected_contact"]},
             "source_report_contact_contention_resolution_deferred_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["deferred_contact"]},
             "source_report_contact_contention_resolution_direction_counts" => %{
               "command" => 1,
               "downlink" => 1
             },
             "source_report_contact_contention_resolution_contact_ids_by_direction" => %{
               "command" => ["deferred_contact"],
               "downlink" => ["selected_contact"]
             },
             "source_report_contact_contention_resolution_direction_routing" =>
               ^expected_direction_routing,
             "source_report_contact_contention_resolution_required_operator_action_counts" => %{
               "review_contact_contention_resolution" => 1
             },
             "source_report_contact_contention_resolution_branch_local_contact_contention_resolution_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_deferred_contact_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_capacity_pack_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_action_pressure" => true,
             "source_reports" => %{
               "contact_contention_resolution_report" => %{
                 "recommendation_count" => 1,
                 "deferred_contact_count" => 1,
                 "resolution_status_counts" => %{"deferred" => 1},
                 "selection_reason_counts" => %{"highest_score" => 1},
                 "capacity_pack_required_capacity_fraction" => 0.55,
                 "capacity_pack_selected_required_capacity_fraction" => 0.2,
                 "capacity_pack_deferred_required_capacity_fraction" => 0.35,
                 "selected_contact_ids" => ["selected_contact"],
                 "deferred_contact_ids" => ["deferred_contact"],
                 "selected_contact_ids_by_ground_station" => %{
                   "equator_prime" => ["selected_contact"]
                 },
                 "deferred_contact_ids_by_ground_station" => %{
                   "equator_prime" => ["deferred_contact"]
                 },
                 "direction_counts" => %{
                   "command" => 1,
                   "downlink" => 1
                 },
                 "contact_ids_by_direction" => %{
                   "command" => ["deferred_contact"],
                   "downlink" => ["selected_contact"]
                 },
                 "direction_routing" => ^expected_direction_routing,
                 "required_operator_action_counts" => %{
                   "review_contact_contention_resolution" => 1
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_contact_contention_resolution_replay_summary",
      "source" =>
        "candidate_refresh.source_report_provenance.contact_contention_resolution_report",
      "contract" => "contact_contention_resolution_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 1,
      "source_report_paths" => ["source_contact_contention_resolution_report"],
      "recommendation_count" => 1,
      "deferred_contact_count" => 1,
      "resolution_status_counts" => %{"deferred" => 1},
      "selection_reason_counts" => %{"highest_score" => 1},
      "capacity_pack_required_capacity_fraction" => 0.55,
      "capacity_pack_selected_required_capacity_fraction" => 0.2,
      "capacity_pack_deferred_required_capacity_fraction" => 0.35,
      "capacity_pack_required_capacity_fraction_by_ground_station" => %{
        "equator_prime" => 0.55
      },
      "capacity_pack_selected_required_capacity_fraction_by_ground_station" => %{
        "equator_prime" => 0.2
      },
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station" => %{
        "equator_prime" => 0.35
      },
      "selected_contact_ids" => ["selected_contact"],
      "deferred_contact_ids" => ["deferred_contact"],
      "selected_contact_ids_by_ground_station" => %{
        "equator_prime" => ["selected_contact"]
      },
      "deferred_contact_ids_by_ground_station" => %{
        "equator_prime" => ["deferred_contact"]
      },
      "direction_counts" => %{
        "command" => 1,
        "downlink" => 1
      },
      "contact_ids_by_direction" => %{
        "command" => ["deferred_contact"],
        "downlink" => ["selected_contact"]
      },
      "direction_routing" => expected_direction_routing,
      "required_operator_action_counts" => %{
        "review_contact_contention_resolution" => 1
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_contention_resolution"],
      "branch_local_contact_contention_resolution_pressure" => true,
      "branch_local_deferred_contact_pressure" => true,
      "branch_local_capacity_pack_pressure" => true,
      "branch_local_contact_contention_resolution_action_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "contact_contention_resolution_source_report_provenance_only",
        "operator_authority" => "not_granted_by_contact_contention_resolution_replay_summary",
        "contact_allocation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_contact_contention_resolution_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.contact_contention_resolution_replay_summary(refresh) ==
             replay_summary

    assert OrbitalDynamics.candidate_refresh_contact_contention_resolution_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_contact_contention_resolution_contract" =>
               "contact_contention_resolution_report.v1",
             "source_report_contact_contention_resolution_count" => 1,
             "source_report_contact_contention_resolution_row_count" => 1,
             "source_report_contact_contention_resolution_paths" => [
               "source_contact_contention_resolution_report"
             ],
             "source_report_contact_contention_resolution_recommendation_count" => 1,
             "source_report_contact_contention_resolution_deferred_contact_count" => 1,
             "source_report_contact_contention_resolution_status_counts" => %{"deferred" => 1},
             "source_report_contact_contention_resolution_selection_reason_counts" => %{
               "highest_score" => 1
             },
             "source_report_contact_contention_capacity_pack_required_capacity_fraction" => 0.55,
             "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction" =>
               0.35,
             "source_report_contact_contention_resolution_selected_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["selected_contact"]},
             "source_report_contact_contention_resolution_deferred_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["deferred_contact"]},
             "source_report_contact_contention_resolution_direction_counts" => %{
               "command" => 1,
               "downlink" => 1
             },
             "source_report_contact_contention_resolution_contact_ids_by_direction" => %{
               "command" => ["deferred_contact"],
               "downlink" => ["selected_contact"]
             },
             "source_report_contact_contention_resolution_direction_routing" =>
               ^expected_direction_routing,
             "source_report_contact_contention_resolution_required_operator_action_counts" => %{
               "review_contact_contention_resolution" => 1
             },
             "source_report_contact_contention_resolution_branch_local_contact_contention_resolution_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_deferred_contact_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_capacity_pack_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_action_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.contact_contention_resolution_replay_summary(artifact) ==
             replay_summary

    assert OrbitalDynamics.candidate_refresh_contact_contention_resolution_replay_summary(
             artifact
           ) ==
             replay_summary
  end
end
