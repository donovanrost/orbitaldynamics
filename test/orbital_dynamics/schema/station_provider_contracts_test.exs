defmodule OrbitalDynamics.Schema.StationProviderContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports nested station calendar provider entry schema" do
    assert {:ok, schema} = Schema.json_schema("station_calendar_provider.v1")

    entry_schema = get_in(schema, ["properties", "entries", "items"])

    assert entry_schema["type"] == "object"

    assert get_in(entry_schema, ["properties", "ground_station_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(entry_schema, ["properties", "station_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(entry_schema, ["properties", "availability", "oneOf", Access.at(0), "enum"]) ==
             [
               "available",
               "unavailable",
               "outage",
               "down",
               "offline",
               "reduced_capacity",
               "maintenance",
               "reserved",
               "hold",
               "held",
               "on_hold",
               "onhold",
               "reservation_held",
               "reserved_hold",
               "reservation_hold"
             ]

    assert %{"required" => ["ground_station_id"]} in entry_schema["anyOf"]
    assert %{"required" => ["station_id"]} in entry_schema["anyOf"]
    assert %{"required" => ["availability"]} in hd(entry_schema["allOf"])["anyOf"]

    assert get_in(entry_schema, ["properties", "capacity_pack_capacity_fraction"]) == %{
             "type" => "number",
             "minimum" => 0.0,
             "maximum" => 1.0
           }

    assert get_in(entry_schema, ["properties", "capacity_fraction", "type"]) == "number"

    assert get_in(entry_schema, ["properties", "reservation_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(entry_schema, ["properties", "reservation_hold_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(entry_schema, ["properties", "hold_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(entry_schema, ["properties", "counteroffer_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(entry_schema, ["properties", "provider_counteroffer_status", "type"]) ==
             "string"

    assert get_in(entry_schema, ["properties", "provider_counteroffer_cost_delta", "type"]) ==
             "number"

    assert get_in(entry_schema, [
             "properties",
             "provider_counteroffer_lock_deadline_s",
             "type"
           ]) == "number"

    assert get_in(entry_schema, ["properties", "provider_counteroffer_starts_at_s", "type"]) ==
             "number"

    assert get_in(entry_schema, ["properties", "provider_counteroffer_ends_at_s", "type"]) ==
             "number"

    assert get_in(entry_schema, ["properties", "held_by", "type"]) == "string"
    assert get_in(entry_schema, ["properties", "hold_owner", "type"]) == "string"
    assert get_in(entry_schema, ["properties", "hold_status", "type"]) == "string"

    assert get_in(entry_schema, ["properties", "reserved_by", "type"]) == "string"
    assert get_in(entry_schema, ["properties", "direction", "type"]) == "string"
    assert get_in(entry_schema, ["properties", "directions", "items", "type"]) == "string"

    assert get_in(entry_schema, [
             "properties",
             "station_calendar_directions",
             "items",
             "type"
           ]) == "string"

    assert get_in(entry_schema, ["properties", "provenance", "type"]) == "object"
  end

  test "exports nested station calendar report affected-contact schema" do
    assert {:ok, schema} = Schema.json_schema("station_calendar_report.v1")

    row_schema = get_in(schema, ["properties", "affected_contacts", "items"])

    assert get_in(schema, ["properties", "model", "const"]) ==
             "campaign_ground_network_interval_overlay"

    assert get_in(schema, ["properties", "affected_duration_s", "type"]) == "number"

    assert get_in(schema, ["properties", "input_contact_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "affected_contact_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, [
             "properties",
             "calendar_entry_trust_boundary_status_counts",
             "additionalProperties",
             "type"
           ]) == "integer"

    assert get_in(schema, [
             "properties",
             "station_calendar_trust_boundary_status_counts",
             "additionalProperties",
             "type"
           ]) == "integer"

    assert get_in(schema, ["properties", "duplicate_affected_contact_id_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "provider_calendar_contention_group_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "provider_counteroffer_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    provider_contention_group_schema =
      get_in(schema, ["properties", "provider_calendar_contention_groups", "items"])

    assert get_in(provider_contention_group_schema, ["properties", "entry_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) == [
             "declared_data_only",
             "no_network_calls",
             "no_provider_reservation",
             "no_schedule_mutation",
             "no_conflict_resolution"
           ]

    assert get_in(row_schema, ["properties", "overlap_starts_at_s", "type"]) == "number"
    assert get_in(row_schema, ["properties", "overlap_ends_at_s", "type"]) == "number"
    assert get_in(row_schema, ["properties", "overlap_duration_s", "type"]) == "number"

    assert get_in(row_schema, ["properties", "station_calendar_provider_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "station_calendar_directions", "items", "type"]) ==
             "string"

    assert get_in(row_schema, [
             "properties",
             "station_calendar_ambiguous_entry_count",
             "minimum"
           ]) == 0

    assert get_in(row_schema, [
             "properties",
             "station_calendar_reservation_ids",
             "items",
             "pattern"
           ]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "contact_success_factor", "maximum"]) == 1.0

    assert get_in(row_schema, ["properties", "provider_counteroffer_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, ["properties", "provider_counteroffer_status", "type"]) ==
             "string"

    assert get_in(row_schema, ["properties", "provider_counteroffer_cost_delta", "type"]) ==
             "number"

    source_entry_schema = get_in(row_schema, ["properties", "source_station_calendar_entry"])

    assert "ambiguous" in get_in(source_entry_schema, ["properties", "status", "enum"])

    assert get_in(source_entry_schema, ["properties", "provider_counteroffer_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(row_schema, [
             "properties",
             "source_station_calendar_overlaps",
             "items",
             "properties",
             "provider_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]
  end

  test "validates checked-in station reservation review summary fixture" do
    review_summary = read_json!("study_results/station_reservation_review_summary_v1.json")

    reservation_report = station_reservation_summary_fixture_report()

    generated_review_summary =
      OrbitalDynamics.station_reservation_review_summary(reservation_report, now_s: 300.0)

    assert generated_review_summary == review_summary

    assert {:ok, %{"schema_contract" => "station_reservation_review_summary.v1"}} =
             Schema.validate_artifact(review_summary)

    assert %{
             "source_artifact_type" => "station_reservation_report.v1",
             "source" => "station_calendar_report.reservation_evidence",
             "reservation_count" => 3,
             "affected_contact_reservation_count" => 1,
             "provider_calendar_contention_group_count" => 2,
             "reservation_review_status" => "review_required",
             "reservation_expiration_count" => 2,
             "earliest_reservation_expires_at_s" => 240.0,
             "expired_reservation_count" => 1,
             "active_reservation_count" => 1,
             "missing_reservation_expiration_count" => 1,
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
             "review_reservation_ids" => [
               "reservation_active",
               "reservation_expired",
               "reservation_missing"
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_reservation",
               "operator_authority" => "not_granted_by_summary",
               "deadline_evaluation" => "relative_to_now_s",
               "now_s" => 300.0
             }
           } = review_summary
  end

  test "validates checked-in station calendar precedence summary fixture" do
    precedence_summary = read_json!("study_results/station_calendar_precedence_summary_v1.json")

    station_calendar_report = station_calendar_precedence_summary_fixture_report()

    generated_precedence_summary =
      OrbitalDynamics.station_calendar_precedence_summary(station_calendar_report)

    assert generated_precedence_summary == precedence_summary

    assert {:ok, %{"schema_contract" => "station_calendar_precedence_summary.v1"}} =
             Schema.validate_artifact(precedence_summary)

    assert %{
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
             "affected_contact_ids_by_applied_status" => %{
               "unavailable" => ["dl_1"]
             },
             "affected_contact_ids_by_overlap_availability" => %{
               "reduced_capacity" => ["dl_1"],
               "reserved" => ["dl_1"],
               "unavailable" => ["dl_1"]
             },
             "applied_status_counts" => %{"unavailable" => 1},
             "reserved_under_higher_precedence_contact_count" => 1,
             "reserved_under_higher_precedence_contact_ids" => ["dl_1"],
             "reserved_under_higher_precedence_contact_ids_by_applied_availability" => %{
               "unavailable" => ["dl_1"]
             },
             "reserved_under_higher_precedence_contact_ids_by_applied_status" => %{
               "unavailable" => ["dl_1"]
             },
             "unavailable_contact_ids" => ["dl_1"],
             "reserved_overlap_contact_ids" => ["dl_1"],
             "reduced_capacity_contact_ids" => ["dl_1"],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_reservation",
               "operator_authority" => "not_granted_by_summary",
               "scope" => "station_calendar_availability_precedence_review"
             }
           } = precedence_summary
  end

  test "validates checked-in provider counteroffer summary fixtures" do
    review_summary = read_json!("study_results/provider_counteroffer_review_summary_v1.json")

    import_readiness_summary =
      read_json!("study_results/provider_counteroffer_import_readiness_summary_v1.json")

    impact_summary = read_json!("study_results/provider_counteroffer_plan_impact_summary_v1.json")

    counteroffer_report = provider_counteroffer_summary_fixture_report()

    generated_review_summary =
      OrbitalDynamics.provider_counteroffer_review_summary(counteroffer_report, now_s: 160.0)

    generated_import_readiness_summary =
      OrbitalDynamics.provider_counteroffer_import_readiness_summary(
        counteroffer_report,
        now_s: 160.0
      )

    generated_impact_summary =
      OrbitalDynamics.provider_counteroffer_plan_impact_summary(
        counteroffer_report,
        now_s: 120.0
      )

    assert generated_review_summary == review_summary
    assert generated_import_readiness_summary == import_readiness_summary
    assert generated_impact_summary == impact_summary

    assert {:ok, %{"schema_contract" => "provider_counteroffer_review_summary.v1"}} =
             Schema.validate_artifact(review_summary)

    assert {:ok, %{"schema_contract" => "provider_counteroffer_import_readiness_summary.v1"}} =
             Schema.validate_artifact(import_readiness_summary)

    assert {:ok, %{"schema_contract" => "provider_counteroffer_plan_impact_summary.v1"}} =
             Schema.validate_artifact(impact_summary)

    assert %{
             "source_artifact_type" => "provider_counteroffer_report.v1",
             "source_counteroffer_artifact_type" => "station_calendar_report.v1",
             "counteroffer_count" => 1,
             "reviewable_count" => 1,
             "counteroffer_review_status" => "review_required",
             "counteroffer_status_counts" => %{"proposed" => 1},
             "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
             "counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
             "counteroffer_ids_by_lock_deadline_status" => %{
               "expired" => ["provider_offer_1"]
             },
             "review_counteroffer_ids" => ["provider_offer_1"],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_writes",
               "operator_authority" => "not_granted_by_summary",
               "deadline_evaluation" => "relative_to_now_s",
               "now_s" => 160.0
             }
           } = review_summary

    assert %{
             "source_artifact_type" => "provider_counteroffer_report.v1",
             "source_counteroffer_artifact_type" => "station_calendar_report.v1",
             "counteroffer_count" => 1,
             "reviewable_count" => 1,
             "import_readiness_status" => "review_required",
             "import_classification" => "review_only",
             "review_required_before_import_count" => 1,
             "provider_counteroffer_import_status_counts" => %{
               "review_required_before_import" => 1
             },
             "required_import_action_counts" => %{"review_provider_counteroffer" => 1},
             "counteroffer_ids_by_import_status" => %{
               "review_required_before_import" => ["provider_offer_1"]
             },
             "counteroffer_ids_by_required_import_action" => %{
               "review_provider_counteroffer" => ["provider_offer_1"]
             },
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
               "operator_authority" => "not_granted_by_import_readiness_summary",
               "provider_write" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary",
               "offer_acceptance" => "not_performed_by_summary"
             }
           } = import_readiness_summary

    assert %{
             "source_artifact_type" => "provider_counteroffer_report.v1",
             "source_counteroffer_artifact_type" => "station_calendar_report.v1",
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
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_writes",
               "operator_authority" => "not_granted_by_summary",
               "deadline_evaluation" => "relative_to_now_s",
               "now_s" => 120.0
             }
           } = impact_summary
  end

  test "validates checked-in station reservation hold summary fixtures" do
    hold_summary = read_json!("study_results/station_reservation_hold_summary_v1.json")

    hold_import_readiness_summary =
      read_json!("study_results/station_reservation_hold_import_readiness_summary_v1.json")

    reservation_report = station_reservation_summary_fixture_report()

    generated_hold_summary =
      OrbitalDynamics.station_reservation_hold_summary(reservation_report, now_s: 300.0)

    generated_hold_import_readiness_summary =
      OrbitalDynamics.station_reservation_hold_import_readiness_summary(
        reservation_report,
        now_s: 300.0
      )

    assert generated_hold_summary == hold_summary
    assert generated_hold_import_readiness_summary == hold_import_readiness_summary

    assert {:ok, %{"schema_contract" => "station_reservation_hold_summary.v1"}} =
             Schema.validate_artifact(hold_summary)

    assert {:ok,
            %{
              "schema_contract" => "station_reservation_hold_import_readiness_summary.v1"
            }} = Schema.validate_artifact(hold_import_readiness_summary)

    assert %{
             "source_artifact_type" => "station_reservation_report.v1",
             "source" => "station_calendar_report.reservation_evidence",
             "reservation_hold_count" => 2,
             "affected_contact_reservation_hold_count" => 1,
             "provider_calendar_contention_hold_count" => 1,
             "reservation_hold_review_status" => "review_required",
             "reservation_hold_expiration_status_counts" => %{
               "expired" => 1,
               "missing" => 1
             },
             "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
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
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_reservation",
               "operator_authority" => "not_granted_by_summary",
               "deadline_evaluation" => "relative_to_now_s",
               "now_s" => 300.0
             }
           } = hold_summary

    assert %{
             "source_artifact_type" => "station_reservation_report.v1",
             "source" => "station_calendar_report.reservation_evidence",
             "reservation_hold_count" => 2,
             "import_readiness_status" => "review_required",
             "import_classification" => "review_only",
             "review_required_before_import_count" => 2,
             "reservation_hold_import_status_counts" => %{
               "review_required_before_import" => 2
             },
             "required_import_action_counts" => %{
               "review_station_provider_contention" => 1,
               "review_station_reservation_overlap" => 1
             },
             "reservation_hold_ids_by_required_import_action" => %{
               "review_station_provider_contention" => ["reservation_missing"],
               "review_station_reservation_overlap" => ["reservation_expired"]
             },
             "reservation_hold_ids_by_direction" => %{},
             "reservation_hold_ids_by_direction_and_ground_station_id" => %{},
             "reservation_hold_contact_ids_by_import_status" => %{
               "review_required_before_import" => ["dl_source_reserved"]
             },
             "reservation_hold_contact_ids_by_direction" => %{},
             "reservation_hold_contact_ids_by_direction_and_ground_station_id" => %{},
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
               "provider_write" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary",
               "reservation_acceptance" => "not_performed_by_summary",
               "operator_authority" => "not_granted_by_import_readiness_summary"
             }
           } = hold_import_readiness_summary
  end

  defp station_calendar_precedence_summary_fixture_report do
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

    OrbitalDynamics.station_calendar_report(contacts, provider, source: "ops_calendar")
  end

  defp provider_counteroffer_summary_fixture_report do
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

    contacts
    |> OrbitalDynamics.station_calendar_report(provider, source: "provider_counteroffers")
    |> OrbitalDynamics.provider_counteroffer_report()
  end

  defp station_reservation_summary_fixture_report do
    OrbitalDynamics.station_reservation_report(%{
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
          "required_operator_action" => "review_station_provider_contention"
        },
        %{
          "provider_calendar_contention_status" => "provider_calendar_overlap",
          "ground_station_id" => "polar_prime",
          "reservation_ids" => ["reservation_missing"],
          "reservation_statuses" => ["held"],
          "reserved_by" => ["partner_calendar"],
          "required_operator_action" => "review_station_provider_contention"
        }
      ]
    })
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
