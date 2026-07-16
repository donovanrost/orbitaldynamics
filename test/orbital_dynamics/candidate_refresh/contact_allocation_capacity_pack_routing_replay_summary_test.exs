defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationCapacityPackRoutingReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary replays contact allocation capacity-pack summaries from result artifact wrappers" do
    refresh = %{
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "source_contact_allocation_capacity_pack_summary" =>
          contact_allocation_capacity_pack_summary_fixture()
          |> Map.delete("provenance"),
        "provenance" => %{"trust_boundary" => "ground_partner_api"}
      }
    }

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 3,
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "paths" => [
                   "source_result_artifact.source_contact_allocation_capacity_pack_summary"
                 ],
                 "capacity_pack_summary_schema_contract" =>
                   "contact_allocation_capacity_pack_summary.v1",
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => ["ground_partner_api"]
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_paths" => [
               "source_result_artifact.source_contact_allocation_capacity_pack_summary"
             ],
             "capacity_pack_summary_schema_contract" =>
               "contact_allocation_capacity_pack_summary.v1",
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ground_partner_api"],
             "branch_local_capacity_pack_pressure" => true,
             "assumptions" => %{
               "contact_allocation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary"
             }
           } = CandidateRefresh.contact_allocation_replay_summary(refresh)
  end

  test "contact allocation replay treats capacity-pack routing maps as family pressure" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_allocation_report" => %{
            "contract" => "contact_allocation_report.v1",
            "count" => 1,
            "row_count" => 1,
            "paths" => ["source_contact_allocation_report"],
            "blocked_row_count" => 0,
            "deferred_row_count" => 0,
            "allocation_status_counts" => %{},
            "effective_allocation_status_counts" => %{},
            "allocation_reason_counts" => %{},
            "capacity_pack_status_counts" => %{},
            "capacity_pack_required_capacity_fraction" => 0.0,
            "capacity_pack_selected_required_capacity_fraction" => 0.0,
            "capacity_pack_deferred_required_capacity_fraction" => 0.0,
            "capacity_pack_required_capacity_fraction_by_status" => %{},
            "capacity_pack_required_capacity_fraction_by_ground_station" => %{},
            "capacity_pack_selected_required_capacity_fraction_by_ground_station" => %{},
            "capacity_pack_deferred_required_capacity_fraction_by_ground_station" => %{},
            "capacity_pack_selected_contact_ids_by_ground_station" => %{},
            "capacity_pack_deferred_contact_ids_by_ground_station" => %{},
            "capacity_pack_contact_ids_by_ground_station" => %{
              "equator_prime" => ["selected_contact"]
            },
            "capacity_pack_contact_ids_by_status" => %{},
            "required_capacity_fraction_source_counts" => %{"capacity_model" => 1},
            "required_capacity_fraction_contact_ids_by_source" => %{
              "capacity_model" => ["selected_contact"]
            },
            "trust_boundary_status" => "declared",
            "trust_boundaries" => ["ops_contact_allocation"]
          }
        }
      }
    }

    summary = CandidateRefresh.contact_allocation_replay_summary(artifact)

    assert summary["source_report_count"] == 1
    assert summary["blocked_row_count"] == 0
    assert summary["deferred_row_count"] == 0
    assert summary["allocation_status_counts"] == %{}
    assert summary["capacity_pack_status_counts"] == %{}
    assert summary["capacity_pack_required_capacity_fraction"] == 0.0
    assert summary["capacity_pack_required_capacity_fraction_by_ground_station"] == %{}

    assert summary["capacity_pack_contact_ids_by_ground_station"] == %{
             "equator_prime" => ["selected_contact"]
           }

    assert summary["required_capacity_fraction_source_counts"] == %{"capacity_model" => 1}

    assert summary["required_capacity_fraction_contact_ids_by_source"] == %{
             "capacity_model" => ["selected_contact"]
           }

    assert summary["branch_local_contact_allocation_pressure"]
    assert summary["branch_local_capacity_pack_pressure"]
    refute summary["branch_local_blocked_allocation_pressure"]
    refute summary["branch_local_deferred_allocation_pressure"]
    refute summary["branch_local_station_pressure"]
  end

  defp contact_allocation_capacity_pack_summary_fixture do
    primary_row = %{
      "contact_id" => "dl_capacity_primary",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_contention_resolution",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "capacity_pack_status" => "selected_by_contention_resolution",
      "required_capacity_fraction" => 0.25,
      "required_capacity_fraction_source" => "contact_required_capacity_fraction"
    }

    secondary_row = %{
      "contact_id" => "dl_capacity_secondary",
      "allocation_status" => "allocated",
      "effective_allocation_status" => "allocated",
      "allocation_reason" => "selected_by_reduced_station_capacity_pack",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
      "required_capacity_fraction" => 0.25,
      "required_capacity_fraction_source" => "contact_required_capacity_fraction"
    }

    overflow_row = %{
      "contact_id" => "dl_capacity_overflow",
      "allocation_status" => "deferred",
      "effective_allocation_status" => "deferred",
      "allocation_reason" => "deferred_by_reduced_station_capacity_pack",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
      "required_capacity_fraction" => 0.25,
      "required_capacity_fraction_source" => "contact_required_capacity_fraction"
    }

    pack_group = %{
      "contention_group_id" => "pack_equator_prime",
      "pack_status" => "capacity_limited",
      "ground_station_id" => "equator_prime",
      "capacity_fraction" => 0.5
    }

    %{
      "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
      "model" => "artifact_only_contact_allocation_capacity_pack_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "unit_test.contact_allocation_capacity_pack_summary",
      "input_contact_count" => 3,
      "capacity_pack_contact_count" => 3,
      "capacity_pack_review_status" => "review_required",
      "reduced_capacity_pack_group_count" => 1,
      "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1},
      "capacity_pack_status_counts" => %{
        "deferred_by_reduced_station_capacity_pack" => 1,
        "selected_by_contention_resolution" => 1,
        "selected_by_reduced_station_capacity_pack" => 1
      },
      "capacity_pack_contact_ids_by_status" => %{
        "deferred_by_reduced_station_capacity_pack" => ["dl_capacity_overflow"],
        "selected_by_contention_resolution" => ["dl_capacity_primary"],
        "selected_by_reduced_station_capacity_pack" => ["dl_capacity_secondary"]
      },
      "capacity_pack_contact_ids_by_ground_station_id" => %{
        "equator_prime" => [
          "dl_capacity_overflow",
          "dl_capacity_primary",
          "dl_capacity_secondary"
        ]
      },
      "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["dl_capacity_primary", "dl_capacity_secondary"]
      },
      "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["dl_capacity_overflow"]
      },
      "capacity_pack_required_capacity_fraction" => 0.75,
      "capacity_pack_selected_required_capacity_fraction" => 0.5,
      "capacity_pack_deferred_required_capacity_fraction" => 0.25,
      "capacity_pack_required_capacity_fraction_by_status" => %{
        "deferred_by_reduced_station_capacity_pack" => 0.25,
        "selected_by_contention_resolution" => 0.25,
        "selected_by_reduced_station_capacity_pack" => 0.25
      },
      "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.75
      },
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.5
      },
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
        "equator_prime" => 0.25
      },
      "capacity_pack_required_capacity_fraction_by_direction" => %{
        "downlink" => 0.75
      },
      "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
        "downlink" => 0.5
      },
      "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
        "downlink" => 0.25
      },
      "capacity_pack_contact_ids_by_direction" => %{
        "downlink" => [
          "dl_capacity_overflow",
          "dl_capacity_primary",
          "dl_capacity_secondary"
        ]
      },
      "capacity_pack_selected_contact_ids_by_direction" => %{
        "downlink" => ["dl_capacity_primary", "dl_capacity_secondary"]
      },
      "capacity_pack_deferred_contact_ids_by_direction" => %{
        "downlink" => ["dl_capacity_overflow"]
      },
      "required_capacity_fraction_source_counts" => %{
        "contact_required_capacity_fraction" => 3
      },
      "required_capacity_fraction_contact_ids_by_source" => %{
        "contact_required_capacity_fraction" => [
          "dl_capacity_overflow",
          "dl_capacity_primary",
          "dl_capacity_secondary"
        ]
      },
      "reduced_capacity_packed_contact_ids" => ["dl_capacity_secondary"],
      "reduced_capacity_deferred_contact_ids" => ["dl_capacity_overflow"],
      "capacity_pack_group_ids" => ["pack_equator_prime"],
      "capacity_pack_group_ids_by_status" => %{
        "capacity_limited" => ["pack_equator_prime"]
      },
      "rows" => [primary_row, secondary_row, overflow_row],
      "reduced_capacity_pack_groups" => [pack_group],
      "review_rows" => [primary_row, secondary_row, overflow_row],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "source" => "contact_allocation_report.v1",
        "operator_authority" => "not_granted_by_capacity_pack_summary"
      },
      "provenance" => %{"trust_boundary" => "capacity_pack_fixture"}
    }
  end
end
