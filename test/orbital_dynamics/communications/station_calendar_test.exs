defmodule OrbitalDynamics.Communications.StationCalendarTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Communications.StationCalendar
  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}

  test "declares station calendar provider capabilities" do
    assert %{
             provider_contract: "station_calendar_provider.v1",
             validation_level: :artifact_contract,
             artifact_contract: "station_calendar_report.v1",
             reservation_artifact_contract: "station_reservation_report.v1",
             precedence_summary_artifact_contract: "station_calendar_precedence_summary.v1",
             reservation_review_summary_artifact_contract:
               "station_reservation_review_summary.v1",
             reservation_hold_summary_artifact_contract: "station_reservation_hold_summary.v1",
             reservation_hold_import_readiness_summary_artifact_contract:
               "station_reservation_hold_import_readiness_summary.v1",
             counteroffer_artifact_contract: "provider_counteroffer_report.v1",
             counteroffer_review_summary_artifact_contract:
               "provider_counteroffer_review_summary.v1",
             counteroffer_import_readiness_summary_artifact_contract:
               "provider_counteroffer_import_readiness_summary.v1",
             counteroffer_plan_impact_summary_artifact_contract:
               "provider_counteroffer_plan_impact_summary.v1",
             availability_values: availability_values,
             provider_availability_precedence_order: provider_availability_precedence_order,
             provider_unavailable_aliases: provider_unavailable_aliases,
             provider_reservation_hold_aliases: provider_reservation_hold_aliases,
             provider_capacity_fraction_paths: provider_capacity_fraction_paths,
             provider_capacity_percent_paths: provider_capacity_percent_paths,
             provider_capacity_value_paths: provider_capacity_value_paths,
             provider_direction_aliases: provider_direction_aliases,
             provider_result_map_value_keys: provider_result_map_value_keys,
             command_contact_directions: command_contact_directions,
             provider_counteroffer_actions: provider_counteroffer_actions,
             provider_counteroffer_negotiation_states: provider_counteroffer_negotiation_states,
             provider_counteroffer_lock_deadline_statuses:
               provider_counteroffer_lock_deadline_statuses,
             provider_counteroffer_import_statuses: provider_counteroffer_import_statuses,
             provider_counteroffer_import_readiness_statuses:
               provider_counteroffer_import_readiness_statuses,
             provider_counteroffer_import_classifications:
               provider_counteroffer_import_classifications,
             provider_counteroffer_plan_impact_statuses:
               provider_counteroffer_plan_impact_statuses,
             provider_counteroffer_field_paths: provider_counteroffer_field_paths,
             public_facades: public_facades,
             handoff_artifacts: handoff_artifacts,
             provider_counteroffer_review_type: "provider_counteroffer_review",
             provider_counteroffer_import_action: "review_provider_counteroffer",
             known_limits: known_limits,
             row_semantics: row_semantics
           } = StationCalendar.capabilities()

    assert availability_values == [
             "available",
             "unavailable",
             "reduced_capacity",
             "maintenance",
             "reserved"
           ]

    assert :declared_data_only in known_limits
    assert :no_network_calls in known_limits
    assert :no_provider_reservation in known_limits
    assert :direction_scoped_station_calendar in row_semantics
    assert :station_calendar_availability_precedence in row_semantics
    assert :provider_direction_aliases in row_semantics
    assert :provider_result_map_value_keys in row_semantics
    assert :command_uplink_direction_compatibility in row_semantics
    assert :station_reservation_match_status in row_semantics
    assert :station_reservation_review_status in row_semantics
    assert :station_reservation_review_count in row_semantics
    assert :affected_contact_reservation_count in row_semantics
    assert :provider_calendar_contention_group_count in row_semantics
    assert :station_reservation_match_status_counts in row_semantics
    assert :station_calendar_trust_boundary_status_id_routing in row_semantics
    assert :station_reservation_match_status_id_routing in row_semantics
    assert :station_reservation_status_counts in row_semantics
    assert :station_reservation_id_sets in row_semantics
    assert :station_reservation_routing_id_sets in row_semantics
    assert :station_reservation_owner_match in row_semantics
    assert :station_reservation_review_summary in row_semantics
    assert :station_reservation_hold_summary in row_semantics
    assert :station_reservation_expiration_status in row_semantics
    assert :station_reservation_review_summary_expiration_routing_id_sets in row_semantics
    assert :station_reservation_hold_expiration_routing_id_sets in row_semantics
    assert :station_reservation_hold_owner_routing_id_sets in row_semantics
    assert :station_reservation_hold_import_readiness_summary in row_semantics
    assert :station_reservation_hold_import_readiness_routing_id_sets in row_semantics
    assert :station_calendar_precedence_summary in row_semantics
    assert :station_calendar_precedence_routing_id_sets in row_semantics
    assert :station_calendar_reserved_under_higher_precedence in row_semantics
    assert :provider_calendar_contention_groups in row_semantics
    assert :station_reservation_report in row_semantics
    assert :feedback_unit_interval_input_validation in row_semantics
    assert :station_calendar_provider_list_input in row_semantics
    assert :provider_unavailable_aliases in row_semantics
    assert :provider_reservation_hold_aliases in row_semantics
    assert :provider_capacity_fraction_paths in row_semantics
    assert :provider_capacity_percent_aliases in row_semantics
    assert :provider_capacity_value_paths in row_semantics
    assert :provider_counteroffer_evidence in row_semantics
    assert :provider_counteroffer_field_aliases in row_semantics
    assert :provider_counteroffer_negotiation_state in row_semantics
    assert :provider_counteroffer_review_summary in row_semantics
    assert :provider_counteroffer_review_summary_deadline_routing_id_sets in row_semantics
    assert :provider_counteroffer_import_readiness_summary in row_semantics
    assert :provider_counteroffer_import_readiness_routing_id_sets in row_semantics
    assert :provider_counteroffer_plan_impact_summary in row_semantics
    assert :provider_counteroffer_plan_impact_routing_id_sets in row_semantics
    assert :provider_counteroffer_lock_deadline_status in row_semantics
    assert :provider_counteroffer_status_vocabularies in row_semantics
    assert :provider_counteroffer_summary_row_derived_counts in row_semantics
    assert provider_counteroffer_actions == ["none", "review_provider_counteroffer"]

    assert provider_counteroffer_lock_deadline_statuses == [
             "missing",
             "expired",
             "active",
             "declared"
           ]

    assert provider_counteroffer_import_statuses == [
             "review_required_before_import",
             "not_applicable"
           ]

    assert provider_counteroffer_import_readiness_statuses == ["clear", "review_required"]
    assert provider_counteroffer_import_classifications == ["not_applicable", "review_only"]
    assert provider_counteroffer_plan_impact_statuses == ["clear", "review_required"]

    assert provider_availability_precedence_order == [
             "unavailable",
             "maintenance",
             "reserved",
             "reduced_capacity",
             "available"
           ]

    assert provider_unavailable_aliases == ["outage", "down", "offline"]

    assert provider_reservation_hold_aliases == [
             "hold",
             "held",
             "on_hold",
             "onhold",
             "reservation_held",
             "reservation_hold",
             "reserved_hold"
           ]

    assert provider_capacity_fraction_paths == [
             ["capacity_pack_capacity_fraction"],
             ["capacity_fraction"],
             ["station_capacity_fraction"],
             ["availability"]
           ]

    assert provider_capacity_percent_paths == [
             ["capacity_percent"],
             ["station_capacity_percent"]
           ]

    assert %{unit: :fraction, path: ["capacity_pack_capacity_fraction"]} in provider_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_fraction"]} in provider_capacity_value_paths

    assert %{unit: :fraction, path: ["station_capacity_fraction"]} in provider_capacity_value_paths

    assert %{unit: :fraction, path: ["availability"]} in provider_capacity_value_paths
    assert %{unit: :percent, path: ["capacity_percent"]} in provider_capacity_value_paths
    assert %{unit: :percent, path: ["station_capacity_percent"]} in provider_capacity_value_paths

    assert provider_counteroffer_field_paths["provider_counteroffer_id"] == [
             ["provider_counteroffer_id"],
             ["counteroffer_id"],
             ["offer_id"]
           ]

    assert ["negotiation_status"] in provider_counteroffer_field_paths[
             "provider_counteroffer_negotiation_state"
           ]

    assert ["price_delta"] in provider_counteroffer_field_paths[
             "provider_counteroffer_cost_delta"
           ]

    assert ["schedule_lock_deadline_s"] in provider_counteroffer_field_paths[
             "provider_counteroffer_lock_deadline_s"
           ]

    assert ["offered_start_s"] in provider_counteroffer_field_paths[
             "provider_counteroffer_starts_at_s"
           ]

    assert ["offered_end_s"] in provider_counteroffer_field_paths[
             "provider_counteroffer_ends_at_s"
           ]

    assert Map.take(provider_direction_aliases, [
             "cmd",
             "commanding",
             "s_band_command",
             "up",
             "up_link",
             "dl",
             "down_link",
             "track",
             "track_ing",
             "health",
             "healthcheck",
             "health_check_window"
           ]) == %{
             "cmd" => "command",
             "commanding" => "command",
             "s_band_command" => "command",
             "up" => "uplink",
             "up_link" => "uplink",
             "dl" => "downlink",
             "down_link" => "downlink",
             "track" => "tracking",
             "track_ing" => "tracking",
             "health" => "health_check",
             "healthcheck" => "health_check",
             "health_check_window" => "health_check"
           }

    assert "result" in provider_result_map_value_keys
    assert "provider_status" in provider_result_map_value_keys
    assert "provider_outcome" in provider_result_map_value_keys
    assert "diagnostics" in provider_result_map_value_keys

    assert command_contact_directions == ["command", "uplink"]

    assert provider_counteroffer_negotiation_states == [
             "proposed",
             "pending",
             "accepted",
             "rejected",
             "expired",
             "canceled",
             "unknown"
           ]

    assert public_facades == [
             :station_calendar_report,
             :station_calendar_ground_network,
             :station_reservation_report,
             :station_reservation_review_summary,
             :station_reservation_hold_summary,
             :station_reservation_hold_import_readiness_summary,
             :station_calendar_precedence_summary,
             :provider_counteroffer_report,
             :provider_counteroffer_review_summary,
             :provider_counteroffer_import_readiness_summary,
             :provider_counteroffer_plan_impact_summary
           ]

    assert handoff_artifacts == [
             "operator_review_package.v1",
             "cadence_import_manifest.v1"
           ]

    assert OrbitalDynamics.capability_catalog().operations.station_calendar.public_facades ==
             public_facades
  end

  test "builds station calendar reports and annotated contacts" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        throughput_model: %{"estimated_throughput_mb" => 42.0}
      },
      %{
        id: :dl_2,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :deep_space_net,
        starts_at_s: 300.0,
        ends_at_s: 360.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      provenance: %{trust_boundary: :operator_declared_station_calendar},
      entries: [
        %{
          id: :equator_capacity,
          station_id: :equator_prime,
          availability: :available,
          start_s: 90.0,
          end_s: 170.0,
          capacity_fraction: 0.5
        }
      ]
    }

    {annotated, report} =
      StationCalendar.overlay_contacts(contacts, provider, source: "ops_calendar")

    assert [
             %{
               "id" => "dl_1",
               "station_availability" => "reduced_capacity",
               "station_calendar_status" => "available",
               "station_calendar_provider_id" => "ops_calendar",
               "station_calendar_provider_entry_id" => "equator_capacity",
               "station_calendar_overlap_count" => 1,
               "station_calendar_overlap_entry_ids" => ["equator_capacity"],
               "station_calendar_overlap_availabilities" => ["reduced_capacity"],
               "station_capacity_fraction" => 0.5,
               "throughput_model" => %{"station_capacity_fraction" => 0.5}
             },
             %{"id" => "dl_2"}
           ] = annotated

    assert %{
             "schema_contract" => "station_calendar_report.v1",
             "model" => "campaign_ground_network_interval_overlay",
             "input_contact_count" => 2,
             "calendar_entry_count" => 1,
             "calendar_entry_trust_boundary_status_counts" => %{"declared" => 1},
             "affected_contact_count" => 1,
             "affected_duration_s" => 60.0,
             "affected_contact_ground_station_counts" => %{"equator_prime" => 1},
             "affected_contact_availability_counts" => %{"reduced_capacity" => 1},
             "direction_counts" => %{"downlink" => 1},
             "station_calendar_status_counts" => %{"available" => 1},
             "station_calendar_trust_boundary_status_counts" => %{"declared" => 1},
             "affected_contact_ids_by_station_calendar_trust_boundary_status" => %{
               "declared" => ["dl_1"]
             },
             "affected_contact_ids_by_reservation_match_status" => %{},
             "model_limits" => model_limits,
             "affected_contacts" => [
               %{
                 "id" => "station_calendar:dl_1:equator_capacity",
                 "contact_id" => "dl_1",
                 "scenario_id" => "leo_1",
                 "ground_station_id" => "equator_prime",
                 "starts_at_s" => 100.0,
                 "ends_at_s" => 160.0,
                 "station_calendar_entry_id" => "equator_capacity",
                 "station_calendar_provider_id" => "ops_calendar",
                 "station_calendar_provider_entry_id" => "equator_capacity",
                 "status" => "available",
                 "station_calendar_status" => "available",
                 "direction" => "downlink",
                 "station_availability" => "reduced_capacity",
                 "station_calendar_overlap_count" => 1,
                 "station_calendar_overlap_entry_ids" => ["equator_capacity"],
                 "station_calendar_overlap_availabilities" => ["reduced_capacity"],
                 "station_calendar_trust_boundary_status" => "declared",
                 "overlap_starts_at_s" => 100.0,
                 "overlap_ends_at_s" => 160.0,
                 "overlap_duration_s" => 60.0,
                 "capacity_fraction" => 0.5,
                 "source_station_calendar_entry" => %{
                   "provider_id" => "ops_calendar",
                   "provider_entry_id" => "equator_capacity"
                 }
               }
             ],
             "assumptions" => %{
               "source" => "ops_calendar",
               "execution_boundary" => "artifact_only_no_provider_reservation"
             }
           } = report

    assert "declared_data_only" in model_limits
    assert "no_network_calls" in model_limits
    assert "no_provider_reservation" in model_limits

    expected_model_limits =
      StationCalendar.capabilities()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&to_string/1)

    assert model_limits == expected_model_limits

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_trust_ids =
      Map.put(report, "affected_contact_ids_by_station_calendar_trust_boundary_status", %{
        "declared" => ["stale_contact"]
      })

    assert {:error, invalid_trust_ids_report} = Schema.validate_artifact(invalid_trust_ids)

    assert Enum.any?(
             invalid_trust_ids_report["errors"],
             &(&1["path"] ==
                 "$.affected_contact_ids_by_station_calendar_trust_boundary_status" and
                 &1["message"] ==
                   "must equal row-derived affected_contact_ids_by_station_calendar_trust_boundary_status")
           )

    invalid_status_counts =
      Map.put(report, "station_calendar_status_counts", %{"reserved" => 1})

    assert {:error, invalid_status_counts_report} =
             Schema.validate_artifact(invalid_status_counts)

    assert Enum.any?(
             invalid_status_counts_report["errors"],
             &(&1["path"] == "$.station_calendar_status_counts" and
                 &1["message"] == "must equal row-derived station_calendar_status_counts")
           )
  end

  test "builds station reservation summaries from reports and raw calendar inputs" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    calendar = [
      %{
        id: :equator_reserved_a,
        ground_station_id: :equator_prime,
        availability: :reserved,
        direction: :downlink,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        reservation_id: :reservation_a,
        reserved_by: :ops_team_a,
        reservation_status: :tentative
      },
      %{
        id: :equator_reserved_b,
        ground_station_id: :equator_prime,
        availability: :reserved,
        direction: :downlink,
        starts_at_s: 95.0,
        ends_at_s: 165.0,
        reservation_id: :reservation_b,
        reserved_by: :ops_team_b,
        reservation_status: :confirmed
      }
    ]

    report = StationCalendar.report(contacts, calendar, source: "ops_calendar")

    assert %{
             "model" => "artifact_only_station_reservation_summary",
             "schema_contract" => "station_reservation_report.v1",
             "schema_version" => 1,
             "source" => "station_calendar_report.reservation_evidence",
             "affected_contact_reservation_count" => 1,
             "provider_calendar_contention_group_count" => 1,
             "reservation_review_count" => 2,
             "reservation_review_status" => "review_required",
             "station_reservation_match_status_counts" => %{"ambiguous" => 1},
             "reservation_status_counts" => %{"confirmed" => 2, "tentative" => 2},
             "reservation_ids" => ["reservation_a", "reservation_b"],
             "reservation_ids_by_status" => %{
               "confirmed" => ["reservation_a", "reservation_b"],
               "tentative" => ["reservation_a", "reservation_b"]
             },
             "reservation_ids_by_match_status" => %{
               "ambiguous" => ["reservation_a", "reservation_b"]
             },
             "affected_contacts" => [
               %{
                 "contact_id" => "dl_1",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_match_status" => "ambiguous",
                 "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
                 "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
                 "station_calendar_reservation_statuses" => ["tentative", "confirmed"],
                 "required_operator_action" => "review_station_reservation_overlap"
               }
             ],
             "provider_calendar_contention_groups" => [
               %{
                 "provider_calendar_contention_status" => "provider_calendar_overlap",
                 "reservation_ids" => ["reservation_a", "reservation_b"],
                 "reservation_statuses" => ["confirmed", "tentative"],
                 "required_operator_action" => "review_station_provider_contention"
               }
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_reservation",
               "scope" => "station_reservation_overlap_and_provider_contention_review"
             }
           } = reservation_report = StationCalendar.reservation_report(report)

    assert OrbitalDynamics.station_reservation_report(report) == reservation_report
    assert StationCalendar.reservation_report(reservation_report) == reservation_report
    assert OrbitalDynamics.station_reservation_report(reservation_report) == reservation_report

    assert StationCalendar.reservation_report(%{
             schema_contract: "station_reservation_report.v1",
             model: "artifact_only_station_reservation_summary",
             schema_version: 1,
             source: "atom_keyed_fixture",
             affected_contacts: [],
             provider_calendar_contention_groups: []
           }) == %{
             "schema_contract" => "station_reservation_report.v1",
             "model" => "artifact_only_station_reservation_summary",
             "schema_version" => 1,
             "source" => "atom_keyed_fixture",
             "affected_contacts" => [],
             "provider_calendar_contention_groups" => []
           }

    assert {:ok, %{"schema_contract" => "station_reservation_report.v1"}} =
             Schema.validate_artifact(reservation_report)

    invalid_match_counts =
      put_in(reservation_report, ["station_reservation_match_status_counts", "ambiguous"], 99)

    assert {:error, invalid_match_counts_report} =
             Schema.validate_artifact(invalid_match_counts)

    assert Enum.any?(
             invalid_match_counts_report["errors"],
             &(&1["path"] == "$.station_reservation_match_status_counts")
           )

    invalid_status_counts =
      put_in(reservation_report, ["reservation_status_counts", "confirmed"], 99)

    assert {:error, invalid_status_counts_report} =
             Schema.validate_artifact(invalid_status_counts)

    assert Enum.any?(
             invalid_status_counts_report["errors"],
             &(&1["path"] == "$.reservation_status_counts")
           )

    invalid_reservation_ids = Map.put(reservation_report, "reservation_ids", ["reservation_b"])

    assert {:error, invalid_reservation_ids_report} =
             Schema.validate_artifact(invalid_reservation_ids)

    assert Enum.any?(
             invalid_reservation_ids_report["errors"],
             &(&1["path"] == "$.reservation_ids")
           )

    invalid_reservation_ids_by_status =
      Map.put(reservation_report, "reservation_ids_by_status", %{"confirmed" => []})

    assert {:error, invalid_reservation_ids_by_status_report} =
             Schema.validate_artifact(invalid_reservation_ids_by_status)

    assert Enum.any?(
             invalid_reservation_ids_by_status_report["errors"],
             &(&1["path"] == "$.reservation_ids_by_status")
           )

    invalid_reservation_ids_by_match_status =
      Map.put(reservation_report, "reservation_ids_by_match_status", %{"ambiguous" => []})

    assert {:error, invalid_reservation_ids_by_match_status_report} =
             Schema.validate_artifact(invalid_reservation_ids_by_match_status)

    assert Enum.any?(
             invalid_reservation_ids_by_match_status_report["errors"],
             &(&1["path"] == "$.reservation_ids_by_match_status")
           )

    invalid_model = Map.put(reservation_report, "model", "custom_station_reservation_summary")

    assert {:error, invalid_model_report} =
             Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             invalid_model_report["errors"],
             &(&1["path"] == "$.model")
           )

    assert OrbitalDynamics.station_reservation_report(contacts, calendar, []) ==
             reservation_report

    assert %{
             "reservation_review_status" => "clear",
             "reservation_review_count" => 0,
             "affected_contacts" => [],
             "provider_calendar_contention_groups" => []
           } = StationCalendar.reservation_report(StationCalendar.report([], []))

    assert_raise ArgumentError, ~r/station calendar report is required/, fn ->
      StationCalendar.reservation_report(:not_a_report)
    end
  end

  test "reservation summary derives affected contact routing from source station-calendar provenance" do
    reservation_report =
      StationCalendar.reservation_report(%{
        "schema_contract" => "station_calendar_report.v1",
        "affected_contacts" => [
          %{
            "contact_id" => "dl_source_reserved",
            "direction" => "downlink",
            "ground_station_id" => "equator_prime",
            "source_station_calendar_entry" => %{
              "id" => "calendar_reserved_1",
              "provider_id" => "ops_calendar",
              "provider_entry_id" => "provider_reserved_1",
              "availability" => "Reserved",
              "reservation_id" => "reservation_1",
              "reserved_by" => "network_partner",
              "reservation_status" => "Held",
              "reservation_match_status" => "Owned",
              "reservation_expires_at_s" => 240.0
            }
          },
          %{
            "contact_id" => "dl_source_available",
            "ground_station_id" => "clear_prime",
            "source_station_calendar_entry" => %{
              "id" => "calendar_available_1",
              "availability" => "Available"
            }
          }
        ],
        "provider_calendar_contention_groups" => []
      })

    assert %{
             "affected_contact_reservation_count" => 1,
             "provider_calendar_contention_group_count" => 0,
             "reservation_review_count" => 1,
             "reservation_review_status" => "review_required",
             "station_reservation_match_status_counts" => %{"owned" => 1},
             "reservation_status_counts" => %{"held" => 2},
             "reservation_ids" => ["reservation_1"],
             "affected_contacts" => [
               %{
                 "contact_id" => "dl_source_reserved",
                 "ground_station_id" => "equator_prime",
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
             "provider_calendar_contention_groups" => []
           } = reservation_report

    assert {:ok, %{"schema_contract" => "station_reservation_report.v1"}} =
             Schema.validate_artifact(reservation_report)
  end

  test "reservation review summary classifies hold expiration evidence without provider writes" do
    reservation_report =
      StationCalendar.reservation_report(%{
        "schema_contract" => "station_calendar_report.v1",
        "source" => "ops_calendar",
        "affected_contacts" => [
          %{
            "contact_id" => "dl_source_reserved",
            "ground_station_id" => "equator_prime",
            "source_station_calendar_entry" => %{
              "id" => "calendar_reserved_1",
              "provider_id" => "ops_calendar",
              "provider_entry_id" => "provider_reserved_1",
              "availability" => "reserved",
              "directions" => ["downlink"],
              "reservation_id" => "reservation_expired",
              "reservation_status" => "held",
              "reserved_by" => "ops_calendar",
              "reservation_expires_at_s" => 240.0
            }
          }
        ],
        "provider_calendar_contention_groups" => [
          %{
            "provider_calendar_contention_status" => "provider_calendar_overlap",
            "ground_station_id" => "equator_prime",
            "reservation_ids" => ["reservation_active"],
            "reservation_statuses" => ["confirmed"],
            "reservation_expires_at_s" => [420.0],
            "directions" => ["downlink"],
            "required_operator_action" => "review_station_provider_contention"
          },
          %{
            "provider_calendar_contention_status" => "provider_calendar_overlap",
            "ground_station_id" => "polar_prime",
            "reservation_ids" => ["reservation_missing"],
            "reservation_statuses" => ["held"],
            "reserved_by" => ["partner_calendar"],
            "directions" => ["uplink"],
            "required_operator_action" => "review_station_provider_contention"
          }
        ]
      })

    reservation_report =
      update_in(reservation_report, ["affected_contacts", Access.at(0)], fn row ->
        Map.put(row, "direction", "downlink")
      end)

    summary = StationCalendar.reservation_review_summary(reservation_report, now_s: 300.0)

    assert OrbitalDynamics.station_reservation_review_summary(reservation_report, now_s: 300.0) ==
             summary

    assert %{
             "schema_contract" => "station_reservation_review_summary.v1",
             "model" => "artifact_only_station_reservation_review_summary",
             "source_artifact_type" => "station_reservation_report.v1",
             "source" => "station_calendar_report.reservation_evidence",
             "model_limits" => review_model_limits,
             "reservation_count" => 3,
             "affected_contact_reservation_count" => 1,
             "provider_calendar_contention_group_count" => 2,
             "reservation_review_status" => "review_required",
             "reservation_expiration_count" => 2,
             "earliest_reservation_expires_at_s" => 240.0,
             "reservation_expiration_status_counts" => %{
               "active" => 1,
               "expired" => 1,
               "missing" => 1
             },
             "reservation_ids_by_expiration_status" => %{
               "active" => ["reservation_active"],
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing"]
             },
             "expired_reservation_count" => 1,
             "active_reservation_count" => 1,
             "missing_reservation_expiration_count" => 1,
             "review_reservation_ids" => [
               "reservation_active",
               "reservation_expired",
               "reservation_missing"
             ],
             "review_rows" => [
               %{
                 "reservation_review_row_type" => "affected_contact",
                 "contact_id" => "dl_source_reserved",
                 "reservation_ids" => ["reservation_expired"],
                 "reservation_expires_at_s" => [240.0],
                 "station_reservation_expiration_status" => "expired"
               },
               %{
                 "reservation_review_row_type" => "provider_calendar_contention_group",
                 "reservation_ids" => ["reservation_active"],
                 "reservation_expires_at_s" => [420.0],
                 "station_reservation_expiration_status" => "active"
               },
               %{
                 "reservation_review_row_type" => "provider_calendar_contention_group",
                 "reservation_ids" => ["reservation_missing"],
                 "station_reservation_expiration_status" => "missing"
               }
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_reservation",
               "operator_authority" => "not_granted_by_summary",
               "deadline_evaluation" => "relative_to_now_s",
               "now_s" => 300.0
             }
           } = summary

    assert %{
             "reservation_expiration_status_counts" => %{"declared" => 2, "missing" => 1},
             "assumptions" => %{"deadline_evaluation" => "not_evaluated"}
           } = StationCalendar.reservation_review_summary(reservation_report)

    assert {:ok, %{"schema_contract" => "station_reservation_review_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert {:ok, reservation_review_schema} =
             Schema.json_schema("station_reservation_review_summary.v1")

    assert get_in(reservation_review_schema, ["properties", "model", "const"]) ==
             "artifact_only_station_reservation_review_summary"

    expected_model_limits =
      StationCalendar.capabilities().known_limits
      |> Enum.map(&Atom.to_string/1)

    assert review_model_limits == expected_model_limits

    assert get_in(reservation_review_schema, ["properties", "model_limits", "const"]) ==
             expected_model_limits

    assert get_in(reservation_review_schema, ["properties", "model_limits", "items", "enum"]) ==
             expected_model_limits

    stale_review_model_limits = Map.put(summary, "model_limits", ["declared_data_only"])

    assert {:error, stale_review_model_limits_report} =
             Schema.validate_artifact(stale_review_model_limits)

    assert Enum.any?(
             stale_review_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match station calendar report model limits")
           )

    stale_count_summary = Map.put(summary, "reservation_count", 2)

    assert {:error, stale_count_report} = Schema.validate_artifact(stale_count_summary)

    assert Enum.any?(
             stale_count_report["errors"],
             &(&1["path"] == "$.reservation_count" and &1["message"] == "must equal 3")
           )

    stale_rows_summary =
      update_in(summary, ["review_rows", Access.at(0)], fn row ->
        Map.put(row, "reservation_ids", [])
      end)

    assert {:error, stale_rows_report} = Schema.validate_artifact(stale_rows_summary)

    assert Enum.any?(
             stale_rows_report["errors"],
             &(&1["path"] == "$.review_reservation_ids" and
                 &1["message"] == "must equal row-derived review_reservation_ids")
           )

    hold_summary = StationCalendar.reservation_hold_summary(reservation_report, now_s: 300.0)

    assert OrbitalDynamics.station_reservation_hold_summary(reservation_report, now_s: 300.0) ==
             hold_summary

    assert %{
             "schema_contract" => "station_reservation_hold_summary.v1",
             "model" => "artifact_only_station_reservation_hold_summary",
             "source_artifact_type" => "station_reservation_report.v1",
             "source" => "station_calendar_report.reservation_evidence",
             "model_limits" => ^expected_model_limits,
             "reservation_hold_count" => 2,
             "affected_contact_reservation_hold_count" => 1,
             "provider_calendar_contention_hold_count" => 1,
             "reservation_hold_review_status" => "review_required",
             "reservation_hold_expiration_count" => 1,
             "earliest_reservation_hold_expires_at_s" => 240.0,
             "reservation_hold_expiration_status_counts" => %{
               "expired" => 1,
               "missing" => 1
             },
             "reservation_hold_status_counts" => %{
               "held" => 2
             },
             "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
             "reservation_hold_ids_by_expiration_status" => %{
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing"]
             },
             "reservation_hold_ids_by_status" => %{
               "held" => ["reservation_expired", "reservation_missing"]
             },
             "reservation_hold_ids_by_reserved_by" => %{
               "ops_calendar" => ["reservation_expired"],
               "partner_calendar" => ["reservation_missing"]
             },
             "reservation_hold_ids_by_row_type" => %{
               "affected_contact" => ["reservation_expired"],
               "provider_calendar_contention_group" => ["reservation_missing"]
             },
             "reservation_hold_contact_ids_by_expiration_status" => %{
               "expired" => ["dl_source_reserved"]
             },
             "review_contact_ids" => ["dl_source_reserved"],
             "review_rows" => [
               %{
                 "reservation_review_row_type" => "affected_contact",
                 "contact_id" => "dl_source_reserved",
                 "reservation_ids" => ["reservation_expired"],
                 "reservation_statuses" => ["held"],
                 "reserved_by" => ["ops_calendar"],
                 "reservation_expires_at_s" => [240.0],
                 "station_reservation_expiration_status" => "expired"
               },
               %{
                 "reservation_review_row_type" => "provider_calendar_contention_group",
                 "reservation_ids" => ["reservation_missing"],
                 "reservation_statuses" => ["held"],
                 "reserved_by" => ["partner_calendar"],
                 "station_reservation_expiration_status" => "missing"
               }
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_reservation",
               "operator_authority" => "not_granted_by_summary",
               "deadline_evaluation" => "relative_to_now_s",
               "now_s" => 300.0
             }
           } = hold_summary

    assert %{
             "reservation_hold_review_status" => "clear",
             "reservation_hold_count" => 0,
             "review_rows" => []
           } =
             StationCalendar.reservation_hold_summary(%{
               reservation_report
               | "affected_contacts" => [],
                 "provider_calendar_contention_groups" => []
             })

    assert {:ok, %{"schema_contract" => "station_reservation_hold_summary.v1"}} =
             Schema.validate_artifact(hold_summary)

    assert {:ok, hold_summary_schema} =
             Schema.json_schema("station_reservation_hold_summary.v1")

    assert get_in(hold_summary_schema, ["properties", "model", "const"]) ==
             "artifact_only_station_reservation_hold_summary"

    assert get_in(hold_summary_schema, ["properties", "model_limits", "const"]) ==
             expected_model_limits

    assert get_in(hold_summary_schema, ["properties", "model_limits", "items", "enum"]) ==
             expected_model_limits

    stale_hold_model_limits = Map.put(hold_summary, "model_limits", ["declared_data_only"])

    assert {:error, stale_hold_model_limits_report} =
             Schema.validate_artifact(stale_hold_model_limits)

    assert Enum.any?(
             stale_hold_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match station calendar report model limits")
           )

    stale_hold_count_summary = Map.put(hold_summary, "reservation_hold_count", 1)

    assert {:error, stale_hold_count_report} = Schema.validate_artifact(stale_hold_count_summary)

    assert Enum.any?(
             stale_hold_count_report["errors"],
             &(&1["path"] == "$.reservation_hold_count" and &1["message"] == "must equal 2")
           )

    stale_hold_rows_summary =
      update_in(hold_summary, ["review_rows", Access.at(0)], fn row ->
        Map.put(row, "reservation_statuses", ["confirmed"])
      end)

    assert {:error, stale_hold_rows_report} = Schema.validate_artifact(stale_hold_rows_summary)

    assert Enum.any?(
             stale_hold_rows_report["errors"],
             &(&1["path"] == "$.review_rows[0].reservation_statuses" and
                 &1["message"] == "must include a hold reservation status")
           )

    hold_import_readiness_summary =
      StationCalendar.reservation_hold_import_readiness_summary(reservation_report,
        now_s: 300.0
      )

    assert OrbitalDynamics.station_reservation_hold_import_readiness_summary(
             reservation_report,
             now_s: 300.0
           ) == hold_import_readiness_summary

    assert %{
             "schema_contract" => "station_reservation_hold_import_readiness_summary.v1",
             "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
             "source_artifact_type" => "station_reservation_report.v1",
             "source" => "station_calendar_report.reservation_evidence",
             "model_limits" => ^expected_model_limits,
             "reservation_hold_count" => 2,
             "import_readiness_status" => "review_required",
             "import_classification" => "review_only",
             "ready_for_import_count" => 0,
             "review_required_before_import_count" => 2,
             "no_import_required_count" => 0,
             "reservation_hold_import_status_counts" => %{
               "review_required_before_import" => 2
             },
             "reservation_hold_status_counts" => %{"held" => 2},
             "reservation_hold_expiration_status_counts" => %{
               "expired" => 1,
               "missing" => 1
             },
             "required_import_action_counts" => %{
               "review_station_provider_contention" => 1,
               "review_station_reservation_overlap" => 1
             },
             "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
             "reservation_hold_ids_by_import_status" => %{
               "review_required_before_import" => [
                 "reservation_expired",
                 "reservation_missing"
               ]
             },
             "reservation_hold_ids_by_expiration_status" => %{
               "expired" => ["reservation_expired"],
               "missing" => ["reservation_missing"]
             },
             "reservation_hold_ids_by_status" => %{
               "held" => ["reservation_expired", "reservation_missing"]
             },
             "reservation_hold_ids_by_reserved_by" => %{
               "ops_calendar" => ["reservation_expired"],
               "partner_calendar" => ["reservation_missing"]
             },
             "reservation_hold_ids_by_required_import_action" => %{
               "review_station_provider_contention" => ["reservation_missing"],
               "review_station_reservation_overlap" => ["reservation_expired"]
             },
             "reservation_hold_ids_by_direction" => %{
               "downlink" => ["reservation_expired"],
               "uplink" => ["reservation_missing"]
             },
             "reservation_hold_ids_by_direction_and_ground_station_id" => %{
               "downlink" => %{"equator_prime" => ["reservation_expired"]},
               "uplink" => %{"polar_prime" => ["reservation_missing"]}
             },
             "reservation_hold_contact_ids_by_import_status" => %{
               "review_required_before_import" => ["dl_source_reserved"]
             },
             "reservation_hold_contact_ids_by_expiration_status" => %{
               "expired" => ["dl_source_reserved"]
             },
             "reservation_hold_contact_ids_by_direction" => %{
               "downlink" => ["dl_source_reserved"]
             },
             "reservation_hold_contact_ids_by_direction_and_ground_station_id" => %{
               "downlink" => %{"equator_prime" => ["dl_source_reserved"]}
             },
             "review_contact_ids" => ["dl_source_reserved"],
             "import_readiness_rows" => [
               %{
                 "reservation_review_row_type" => "affected_contact",
                 "contact_id" => "dl_source_reserved",
                 "reservation_ids" => ["reservation_expired"],
                 "station_reservation_hold_import_status" => "review_required_before_import",
                 "required_operator_action" => "review_station_reservation_overlap"
               },
               %{
                 "reservation_review_row_type" => "provider_calendar_contention_group",
                 "reservation_ids" => ["reservation_missing"],
                 "station_reservation_hold_import_status" => "review_required_before_import",
                 "required_operator_action" => "review_station_provider_contention"
               }
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
               "operator_authority" => "not_granted_by_import_readiness_summary",
               "provider_write" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary",
               "reservation_acceptance" => "not_performed_by_summary",
               "deadline_evaluation" => "relative_to_now_s",
               "now_s" => 300.0
             }
           } = hold_import_readiness_summary

    assert %{
             "import_readiness_status" => "clear",
             "import_classification" => "not_applicable",
             "reservation_hold_count" => 0,
             "review_contact_ids" => [],
             "import_readiness_rows" => []
           } =
             StationCalendar.reservation_hold_import_readiness_summary(%{
               reservation_report
               | "affected_contacts" => [],
                 "provider_calendar_contention_groups" => []
             })

    assert {:ok, %{"schema_contract" => "station_reservation_hold_import_readiness_summary.v1"}} =
             Schema.validate_artifact(hold_import_readiness_summary)

    assert {:ok, hold_import_readiness_schema} =
             Schema.json_schema("station_reservation_hold_import_readiness_summary.v1")

    assert get_in(hold_import_readiness_schema, ["properties", "model", "const"]) ==
             "artifact_only_station_reservation_hold_import_readiness_summary"

    assert get_in(hold_import_readiness_schema, ["properties", "model_limits", "const"]) ==
             expected_model_limits

    assert get_in(hold_import_readiness_schema, [
             "properties",
             "model_limits",
             "items",
             "enum"
           ]) == expected_model_limits

    stale_import_model_limits =
      Map.put(hold_import_readiness_summary, "model_limits", ["declared_data_only"])

    assert {:error, stale_import_model_limits_report} =
             Schema.validate_artifact(stale_import_model_limits)

    assert Enum.any?(
             stale_import_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match station calendar report model limits")
           )

    stale_count_summary =
      Map.put(hold_import_readiness_summary, "review_required_before_import_count", 1)

    assert {:error, stale_count_report} = Schema.validate_artifact(stale_count_summary)

    assert Enum.any?(
             stale_count_report["errors"],
             &(&1["path"] == "$.review_required_before_import_count" and
                 &1["message"] == "must equal row-derived review_required_before_import_count")
           )

    stale_direction_summary =
      Map.put(hold_import_readiness_summary, "reservation_hold_ids_by_direction", %{
        "downlink" => ["reservation_missing"]
      })

    assert {:error, stale_direction_report} =
             Schema.validate_artifact(stale_direction_summary)

    assert Enum.any?(
             stale_direction_report["errors"],
             &(&1["path"] == "$.reservation_hold_ids_by_direction" and
                 &1["message"] == "must equal row-derived reservation_hold_ids_by_direction")
           )

    stale_row_summary =
      update_in(hold_import_readiness_summary, ["import_readiness_rows", Access.at(0)], fn row ->
        Map.put(row, "station_reservation_hold_import_status", "ready_for_import")
      end)

    assert {:error, stale_row_report} = Schema.validate_artifact(stale_row_summary)

    assert Enum.any?(
             stale_row_report["errors"],
             &(&1["path"] ==
                 "$.import_readiness_rows[0].station_reservation_hold_import_status" and
                 &1["message"] == "must equal \"review_required_before_import\"")
           )

    assert_summary_handoff(
      summary,
      &StationCalendar.reservation_review_summary/1,
      &StationCalendar.reservation_review_summary(&1, now_s: 999.0),
      &OrbitalDynamics.station_reservation_review_summary/1,
      &OrbitalDynamics.station_reservation_review_summary(&1, now_s: 999.0)
    )

    assert_summary_handoff(
      hold_summary,
      &StationCalendar.reservation_hold_summary/1,
      &StationCalendar.reservation_hold_summary(&1, now_s: 999.0),
      &OrbitalDynamics.station_reservation_hold_summary/1,
      &OrbitalDynamics.station_reservation_hold_summary(&1, now_s: 999.0)
    )

    assert_summary_handoff(
      hold_import_readiness_summary,
      &StationCalendar.reservation_hold_import_readiness_summary/1,
      &StationCalendar.reservation_hold_import_readiness_summary(&1, now_s: 999.0),
      &OrbitalDynamics.station_reservation_hold_import_readiness_summary/1,
      &OrbitalDynamics.station_reservation_hold_import_readiness_summary(&1, now_s: 999.0)
    )
  end

  test "normalizes numeric string provider timing and capacity fields" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      provenance: %{trust_boundary: :operator_declared_station_calendar},
      entries: [
        %{
          id: :equator_capacity,
          station_id: :equator_prime,
          availability: :available,
          start_s: "90.0",
          end_s: "170.0",
          capacity_pack_capacity_fraction: "0.5"
        }
      ]
    }

    {annotated, report} =
      StationCalendar.overlay_contacts(contacts, provider, source: "ops_calendar")

    assert [
             %{
               "id" => "dl_1",
               "station_availability" => "reduced_capacity",
               "station_capacity_fraction" => 0.5,
               "source_station_calendar_entry" => %{
                 "starts_at_s" => 90.0,
                 "ends_at_s" => 170.0,
                 "capacity_pack_capacity_fraction" => 0.5,
                 "capacity_fraction" => 0.5
               }
             }
           ] = annotated

    assert [
             %{
               "station_availability" => "reduced_capacity",
               "capacity_fraction" => 0.5,
               "source_station_calendar_entry" => %{
                 "starts_at_s" => 90.0,
                 "ends_at_s" => 170.0,
                 "capacity_pack_capacity_fraction" => 0.5,
                 "capacity_fraction" => 0.5
               }
             }
           ] = report["affected_contacts"]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes direct station calendar numeric string capacity fields" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    station_calendar = [
      %{
        id: :equator_capacity,
        station_id: :equator_prime,
        availability: :available,
        start_s: "90.0",
        end_s: "170.0",
        capacity_fraction: "0.5"
      }
    ]

    {annotated, report} =
      StationCalendar.overlay_contacts(contacts, station_calendar, source: "declared_calendar")

    assert [
             %{
               "id" => "dl_1",
               "station_availability" => "reduced_capacity",
               "station_capacity_fraction" => 0.5,
               "source_station_calendar_entry" => %{
                 "starts_at_s" => 90.0,
                 "ends_at_s" => 170.0,
                 "capacity_fraction" => 0.5
               }
             }
           ] = annotated

    assert [
             %{
               "station_availability" => "reduced_capacity",
               "capacity_fraction" => 0.5
             }
           ] = report["affected_contacts"]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "rejects out-of-range direct station calendar capacity fields" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    assert_raise ArgumentError, ~r/capacity_fraction must be between 0.0 and 1.0/, fn ->
      StationCalendar.overlay_contacts(
        contacts,
        [
          %{
            id: :bad_capacity,
            station_id: :equator_prime,
            availability: :available,
            start_s: 90.0,
            end_s: 170.0,
            capacity_fraction: 1.2
          }
        ]
      )
    end

    assert_raise ArgumentError, ~r/capacity_fraction must be between 0.0 and 1.0/, fn ->
      StationCalendar.overlay_contacts(
        contacts,
        [
          %{
            id: :bad_availability,
            station_id: :equator_prime,
            availability: "1.2",
            start_s: 90.0,
            end_s: 170.0
          }
        ]
      )
    end
  end

  test "reports calendar entry trust counts even when no contacts are affected" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    calendar = [
      %{
        id: :deep_space_outage,
        station_id: :deep_space_net,
        availability: :unavailable,
        start_s: 90.0,
        end_s: 170.0,
        provenance: %{trust_boundary: :partner_api}
      },
      %{
        id: :polar_reserved,
        station_id: :polar_station,
        availability: :reserved,
        start_s: 90.0,
        end_s: 170.0
      }
    ]

    {_annotated, report} =
      StationCalendar.overlay_contacts(contacts, calendar, source: "ops_calendar")

    assert %{
             "calendar_entry_count" => 2,
             "calendar_entry_trust_boundary_status_counts" => %{
               "declared" => 1,
               "missing" => 1
             },
             "affected_contact_count" => 0,
             "station_calendar_trust_boundary_status_counts" => %{},
             "affected_contacts" => []
           } = report

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "scopes provider station calendar entries by station-calendar direction aliases" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      },
      %{
        id: :cmd_1,
        type: :command,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 110.0,
        ends_at_s: 150.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      provenance: %{trust_boundary: :operator_declared_station_calendar},
      entries: [
        %{
          id: :equator_command_outage,
          station_id: :equator_prime,
          availability: :maintenance,
          station_calendar_directions: [:commanding],
          start_s: 90.0,
          end_s: 170.0
        }
      ]
    }

    {annotated, report} = StationCalendar.overlay_contacts(contacts, provider)

    assert [
             %{"id" => "dl_1"},
             %{
               "id" => "cmd_1",
               "station_availability" => "unavailable",
               "station_calendar_status" => "maintenance",
               "station_calendar_directions" => ["command"]
             }
           ] = annotated

    assert [
             %{
               "contact_id" => "cmd_1",
               "station_calendar_directions" => ["command"],
               "source_station_calendar_entry" => %{
                 "directions" => ["command"]
               }
             }
           ] = report["affected_contacts"]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes whitespace and hyphenated provider direction aliases" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      },
      %{
        id: :tracking_1,
        type: :tracking,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      },
      %{
        id: :health_1,
        type: :health_check,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      entries: [
        %{
          id: :equator_downlink,
          station_id: :equator_prime,
          availability: :maintenance,
          direction: "Down Link",
          start_s: 90.0,
          end_s: 170.0
        },
        %{
          id: :equator_tracking,
          station_id: :equator_prime,
          availability: :maintenance,
          direction: "Track-ing",
          start_s: 90.0,
          end_s: 170.0
        },
        %{
          id: :equator_health,
          station_id: :equator_prime,
          availability: :maintenance,
          direction: "healthcheck",
          start_s: 90.0,
          end_s: 170.0
        }
      ]
    }

    {annotated, report} = StationCalendar.overlay_contacts(contacts, provider)

    assert Enum.map(annotated, &{&1["id"], &1["station_calendar_directions"]}) == [
             {"dl_1", ["downlink"]},
             {"tracking_1", ["tracking"]},
             {"health_1", ["health_check"]}
           ]

    assert Enum.map(
             report["affected_contacts"],
             &{&1["contact_id"], &1["station_calendar_directions"]}
           ) == [
             {"dl_1", ["downlink"]},
             {"tracking_1", ["tracking"]},
             {"health_1", ["health_check"]}
           ]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes numeric provider availability as reduced station capacity" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        throughput_model: %{"estimated_throughput_mb" => 42.0}
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      entries: [
        %{
          id: :equator_numeric_capacity,
          station_id: :equator_prime,
          availability: 0.5,
          start_s: 90.0,
          end_s: 170.0
        }
      ]
    }

    {annotated, report} = StationCalendar.overlay_contacts(contacts, provider)

    assert [
             %{
               "id" => "dl_1",
               "station_availability" => "reduced_capacity",
               "station_calendar_status" => "reduced_capacity",
               "station_capacity_fraction" => 0.5,
               "throughput_model" => %{"station_capacity_fraction" => 0.5}
             }
           ] = annotated

    assert [
             %{
               "station_availability" => "reduced_capacity",
               "status" => "reduced_capacity",
               "capacity_fraction" => 0.5,
               "source_station_calendar_entry" => %{
                 "availability" => "reduced_capacity",
                 "capacity_fraction" => 0.5
               }
             }
           ] = report["affected_contacts"]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes numeric raw station-calendar availability as reduced capacity" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        throughput_model: %{"estimated_throughput_mb" => 42.0}
      }
    ]

    ground_network = [
      %{
        id: :equator_numeric_capacity,
        ground_station_id: :equator_prime,
        availability: 0.5,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    {annotated, report} = StationCalendar.overlay_contacts(contacts, ground_network)

    assert [
             %{
               "id" => "dl_1",
               "station_availability" => "reduced_capacity",
               "station_calendar_status" => "reduced_capacity",
               "station_capacity_fraction" => 0.5
             }
           ] = annotated

    assert [
             %{
               "station_availability" => "reduced_capacity",
               "status" => "reduced_capacity",
               "capacity_fraction" => 0.5,
               "source_station_calendar_entry" => %{
                 "status" => "reduced_capacity",
                 "availability" => "reduced_capacity",
                 "capacity_fraction" => 0.5
               }
             }
           ] = report["affected_contacts"]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "overlays station-id-only provider contacts" do
    contacts = [
      %{
        id: :provider_contact,
        type: :contact,
        direction: :downlink,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        throughput_model: %{"estimated_throughput_mb" => 42.0}
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      provenance: %{trust_boundary: :operator_declared_station_calendar},
      entries: [
        %{
          id: :equator_capacity,
          station_id: :equator_prime,
          availability: :available,
          start_s: 90.0,
          end_s: 170.0,
          capacity_fraction: 0.5
        }
      ]
    }

    {annotated, report} = StationCalendar.overlay_contacts(contacts, provider)

    assert [
             %{
               "id" => "provider_contact",
               "ground_station_id" => "equator_prime",
               "station_availability" => "reduced_capacity",
               "station_capacity_fraction" => 0.5,
               "throughput_model" => %{"station_capacity_fraction" => 0.5}
             }
           ] = annotated

    assert %{
             "input_contact_count" => 1,
             "affected_contact_count" => 1,
             "affected_contacts" => [
               %{
                 "contact_id" => "provider_contact",
                 "ground_station_id" => "equator_prime",
                 "station_calendar_entry_id" => "equator_capacity",
                 "station_availability" => "reduced_capacity"
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "applies direction-scoped station calendar entries only to matching contacts" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        direction: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      },
      %{
        id: :cmd_1,
        type: :command,
        direction: :uplink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 110.0,
        ends_at_s: 140.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      entries: [
        %{
          id: :equator_uplink_reserved,
          station_id: :equator_prime,
          direction: :uplink,
          availability: :reserved,
          start_s: 90.0,
          end_s: 170.0,
          reservation_id: :uplink_reservation
        }
      ]
    }

    {[downlink, command], report} = StationCalendar.overlay_contacts(contacts, provider)

    refute Map.has_key?(downlink, "station_availability")

    assert %{
             "id" => "cmd_1",
             "station_availability" => "reserved",
             "station_calendar_directions" => ["uplink"],
             "station_calendar_entry_id" => "equator_uplink_reserved",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "uplink_reservation"
           } = command

    assert %{
             "input_contact_count" => 2,
             "calendar_entry_count" => 1,
             "affected_contact_count" => 1,
             "affected_contacts" => [
               %{
                 "contact_id" => "cmd_1",
                 "direction" => "uplink",
                 "station_calendar_directions" => ["uplink"],
                 "station_calendar_entry_id" => "equator_uplink_reserved",
                 "source_station_calendar_entry" => %{
                   "directions" => ["uplink"],
                   "reservation_id" => "uplink_reservation"
                 }
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "treats command and uplink station-calendar directions as the same command boundary" do
    contacts = [
      %{
        id: :typed_command,
        type: :command,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 140.0
      },
      %{
        id: :explicit_uplink,
        type: :planned_contact,
        direction: :uplink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 150.0,
        ends_at_s: 180.0
      },
      %{
        id: :downlink,
        type: :downlink,
        direction: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 110.0,
        ends_at_s: 130.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      entries: [
        %{
          id: :equator_uplink_reserved,
          station_id: :equator_prime,
          direction: :uplink,
          availability: :reserved,
          start_s: 90.0,
          end_s: 145.0,
          reservation_id: :uplink_reservation
        },
        %{
          id: :equator_command_reserved,
          station_id: :equator_prime,
          direction: :command,
          availability: :reserved,
          start_s: 145.0,
          end_s: 190.0,
          reservation_id: :command_reservation
        }
      ]
    }

    {[typed_command, explicit_uplink, downlink], report} =
      StationCalendar.overlay_contacts(contacts, provider)

    assert %{
             "id" => "typed_command",
             "station_calendar_entry_id" => "equator_uplink_reserved",
             "station_calendar_directions" => ["uplink"],
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "uplink_reservation"
           } = typed_command

    assert %{
             "id" => "explicit_uplink",
             "station_calendar_entry_id" => "equator_command_reserved",
             "station_calendar_directions" => ["command"],
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "command_reservation"
           } = explicit_uplink

    refute Map.has_key?(downlink, "station_availability")

    assert Enum.map(report["affected_contacts"], &{&1["contact_id"], &1["direction"]}) == [
             {"typed_command", nil},
             {"explicit_uplink", "uplink"}
           ]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "infers tracking and health-check directions from typed contacts" do
    contacts = [
      %{
        id: :tracking_1,
        type: :tracking,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 140.0
      },
      %{
        id: :health_1,
        type: :health_check,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 150.0,
        ends_at_s: 180.0
      },
      %{
        id: :command_1,
        type: :command,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 155.0,
        ends_at_s: 175.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      entries: [
        %{
          id: :tracking_reserved,
          station_id: :equator_prime,
          direction: :tracking,
          availability: :reserved,
          start_s: 90.0,
          end_s: 145.0,
          reservation_id: :tracking_reservation
        },
        %{
          id: :health_outage,
          station_id: :equator_prime,
          direction: :health_check,
          availability: :maintenance,
          start_s: 145.0,
          end_s: 190.0
        }
      ]
    }

    {[tracking, health_check, command], report} =
      StationCalendar.overlay_contacts(contacts, provider)

    assert %{
             "id" => "tracking_1",
             "station_calendar_entry_id" => "tracking_reserved",
             "station_calendar_directions" => ["tracking"],
             "station_reservation_id" => "tracking_reservation",
             "station_reservation_match_status" => "overlap"
           } = tracking

    assert %{
             "id" => "health_1",
             "station_calendar_entry_id" => "health_outage",
             "station_calendar_directions" => ["health_check"],
             "station_availability" => "unavailable"
           } = health_check

    refute Map.has_key?(command, "station_availability")

    assert Enum.map(
             report["affected_contacts"],
             &{&1["contact_id"], &1["contact_type"], &1["direction"],
              &1["station_calendar_directions"], &1["required_operator_action"]}
           ) == [
             {"tracking_1", "tracking", nil, ["tracking"], "review_station_reservation_overlap"},
             {"health_1", "health_check", nil, ["health_check"], "review_station_availability"}
           ]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "reserved station calendar entries take precedence over reduced capacity overlaps" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    calendar = [
      %{
        id: :equator_capacity,
        ground_station_id: :equator_prime,
        status: "Available",
        availability: "Reduced-Capacity",
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        capacity_fraction: 0.5
      },
      %{
        id: :equator_reserved,
        ground_station_id: :equator_prime,
        availability: "Reserved",
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        reservation_id: :reservation_42,
        reserved_by: :ops_team_b
      }
    ]

    {[%{"id" => "dl_1"} = contact], report} =
      StationCalendar.overlay_contacts(contacts, calendar,
        source: "ops_calendar",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert contact["station_availability"] == "reserved"
    assert contact["station_calendar_entry_id"] == "equator_reserved"
    assert contact["station_contention_status"] == "reserved_overlap"
    assert contact["station_reservation_id"] == "reservation_42"
    assert contact["station_reserved_by"] == "ops_team_b"
    assert contact["station_reservation_status"] == "reserved"
    assert contact["station_calendar_overlap_count"] == 2

    assert contact["station_calendar_overlap_entry_ids"] == [
             "equator_reserved",
             "equator_capacity"
           ]

    assert contact["station_calendar_overlap_availabilities"] == ["reserved", "reduced_capacity"]

    assert [
             %{
               "station_calendar_entry_id" => "equator_reserved",
               "station_availability" => "reserved",
               "station_calendar_overlap_count" => 2,
               "station_calendar_overlap_entry_ids" => ["equator_reserved", "equator_capacity"],
               "station_calendar_overlap_availabilities" => ["reserved", "reduced_capacity"],
               "station_contention_status" => "reserved_overlap",
               "station_reservation_id" => "reservation_42",
               "station_reserved_by" => "ops_team_b",
               "station_reservation_status" => "reserved",
               "station_reservation_match_status" => "overlap",
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "station_contention_status" => "reserved_overlap",
                     "station_reservation_id" => "reservation_42",
                     "station_reserved_by" => "ops_team_b",
                     "station_reservation_status" => "reserved",
                     "station_reservation_match_status" => "overlap"
                   }
                 }
               ],
               "source_station_calendar_entry" => %{
                 "id" => "equator_reserved",
                 "availability" => "reserved"
               },
               "source_station_calendar_overlaps" => [
                 %{"id" => "equator_reserved", "availability" => "reserved"},
                 %{"id" => "equator_capacity", "availability" => "reduced_capacity"}
               ]
             }
           ] = report["affected_contacts"]

    assert report["station_calendar_trust_boundary_status_counts"] == %{"missing" => 1}

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "unavailable station entries take precedence while preserving reservation overlap evidence" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    calendar = [
      %{
        id: :equator_capacity,
        ground_station_id: :equator_prime,
        availability: :reduced_capacity,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        capacity_fraction: 0.5
      },
      %{
        id: :equator_reserved,
        ground_station_id: :equator_prime,
        availability: :reserved,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        reservation_id: :reservation_42,
        reserved_by: :ops_team_b
      },
      %{
        id: :equator_maintenance,
        ground_station_id: :equator_prime,
        availability: :maintenance,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      }
    ]

    {[%{"id" => "dl_1"} = contact], report} =
      StationCalendar.overlay_contacts(contacts, calendar)

    assert contact["station_availability"] == "unavailable"
    assert contact["station_calendar_status"] == "maintenance"
    assert contact["station_calendar_entry_id"] == "equator_maintenance"
    assert contact["station_calendar_precedence_rank"] == 0
    assert contact["station_calendar_precedence_availability"] == "unavailable"
    assert contact["station_contention_status"] == "reserved_overlap"
    assert contact["station_reservation_id"] == "reservation_42"
    assert contact["station_reserved_by"] == "ops_team_b"
    assert contact["station_reservation_status"] == "reserved"

    assert contact["station_calendar_overlap_entry_ids"] == [
             "equator_maintenance",
             "equator_reserved",
             "equator_capacity"
           ]

    assert contact["station_calendar_overlap_availabilities"] == [
             "unavailable",
             "reserved",
             "reduced_capacity"
           ]

    assert [
             %{
               "station_calendar_entry_id" => "equator_maintenance",
               "station_availability" => "unavailable",
               "status" => "maintenance",
               "station_calendar_precedence_rank" => 0,
               "station_calendar_precedence_availability" => "unavailable",
               "station_contention_status" => "reserved_overlap",
               "station_reservation_id" => "reservation_42",
               "station_reserved_by" => "ops_team_b",
               "station_reservation_status" => "reserved",
               "station_reservation_match_status" => "overlap",
               "station_calendar_reservation_ids" => ["reservation_42"],
               "required_operator_action" => "review_station_reservation_overlap"
             }
           ] = report["affected_contacts"]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "applied_availability_counts" => %{"unavailable" => 1},
             "applied_status_counts" => %{"maintenance" => 1},
             "affected_contact_ids_by_applied_availability" => %{
               "unavailable" => ["dl_1"]
             },
             "affected_contact_ids_by_applied_status" => %{
               "maintenance" => ["dl_1"]
             },
             "reserved_under_higher_precedence_contact_ids_by_applied_availability" => %{
               "unavailable" => ["dl_1"]
             },
             "reserved_under_higher_precedence_contact_ids_by_applied_status" => %{
               "maintenance" => ["dl_1"]
             }
           } = precedence_summary = StationCalendar.precedence_summary(report)

    assert {:ok, %{"schema_contract" => "station_calendar_precedence_summary.v1"}} =
             Schema.validate_artifact(precedence_summary)
  end

  test "marks same-priority station calendar ambiguity without choosing capacity metadata" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    calendar = [
      %{
        id: :equator_capacity_low,
        ground_station_id: :equator_prime,
        status: :available,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        capacity_fraction: 0.25
      },
      %{
        id: :equator_capacity_high,
        ground_station_id: :equator_prime,
        status: :available,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        capacity_fraction: 0.75
      }
    ]

    {[%{"id" => "dl_1"} = contact], report} =
      StationCalendar.overlay_contacts(contacts, calendar,
        source: "ops_calendar",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert contact["station_availability"] == "reduced_capacity"

    assert contact["station_calendar_entry_id"] ==
             "ambiguous_station_calendar:equator_capacity_high:equator_capacity_low"

    assert contact["station_calendar_entry_ambiguous"]
    assert contact["station_calendar_ambiguous_entry_count"] == 2

    assert contact["station_calendar_ambiguous_entry_ids"] == [
             "equator_capacity_high",
             "equator_capacity_low"
           ]

    refute Map.has_key?(contact, "station_capacity_fraction")
    refute Map.has_key?(contact, "throughput_model")

    assert [
             %{
               "station_calendar_entry_id" =>
                 "ambiguous_station_calendar:equator_capacity_high:equator_capacity_low",
               "station_availability" => "reduced_capacity",
               "station_calendar_entry_ambiguous" => true,
               "station_calendar_ambiguous_entry_count" => 2,
               "station_calendar_ambiguous_entry_ids" => [
                 "equator_capacity_high",
                 "equator_capacity_low"
               ],
               "station_calendar_overlap_count" => 2,
               "station_calendar_overlap_entry_ids" => [
                 "equator_capacity_high",
                 "equator_capacity_low"
               ],
               "required_operator_action" => "review_reduced_station_capacity"
             }
           ] = report["affected_contacts"]

    refute Map.has_key?(List.first(report["affected_contacts"]), "capacity_fraction")

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "marks ambiguous reserved station entries without choosing singular reservation metadata" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    calendar = [
      %{
        id: :equator_reserved_a,
        ground_station_id: :equator_prime,
        availability: :reserved,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        reservation_id: :reservation_a,
        reserved_by: :ops_team_a,
        reservation_status: :tentative
      },
      %{
        id: :equator_reserved_b,
        ground_station_id: :equator_prime,
        availability: :reserved,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        reservation_id: :reservation_b,
        reserved_by: :ops_team_b,
        reservation_status: :confirmed
      }
    ]

    {[%{"id" => "dl_1"} = contact], report} =
      StationCalendar.overlay_contacts(contacts, calendar,
        source: "ops_calendar",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert contact["station_availability"] == "reserved"
    assert contact["station_contention_status"] == "reserved_overlap"

    assert contact["station_calendar_entry_id"] ==
             "ambiguous_station_calendar:equator_reserved_a:equator_reserved_b"

    refute Map.has_key?(contact, "station_reservation_id")
    refute Map.has_key?(contact, "station_reserved_by")
    refute Map.has_key?(contact, "station_reservation_status")

    assert contact["station_calendar_reservation_overlap_count"] == 2
    assert contact["station_calendar_reservation_ids"] == ["reservation_a", "reservation_b"]
    assert contact["station_calendar_reserved_by"] == ["ops_team_a", "ops_team_b"]
    assert contact["station_calendar_reservation_statuses"] == ["tentative", "confirmed"]

    assert [
             %{
               "station_calendar_entry_id" =>
                 "ambiguous_station_calendar:equator_reserved_a:equator_reserved_b",
               "station_availability" => "reserved",
               "station_calendar_entry_ambiguous" => true,
               "station_calendar_ambiguous_entry_ids" => [
                 "equator_reserved_a",
                 "equator_reserved_b"
               ],
               "station_contention_status" => "reserved_overlap",
               "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
               "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
               "station_calendar_reservation_statuses" => ["tentative", "confirmed"],
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "station_calendar_entry_ambiguous" => true,
                     "station_calendar_ambiguous_entry_count" => 2,
                     "station_calendar_ambiguous_entry_ids" => [
                       "equator_reserved_a",
                       "equator_reserved_b"
                     ],
                     "station_calendar_reservation_ids" => [
                       "reservation_a",
                       "reservation_b"
                     ],
                     "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
                     "station_calendar_reservation_statuses" => ["tentative", "confirmed"]
                   }
                 }
               ],
               "required_operator_action" => "review_station_reservation_overlap"
             } = affected
           ] = report["affected_contacts"]

    refute Map.has_key?(affected, "station_reservation_id")
    refute Map.has_key?(affected, "station_reserved_by")
    refute Map.has_key?(affected, "station_reservation_status")

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "routes provider calendar reservation owner and status lists through approval policy" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    calendar = [
      %{
        id: :equator_reserved_a,
        ground_station_id: :equator_prime,
        availability: :reserved,
        starts_at_s: 80.0,
        ends_at_s: 180.0,
        reservation_id: :reservation_a,
        reserved_by: :ops_team_a,
        reservation_status: :tentative
      },
      %{
        id: :equator_reserved_b,
        ground_station_id: :equator_prime,
        availability: :reserved,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        reservation_id: :reservation_b,
        reserved_by: :ops_team_b,
        reservation_status: :confirmed
      }
    ]

    approval_policy = %{
      action_rules: [
        %{
          id: :provider_calendar_owner_status_review,
          station_calendar_entry_ambiguous: true,
          station_calendar_ambiguous_entry_count_min: 2,
          station_calendar_ambiguous_entry_ids: [:equator_reserved_b],
          station_calendar_reserved_bys: [:ops_team_b],
          station_calendar_reservation_statuses: [:confirmed],
          classification: :operator_review_required,
          reason: "confirmed provider reservations require ground-network review"
        }
      ]
    }

    {_contacts, report} =
      StationCalendar.overlay_contacts(contacts, calendar,
        source: "ops_calendar",
        approval_policy: approval_policy
      )

    assert [
             %{
               "station_calendar_entry_ambiguous" => true,
               "station_calendar_ambiguous_entry_count" => 2,
               "station_calendar_ambiguous_entry_ids" => [
                 "equator_reserved_a",
                 "equator_reserved_b"
               ],
               "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
               "station_calendar_reservation_statuses" => ["tentative", "confirmed"],
               "approval_status" => "operator_review_required",
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "provider_calendar_owner_status_review",
                   "station_calendar_entry_ambiguous" => true,
                   "station_calendar_ambiguous_entry_count" => 2,
                   "station_calendar_ambiguous_entry_ids" => [
                     "equator_reserved_a",
                     "equator_reserved_b"
                   ],
                   "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
                   "station_calendar_reservation_statuses" => ["tentative", "confirmed"]
                 }
               ]
             }
           ] = report["affected_contacts"]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "routes provider calendar contention groups through schema review and import contracts" do
    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      provenance: %{trust_boundary: :operator_declared_station_calendar},
      entries: [
        %{
          id: :equator_reserved_a,
          station_id: :equator_prime,
          direction: :downlink,
          availability: :reserved,
          start_s: 100.0,
          end_s: 160.0,
          reservation_id: :reservation_a,
          reserved_by: :network_a,
          reservation_status: :confirmed,
          reservation_expires_at_s: 300.0
        },
        %{
          id: :equator_reserved_b,
          station_id: :equator_prime,
          direction: :downlink,
          availability: :reserved,
          start_s: 140.0,
          end_s: 180.0,
          reservation_id: :reservation_b,
          reserved_by: :network_b,
          reservation_status: :planned,
          reservation_expires_at_s: "420.0"
        }
      ]
    }

    {_contacts, report} =
      StationCalendar.overlay_contacts([], provider,
        source: "ops_calendar",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "affected_contact_count" => 0,
             "provider_calendar_contention_group_count" => 1,
             "provider_calendar_contention_groups" => [
               %{
                 "id" => "station_calendar_provider_contention:equator_prime:1",
                 "provider_calendar_contention_status" => "provider_calendar_overlap",
                 "required_operator_action" => "review_station_provider_contention",
                 "approval_status" => "operator_review_required",
                 "operator_action_reason" => "overlapping_provider_calendar_entries",
                 "ground_station_id" => "equator_prime",
                 "starts_at_s" => 140.0,
                 "ends_at_s" => 160.0,
                 "overlap_duration_s" => 20.0,
                 "entry_count" => 2,
                 "entry_ids" => ["equator_reserved_a", "equator_reserved_b"],
                 "provider_ids" => ["ops_calendar"],
                 "provider_entry_ids" => ["equator_reserved_a", "equator_reserved_b"],
                 "availabilities" => ["reserved"],
                 "directions" => ["downlink"],
                 "reservation_ids" => ["reservation_a", "reservation_b"],
                 "reserved_by" => ["network_a", "network_b"],
                 "reservation_statuses" => ["confirmed", "planned"],
                 "reservation_expires_at_s" => [300.0, 420.0],
                 "trust_boundary_statuses" => ["declared"],
                 "overlap_pairs" => [
                   %{
                     "left_entry_id" => "equator_reserved_a",
                     "right_entry_id" => "equator_reserved_b",
                     "overlap_starts_at_s" => 140.0,
                     "overlap_ends_at_s" => 160.0,
                     "overlap_duration_s" => 20.0
                   }
                 ],
                 "source_station_calendar_entries" => source_entries
               } = group
             ]
           } = report

    assert length(source_entries) == 2

    assert Enum.any?(
             group["approval_rule_matches"],
             &(&1["rule_id"] == "declared_provider_calendar_contention_review" and
                 &1["station_calendar_provider_ids"] == ["ops_calendar"] and
                 &1["station_calendar_reservation_expires_at_s"] == [300.0, 420.0] and
                 &1["station_calendar_trust_boundary_statuses"] == ["declared"] and
                 &1["escalation_queue"] == "ground_network")
           )

    assert [
             %{
               "activity_context" => %{
                 "station_calendar_reservation_expires_at_s" => [300.0, 420.0]
               }
             }
           ] = group["approval_requirements"]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_count = Map.put(report, "provider_calendar_contention_group_count", 2)

    assert {:error, validation} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             validation["errors"],
             &(&1["path"] == "$.provider_calendar_contention_group_count" and
                 &1["message"] == "must equal 1")
           )

    invalid_expiration =
      put_in(
        report,
        ["provider_calendar_contention_groups", Access.at(0), "reservation_expires_at_s"],
        ["soon"]
      )

    assert {:error, validation} = Schema.validate_artifact(invalid_expiration)

    assert Enum.any?(
             validation["errors"],
             &(&1["path"] ==
                 "$.provider_calendar_contention_groups[0].reservation_expires_at_s[0]" and
                 &1["message"] == "must be a number")
           )

    review = OperatorReview.from_station_calendar_report(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert [
             %{
               "review_type" => "station_calendar_review",
               "source" => "station_calendar_report.provider_calendar_contention_groups",
               "subject_id" => "station_calendar_provider_contention:equator_prime:1",
               "ground_station_id" => "equator_prime",
               "action" => "review_station_provider_contention",
               "required_operator_action" => "review_station_provider_contention",
               "approval_status" => "operator_review_required",
               "provider_calendar_contention_status" => "provider_calendar_overlap",
               "provider_calendar_contention_entry_count" => 2,
               "provider_calendar_contention_entry_ids" => [
                 "equator_reserved_a",
                 "equator_reserved_b"
               ],
               "provider_calendar_contention_reservation_expires_at_s" => [300.0, 420.0],
               "escalation_queue" => "ground_network",
               "required_authority" => "contact_schedule_authority",
               "source_policy_escalation" => %{
                 "rule_id" => "declared_provider_calendar_contention_review",
                 "escalation_queue" => "ground_network"
               },
               "source_station_calendar_provider_contention" => ^group
             }
           ] = review["rows"]

    manifest = CadenceImport.from_station_calendar_report(report)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert [
             %{
               "import_action" => "review_station_calendar",
               "source_review_type" => "station_calendar_review",
               "source_review_action" => "review_station_provider_contention",
               "provider_calendar_contention_status" => "provider_calendar_overlap",
               "provider_calendar_contention_entry_count" => 2,
               "provider_calendar_contention_entry_ids" => [
                 "equator_reserved_a",
                 "equator_reserved_b"
               ],
               "provider_calendar_contention_reservation_expires_at_s" => [300.0, 420.0],
               "escalation_queue" => "ground_network",
               "required_authority" => "contact_schedule_authority",
               "source_policy_escalation" => %{
                 "rule_id" => "declared_provider_calendar_contention_review",
                 "escalation_queue" => "ground_network"
               },
               "source_station_calendar_provider_contention" => ^group,
               "source_review_row" => %{
                 "review_type" => "station_calendar_review",
                 "provider_calendar_contention_group_id" =>
                   "station_calendar_provider_contention:equator_prime:1",
                 "provider_calendar_contention_entry_count" => 2
               }
             }
           ] = manifest["rows"]

    invalid_manifest =
      update_in(manifest, ["rows", Access.at(0), "source_review_row"], fn row ->
        Map.put(row, "provider_calendar_contention_entry_count", 1)
      end)

    assert {:error, validation} = Schema.validate_artifact(invalid_manifest)

    assert Enum.any?(
             validation["errors"],
             &(&1["path"] ==
                 "$.rows[0].source_review_row.provider_calendar_contention_entry_count" and
                 &1["message"] ==
                   "must match provider_calendar_contention_entry_count on Cadence import row")
           )
  end

  test "omits provider calendar overlap pair timings when contention window is open ended" do
    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      provenance: %{trust_boundary: :operator_declared_station_calendar},
      entries: [
        %{
          id: :equator_reserved_a,
          station_id: :equator_prime,
          direction: :downlink,
          availability: :reserved,
          reservation_id: :reservation_a
        },
        %{
          id: :equator_reserved_b,
          station_id: :equator_prime,
          direction: :downlink,
          availability: :reserved,
          reservation_id: :reservation_b
        }
      ]
    }

    {_contacts, report} = StationCalendar.overlay_contacts([], provider)

    assert %{
             "provider_calendar_contention_group_count" => 1,
             "provider_calendar_contention_groups" => [
               %{
                 "entry_count" => 2,
                 "entry_ids" => ["equator_reserved_a", "equator_reserved_b"],
                 "overlap_pairs" => []
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves reservation overlaps when an outage is the applied station event" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    calendar = [
      %{
        id: :equator_outage,
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      },
      %{
        id: :equator_reserved,
        ground_station_id: :equator_prime,
        availability: :reserved,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        reservation_id: :reservation_42,
        reserved_by: :ops_team_b,
        reservation_status: :confirmed
      }
    ]

    {[%{"id" => "dl_1"} = contact], report} =
      StationCalendar.overlay_contacts(contacts, calendar, source: "ops_calendar")

    assert contact["station_availability"] == "unavailable"
    assert contact["station_calendar_entry_id"] == "equator_outage"
    assert contact["station_contention_status"] == "reserved_overlap"
    assert contact["station_reservation_id"] == "reservation_42"
    assert contact["station_calendar_overlap_entry_ids"] == ["equator_outage", "equator_reserved"]
    assert contact["station_calendar_overlap_availabilities"] == ["unavailable", "reserved"]
    assert contact["station_calendar_reservation_overlap_count"] == 1
    assert contact["station_calendar_reservation_ids"] == ["reservation_42"]
    assert contact["station_calendar_reserved_by"] == ["ops_team_b"]
    assert contact["station_calendar_reservation_statuses"] == ["confirmed"]

    assert [
             %{
               "station_calendar_entry_id" => "equator_outage",
               "station_availability" => "unavailable",
               "station_contention_status" => "reserved_overlap",
               "station_reservation_id" => "reservation_42",
               "station_calendar_reservation_overlap_count" => 1,
               "station_calendar_reservation_ids" => ["reservation_42"],
               "station_calendar_reserved_by" => ["ops_team_b"],
               "station_calendar_reservation_statuses" => ["confirmed"]
             }
           ] = report["affected_contacts"]

    assert %{
             "required_operator_action" => "review_station_reservation_overlap",
             "station_availability" => "unavailable",
             "station_contention_status" => "reserved_overlap",
             "station_calendar_reservation_ids" => ["reservation_42"]
           } =
             report
             |> OperatorReview.from_station_calendar_report()
             |> Map.get("rows")
             |> List.first()

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "canonicalizes provider outage aliases before applying availability precedence" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      entries: [
        %{
          id: :equator_reduced,
          station_id: :equator_prime,
          availability: :available,
          capacity_fraction: 0.5,
          start_s: 90.0,
          end_s: 170.0
        },
        %{
          id: :equator_reserved,
          station_id: :equator_prime,
          availability: :reserved,
          reservation_id: :reservation_42,
          reserved_by: :ops_team_b,
          reservation_status: :confirmed,
          start_s: 90.0,
          end_s: 170.0
        },
        %{
          id: :equator_outage,
          station_id: :equator_prime,
          availability: "Outage",
          start_s: 90.0,
          end_s: 170.0
        }
      ]
    }

    schema_provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      trust_boundary: :declared_station_calendar,
      entries: [
        %{id: :provider_outage, station_id: :equator_prime, availability: :outage},
        %{id: :provider_down, station_id: :polar_prime, availability: :down},
        %{id: :provider_offline, station_id: :desert_prime, availability: :offline}
      ]
    }

    assert {:ok, %{"schema_contract" => "station_calendar_provider.v1"}} =
             schema_provider
             |> stringify_keys()
             |> Schema.validate_artifact()

    assert %{"availability" => "unavailable", "status" => "unavailable"} =
             provider
             |> StationCalendar.to_ground_network()
             |> Enum.find(&(&1["id"] == "equator_outage"))

    {[%{"id" => "dl_1"} = contact], report} =
      StationCalendar.overlay_contacts(contacts, provider, source: "ops_calendar")

    assert contact["station_availability"] == "unavailable"
    assert contact["station_calendar_status"] == "unavailable"
    assert contact["station_calendar_entry_id"] == "equator_outage"
    assert contact["station_contention_status"] == "reserved_overlap"
    assert contact["station_reservation_id"] == "reservation_42"
    assert contact["station_calendar_overlap_count"] == 3

    assert contact["station_calendar_overlap_entry_ids"] == [
             "equator_outage",
             "equator_reserved",
             "equator_reduced"
           ]

    assert contact["station_calendar_overlap_availabilities"] == [
             "unavailable",
             "reserved",
             "reduced_capacity"
           ]

    assert [
             %{
               "station_calendar_entry_id" => "equator_outage",
               "station_availability" => "unavailable",
               "station_calendar_overlap_count" => 3,
               "station_calendar_reservation_overlap_count" => 1,
               "station_calendar_reservation_ids" => ["reservation_42"],
               "station_calendar_reserved_by" => ["ops_team_b"],
               "station_calendar_reservation_statuses" => ["confirmed"],
               "source_station_calendar_entry" => %{
                 "id" => "equator_outage",
                 "availability" => "unavailable"
               },
               "source_station_calendar_overlaps" => [
                 %{"id" => "equator_outage", "availability" => "unavailable"},
                 %{"id" => "equator_reserved", "availability" => "reserved"},
                 %{"id" => "equator_reduced", "availability" => "reduced_capacity"}
               ]
             }
           ] = report["affected_contacts"]

    assert %{
             "schema_contract" => "station_calendar_precedence_summary.v1",
             "model" => "artifact_only_station_calendar_precedence_summary",
             "model_limits" => precedence_model_limits,
             "source_artifact_type" => "station_calendar_report.v1",
             "source" => "ops_calendar",
             "affected_contact_count" => 1,
             "precedence_review_status" => "review_required",
             "applied_availability_counts" => %{"unavailable" => 1},
             "overlap_availability_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "affected_contact_ids_by_applied_availability" => %{
               "unavailable" => ["dl_1"]
             },
             "affected_contact_ids_by_overlap_availability" => %{
               "reduced_capacity" => ["dl_1"],
               "reserved" => ["dl_1"],
               "unavailable" => ["dl_1"]
             },
             "reserved_under_higher_precedence_contact_count" => 1,
             "reserved_under_higher_precedence_contact_ids" => ["dl_1"],
             "reserved_under_higher_precedence_contact_ids_by_applied_availability" => %{
               "unavailable" => ["dl_1"]
             },
             "reserved_under_higher_precedence_reservation_ids" => ["reservation_42"],
             "reserved_under_higher_precedence_reservation_ids_by_status" => %{
               "confirmed" => ["reservation_42"]
             },
             "reserved_under_higher_precedence_reservation_ids_by_reserved_by" => %{
               "ops_team_b" => ["reservation_42"]
             },
             "reserved_under_higher_precedence_contact_ids_by_reservation_status" => %{
               "confirmed" => ["dl_1"]
             },
             "reserved_under_higher_precedence_contact_ids_by_reserved_by" => %{
               "ops_team_b" => ["dl_1"]
             },
             "unavailable_contact_ids" => ["dl_1"],
             "reserved_overlap_contact_ids" => ["dl_1"],
             "reduced_capacity_contact_ids" => ["dl_1"],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_reservation",
               "scope" => "station_calendar_availability_precedence_review",
               "operator_authority" => "not_granted_by_summary"
             }
           } = precedence_summary = StationCalendar.precedence_summary(report)

    assert precedence_model_limits ==
             StationCalendar.capabilities().known_limits
             |> Enum.map(&Atom.to_string/1)

    assert OrbitalDynamics.station_calendar_precedence_summary(report) == precedence_summary

    assert StationCalendar.precedence_summary(contacts, provider, source: "ops_calendar") ==
             precedence_summary

    assert %{
             "precedence_review_status" => "clear",
             "affected_contact_count" => 0,
             "affected_contact_ids_by_applied_availability" => %{}
           } =
             StationCalendar.precedence_summary(%{
               "schema_contract" => "station_calendar_report.v1",
               "affected_contacts" => []
             })

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "station_calendar_precedence_summary.v1"}} =
             Schema.validate_artifact(precedence_summary)

    assert {:ok, precedence_schema} =
             Schema.json_schema("station_calendar_precedence_summary.v1")

    assert get_in(precedence_schema, ["properties", "model", "const"]) ==
             "artifact_only_station_calendar_precedence_summary"

    assert get_in(precedence_schema, ["properties", "model_limits", "const"]) ==
             precedence_model_limits

    assert get_in(precedence_schema, ["properties", "model_limits", "items", "enum"]) ==
             precedence_model_limits

    assert get_in(precedence_schema, ["properties", "source"]) == %{"type" => "string"}

    assert get_in(precedence_schema, [
             "properties",
             "reserved_under_higher_precedence_reservation_ids",
             "items",
             "type"
           ]) == "string"

    assert get_in(precedence_schema, [
             "properties",
             "reserved_under_higher_precedence_reservation_ids_by_status",
             "type"
           ]) == "object"

    stale_precedence_source = Map.put(precedence_summary, "source", %{"id" => "ops_calendar"})

    assert {:error, stale_precedence_source_report} =
             Schema.validate_artifact(stale_precedence_source)

    assert Enum.any?(
             stale_precedence_source_report["errors"],
             &(&1["path"] == "$.source" and &1["message"] == "must be a binary")
           )

    stale_precedence_model_limits =
      Map.put(precedence_summary, "model_limits", ["declared_data_only"])

    assert {:error, stale_precedence_model_limits_report} =
             Schema.validate_artifact(stale_precedence_model_limits)

    assert Enum.any?(
             stale_precedence_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match station calendar report model limits")
           )

    stale_precedence_count =
      Map.put(precedence_summary, "reserved_under_higher_precedence_contact_count", 0)

    assert {:error, stale_precedence_count_report} =
             Schema.validate_artifact(stale_precedence_count)

    assert Enum.any?(
             stale_precedence_count_report["errors"],
             &(&1["path"] == "$.reserved_under_higher_precedence_contact_count" and
                 &1["message"] == "must equal reserved-under-higher-precedence contact ID count")
           )

    stale_overlap_routing =
      put_in(precedence_summary, ["affected_contact_ids_by_overlap_availability", "reserved"], [])

    assert {:error, stale_overlap_routing_report} =
             Schema.validate_artifact(stale_overlap_routing)

    assert Enum.any?(
             stale_overlap_routing_report["errors"],
             &(&1["path"] == "$.reserved_overlap_contact_ids" and
                 &1["message"] == "must equal reserved overlap contact IDs")
           )

    stale_status_count = Map.put(precedence_summary, "applied_status_counts", %{})

    assert {:error, stale_status_count_report} =
             Schema.validate_artifact(stale_status_count)

    assert Enum.any?(
             stale_status_count_report["errors"],
             &(&1["path"] == "$.applied_status_counts" and
                 &1["message"] == "must equal contact IDs by applied status")
           )

    stale_reserved_status_routing =
      put_in(
        precedence_summary,
        ["reserved_under_higher_precedence_reservation_ids_by_status", "confirmed"],
        []
      )

    assert {:error, stale_reserved_status_routing_report} =
             Schema.validate_artifact(stale_reserved_status_routing)

    assert Enum.any?(
             stale_reserved_status_routing_report["errors"],
             &(&1["path"] == "$.reserved_under_higher_precedence_reservation_ids" and
                 &1["message"] ==
                   "must equal reserved-under-higher-precedence reservation IDs by reservation status")
           )

    assert_summary_handoff(
      precedence_summary,
      &StationCalendar.precedence_summary/1,
      &OrbitalDynamics.station_calendar_precedence_summary/1
    )
  end

  test "disambiguates duplicate affected-contact row ids without dropping contacts" do
    contacts = [
      %{
        id: :dup_contact,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      },
      %{
        id: :dup_contact,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 180.0
      }
    ]

    calendar = [
      %{
        id: :equator_outage,
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 90.0,
        ends_at_s: 190.0
      }
    ]

    {_annotated, report} = StationCalendar.overlay_contacts(contacts, calendar)

    assert %{
             "affected_contact_count" => 2,
             "duplicate_affected_contact_id_count" => 1,
             "duplicate_affected_contact_row_count" => 2,
             "affected_contacts" => affected_contacts
           } = report

    assert Enum.map(affected_contacts, & &1["id"]) == [
             "station_calendar:dup_contact:equator_outage:1",
             "station_calendar:dup_contact:equator_outage:2"
           ]

    assert Enum.map(affected_contacts, & &1["scenario_id"]) == ["leo_1", "leo_2"]

    assert Enum.all?(
             affected_contacts,
             &(&1["contact_id"] == "dup_contact" and
                 &1["base_station_calendar_row_id"] ==
                   "station_calendar:dup_contact:equator_outage" and
                 &1["duplicate_station_calendar_row_id_collision"])
           )

    assert Enum.map(affected_contacts, & &1["duplicate_station_calendar_row_index"]) == [1, 2]
    assert Enum.all?(affected_contacts, &(&1["duplicate_station_calendar_row_count"] == 2))

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)

    fractional_duplicate_row_index =
      put_in(
        report,
        ["affected_contacts", Access.at(0), "duplicate_station_calendar_row_index"],
        1.5
      )

    assert {:error, fractional_duplicate_row_index_report} =
             Schema.validate_artifact(fractional_duplicate_row_index)

    assert Enum.any?(
             fractional_duplicate_row_index_report["errors"],
             &(&1["path"] == "$.affected_contacts[0].duplicate_station_calendar_row_index" and
                 &1["message"] == "must be an integer")
           )

    missing_duplicate_row_evidence =
      update_in(
        report,
        ["affected_contacts", Access.at(0)],
        &Map.delete(&1, "base_station_calendar_row_id")
      )

    assert {:error, missing_duplicate_row_evidence_report} =
             Schema.validate_artifact(missing_duplicate_row_evidence)

    assert Enum.any?(
             missing_duplicate_row_evidence_report["errors"],
             &(&1["path"] == "$.affected_contacts[0].base_station_calendar_row_id" and
                 &1["message"] == "is required")
           )

    invalid_duplicate_row_count =
      update_in(
        report,
        ["affected_contacts", Access.at(0)],
        &Map.put(&1, "duplicate_station_calendar_row_count", 1)
      )

    assert {:error, duplicate_row_count_report} =
             Schema.validate_artifact(invalid_duplicate_row_count)

    assert Enum.any?(
             duplicate_row_count_report["errors"],
             &(&1["path"] == "$.affected_contacts[0].duplicate_station_calendar_row_count" and
                 &1["message"] == "must equal 2")
           )

    duplicate_row_index_collision =
      update_in(
        report,
        ["affected_contacts", Access.at(1)],
        &Map.put(&1, "duplicate_station_calendar_row_index", 1)
      )

    assert {:error, duplicate_row_index_report} =
             Schema.validate_artifact(duplicate_row_index_collision)

    assert Enum.any?(
             duplicate_row_index_report["errors"],
             &(&1["path"] == "$.affected_contacts" and
                 String.starts_with?(
                   &1["message"],
                   "duplicate_station_calendar_row_index values must cover 1..2"
                 ))
           )

    review = OperatorReview.from_station_calendar_report(report)

    assert Enum.count(
             review["rows"],
             &(&1["contact_id"] == "dup_contact" and
                 &1["duplicate_station_calendar_row_id_collision"])
           ) == 2

    manifest = CadenceImport.from_station_calendar_report(report)

    assert Enum.count(
             manifest["rows"],
             &(&1["contact_id"] == "dup_contact" and
                 &1["duplicate_station_calendar_row_id_collision"])
           ) == 2
  end

  test "classifies affected contacts with ground-network approval policy" do
    contacts = [
      %{
        id: :dl_blocked,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0
      },
      %{
        id: :cmd_reserved,
        direction: :command,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 300.0,
        ends_at_s: 330.0
      },
      %{
        id: :dl_reduced,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 500.0,
        ends_at_s: 540.0
      }
    ]

    calendar = [
      %{
        id: :equator_outage,
        ground_station_id: :equator_prime,
        status: :unavailable,
        starts_at_s: 90.0,
        ends_at_s: 170.0
      },
      %{
        id: :equator_reserved,
        ground_station_id: :equator_prime,
        availability: :reserved,
        starts_at_s: 295.0,
        ends_at_s: 335.0,
        reservation_id: :provider_reservation_42,
        reservation_status: :confirmed
      },
      %{
        id: :equator_capacity,
        ground_station_id: :equator_prime,
        status: :available,
        starts_at_s: 490.0,
        ends_at_s: 550.0,
        capacity_fraction: 0.4
      }
    ]

    report =
      StationCalendar.report(contacts, calendar,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    blocked = Enum.find(report["affected_contacts"], &(&1["contact_id"] == "dl_blocked"))
    reserved = Enum.find(report["affected_contacts"], &(&1["contact_id"] == "cmd_reserved"))
    reduced = Enum.find(report["affected_contacts"], &(&1["contact_id"] == "dl_reduced"))

    assert %{
             "approval_status" => "blocked_by_policy",
             "required_operator_action" => "review_station_availability",
             "approval_requirements" => [
               %{
                 "requirement_type" => "contact_schedule_change",
                 "policy_classification" => "blocked_by_policy"
               }
             ],
             "policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "policy_bundle_id" => "ground_network_allocation_v1"
             }
           } = blocked

    assert Enum.any?(
             blocked["approval_rule_matches"],
             &(&1["rule_id"] == "unavailable_station_contact_block" and
                 &1["station_availability"] == "unavailable")
           )

    assert Enum.any?(
             blocked["approval_rule_matches"],
             &(&1["rule_id"] == "missing_station_calendar_trust_review" and
                 &1["station_calendar_trust_boundary_status"] == "missing")
           )

    assert %{
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_station_reservation_overlap",
             "direction" => "command"
           } = reserved

    assert Enum.any?(
             reserved["approval_rule_matches"],
             &(&1["rule_id"] == "reserved_station_contact_review" and
                 &1["station_contention_status"] == "reserved_overlap" and
                 &1["station_reservation_status"] == "confirmed")
           )

    assert Enum.any?(
             reserved["approval_rule_matches"],
             &(&1["rule_id"] == "missing_station_calendar_trust_review" and
                 &1["station_calendar_trust_boundary_status"] == "missing")
           )

    assert %{
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_reduced_station_capacity",
             "capacity_fraction" => 0.4
           } = reduced

    assert Enum.any?(
             reduced["approval_rule_matches"],
             &(&1["rule_id"] == "severe_capacity_reduction_review" and
                 &1["capacity_fraction"] == 0.4)
           )

    assert Enum.any?(
             reduced["approval_rule_matches"],
             &(&1["rule_id"] == "missing_station_calendar_trust_review" and
                 &1["station_calendar_trust_boundary_status"] == "missing")
           )

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "classifies uplink station-calendar requirements as command review" do
    contacts = [
      %{
        id: :uplink_reserved,
        type: :planned_contact,
        direction: :uplink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 300.0,
        ends_at_s: 330.0
      }
    ]

    calendar = [
      %{
        id: :equator_reserved,
        ground_station_id: :equator_prime,
        availability: :reserved,
        starts_at_s: 295.0,
        ends_at_s: 335.0,
        reservation_id: :provider_reservation_42,
        reservation_status: :confirmed
      }
    ]

    report =
      StationCalendar.report(contacts, calendar,
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert [
             %{
               "contact_id" => "uplink_reserved",
               "direction" => "uplink",
               "approval_status" => "operator_review_required",
               "approval_requirements" => [
                 %{
                   "requirement_type" => "command_review",
                   "reason" =>
                     "command contact station calendar review: station equator_prime calendar reports reserved",
                   "activity_context" => %{
                     "direction" => "uplink",
                     "station_reservation_id" => "provider_reservation_42",
                     "station_calendar_trust_boundary_status" => "missing"
                   }
                 }
               ],
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "command_uplink_authority_review",
                   "direction" => "uplink",
                   "requirement_type" => "command_review",
                   "required_authority" => "command_authority"
                 }
               ]
             }
           ] = report["affected_contacts"]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_station_calendar_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "uplink_reserved" and
                 &1["direction"] == "uplink" and
                 get_in(&1, [
                   "source_station_calendar_review",
                   "approval_requirements",
                   Access.at(0),
                   "requirement_type"
                 ]) == "command_review")
           )

    manifest = CadenceImport.from_station_calendar_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "uplink_reserved" and
                 &1["direction"] == "uplink" and
                 get_in(&1, [
                   "source_station_calendar_review",
                   "approval_requirements",
                   Access.at(0),
                   "requirement_type"
                 ]) == "command_review")
           )
  end

  test "carries contact feedback evidence into station calendar policy, review, and import rows" do
    contacts = [
      %{
        id: :dl_failed_feedback,
        type: :downlink,
        scenario_id: :leo_1,
        direction: :downlink,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        contact_success: false,
        contact_result: %{
          outcome: :accepted,
          provider_status: :dropped
        },
        contact_success_factor: 0.25,
        contact_success_factor_source: :operational_feedback_contact_success,
        command_success: false,
        command_result: %{
          outcome: :accepted,
          status: :rejected
        },
        command_success_factor: 0.5,
        command_success_factor_source: :operational_feedback_command_success
      }
    ]

    calendar = [
      %{
        id: :equator_capacity,
        ground_station_id: :equator_prime,
        availability: :reduced_capacity,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        capacity_fraction: 0.5
      }
    ]

    report =
      StationCalendar.report(contacts, calendar,
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert [
             %{
               "contact_id" => "dl_failed_feedback",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "contact_success" => false,
                     "contact_result" => "accepted,dropped",
                     "contact_success_factor" => 0.25,
                     "contact_success_factor_source" => "operational_feedback_contact_success",
                     "command_success" => false,
                     "command_result" => "accepted,rejected",
                     "command_success_factor" => 0.5,
                     "command_success_factor_source" => "operational_feedback_command_success"
                   }
                 }
               ]
             } = row
           ] = report["affected_contacts"]

    assert Enum.any?(
             row["approval_rule_matches"],
             &(&1["rule_id"] == "failed_contact_success_review" and
                 &1["contact_success"] == false)
           )

    assert Enum.any?(
             row["approval_rule_matches"],
             &(&1["rule_id"] == "low_contact_success_confidence_review" and
                 &1["contact_success_factor"] == 0.25 and
                 &1["contact_success_factor_source"] ==
                   "operational_feedback_contact_success")
           )

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_station_calendar_report(report)

    assert [
             %{
               "review_type" => "station_calendar_review",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "source_station_calendar_review" => %{
                 "contact_success" => false,
                 "contact_result" => "accepted,dropped",
                 "command_success" => false
               }
             }
           ] = review["rows"]

    manifest = CadenceImport.from_station_calendar_report(report)

    assert [
             %{
               "import_action" => "review_station_calendar",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "source_station_calendar_review" => %{
                 "contact_success" => false,
                 "contact_result" => "accepted,dropped",
                 "command_success" => false
               }
             }
           ] = manifest["rows"]
  end

  test "review-gates out-of-range contact feedback confidence factors before policy handoff" do
    contacts = [
      %{
        id: :dl_clamped_feedback,
        type: :downlink,
        scenario_id: :leo_1,
        direction: :downlink,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        contact_success_factor: 1.4,
        contact_success_factor_source: :operator_feedback,
        command_success_factor: -0.25,
        command_success_factor_source: :command_adapter
      }
    ]

    calendar = [
      %{
        id: :equator_capacity,
        ground_station_id: :equator_prime,
        availability: :reduced_capacity,
        starts_at_s: 90.0,
        ends_at_s: 170.0,
        capacity_fraction: 0.5
      }
    ]

    report =
      StationCalendar.report(contacts, calendar,
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert [
             %{
               "contact_id" => "dl_clamped_feedback",
               "invalid_feedback_confidence" => true,
               "invalid_feedback_confidence_reason" => "invalid_contact_success_factor",
               "source_contact_candidate" => %{
                 "contact_success_factor" => 1.4,
                 "command_success_factor" => -0.25
               },
               "approval_requirements" => [
                 %{
                   "activity_context" => context
                 }
               ]
             }
           ] = report["affected_contacts"]

    affected = List.first(report["affected_contacts"])

    refute Map.has_key?(affected, "contact_success_factor")
    refute Map.has_key?(affected, "contact_success_factor_source")
    refute Map.has_key?(affected, "command_success_factor")
    refute Map.has_key?(affected, "command_success_factor_source")
    assert context["invalid_feedback_confidence_reason"] == "invalid_contact_success_factor"
    refute Map.has_key?(context, "contact_success_factor")
    refute Map.has_key?(context, "command_success_factor")

    review = OperatorReview.from_station_calendar_report(report)
    manifest = CadenceImport.from_station_calendar_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "dl_clamped_feedback" and
                 &1["invalid_feedback_confidence_reason"] == "invalid_contact_success_factor")
           )

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "dl_clamped_feedback" and
                 &1["invalid_feedback_confidence_reason"] == "invalid_contact_success_factor")
           )

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "public facade builds station calendar reports" do
    report =
      OrbitalDynamics.station_calendar_report(
        [
          %{
            "id" => "cmd_1",
            "direction" => "command",
            "scenario_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 10.0,
            "ends_at_s" => 20.0
          }
        ],
        [
          %{
            "id" => "equator_maintenance",
            "ground_station_id" => "equator_prime",
            "status" => "maintenance",
            "starts_at_s" => 0.0,
            "ends_at_s" => 30.0
          }
        ]
      )

    assert [%{"station_availability" => "unavailable"}] = report["affected_contacts"]
    assert StationCalendar.report(report) == report
    assert OrbitalDynamics.station_calendar_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert StationCalendar.report(atom_keyed_report) == report
    assert OrbitalDynamics.station_calendar_report(atom_keyed_report) == report
  end

  test "reports declared reserved station time as contact contention" do
    contacts = [
      %{
        id: :cmd_1,
        direction: :command,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 10.0,
        ends_at_s: 20.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      provenance: %{trust_boundary: :operator_declared_station_calendar},
      entries: [
        %{
          id: :equator_reserved,
          ground_station_id: :equator_prime,
          availability: :reserved,
          starts_at_s: 0.0,
          ends_at_s: 30.0,
          reservation_id: :provider_reservation_42,
          reserved_by: :cadence_ops,
          reservation_status: :confirmed
        }
      ]
    }

    {annotated, report} =
      StationCalendar.overlay_contacts(contacts, provider, source: "ops_calendar")

    assert [
             %{
               "station_availability" => "reserved",
               "station_contention_status" => "reserved_overlap",
               "station_reservation_id" => "provider_reservation_42",
               "station_reserved_by" => "cadence_ops",
               "station_reservation_status" => "confirmed"
             }
           ] = annotated

    assert [
             %{
               "station_availability" => "reserved",
               "station_contention_status" => "reserved_overlap",
               "station_reservation_id" => "provider_reservation_42",
               "station_reserved_by" => "cadence_ops",
               "station_reservation_status" => "confirmed",
               "station_calendar_trust_boundary_status" => "declared",
               "overlap_starts_at_s" => 10.0,
               "overlap_ends_at_s" => 20.0,
               "overlap_duration_s" => 10.0,
               "trust_boundary" => "operator_declared_station_calendar",
               "provenance" => %{
                 "provider_id" => "ops_calendar",
                 "trust_boundary" => "operator_declared_station_calendar"
               }
             }
           ] = report["affected_contacts"]

    assert report["affected_duration_s"] == 10.0
    assert report["station_calendar_trust_boundary_status_counts"] == %{"declared" => 1}

    assert {:ok, %{"schema_contract" => "station_calendar_provider.v1"}} =
             provider
             |> stringify_keys()
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "marks contacts that match declared station reservation identity" do
    contacts = [
      %{
        id: :dl_reserved_owner,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        station_reservation_id: :provider_reservation_42
      }
    ]

    ground_network = [
      %{
        id: :equator_reserved,
        ground_station_id: :equator_prime,
        availability: :reserved,
        starts_at_s: 0.0,
        ends_at_s: 30.0,
        reservation_id: :provider_reservation_42,
        reserved_by: :cadence_ops,
        reservation_status: :confirmed
      }
    ]

    {annotated, report} = StationCalendar.overlay_contacts(contacts, ground_network)

    assert [
             %{
               "station_reservation_id" => "provider_reservation_42",
               "station_reservation_match_status" => "matched"
             }
           ] = annotated

    assert [
             %{
               "station_reservation_id" => "provider_reservation_42",
               "station_reservation_match_status" => "matched"
             }
           ] = report["affected_contacts"]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "marks contacts that match declared station reservation owner" do
    contacts = [
      %{
        id: :dl_reserved_owner,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        station_reserved_by: :cadence_ops
      }
    ]

    ground_network = [
      %{
        id: :equator_reserved,
        ground_station_id: :equator_prime,
        availability: :reserved,
        starts_at_s: 0.0,
        ends_at_s: 30.0,
        reservation_id: :provider_reservation_42,
        reserved_by: :cadence_ops,
        reservation_status: :confirmed
      }
    ]

    {annotated, report} = StationCalendar.overlay_contacts(contacts, ground_network)

    assert [
             %{
               "station_reservation_id" => "provider_reservation_42",
               "station_reserved_by" => "cadence_ops",
               "station_reservation_status" => "confirmed",
               "station_reservation_match_status" => "owner_matched"
             }
           ] = annotated

    assert [
             %{
               "station_reservation_id" => "provider_reservation_42",
               "station_reserved_by" => "cadence_ops",
               "station_reservation_match_status" => "owner_matched"
             }
           ] = report["affected_contacts"]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "does not treat provider-derived reservation annotations as reservation ownership" do
    contacts = [
      %{
        id: :dl_reserved_overlap,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        station_contention_status: :reserved_overlap,
        station_reservation_id: :provider_reservation_42
      }
    ]

    ground_network = [
      %{
        id: :equator_reserved,
        ground_station_id: :equator_prime,
        availability: :reserved,
        starts_at_s: 0.0,
        ends_at_s: 30.0,
        reservation_id: :provider_reservation_42,
        reserved_by: :cadence_ops,
        reservation_status: :confirmed
      }
    ]

    {annotated, report} = StationCalendar.overlay_contacts(contacts, ground_network)

    assert [
             %{
               "station_reservation_id" => "provider_reservation_42",
               "station_contention_status" => "reserved_overlap",
               "station_reservation_match_status" => "overlap"
             }
           ] = annotated

    assert [
             %{
               "station_reservation_id" => "provider_reservation_42",
               "station_reservation_match_status" => "overlap"
             }
           ] = report["affected_contacts"]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes declared provider entries into ground-network intervals" do
    provider = %{
      "schema_contract" => "station_calendar_provider.v1",
      id: :ops_calendar,
      provenance: %{trust_boundary: :operator_declared_station_calendar},
      entries: [
        %{
          id: :maintenance_1,
          station_id: :equator_prime,
          availability: :maintenance,
          directions: [:uplink, :commanding],
          start_s: 100.0,
          end_s: 200.0
        }
      ]
    }

    assert [
             %{
               "id" => "maintenance_1",
               "ground_station_id" => "equator_prime",
               "status" => "maintenance",
               "availability" => "maintenance",
               "directions" => ["command", "uplink"],
               "starts_at_s" => 100.0,
               "ends_at_s" => 200.0,
               "provenance" => %{
                 "source" => "station_calendar_provider",
                 "provider_id" => "ops_calendar",
                 "trust_boundary" => "operator_declared_station_calendar"
               }
             }
           ] = StationCalendar.to_ground_network(provider)

    assert OrbitalDynamics.station_calendar_ground_network(provider) ==
             StationCalendar.to_ground_network(provider)
  end

  test "normalizes declared provider lists into ground-network intervals and reports" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 160.0
      }
    ]

    providers = [
      %{
        schema_contract: "station_calendar_provider.v1",
        id: :aux_calendar,
        trust_boundary: :declared_station_calendar,
        entries: [
          %{
            id: :aux_available,
            station_id: :polar_aux,
            availability: :available,
            start_s: 100.0,
            end_s: 200.0
          }
        ]
      },
      %{
        schema_contract: "station_calendar_provider.v1",
        id: :ops_calendar,
        trust_boundary: :declared_station_calendar,
        entries: [
          %{
            id: :provider_downlink_reservation,
            station_id: :equator_prime,
            availability: :reserved,
            directions: [:downlink],
            start_s: 100.0,
            end_s: 200.0,
            reservation_id: :provider_reservation_1,
            reserved_by: :ops_calendar,
            reservation_status: :confirmed
          }
        ]
      }
    ]

    assert [
             %{"id" => "aux_available", "provider_id" => "aux_calendar"},
             %{
               "id" => "provider_downlink_reservation",
               "provider_id" => "ops_calendar",
               "provider_entry_id" => "provider_downlink_reservation"
             }
           ] = StationCalendar.to_ground_network(providers)

    assert OrbitalDynamics.station_calendar_ground_network(providers) ==
             StationCalendar.to_ground_network(providers)

    {_annotated, report} = StationCalendar.overlay_contacts(contacts, providers)

    assert %{
             "calendar_entry_count" => 2,
             "affected_contact_count" => 1,
             "affected_contacts" => [
               %{
                 "contact_id" => "dl_1",
                 "station_calendar_entry_id" => "provider_downlink_reservation",
                 "station_calendar_provider_id" => "ops_calendar",
                 "station_calendar_provider_entry_id" => "provider_downlink_reservation",
                 "station_reservation_id" => "provider_reservation_1",
                 "station_reserved_by" => "ops_calendar",
                 "station_reservation_status" => "confirmed",
                 "station_calendar_reservation_ids" => ["provider_reservation_1"],
                 "station_calendar_reservation_statuses" => ["confirmed"],
                 "station_calendar_directions" => ["downlink"],
                 "source_station_calendar_entry" => %{
                   "id" => "provider_downlink_reservation",
                   "provenance" => %{
                     "source" => "station_calendar_provider",
                     "provider_id" => "ops_calendar",
                     "trust_boundary" => "declared_station_calendar"
                   }
                 }
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes provider reservation holds into reserved-station evidence" do
    contacts = [
      %{
        id: :dl_hold,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 160.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      trust_boundary: :declared_station_calendar,
      entries: [
        %{
          id: :provider_downlink_hold,
          station_id: :equator_prime,
          availability: :reservation_hold,
          directions: [:downlink],
          start_s: 100.0,
          end_s: 200.0,
          hold_id: :provider_hold_1,
          hold_expires_at_s: 240.0,
          held_by: :ops_calendar,
          hold_status: :tentative_hold
        }
      ]
    }

    assert [
             %{
               "availability" => "reserved",
               "status" => "reserved",
               "reservation_id" => "provider_hold_1",
               "reservation_expires_at_s" => 240.0,
               "reserved_by" => "ops_calendar",
               "reservation_status" => "tentative_hold"
             }
           ] = StationCalendar.to_ground_network(provider)

    {annotated, report} = StationCalendar.overlay_contacts(contacts, provider)

    assert report["station_reservation_match_status_counts"] == %{"overlap" => 1}

    assert report["affected_contact_ids_by_reservation_match_status"] == %{
             "overlap" => ["dl_hold"]
           }

    assert [
             %{
               "station_availability" => "reserved",
               "station_contention_status" => "reserved_overlap",
               "station_reservation_id" => "provider_hold_1",
               "station_reservation_expires_at_s" => 240.0,
               "station_reserved_by" => "ops_calendar",
               "station_reservation_status" => "tentative_hold",
               "station_calendar_reservation_ids" => ["provider_hold_1"],
               "station_calendar_reservation_statuses" => ["tentative_hold"],
               "station_calendar_reservation_expires_at_s" => [240.0]
             }
           ] = annotated

    assert [
             %{
               "contact_id" => "dl_hold",
               "station_availability" => "reserved",
               "station_reservation_id" => "provider_hold_1",
               "station_reservation_expires_at_s" => 240.0,
               "station_reserved_by" => "ops_calendar",
               "station_reservation_status" => "tentative_hold",
               "station_calendar_reservation_ids" => ["provider_hold_1"],
               "station_calendar_reservation_statuses" => ["tentative_hold"],
               "station_calendar_reservation_expires_at_s" => [240.0]
             }
           ] = report["affected_contacts"]

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_match_counts =
      Map.put(report, "station_reservation_match_status_counts", %{"matched" => 1})

    assert {:error, invalid_match_count_report} = Schema.validate_artifact(invalid_match_counts)

    assert Enum.any?(
             invalid_match_count_report["errors"],
             &(&1["path"] == "$.station_reservation_match_status_counts" and
                 &1["message"] ==
                   "must equal row-derived station_reservation_match_status_counts")
           )

    invalid_match_ids =
      Map.put(report, "affected_contact_ids_by_reservation_match_status", %{
        "overlap" => ["stale_contact"]
      })

    assert {:error, invalid_match_ids_report} = Schema.validate_artifact(invalid_match_ids)

    assert Enum.any?(
             invalid_match_ids_report["errors"],
             &(&1["path"] == "$.affected_contact_ids_by_reservation_match_status" and
                 &1["message"] ==
                   "must equal row-derived affected_contact_ids_by_reservation_match_status")
           )

    review_row =
      report
      |> OperatorReview.from_station_calendar_report()
      |> Map.fetch!("rows")
      |> List.first()

    assert %{
             "action" => "review_station_reservation_overlap",
             "station_reservation_id" => "provider_hold_1",
             "station_reservation_expires_at_s" => 240.0,
             "station_calendar_reservation_expires_at_s" => [240.0],
             "station_reservation_status" => "tentative_hold"
           } = review_row

    import_row =
      report
      |> CadenceImport.from_station_calendar_report()
      |> Map.fetch!("rows")
      |> List.first()

    assert %{
             "source_review_action" => "review_station_reservation_overlap",
             "station_reservation_id" => "provider_hold_1",
             "station_reservation_expires_at_s" => 240.0,
             "station_calendar_reservation_expires_at_s" => [240.0],
             "station_reservation_status" => "tentative_hold"
           } = import_row

    invalid_expiration =
      put_in(
        report,
        ["affected_contacts", Access.at(0), "station_reservation_expires_at_s"],
        "240"
      )

    assert {:error, invalid_expiration_report} = Schema.validate_artifact(invalid_expiration)

    assert Enum.any?(
             invalid_expiration_report["errors"],
             &(&1["path"] == "$.affected_contacts[0].station_reservation_expires_at_s" and
                 &1["message"] == "must be a number")
           )
  end

  test "normalizes provider on-hold availability aliases into reserved station evidence" do
    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      trust_boundary: :declared_station_calendar,
      entries: [
        %{
          id: :provider_on_hold,
          station_id: :equator_prime,
          availability: "On Hold",
          hold_id: :hold_on_hold,
          held_by: :ops_calendar
        },
        %{
          id: :provider_reservation_held,
          station_id: :polar_prime,
          availability: "reservation-held",
          hold_id: :hold_reservation_held,
          held_by: :partner_calendar
        },
        %{
          id: :provider_onhold,
          station_id: :desert_prime,
          availability: "onhold",
          hold_id: :hold_onhold,
          held_by: :ops_calendar
        },
        %{
          id: :provider_reserved_hold,
          station_id: :coastal_prime,
          availability: "reserved-hold",
          hold_id: :hold_reserved_hold,
          held_by: :partner_calendar
        }
      ]
    }

    schema_provider = %{
      provider
      | entries: [
          %{Enum.at(provider.entries, 0) | availability: :on_hold},
          %{Enum.at(provider.entries, 1) | availability: :reservation_held},
          %{Enum.at(provider.entries, 2) | availability: :onhold},
          %{Enum.at(provider.entries, 3) | availability: :reserved_hold}
        ]
    }

    assert {:ok, %{"schema_contract" => "station_calendar_provider.v1"}} =
             schema_provider
             |> stringify_keys()
             |> Schema.validate_artifact()

    assert [
             %{
               "id" => "provider_on_hold",
               "availability" => "reserved",
               "status" => "reserved",
               "reservation_id" => "hold_on_hold",
               "reservation_status" => "hold",
               "reserved_by" => "ops_calendar"
             },
             %{
               "id" => "provider_reservation_held",
               "availability" => "reserved",
               "status" => "reserved",
               "reservation_id" => "hold_reservation_held",
               "reservation_status" => "hold",
               "reserved_by" => "partner_calendar"
             },
             %{
               "id" => "provider_onhold",
               "availability" => "reserved",
               "status" => "reserved",
               "reservation_id" => "hold_onhold",
               "reservation_status" => "hold",
               "reserved_by" => "ops_calendar"
             },
             %{
               "id" => "provider_reserved_hold",
               "availability" => "reserved",
               "status" => "reserved",
               "reservation_id" => "hold_reserved_hold",
               "reservation_status" => "hold",
               "reserved_by" => "partner_calendar"
             }
           ] = StationCalendar.to_ground_network(provider)
  end

  test "preserves provider counteroffer evidence through station calendar review handoff" do
    contacts = [
      %{
        id: :dl_counteroffer,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 140.0
      }
    ]

    provider = %{
      schema_contract: "station_calendar_provider.v1",
      id: :ops_calendar,
      trust_boundary: :declared_station_calendar,
      entries: [
        %{
          id: :provider_counteroffer_window,
          station_id: :equator_prime,
          availability: :available,
          directions: [:downlink],
          start_s: 130.0,
          end_s: 170.0,
          counteroffer_id: :provider_offer_1,
          counteroffer_status: :proposed,
          counteroffer_reason_code: :provider_shifted_window,
          counteroffer_cost_delta: 125.5,
          schedule_lock_deadline_s: 150.0,
          counteroffer_start_s: 130.0,
          counteroffer_end_s: 170.0
        }
      ]
    }

    assert {:ok, %{"schema_contract" => "station_calendar_provider.v1"}} =
             provider
             |> stringify_keys()
             |> Schema.validate_artifact()

    {annotated, report} =
      StationCalendar.overlay_contacts(contacts, provider, source: "provider_counteroffers")

    assert [
             annotated_counteroffer = %{
               "provider_counteroffer_id" => "provider_offer_1",
               "provider_counteroffer_status" => "proposed",
               "provider_counteroffer_negotiation_state" => "proposed",
               "provider_counteroffer_reason_code" => "provider_shifted_window",
               "provider_counteroffer_cost_delta" => 125.5,
               "provider_counteroffer_lock_deadline_s" => 150.0,
               "provider_counteroffer_starts_at_s" => 130.0,
               "provider_counteroffer_ends_at_s" => 170.0,
               "provider_counteroffer_start_delta_s" => 30.0,
               "provider_counteroffer_end_delta_s" => 30.0
             }
           ] = annotated

    assert annotated_counteroffer["provider_counteroffer_duration_delta_s"] == 0.0

    assert %{
             "provider_counteroffer_count" => 1,
             "affected_contacts" => [
               affected_counteroffer = %{
                 "contact_id" => "dl_counteroffer",
                 "required_operator_action" => "review_provider_counteroffer",
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_status" => "proposed",
                 "provider_counteroffer_negotiation_state" => "proposed",
                 "provider_counteroffer_reason_code" => "provider_shifted_window",
                 "provider_counteroffer_cost_delta" => 125.5,
                 "provider_counteroffer_lock_deadline_s" => 150.0,
                 "provider_counteroffer_starts_at_s" => 130.0,
                 "provider_counteroffer_ends_at_s" => 170.0,
                 "provider_counteroffer_start_delta_s" => 30.0,
                 "provider_counteroffer_end_delta_s" => 30.0,
                 "source_station_calendar_entry" => %{
                   "provider_counteroffer_id" => "provider_offer_1",
                   "provider_counteroffer_status" => "proposed",
                   "provider_counteroffer_negotiation_state" => "proposed"
                 }
               }
             ]
           } = report

    assert affected_counteroffer["provider_counteroffer_duration_delta_s"] == 0.0

    assert {:ok, %{"schema_contract" => "station_calendar_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_count = Map.put(report, "provider_counteroffer_count", 2)

    assert {:error, invalid_count_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             invalid_count_report["errors"],
             &(&1["path"] == "$.provider_counteroffer_count" and
                 &1["message"] == "must equal row-derived provider_counteroffer_count")
           )

    review = OperatorReview.from_station_calendar_report(report)

    assert [
             review_counteroffer = %{
               "review_type" => "station_calendar_review",
               "required_operator_action" => "review_provider_counteroffer",
               "provider_counteroffer_id" => "provider_offer_1",
               "provider_counteroffer_status" => "proposed",
               "provider_counteroffer_negotiation_state" => "proposed",
               "provider_counteroffer_reason_code" => "provider_shifted_window",
               "provider_counteroffer_cost_delta" => 125.5,
               "provider_counteroffer_lock_deadline_s" => 150.0,
               "provider_counteroffer_starts_at_s" => 130.0,
               "provider_counteroffer_ends_at_s" => 170.0,
               "provider_counteroffer_start_delta_s" => 30.0,
               "provider_counteroffer_end_delta_s" => 30.0,
               "source_station_calendar_review" => %{
                 "provider_counteroffer_id" => "provider_offer_1"
               }
             }
           ] = review["rows"]

    assert review_counteroffer["provider_counteroffer_duration_delta_s"] == 0.0

    manifest = CadenceImport.from_station_calendar_report(report)

    assert [
             import_counteroffer = %{
               "import_action" => "review_station_calendar",
               "source_review_action" => "review_provider_counteroffer",
               "provider_counteroffer_id" => "provider_offer_1",
               "provider_counteroffer_status" => "proposed",
               "provider_counteroffer_negotiation_state" => "proposed",
               "provider_counteroffer_reason_code" => "provider_shifted_window",
               "provider_counteroffer_cost_delta" => 125.5,
               "provider_counteroffer_lock_deadline_s" => 150.0,
               "provider_counteroffer_starts_at_s" => 130.0,
               "provider_counteroffer_ends_at_s" => 170.0,
               "provider_counteroffer_start_delta_s" => 30.0,
               "provider_counteroffer_end_delta_s" => 30.0,
               "source_station_calendar_review" => %{
                 "provider_counteroffer_id" => "provider_offer_1"
               }
             }
           ] = manifest["rows"]

    assert import_counteroffer["provider_counteroffer_duration_delta_s"] == 0.0

    counteroffer_report = StationCalendar.provider_counteroffer_report(report)

    assert OrbitalDynamics.provider_counteroffer_report(report) == counteroffer_report

    assert StationCalendar.provider_counteroffer_report(counteroffer_report) ==
             counteroffer_report

    assert OrbitalDynamics.provider_counteroffer_report(counteroffer_report) ==
             counteroffer_report

    atom_keyed_counteroffer_report =
      Map.new(counteroffer_report, fn {key, value} -> {String.to_atom(key), value} end)

    assert StationCalendar.provider_counteroffer_report(atom_keyed_counteroffer_report) ==
             counteroffer_report

    assert OrbitalDynamics.provider_counteroffer_report(atom_keyed_counteroffer_report) ==
             counteroffer_report

    assert %{
             "schema_contract" => "provider_counteroffer_report.v1",
             "source_artifact_type" => "station_calendar_report.v1",
             "counteroffer_count" => 1,
             "reviewable_count" => 1,
             "counteroffer_cost_delta_count" => 1,
             "counteroffer_cost_delta_total" => 125.5,
             "counteroffer_lock_deadline_count" => 1,
             "earliest_counteroffer_lock_deadline_s" => 150.0,
             "counteroffer_status_counts" => %{"proposed" => 1},
             "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
             "required_operator_action_counts" => %{"review_provider_counteroffer" => 1},
             "rows" => [
               counteroffer_row = %{
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_status" => "proposed",
                 "provider_counteroffer_negotiation_state" => "proposed",
                 "provider_counteroffer_reason_code" => "provider_shifted_window",
                 "provider_counteroffer_cost_delta" => 125.5,
                 "provider_counteroffer_lock_deadline_s" => 150.0,
                 "provider_counteroffer_starts_at_s" => 130.0,
                 "provider_counteroffer_ends_at_s" => 170.0,
                 "provider_counteroffer_start_delta_s" => 30.0,
                 "provider_counteroffer_end_delta_s" => 30.0,
                 "required_operator_action" => "review_provider_counteroffer",
                 "source_station_calendar_entry" => %{
                   "provider_counteroffer_id" => "provider_offer_1"
                 }
               }
             ]
           } = counteroffer_report

    assert counteroffer_row["provider_counteroffer_duration_delta_s"] == 0.0

    assert {:ok, %{"schema_contract" => "provider_counteroffer_report.v1"}} =
             Schema.validate_artifact(counteroffer_report)

    stale_counteroffer_model =
      Map.put(counteroffer_report, "model", "custom_provider_counteroffer_review")

    assert {:error, stale_counteroffer_model_report} =
             Schema.validate_artifact(stale_counteroffer_model)

    assert Enum.any?(
             stale_counteroffer_model_report["errors"],
             &(&1["path"] == "$.model")
           )

    review_summary =
      StationCalendar.provider_counteroffer_review_summary(counteroffer_report, now_s: 160.0)

    assert OrbitalDynamics.provider_counteroffer_review_summary(counteroffer_report,
             now_s: 160.0
           ) == review_summary

    assert %{
             "schema_contract" => "provider_counteroffer_review_summary.v1",
             "model" => "artifact_only_provider_counteroffer_review_summary",
             "source_artifact_type" => "provider_counteroffer_report.v1",
             "source_counteroffer_artifact_type" => "station_calendar_report.v1",
             "counteroffer_count" => 1,
             "reviewable_count" => 1,
             "counteroffer_review_status" => "review_required",
             "counteroffer_status_counts" => %{"proposed" => 1},
             "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
             "counteroffer_lock_deadline_count" => 1,
             "earliest_counteroffer_lock_deadline_s" => 150.0,
             "counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
             "counteroffer_ids_by_lock_deadline_status" => %{
               "expired" => ["provider_offer_1"]
             },
             "expired_counteroffer_lock_deadline_count" => 1,
             "active_counteroffer_lock_deadline_count" => 0,
             "missing_counteroffer_lock_deadline_count" => 0,
             "review_counteroffer_ids" => ["provider_offer_1"],
             "rows" => [
               %{
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_lock_deadline_status" => "expired"
               }
             ],
             "review_rows" => [
               %{
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_lock_deadline_status" => "expired"
               }
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_writes",
               "operator_authority" => "not_granted_by_summary",
               "deadline_evaluation" => "relative_to_now_s",
               "now_s" => 160.0
             }
           } = review_summary

    assert {:ok, %{"schema_contract" => "provider_counteroffer_review_summary.v1"}} =
             Schema.validate_artifact(review_summary)

    assert {:ok, counteroffer_review_schema} =
             Schema.json_schema("provider_counteroffer_review_summary.v1")

    assert get_in(counteroffer_review_schema, ["properties", "model", "const"]) ==
             "artifact_only_provider_counteroffer_review_summary"

    stale_review_count = Map.put(review_summary, "reviewable_count", 0)

    assert {:error, stale_review_count_report} =
             Schema.validate_artifact(stale_review_count)

    assert Enum.any?(
             stale_review_count_report["errors"],
             &(&1["path"] == "$.reviewable_count" and &1["message"] == "must equal 1")
           )

    stale_review_rows = Map.put(review_summary, "review_rows", [])

    assert {:error, stale_review_rows_report} =
             Schema.validate_artifact(stale_review_rows)

    assert Enum.any?(
             stale_review_rows_report["errors"],
             &(&1["path"] == "$.review_rows" and
                 &1["message"] == "must equal reviewable provider-counteroffer rows")
           )

    assert %{
             "counteroffer_lock_deadline_status_counts" => %{"declared" => 1},
             "assumptions" => %{"deadline_evaluation" => "not_evaluated"}
           } = StationCalendar.provider_counteroffer_review_summary(counteroffer_report)

    import_readiness_summary =
      StationCalendar.provider_counteroffer_import_readiness_summary(counteroffer_report,
        now_s: 160.0
      )

    assert OrbitalDynamics.provider_counteroffer_import_readiness_summary(counteroffer_report,
             now_s: 160.0
           ) == import_readiness_summary

    assert %{
             "schema_contract" => "provider_counteroffer_import_readiness_summary.v1",
             "model" => "artifact_only_provider_counteroffer_import_readiness_summary",
             "source_artifact_type" => "provider_counteroffer_report.v1",
             "source_counteroffer_artifact_type" => "station_calendar_report.v1",
             "counteroffer_count" => 1,
             "reviewable_count" => 1,
             "import_readiness_status" => "review_required",
             "import_classification" => "review_only",
             "ready_for_import_count" => 0,
             "review_required_before_import_count" => 1,
             "no_import_required_count" => 0,
             "counteroffer_status_counts" => %{"proposed" => 1},
             "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
             "required_import_action_counts" => %{"review_provider_counteroffer" => 1},
             "provider_counteroffer_import_status_counts" => %{
               "review_required_before_import" => 1
             },
             "counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
             "counteroffer_ids_by_required_import_action" => %{
               "review_provider_counteroffer" => ["provider_offer_1"]
             },
             "counteroffer_ids_by_import_status" => %{
               "review_required_before_import" => ["provider_offer_1"]
             },
             "counteroffer_ids_by_lock_deadline_status" => %{
               "expired" => ["provider_offer_1"]
             },
             "review_counteroffer_ids" => ["provider_offer_1"],
             "no_import_required_counteroffer_ids" => [],
             "import_readiness_rows" => [
               %{
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_import_status" => "review_required_before_import",
                 "provider_counteroffer_lock_deadline_status" => "expired"
               }
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
               "operator_authority" => "not_granted_by_import_readiness_summary",
               "provider_write" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary",
               "offer_acceptance" => "not_performed_by_summary",
               "deadline_evaluation" => "relative_to_now_s",
               "now_s" => 160.0
             }
           } = import_readiness_summary

    assert {:ok, %{"schema_contract" => "provider_counteroffer_import_readiness_summary.v1"}} =
             Schema.validate_artifact(import_readiness_summary)

    assert {:ok, counteroffer_import_readiness_schema} =
             Schema.json_schema("provider_counteroffer_import_readiness_summary.v1")

    assert get_in(counteroffer_import_readiness_schema, ["properties", "model", "const"]) ==
             "artifact_only_provider_counteroffer_import_readiness_summary"

    stale_import_count =
      Map.put(import_readiness_summary, "review_required_before_import_count", 0)

    assert {:error, stale_import_count_report} =
             Schema.validate_artifact(stale_import_count)

    assert Enum.any?(
             stale_import_count_report["errors"],
             &(&1["path"] == "$.review_required_before_import_count" and
                 &1["message"] ==
                   "must equal row-derived review_required_before_import_count")
           )

    stale_import_rows = Map.put(import_readiness_summary, "import_readiness_rows", [])

    assert {:error, stale_import_rows_report} =
             Schema.validate_artifact(stale_import_rows)

    assert Enum.any?(
             stale_import_rows_report["errors"],
             &(&1["path"] == "$.import_readiness_status" and &1["message"] == "must equal clear")
           )

    clear_import_readiness =
      counteroffer_report
      |> Map.put("rows", [])
      |> StationCalendar.provider_counteroffer_import_readiness_summary()

    assert %{
             "import_readiness_status" => "clear",
             "import_classification" => "not_applicable",
             "counteroffer_count" => 0,
             "review_counteroffer_ids" => []
           } = clear_import_readiness

    impact_summary =
      StationCalendar.provider_counteroffer_plan_impact_summary(counteroffer_report, now_s: 120.0)

    assert OrbitalDynamics.provider_counteroffer_plan_impact_summary(counteroffer_report,
             now_s: 120.0
           ) == impact_summary

    assert %{
             "schema_contract" => "provider_counteroffer_plan_impact_summary.v1",
             "model" => "artifact_only_provider_counteroffer_plan_impact_summary",
             "source_artifact_type" => "provider_counteroffer_report.v1",
             "counteroffer_count" => 1,
             "reviewable_count" => 1,
             "plan_impact_status" => "review_required",
             "timing_shift_counteroffer_count" => 1,
             "counteroffer_cost_delta_count" => 1,
             "counteroffer_cost_delta_total" => 125.5,
             "counteroffer_lock_deadline_status_counts" => %{"active" => 1},
             "affected_station_calendar_entry_ids" => ["provider_counteroffer_window"],
             "affected_provider_entry_ids" => ["provider_counteroffer_window"],
             "impact_counteroffer_ids" => ["provider_offer_1"],
             "timing_shift_counteroffer_ids" => ["provider_offer_1"],
             "cost_delta_counteroffer_ids" => ["provider_offer_1"],
             "counteroffer_ids_by_lock_deadline_status" => %{
               "active" => ["provider_offer_1"]
             },
             "rows" => [
               %{
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_start_delta_s" => 30.0,
                 "provider_counteroffer_end_delta_s" => 30.0,
                 "provider_counteroffer_lock_deadline_status" => "active"
               }
             ],
             "impact_rows" => [
               impact_row = %{
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_start_delta_s" => 30.0,
                 "provider_counteroffer_end_delta_s" => 30.0,
                 "provider_counteroffer_lock_deadline_status" => "active"
               }
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_writes",
               "operator_authority" => "not_granted_by_summary",
               "deadline_evaluation" => "relative_to_now_s",
               "now_s" => 120.0
             }
           } = impact_summary

    assert impact_row["provider_counteroffer_duration_delta_s"] == 0.0

    assert {:ok, %{"schema_contract" => "provider_counteroffer_plan_impact_summary.v1"}} =
             Schema.validate_artifact(impact_summary)

    assert {:ok, counteroffer_plan_impact_schema} =
             Schema.json_schema("provider_counteroffer_plan_impact_summary.v1")

    assert get_in(counteroffer_plan_impact_schema, ["properties", "model", "const"]) ==
             "artifact_only_provider_counteroffer_plan_impact_summary"

    stale_impact_count = Map.put(impact_summary, "timing_shift_counteroffer_count", 0)

    assert {:error, stale_impact_count_report} =
             Schema.validate_artifact(stale_impact_count)

    assert Enum.any?(
             stale_impact_count_report["errors"],
             &(&1["path"] == "$.timing_shift_counteroffer_count" and
                 &1["message"] == "must equal row-derived timing_shift_counteroffer_count")
           )

    stale_impact_rows = Map.put(impact_summary, "impact_rows", [])

    assert {:error, stale_impact_rows_report} =
             Schema.validate_artifact(stale_impact_rows)

    assert Enum.any?(
             stale_impact_rows_report["errors"],
             &(&1["path"] == "$.impact_rows" and
                 &1["message"] == "must equal reviewable provider-counteroffer rows")
           )

    stale_summary_report =
      counteroffer_report
      |> Map.put("counteroffer_count", 9)
      |> Map.put("reviewable_count", 0)
      |> Map.put("counteroffer_status_counts", %{"accepted" => 9})
      |> Map.put("counteroffer_negotiation_state_counts", %{"accepted" => 9})
      |> Map.put("counteroffer_lock_deadline_count", 9)
      |> Map.put("earliest_counteroffer_lock_deadline_s", 999.0)
      |> Map.put("counteroffer_cost_delta_count", 9)
      |> Map.put("counteroffer_cost_delta_total", 999.0)

    assert %{
             "counteroffer_count" => 1,
             "reviewable_count" => 1,
             "counteroffer_status_counts" => %{"proposed" => 1},
             "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
             "counteroffer_lock_deadline_count" => 1,
             "earliest_counteroffer_lock_deadline_s" => 150.0
           } =
             StationCalendar.provider_counteroffer_review_summary(stale_summary_report,
               now_s: 160.0
             )

    assert %{
             "counteroffer_count" => 1,
             "reviewable_count" => 1,
             "counteroffer_cost_delta_count" => 1,
             "counteroffer_cost_delta_total" => 125.5
           } =
             StationCalendar.provider_counteroffer_plan_impact_summary(stale_summary_report,
               now_s: 120.0
             )

    duplicate_counteroffer_report =
      Map.put(counteroffer_report, "rows", [
        Map.put(hd(counteroffer_report["rows"]), "provider_counteroffer_id", "provider_offer_2"),
        hd(counteroffer_report["rows"]),
        hd(counteroffer_report["rows"])
      ])

    assert %{"review_counteroffer_ids" => ["provider_offer_1", "provider_offer_2"]} =
             StationCalendar.provider_counteroffer_review_summary(duplicate_counteroffer_report,
               now_s: 160.0
             )

    assert %{"impact_counteroffer_ids" => ["provider_offer_1", "provider_offer_2"]} =
             StationCalendar.provider_counteroffer_plan_impact_summary(
               duplicate_counteroffer_report,
               now_s: 120.0
             )

    direct_counteroffer_report =
      Map.merge(counteroffer_report, %{
        "counteroffer_count" => 1,
        "reviewable_count" => 1,
        "rows" => [
          %{
            "counteroffer_id" => "provider_offer_string",
            "offer_status" => "proposal",
            "price_delta" => "125.5",
            "schedule_lock_deadline_s" => "150.0",
            "offered_start_s" => "130.0",
            "offered_end_s" => "170.0",
            "starts_at_s" => "100.0",
            "ends_at_s" => "140.0",
            "ground_station_id" => "equator_prime",
            "station_calendar_provider_entry_id" => "provider_counteroffer_window"
          }
        ]
      })

    assert %{
             "counteroffer_count" => 1,
             "reviewable_count" => 1,
             "counteroffer_lock_deadline_count" => 1,
             "earliest_counteroffer_lock_deadline_s" => 150.0,
             "counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
             "review_counteroffer_ids" => ["provider_offer_string"],
             "rows" => [
               %{
                 "id" => "provider_counteroffer:1:provider_offer_string",
                 "provider_counteroffer_id" => "provider_offer_string",
                 "provider_counteroffer_status" => "proposal",
                 "provider_counteroffer_negotiation_state" => "proposed",
                 "provider_counteroffer_cost_delta" => 125.5,
                 "provider_counteroffer_lock_deadline_s" => 150.0,
                 "provider_counteroffer_starts_at_s" => 130.0,
                 "provider_counteroffer_ends_at_s" => 170.0,
                 "reviewable" => true,
                 "required_operator_action" => "review_provider_counteroffer",
                 "source_station_calendar_entry" => %{}
               }
             ]
           } =
             direct_review_summary =
             StationCalendar.provider_counteroffer_review_summary(direct_counteroffer_report,
               now_s: 160.0
             )

    assert {:ok, %{"schema_contract" => "provider_counteroffer_review_summary.v1"}} =
             Schema.validate_artifact(direct_review_summary)

    assert %{
             "review_required_before_import_count" => 1,
             "counteroffer_ids_by_import_status" => %{
               "review_required_before_import" => ["provider_offer_string"]
             },
             "import_readiness_rows" => [
               %{
                 "provider_counteroffer_id" => "provider_offer_string",
                 "provider_counteroffer_import_status" => "review_required_before_import",
                 "provider_counteroffer_lock_deadline_s" => 150.0
               }
             ]
           } =
             direct_import_summary =
             StationCalendar.provider_counteroffer_import_readiness_summary(
               direct_counteroffer_report,
               now_s: 160.0
             )

    assert {:ok, %{"schema_contract" => "provider_counteroffer_import_readiness_summary.v1"}} =
             Schema.validate_artifact(direct_import_summary)

    assert %{
             "timing_shift_counteroffer_count" => 1,
             "counteroffer_cost_delta_count" => 1,
             "counteroffer_cost_delta_total" => 125.5,
             "timing_shift_counteroffer_ids" => ["provider_offer_string"],
             "cost_delta_counteroffer_ids" => ["provider_offer_string"],
             "rows" => [
               direct_impact_row = %{
                 "provider_counteroffer_id" => "provider_offer_string",
                 "provider_counteroffer_start_delta_s" => 30.0,
                 "provider_counteroffer_end_delta_s" => 30.0
               }
             ]
           } =
             direct_impact_summary =
             StationCalendar.provider_counteroffer_plan_impact_summary(
               direct_counteroffer_report,
               now_s: 120.0
             )

    assert direct_impact_row["provider_counteroffer_duration_delta_s"] == 0.0

    assert {:ok, %{"schema_contract" => "provider_counteroffer_plan_impact_summary.v1"}} =
             Schema.validate_artifact(direct_impact_summary)

    malformed_direct_counteroffer_report =
      Map.put(direct_counteroffer_report, "rows", [
        %{
          "provider_counteroffer_id" => "provider_offer_malformed",
          "provider_counteroffer_status" => "proposed",
          "provider_counteroffer_cost_delta" => "not-a-number",
          "provider_counteroffer_lock_deadline_s" => "soon",
          "provider_counteroffer_starts_at_s" => "later",
          "provider_counteroffer_ends_at_s" => "never",
          "reviewable" => "false"
        }
      ])

    assert %{
             "reviewable_count" => 0,
             "counteroffer_lock_deadline_count" => 0,
             "counteroffer_lock_deadline_status_counts" => %{"missing" => 1},
             "review_counteroffer_ids" => [],
             "rows" => [malformed_review_row]
           } =
             malformed_review_summary =
             StationCalendar.provider_counteroffer_review_summary(
               malformed_direct_counteroffer_report,
               now_s: 160.0
             )

    refute Map.has_key?(malformed_review_row, "provider_counteroffer_cost_delta")
    refute Map.has_key?(malformed_review_row, "provider_counteroffer_lock_deadline_s")
    refute Map.has_key?(malformed_review_row, "provider_counteroffer_starts_at_s")
    refute Map.has_key?(malformed_review_row, "provider_counteroffer_ends_at_s")
    assert malformed_review_row["reviewable"] == false
    assert malformed_review_row["required_operator_action"] == "none"

    assert {:ok, %{"schema_contract" => "provider_counteroffer_review_summary.v1"}} =
             Schema.validate_artifact(malformed_review_summary)

    assert %{
             "review_required_before_import_count" => 0,
             "no_import_required_count" => 1,
             "no_import_required_counteroffer_ids" => ["provider_offer_malformed"],
             "provider_counteroffer_import_status_counts" => %{"not_applicable" => 1}
           } =
             malformed_import_summary =
             StationCalendar.provider_counteroffer_import_readiness_summary(
               malformed_direct_counteroffer_report,
               now_s: 160.0
             )

    assert {:ok, %{"schema_contract" => "provider_counteroffer_import_readiness_summary.v1"}} =
             Schema.validate_artifact(malformed_import_summary)

    assert %{
             "timing_shift_counteroffer_count" => 0,
             "counteroffer_cost_delta_count" => 0,
             "counteroffer_cost_delta_total" => 0,
             "timing_shift_counteroffer_ids" => [],
             "cost_delta_counteroffer_ids" => []
           } =
             malformed_impact_summary =
             StationCalendar.provider_counteroffer_plan_impact_summary(
               malformed_direct_counteroffer_report,
               now_s: 120.0
             )

    assert {:ok, %{"schema_contract" => "provider_counteroffer_plan_impact_summary.v1"}} =
             Schema.validate_artifact(malformed_impact_summary)

    invalid_counteroffer_count = Map.put(counteroffer_report, "counteroffer_count", 2)

    assert {:error, invalid_counteroffer_count_report} =
             Schema.validate_artifact(invalid_counteroffer_count)

    assert Enum.any?(
             invalid_counteroffer_count_report["errors"],
             &(&1["path"] == "$.counteroffer_count")
           )

    invalid_cost_total = Map.put(counteroffer_report, "counteroffer_cost_delta_total", 126.5)

    assert {:error, invalid_cost_total_report} = Schema.validate_artifact(invalid_cost_total)

    assert Enum.any?(
             invalid_cost_total_report["errors"],
             &(&1["path"] == "$.counteroffer_cost_delta_total")
           )

    invalid_state_counts =
      put_in(counteroffer_report, ["counteroffer_negotiation_state_counts", "proposed"], 2)

    assert {:error, invalid_state_counts_report} =
             Schema.validate_artifact(invalid_state_counts)

    assert Enum.any?(
             invalid_state_counts_report["errors"],
             &(&1["path"] == "$.counteroffer_negotiation_state_counts")
           )

    assert_summary_handoff(
      review_summary,
      &StationCalendar.provider_counteroffer_review_summary/1,
      &StationCalendar.provider_counteroffer_review_summary(&1, now_s: 999.0),
      &OrbitalDynamics.provider_counteroffer_review_summary/1,
      &OrbitalDynamics.provider_counteroffer_review_summary(&1, now_s: 999.0)
    )

    assert_summary_handoff(
      import_readiness_summary,
      &StationCalendar.provider_counteroffer_import_readiness_summary/1,
      &StationCalendar.provider_counteroffer_import_readiness_summary(&1, now_s: 999.0),
      &OrbitalDynamics.provider_counteroffer_import_readiness_summary/1,
      &OrbitalDynamics.provider_counteroffer_import_readiness_summary(&1, now_s: 999.0)
    )

    assert_summary_handoff(
      impact_summary,
      &StationCalendar.provider_counteroffer_plan_impact_summary/1,
      &StationCalendar.provider_counteroffer_plan_impact_summary(&1, now_s: 999.0),
      &OrbitalDynamics.provider_counteroffer_plan_impact_summary/1,
      &OrbitalDynamics.provider_counteroffer_plan_impact_summary(&1, now_s: 999.0)
    )

    counteroffer_review = OperatorReview.from_provider_counteroffer_report(counteroffer_report)

    assert %{
             "source_artifact_type" => "provider_counteroffer_report.v1",
             "provider_counteroffer_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "provider_counteroffer_review",
                 "required_operator_action" => "review_provider_counteroffer",
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_status" => "proposed",
                 "provider_counteroffer_negotiation_state" => "proposed",
                 "source_provider_counteroffer" => %{
                   "provider_counteroffer_id" => "provider_offer_1"
                 }
               }
             ]
           } = counteroffer_review

    counteroffer_manifest = CadenceImport.from_provider_counteroffer_report(counteroffer_report)

    assert %{
             "source_artifact_type" => "provider_counteroffer_report.v1",
             "import_action_counts" => %{"review_provider_counteroffer" => 1},
             "rows" => [
               %{
                 "import_action" => "review_provider_counteroffer",
                 "source_review_type" => "provider_counteroffer_review",
                 "source_review_action" => "review_provider_counteroffer",
                 "provider_counteroffer_id" => "provider_offer_1",
                 "provider_counteroffer_negotiation_state" => "proposed",
                 "source_provider_counteroffer" => %{
                   "provider_counteroffer_id" => "provider_offer_1"
                 }
               }
             ]
           } = counteroffer_manifest

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(counteroffer_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(counteroffer_manifest)

    invalid_provider =
      put_in(provider, [:entries, Access.at(0), :counteroffer_id], "bad offer id")

    assert {:error, invalid_provider_report} =
             invalid_provider
             |> stringify_keys()
             |> Schema.validate_artifact()

    assert Enum.any?(
             invalid_provider_report["errors"],
             &(&1["path"] == "$.entries[0].counteroffer_id")
           )

    assert_raise ArgumentError, ~r/provider_counteroffer_id must match stable ID pattern/, fn ->
      StationCalendar.to_ground_network(invalid_provider)
    end
  end

  test "rejects invalid provider calendars" do
    assert {:error, report} =
             Schema.validate_artifact(%{
               "schema_contract" => "station_calendar_provider.v1",
               "id" => "ops_calendar",
               "entries" => [
                 %{
                   "ground_station_id" => "equator_prime",
                   "availability" => "available",
                   "starts_at_s" => 20.0,
                   "ends_at_s" => 10.0
                 }
               ]
             })

    assert Enum.any?(report["errors"], &(&1["path"] == "$.entries[0].ends_at_s"))

    assert {:error, report} =
             Schema.validate_artifact(%{
               "schema_contract" => "station_calendar_provider.v1",
               "id" => "ops_calendar",
               "entries" => [
                 %{
                   "ground_station_id" => "equator_prime",
                   "availability" => "available",
                   "starts_at_s" => 10.0,
                   "ends_at_s" => 20.0
                 }
               ]
             })

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.trust_boundary" and
                 &1["message"] =~ "requires trust_boundary")
           )

    invalid_reservation_hold_id = %{
      "schema_contract" => "station_calendar_provider.v1",
      "id" => "ops_calendar",
      "trust_boundary" => "declared_station_calendar",
      "entries" => [
        %{
          "station_id" => "equator_prime",
          "availability" => "reservation_hold",
          "reservation_hold_id" => "bad hold id",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0
        }
      ]
    }

    assert {:error, invalid_reservation_hold_id_report} =
             Schema.validate_artifact(invalid_reservation_hold_id)

    assert Enum.any?(
             invalid_reservation_hold_id_report["errors"],
             &(&1["path"] == "$.entries[0].reservation_hold_id" and
                 &1["message"] =~ "stable ID pattern")
           )

    invalid_hold_id =
      put_in(invalid_reservation_hold_id, ["entries", Access.at(0), "hold_id"], "bad hold id")
      |> put_in(["entries", Access.at(0), "reservation_hold_id"], "provider_hold_1")

    assert {:error, invalid_hold_id_report} = Schema.validate_artifact(invalid_hold_id)

    assert Enum.any?(
             invalid_hold_id_report["errors"],
             &(&1["path"] == "$.entries[0].hold_id" and
                 &1["message"] =~ "stable ID pattern")
           )

    assert_raise ArgumentError, ~r/entries must be a list/, fn ->
      StationCalendar.to_ground_network(%{id: "ops_calendar", entries: %{}})
    end

    assert_raise ArgumentError, ~r/ground_station_id is required/, fn ->
      StationCalendar.to_ground_network(%{id: "ops_calendar", entries: [%{}]})
    end

    assert_raise ArgumentError, ~r/ground_station_id must match stable ID pattern/, fn ->
      StationCalendar.to_ground_network(%{
        id: "ops_calendar",
        entries: [%{ground_station_id: "bad station id", availability: "available"}]
      })
    end

    assert_raise ArgumentError, ~r/reservation_id must match stable ID pattern/, fn ->
      StationCalendar.to_ground_network(%{
        id: "ops_calendar",
        entries: [
          %{
            ground_station_id: "equator_prime",
            availability: "reserved",
            reservation_id: "bad reservation id"
          }
        ]
      })
    end

    assert_raise ArgumentError, ~r/reservation_id must match stable ID pattern/, fn ->
      StationCalendar.to_ground_network(%{
        id: "ops_calendar",
        entries: [
          %{
            ground_station_id: "equator_prime",
            availability: "reservation_hold",
            hold_id: "bad hold id"
          }
        ]
      })
    end

    assert_raise ArgumentError, ~r/availability must be one of/, fn ->
      StationCalendar.to_ground_network(%{
        id: "ops_calendar",
        entries: [%{ground_station_id: "equator_prime", availability: "unknown"}]
      })
    end

    assert_raise ArgumentError, ~r/capacity_fraction must be between 0.0 and 1.0/, fn ->
      StationCalendar.to_ground_network(%{
        id: "ops_calendar",
        entries: [%{ground_station_id: "equator_prime", availability: 1.5}]
      })
    end

    assert_raise ArgumentError, ~r/capacity_fraction must be between 0.0 and 1.0/, fn ->
      StationCalendar.to_ground_network(%{
        id: "ops_calendar",
        entries: [
          %{
            ground_station_id: "equator_prime",
            availability: "available",
            capacity_fraction: -0.1
          }
        ]
      })
    end
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key

  defp assert_summary_handoff(summary, module_summary, facade_summary) do
    assert module_summary.(summary) == summary
    assert facade_summary.(summary) == summary

    atom_keyed_summary =
      Map.new(summary, fn {key, value} -> {String.to_atom(key), value} end)

    assert module_summary.(atom_keyed_summary) == summary
    assert facade_summary.(atom_keyed_summary) == summary
  end

  defp assert_summary_handoff(
         summary,
         module_summary,
         module_summary_with_opts,
         facade_summary,
         facade_summary_with_opts
       ) do
    assert module_summary.(summary) == summary
    assert module_summary_with_opts.(summary) == summary
    assert facade_summary.(summary) == summary
    assert facade_summary_with_opts.(summary) == summary

    atom_keyed_summary =
      Map.new(summary, fn {key, value} -> {String.to_atom(key), value} end)

    assert module_summary.(atom_keyed_summary) == summary
    assert facade_summary.(atom_keyed_summary) == summary
  end
end
