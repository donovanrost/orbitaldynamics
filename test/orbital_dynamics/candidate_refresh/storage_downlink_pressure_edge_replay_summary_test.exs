defmodule OrbitalDynamics.CandidateRefresh.StorageDownlinkPressureEdgeReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "storage downlink pressure replay summary treats capacity-adjusted throughput as downlink pressure" do
    refresh = %{
      "source_link_capacity_report" => %{
        "schema_contract" => "link_capacity_report.v1",
        "rows" => [
          %{
            "ground_station_id" => "equator_prime",
            "direction" => "Down Link",
            "capacity_adjusted_throughput_mb" => 72.0
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_link_capacity"}
      }
    }

    summary = CandidateRefresh.storage_downlink_pressure_replay_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "capacity_adjusted_throughput_row_count" => 1,
             "capacity_adjusted_throughput_mb_total" => 72.0,
             "capacity_adjusted_throughput_mb_by_ground_station" => %{
               "equator_prime" => 72.0
             },
             "capacity_adjusted_throughput_mb_by_direction" => %{
               "downlink" => 72.0
             },
             "branch_local_capacity_adjusted_throughput_pressure" => true,
             "branch_local_downlink_pressure" => true,
             "branch_local_storage_downlink_pressure" => true,
             "branch_local_storage_pressure" => false
           } = summary

    refute summary["branch_local_downlink_shortfall_pressure"]
  end

  test "storage downlink pressure replay ignores stale capacity-pack count with empty maps" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 0,
            "capacity_pack_contact_count" => 99,
            "capacity_pack_contact_ids_by_ground_station" => %{},
            "capacity_pack_contact_ids_by_direction" => %{},
            "capacity_pack_contact_ids_by_status" => %{}
          }
        }
      }
    }

    summary = CandidateRefresh.storage_downlink_pressure_replay_summary(artifact)

    refute Map.has_key?(summary, "capacity_pack_contact_count")
    assert summary["capacity_pack_contact_ids_by_ground_station"] == %{}
    refute summary["branch_local_capacity_pack_pressure"]
    refute summary["branch_local_downlink_pressure"]
    refute summary["branch_local_storage_downlink_pressure"]
  end

  test "storage downlink pressure replay summary treats provider ID routing maps as downlink pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_resource_projection_report"],
            "resource_pressure_station_calendar_provider_ids_by_type" => %{
              "downlink_shortfall" => ["ops_calendar"]
            }
          }
        }
      }
    }

    summary = CandidateRefresh.storage_downlink_pressure_replay_summary(artifact)

    assert summary["resource_pressure_station_calendar_provider_ids_by_type"] == %{
             "downlink_shortfall" => ["ops_calendar"]
           }

    assert summary["branch_local_downlink_pressure"]
    assert summary["branch_local_downlink_shortfall_pressure"]
    assert summary["branch_local_storage_downlink_pressure"]
    refute summary["branch_local_storage_pressure"]
  end

  test "storage downlink pressure replay summary treats actual throughput as downlink pressure" do
    refresh = %{
      "source_link_capacity_report" => %{
        "schema_contract" => "link_capacity_report.v1",
        "rows" => [
          %{
            "ground_station_id" => "equator_prime",
            "actual_throughput_mb" => 18.0,
            "actual_throughput_contact_id" => "actual_contact_only"
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_link_capacity"}
      }
    }

    summary = CandidateRefresh.storage_downlink_pressure_replay_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 1,
             "actual_throughput_row_count" => 1,
             "actual_throughput_contact_id_counts" => %{"actual_contact_only" => 1},
             "branch_local_actual_throughput_pressure" => true,
             "branch_local_downlink_pressure" => true,
             "branch_local_storage_downlink_pressure" => true,
             "branch_local_storage_pressure" => false
           } = summary

    refute summary["branch_local_capacity_adjusted_throughput_pressure"]
    refute summary["branch_local_downlink_shortfall_pressure"]
  end

  test "storage downlink pressure replay summary treats actual throughput ID lists as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_link_capacity_report"],
            "actual_throughput_row_count" => 0,
            "actual_throughput_contact_id_counts" => %{},
            "actual_throughput_contact_ids" => ["actual_contact_only"],
            "actual_throughput_source_window_ids" => ["window_actual_only"],
            "actual_throughput_station_calendar_entry_ids" => ["station_entry_actual_only"],
            "actual_throughput_station_calendar_provider_entry_ids" => [
              "provider_entry_actual_only"
            ],
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_link_capacity"]
          }
        }
      }
    }

    summary = CandidateRefresh.storage_downlink_pressure_replay_summary(artifact)

    assert summary["actual_throughput_row_count"] == 0
    assert summary["actual_throughput_contact_id_counts"] == %{}
    assert summary["actual_throughput_contact_ids"] == ["actual_contact_only"]
    assert summary["actual_throughput_source_window_ids"] == ["window_actual_only"]

    assert summary["actual_throughput_station_calendar_entry_ids"] == [
             "station_entry_actual_only"
           ]

    assert summary["actual_throughput_station_calendar_provider_entry_ids"] == [
             "provider_entry_actual_only"
           ]

    assert summary["branch_local_actual_throughput_pressure"]
    assert summary["branch_local_downlink_pressure"]
    assert summary["branch_local_storage_downlink_pressure"]
    refute summary["branch_local_storage_pressure"]
    refute summary["branch_local_capacity_adjusted_throughput_pressure"]
    refute summary["branch_local_downlink_shortfall_pressure"]
  end

  test "storage downlink pressure replay summary treats each actual throughput ID list as pressure" do
    Enum.each(
      [
        {"actual_throughput_contact_ids", ["actual_contact_only"]},
        {"actual_throughput_source_window_ids", ["window_actual_only"]},
        {"actual_throughput_station_calendar_entry_ids", ["station_entry_actual_only"]},
        {"actual_throughput_station_calendar_provider_entry_ids", ["provider_entry_actual_only"]}
      ],
      fn {field, ids} ->
        artifact = %{
          "schema_contract" => "candidate_refresh.v1",
          "provenance" => %{
            "source_reports" => %{
              "link_capacity_report" => %{
                "contract" => "link_capacity_report.v1",
                "count" => 1,
                "row_count" => 0,
                "paths" => ["source_link_capacity_report"],
                "actual_throughput_row_count" => 0,
                "actual_throughput_contact_id_counts" => %{},
                field => ids,
                "trust_boundary_status" => "declared",
                "trust_boundaries" => ["ops_link_capacity"]
              }
            }
          }
        }

        summary = CandidateRefresh.storage_downlink_pressure_replay_summary(artifact)

        assert summary["actual_throughput_row_count"] == 0
        assert summary["actual_throughput_contact_id_counts"] == %{}
        assert summary[field] == ids
        assert summary["branch_local_actual_throughput_pressure"]
        assert summary["branch_local_downlink_pressure"]
        assert summary["branch_local_storage_downlink_pressure"]
        refute summary["branch_local_storage_pressure"]
        refute summary["branch_local_capacity_adjusted_throughput_pressure"]
        refute summary["branch_local_downlink_shortfall_pressure"]
      end
    )
  end

  test "storage downlink pressure replay summary treats selected contact counts as downlink pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_link_capacity_report"],
            "selected_contact_id_counts" => %{"selected_contact_only" => 1},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_link_capacity"]
          }
        }
      }
    }

    summary = CandidateRefresh.storage_downlink_pressure_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0
    assert summary["selected_contact_id_counts"] == %{"selected_contact_only" => 1}
    assert summary["branch_local_downlink_pressure"]
    assert summary["branch_local_storage_downlink_pressure"]
    refute summary["branch_local_actual_throughput_pressure"]
    refute summary["branch_local_capacity_adjusted_throughput_pressure"]
    refute summary["branch_local_storage_pressure"]
    refute summary["branch_local_downlink_shortfall_pressure"]
  end

  test "storage downlink pressure replay summary treats capacity-pack direction maps as pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 0,
            "paths" => ["source_contact_allocation_report"],
            "capacity_pack_required_capacity_fraction_by_direction" => %{
              "downlink" => 0.6
            },
            "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
              "downlink" => 0.25
            },
            "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
              "downlink" => 0.35
            },
            "capacity_pack_contact_ids_by_direction" => %{
              "downlink" => ["selected_pack_contact", "deferred_contact"]
            },
            "capacity_pack_selected_contact_ids_by_direction" => %{
              "downlink" => ["selected_pack_contact"]
            },
            "capacity_pack_deferred_contact_ids_by_direction" => %{
              "downlink" => ["deferred_contact"]
            },
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_contact_allocation"]
          }
        }
      }
    }

    summary = CandidateRefresh.storage_downlink_pressure_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 0

    assert summary["capacity_pack_required_capacity_fraction_by_direction"] == %{
             "downlink" => 0.6
           }

    assert summary["capacity_pack_selected_required_capacity_fraction_by_direction"] == %{
             "downlink" => 0.25
           }

    assert summary["capacity_pack_deferred_required_capacity_fraction_by_direction"] == %{
             "downlink" => 0.35
           }

    assert summary["capacity_pack_contact_ids_by_direction"] == %{
             "downlink" => ["selected_pack_contact", "deferred_contact"]
           }

    assert summary["capacity_pack_selected_contact_ids_by_direction"] == %{
             "downlink" => ["selected_pack_contact"]
           }

    assert summary["capacity_pack_deferred_contact_ids_by_direction"] == %{
             "downlink" => ["deferred_contact"]
           }

    assert summary["branch_local_downlink_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]
    assert summary["branch_local_storage_downlink_pressure"]
    refute summary["branch_local_storage_pressure"]
    refute summary["branch_local_downlink_shortfall_pressure"]
  end

  test "storage downlink pressure replay summary treats resource activity routing as family pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_resource_projection_report"],
            "projected_resource_count" => 0,
            "invalid_activity_input_count" => 0,
            "invalid_resource_summary_input_count" => 0,
            "resource_pressure_status_counts" => %{},
            "ground_station_counts" => %{},
            "resource_projection_spacecraft_counts" => %{},
            "resource_pressure_type_counts" => %{},
            "resource_pressure_activity_id_counts" => %{"activity_pressure_only" => 1},
            "resource_pressure_direction_counts" => %{},
            "resource_pressure_activity_ids_by_direction" => %{},
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_resource_projection"]
          }
        }
      }
    }

    summary = CandidateRefresh.storage_downlink_pressure_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["source_report_row_count"] == 1
    assert summary["resource_pressure_activity_id_counts"] == %{"activity_pressure_only" => 1}
    assert summary["resource_pressure_activity_ids_by_direction"] == %{}
    assert summary["branch_local_storage_downlink_pressure"]
    assert summary["branch_local_resource_activity_pressure"]
    refute summary["branch_local_storage_pressure"]
    refute summary["branch_local_downlink_pressure"]
    refute summary["branch_local_downlink_shortfall_pressure"]
  end

  test "storage downlink pressure replay summary preserves explicit zero family identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => [],
            "trust_boundary_status" => "declared"
          },
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => [],
            "trust_boundary_status" => "declared"
          },
          "resource_projection_report" => %{
            "contract" => "resource_projection_report.v1",
            "count" => 0,
            "row_count" => 0,
            "paths" => [],
            "trust_boundary_status" => "declared"
          }
        }
      }
    }

    summary = CandidateRefresh.storage_downlink_pressure_replay_summary(artifact)

    assert %{
             "source_report_count" => 0,
             "source_report_row_count" => 0,
             "source_report_counts_by_family" => %{
               "contact_allocation_report" => 0,
               "link_capacity_report" => 0,
               "resource_projection_report" => 0
             },
             "source_report_row_counts_by_family" => %{
               "contact_allocation_report" => 0,
               "link_capacity_report" => 0,
               "resource_projection_report" => 0
             },
             "source_report_paths" => [],
             "source_report_paths_by_family" => %{},
             "source_report_counts_by_trust_boundary_status" => %{"declared" => 0}
           } = summary

    refute summary["branch_local_storage_downlink_pressure"]
  end

  test "storage downlink pressure replay summary omits missing family identity counts" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "paths" => ["source_contact_allocation_report"],
            "trust_boundary_status" => "declared",
            "capacity_pack_contact_ids_by_direction" => %{"downlink" => ["contact_only"]}
          },
          "link_capacity_report" => %{
            "contract" => "link_capacity_report.v1",
            "count" => nil,
            "row_count" => nil,
            "paths" => nil,
            "trust_boundary_status" => "declared",
            "selected_contact_id_counts" => %{"selected_only" => 1}
          }
        }
      }
    }

    summary = CandidateRefresh.storage_downlink_pressure_replay_summary(artifact)

    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_counts_by_family"] == %{}
    assert summary["source_report_row_counts_by_family"] == %{}
    assert summary["source_report_counts_by_trust_boundary_status"] == %{}
    assert summary["source_report_paths"] == ["source_contact_allocation_report"]

    assert summary["source_report_paths_by_family"] == %{
             "contact_allocation_report" => ["source_contact_allocation_report"]
           }

    assert summary["capacity_pack_contact_ids_by_direction"] == %{"downlink" => ["contact_only"]}
    assert summary["selected_contact_id_counts"] == %{"selected_only" => 1}
    assert summary["branch_local_storage_downlink_pressure"]
    assert summary["branch_local_downlink_pressure"]
  end

  test "storage downlink pressure replay summary is clear when pressure provenance is absent" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => %{}}
    }

    summary = CandidateRefresh.storage_downlink_pressure_replay_summary(artifact)

    assert summary["source_report_count"] == 0
    assert summary["source_report_row_count"] == 0
    assert summary["source_report_paths"] == []
    assert summary["source_report_families"] == []
    refute summary["branch_local_storage_downlink_pressure"]
    refute summary["branch_local_storage_pressure"]
    refute summary["branch_local_downlink_pressure"]
  end
end
