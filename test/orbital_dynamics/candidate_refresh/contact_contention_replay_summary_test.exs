defmodule OrbitalDynamics.CandidateRefresh.ContactContentionReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, CandidateRefresh, OperatorReview}

  test "contact contention replay treats preserved invalid contact IDs as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_contact_contention_report"],
            "conflict_group_count" => 0,
            "invalid_contact_input_count" => 0,
            "invalid_contact_input_ids" => ["bad_contact"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_replay_summary(artifact)

    assert summary["conflict_group_count"] == 0
    assert summary["invalid_contact_input_count"] == 0
    assert summary["invalid_contact_input_ids"] == ["bad_contact"]
    assert summary["branch_local_contact_contention_pressure"]
    assert summary["branch_local_invalid_contact_input_pressure"]
    refute summary["branch_local_contact_contention_conflict_pressure"]
    refute summary["branch_local_contact_contention_review_pressure"]
  end

  test "source report summary aggregates direct contact contention core count maps" do
    refresh = %{
      "source_contact_contention_report" => %{
        "schema_contract" => "contact_contention_report.v1",
        "conflict_groups" => [
          %{
            "group_id" => "equator_prime:contention:1",
            "resource_scope" => "ground_station",
            "ground_station_id" => "equator_prime",
            "contact_ids" => ["contention_contact_a", "contention_contact_b"],
            "required_operator_action" => "review_contact_contention",
            "source_contact_candidates" => [
              %{"id" => "contention_contact_a", "direction" => "Down Link"},
              %{"id" => "contention_contact_b", "direction" => "s-band command"}
            ]
          }
        ],
        "invalid_contact_inputs" => [
          %{
            "contact_id" => "bad_contention_contact",
            "required_operator_action" => "review_invalid_contact_contention_input"
          }
        ],
        "resource_scope_counts" => %{"stale_scope" => 99},
        "contact_contention_ground_station_counts" => %{"stale_station" => 99},
        "contact_contention_contact_id_counts" => %{"stale_contact" => 99},
        "required_operator_action_counts" => %{"stale_action" => 99},
        "provenance" => %{"trust_boundary" => "ops_contact_contention"}
      }
    }

    expected_direction_routing = %{
      "command" => %{
        "contact_count" => 1,
        "contact_ids" => ["contention_contact_b"]
      },
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["contention_contact_a"]
      }
    }

    assert %{
             "source_report_contact_contention_contract" => "contact_contention_report.v1",
             "source_report_contact_contention_count" => 1,
             "source_report_contact_contention_row_count" => 2,
             "source_report_contact_contention_paths" => ["source_contact_contention_report"],
             "source_report_contact_contention_conflict_group_count" => 1,
             "source_report_contact_contention_invalid_contact_input_count" => 1,
             "source_report_contact_contention_invalid_contact_input_ids" => [
               "bad_contention_contact"
             ],
             "source_report_contact_contention_resource_scope_counts" => %{
               "ground_station" => 1
             },
             "source_report_contact_contention_ground_station_counts" => %{
               "equator_prime" => 1
             },
             "source_report_contact_contention_contact_id_counts" => %{
               "contention_contact_a" => 1,
               "contention_contact_b" => 1
             },
             "source_report_contact_contention_required_operator_action_counts" => %{
               "review_contact_contention" => 1,
               "review_invalid_contact_contention_input" => 1
             },
             "source_report_contact_contention_direction_counts" => %{
               "command" => 1,
               "downlink" => 1
             },
             "source_report_contact_contention_branch_local_contact_contention_pressure" => true,
             "source_report_contact_contention_branch_local_conflict_pressure" => true,
             "source_report_contact_contention_branch_local_invalid_contact_input_pressure" =>
               true,
             "source_report_contact_contention_branch_local_review_pressure" => true,
             "source_report_contact_contention_contact_ids_by_direction" => %{
               "command" => ["contention_contact_b"],
               "downlink" => ["contention_contact_a"]
             },
             "source_report_contact_contention_direction_routing" => ^expected_direction_routing,
             "source_reports" => %{
               "contact_contention_report" => %{
                 "conflict_group_count" => 1,
                 "invalid_contact_input_count" => 1,
                 "resource_scope_counts" => %{"ground_station" => 1},
                 "contact_contention_ground_station_counts" => %{"equator_prime" => 1},
                 "contact_contention_contact_id_counts" => %{
                   "contention_contact_a" => 1,
                   "contention_contact_b" => 1
                 },
                 "required_operator_action_counts" => %{
                   "review_contact_contention" => 1,
                   "review_invalid_contact_contention_input" => 1
                 },
                 "direction_routing" => ^expected_direction_routing
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_contact_contention_contract" => "contact_contention_report.v1",
             "source_report_contact_contention_count" => 1,
             "source_report_contact_contention_row_count" => 2,
             "source_report_contact_contention_paths" => ["source_contact_contention_report"],
             "source_report_contact_contention_conflict_group_count" => 1,
             "source_report_contact_contention_invalid_contact_input_count" => 1,
             "source_report_contact_contention_resource_scope_counts" => %{
               "ground_station" => 1
             },
             "source_report_contact_contention_required_operator_action_counts" => %{
               "review_contact_contention" => 1,
               "review_invalid_contact_contention_input" => 1
             },
             "source_report_contact_contention_branch_local_contact_contention_pressure" => true,
             "source_report_contact_contention_branch_local_conflict_pressure" => true,
             "source_report_contact_contention_branch_local_invalid_contact_input_pressure" =>
               true,
             "source_report_contact_contention_branch_local_review_pressure" => true,
             "source_report_contact_contention_direction_routing" => ^expected_direction_routing
           } = CandidateRefresh.source_report_summary(artifact)

    replay_summary = CandidateRefresh.contact_contention_replay_summary(artifact)

    assert replay_summary["conflict_group_count"] == 1
    assert replay_summary["invalid_contact_input_count"] == 1
    assert replay_summary["resource_scope_counts"] == %{"ground_station" => 1}
    assert replay_summary["contact_contention_ground_station_counts"] == %{"equator_prime" => 1}

    assert replay_summary["contact_contention_contact_id_counts"] == %{
             "contention_contact_a" => 1,
             "contention_contact_b" => 1
           }

    assert replay_summary["required_operator_action_counts"] == %{
             "review_contact_contention" => 1,
             "review_invalid_contact_contention_input" => 1
           }

    assert replay_summary["direction_routing"] == expected_direction_routing

    assert replay_summary["branch_local_contact_contention_pressure"]
    assert replay_summary["branch_local_contact_contention_conflict_pressure"]
    assert replay_summary["branch_local_invalid_contact_input_pressure"]
    assert replay_summary["branch_local_contact_contention_review_pressure"]
  end

  test "contact contention replay summary omits contract when source report is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)
    summary = CandidateRefresh.contact_contention_replay_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_contact_contention_contract")
    refute Map.has_key?(source_summary, "source_report_contact_contention_count")
    refute Map.has_key?(source_summary, "source_report_contact_contention_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_contention_paths")
    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    refute Map.has_key?(summary, "contract")
    refute summary["branch_local_contact_contention_pressure"]
  end

  test "contact contention source summary omits missing identity counts for partial family placeholder" do
    partial_summaries = [
      %{"contract" => "contact_contention_report.v1"},
      %{"count" => 1},
      %{"row_count" => 2},
      %{"paths" => ["provenance.source_reports.contact_contention_report"]},
      %{"count" => nil, "row_count" => nil},
      %{
        "count" => nil,
        "row_count" => nil,
        "paths" => ["provenance.source_reports.contact_contention_report"]
      }
    ]

    for partial_summary <- partial_summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "contact_contention_report" => partial_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      if Map.has_key?(partial_summary, "contract") do
        assert source_summary["source_report_contact_contention_contract"] ==
                 "contact_contention_report.v1"
      else
        refute Map.has_key?(source_summary, "source_report_contact_contention_contract")
      end

      refute Map.has_key?(source_summary, "source_report_contact_contention_count")
      refute Map.has_key?(source_summary, "source_report_contact_contention_row_count")
      refute Map.has_key?(source_summary, "source_report_contact_contention_paths")
    end
  end

  test "contact contention source summary preserves explicit empty identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["provenance.source_reports.contact_contention_report"]
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_contact_contention_contract"] ==
             "contact_contention_report.v1"

    assert source_summary["source_report_contact_contention_count"] == 0
    assert source_summary["source_report_contact_contention_row_count"] == 0

    assert source_summary["source_report_contact_contention_paths"] == [
             "provenance.source_reports.contact_contention_report"
           ]
  end

  test "contact contention source summary omits missing identity paths after preserving counts" do
    summaries = [
      {"missing paths",
       %{
         "contract" => "contact_contention_report.v1",
         "count" => 1,
         "row_count" => 2
       }},
      {"nil paths",
       %{
         "contract" => "contact_contention_report.v1",
         "count" => 1,
         "row_count" => 2,
         "paths" => nil
       }}
    ]

    for {label, contact_contention_summary} <- summaries do
      artifact = %{
        "schema_contract" => "candidate_refresh.v1",
        "provenance" => %{
          "source_reports" => %{
            "contact_contention_report" => contact_contention_summary
          }
        }
      }

      source_summary = CandidateRefresh.source_report_summary(artifact)

      assert source_summary["source_report_contact_contention_contract"] ==
               "contact_contention_report.v1",
             label

      assert source_summary["source_report_contact_contention_count"] == 1, label
      assert source_summary["source_report_contact_contention_row_count"] == 2, label
      refute Map.has_key?(source_summary, "source_report_contact_contention_paths"), label
    end
  end

  test "contact contention source summary preserves empty identity paths after preserving counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 1,
            "row_count" => 2,
            "paths" => []
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_contact_contention_contract"] ==
             "contact_contention_report.v1"

    assert source_summary["source_report_contact_contention_count"] == 1
    assert source_summary["source_report_contact_contention_row_count"] == 2
    assert source_summary["source_report_contact_contention_paths"] == []
  end

  test "contact contention replay preserves pressure maps with partial identity" do
    direction_routing = %{
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["contention_contact_a"]
      }
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 1,
            "conflict_group_count" => 0,
            "invalid_contact_input_count" => 0,
            "invalid_contact_input_ids" => ["bad_contact"],
            "resource_scope_counts" => %{"ground_station" => 1},
            "contact_contention_ground_station_counts" => %{"equator_prime" => 1},
            "contact_contention_contact_id_counts" => %{"contention_contact_a" => 1},
            "direction_counts" => %{"downlink" => 1},
            "contact_ids_by_direction" => %{"downlink" => ["contention_contact_a"]},
            "direction_routing" => direction_routing,
            "required_operator_action_counts" => %{"review_contact_contention" => 1}
          }
        }
      }
    }

    source_summary = CandidateRefresh.source_report_summary(artifact)

    refute Map.has_key?(source_summary, "source_report_contact_contention_count")
    refute Map.has_key?(source_summary, "source_report_contact_contention_row_count")
    refute Map.has_key?(source_summary, "source_report_contact_contention_paths")

    assert source_summary["source_report_contact_contention_invalid_contact_input_ids"] == [
             "bad_contact"
           ]

    assert source_summary["source_report_contact_contention_resource_scope_counts"] == %{
             "ground_station" => 1
           }

    assert source_summary["source_report_contact_contention_ground_station_counts"] == %{
             "equator_prime" => 1
           }

    assert source_summary["source_report_contact_contention_contact_id_counts"] == %{
             "contention_contact_a" => 1
           }

    assert source_summary["source_report_contact_contention_direction_counts"] == %{
             "downlink" => 1
           }

    assert source_summary["source_report_contact_contention_contact_ids_by_direction"] == %{
             "downlink" => ["contention_contact_a"]
           }

    assert source_summary["source_report_contact_contention_direction_routing"] ==
             direction_routing

    assert source_summary["source_report_contact_contention_required_operator_action_counts"] ==
             %{"review_contact_contention" => 1}

    summary = CandidateRefresh.contact_contention_replay_summary(artifact)

    assert summary["branch_local_contact_contention_pressure"]
    refute summary["branch_local_contact_contention_conflict_pressure"]
    assert summary["branch_local_invalid_contact_input_pressure"]
    assert summary["branch_local_contact_contention_review_pressure"]
  end

  test "contact contention replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_contention_report" => %{
              "contract" => "contact_contention_report.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_contention_report"
              ],
              "conflict_group_count" => 2,
              "invalid_contact_input_count" => 1,
              "invalid_contact_input_ids" => ["bad_branch_contact"],
              "resource_scope_counts" => %{"ground_station" => 2},
              "contact_contention_ground_station_counts" => %{"equator_prime" => 2},
              "contact_contention_contact_id_counts" => %{
                "branch_command_contact" => 1,
                "branch_downlink_contact" => 1
              },
              "required_operator_action_counts" => %{
                "review_contact_contention" => 1,
                "review_invalid_contact_contention_input" => 1
              },
              "direction_counts" => %{"command" => 1, "downlink" => 1},
              "contact_ids_by_direction" => %{
                "command" => ["branch_command_contact"],
                "downlink" => ["branch_downlink_contact"]
              },
              "direction_routing" => %{
                "command" => %{
                  "contact_count" => 1,
                  "contact_ids" => ["branch_command_contact"]
                },
                "downlink" => %{
                  "contact_count" => 1,
                  "contact_ids" => ["branch_downlink_contact"]
                }
              },
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_contact_contention"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => ["source_contact_contention_report"],
            "conflict_group_count" => 0,
            "invalid_contact_input_count" => 0,
            "contact_contention_contact_id_counts" => %{},
            "required_operator_action_counts" => %{}
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_contention_report"
           ]

    assert summary["conflict_group_count"] == 2
    assert summary["invalid_contact_input_count"] == 1
    assert summary["invalid_contact_input_ids"] == ["bad_branch_contact"]
    assert summary["resource_scope_counts"] == %{"ground_station" => 2}
    assert summary["contact_contention_ground_station_counts"] == %{"equator_prime" => 2}

    assert summary["contact_contention_contact_id_counts"] == %{
             "branch_command_contact" => 1,
             "branch_downlink_contact" => 1
           }

    assert summary["required_operator_action_counts"] == %{
             "review_contact_contention" => 1,
             "review_invalid_contact_contention_input" => 1
           }

    assert summary["direction_counts"] == %{"command" => 1, "downlink" => 1}

    assert summary["contact_ids_by_direction"] == %{
             "command" => ["branch_command_contact"],
             "downlink" => ["branch_downlink_contact"]
           }

    assert summary["direction_routing"] == %{
             "command" => %{
               "contact_count" => 1,
               "contact_ids" => ["branch_command_contact"]
             },
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["branch_downlink_contact"]
             }
           }

    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_contact_contention"]
    assert summary["branch_local_contact_contention_pressure"]
    assert summary["branch_local_contact_contention_conflict_pressure"]
    assert summary["branch_local_invalid_contact_input_pressure"]
    assert summary["branch_local_contact_contention_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_candidate_source_report_summary_only"

    assert %{
             "source_report_contact_contention_branch_local_contact_contention_pressure" => true,
             "source_report_contact_contention_branch_local_conflict_pressure" => true,
             "source_report_contact_contention_branch_local_invalid_contact_input_pressure" =>
               true,
             "source_report_contact_contention_branch_local_review_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert OrbitalDynamics.candidate_refresh_contact_contention_replay_summary(artifact) ==
             summary
  end

  test "contact contention replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_contact_contention_report"
            ],
            "contact_ids_by_direction" => %{
              "downlink" => ["direct_branch_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_contention_report"
           ]

    assert summary["contact_ids_by_direction"] == %{
             "downlink" => ["direct_branch_contact"]
           }

    assert summary["branch_local_contact_contention_pressure"]
    refute summary["branch_local_contact_contention_conflict_pressure"]
    refute summary["branch_local_invalid_contact_input_pressure"]
    refute summary["branch_local_contact_contention_review_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_candidate_source_report_summary_only"
  end

  test "contact contention replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_contention_report" => %{},
            "contact_filter_report" => %{
              "contract" => "contact_filter_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_contact_contention_report"],
            "invalid_contact_input_count" => 1,
            "invalid_contact_input_ids" => ["provenance_bad_contact"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.contact_contention_report"

    assert summary["source_report_paths"] == ["source_contact_contention_report"]
    assert summary["invalid_contact_input_count"] == 1
    assert summary["invalid_contact_input_ids"] == ["provenance_bad_contact"]
    assert summary["branch_local_contact_contention_pressure"]
    assert summary["branch_local_invalid_contact_input_pressure"]
    refute summary["branch_local_contact_contention_conflict_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_source_report_provenance_only"
  end

  test "contact contention replay falls back when branch family is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_filter_report" => %{
              "contract" => "contact_filter_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 1,
            "paths" => ["source_contact_contention_report"],
            "contact_ids_by_direction" => %{
              "downlink" => ["provenance_contact"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.contact_contention_report"

    assert summary["source_report_paths"] == ["source_contact_contention_report"]

    assert summary["contact_ids_by_direction"] == %{
             "downlink" => ["provenance_contact"]
           }

    assert summary["branch_local_contact_contention_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_source_report_provenance_only"
  end

  test "contact contention replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "contact_contention_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_contact_contention_report"
              ],
              "resource_scope_counts" => %{"ground_station" => 1}
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_report" => %{
            "contract" => "contact_contention_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_contact_contention_report"],
            "conflict_group_count" => 9,
            "resource_scope_counts" => %{"provenance_scope" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.contact_contention_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.contact_contention_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_contact_contention_report"
           ]

    assert summary["conflict_group_count"] == 0
    assert summary["resource_scope_counts"] == %{"ground_station" => 1}
    assert summary["branch_local_contact_contention_pressure"]
    refute summary["branch_local_contact_contention_conflict_pressure"]
    refute summary["branch_local_invalid_contact_input_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "contact_contention_candidate_source_report_summary_only"
  end

  test "replays contact contention source reports from review and import containers" do
    source_report = %{
      "schema_contract" => "contact_contention_report.v1",
      "input_contact_count" => 3,
      "conflict_group_count" => 1,
      "invalid_contact_input_count" => 1,
      "conflict_groups" => [
        %{
          "id" => "station:equator_prime:contention:1",
          "resource_scope" => "ground_station",
          "ground_station_id" => "equator_prime",
          "contact_ids" => ["dl_primary", "dl_backup"],
          "required_operator_action" => "review_contact_contention",
          "trust_boundary" => "contention_group_evidence"
        }
      ],
      "invalid_contact_inputs" => [
        %{
          "contact_id" => "missing_station",
          "invalid_contact_input_reason" => "missing_ground_station_id",
          "required_operator_action" => "review_invalid_contact_contention_input",
          "trust_boundary" => "invalid_input_evidence"
        }
      ],
      "provenance" => %{"trust_boundary" => "contact_contention_report_evidence"}
    }

    review = OperatorReview.from_contact_contention_report(source_report)
    manifest = CadenceImport.from_contact_contention_report(source_report)

    refresh = %{
      "source_operator_review_package" => review,
      "source_cadence_import_manifest" => manifest
    }

    assert %{
             "paths" => [
               "source_operator_review_package.rows.source_contact_contention",
               "source_cadence_import_manifest.rows.source_contact_contention"
             ],
             "contract" => "contact_contention_report.v1",
             "count" => 2,
             "row_count" => 4,
             "conflict_group_count" => 2,
             "invalid_contact_input_count" => 2,
             "resource_scope_counts" => %{"ground_station" => 2},
             "required_operator_action_counts" => %{
               "review_contact_contention" => 2,
               "review_invalid_contact_contention_input" => 2
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "contact_contention_report_evidence",
               "contention_group_evidence",
               "invalid_input_evidence"
             ]
           } =
             refresh
             |> CandidateRefresh.source_report_summary()
             |> get_in(["source_reports", "contact_contention_report"])
  end
end
