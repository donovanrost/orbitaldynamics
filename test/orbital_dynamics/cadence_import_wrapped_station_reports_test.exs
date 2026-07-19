defmodule OrbitalDynamics.CadenceImportWrappedStationReportsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, Schema}

  test "candidate refresh import preserves wrapped station calendar reports" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_station_calendar_import:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "station_calendar_report" => %{
            "schema_contract" => "station_calendar_report.v1",
            "affected_contacts" => [
              %{
                "contact_id" => "dl_wrapped_station_unavailable",
                "scenario_id" => "leo_1",
                "contact_type" => "planned_contact",
                "direction" => "downlink",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 100.0,
                "ends_at_s" => 160.0,
                "station_calendar_entry_id" => "calendar_unavailable_wrapped",
                "station_calendar_provider_id" => "ops_calendar",
                "station_calendar_provider_entry_id" => "provider_unavailable_wrapped",
                "station_calendar_directions" => ["downlink"],
                "station_availability" => "unavailable",
                "station_contention_status" => "station_unavailable",
                "station_calendar_trust_boundary_status" => "declared",
                "trust_boundary" => "mission_state_station_calendar_report",
                "required_operator_action" => "review_station_calendar_contact",
                "approval_status" => "operator_review_required",
                "source_station_calendar_entry" => %{
                  "id" => "calendar_unavailable_wrapped",
                  "availability" => "unavailable"
                }
              }
            ],
            "provider_calendar_contention_groups" => [
              %{
                "id" => "station_calendar_provider_contention:equator_prime:wrapped",
                "provider_calendar_contention_status" => "provider_calendar_overlap",
                "required_operator_action" => "review_station_provider_contention",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 95.0,
                "ends_at_s" => 165.0,
                "entry_count" => 2,
                "entry_ids" => ["calendar_unavailable_wrapped", "calendar_reserved_wrapped"],
                "provider_ids" => ["ops_calendar"],
                "provider_entry_ids" => [
                  "provider_unavailable_wrapped",
                  "provider_reserved_wrapped"
                ],
                "availabilities" => ["unavailable", "reserved"],
                "directions" => ["downlink"]
              }
            ]
          }
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_station_calendar_import:001",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_station_calendar" => 2},
             "source_review_type_counts" => %{"station_calendar_review" => 2}
           } = manifest

    assert %{
             "import_action" => "review_station_calendar",
             "source_review_type" => "station_calendar_review",
             "source_review_action" => "review_station_calendar_contact",
             "import_status" => "review_required_before_import",
             "approval_status" => "operator_review_required",
             "contact_id" => "dl_wrapped_station_unavailable",
             "activity_type" => "planned_contact",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "station_calendar_entry_id" => "calendar_unavailable_wrapped",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_unavailable_wrapped",
             "station_calendar_directions" => ["downlink"],
             "station_availability" => "unavailable",
             "station_contention_status" => "station_unavailable",
             "station_calendar_trust_boundary_status" => "declared",
             "trust_boundary" => "mission_state_station_calendar_report",
             "has_cadence_import" => false,
             "source_station_calendar_entry" => %{
               "id" => "calendar_unavailable_wrapped",
               "availability" => "unavailable"
             },
             "source_station_calendar_review" => %{
               "contact_id" => "dl_wrapped_station_unavailable",
               "station_contention_status" => "station_unavailable"
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].station_calendar_report.affected_contacts",
               "review_type" => "station_calendar_review",
               "source_station_calendar_review" => %{
                 "contact_id" => "dl_wrapped_station_unavailable"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["contact_id"] == "dl_wrapped_station_unavailable")
             )

    assert %{
             "import_action" => "review_station_calendar",
             "source_review_type" => "station_calendar_review",
             "source_review_action" => "review_station_provider_contention",
             "import_status" => "review_required_before_import",
             "approval_status" => "operator_review_required",
             "ground_station_id" => "equator_prime",
             "provider_calendar_contention_status" => "provider_calendar_overlap",
             "provider_calendar_contention_group_id" =>
               "station_calendar_provider_contention:equator_prime:wrapped",
             "provider_calendar_contention_entry_count" => 2,
             "provider_calendar_contention_entry_ids" => [
               "calendar_unavailable_wrapped",
               "calendar_reserved_wrapped"
             ],
             "provider_calendar_contention_provider_ids" => ["ops_calendar"],
             "provider_calendar_contention_provider_entry_ids" => [
               "provider_unavailable_wrapped",
               "provider_reserved_wrapped"
             ],
             "provider_calendar_contention_availabilities" => ["unavailable", "reserved"],
             "provider_calendar_contention_directions" => ["downlink"],
             "has_cadence_import" => false,
             "source_station_calendar_provider_contention" => %{
               "id" => "station_calendar_provider_contention:equator_prime:wrapped",
               "entry_count" => 2
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].station_calendar_report.provider_calendar_contention_groups",
               "review_type" => "station_calendar_review",
               "source_station_calendar_provider_contention" => %{
                 "id" => "station_calendar_provider_contention:equator_prime:wrapped"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["provider_calendar_contention_status"] == "provider_calendar_overlap")
             )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves wrapped station reservation reports" do
    affected_contact = %{
      "contact_id" => "dl_wrapped_reserved",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => 100.0,
      "ends_at_s" => 160.0,
      "station_calendar_entry_id" => "calendar_reserved_wrapped",
      "station_calendar_provider_id" => "ops_calendar",
      "station_calendar_provider_entry_id" => "provider_reserved_wrapped",
      "station_contention_status" => "reserved_overlap",
      "station_reservation_match_status" => "owned",
      "station_reservation_id" => "reservation_wrapped",
      "station_reserved_by" => "network_partner",
      "station_reservation_status" => "held",
      "station_calendar_reservation_overlap_count" => 1,
      "station_calendar_reservation_ids" => ["reservation_wrapped"],
      "station_calendar_reserved_by" => ["network_partner"],
      "station_calendar_reservation_statuses" => ["held"],
      "station_calendar_reservation_expires_at_s" => [240.0],
      "required_operator_action" => "review_station_reservation_overlap"
    }

    provider_contention_group = %{
      "id" => "station_calendar_provider_contention:equator_prime:reservation_wrapped",
      "provider_calendar_contention_status" => "provider_calendar_overlap",
      "required_operator_action" => "review_station_provider_contention",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => 95.0,
      "ends_at_s" => 165.0,
      "entry_count" => 2,
      "entry_ids" => ["calendar_reserved_wrapped", "calendar_reserved_partner"],
      "reservation_ids" => ["reservation_wrapped", "reservation_partner"],
      "reservation_statuses" => ["held", "confirmed"],
      "reserved_by" => ["network_partner", "partner_calendar"]
    }

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_station_reservation_import:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "station_reservation_report" => %{
            "schema_contract" => "station_reservation_report.v1",
            "source" => "ops_calendar",
            "affected_contacts" => [affected_contact],
            "provider_calendar_contention_groups" => [provider_contention_group]
          }
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_station_reservation_import:001",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_station_reservation" => 2},
             "source_review_type_counts" => %{"station_reservation_review" => 2}
           } = manifest

    affected_row = Enum.find(manifest["rows"], &(&1["contact_id"] == "dl_wrapped_reserved"))

    assert %{
             "import_action" => "review_station_reservation",
             "source_review_type" => "station_reservation_review",
             "source_review_action" => "review_station_reservation_overlap",
             "import_status" => "review_required_before_import",
             "approval_status" => "operator_review_required",
             "contact_id" => "dl_wrapped_reserved",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "calendar_reserved_wrapped",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_reserved_wrapped",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_wrapped",
             "station_reserved_by" => "network_partner",
             "station_reservation_status" => "held",
             "station_reservation_match_status" => "owned",
             "station_calendar_reservation_overlap_count" => 1,
             "station_calendar_reservation_ids" => ["reservation_wrapped"],
             "station_calendar_reserved_by" => ["network_partner"],
             "station_calendar_reservation_statuses" => ["held"],
             "station_calendar_reservation_expires_at_s" => [240.0],
             "has_cadence_import" => false,
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].station_reservation_report.affected_contacts",
               "review_type" => "station_reservation_review"
             }
           } = affected_row

    assert affected_row["source_station_reservation"] == affected_contact

    assert get_in(affected_row, ["source_review_row", "source_station_reservation"]) ==
             affected_contact

    provider_contention_row =
      Enum.find(
        manifest["rows"],
        &(&1["provider_calendar_contention_status"] == "provider_calendar_overlap")
      )

    assert %{
             "import_action" => "review_station_reservation",
             "source_review_type" => "station_reservation_review",
             "source_review_action" => "review_station_provider_contention",
             "import_status" => "review_required_before_import",
             "approval_status" => "operator_review_required",
             "ground_station_id" => "equator_prime",
             "provider_calendar_contention_status" => "provider_calendar_overlap",
             "provider_calendar_contention_group_id" =>
               "station_calendar_provider_contention:equator_prime:reservation_wrapped",
             "provider_calendar_contention_entry_count" => 2,
             "provider_calendar_contention_entry_ids" => [
               "calendar_reserved_wrapped",
               "calendar_reserved_partner"
             ],
             "provider_calendar_contention_reservation_ids" => [
               "reservation_wrapped",
               "reservation_partner"
             ],
             "provider_calendar_contention_reservation_statuses" => ["held", "confirmed"],
             "provider_calendar_contention_reserved_by" => [
               "network_partner",
               "partner_calendar"
             ],
             "has_cadence_import" => false,
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].station_reservation_report.provider_calendar_contention_groups",
               "review_type" => "station_reservation_review"
             }
           } = provider_contention_row

    assert provider_contention_row["source_station_reservation"] == provider_contention_group

    assert get_in(provider_contention_row, ["source_review_row", "source_station_reservation"]) ==
             provider_contention_group

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end
end
