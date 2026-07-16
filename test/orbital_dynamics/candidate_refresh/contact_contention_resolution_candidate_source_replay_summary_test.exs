defmodule OrbitalDynamics.CandidateRefresh.ContactContentionResolutionCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

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
end
