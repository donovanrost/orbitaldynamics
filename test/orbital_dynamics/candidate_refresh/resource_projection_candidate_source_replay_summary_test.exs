defmodule OrbitalDynamics.CandidateRefresh.ResourceProjectionCandidateSourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "resource projection replay reads strategy branch candidate-source summary metadata" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_projection_report" => %{
              "contract" => "resource_projection_report.v1",
              "count" => 1,
              "row_count" => 3,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_resource_projection_report"
              ],
              "projected_resource_count" => 2,
              "source_artifact_type_counts" => %{"resource_summary.v1" => 1},
              "source_flow_summary_model_counts" => %{
                "artifact_only_resource_projection_flow_summary" => 1
              },
              "invalid_activity_input_count" => 1,
              "invalid_resource_summary_input_count" => 1,
              "resource_pressure_status_counts" => %{"downlink_shortfall" => 1},
              "ground_station_counts" => %{"equator_prime" => 1},
              "resource_projection_spacecraft_counts" => %{"leo_1" => 1},
              "resource_pressure_type_counts" => %{"storage_pressure" => 1},
              "resource_pressure_activity_id_counts" => %{"branch_activity" => 1},
              "resource_pressure_activity_ids_by_status" => %{
                "downlink_shortfall" => ["branch_activity"]
              },
              "resource_pressure_activity_ids_by_type" => %{
                "storage_pressure" => ["branch_activity"]
              },
              "resource_pressure_activity_ids_by_ground_station" => %{
                "equator_prime" => ["branch_activity"]
              },
              "resource_pressure_activity_ids_by_spacecraft" => %{
                "leo_1" => ["branch_activity"]
              },
              "resource_pressure_direction_counts" => %{"downlink" => 1},
              "resource_pressure_directions" => ["downlink"],
              "resource_pressure_activity_ids_by_direction" => %{
                "downlink" => ["branch_activity"]
              },
              "resource_pressure_direction_routing" => %{
                "downlink" => %{
                  "pressure_count" => 1,
                  "activity_ids" => ["branch_activity"]
                }
              },
              "resource_pressure_ground_station_ids_by_type" => %{
                "storage_pressure" => ["equator_prime"]
              },
              "resource_pressure_source_window_ids_by_status" => %{
                "downlink_shortfall" => ["branch_window"]
              },
              "resource_pressure_source_window_ids_by_type" => %{
                "storage_pressure" => ["branch_window"]
              },
              "resource_pressure_station_calendar_entry_ids_by_status" => %{
                "downlink_shortfall" => ["branch_station_entry"]
              },
              "resource_pressure_station_calendar_entry_ids_by_type" => %{
                "storage_pressure" => ["branch_station_entry"]
              },
              "resource_pressure_station_calendar_provider_ids_by_status" => %{
                "downlink_shortfall" => ["branch_provider"]
              },
              "resource_pressure_station_calendar_provider_ids_by_type" => %{
                "storage_pressure" => ["branch_provider"]
              },
              "resource_pressure_station_calendar_provider_entry_ids_by_status" => %{
                "downlink_shortfall" => ["branch_provider_entry"]
              },
              "resource_pressure_station_calendar_provider_entry_ids_by_type" => %{
                "storage_pressure" => ["branch_provider_entry"]
              },
              "invalid_activity_input_ids" => ["bad_branch_activity"],
              "invalid_resource_summary_input_ids" => ["bad_branch_resource"],
              "trust_boundary_status" => "declared",
              "trust_boundaries" => ["branch_resource_projection"]
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_resource_projection_report"],
            "projected_resource_count" => 99,
            "resource_pressure_activity_id_counts" => %{"provenance_activity" => 9}
          }
        }
      }
    }

    summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_projection_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 3

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_resource_projection_report"
           ]

    assert summary["projected_resource_count"] == 2
    assert summary["source_artifact_type_counts"] == %{"resource_summary.v1" => 1}

    assert summary["source_flow_summary_model_counts"] == %{
             "artifact_only_resource_projection_flow_summary" => 1
           }

    assert summary["invalid_activity_input_count"] == 1
    assert summary["invalid_resource_summary_input_count"] == 1
    assert summary["resource_pressure_status_counts"] == %{"downlink_shortfall" => 1}
    assert summary["ground_station_counts"] == %{"equator_prime" => 1}
    assert summary["resource_projection_spacecraft_counts"] == %{"leo_1" => 1}
    assert summary["resource_pressure_type_counts"] == %{"storage_pressure" => 1}
    assert summary["resource_pressure_activity_id_counts"] == %{"branch_activity" => 1}

    assert summary["resource_pressure_activity_ids_by_status"] == %{
             "downlink_shortfall" => ["branch_activity"]
           }

    assert summary["resource_pressure_activity_ids_by_type"] == %{
             "storage_pressure" => ["branch_activity"]
           }

    assert summary["resource_pressure_activity_ids_by_ground_station"] == %{
             "equator_prime" => ["branch_activity"]
           }

    assert summary["resource_pressure_activity_ids_by_spacecraft"] == %{
             "leo_1" => ["branch_activity"]
           }

    assert summary["resource_pressure_direction_counts"] == %{"downlink" => 1}
    assert summary["resource_pressure_directions"] == ["downlink"]

    assert summary["resource_pressure_activity_ids_by_direction"] == %{
             "downlink" => ["branch_activity"]
           }

    assert summary["resource_pressure_direction_routing"] == %{
             "downlink" => %{
               "pressure_count" => 1,
               "activity_ids" => ["branch_activity"]
             }
           }

    assert summary["resource_pressure_ground_station_ids_by_type"] == %{
             "storage_pressure" => ["equator_prime"]
           }

    assert summary["resource_pressure_source_window_ids_by_status"] == %{
             "downlink_shortfall" => ["branch_window"]
           }

    assert summary["resource_pressure_source_window_ids_by_type"] == %{
             "storage_pressure" => ["branch_window"]
           }

    assert summary["resource_pressure_station_calendar_entry_ids_by_status"] == %{
             "downlink_shortfall" => ["branch_station_entry"]
           }

    assert summary["resource_pressure_station_calendar_entry_ids_by_type"] == %{
             "storage_pressure" => ["branch_station_entry"]
           }

    assert summary["resource_pressure_station_calendar_provider_ids_by_status"] == %{
             "downlink_shortfall" => ["branch_provider"]
           }

    assert summary["resource_pressure_station_calendar_provider_ids_by_type"] == %{
             "storage_pressure" => ["branch_provider"]
           }

    assert summary["resource_pressure_station_calendar_provider_entry_ids_by_status"] == %{
             "downlink_shortfall" => ["branch_provider_entry"]
           }

    assert summary["resource_pressure_station_calendar_provider_entry_ids_by_type"] == %{
             "storage_pressure" => ["branch_provider_entry"]
           }

    assert summary["invalid_activity_input_ids"] == ["bad_branch_activity"]
    assert summary["invalid_resource_summary_input_ids"] == ["bad_branch_resource"]
    assert summary["trust_boundary_status"] == "declared"
    assert summary["trust_boundaries"] == ["branch_resource_projection"]
    assert summary["branch_local_resource_projection_pressure"]
    assert summary["branch_local_projected_resource_pressure"]
    assert summary["branch_local_invalid_resource_projection_pressure"]
    assert summary["branch_local_activity_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_projection_candidate_source_report_summary_only"

    assert OrbitalDynamics.candidate_refresh_resource_projection_replay_summary(artifact) ==
             summary
  end

  test "resource projection replay labels direct candidate-source summary metadata" do
    candidate_source = %{
      "candidate_refresh_request_source_report_summary" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 1,
            "paths" => [
              "candidate_source.candidate_refresh_request.source_resource_projection_report"
            ],
            "resource_pressure_direction_routing" => %{
              "downlink" => %{
                "pressure_count" => 1,
                "activity_ids" => ["direct_branch_activity"]
              }
            }
          }
        }
      }
    }

    summary = CandidateRefresh.resource_projection_replay_summary(candidate_source)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_projection_report"

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_resource_projection_report"
           ]

    assert summary["resource_pressure_direction_routing"] == %{
             "downlink" => %{
               "pressure_count" => 1,
               "activity_ids" => ["direct_branch_activity"]
             }
           }

    assert summary["branch_local_resource_projection_pressure"]
    assert summary["branch_local_projected_resource_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_projection_candidate_source_report_summary_only"
  end

  test "resource projection replay falls back when branch summary is empty" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_projection_report" => %{},
            "link_capacity_report" => %{
              "contract" => "link_capacity_report.v1",
              "count" => 1
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_resource_projection_report"],
            "invalid_activity_input_count" => 1,
            "invalid_activity_input_ids" => ["provenance_bad_activity"]
          }
        }
      }
    }

    summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.source_report_provenance.resource_projection_report"

    assert summary["source_report_paths"] == ["source_resource_projection_report"]
    assert summary["invalid_activity_input_count"] == 1
    assert summary["invalid_activity_input_ids"] == ["provenance_bad_activity"]
    assert summary["branch_local_resource_projection_pressure"]
    assert summary["branch_local_invalid_resource_projection_pressure"]
    refute summary["branch_local_projected_resource_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_projection_source_report_provenance_only"
  end

  test "resource projection replay prefers partial branch family over provenance" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "candidate_source" => %{
        "candidate_refresh_request_source_report_summary" => %{
          "source_reports" => %{
            "resource_projection_report" => %{
              "count" => 1,
              "paths" => [
                "candidate_source.candidate_refresh_request.source_resource_projection_report"
              ],
              "resource_pressure_source_window_ids_by_type" => %{
                "downlink_shortfall" => ["branch_window"]
              }
            }
          }
        }
      },
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 9,
            "row_count" => 9,
            "paths" => ["source_resource_projection_report"],
            "projected_resource_count" => 9,
            "resource_pressure_source_window_ids_by_type" => %{
              "storage_pressure" => ["provenance_window"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    assert summary["source"] ==
             "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.resource_projection_report"

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["source_report_paths"] == [
             "candidate_source.candidate_refresh_request.source_resource_projection_report"
           ]

    assert summary["projected_resource_count"] == 0

    assert summary["resource_pressure_source_window_ids_by_type"] == %{
             "downlink_shortfall" => ["branch_window"]
           }

    assert summary["branch_local_resource_projection_pressure"]
    assert summary["branch_local_projected_resource_pressure"]
    refute summary["branch_local_invalid_resource_projection_pressure"]

    assert summary["assumptions"]["replay_scope"] ==
             "resource_projection_candidate_source_report_summary_only"
  end
end
