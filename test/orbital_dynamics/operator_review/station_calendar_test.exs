defmodule OrbitalDynamics.OperatorReview.StationCalendarTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "builds review package from station calendar affected contacts" do
    report = %{
      "schema_contract" => "station_calendar_report.v1",
      "model" => "campaign_ground_network_interval_overlay",
      "input_contact_count" => 1,
      "calendar_entry_count" => 1,
      "affected_contact_count" => 1,
      "affected_contacts" => [
        %{
          "id" => "station_calendar:cmd_1:equator_reserved",
          "contact_id" => "cmd_1",
          "scenario_id" => "leo_1",
          "contact_type" => "planned_contact",
          "direction" => "command",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0,
          "station_calendar_entry_id" => "equator_reserved",
          "station_calendar_provider_id" => "ops_calendar",
          "station_calendar_provider_entry_id" => "provider_reserved_1",
          "station_calendar_directions" => ["command"],
          "status" => "Reserved",
          "station_availability" => "Reserved",
          "station_calendar_overlap_count" => 2,
          "station_calendar_overlap_entry_ids" => ["equator_reserved", "equator_capacity"],
          "station_calendar_overlap_availabilities" => ["Reserved", "Reduced Capacity"],
          "station_calendar_entry_ambiguous" => true,
          "station_calendar_ambiguous_entry_count" => 2,
          "station_calendar_ambiguous_entry_ids" => [
            "equator_reserved",
            "equator_backup_reserved"
          ],
          "station_calendar_trust_boundary_status" => "declared",
          "trust_boundary" => "operator_declared_station_calendar",
          "station_contention_status" => "Reserved Overlap",
          "station_reservation_id" => "provider_reservation_42",
          "station_reserved_by" => "cadence_ops",
          "station_reservation_status" => "Confirmed",
          "source_station_calendar_entry" => %{
            "id" => "equator_reserved",
            "availability" => "Reserved"
          },
          "source_station_calendar_overlaps" => [
            %{"id" => "equator_reserved", "availability" => "Reserved"},
            %{"id" => "equator_capacity", "availability" => "Reduced Capacity"}
          ],
          "approval_status" => "operator_review_required",
          "approval_requirements" => [
            %{
              "activity_id" => "cmd_1",
              "activity_type" => "planned_contact",
              "action" => "review_station_reservation_overlap",
              "requirement_type" => "contact_schedule_change",
              "policy_classification" => "operator_review_required"
            }
          ],
          "approval_rule_matches" => [
            %{
              "rule_id" => "reserved_station_contact_review",
              "classification" => "operator_review_required",
              "station_contention_status" => "reserved_overlap"
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "operator_review_required",
            "policy_bundle_id" => "ground_network_allocation_v1",
            "rule_matches" => [
              %{
                "rule_id" => "reserved_station_contact_review",
                "classification" => "operator_review_required"
              }
            ],
            "escalations" => [
              %{
                "rule_id" => "reserved_station_contact_review",
                "escalation_level" => "ops_lead",
                "escalation_queue" => "ground_network",
                "escalation_role" => "contact_scheduler",
                "required_authority" => "contact_schedule_authority",
                "sla_s" => 600
              }
            ],
            "approval_requirement_count" => 1,
            "risk_count" => 0
          }
        }
      ],
      "assumptions" => %{
        "source" => "ops_calendar",
        "execution_boundary" => "artifact_only_no_provider_reservation"
      }
    }

    package = OperatorReview.from_station_calendar_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "station_calendar_report.v1",
             "source_artifact_id" => "ops_calendar",
             "review_count" => 1,
             "station_calendar_review_count" => 1
           } = package

    assert %{
             "review_type" => "station_calendar_review",
             "subject_id" => "cmd_1",
             "contact_id" => "cmd_1",
             "activity_type" => "planned_contact",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "equator_reserved",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_reserved_1",
             "station_calendar_directions" => ["command"],
             "station_availability" => "reserved",
             "station_calendar_overlap_count" => 2,
             "station_calendar_overlap_entry_ids" => ["equator_reserved", "equator_capacity"],
             "station_calendar_overlap_availabilities" => ["reserved", "reduced_capacity"],
             "station_calendar_entry_ambiguous" => true,
             "station_calendar_ambiguous_entry_count" => 2,
             "station_calendar_ambiguous_entry_ids" => [
               "equator_reserved",
               "equator_backup_reserved"
             ],
             "station_calendar_trust_boundary_status" => "declared",
             "trust_boundary" => "operator_declared_station_calendar",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "provider_reservation_42",
             "required_operator_action" => "review_station_reservation_overlap",
             "escalation_level" => "ops_lead",
             "escalation_queue" => "ground_network",
             "escalation_role" => "contact_scheduler",
             "required_authority" => "contact_schedule_authority",
             "sla_s" => 600,
             "approval_rule_matches" => [
               %{"rule_id" => "reserved_station_contact_review"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "reserved_station_contact_review",
               "required_authority" => "contact_schedule_authority"
             },
             "source_station_calendar_entry" => %{
               "id" => "equator_reserved",
               "availability" => "reserved"
             },
             "source_station_calendar_overlaps" => [
               %{"id" => "equator_reserved", "availability" => "reserved"},
               %{"id" => "equator_capacity", "availability" => "reduced_capacity"}
             ],
             "source_station_calendar_review" => %{"contact_id" => "cmd_1"}
           } = List.first(package["rows"])

    assert get_in(List.first(package["rows"]), [
             "source_station_calendar_review",
             "station_contention_status"
           ]) == "reserved_overlap"

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(row, ["source_station_calendar_entry", "id"], "calendar entry with spaces")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_station_calendar_entry.id")
           )

    invalid_overlap_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(
            row,
            ["source_station_calendar_overlaps", Access.at(1), "id"],
            "calendar overlap with spaces"
          )
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_overlap_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_station_calendar_overlaps[1].id")
           )

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [
          row
          |> Map.put("station_contention_status", "stale_contention_status")
          |> Map.put("starts_at_s", 11.0)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].station_contention_status" and
                 &1["message"] == "must match station calendar source station_contention_status")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].starts_at_s" and
                 &1["message"] == "must match station calendar source starts_at_s")
           )
  end

  test "builds review package from station reservation reports" do
    report = %{
      "schema_contract" => "station_reservation_report.v1",
      "source" => "ops_calendar",
      "affected_contacts" => [
        %{
          "contact_id" => "dl_reserved",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "station_calendar_entry_id" => "calendar_reserved_1",
          "station_calendar_provider_id" => "ops_calendar",
          "station_calendar_provider_entry_id" => "provider_reserved_1",
          "station_contention_status" => "reserved_overlap",
          "station_reservation_match_status" => "owned",
          "station_reservation_id" => "reservation_1",
          "station_reserved_by" => "network_partner",
          "station_reservation_status" => "held",
          "station_calendar_reservation_overlap_count" => 1,
          "station_calendar_reservation_ids" => ["reservation_1"],
          "station_calendar_reserved_by" => ["network_partner"],
          "station_calendar_reservation_statuses" => ["held"],
          "station_calendar_reservation_expires_at_s" => [240.0],
          "required_operator_action" => "review_station_reservation_overlap"
        }
      ],
      "provider_calendar_contention_groups" => [
        %{
          "id" => "station_calendar_provider_contention:equator_prime:1",
          "provider_calendar_contention_status" => "provider_calendar_overlap",
          "required_operator_action" => "review_station_provider_contention",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 95.0,
          "ends_at_s" => 165.0,
          "entry_count" => 2,
          "entry_ids" => ["calendar_reserved_1", "calendar_reserved_2"],
          "reservation_ids" => ["reservation_1", "reservation_2"],
          "reservation_statuses" => ["held", "confirmed"]
        }
      ]
    }

    package = OperatorReview.from_station_reservation_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "station_reservation_report.v1",
             "source_artifact_id" => "ops_calendar",
             "review_count" => 2,
             "station_reservation_review_count" => 2,
             "review_type_counts" => %{"station_reservation_review" => 2}
           } = package

    assert %{
             "review_type" => "station_reservation_review",
             "source" => "station_reservation_report.affected_contacts",
             "contact_id" => "dl_reserved",
             "ground_station_id" => "equator_prime",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "provider_reserved_1",
             "station_reservation_id" => "reservation_1",
             "station_reserved_by" => "network_partner",
             "station_reservation_status" => "held",
             "station_reservation_match_status" => "owned",
             "required_operator_action" => "review_station_reservation_overlap",
             "source_station_reservation" => %{
               "contact_id" => "dl_reserved",
               "station_reservation_id" => "reservation_1"
             }
           } = List.first(package["rows"])

    assert %{
             "review_type" => "station_reservation_review",
             "source" => "station_reservation_report.provider_calendar_contention_groups",
             "provider_calendar_contention_group_id" =>
               "station_calendar_provider_contention:equator_prime:1",
             "provider_calendar_contention_reservation_ids" => [
               "reservation_1",
               "reservation_2"
             ],
             "required_operator_action" => "review_station_provider_contention",
             "source_station_reservation" => %{
               "id" => "station_calendar_provider_contention:equator_prime:1"
             }
           } = Enum.at(package["rows"], 1)

    manifest = CadenceImport.from_operator_review_package(package)

    assert CadenceImport.from_station_reservation_report(report) == manifest
    assert OrbitalDynamics.cadence_import_manifest(report) == manifest

    assert %{
             "source_artifact_type" => "station_reservation_report.v1",
             "row_count" => 2,
             "review_required_count" => 2,
             "source_review_type_counts" => %{"station_reservation_review" => 2}
           } = manifest

    assert %{
             "import_action" => "review_station_reservation",
             "source_review_type" => "station_reservation_review",
             "contact_id" => "dl_reserved",
             "station_reservation_id" => "reservation_1",
             "source_station_reservation" => %{
               "contact_id" => "dl_reserved"
             }
           } = List.first(manifest["rows"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_evidence_package =
      update_in(package, ["rows"], fn [reservation_row, provider_row] ->
        [
          put_in(
            reservation_row,
            ["source_station_reservation", "station_reservation_id"],
            "bad reservation id"
          ),
          provider_row
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_station_reservation.station_reservation_id")
           )

    invalid_source_evidence_manifest =
      update_in(manifest, ["rows"], fn [reservation_row, provider_row] ->
        [
          put_in(
            reservation_row,
            ["source_station_reservation", "station_reservation_id"],
            "bad reservation id"
          ),
          provider_row
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_station_reservation.station_reservation_id")
           )

    invalid_package =
      update_in(package, ["rows"], fn [reservation_row, provider_row] ->
        [
          Map.put(reservation_row, "station_calendar_reservation_overlap_count", 2),
          provider_row
          |> Map.put("provider_calendar_contention_entry_count", 1)
          |> Map.put("starts_at_s", 96.0)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_reservation_overlap_count" and
                 &1["message"] == "must equal length of station_calendar_reservation_ids")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[1].provider_calendar_contention_entry_count" and
                 &1["message"] == "must equal length of provider_calendar_contention_entry_ids")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[1].starts_at_s" and
                 &1["message"] == "must match provider calendar contention source starts_at_s")
           )

    invalid_manifest =
      update_in(manifest, ["rows"], fn [reservation_row, provider_row] ->
        [
          Map.put(reservation_row, "station_calendar_reservation_overlap_count", 2),
          provider_row
          |> Map.put("provider_calendar_contention_entry_count", 1)
          |> Map.put("starts_at_s", 96.0)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].station_calendar_reservation_overlap_count" and
                 &1["message"] == "must equal length of station_calendar_reservation_ids")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[1].provider_calendar_contention_entry_count" and
                 &1["message"] == "must equal length of provider_calendar_contention_entry_ids")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[1].starts_at_s" and
                 &1["message"] == "must match provider calendar contention source starts_at_s")
           )

    invalid_source_review_manifest =
      update_in(manifest, ["rows"], fn [reservation_row, provider_row] ->
        reservation_source_review_row =
          reservation_row["source_review_row"]
          |> Map.put("station_reservation_id", "stale_reservation")
          |> Map.put("import_status", "ready_for_import")

        provider_source_review_row =
          provider_row["source_review_row"]
          |> Map.put("provider_calendar_contention_entry_count", 1)
          |> Map.put("source_review_action", "stale_provider_action")

        [
          Map.put(reservation_row, "source_review_row", reservation_source_review_row),
          Map.put(provider_row, "source_review_row", provider_source_review_row)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_review_manifest)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.station_reservation_id" and
                 &1["message"] == "must match station_reservation_id on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_review_row.import_status" and
                 &1["message"] == "must match import_status on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.rows[1].source_review_row.provider_calendar_contention_entry_count" and
                 &1["message"] ==
                   "must match provider_calendar_contention_entry_count on Cadence import row")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[1].source_review_row.source_review_action" and
                 &1["message"] == "must match source_review_action on Cadence import row")
           )
  end

  test "station calendar and reservation report source ids fall back through defaults" do
    assert %{"source_artifact_id" => "station-calendar:report"} =
             OperatorReview.from_station_calendar_report(%{
               id: :"station-calendar:report",
               affected_contacts: []
             })

    assert %{"source_artifact_id" => "station-calendar:assumption"} =
             OperatorReview.from_station_calendar_report(%{
               assumptions: %{source: :"station-calendar:assumption"},
               affected_contacts: []
             })

    assert %{"source_artifact_id" => "station_calendar_report"} =
             OperatorReview.from_station_calendar_report(%{affected_contacts: []})

    assert %{"source_artifact_id" => "station-reservation:report"} =
             OperatorReview.from_station_reservation_report(%{
               id: :"station-reservation:report",
               affected_contacts: []
             })

    assert %{"source_artifact_id" => "station-reservation:source"} =
             OperatorReview.from_station_reservation_report(%{
               source: :"station-reservation:source",
               affected_contacts: []
             })

    assert %{"source_artifact_id" => "station_reservation_report"} =
             OperatorReview.from_station_reservation_report(%{affected_contacts: []})
  end
end
