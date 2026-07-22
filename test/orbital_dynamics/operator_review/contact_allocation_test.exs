defmodule OrbitalDynamics.OperatorReview.ContactAllocationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "candidate refresh source contact allocation reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:contact_allocation_review:001",
      "source_contact_allocation_report" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "id" => "source_contact_allocation:mission_state",
        "calendar_entry_trust_boundary_status_counts" => %{"declared" => 1},
        "station_reservation_match_status_counts" => %{"matched" => 1},
        "station_reservation_expiration_status_counts" => %{"declared" => 1},
        "station_reservation_declared_expiration_contact_count" => 1,
        "station_reservation_missing_expiration_contact_count" => 0,
        "earliest_station_reservation_expires_at_s" => 360.0,
        "station_reservation_ids" => ["reservation:equator_prime:dl_source_deferred"],
        "station_reservation_expires_at_s" => [360.0],
        "station_reserved_bys" => ["ops"],
        "station_reservation_statuses" => ["held"],
        "resource_blocking_dimension_counts" => %{"antenna" => 1},
        "capacity_pack_required_capacity_fraction" => 0.65,
        "capacity_pack_selected_required_capacity_fraction" => 0.35,
        "capacity_pack_deferred_required_capacity_fraction" => 0.3,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => 0.35,
          "deferred_by_reduced_station_capacity_pack" => 0.3
        },
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "equator_prime" => 0.65
        },
        "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
          "equator_prime" => 0.35
        },
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
          "equator_prime" => 0.3
        },
        "capacity_pack_contact_ids_by_status" => %{
          "selected_by_reduced_station_capacity_pack" => ["dl_source_primary"],
          "deferred_by_reduced_station_capacity_pack" => ["dl_source_deferred"]
        },
        "capacity_pack_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_source_primary", "dl_source_deferred"]
        },
        "capacity_pack_selected_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_source_primary"]
        },
        "capacity_pack_deferred_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_source_deferred"]
        },
        "reduced_capacity_packed_contact_ids" => ["dl_source_primary"],
        "reduced_capacity_deferred_contact_ids" => ["dl_source_deferred"],
        "rows" => [
          %{
            "id" => "allocation:dl_source_deferred",
            "contact_id" => "dl_source_deferred",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "sat_1",
            "ground_station_id" => "equator_prime",
            "direction" => "downlink",
            "starts_at_s" => 120.0,
            "ends_at_s" => 180.0,
            "allocation_status" => "deferred",
            "allocation_reason" => "reduced_station_capacity",
            "selected" => false,
            "capacity_pack_group_id" => "station:equator_prime:capacity_pack:1",
            "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
            "required_capacity_fraction" => 0.3,
            "required_capacity_fraction_source" => "source_contact_allocation_report.rows",
            "station_availability" => "available",
            "station_reservation_id" => "reservation:equator_prime:dl_source_deferred",
            "station_reservation_expires_at_s" => 360.0,
            "station_reserved_by" => "ops",
            "station_reservation_status" => "held",
            "station_reservation_match_status" => "matched",
            "resource_blocking_dimension" => "antenna",
            "source_contact_candidate" => %{"id" => "dl_source_deferred"},
            "source_resource_suppression" => %{"suppressed_reason" => "antenna_unavailable"}
          }
        ],
        "reduced_capacity_pack_groups" => [
          %{
            "contention_group_id" => "station:equator_prime:capacity_pack:1",
            "ground_station_id" => "equator_prime",
            "capacity_fraction" => 0.5,
            "used_capacity_fraction" => 0.5,
            "default_required_capacity_fraction" => 0.25,
            "input_contact_ids" => ["dl_source_primary", "dl_source_deferred"],
            "selected_contact_ids" => ["dl_source_primary"],
            "capacity_packed_contact_ids" => ["dl_source_primary"],
            "deferred_contact_ids" => ["dl_source_deferred"],
            "pack_status" => "packed_with_deferred_contacts"
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:contact_allocation_review:001",
             "review_count" => 2,
             "contact_allocation_review_count" => 1,
             "contact_allocation_capacity_pack_review_count" => 1,
             "calendar_entry_trust_boundary_status_counts" => %{"declared" => 1},
             "station_reservation_match_status_counts" => %{"matched" => 1},
             "station_reservation_expiration_status_counts" => %{"declared" => 1},
             "station_reservation_declared_expiration_contact_count" => 1,
             "resource_blocking_dimension_counts" => %{"antenna" => 1},
             "capacity_pack_required_capacity_fraction" => 0.65,
             "capacity_pack_selected_required_capacity_fraction" => 0.35,
             "capacity_pack_deferred_required_capacity_fraction" => 0.3
           } = package

    assert %{
             "review_type" => "contact_allocation_review",
             "source" => "candidate_refresh.source_contact_allocation_report.rows",
             "subject_id" => "dl_source_deferred",
             "contact_id" => "dl_source_deferred",
             "allocation_status" => "deferred",
             "allocation_reason" => "reduced_station_capacity",
             "required_operator_action" => "review_contact_allocation",
             "ground_station_id" => "equator_prime",
             "capacity_pack_group_id" => "station:equator_prime:capacity_pack:1",
             "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
             "station_reservation_id" => "reservation:equator_prime:dl_source_deferred",
             "station_reservation_match_status" => "matched",
             "resource_blocking_dimension" => "antenna",
             "source_contact_allocation" => %{
               "contact_id" => "dl_source_deferred",
               "allocation_reason" => "reduced_station_capacity"
             },
             "source_resource_suppression" => %{"suppressed_reason" => "antenna_unavailable"}
           } =
             Enum.find(package["rows"], &(&1["review_type"] == "contact_allocation_review"))

    assert %{
             "review_type" => "contact_allocation_capacity_pack_review",
             "source" =>
               "candidate_refresh.source_contact_allocation_report.reduced_capacity_pack_groups",
             "contention_group_id" => "station:equator_prime:capacity_pack:1",
             "ground_station_id" => "equator_prime",
             "capacity_fraction" => 0.5,
             "used_capacity_fraction" => 0.5,
             "default_required_capacity_fraction" => 0.25,
             "selected_contact_ids" => ["dl_source_primary"],
             "deferred_contact_ids" => ["dl_source_deferred"],
             "source_contact_allocation_capacity_pack" => %{
               "contention_group_id" => "station:equator_prime:capacity_pack:1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["review_type"] == "contact_allocation_capacity_pack_review")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh accepted planning state contact allocation summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:accepted_contact_allocation_summary:001",
      "accepted_planning_state" => %{
        "source_contact_allocation_summary" =>
          study_result_fixture("contact_allocation_summary_v1.json")
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:accepted_contact_allocation_summary:001",
             "review_count" => 3,
             "contact_allocation_review_count" => 3
           } = package

    assert Enum.map(package["rows"], & &1["source"]) == [
             "candidate_refresh.accepted_planning_state.source_contact_allocation_summary.review_rows",
             "candidate_refresh.accepted_planning_state.source_contact_allocation_summary.review_rows",
             "candidate_refresh.accepted_planning_state.source_contact_allocation_summary.review_rows"
           ]

    assert %{
             "review_type" => "contact_allocation_review",
             "source" =>
               "candidate_refresh.accepted_planning_state.source_contact_allocation_summary.review_rows",
             "required_operator_action" => "review_contact_allocation",
             "source_contact_allocation" => %{
               "source_summary_schema_contract" => "contact_allocation_summary.v1",
               "source_summary_model" => "artifact_only_contact_allocation_summary",
               "source_contact_allocation_summary" => %{
                 "schema_contract" => "contact_allocation_summary.v1",
                 "model" => "artifact_only_contact_allocation_summary"
               }
             }
           } = List.first(package["rows"])

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:accepted_contact_allocation_summary:001",
             "row_count" => 3,
             "source_review_type_counts" => %{"contact_allocation_review" => 3},
             "import_action_counts" => %{"review_contact_allocation" => 3}
           } = manifest

    assert %{
             "import_action" => "review_contact_allocation",
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.accepted_planning_state.source_contact_allocation_summary.review_rows",
               "source_contact_allocation" => %{
                 "source_contact_allocation_summary" => %{
                   "schema_contract" => "contact_allocation_summary.v1",
                   "model" => "artifact_only_contact_allocation_summary"
                 }
               }
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh mission state contact allocation summaries become review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:mission_contact_allocation_summary:001",
      "mission_state" => %{
        "contact_allocation_reservation_conflict_summary" =>
          study_result_fixture("contact_allocation_reservation_conflict_summary_v1.json")
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:mission_contact_allocation_summary:001",
             "review_count" => 1,
             "contact_allocation_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "contact_allocation_review",
               "source" =>
                 "candidate_refresh.mission_state.contact_allocation_reservation_conflict_summary.reservation_review_rows",
               "required_operator_action" => "review_contact_allocation",
               "source_contact_allocation" => %{
                 "source_summary_schema_contract" =>
                   "contact_allocation_reservation_conflict_summary.v1",
                 "source_contact_allocation_summary" => %{
                   "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
                   "model" => "artifact_only_contact_allocation_reservation_conflict_summary"
                 }
               }
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "standalone contact allocation summaries become operator review rows" do
    capacity_pack_summary =
      study_result_fixture("contact_allocation_capacity_pack_summary_v1.json")

    capacity_pack_package =
      OperatorReview.from_contact_allocation_capacity_pack_summary(capacity_pack_summary)

    assert OrbitalDynamics.operator_review_package(capacity_pack_summary) ==
             capacity_pack_package

    assert %{
             "source_artifact_type" => "contact_allocation_capacity_pack_summary.v1",
             "source_artifact_id" => "validation.contact_allocation_capacity_pack_summary",
             "review_count" => 4,
             "contact_allocation_review_count" => 3,
             "contact_allocation_capacity_pack_review_count" => 1,
             "reduced_capacity_pack_group_count" => 1,
             "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1}
           } = capacity_pack_package

    assert %{
             "review_type" => "contact_allocation_capacity_pack_review",
             "source" => "contact_allocation_capacity_pack_summary.reduced_capacity_pack_groups",
             "required_operator_action" => "review_contact_allocation_capacity_pack",
             "contention_group_id" => "capacity_pack:equator_prime:downlink:100_160",
             "capacity_packed_contact_ids" => ["dl_capacity_secondary"],
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
             "capacity_pack_required_capacity_fraction_by_direction" => %{"downlink" => 0.75},
             "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.5
             },
             "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.25
             },
             "source_contact_allocation_capacity_pack" => %{
               "capacity_pack_contact_ids_by_direction" => %{
                 "downlink" => [
                   "dl_capacity_overflow",
                   "dl_capacity_primary",
                   "dl_capacity_secondary"
                 ]
               },
               "source_contact_allocation_summary" => %{
                 "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
                 "model" => "artifact_only_contact_allocation_capacity_pack_summary"
               }
             }
           } =
             Enum.find(
               capacity_pack_package["rows"],
               &(&1["review_type"] == "contact_allocation_capacity_pack_review")
             )

    reservation_conflict_summary =
      study_result_fixture("contact_allocation_reservation_conflict_summary_v1.json")

    reservation_conflict_package =
      OperatorReview.from_contact_allocation_reservation_conflict_summary(
        reservation_conflict_summary
      )

    assert OrbitalDynamics.operator_review_package(reservation_conflict_summary) ==
             reservation_conflict_package

    assert %{
             "source_artifact_type" => "contact_allocation_reservation_conflict_summary.v1",
             "source_artifact_id" => "validation.contact_allocation_reservation_conflict_summary",
             "review_count" => 1,
             "contact_allocation_review_count" => 1,
             "reservation_conflict_contact_ids_by_direction" => %{
               "downlink" => ["dl_reserved_intruder"]
             }
           } = reservation_conflict_package

    assert [
             %{
               "review_type" => "contact_allocation_review",
               "source" =>
                 "contact_allocation_reservation_conflict_summary.reservation_review_rows",
               "required_operator_action" => "review_contact_allocation",
               "contact_id" => "dl_reserved_intruder",
               "station_reservation_id" => "reservation_1",
               "source_contact_allocation" => %{
                 "source_summary_schema_contract" =>
                   "contact_allocation_reservation_conflict_summary.v1",
                 "source_contact_allocation_summary" => %{
                   "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
                   "model" => "artifact_only_contact_allocation_reservation_conflict_summary"
                 }
               }
             }
           ] = reservation_conflict_package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(capacity_pack_package)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(reservation_conflict_package)
  end

  test "candidate refresh result artifact contact allocation reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_contact_allocation_review:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "contact_allocation_report" => %{
            "schema_contract" => "contact_allocation_report.v1",
            "rows" => [
              %{
                "id" => "allocation:dl_wrapped_deferred",
                "contact_id" => "dl_wrapped_deferred",
                "type" => "downlink",
                "spacecraft_id" => "sat_1",
                "ground_station_id" => "equator_prime",
                "direction" => "downlink",
                "allocation_status" => "deferred",
                "allocation_reason" => "reduced_station_capacity",
                "selected" => false,
                "capacity_pack_group_id" => "station:equator_prime:capacity_pack:1",
                "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
                "required_capacity_fraction" => 0.3,
                "required_capacity_fraction_source" => "wrapped_contact_allocation_report.rows",
                "station_availability" => "available",
                "station_reservation_id" => "reservation:equator_prime:dl_wrapped_deferred",
                "station_reservation_expires_at_s" => 360.0,
                "station_reserved_by" => "ops",
                "station_reservation_status" => "held",
                "station_reservation_match_status" => "matched",
                "resource_blocking_dimension" => "antenna",
                "source_contact_candidate" => %{"id" => "dl_wrapped_deferred"},
                "source_resource_suppression" => %{"suppressed_reason" => "antenna_unavailable"}
              }
            ],
            "reduced_capacity_pack_groups" => [
              %{
                "contention_group_id" => "station:equator_prime:capacity_pack:1",
                "ground_station_id" => "equator_prime",
                "capacity_fraction" => 0.5,
                "used_capacity_fraction" => 0.5,
                "default_required_capacity_fraction" => 0.25,
                "input_contact_ids" => ["dl_wrapped_primary", "dl_wrapped_deferred"],
                "selected_contact_ids" => ["dl_wrapped_primary"],
                "capacity_packed_contact_ids" => ["dl_wrapped_primary"],
                "deferred_contact_ids" => ["dl_wrapped_deferred"],
                "pack_status" => "packed_with_deferred_contacts"
              }
            ]
          }
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_contact_allocation_review:001",
             "review_count" => 2,
             "contact_allocation_review_count" => 1,
             "contact_allocation_capacity_pack_review_count" => 1
           } = package

    assert %{
             "review_type" => "contact_allocation_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].contact_allocation_report.rows",
             "subject_id" => "dl_wrapped_deferred",
             "contact_id" => "dl_wrapped_deferred",
             "allocation_status" => "deferred",
             "allocation_reason" => "reduced_station_capacity",
             "required_operator_action" => "review_contact_allocation",
             "ground_station_id" => "equator_prime",
             "capacity_pack_group_id" => "station:equator_prime:capacity_pack:1",
             "station_reservation_id" => "reservation:equator_prime:dl_wrapped_deferred",
             "station_reservation_match_status" => "matched",
             "resource_blocking_dimension" => "antenna",
             "source_contact_allocation" => %{
               "contact_id" => "dl_wrapped_deferred",
               "allocation_reason" => "reduced_station_capacity"
             },
             "source_resource_suppression" => %{"suppressed_reason" => "antenna_unavailable"}
           } =
             Enum.find(package["rows"], &(&1["review_type"] == "contact_allocation_review"))

    assert %{
             "review_type" => "contact_allocation_capacity_pack_review",
             "source" =>
               "candidate_refresh.source_result_artifact[0].contact_allocation_report.reduced_capacity_pack_groups",
             "contention_group_id" => "station:equator_prime:capacity_pack:1",
             "ground_station_id" => "equator_prime",
             "capacity_fraction" => 0.5,
             "used_capacity_fraction" => 0.5,
             "selected_contact_ids" => ["dl_wrapped_primary"],
             "deferred_contact_ids" => ["dl_wrapped_deferred"],
             "source_contact_allocation_capacity_pack" => %{
               "contention_group_id" => "station:equator_prime:capacity_pack:1"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["review_type"] == "contact_allocation_capacity_pack_review")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "lifts CandidateRefresh provider-reservation request summaries into contact allocation review rows" do
    artifact = %{
      "refresh_id" => "refresh:provider_reservation_handoff",
      "source_contact_allocation_provider_reservation_request_summary" =>
        provider_reservation_request_summary()
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "refresh:provider_reservation_handoff",
             "review_count" => 2,
             "contact_allocation_review_count" => 2,
             "required_operator_action_counts" => %{
               "review_contact_allocation" => 1,
               "review_provider_reservation_request" => 1
             },
             "provider_reservation_candidate_contact_count" => 2,
             "provider_reservation_request_contact_count" => 1,
             "provider_reservation_review_contact_count" => 1,
             "provider_reservation_no_request_contact_count" => 1,
             "provider_reservation_request_status_counts" => %{"review_required" => 1},
             "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
             "provider_reservation_review_contact_ids" => ["dl_review_overlap"],
             "provider_reservation_no_request_contact_ids" => ["dl_unreserved"]
           } = package

    assert package["provider_reservation_request_contact_ids_by_ground_station_id"] == %{
             "equator_prime" => ["dl_reserved_owner"]
           }

    assert package["provider_reservation_review_contact_ids_by_ground_station_id"] == %{
             "equator_prime" => ["dl_review_overlap"]
           }

    assert package["provider_reservation_no_request_contact_ids_by_direction"] == %{
             "uplink" => ["dl_unreserved"]
           }

    assert package["provider_reservation_request_contact_ids_by_direction"] == %{
             "downlink" => ["dl_reserved_owner"]
           }

    assert package["provider_reservation_review_contact_ids_by_direction"] == %{
             "command" => ["dl_review_overlap"]
           }

    assert package[
             "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id"
           ] == %{
             "uplink" => %{"equator_prime" => ["dl_unreserved"]}
           }

    assert package[
             "provider_reservation_request_contact_ids_by_direction_and_ground_station_id"
           ] == %{
             "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
           }

    assert package[
             "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
           ] == %{
             "command" => %{"equator_prime" => ["dl_review_overlap"]}
           }

    assert package["provider_reservation_request_contact_ids_by_match_status"] == %{
             "matched" => ["dl_reserved_owner"]
           }

    assert package["provider_reservation_review_contact_ids_by_match_status"] == %{
             "overlap" => ["dl_review_overlap"]
           }

    assert package["provider_reservation_request_ids_by_match_status"] == %{
             "matched" => ["reservation_1"]
           }

    assert package["provider_reservation_review_ids_by_match_status"] == %{
             "overlap" => ["reservation_review"]
           }

    request_row = Enum.find(package["rows"], &(&1["contact_id"] == "dl_reserved_owner"))
    review_row = Enum.find(package["rows"], &(&1["contact_id"] == "dl_review_overlap"))

    assert %{
             "action" => "review_provider_reservation_request",
             "required_operator_action" => "review_provider_reservation_request",
             "review_type" => "contact_allocation_review",
             "source" =>
               "candidate_refresh.source_contact_allocation_provider_reservation_request_summary.provider_reservation_request_rows",
             "contact_id" => "dl_reserved_owner",
             "ground_station_id" => "equator_prime",
             "station_reservation_id" => "reservation_1",
             "station_reservation_match_status" => "matched",
             "provider_reservation_request_status" => "request_ready",
             "provider_reservation_request_summary_model" =>
               "artifact_only_contact_allocation_provider_reservation_request_summary",
             "provider_reservation_request_summary_schema_contract" =>
               "contact_allocation_provider_reservation_request_summary.v1",
             "provider_reservation_request_execution_boundary" =>
               "artifact_only_no_provider_reservation_or_schedule_mutation",
             "provider_reservation_execution" => "not_performed_by_summary",
             "source_provider_reservation_request_summary" => %{
               "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
               "provider_reservation_request_status" => "review_required"
             },
             "source_contact_allocation" => %{
               "provider_reservation_request_status" => "request_ready",
               "station_reservation_id" => "reservation_1",
               "station_reservation_match_status" => "matched"
             }
           } = request_row

    assert %{
             "action" => "review_contact_allocation",
             "required_operator_action" => "review_contact_allocation",
             "review_type" => "contact_allocation_review",
             "contact_id" => "dl_review_overlap",
             "station_reservation_id" => "reservation_review",
             "station_reservation_match_status" => "overlap",
             "provider_reservation_request_status" => "review_required",
             "source_contact_allocation" => %{
               "provider_reservation_request_status" => "review_required",
               "station_reservation_id" => "reservation_review",
               "station_reservation_match_status" => "overlap"
             }
           } = review_row

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "lifts standalone provider-reservation request summaries from CandidateRefresh result artifacts" do
    source_result_summary =
      provider_reservation_request_summary()
      |> Map.put("source", "unit_test.provider_reservation.source_result")

    nested_summary =
      provider_reservation_request_summary()
      |> Map.put("source", "unit_test.provider_reservation.nested_result")

    result_summary =
      provider_reservation_request_summary()
      |> Map.put("source", "unit_test.provider_reservation.result")

    artifact = %{
      "refresh_id" => "refresh:provider_reservation_result_artifact_handoff",
      "source_result_artifact" => [
        source_result_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "contact_allocation_provider_reservation_request_summary" => nested_summary
        }
      ],
      "result_artifact" => result_summary
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    provider_rows =
      Enum.filter(
        review["rows"],
        &(&1["source_provider_reservation_request_summary"]["schema_contract"] ==
            "contact_allocation_provider_reservation_request_summary.v1")
      )

    assert length(provider_rows) == 6

    assert Enum.sort(Enum.map(provider_rows, & &1["source"])) == [
             "candidate_refresh.result_artifact.provider_reservation_request_rows",
             "candidate_refresh.result_artifact.provider_reservation_request_rows",
             "candidate_refresh.source_result_artifact[0].provider_reservation_request_rows",
             "candidate_refresh.source_result_artifact[0].provider_reservation_request_rows",
             "candidate_refresh.source_result_artifact[1].contact_allocation_provider_reservation_request_summary.provider_reservation_request_rows",
             "candidate_refresh.source_result_artifact[1].contact_allocation_provider_reservation_request_summary.provider_reservation_request_rows"
           ]

    assert %{
             "contact_allocation_review_count" => 6,
             "provider_reservation_candidate_contact_count" => 6,
             "provider_reservation_request_contact_count" => 1,
             "provider_reservation_review_contact_count" => 1,
             "provider_reservation_no_request_contact_count" => 1,
             "provider_reservation_request_status_counts" => %{"review_required" => 3},
             "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
             "provider_reservation_review_contact_ids" => ["dl_review_overlap"],
             "provider_reservation_no_request_contact_ids" => ["dl_unreserved"]
           } = review

    assert import["provider_reservation_review_contact_count"] == 1
    assert import["provider_reservation_review_contact_ids"] == ["dl_review_overlap"]
    assert import["provider_reservation_request_contact_count"] == 1
    assert import["provider_reservation_request_contact_ids"] == ["dl_reserved_owner"]
    assert import["provider_reservation_no_request_contact_count"] == 1
    assert import["provider_reservation_no_request_contact_ids"] == ["dl_unreserved"]

    assert Enum.frequencies_by(provider_rows, & &1["required_operator_action"]) == %{
             "review_contact_allocation" => 3,
             "review_provider_reservation_request" => 3
           }

    import_rows =
      Enum.filter(
        import["rows"],
        &(get_in(&1, [
            "source_review_row",
            "source_provider_reservation_request_summary",
            "schema_contract"
          ]) == "contact_allocation_provider_reservation_request_summary.v1")
      )

    assert length(import_rows) == 6

    assert Enum.all?(
             import_rows,
             &(&1["source_review_row"]["provider_reservation_execution"] ==
                 "not_performed_by_summary")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "builds review package from standalone reduced-capacity contact allocation pack fixture" do
    report =
      "study_results/contact_allocation_capacity_pack_report_v1.json"
      |> File.read!()
      |> :json.decode()
      |> put_in(
        ["reduced_capacity_pack_groups", Access.at(0), "default_required_capacity_fraction"],
        0.25
      )

    package = OperatorReview.from_contact_allocation_report(report)

    assert %{
             "source_artifact_type" => "contact_allocation_report.v1",
             "source_artifact_id" => "fixture.contact_allocation.capacity_pack",
             "review_count" => 4,
             "contact_allocation_review_count" => 3,
             "contact_allocation_capacity_pack_review_count" => 1,
             "calendar_entry_trust_boundary_status_counts" => %{"declared" => 1}
           } = package

    assert %{
             "review_type" => "contact_allocation_capacity_pack_review",
             "action" => "review_contact_allocation_capacity_pack",
             "required_operator_action" => "review_contact_allocation_capacity_pack",
             "contention_group_id" => "station:equator_prime:contention:1",
             "capacity_fraction" => 0.5,
             "used_capacity_fraction" => 0.5,
             "default_required_capacity_fraction" => 0.25,
             "selected_contact_ids" => ["dl_capacity_primary"],
             "capacity_packed_contact_ids" => ["dl_capacity_secondary"],
             "deferred_contact_ids" => ["dl_capacity_overflow"],
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
             "capacity_pack_required_capacity_fraction_by_direction" => %{"downlink" => 0.75},
             "capacity_pack_selected_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.5
             },
             "capacity_pack_deferred_required_capacity_fraction_by_direction" => %{
               "downlink" => 0.25
             },
             "source_contact_allocation_capacity_pack" => %{
               "contention_group_id" => "station:equator_prime:contention:1",
               "capacity_pack_contact_ids_by_direction" => %{
                 "downlink" => [
                   "dl_capacity_overflow",
                   "dl_capacity_primary",
                   "dl_capacity_secondary"
                 ]
               }
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["review_type"] == "contact_allocation_capacity_pack_review")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "contact_allocation_capacity_pack_review"} = row ->
            put_in(
              row,
              ["source_contact_allocation_capacity_pack", "id"],
              "capacity pack with spaces"
            )

          row ->
            row
        end)
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.source_contact_allocation_capacity_pack\.id$/)
           )

    invalid_package =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "contact_allocation_capacity_pack_review"} = row ->
            Map.put(row, "capacity_fraction", 0.4)

          row ->
            row
        end)
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.capacity_fraction$/ and
                 &1["message"] ==
                   "must match source_contact_allocation_capacity_pack.capacity_fraction")
           )

    invalid_direction_map_package =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "contact_allocation_capacity_pack_review"} = row ->
            Map.put(row, "capacity_pack_selected_contact_ids_by_direction", %{
              "downlink" => ["dl_capacity_primary"]
            })

          row ->
            row
        end)
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_direction_map_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.capacity_pack_selected_contact_ids_by_direction$/ and
                 &1["message"] ==
                   "must match source_contact_allocation_capacity_pack.capacity_pack_selected_contact_ids_by_direction")
           )
  end

  test "builds review package from standalone contact allocation report rows" do
    report =
      "study_results/contact_allocation_report_v1.json"
      |> File.read!()
      |> :json.decode()

    package = OperatorReview.from_contact_allocation_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "contact_allocation_report.v1",
             "source_artifact_id" => "fixture.contact_allocation",
             "review_count" => 5,
             "contact_allocation_review_count" => 5,
             "calendar_entry_trust_boundary_status_counts" => %{"missing" => 2}
           } = package

    assert %{
             "review_type" => "contact_allocation_review",
             "source" => "contact_allocation_report.rows",
             "subject_id" => "dl_1",
             "contact_id" => "dl_1",
             "allocation_status" => "allocated",
             "allocation_reason" => "selected_by_contention_resolution",
             "required_operator_action" => "review_contact_allocation",
             "source_contact_allocation" => %{"contact_id" => "dl_1"},
             "source_contention_recommendation" => %{"selected_contact_id" => "dl_1"}
           } = List.first(package["rows"])

    assert %{
             "contact_id" => "dl_3",
             "allocation_status" => "blocked",
             "suppressed_reason" => "ground_station_reserved",
             "source_contact_suppression" => %{"suppressed_reason" => "ground_station_reserved"}
           } = Enum.find(package["rows"], &(&1["contact_id"] == "dl_3"))

    assert %{
             "contact_id" => "cmd_unavailable",
             "activity_type" => "command",
             "direction" => "command",
             "allocation_status" => "blocked",
             "allocation_reason" => "ground_station_unavailable",
             "approval_status" => "blocked_by_policy",
             "source_contact_allocation" => %{
               "source_station_calendar_contact" => %{
                 "id" => "cmd_unavailable",
                 "station_availability" => "unavailable"
               }
             }
           } = Enum.find(package["rows"], &(&1["contact_id"] == "cmd_unavailable"))

    assert %{
             "contact_id" => "dl_resource_blocked",
             "allocation_status" => "blocked",
             "allocation_reason" => "antenna_unavailable",
             "resource_blocking_dimension" => "antenna",
             "source_resource_suppression" => %{
               "suppressed_reason" => "antenna_unavailable"
             }
           } = Enum.find(package["rows"], &(&1["contact_id"] == "dl_resource_blocked"))

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{"review_type" => "contact_allocation_review", "source_contact_allocation" => %{}} =
              row ->
            put_in(row, ["source_contact_allocation", "id"], "allocation source with spaces")

          row ->
            row
        end)
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~ ~r/^\$\.rows\[\d+\]\.source_contact_allocation\.id$/)
           )

    invalid_contention_recommendation_evidence =
      update_in(package, ["rows"], fn rows ->
        Enum.map(rows, fn
          %{
            "review_type" => "contact_allocation_review",
            "source_contention_recommendation" => %{}
          } = row ->
            put_in(
              row,
              ["source_contention_recommendation", "selected_contact_id"],
              "selected contact with spaces"
            )

          row ->
            row
        end)
      end)

    assert {:error, report} =
             Schema.validate_artifact(invalid_contention_recommendation_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] =~
                 ~r/^\$\.rows\[\d+\]\.source_contention_recommendation\.selected_contact_id$/)
           )

    invalid_package =
      update_in(package, ["rows"], fn [row | rest] ->
        invalid_row =
          Map.merge(row, %{
            "allocation_reason" => "duplicate_contact_id",
            "duplicate_contact_candidate_count" => 2,
            "duplicate_contact_candidate_ids" => [row["contact_id"]],
            "resolution_priority_override_count" => 2,
            "resolution_priority_override_contact_ids" => [row["contact_id"]]
          })

        [invalid_row | rest]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].duplicate_contact_candidate_count" and
                 &1["message"] == "must equal 1")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].resolution_priority_override_count" and
                 &1["message"] == "must equal length of resolution_priority_override_contact_ids")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].allocation_reason" and
                 &1["message"] == "must match source_contact_allocation.allocation_reason")
           )
  end

  test "contact allocation report and summary source ids fall back through defaults" do
    assert %{"source_artifact_id" => "contact-allocation:report"} =
             OperatorReview.from_contact_allocation_report(%{
               id: :"contact-allocation:report",
               rows: []
             })

    assert %{"source_artifact_id" => "contact-allocation:source"} =
             OperatorReview.from_contact_allocation_report(%{
               source: :"contact-allocation:source",
               rows: []
             })

    assert %{"source_artifact_id" => "contact_allocation_report"} =
             OperatorReview.from_contact_allocation_report(%{rows: []})

    assert %{"source_artifact_id" => "contact-allocation:capacity"} =
             OperatorReview.from_contact_allocation_capacity_pack_summary(%{
               id: :"contact-allocation:capacity",
               reduced_capacity_pack_groups: []
             })

    assert %{"source_artifact_id" => "contact_allocation_capacity_pack_summary"} =
             OperatorReview.from_contact_allocation_capacity_pack_summary(%{
               reduced_capacity_pack_groups: []
             })

    assert %{"source_artifact_id" => "contact-allocation:reservation"} =
             OperatorReview.from_contact_allocation_reservation_conflict_summary(%{
               source: :"contact-allocation:reservation",
               reservation_review_rows: []
             })

    assert %{"source_artifact_id" => "contact_allocation_reservation_conflict_summary"} =
             OperatorReview.from_contact_allocation_reservation_conflict_summary(%{
               reservation_review_rows: []
             })
  end

  defp provider_reservation_request_summary do
    %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "unit_test.provider_reservation_request_summary",
      "provider_reservation_candidate_contact_count" => 2,
      "provider_reservation_request_contact_count" => 1,
      "provider_reservation_review_contact_count" => 1,
      "provider_reservation_no_request_contact_count" => 1,
      "provider_reservation_request_status" => "review_required",
      "provider_reservation_request_contact_ids" => ["dl_reserved_owner"],
      "provider_reservation_review_contact_ids" => ["dl_review_overlap"],
      "provider_reservation_no_request_contact_ids" => ["dl_unreserved"],
      "provider_reservation_request_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["dl_review_overlap"]
      },
      "provider_reservation_no_request_contact_ids_by_direction" => %{
        "uplink" => ["dl_unreserved"]
      },
      "provider_reservation_request_contact_ids_by_direction" => %{
        "downlink" => ["dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_direction" => %{
        "command" => ["dl_review_overlap"]
      },
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" => %{
        "uplink" => %{"equator_prime" => ["dl_unreserved"]}
      },
      "provider_reservation_request_contact_ids_by_direction_and_ground_station_id" => %{
        "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
      },
      "provider_reservation_review_contact_ids_by_direction_and_ground_station_id" => %{
        "command" => %{"equator_prime" => ["dl_review_overlap"]}
      },
      "provider_reservation_request_contact_ids_by_match_status" => %{
        "matched" => ["dl_reserved_owner"]
      },
      "provider_reservation_review_contact_ids_by_match_status" => %{
        "overlap" => ["dl_review_overlap"]
      },
      "provider_reservation_request_ids_by_match_status" => %{
        "matched" => ["reservation_1"]
      },
      "provider_reservation_review_ids_by_match_status" => %{
        "overlap" => ["reservation_review"]
      },
      "provider_reservation_request_rows" => [
        %{
          "contact_id" => "dl_reserved_owner",
          "allocation_status" => "allocated",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "station_reservation_id" => "reservation_1",
          "station_reservation_match_status" => "matched",
          "station_reservation_status" => "confirmed"
        }
      ],
      "provider_reservation_review_rows" => [
        %{
          "contact_id" => "dl_review_overlap",
          "allocation_status" => "allocated",
          "ground_station_id" => "equator_prime",
          "direction" => "command",
          "station_reservation_id" => "reservation_review",
          "station_reservation_match_status" => "overlap",
          "station_reservation_status" => "confirmed"
        }
      ],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "provider_reservation_execution" => "not_performed_by_summary"
      }
    }
  end

  defp study_result_fixture(filename) do
    ["study_results", filename]
    |> Path.join()
    |> File.read!()
    |> :json.decode()
  end
end
