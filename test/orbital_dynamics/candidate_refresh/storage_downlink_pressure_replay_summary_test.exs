defmodule OrbitalDynamics.CandidateRefresh.StorageDownlinkPressureReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "storage downlink pressure replay summary composes allocation link and projection provenance" do
    refresh = %{
      "source_contact_allocation_report" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "rows" => [
          %{
            "contact_id" => "selected_pack_contact",
            "allocation_status" => "allocated",
            "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
            "ground_station_id" => "equator_prime",
            "direction" => "Down Link",
            "required_capacity_fraction" => 0.25,
            "required_capacity_fraction_source" => "contact_required_capacity_fraction"
          },
          %{
            "contact_id" => "deferred_contact",
            "allocation_status" => "deferred",
            "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
            "ground_station_id" => "equator_prime",
            "direction" => "Down Link",
            "required_capacity_fraction" => 0.35,
            "required_capacity_fraction_source" => "capacity_model"
          }
        ],
        "reduced_capacity_pack_groups" => [
          %{
            "contention_group_id" => "pack_equator_prime",
            "pack_status" => "capacity_limited",
            "selected_contact_ids" => ["selected_pack_contact"],
            "deferred_contact_ids" => ["deferred_contact"]
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_contact_allocation"}
      },
      "source_link_capacity_report" => %{
        "schema_contract" => "link_capacity_report.v1",
        "rows" => [
          %{
            "ground_station_id" => "equator_prime",
            "direction" => "Down Link",
            "capacity_adjusted_throughput_mb" => 65.0,
            "selected_capacity_adjusted_throughput_mb" => 25.0,
            "unused_capacity_adjusted_throughput_mb" => 40.0,
            "actual_throughput_mb" => 12.0,
            "selected_downlink_shortfall_mb" => 12.0,
            "selected_contact_id" => "deferred_contact",
            "downlink_requirement_status" => "selected_shortfall"
          }
        ],
        "provenance" => %{"trust_boundary" => "ops_link_capacity"}
      },
      "source_resource_projection_report" => %{
        "schema_contract" => "resource_projection_report.v1",
        "projected_resources" => [
          %{
            "spacecraft_id" => "leo_1",
            "resource_pressure_status" => "storage_shortfall",
            "resource_pressure_types" => ["storage_shortfall", "downlink_shortfall"],
            "first_resource_pressure_activity_id" => "obs_1",
            "first_resource_pressure_direction" => "Down Link",
            "first_resource_pressure_ground_station_id" => "equator_prime"
          }
        ],
        "resource_pressure_station_calendar_provider_entry_ids_by_type" => %{
          "downlink_shortfall" => ["provider_api_window_1"]
        },
        "resource_pressure_station_calendar_provider_ids_by_type" => %{
          "downlink_shortfall" => ["ops_calendar_api"]
        },
        "resource_pressure_station_calendar_entry_ids_by_type" => %{
          "downlink_shortfall" => ["station_api_window_1"]
        },
        "resource_pressure_source_window_ids_by_type" => %{
          "downlink_shortfall" => ["source_window_1"]
        },
        "resource_pressure_ground_station_ids_by_type" => %{
          "downlink_shortfall" => ["equator_prime"]
        },
        "provenance" => %{"trust_boundary" => "ops_resource_projection"}
      }
    }

    summary = CandidateRefresh.source_report_summary(refresh)
    replay_summary = CandidateRefresh.storage_downlink_pressure_replay_summary(refresh)

    assert OrbitalDynamics.candidate_refresh_storage_downlink_pressure_replay_summary(refresh) ==
             replay_summary

    assert %{
             "model" =>
               "artifact_only_candidate_refresh_storage_downlink_pressure_replay_summary",
             "source" => "candidate_refresh.source_report_provenance.storage_downlink_pressure",
             "source_report_count" => 3,
             "source_report_row_count" => 4,
             "source_report_families" => [
               "contact_allocation_report",
               "link_capacity_report",
               "resource_projection_report"
             ],
             "source_report_contracts" => [
               "contact_allocation_report.v1",
               "link_capacity_report.v1",
               "resource_projection_report.v1"
             ],
             "source_report_counts_by_family" => %{
               "contact_allocation_report" => 1,
               "link_capacity_report" => 1,
               "resource_projection_report" => 1
             },
             "source_report_row_counts_by_family" => %{
               "contact_allocation_report" => 2,
               "link_capacity_report" => 1,
               "resource_projection_report" => 1
             },
             "source_report_paths" => [
               "source_contact_allocation_report",
               "source_link_capacity_report",
               "source_resource_projection_report"
             ],
             "source_report_counts_by_trust_boundary_status" => %{"declared" => 3},
             "trust_boundaries" => [
               "ops_contact_allocation",
               "ops_link_capacity",
               "ops_resource_projection"
             ],
             "contact_allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
             "capacity_pack_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "capacity_pack_contact_status_counts" => %{
               "deferred_by_reduced_station_capacity_pack" => 1,
               "selected_by_reduced_station_capacity_pack" => 1
             },
             "capacity_pack_required_capacity_fraction" => 0.6,
             "capacity_pack_selected_required_capacity_fraction" => 0.25,
             "capacity_pack_deferred_required_capacity_fraction" => 0.35,
             "capacity_pack_required_capacity_fraction_by_ground_station" => %{
               "equator_prime" => 0.6
             },
             "capacity_pack_required_capacity_fraction_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => 0.35,
               "selected_by_reduced_station_capacity_pack" => 0.25
             },
             "capacity_pack_required_capacity_fraction_by_direction" => %{"downlink" => 0.6},
             "capacity_pack_selected_required_capacity_fraction_by_ground_station" => %{
               "equator_prime" => 0.25
             },
             "capacity_pack_deferred_required_capacity_fraction_by_ground_station" => %{
               "equator_prime" => 0.35
             },
             "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.25
             },
             "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.35
             },
             "capacity_pack_contact_count" => 2,
             "capacity_pack_contact_ids_by_ground_station" => %{
               "equator_prime" => ["deferred_contact", "selected_pack_contact"]
             },
             "capacity_pack_contact_ids_by_direction" => %{
               "downlink" => ["deferred_contact", "selected_pack_contact"]
             },
             "capacity_pack_contact_ids_by_status" => %{
               "deferred_by_reduced_station_capacity_pack" => ["deferred_contact"],
               "selected_by_reduced_station_capacity_pack" => ["selected_pack_contact"]
             },
             "capacity_pack_selected_contact_ids_by_ground_station" => %{
               "equator_prime" => ["selected_pack_contact"]
             },
             "capacity_pack_deferred_contact_ids_by_ground_station" => %{
               "equator_prime" => ["deferred_contact"]
             },
             "capacity_pack_selected_contact_ids_by_direction" => %{
               "downlink" => ["selected_pack_contact"]
             },
             "capacity_pack_deferred_contact_ids_by_direction" => %{
               "downlink" => ["deferred_contact"]
             },
             "reduced_capacity_packed_contact_ids" => ["selected_pack_contact"],
             "reduced_capacity_deferred_contact_ids" => ["deferred_contact"],
             "reduced_capacity_pack_group_count" => 1,
             "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1},
             "capacity_pack_group_ids" => ["pack_equator_prime"],
             "capacity_pack_group_ids_by_status" => %{
               "capacity_limited" => ["pack_equator_prime"]
             },
             "required_capacity_fraction_source_counts" => %{
               "capacity_model" => 1,
               "contact_required_capacity_fraction" => 1
             },
             "required_capacity_fraction_contact_ids_by_source" => %{
               "capacity_model" => ["deferred_contact"],
               "contact_required_capacity_fraction" => ["selected_pack_contact"]
             },
             "selected_shortfall_row_count" => 1,
             "actual_shortfall_row_count" => 0,
             "actual_throughput_row_count" => 1,
             "capacity_adjusted_throughput_row_count" => 1,
             "downlink_requirement_status_counts" => %{"selected_shortfall" => 1},
             "capacity_adjusted_throughput_mb_total" => 65.0,
             "selected_capacity_adjusted_throughput_mb_total" => 25.0,
             "unused_capacity_adjusted_throughput_mb_total" => 40.0,
             "capacity_adjusted_throughput_mb_by_ground_station" => %{
               "equator_prime" => 65.0
             },
             "selected_capacity_adjusted_throughput_mb_by_ground_station" => %{
               "equator_prime" => 25.0
             },
             "unused_capacity_adjusted_throughput_mb_by_ground_station" => %{
               "equator_prime" => 40.0
             },
             "capacity_adjusted_throughput_mb_by_direction" => %{
               "downlink" => 65.0
             },
             "selected_capacity_adjusted_throughput_mb_by_direction" => %{
               "downlink" => 25.0
             },
             "unused_capacity_adjusted_throughput_mb_by_direction" => %{
               "downlink" => 40.0
             },
             "direction_counts" => %{"downlink" => 1},
             "contact_ids_by_direction" => %{"downlink" => ["deferred_contact"]},
             "selected_contact_id_counts" => %{"deferred_contact" => 1},
             "actual_throughput_contact_id_counts" => %{},
             "resource_projection_spacecraft_counts" => %{"leo_1" => 1},
             "ground_station_counts" => %{"equator_prime" => 2},
             "resource_pressure_activity_id_counts" => %{"obs_1" => 1},
             "resource_pressure_direction_counts" => %{"downlink" => 1},
             "resource_pressure_activity_ids_by_direction" => %{
               "downlink" => ["obs_1"]
             },
             "resource_pressure_ground_station_ids_by_type" => %{
               "downlink_shortfall" => ["equator_prime"],
               "storage_shortfall" => ["equator_prime"]
             },
             "resource_pressure_source_window_ids_by_type" => %{
               "downlink_shortfall" => ["source_window_1"]
             },
             "resource_pressure_station_calendar_entry_ids_by_type" => %{
               "downlink_shortfall" => ["station_api_window_1"]
             },
             "resource_pressure_station_calendar_provider_ids_by_type" => %{
               "downlink_shortfall" => ["ops_calendar_api"]
             },
             "resource_pressure_station_calendar_provider_entry_ids_by_type" => %{
               "downlink_shortfall" => ["provider_api_window_1"]
             },
             "storage_pressure_status_counts" => %{"storage_shortfall" => 1},
             "storage_pressure_type_counts" => %{"storage_shortfall" => 1},
             "downlink_pressure_status_counts" => %{},
             "downlink_pressure_type_counts" => %{"downlink_shortfall" => 1},
             "branch_local_storage_downlink_pressure" => true,
             "branch_local_storage_pressure" => true,
             "branch_local_downlink_pressure" => true,
             "branch_local_capacity_pack_pressure" => true,
             "branch_local_downlink_shortfall_pressure" => true,
             "branch_local_capacity_adjusted_throughput_pressure" => true,
             "branch_local_actual_throughput_pressure" => true,
             "branch_local_resource_activity_pressure" => true,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
               "replay_scope" =>
                 "contact_allocation_link_capacity_resource_projection_source_report_provenance_only",
               "operator_authority" => "not_granted_by_storage_downlink_pressure_replay_summary",
               "contact_allocation" => "not_performed_by_summary",
               "resource_projection" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "import_approval" => "not_granted_by_storage_downlink_pressure_replay_summary",
               "cadence_write" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary"
             }
           } = replay_summary

    assert summary[
             "source_report_contact_allocation_capacity_pack_selected_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["selected_pack_contact"]}

    assert summary[
             "source_report_contact_allocation_capacity_pack_selected_contact_ids_by_direction"
           ] == %{"downlink" => ["selected_pack_contact"]}

    assert summary[
             "source_report_contact_allocation_capacity_pack_deferred_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["deferred_contact"]}

    assert summary[
             "source_report_contact_allocation_capacity_pack_deferred_contact_ids_by_direction"
           ] == %{"downlink" => ["deferred_contact"]}

    assert summary[
             "source_report_contact_allocation_capacity_pack_contact_ids_by_ground_station"
           ] == %{"equator_prime" => ["deferred_contact", "selected_pack_contact"]}

    assert summary[
             "source_report_contact_allocation_capacity_pack_contact_ids_by_direction"
           ] == %{"downlink" => ["deferred_contact", "selected_pack_contact"]}

    assert summary[
             "source_report_resource_projection_resource_pressure_ground_station_ids_by_type"
           ] == %{
             "downlink_shortfall" => ["equator_prime"],
             "storage_shortfall" => ["equator_prime"]
           }

    assert summary[
             "source_report_resource_projection_resource_pressure_direction_counts"
           ] == %{"downlink" => 1}

    assert summary[
             "source_report_resource_projection_resource_pressure_activity_ids_by_direction"
           ] == %{"downlink" => ["obs_1"]}

    assert summary[
             "source_report_resource_projection_resource_pressure_source_window_ids_by_type"
           ] == %{"downlink_shortfall" => ["source_window_1"]}

    assert summary[
             "source_report_resource_projection_resource_pressure_station_calendar_entry_ids_by_type"
           ] == %{"downlink_shortfall" => ["station_api_window_1"]}

    assert summary[
             "source_report_resource_projection_resource_pressure_station_calendar_provider_ids_by_type"
           ] == %{"downlink_shortfall" => ["ops_calendar_api"]}

    assert summary[
             "source_report_resource_projection_resource_pressure_station_calendar_provider_entry_ids_by_type"
           ] == %{"downlink_shortfall" => ["provider_api_window_1"]}

    assert summary[
             "source_report_storage_downlink_pressure_branch_local_storage_downlink_pressure"
           ]

    assert summary["source_report_storage_downlink_pressure_branch_local_downlink_pressure"]

    assert summary[
             "source_report_storage_downlink_pressure_branch_local_capacity_adjusted_throughput_pressure"
           ]

    assert summary[
             "source_report_storage_downlink_pressure_capacity_adjusted_throughput_row_count"
           ] == 1

    assert summary[
             "source_report_storage_downlink_pressure_capacity_adjusted_throughput_mb_by_ground_station"
           ] == %{"equator_prime" => 65.0}

    assert summary[
             "source_report_storage_downlink_pressure_capacity_adjusted_throughput_mb_by_direction"
           ] == %{"downlink" => 65.0}

    assert summary[
             "source_report_storage_downlink_pressure_resource_pressure_station_calendar_provider_ids_by_type"
           ] == %{"downlink_shortfall" => ["ops_calendar_api"]}

    assert summary[
             "source_report_storage_downlink_pressure_resource_pressure_station_calendar_provider_entry_ids_by_type"
           ] == %{"downlink_shortfall" => ["provider_api_window_1"]}

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert CandidateRefresh.storage_downlink_pressure_replay_summary(artifact) == replay_summary

    assert OrbitalDynamics.candidate_refresh_storage_downlink_pressure_replay_summary(artifact) ==
             replay_summary
  end

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
