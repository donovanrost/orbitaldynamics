defmodule OrbitalDynamics.CadenceImport.ActivityInputTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.Schema

  test "builds import manifest from standalone proposed contact" do
    contact = %{
      "schema_contract" => "proposed_contact.v1",
      "id" => "leo_1_downlink_equator_prime_1",
      "type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "starts_at_s" => 0.0,
      "ends_at_s" => 345.1793094813298,
      "estimated_throughput_mb" => 690.3586189626596,
      "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
      "cadence_import" => %{
        "external_id" => "leo_1_downlink_equator_prime_1",
        "activity_type" => "contact",
        "schema_contract" => "proposed_contact.v1"
      }
    }

    manifest = CadenceImport.from_proposed_contact(contact)
    assert OrbitalDynamics.cadence_import_manifest(contact) == manifest

    assert %{
             "source_artifact_type" => "proposed_contact.v1",
             "source_artifact_id" => "leo_1_downlink_equator_prime_1",
             "row_count" => 1,
             "ready_count" => 1,
             "import_action_counts" => %{"import_proposed_contact" => 1},
             "rows" => [
               %{
                 "import_action" => "import_proposed_contact",
                 "import_status" => "ready_for_import",
                 "source_review_type" => "proposed_contact",
                 "activity_id" => "leo_1_downlink_equator_prime_1",
                 "cadence_import_status" => "present",
                 "cadence_import_type" => "contact",
                 "cadence_import_id" => "leo_1_downlink_equator_prime_1",
                 "cadence_import_contract" => "proposed_contact.v1"
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_import_status =
      put_in(manifest, ["rows", Access.at(0), "import_status"], "provider_custom")

    assert {:error, invalid_import_status_report} =
             Schema.validate_artifact(invalid_import_status)

    assert Enum.any?(
             invalid_import_status_report["errors"],
             &(&1["path"] == "$.rows[0].import_status" and
                 &1["message"] =~ "must be one of")
           )

    invalid_cadence_import_status =
      put_in(manifest, ["rows", Access.at(0), "cadence_import_status"], "provider_custom")

    assert {:error, invalid_cadence_import_status_report} =
             Schema.validate_artifact(invalid_cadence_import_status)

    assert Enum.any?(
             invalid_cadence_import_status_report["errors"],
             &(&1["path"] == "$.rows[0].cadence_import_status" and
                 &1["message"] =~ "must be one of")
           )
  end

  test "preserves proposed-contact station-calendar trust evidence in import rows" do
    station_calendar_context = %{
      "station_availability" => "reduced_capacity",
      "station_contention_status" => "reserved_overlap",
      "station_calendar_entry_id" => "station_reduced_capacity",
      "station_calendar_status" => "available",
      "station_calendar_overlap_count" => 1,
      "station_calendar_overlap_entry_ids" => ["station_reduced_capacity"],
      "station_calendar_overlap_availabilities" => ["reduced_capacity"],
      "station_calendar_reservation_overlap_count" => 1,
      "station_calendar_reservation_ids" => ["reservation_1"],
      "station_calendar_reserved_by" => ["mission_ops"],
      "station_calendar_reservation_statuses" => ["held"],
      "station_calendar_trust_boundary_status" => "declared",
      "trust_boundary" => "ground_partner_api",
      "provenance" => %{
        "source" => "station_calendar_provider",
        "provider_id" => "ground_partner_a",
        "trust_boundary" => "ground_partner_api"
      },
      "source_station_calendar_entry" => %{
        "id" => "station_reduced_capacity",
        "provenance" => %{"trust_boundary" => "ground_partner_api"}
      },
      "source_station_calendar_overlaps" => [
        %{"id" => "station_reduced_capacity"}
      ]
    }

    contact =
      Map.merge(
        %{
          "schema_contract" => "proposed_contact.v1",
          "id" => "leo_1_downlink_trusted_station",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "starts_at_s" => 0.0,
          "ends_at_s" => 120.0,
          "estimated_throughput_mb" => 240.0,
          "source_window" => %{"id" => "window_1", "type" => "ground_station_access"},
          "cadence_import" => %{
            "external_id" => "leo_1_downlink_trusted_station",
            "activity_type" => "contact",
            "schema_contract" => "proposed_contact.v1"
          }
        },
        station_calendar_context
      )

    manifest = CadenceImport.from_proposed_contact(contact)
    [row] = manifest["rows"]

    assert Map.take(row, Map.keys(station_calendar_context)) == station_calendar_context

    assert Map.take(row["import_activity_context"], Map.keys(station_calendar_context)) ==
             station_calendar_context

    assert {:ok, %{"schema_contract" => "proposed_contact.v1"}} =
             Schema.validate_artifact(contact)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "review-gates standalone proposed contact with malformed cadence import context" do
    contact = %{
      "schema_contract" => "proposed_contact.v1",
      "id" => "leo_1_downlink_bad_import",
      "type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "starts_at_s" => 0.0,
      "ends_at_s" => 120.0,
      "estimated_throughput_mb" => 240.0,
      "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
      "cadence_import" => "bad_import_context"
    }

    manifest = CadenceImport.from_proposed_contact(contact)

    assert %{
             "row_count" => 1,
             "ready_count" => 0,
             "review_required_count" => 1,
             "cadence_import_status_counts" => %{"invalid" => 1},
             "rows" => [
               %{
                 "import_action" => "import_proposed_contact",
                 "import_status" => "review_required_before_import",
                 "activity_id" => "leo_1_downlink_bad_import",
                 "cadence_import_status" => "invalid",
                 "has_cadence_import" => false,
                 "invalid_cadence_import" => true,
                 "invalid_cadence_import_reason" => "cadence_import_must_be_object",
                 "source_cadence_import" => %{"invalid_import_shape" => "bad_import_context"},
                 "import_activity_context" => %{
                   "invalid_cadence_import" => true,
                   "invalid_cadence_import_reason" => "cadence_import_must_be_object",
                   "source_cadence_import" => %{
                     "invalid_import_shape" => "bad_import_context"
                   }
                 }
               }
             ]
           } = manifest

    refute Map.has_key?(List.first(manifest["rows"])["import_activity_context"], "cadence_import")

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds import manifest from standalone planned activity" do
    activity = %{
      "schema_contract" => "planned_activity.v1",
      "id" => "cmd_repoint",
      "type" => "command",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "direction" => "command",
      "starts_at_s" => 180.0,
      "ends_at_s" => 200.0,
      "source_window_id" => "window:leo_1:command:equator_prime:1",
      "cadence_import" => %{
        "external_id" => "cadence_cmd_repoint",
        "activity_type" => "command",
        "schema_contract" => "planned_activity.v1"
      }
    }

    manifest = CadenceImport.from_planned_activity(activity)
    assert OrbitalDynamics.cadence_import_manifest(activity) == manifest

    alias_manifest =
      activity
      |> Map.delete("type")
      |> Map.put("activity_type", "command")
      |> CadenceImport.from_planned_activity()

    assert [
             %{
               "activity_id" => "cmd_repoint",
               "source_review_action" => "review_command_contact"
             }
           ] = alias_manifest["rows"]

    assert %{
             "source_artifact_type" => "planned_activity.v1",
             "source_artifact_id" => "cmd_repoint",
             "row_count" => 1,
             "import_action_counts" => %{"review_operational_timeline" => 1},
             "rows" => [
               %{
                 "import_action" => "review_operational_timeline",
                 "source_review_type" => "operational_timeline_review",
                 "source_review_action" => "review_command_contact",
                 "activity_id" => "cmd_repoint",
                 "cadence_import_status" => "present",
                 "cadence_import_type" => "command",
                 "cadence_import_id" => "cadence_cmd_repoint",
                 "cadence_import_contract" => "planned_activity.v1",
                 "source_operational_timeline" => %{"activity_id" => "cmd_repoint"}
               }
             ]
           } = manifest

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    invalid_source_evidence =
      update_in(manifest, ["rows"], fn [row] ->
        [
          put_in(row, ["source_operational_timeline", "activity_id"], "activity id with spaces")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_operational_timeline.activity_id")
           )
  end

  test "preserves planned-activity station-calendar trust evidence in import rows" do
    station_calendar_context = %{
      "station_availability" => "reduced_capacity",
      "station_contention_status" => "reduced_capacity",
      "station_calendar_entry_id" => "station_reduced_capacity",
      "station_calendar_status" => "reduced_capacity",
      "station_calendar_overlap_count" => 1,
      "station_calendar_overlap_entry_ids" => ["station_reduced_capacity"],
      "station_calendar_overlap_availabilities" => ["reduced_capacity"],
      "station_calendar_entry_ambiguous" => true,
      "station_calendar_ambiguous_entry_count" => 1,
      "station_calendar_ambiguous_entry_ids" => ["station_reduced_capacity_alt"],
      "station_calendar_reservation_overlap_count" => 1,
      "station_calendar_reservation_ids" => ["reservation_1"],
      "station_calendar_reserved_by" => ["mission_ops"],
      "station_calendar_reservation_statuses" => ["held"],
      "station_calendar_trust_boundary_status" => "declared",
      "trust_boundary" => "ground_partner_api",
      "provenance" => %{"trust_boundary" => "ground_partner_api"},
      "source_station_calendar_entry" => %{"id" => "station_reduced_capacity"},
      "source_station_calendar_overlaps" => [%{"id" => "station_reduced_capacity"}]
    }

    activity =
      Map.merge(
        %{
          "schema_contract" => "planned_activity.v1",
          "id" => "cmd_repoint",
          "type" => "command",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "command",
          "starts_at_s" => 180.0,
          "ends_at_s" => 200.0,
          "source_window_id" => "window:leo_1:command:equator_prime:1",
          "cadence_import" => %{
            "external_id" => "cadence_cmd_repoint",
            "activity_type" => "command",
            "schema_contract" => "planned_activity.v1"
          }
        },
        station_calendar_context
      )

    assert {:ok, %{"schema_contract" => "planned_activity.v1"}} =
             Schema.validate_artifact(activity, schema_contract: "planned_activity.v1")

    manifest = CadenceImport.from_planned_activity(activity)
    [row] = manifest["rows"]

    assert Map.take(row, Map.keys(station_calendar_context)) == station_calendar_context

    assert Map.take(row["import_activity_context"], Map.keys(station_calendar_context)) ==
             station_calendar_context

    assert Map.take(row["source_review_row"], Map.keys(station_calendar_context)) ==
             station_calendar_context

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end
end
