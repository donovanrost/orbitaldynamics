defmodule OrbitalDynamics.Communications.ContactIntentTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema}
  alias OrbitalDynamics.Communications.ContactIntent

  test "declares contact intent capabilities" do
    assert %{
             artifact_contract: "contact_intent.v1",
             summary_artifact_contract: "contact_intent_summary.v1",
             validation_level: :artifact_contract,
             directions: directions,
             source_activity_types: [
               "downlink",
               "planned_contact",
               "contact",
               "command",
               "tracking",
               "health_check"
             ],
             default_direction_by_activity_type: %{
               "downlink" => "downlink",
               "command" => "command",
               "tracking" => "tracking",
               "health_check" => "health_check"
             },
             provider_direction_aliases: provider_direction_aliases,
             station_calendar_direction_aliases: station_calendar_direction_aliases,
             provider_result_map_value_keys: provider_result_map_value_keys,
             station_unavailable_aliases: station_unavailable_aliases,
             station_availability_precedence: station_availability_precedence,
             station_capacity_fraction_paths: station_capacity_fraction_paths,
             station_capacity_percent_paths: station_capacity_percent_paths,
             station_capacity_value_paths: station_capacity_value_paths,
             required_capacity_fraction_paths: required_capacity_fraction_paths,
             required_capacity_percent_paths: required_capacity_percent_paths,
             required_capacity_value_paths: required_capacity_value_paths,
             required_capacity_fraction_source_values: required_capacity_fraction_source_values,
             source_station_capacity_fraction_paths: source_station_capacity_fraction_paths,
             source_station_capacity_percent_paths: source_station_capacity_percent_paths,
             source_station_capacity_value_paths: source_station_capacity_value_paths,
             activity_stable_identity_fields: activity_stable_identity_fields,
             station_calendar_id_list_fields: station_calendar_id_list_fields,
             station_reservation_expiration_fields: station_reservation_expiration_fields,
             station_calendar_reservation_expiration_fields:
               station_calendar_reservation_expiration_fields,
             summary_routing_fields: summary_routing_fields,
             public_facades: [
               :contact_intents_from_activities,
               :contact_intent_from_activity!,
               :contact_intent_summary
             ],
             policy_gate_statuses: [
               "auto_approvable",
               "operator_review_required",
               "blocked_by_policy"
             ],
             summary_row_semantics: summary_row_semantics,
             row_semantics: row_semantics,
             approval_policy_boundary: :optional_policy_decision_v1,
             known_limits: known_limits
           } = ContactIntent.capabilities()

    assert directions == ["downlink", "uplink", "command", "tracking", "health_check"]

    assert Map.take(provider_direction_aliases, [
             "cmd",
             "commands",
             "sband_command",
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
             "commands" => "command",
             "sband_command" => "command",
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

    assert Map.take(station_calendar_direction_aliases, [
             "uplink",
             "commands",
             "sband_command",
             "s_band_command",
             "up",
             "up_link",
             "dl",
             "track",
             "healthcheck"
           ]) == %{
             "uplink" => "command",
             "commands" => "command",
             "sband_command" => "command",
             "s_band_command" => "command",
             "up" => "command",
             "up_link" => "command",
             "dl" => "downlink",
             "track" => "tracking",
             "healthcheck" => "health_check"
           }

    assert "result" in provider_result_map_value_keys
    assert "provider_status" in provider_result_map_value_keys
    assert "provider_outcome" in provider_result_map_value_keys
    assert "diagnostics" in provider_result_map_value_keys

    assert station_unavailable_aliases == ["outage", "down", "offline"]

    assert station_availability_precedence == %{
             "unavailable" => 5,
             "maintenance" => 5,
             "reserved" => 4,
             "reduced_capacity" => 3,
             "available" => 1
           }

    assert ["availability"] in station_capacity_fraction_paths
    assert ["capacity_pack_capacity_fraction"] in station_capacity_fraction_paths
    assert ["station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_fraction"] in station_capacity_fraction_paths
    assert ["throughput_model", "availability"] in station_capacity_fraction_paths
    assert ["throughput_model", "station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_model", "availability"] in station_capacity_fraction_paths
    assert ["capacity_model", "capacity_fraction"] in station_capacity_fraction_paths
    assert ["activity_context", "availability"] in station_capacity_fraction_paths
    assert ["activity_context", "capacity_fraction"] in station_capacity_fraction_paths

    assert ["station_capacity_percent"] in station_capacity_percent_paths
    assert ["capacity_percent"] in station_capacity_percent_paths
    assert ["throughput_model", "station_capacity_percent"] in station_capacity_percent_paths
    assert ["capacity_model", "capacity_percent"] in station_capacity_percent_paths
    assert ["activity_context", "capacity_percent"] in station_capacity_percent_paths

    assert source_station_capacity_fraction_paths == station_capacity_fraction_paths
    assert source_station_capacity_percent_paths == station_capacity_percent_paths
    assert source_station_capacity_value_paths == station_capacity_value_paths

    assert %{unit: :fraction, path: ["availability"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_pack_capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :percent, path: ["capacity_percent"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_model", "availability"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["activity_context", "capacity_fraction"]} in source_station_capacity_value_paths

    assert %{unit: :percent, path: ["capacity_model", "station_capacity_percent"]} in source_station_capacity_value_paths

    assert ["required_capacity_fraction"] in required_capacity_fraction_paths
    assert ["required_station_capacity_fraction"] in required_capacity_fraction_paths
    assert ["throughput_model", "required_capacity_fraction"] in required_capacity_fraction_paths
    assert ["capacity_model", "station_capacity_requirement"] in required_capacity_fraction_paths

    assert ["activity_context", "required_station_capacity_fraction"] in required_capacity_fraction_paths

    assert ["required_capacity_percent"] in required_capacity_percent_paths

    assert ["throughput_model", "required_station_capacity_percent"] in required_capacity_percent_paths

    assert ["capacity_model", "station_capacity_requirement_percent"] in required_capacity_percent_paths

    assert %{unit: :fraction, path: ["required_capacity_fraction"]} in required_capacity_value_paths

    assert %{
             unit: :percent,
             path: ["activity_context", "station_capacity_requirement_percent"]
           } in required_capacity_value_paths

    assert required_capacity_fraction_source_values == [
             "contact_required_capacity_fraction",
             "throughput_model",
             "capacity_model",
             "activity_context"
           ]

    assert activity_stable_identity_fields == [
             "id",
             "scenario_id",
             "spacecraft_id",
             "ground_station_id",
             "source_window_id",
             "station_calendar_entry_id",
             "station_reservation_id"
           ]

    assert station_calendar_id_list_fields == [
             "station_calendar_overlap_entry_ids",
             "station_calendar_ambiguous_entry_ids",
             "station_calendar_reservation_ids"
           ]

    assert station_reservation_expiration_fields == [
             "station_reservation_expires_at_s",
             "reservation_expires_at_s",
             "reservation_hold_expires_at_s",
             "hold_expires_at_s",
             "expires_at_s",
             "expires_at"
           ]

    assert station_calendar_reservation_expiration_fields == [
             "station_calendar_reservation_expires_at_s"
             | station_reservation_expiration_fields
           ]

    assert summary_routing_fields == [
             "contact_intent_count",
             "capacity_pack_required_contact_count",
             "capacity_pack_required_capacity_fraction",
             "capacity_pack_required_capacity_fraction_by_ground_station_id",
             "capacity_pack_required_capacity_fraction_by_direction",
             "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id",
             "required_capacity_fraction_source_counts",
             "required_capacity_fraction_contact_ids_by_source",
             "contact_ids_by_ground_station_id",
             "contact_ids_by_direction",
             "contact_ids_by_direction_and_ground_station_id",
             "capacity_pack_contact_ids_by_ground_station_id",
             "capacity_pack_contact_ids_by_direction",
             "capacity_pack_contact_ids_by_direction_and_ground_station_id",
             "ground_station_ids",
             "directions",
             "direction_counts",
             "direction_routing"
           ]

    assert :contact_intent_summary_row_derived_counts in summary_row_semantics
    assert :contact_intent_summary_station_routing in summary_row_semantics
    assert :contact_intent_summary_direction_routing in summary_row_semantics
    assert :contact_intent_summary_capacity_pack_routing in summary_row_semantics
    assert :contact_intent_summary_required_capacity_source_routing in summary_row_semantics

    assert :activity_stable_identity_fields in row_semantics
    assert :station_calendar_id_list_fields in row_semantics
    assert :station_reservation_context in row_semantics
    assert :station_reservation_match_status in row_semantics
    assert :station_availability_precedence in row_semantics
    assert :station_calendar_overlap_count in row_semantics
    assert :station_calendar_ambiguous_entry_count in row_semantics
    assert :station_calendar_reservation_overlap_count in row_semantics
    assert :station_calendar_counts_derive_from_id_sets in row_semantics
    assert :station_calendar_overlap_id_sets in row_semantics
    assert :station_calendar_reservation_id_sets in row_semantics
    assert :station_calendar_reservation_statuses in row_semantics
    assert :station_calendar_reservation_expiration_context in row_semantics
    assert :station_reservation_expiration_aliases in row_semantics
    assert :station_calendar_reservation_expiration_aliases in row_semantics
    assert :station_calendar_trust_evidence_preservation in row_semantics
    assert :station_calendar_entry_identity_preservation in row_semantics
    assert :station_capacity_value_paths in row_semantics
    assert :required_capacity_value_paths in row_semantics
    assert :source_station_capacity_value_paths in row_semantics
    assert :capacity_pack_required_capacity_summary in row_semantics
    assert :contact_intent_summary_routing_fields in row_semantics
    assert :station_calendar_direction_context in row_semantics
    assert :station_calendar_direction_aliases in row_semantics
    assert :provider_direction_aliases in row_semantics
    assert :provider_result_map_value_keys in row_semantics
    assert :spacecraft_identity_context in row_semantics
    assert :invalid_activity_input_review in row_semantics
    assert :feedback_unit_interval_input_validation in row_semantics
    assert :no_link_budget_model in known_limits
    assert :no_provider_reservation in known_limits
    assert :no_command_execution in known_limits
  end

  test "builds contact intent rows from downlink candidates" do
    [intent] =
      ContactIntent.from_activities([
        %{
          "id" => "dl_1",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 10.0,
          "ends_at_s" => 70.0,
          "estimated_throughput_mb" => 120.0,
          "source_window_id" => "window_1",
          "cadence_import" => %{"external_id" => "dl_1", "activity_type" => "contact"}
        }
      ])

    assert intent["schema_contract"] == "contact_intent.v1"
    assert intent["direction"] == "downlink"
    assert intent["estimated_throughput_mb"] == 120.0
    assert intent["schedule_conflict_status"] == "not_evaluated"
    assert intent["timeline_id"] == "timeline:leo_1:downlink:equator_prime:window_1"

    expected_model_limits =
      ContactIntent.capabilities()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&to_string/1)
      |> Enum.sort()

    assert intent["model_limits"] == expected_model_limits

    assert "no_link_budget_model" in intent["model_limits"]
    assert "no_provider_reservation" in intent["model_limits"]
    assert "no_schedule_mutation" in intent["model_limits"]

    assert {:ok, schema} = Schema.json_schema("contact_intent.v1")

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             expected_model_limits

    assert get_in(schema, ["properties", "timeline_integrity_issue_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    invalid_model_limits = Map.put(intent, "model_limits", ["no_schedule_mutation"])

    assert {:error, validation_report} = Schema.validate_artifact(invalid_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] =~ "must match contact intent model limits")
           )

    assert intent["timeline_identity"] == %{
             "activity_id" => "dl_1",
             "activity_type" => "downlink",
             "scenario_id" => "leo_1",
             "source_window_id" => "window_1",
             "subject_id" => "equator_prime",
             "timeline_id" => "timeline:leo_1:downlink:equator_prime:window_1"
           }
  end

  test "preserves dependency and timeline integrity context on contact intents" do
    [intent] =
      ContactIntent.from_activities(
        [
          %{
            id: :health_gate,
            type: :health_check,
            scenario_id: :leo_1,
            starts_at_s: 35.0,
            ends_at_s: 45.0,
            approval_status: :approved
          },
          %{
            id: :cmd_1,
            type: :command,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 30.0,
            ends_at_s: 40.0,
            dependencies: [:health_gate, :missing_gate],
            exclusive_with: [:dl_conflict]
          },
          %{
            id: :dl_conflict,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 32.0,
            ends_at_s: 38.0
          }
        ],
        validate_missing_dependencies?: true
      )

    assert %{
             "id" => "cmd_1",
             "direction" => "command",
             "dependency_activity_ids" => ["health_gate", "missing_gate"],
             "exclusive_with_activity_ids" => ["dl_conflict"],
             "timeline_integrity_status" => "review_required",
             "missing_dependency_activity_ids" => ["missing_gate"],
             "dependency_order_violation_activity_ids" => ["health_gate"],
             "exclusivity_violation_activity_ids" => ["dl_conflict"],
             "activity_context" => %{
               "dependency_activity_ids" => ["health_gate", "missing_gate"],
               "exclusive_with_activity_ids" => ["dl_conflict"],
               "timeline_identity" => %{"activity_id" => "cmd_1"}
             }
           } = intent

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(intent)

    fractional_count = Map.put(intent, "timeline_integrity_issue_count", 1.5)

    assert {:error, fractional_count_report} = Schema.validate_artifact(fractional_count)

    assert Enum.any?(
             fractional_count_report["errors"],
             &(&1["path"] == "$.timeline_integrity_issue_count" and
                 &1["message"] == "must be a non-negative integer")
           )

    negative_count = Map.put(intent, "timeline_integrity_issue_count", -1)

    assert {:error, negative_count_report} = Schema.validate_artifact(negative_count)

    assert Enum.any?(
             negative_count_report["errors"],
             &(&1["path"] == "$.timeline_integrity_issue_count" and
                 &1["message"] == "must be a non-negative integer")
           )

    unknown_issue_type = Map.put(intent, "timeline_integrity_issue_types", ["provider_custom"])

    assert {:error, unknown_issue_type_report} = Schema.validate_artifact(unknown_issue_type)

    assert Enum.any?(
             unknown_issue_type_report["errors"],
             &(&1["path"] == "$.timeline_integrity_issue_types[0]" and
                 &1["message"] =~ "must be one of")
           )
  end

  test "preserves malformed contact intent activity inputs for review" do
    intents =
      ContactIntent.from_activities(
        [
          %{
            type: :command,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 20.0
          },
          %{
            id: :uplink_missing_type,
            scenario_id: :leo_1,
            station_id: :dss_43,
            direction: :uplink,
            start_s: 30.0,
            end_s: 40.0
          },
          "not a contact intent"
        ],
        approval_policy: %{bundle: "contact_command_review_v1"}
      )

    assert Enum.map(intents, & &1["id"]) == ["missing_activity_id:1", "uplink_missing_type"]

    [command, uplink] = intents

    assert %{
             "schema_contract" => "contact_intent.v1",
             "id" => "missing_activity_id:1",
             "activity_id" => "missing_activity_id:1",
             "activity_type" => "command",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 10.0,
             "ends_at_s" => 20.0,
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "source_activity" => %{"type" => "command"},
             "approval_status" => "operator_review_required",
             "approval_requirements" => [
               %{
                 "action" => "review_invalid_activity_input",
                 "requirement_type" => "operator_review",
                 "policy_classification" => "operator_review_required",
                 "activity_context" => %{
                   "invalid_activity_input" => true,
                   "invalid_activity_input_reason" => "missing_activity_id"
                 }
               }
             ],
             "approval_rule_matches" => [
               %{
                 "rule_id" => "invalid_contact_intent_input_review",
                 "classification" => "operator_review_required"
               }
             ],
             "policy_decision" => %{"policy_bundle_id" => "contact_command_review_v1"}
           } = command

    assert %{
             "id" => "uplink_missing_type",
             "activity_type" => "planned_contact",
             "direction" => "uplink",
             "ground_station_id" => "dss_43",
             "starts_at_s" => 30.0,
             "ends_at_s" => 40.0,
             "approval_status" => "operator_review_required",
             "approval_requirements" => [
               %{
                 "action" => "review_command_contact",
                 "requirement_type" => "command_review",
                 "activity_context" => %{
                   "direction" => "uplink",
                   "ground_station_id" => "dss_43"
                 }
               }
             ]
           } = uplink

    refute Map.get(uplink, "invalid_activity_input")

    review = OperatorReview.from_contact_intent(command)
    import = CadenceImport.from_contact_intent(command)

    assert [
             %{
               "required_operator_action" => "review_invalid_activity_input",
               "invalid_activity_input" => true,
               "invalid_activity_input_reason" => "missing_activity_id",
               "approval_rule_matches" => [
                 %{"rule_id" => "invalid_contact_intent_input_review"}
               ],
               "source_policy_decision" => %{"policy_bundle_id" => "contact_command_review_v1"},
               "source_activity" => %{"type" => "command"},
               "source_contact_intent" => %{
                 "id" => "missing_activity_id:1",
                 "invalid_activity_input" => true
               }
             }
           ] = review["rows"]

    assert [
             %{
               "source_review_action" => "review_invalid_activity_input",
               "invalid_activity_input" => true,
               "invalid_activity_input_reason" => "missing_activity_id",
               "approval_rule_matches" => [
                 %{"rule_id" => "invalid_contact_intent_input_review"}
               ],
               "source_policy_decision" => %{"policy_bundle_id" => "contact_command_review_v1"},
               "source_activity" => %{"type" => "command"},
               "source_contact_intent" => %{
                 "id" => "missing_activity_id:1",
                 "invalid_activity_input" => true
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(command)

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(uplink)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "preserves malformed contact intent stable identity fields for review" do
    intents =
      ContactIntent.from_activities([
        %{
          id: "bad activity id",
          type: :command,
          scenario_id: :leo_1,
          ground_station_id: :equator_prime,
          starts_at_s: 10.0,
          ends_at_s: 20.0
        },
        %{
          id: :bad_station,
          type: :command,
          scenario_id: :leo_1,
          ground_station_id: "bad station id",
          starts_at_s: 30.0,
          ends_at_s: 40.0
        },
        %{
          id: :bad_scenario,
          type: :tracking,
          scenario_id: "bad scenario id",
          ground_station_id: :equator_prime,
          starts_at_s: 50.0,
          ends_at_s: 60.0
        },
        %{
          id: :bad_source_window,
          type: :downlink,
          scenario_id: :leo_1,
          ground_station_id: :equator_prime,
          source_window_id: "bad source window",
          station_calendar_overlap_entry_ids: [
            :overlap_1,
            "bad overlap id",
            %{id: :overlap_2},
            %{id: "bad nested overlap id"}
          ],
          starts_at_s: 70.0,
          ends_at_s: 80.0
        }
      ])

    assert Enum.map(intents, & &1["invalid_activity_input_reason"]) == [
             "invalid_activity_id",
             "invalid_ground_station_id",
             "invalid_source_window_id",
             "invalid_scenario_id"
           ]

    bad_id = Enum.find(intents, &(&1["invalid_activity_input_reason"] == "invalid_activity_id"))

    assert %{
             "id" => "invalid_activity_id:1",
             "activity_id" => "invalid_activity_id:1",
             "ground_station_id" => "equator_prime",
             "scenario_id" => "leo_1",
             "source_activity" => %{"id" => "bad activity id"},
             "cadence_import" => %{"external_id" => "invalid_activity_id:1"}
           } = bad_id

    bad_station =
      Enum.find(intents, &(&1["invalid_activity_input_reason"] == "invalid_ground_station_id"))

    assert %{
             "id" => "bad_station",
             "ground_station_id" => "missing_ground_station_id:bad_station",
             "source_activity" => %{"ground_station_id" => "bad station id"}
           } = bad_station

    bad_source_window =
      Enum.find(intents, &(&1["invalid_activity_input_reason"] == "invalid_source_window_id"))

    assert %{
             "id" => "bad_source_window",
             "source_activity" => %{"source_window_id" => "bad source window"}
           } = bad_source_window

    refute Map.has_key?(bad_source_window, "source_window_id")
    assert bad_source_window["station_calendar_overlap_entry_ids"] == ["overlap_1", "overlap_2"]

    bad_scenario =
      Enum.find(intents, &(&1["invalid_activity_input_reason"] == "invalid_scenario_id"))

    assert %{
             "id" => "bad_scenario",
             "scenario_id" => "missing_scenario_id:bad_scenario",
             "source_activity" => %{"scenario_id" => "bad scenario id"}
           } = bad_scenario

    assert Enum.all?(intents, fn intent ->
             match?(
               {:ok, %{"schema_contract" => "contact_intent.v1"}},
               Schema.validate_artifact(intent)
             )
           end)

    direct =
      ContactIntent.from_activity!(%{
        id: "bad direct id",
        type: :command,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 90.0,
        ends_at_s: 100.0
      })

    assert %{
             "id" => "invalid_activity_id:1",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "invalid_activity_id",
             "source_activity" => %{"id" => "bad direct id"}
           } = direct

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(direct)
  end

  test "preserves station reservation context through contact intent handoff rows" do
    reservation_context = %{
      "station_availability" => "reserved",
      "station_contention_status" => "reserved_overlap",
      "station_reservation_id" => "reservation_1",
      "station_reservation_expires_at_s" => 420.0,
      "station_calendar_reservation_expires_at_s" => [420.0],
      "station_reserved_by" => "mission_ops",
      "station_reservation_status" => "held",
      "station_reservation_match_status" => "matched"
    }

    [intent] =
      ContactIntent.from_activities(
        [
          %{
            id: :contact_1,
            type: :planned_contact,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 70.0,
            station_availability: :reserved,
            station_contention_status: :reserved_overlap,
            station_reservation_id: :reservation_1,
            station_reservation_expires_at_s: "420.0",
            station_reserved_by: :mission_ops,
            station_reservation_status: :held,
            station_reservation_match_status: :matched
          }
        ],
        approval_policy: %{bundle: "contact_command_review_v1"}
      )

    reservation_keys = Map.keys(reservation_context)

    assert Map.take(intent, reservation_keys) == reservation_context
    assert Map.take(intent["activity_context"], reservation_keys) == reservation_context

    assert [
             %{
               "activity_context" => activity_context
             }
           ] = intent["approval_requirements"]

    assert Map.take(activity_context, reservation_keys) == reservation_context

    review_package = OperatorReview.from_contact_intent(intent)
    [review_row] = review_package["rows"]

    assert Map.take(review_row, reservation_keys) == reservation_context
    assert Map.take(review_row["activity_context"], reservation_keys) == reservation_context

    import_manifest = CadenceImport.from_contact_intent(intent)
    [import_row] = import_manifest["rows"]

    assert Map.take(import_row, reservation_keys) == reservation_context

    assert Map.take(import_row["import_activity_context"], reservation_keys) ==
             reservation_context

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(intent)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review_package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import_manifest)
  end

  test "preserves station calendar trust evidence through contact intent handoff rows" do
    station_calendar_context = %{
      "station_calendar_entry_id" => "station_reduced_capacity",
      "station_calendar_directions" => ["downlink"],
      "station_calendar_status" => "available",
      "capacity_fraction" => 0.4,
      "capacity_fraction_min" => 0.4,
      "capacity_fraction_max" => 0.8,
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
        "station_calendar_directions" => ["downlink"],
        "reservation_expires_at_s" => "420.0",
        "capacity_model" => %{"station_capacity_percent" => "60"},
        "provenance" => %{"trust_boundary" => "ground_partner_api"}
      },
      "source_station_calendar_overlaps" => [
        %{"id" => "station_reduced_capacity", "expires_at" => "540.0"}
      ]
    }

    reservation_expiration_context = %{
      "station_reservation_expires_at_s" => 420.0,
      "station_calendar_reservation_expires_at_s" => [420.0, 540.0]
    }

    [intent] =
      ContactIntent.from_activities(
        [
          Map.merge(
            %{
              id: :contact_1,
              type: :planned_contact,
              direction: :downlink,
              scenario_id: :leo_1,
              ground_station_id: :equator_prime,
              starts_at_s: 10.0,
              ends_at_s: 70.0,
              station_availability: :reduced_capacity,
              capacity_percent: "40",
              station_capacity_fraction: "0.8"
            },
            station_calendar_context
          )
        ],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert Map.take(intent, Map.keys(station_calendar_context)) == station_calendar_context

    assert Map.take(intent, Map.keys(reservation_expiration_context)) ==
             reservation_expiration_context

    assert [
             %{
               "activity_context" => activity_context
             }
           ] = intent["approval_requirements"]

    assert Map.take(activity_context, Map.keys(station_calendar_context)) ==
             station_calendar_context

    assert Map.take(activity_context, Map.keys(reservation_expiration_context)) ==
             reservation_expiration_context

    review_package = OperatorReview.from_contact_intent(intent)
    [review_row] = review_package["rows"]

    assert Map.take(review_row, Map.keys(station_calendar_context)) == station_calendar_context

    assert Map.take(review_row, Map.keys(reservation_expiration_context)) ==
             reservation_expiration_context

    import_manifest = CadenceImport.from_contact_intent(intent)
    [import_row] = import_manifest["rows"]

    assert Map.take(import_row, Map.keys(station_calendar_context)) == station_calendar_context

    assert Map.take(import_row, Map.keys(reservation_expiration_context)) ==
             reservation_expiration_context

    assert Map.take(
             import_row["import_activity_context"],
             Map.keys(reservation_expiration_context)
           ) ==
             reservation_expiration_context

    assert Map.take(import_row["import_activity_context"], [
             "capacity_fraction",
             "capacity_fraction_min",
             "capacity_fraction_max"
           ]) == %{
             "capacity_fraction" => 0.4,
             "capacity_fraction_min" => 0.4,
             "capacity_fraction_max" => 0.8
           }

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(intent)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review_package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import_manifest)
  end

  test "derives station capacity context from numeric availability and source capacity-pack evidence" do
    [intent] =
      ContactIntent.from_activities(
        [
          %{
            id: :source_capacity_pack_contact,
            type: :planned_contact,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 70.0,
            availability: "0.25",
            source_station_calendar_entry: %{
              id: :provider_reduced_capacity,
              availability: 0.4,
              capacity_pack_capacity_fraction: "0.5"
            },
            source_station_calendar_overlaps: [
              %{
                id: :provider_overlap_reduced_capacity,
                capacity_model: %{"availability" => "0.75"},
                capacity_pack_capacity_fraction: "0.6"
              }
            ]
          }
        ],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "capacity_fraction" => 0.25,
             "capacity_fraction_min" => 0.25,
             "capacity_fraction_max" => 0.75,
             "station_availability" => "not_evaluated",
             "source_station_calendar_entry" => %{
               "availability" => 0.4,
               "capacity_pack_capacity_fraction" => "0.5"
             },
             "source_station_calendar_overlaps" => [
               %{
                 "capacity_model" => %{"availability" => "0.75"},
                 "capacity_pack_capacity_fraction" => "0.6"
               }
             ],
             "activity_context" => %{
               "capacity_fraction" => 0.25,
               "capacity_fraction_min" => 0.25,
               "capacity_fraction_max" => 0.75
             }
           } = intent

    review_package = OperatorReview.from_contact_intent(intent)
    [review_row] = review_package["rows"]

    assert Map.take(review_row, [
             "capacity_fraction",
             "capacity_fraction_min",
             "capacity_fraction_max"
           ]) == %{
             "capacity_fraction" => 0.25,
             "capacity_fraction_min" => 0.25,
             "capacity_fraction_max" => 0.75
           }

    import_manifest = CadenceImport.from_contact_intent(intent)
    [import_row] = import_manifest["rows"]

    assert Map.take(import_row["import_activity_context"], [
             "capacity_fraction",
             "capacity_fraction_min",
             "capacity_fraction_max"
           ]) == %{
             "capacity_fraction" => 0.25,
             "capacity_fraction_min" => 0.25,
             "capacity_fraction_max" => 0.75
           }

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(intent)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review_package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import_manifest)
  end

  test "summarizes required capacity-pack demand from contact intent rows" do
    activities = [
      %{
        id: :direct_capacity_contact,
        type: :planned_contact,
        direction: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 10.0,
        ends_at_s: 70.0,
        required_capacity_fraction: "0.25"
      },
      %{
        id: :throughput_capacity_contact,
        type: :planned_contact,
        direction: :command,
        scenario_id: :leo_1,
        ground_station_id: :dss_43,
        starts_at_s: 80.0,
        ends_at_s: 120.0,
        throughput_model: %{required_station_capacity_percent: "50"}
      },
      %{
        id: :capacity_model_contact,
        type: :planned_contact,
        direction: :tracking,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 130.0,
        ends_at_s: 170.0,
        capacity_model: %{station_capacity_requirement: 0.2}
      }
    ]

    opts = [approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}]

    intents = ContactIntent.from_activities(activities, opts)

    assert Enum.map(intents, & &1["required_capacity_fraction"]) == [0.25, 0.5, 0.2]

    assert Enum.map(intents, & &1["required_capacity_fraction_source"]) == [
             "contact_required_capacity_fraction",
             "throughput_model",
             "capacity_model"
           ]

    [direct | _rest] = intents

    assert get_in(direct, ["activity_context", "required_capacity_fraction"]) == 0.25

    assert get_in(direct, [
             "approval_requirements",
             Access.at(0),
             "activity_context",
             "required_capacity_fraction"
           ]) == 0.25

    review_package = OperatorReview.from_contact_intent(direct)
    [review_row] = review_package["rows"]

    assert Map.take(review_row, [
             "required_capacity_fraction",
             "required_capacity_fraction_source"
           ]) == %{
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "contact_required_capacity_fraction"
           }

    import_manifest = CadenceImport.from_contact_intent(direct)
    [import_row] = import_manifest["rows"]

    assert Map.take(import_row, [
             "required_capacity_fraction",
             "required_capacity_fraction_source"
           ]) == %{
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "contact_required_capacity_fraction"
           }

    stale_rows =
      Enum.map(intents, fn intent ->
        Map.put(intent, "capacity_pack_required_capacity_fraction", 99.0)
      end)

    summary = ContactIntent.summary(stale_rows)
    capabilities = ContactIntent.capabilities()

    station_capacity_value_paths =
      json_capacity_value_paths(capabilities.station_capacity_value_paths)

    required_capacity_value_paths =
      json_capacity_value_paths(capabilities.required_capacity_value_paths)

    required_capacity_fraction_source_values =
      capabilities.required_capacity_fraction_source_values

    assert summary == %{
             "schema_contract" => "contact_intent_summary.v1",
             "model" => "artifact_only_contact_intent_summary",
             "model_limits" =>
               ContactIntent.capabilities().known_limits
               |> Enum.map(&Atom.to_string/1)
               |> Enum.sort(),
             "source_artifact_type" => "contact_intent.v1",
             "contact_intent_count" => 3,
             "capacity_pack_required_contact_count" => 3,
             "capacity_pack_required_capacity_fraction" => 0.95,
             "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
               "dss_43" => 0.5,
               "equator_prime" => 0.45
             },
             "capacity_pack_required_capacity_fraction_by_direction" => %{
               "command" => 0.5,
               "downlink" => 0.25,
               "tracking" => 0.2
             },
             "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id" => %{
               "command" => %{"dss_43" => 0.5},
               "downlink" => %{"equator_prime" => 0.25},
               "tracking" => %{"equator_prime" => 0.2}
             },
             "required_capacity_fraction_source_counts" => %{
               "capacity_model" => 1,
               "contact_required_capacity_fraction" => 1,
               "throughput_model" => 1
             },
             "required_capacity_fraction_contact_ids_by_source" => %{
               "capacity_model" => ["capacity_model_contact"],
               "contact_required_capacity_fraction" => ["direct_capacity_contact"],
               "throughput_model" => ["throughput_capacity_contact"]
             },
             "contact_ids_by_ground_station_id" => %{
               "dss_43" => ["throughput_capacity_contact"],
               "equator_prime" => ["capacity_model_contact", "direct_capacity_contact"]
             },
             "contact_ids_by_direction" => %{
               "command" => ["throughput_capacity_contact"],
               "downlink" => ["direct_capacity_contact"],
               "tracking" => ["capacity_model_contact"]
             },
             "contact_ids_by_direction_and_ground_station_id" => %{
               "command" => %{"dss_43" => ["throughput_capacity_contact"]},
               "downlink" => %{"equator_prime" => ["direct_capacity_contact"]},
               "tracking" => %{"equator_prime" => ["capacity_model_contact"]}
             },
             "capacity_pack_contact_ids_by_ground_station_id" => %{
               "dss_43" => ["throughput_capacity_contact"],
               "equator_prime" => ["capacity_model_contact", "direct_capacity_contact"]
             },
             "capacity_pack_contact_ids_by_direction" => %{
               "command" => ["throughput_capacity_contact"],
               "downlink" => ["direct_capacity_contact"],
               "tracking" => ["capacity_model_contact"]
             },
             "capacity_pack_contact_ids_by_direction_and_ground_station_id" => %{
               "command" => %{"dss_43" => ["throughput_capacity_contact"]},
               "downlink" => %{"equator_prime" => ["direct_capacity_contact"]},
               "tracking" => %{"equator_prime" => ["capacity_model_contact"]}
             },
             "ground_station_ids" => ["dss_43", "equator_prime"],
             "directions" => ["command", "downlink", "tracking"],
             "direction_counts" => %{
               "command" => 1,
               "downlink" => 1,
               "tracking" => 1
             },
             "direction_routing" => %{
               "command" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["throughput_capacity_contact"],
                 "capacity_pack_required_capacity_fraction" => 0.5,
                 "capacity_pack_contact_ids" => ["throughput_capacity_contact"],
                 "ground_station_ids" => ["dss_43"],
                 "contact_ids_by_ground_station_id" => %{
                   "dss_43" => ["throughput_capacity_contact"]
                 },
                 "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
                   "dss_43" => 0.5
                 },
                 "capacity_pack_contact_ids_by_ground_station_id" => %{
                   "dss_43" => ["throughput_capacity_contact"]
                 }
               },
               "downlink" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["direct_capacity_contact"],
                 "capacity_pack_required_capacity_fraction" => 0.25,
                 "capacity_pack_contact_ids" => ["direct_capacity_contact"],
                 "ground_station_ids" => ["equator_prime"],
                 "contact_ids_by_ground_station_id" => %{
                   "equator_prime" => ["direct_capacity_contact"]
                 },
                 "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
                   "equator_prime" => 0.25
                 },
                 "capacity_pack_contact_ids_by_ground_station_id" => %{
                   "equator_prime" => ["direct_capacity_contact"]
                 }
               },
               "tracking" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["capacity_model_contact"],
                 "capacity_pack_required_capacity_fraction" => 0.2,
                 "capacity_pack_contact_ids" => ["capacity_model_contact"],
                 "ground_station_ids" => ["equator_prime"],
                 "contact_ids_by_ground_station_id" => %{
                   "equator_prime" => ["capacity_model_contact"]
                 },
                 "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
                   "equator_prime" => 0.2
                 },
                 "capacity_pack_contact_ids_by_ground_station_id" => %{
                   "equator_prime" => ["capacity_model_contact"]
                 }
               }
             },
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "required_capacity_fraction_source_values" =>
                 required_capacity_fraction_source_values,
               "required_capacity_value_paths" => required_capacity_value_paths,
               "station_capacity_value_paths" => station_capacity_value_paths,
               "source_artifact_type" => "contact_intent.v1"
             }
           }

    assert ContactIntent.capabilities().summary_routing_fields -- Map.keys(summary) == []

    assert OrbitalDynamics.contact_intent_summary(stale_rows) == summary
    assert OrbitalDynamics.contact_intent_summary(activities, opts) == summary

    assert {:ok, %{"schema_contract" => "contact_intent_summary.v1"}} =
             Schema.validate_artifact(summary)

    non_capacity_summary =
      ContactIntent.summary([
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "command_without_capacity",
          "activity_id" => "command_without_capacity",
          "ground_station_id" => "dss_43",
          "direction" => "command"
        }
      ])

    assert get_in(non_capacity_summary, [
             "direction_routing",
             "command",
             "capacity_pack_contact_ids"
           ]) == []

    assert {:ok, %{"schema_contract" => "contact_intent_summary.v1"}} =
             Schema.validate_artifact(non_capacity_summary)

    empty_summary = ContactIntent.summary([])

    assert Map.take(empty_summary, [
             "contact_intent_count",
             "capacity_pack_required_contact_count",
             "direction_counts",
             "direction_routing",
             "directions"
           ]) == %{
             "contact_intent_count" => 0,
             "capacity_pack_required_contact_count" => 0,
             "direction_counts" => %{},
             "direction_routing" => %{},
             "directions" => []
           }

    assert {:ok, %{"schema_contract" => "contact_intent_summary.v1"}} =
             Schema.validate_artifact(empty_summary)

    stale_empty_direction_counts =
      Map.put(empty_summary, "direction_counts", %{"downlink" => 1})

    assert {:error, stale_empty_direction_counts_validation} =
             Schema.validate_artifact(stale_empty_direction_counts)

    assert Enum.any?(
             stale_empty_direction_counts_validation["errors"],
             &(&1["path"] == "$.direction_counts" and
                 &1["message"] == "must equal contact_ids_by_direction counts")
           )

    assert {:ok, summary_schema} = Schema.json_schema("contact_intent_summary.v1")

    assert get_in(summary_schema, ["properties", "model", "const"]) ==
             "artifact_only_contact_intent_summary"

    assert get_in(summary_schema, ["properties", "source_artifact_type", "const"]) ==
             "contact_intent.v1"

    assert get_in(summary_schema, ["properties", "model_limits", "const"]) ==
             summary["model_limits"]

    assert get_in(summary_schema, ["properties", "model_limits", "items", "enum"]) ==
             summary["model_limits"]

    assert get_in(summary_schema, [
             "properties",
             "assumptions",
             "properties",
             "station_capacity_value_paths",
             "const"
           ]) == station_capacity_value_paths

    assert get_in(summary_schema, [
             "properties",
             "assumptions",
             "properties",
             "required_capacity_value_paths",
             "const"
           ]) == required_capacity_value_paths

    assert get_in(summary_schema, [
             "properties",
             "assumptions",
             "properties",
             "required_capacity_fraction_source_values",
             "const"
           ]) == required_capacity_fraction_source_values

    assert get_in(summary_schema, ["properties", "direction_routing", "type"]) == "object"

    stale_model_summary = Map.put(summary, "model", "stale_contact_intent_summary")

    assert {:error, stale_model_summary_validation} =
             Schema.validate_artifact(stale_model_summary)

    assert Enum.any?(
             stale_model_summary_validation["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"artifact_only_contact_intent_summary\"")
           )

    stale_model_limits_summary = Map.put(summary, "model_limits", ["artifact_level_only"])

    assert {:error, stale_model_limits_validation} =
             Schema.validate_artifact(stale_model_limits_summary)

    assert Enum.any?(
             stale_model_limits_validation["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match contact intent model limits")
           )

    stale_source_summary = Map.put(summary, "source_artifact_type", "contact_intent.v2")

    assert {:error, stale_source_summary_validation} =
             Schema.validate_artifact(stale_source_summary)

    assert Enum.any?(
             stale_source_summary_validation["errors"],
             &(&1["path"] == "$.source_artifact_type" and
                 &1["message"] == "must equal \"contact_intent.v1\"")
           )

    stale_required_capacity_paths =
      put_in(
        summary,
        ["assumptions", "required_capacity_value_paths"],
        [%{"unit" => "fraction", "path" => ["legacy_capacity_fraction"]}]
      )

    assert {:error, stale_required_capacity_paths_validation} =
             Schema.validate_artifact(stale_required_capacity_paths)

    assert Enum.any?(
             stale_required_capacity_paths_validation["errors"],
             &(&1["path"] == "$.assumptions.required_capacity_value_paths" and
                 &1["message"] == "must match ContactIntent required capacity value paths")
           )

    stale_station_capacity_paths =
      put_in(
        summary,
        ["assumptions", "station_capacity_value_paths"],
        [%{"unit" => "fraction", "path" => ["legacy_station_capacity"]}]
      )

    assert {:error, stale_station_capacity_paths_validation} =
             Schema.validate_artifact(stale_station_capacity_paths)

    assert Enum.any?(
             stale_station_capacity_paths_validation["errors"],
             &(&1["path"] == "$.assumptions.station_capacity_value_paths" and
                 &1["message"] == "must match ContactIntent station capacity value paths")
           )

    stale_required_capacity_sources =
      put_in(
        summary,
        ["assumptions", "required_capacity_fraction_source_values"],
        ["legacy_required_capacity_source"]
      )

    assert {:error, stale_required_capacity_sources_validation} =
             Schema.validate_artifact(stale_required_capacity_sources)

    assert Enum.any?(
             stale_required_capacity_sources_validation["errors"],
             &(&1["path"] == "$.assumptions.required_capacity_fraction_source_values" and
                 &1["message"] ==
                   "must match ContactIntent required capacity fraction source values")
           )

    stale_summary = Map.put(summary, "capacity_pack_required_capacity_fraction", 99.0)

    assert {:error, stale_summary_validation} = Schema.validate_artifact(stale_summary)

    assert Enum.any?(
             stale_summary_validation["errors"],
             &(&1["path"] == "$.capacity_pack_required_capacity_fraction" and
                 &1["message"] ==
                   "must equal capacity_pack_required_capacity_fraction_by_ground_station_id total")
           )

    stale_direction_ids = Map.put(summary, "contact_ids_by_direction", %{"downlink" => []})

    assert {:error, stale_direction_ids_validation} =
             Schema.validate_artifact(stale_direction_ids)

    assert Enum.any?(
             stale_direction_ids_validation["errors"],
             &(&1["path"] == "$.contact_intent_count" and
                 &1["message"] == "must equal contact_ids_by_direction total")
           )

    stale_direction_counts = Map.put(summary, "direction_counts", %{"downlink" => 99})

    assert {:error, stale_direction_counts_validation} =
             Schema.validate_artifact(stale_direction_counts)

    assert Enum.any?(
             stale_direction_counts_validation["errors"],
             &(&1["path"] == "$.direction_counts" and
                 &1["message"] == "must equal contact_ids_by_direction counts")
           )

    stale_direction_routing =
      put_in(summary, ["direction_routing", "downlink", "contact_count"], 99)

    assert {:error, stale_direction_routing_validation} =
             Schema.validate_artifact(stale_direction_routing)

    assert Enum.any?(
             stale_direction_routing_validation["errors"],
             &(&1["path"] == "$.direction_routing" and
                 &1["message"] == "must equal row-derived direction routing")
           )

    assert ContactIntent.summary(summary) == summary
    assert OrbitalDynamics.contact_intent_summary(summary) == summary

    atom_keyed_summary =
      Map.new(summary, fn {key, value} -> {String.to_atom(key), value} end)

    assert ContactIntent.summary(atom_keyed_summary) == summary
    assert OrbitalDynamics.contact_intent_summary(atom_keyed_summary) == summary

    assert Enum.all?(intents, fn intent ->
             {:ok, %{"schema_contract" => "contact_intent.v1"}} =
               Schema.validate_artifact(intent)
           end)
  end

  test "derives station availability from direct station calendar status before policy handoff" do
    [direct, nested] =
      ContactIntent.from_activities(
        [
          %{
            id: :direct_station_outage,
            type: :planned_contact,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 70.0,
            station_availability: :available,
            station_calendar_status: "Offline",
            station_calendar_provider_id: :ground_partner_a,
            station_calendar_provider_entry_id: :provider_outage_1,
            source_station_calendar_entry: %{
              id: :provider_outage_1,
              availability: "Offline"
            }
          },
          %{
            id: :nested_station_maintenance,
            type: :planned_contact,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 80.0,
            ends_at_s: 140.0,
            station_calendar_status: :available,
            source_station_calendar_entry: %{
              id: :provider_window_2,
              station_calendar_status: :available
            },
            source_station_calendar_overlaps: [
              %{id: :provider_maintenance_2, availability: "Maintenance"}
            ]
          }
        ],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "station_availability" => "unavailable",
             "station_calendar_status" => "unavailable",
             "source_station_calendar_entry" => %{
               "id" => "provider_outage_1",
               "availability" => "unavailable"
             },
             "activity_context" => %{"station_availability" => "unavailable"},
             "approval_status" => "blocked_by_policy",
             "approval_rule_matches" => [
               %{"rule_id" => "unavailable_station_contact_block"}
             ]
           } = direct

    assert get_in(direct, ["approval_requirements", Access.at(0), "activity_context"])
           |> Map.take([
             "station_availability",
             "station_calendar_status",
             "station_calendar_provider_id",
             "station_calendar_provider_entry_id"
           ]) == %{
             "station_availability" => "unavailable",
             "station_calendar_status" => "unavailable",
             "station_calendar_provider_id" => "ground_partner_a",
             "station_calendar_provider_entry_id" => "provider_outage_1"
           }

    assert %{
             "station_availability" => "unavailable",
             "station_calendar_status" => "available",
             "source_station_calendar_overlaps" => [
               %{"id" => "provider_maintenance_2", "availability" => "maintenance"}
             ],
             "approval_status" => "blocked_by_policy"
           } = nested

    review_package = OperatorReview.from_contact_intent(direct)
    [review_row] = review_package["rows"]

    assert %{
             "station_availability" => "unavailable",
             "station_calendar_status" => "unavailable",
             "required_operator_action" => "review_contact_intent",
             "source_station_calendar_entry" => %{
               "id" => "provider_outage_1",
               "availability" => "unavailable"
             }
           } = review_row

    import_manifest = CadenceImport.from_contact_intent(direct)
    [import_row] = import_manifest["rows"]

    assert %{
             "station_availability" => "unavailable",
             "station_calendar_status" => "unavailable",
             "source_review_action" => "review_contact_intent",
             "source_station_calendar_entry" => %{
               "id" => "provider_outage_1",
               "availability" => "unavailable"
             }
           } = import_row

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(direct)

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(nested)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review_package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import_manifest)
  end

  test "flattens nested station calendar entry id through contact intent handoff rows" do
    [intent] =
      ContactIntent.from_activities(
        [
          %{
            id: :contact_nested_calendar_entry,
            type: :planned_contact,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 70.0,
            station_calendar_trust_boundary_status: :declared,
            trust_boundary: :ground_partner_api,
            source_station_calendar_entry: %{
              id: :provider_entry_only,
              provenance: %{trust_boundary: :ground_partner_api}
            },
            source_station_calendar_overlaps: [
              %{id: :provider_entry_only}
            ]
          }
        ],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "station_calendar_entry_id" => "provider_entry_only",
             "activity_context" => %{
               "station_calendar_entry_id" => "provider_entry_only",
               "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
             },
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "station_calendar_entry_id" => "provider_entry_only",
                   "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
                 }
               }
             ]
           } = intent

    review_package = OperatorReview.from_contact_intent(intent)
    [review_row] = review_package["rows"]

    assert %{
             "station_calendar_entry_id" => "provider_entry_only",
             "activity_context" => %{
               "station_calendar_entry_id" => "provider_entry_only",
               "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
             }
           } = review_row

    import_manifest = CadenceImport.from_contact_intent(intent)
    [import_row] = import_manifest["rows"]

    assert %{
             "station_calendar_entry_id" => "provider_entry_only",
             "import_activity_context" => %{
               "station_calendar_entry_id" => "provider_entry_only",
               "source_station_calendar_entry" => %{"id" => "provider_entry_only"}
             }
           } = import_row

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(intent)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review_package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import_manifest)
  end

  test "builds command and tracking contact intents from typed activities" do
    intents =
      ContactIntent.from_activities([
        %{
          id: :cmd_1,
          type: :command,
          scenario_id: :leo_1,
          ground_station_id: :equator_prime,
          start_s: 10.0,
          end_s: 20.0
        },
        %{
          id: :track_1,
          type: :tracking,
          scenario_id: :leo_1,
          ground_station_id: :equator_prime,
          start_s: 30.0,
          end_s: 40.0
        },
        %{
          id: :provider_sband_command,
          type: :planned_contact,
          direction: "s-band command",
          scenario_id: :leo_1,
          ground_station_id: :equator_prime,
          start_s: 45.0,
          end_s: 55.0,
          source_station_calendar_entry: %{
            id: :sband_calendar,
            directions: ["s_band_command"]
          }
        },
        %{
          id: :cmd_no_station,
          type: :command,
          scenario_id: :leo_1,
          start_s: 50.0,
          end_s: 60.0
        }
      ])

    assert Enum.map(intents, & &1["id"]) == ["cmd_1", "track_1", "provider_sband_command"]

    [command, tracking, provider_command] = intents
    assert command["direction"] == "command"
    assert command["starts_at_s"] == 10.0
    assert command["ends_at_s"] == 20.0
    assert command["timeline_id"] == "timeline:leo_1:command:equator_prime:10.0"
    assert command["cadence_import"] == %{"external_id" => "cmd_1", "activity_type" => "command"}

    assert tracking["direction"] == "tracking"

    assert tracking["cadence_import"] == %{
             "external_id" => "track_1",
             "activity_type" => "tracking"
           }

    assert %{
             "direction" => "command",
             "station_calendar_entry_id" => "sband_calendar",
             "station_calendar_directions" => ["command"]
           } = provider_command

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(command)
  end

  test "builds health-check contact intents from typed and provider-shaped activities" do
    intents =
      ContactIntent.from_activities(
        [
          %{
            id: :health_1,
            type: :health_check,
            scenario_id: :leo_1,
            spacecraft: %{id: :sat_1},
            ground_station_id: :equator_prime,
            start_s: "12.5",
            end_s: "22.5",
            command_success_factor: "0.72",
            command_success_factor_source: :health_check_adapter,
            source_window_id: :health_window_1,
            source_station_calendar_entry: %{
              id: :health_calendar_1,
              directions: [:healthcheck],
              provenance: %{provider_id: :ground_partner_a}
            }
          },
          %{
            id: :provider_health,
            type: :planned_contact,
            direction: "Health Check",
            scenario_id: :leo_1,
            station_id: :dss_43,
            start_s: "30.0",
            end_s: "40.0",
            source_window: %{id: :provider_health_window}
          }
        ],
        approval_policy: %{bundle: "contact_command_review_v1"}
      )

    assert Enum.map(intents, & &1["id"]) == ["health_1", "provider_health"]

    [typed_health, provider_health] = intents

    assert %{
             "schema_contract" => "contact_intent.v1",
             "activity_type" => "health_check",
             "direction" => "health_check",
             "spacecraft_id" => "sat_1",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 12.5,
             "ends_at_s" => 22.5,
             "command_success_factor" => 0.72,
             "command_success_factor_source" => "health_check_adapter",
             "source_window_id" => "health_window_1",
             "station_calendar_entry_id" => "health_calendar_1",
             "station_calendar_directions" => ["health_check"],
             "timeline_id" => "timeline:leo_1:health_check:equator_prime:health_window_1",
             "cadence_import" => %{
               "external_id" => "health_1",
               "activity_type" => "health_check"
             },
             "approval_requirements" => [
               %{
                 "activity_type" => "health_check",
                 "action" => "review_contact_intent",
                 "requirement_type" => "health_check_review",
                 "reason" => "health-check contact intents require command policy classification",
                 "activity_context" => %{
                   "direction" => "health_check",
                   "spacecraft_id" => "sat_1",
                   "ground_station_id" => "equator_prime",
                   "station_calendar_directions" => ["health_check"],
                   "command_success_factor" => 0.72,
                   "command_success_factor_source" => "health_check_adapter"
                 },
                 "policy_classification" => "operator_review_required"
               }
             ],
             "approval_rule_matches" => [
               %{
                 "rule_id" => "command_health_review",
                 "classification" => "operator_review_required"
               }
             ],
             "policy_decision" => %{"policy_bundle_id" => "contact_command_review_v1"}
           } = typed_health

    assert %{
             "activity_type" => "planned_contact",
             "direction" => "health_check",
             "ground_station_id" => "dss_43",
             "timeline_id" => "timeline:leo_1:planned_contact:dss_43:provider_health_window",
             "cadence_import" => %{
               "external_id" => "provider_health",
               "activity_type" => "health_check_contact"
             },
             "approval_requirements" => [
               %{
                 "activity_type" => "planned_contact",
                 "requirement_type" => "health_check_review",
                 "activity_context" => %{
                   "direction" => "health_check",
                   "ground_station_id" => "dss_43"
                 }
               }
             ],
             "approval_rule_matches" => [
               %{"rule_id" => "command_health_review"}
             ]
           } = provider_health

    review_package = OperatorReview.from_contact_intent(typed_health)
    [review_row] = review_package["rows"]

    assert %{
             "review_type" => "contact_intent_review",
             "activity_type" => "health_check",
             "direction" => "health_check",
             "required_operator_action" => "review_contact_intent",
             "requirement_type" => "health_check_review",
             "source_contact_intent" => %{"id" => "health_1", "direction" => "health_check"}
           } = review_row

    import_manifest = CadenceImport.from_contact_intent(typed_health)
    [import_row] = import_manifest["rows"]

    assert %{
             "import_action" => "review_contact_intent",
             "activity_type" => "health_check",
             "direction" => "health_check",
             "requirement_type" => "health_check_review",
             "source_contact_intent" => %{"id" => "health_1", "direction" => "health_check"}
           } = import_row

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(typed_health)

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(provider_health)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review_package)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import_manifest)
  end

  test "builds contact intents from station-id-only provider contacts" do
    [intent] =
      ContactIntent.from_activities(
        [
          %{
            id: :provider_contact,
            type: :contact,
            direction: :downlink,
            scenario_id: :leo_1,
            station_id: :equator_prime,
            start_s: 10.0,
            end_s: 70.0,
            estimated_throughput_mb: 120.0,
            source_window: %{id: :provider_window}
          }
        ],
        approval_policy: %{bundle: "contact_command_review_v1"}
      )

    assert %{
             "schema_contract" => "contact_intent.v1",
             "id" => "provider_contact",
             "activity_type" => "contact",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "starts_at_s" => 10.0,
             "ends_at_s" => 70.0,
             "source_window_id" => "provider_window",
             "timeline_id" => "timeline:leo_1:contact:equator_prime:provider_window",
             "cadence_import" => %{
               "external_id" => "provider_contact",
               "activity_type" => "contact"
             },
             "approval_requirements" => [
               %{
                 "activity_type" => "contact",
                 "activity_context" => %{
                   "direction" => "downlink",
                   "ground_station_id" => "equator_prime"
                 }
               }
             ]
           } = intent

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(intent)
  end

  test "builds contact intents from provider contacts with nested station identity" do
    intents =
      ContactIntent.from_activities(
        [
          %{
            id: :provider_nested_station,
            type: :contact,
            direction: :downlink,
            scenario_id: :leo_1,
            spacecraft: %{id: :sat_1},
            station: %{id: :equator_prime},
            start_s: 10.0,
            end_s: 70.0,
            estimated_throughput_mb: 120.0,
            source_window: %{id: :provider_window_a}
          },
          %{
            id: :provider_nested_ground_station,
            type: :contact,
            direction: :downlink,
            scenario_id: :leo_2,
            satellite: %{satellite_id: :sat_2},
            ground_station: %{ground_station_id: :equator_prime},
            start_s: 80.0,
            end_s: 140.0,
            estimated_throughput_mb: 90.0,
            source_window: %{id: :provider_window_b}
          }
        ],
        approval_policy: %{bundle: "contact_command_review_v1"}
      )

    assert Enum.map(intents, & &1["ground_station_id"]) == ["equator_prime", "equator_prime"]
    assert Enum.map(intents, & &1["spacecraft_id"]) == ["sat_1", "sat_2"]

    assert Enum.map(intents, & &1["timeline_id"]) == [
             "timeline:leo_1:contact:equator_prime:provider_window_a",
             "timeline:leo_2:contact:equator_prime:provider_window_b"
           ]

    assert Enum.all?(intents, fn intent ->
             get_in(intent, [
               "approval_requirements",
               Access.at(0),
               "activity_context",
               "spacecraft_id"
             ]) ==
               intent["spacecraft_id"]
           end)

    review_package = OperatorReview.from_contact_intent(List.first(intents))
    assert [%{"spacecraft_id" => "sat_1"}] = review_package["rows"]

    import_manifest = CadenceImport.from_contact_intent(List.first(intents))
    assert [%{"spacecraft_id" => "sat_1"}] = import_manifest["rows"]

    assert Enum.all?(intents, fn intent ->
             {:ok, %{"schema_contract" => "contact_intent.v1"}} =
               Schema.validate_artifact(intent)
           end)
  end

  test "infers downlink intents from provider contacts without type or direction" do
    [intent] =
      ContactIntent.from_activities([
        %{
          id: :provider_contact,
          scenario_id: :leo_1,
          station_id: :equator_prime,
          start_s: 10.0,
          end_s: 70.0,
          estimated_throughput_mb: 120.0,
          source_window: %{id: :provider_window}
        }
      ])

    assert %{
             "schema_contract" => "contact_intent.v1",
             "id" => "provider_contact",
             "activity_type" => "downlink",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "starts_at_s" => 10.0,
             "ends_at_s" => 70.0,
             "estimated_throughput_mb" => 120.0,
             "source_window_id" => "provider_window",
             "timeline_id" => "timeline:leo_1:downlink:equator_prime:provider_window",
             "cadence_import" => %{
               "external_id" => "provider_contact",
               "activity_type" => "contact"
             }
           } = intent

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(intent)
  end

  test "normalizes numeric string provider contact timing throughput and factors" do
    [intent] =
      ContactIntent.from_activities([
        %{
          "id" => "provider_numeric_string_contact",
          "scenario_id" => "leo_1",
          "station_id" => "equator_prime",
          "start_s" => "10.0",
          "end_s" => "70.5",
          "estimated_throughput_mb" => "120.25",
          "station_calendar_overlap_count" => "1",
          "station_calendar_reservation_overlap_count" => "1.0",
          "contact_success_factor" => "0.75",
          "station_calendar_reservation_ids" => ["reservation_1"],
          "source_window" => %{"id" => "provider_window"}
        }
      ])

    assert %{
             "schema_contract" => "contact_intent.v1",
             "id" => "provider_numeric_string_contact",
             "activity_type" => "downlink",
             "ground_station_id" => "equator_prime",
             "direction" => "downlink",
             "starts_at_s" => 10.0,
             "ends_at_s" => 70.5,
             "estimated_throughput_mb" => 120.25,
             "station_calendar_overlap_count" => 1,
             "station_calendar_reservation_overlap_count" => 1,
             "contact_success_factor" => 0.75,
             "activity_context" => %{
               "starts_at_s" => 10.0,
               "ends_at_s" => 70.5,
               "contact_success_factor" => 0.75
             }
           } = intent

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(intent)
  end

  test "derives station calendar counts from preserved id sets" do
    [intent] =
      ContactIntent.from_activities([
        %{
          id: :provider_stale_counts,
          type: :planned_contact,
          direction: :downlink,
          scenario_id: :leo_1,
          ground_station_id: :equator_prime,
          starts_at_s: 10.0,
          ends_at_s: 70.0,
          station_calendar_overlap_count: 99,
          station_calendar_overlap_entry_ids: [:station_a, :station_b],
          station_calendar_ambiguous_entry_count: 99,
          station_calendar_ambiguous_entry_ids: [:station_b],
          station_calendar_reservation_overlap_count: 99,
          station_calendar_reservation_ids: [:reservation_1]
        }
      ])

    assert %{
             "station_calendar_overlap_count" => 2,
             "station_calendar_overlap_entry_ids" => ["station_a", "station_b"],
             "station_calendar_ambiguous_entry_count" => 1,
             "station_calendar_ambiguous_entry_ids" => ["station_b"],
             "station_calendar_reservation_overlap_count" => 1,
             "station_calendar_reservation_ids" => ["reservation_1"]
           } = intent

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(intent)

    stale_overlap_count = Map.put(intent, "station_calendar_overlap_count", 1)

    assert {:error, overlap_validation} = Schema.validate_artifact(stale_overlap_count)

    assert Enum.any?(
             overlap_validation["errors"],
             &(&1["path"] == "$.station_calendar_overlap_count" and
                 &1["message"] == "must equal 2")
           )

    stale_ambiguous_count = Map.put(intent, "station_calendar_ambiguous_entry_count", 2)

    assert {:error, ambiguous_validation} = Schema.validate_artifact(stale_ambiguous_count)

    assert Enum.any?(
             ambiguous_validation["errors"],
             &(&1["path"] == "$.station_calendar_ambiguous_entry_count" and
                 &1["message"] == "must equal 1")
           )

    stale_reservation_count = Map.put(intent, "station_calendar_reservation_overlap_count", 2)

    assert {:error, reservation_validation} = Schema.validate_artifact(stale_reservation_count)

    assert Enum.any?(
             reservation_validation["errors"],
             &(&1["path"] == "$.station_calendar_reservation_overlap_count" and
                 &1["message"] == "must equal 1")
           )
  end

  test "adds policy decisions to command and contact intents when requested" do
    [command, uplink] =
      ContactIntent.from_activities(
        [
          %{
            id: :cmd_1,
            type: :command,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            start_s: 10.0,
            end_s: 20.0
          },
          %{
            id: :uplink_1,
            type: :planned_contact,
            direction: :uplink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            start_s: 30.0,
            end_s: 40.0
          }
        ],
        approval_policy: %{bundle: "contact_command_review_v1"}
      )

    assert command["approval_status"] == "operator_review_required"
    assert uplink["approval_status"] == "operator_review_required"

    assert [
             %{
               "activity_id" => "cmd_1",
               "activity_type" => "command",
               "action" => "review_command_contact",
               "requirement_type" => "command_review",
               "activity_context" => %{
                 "direction" => "command",
                 "ground_station_id" => "equator_prime"
               },
               "policy_classification" => "operator_review_required"
             }
           ] = command["approval_requirements"]

    assert [
             %{
               "activity_id" => "uplink_1",
               "activity_type" => "planned_contact",
               "action" => "review_command_contact",
               "requirement_type" => "command_review",
               "reason" => "uplink contact intents require command policy classification",
               "activity_context" => %{
                 "direction" => "uplink",
                 "ground_station_id" => "equator_prime"
               },
               "policy_classification" => "operator_review_required"
             }
           ] = uplink["approval_requirements"]

    assert [
             %{
               "rule_id" => "command_health_review",
               "classification" => "operator_review_required"
             }
           ] = command["approval_rule_matches"]

    assert [
             %{
               "rule_id" => "command_health_review",
               "classification" => "operator_review_required"
             }
           ] = uplink["approval_rule_matches"]

    assert %{
             "schema_contract" => "policy_decision.v1",
             "classification" => "operator_review_required",
             "policy_bundle_id" => "contact_command_review_v1"
           } = command["policy_decision"]

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(command)

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(uplink)
  end

  test "carries contact feedback evidence into policy decisions" do
    [intent] =
      ContactIntent.from_activities(
        [
          %{
            id: :downlink_1,
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            start_s: 10.0,
            end_s: 20.0,
            metadata: %{
              contact_success: " FALSE ",
              contact_result: [:accepted, :dropped],
              contact_success_factor: "0.25",
              contact_success_factor_source: :operational_feedback_contact_success
            }
          }
        ],
        approval_policy: %{bundle: "command_contact_authority_v1"}
      )

    assert %{
             "contact_success" => false,
             "contact_result" => "accepted,dropped",
             "contact_success_factor" => 0.25,
             "contact_success_factor_source" => "operational_feedback_contact_success",
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "contact_success" => false,
                   "contact_result" => "accepted,dropped",
                   "contact_success_factor" => 0.25,
                   "contact_success_factor_source" => "operational_feedback_contact_success"
                 }
               }
             ]
           } = intent

    assert Enum.any?(
             intent["approval_rule_matches"],
             &(&1["rule_id"] == "failed_contact_success_review" and
                 &1["contact_success"] == false and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert Enum.any?(
             intent["approval_rule_matches"],
             &(&1["rule_id"] == "low_contact_success_confidence_review" and
                 &1["contact_success_factor"] == 0.25 and
                 &1["contact_success_factor_source"] == "operational_feedback_contact_success" and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(intent)

    review_package = OperatorReview.from_contact_intent(intent)

    assert [
             %{
               "review_type" => "contact_intent_review",
               "contact_result" => "accepted,dropped",
               "activity_context" => %{"contact_result" => "accepted,dropped"}
             }
           ] = review_package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review_package)

    import_manifest = CadenceImport.from_contact_intent(intent)

    assert [
             %{
               "import_action" => "review_contact_intent",
               "contact_result" => "accepted,dropped",
               "import_activity_context" => %{"contact_result" => "accepted,dropped"}
             }
           ] = import_manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import_manifest)
  end

  test "normalizes map-valued provider results in contact intent handoff" do
    [intent] =
      ContactIntent.from_activities(
        [
          %{
            id: :downlink_provider_map,
            type: :downlink,
            direction: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            start_s: 10.0,
            end_s: 20.0,
            metadata: %{
              contact_success: " FALSE ",
              contact_result: %{
                outcome: :accepted,
                provider_status: :"NO-CONTACT"
              }
            }
          }
        ],
        approval_policy: %{bundle: "command_contact_authority_v1"}
      )

    assert %{
             "contact_success" => false,
             "contact_result" => "accepted,NO-CONTACT",
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "contact_success" => false,
                   "contact_result" => "accepted,NO-CONTACT"
                 }
               }
             ]
           } = intent

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(intent)

    review_package = OperatorReview.from_contact_intent(intent)

    assert [
             %{
               "review_type" => "contact_intent_review",
               "contact_result" => "accepted,NO-CONTACT",
               "activity_context" => %{"contact_result" => "accepted,NO-CONTACT"}
             }
           ] = review_package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review_package)

    import_manifest = CadenceImport.from_contact_intent(intent)

    assert [
             %{
               "import_action" => "review_contact_intent",
               "contact_result" => "accepted,NO-CONTACT",
               "import_activity_context" => %{"contact_result" => "accepted,NO-CONTACT"}
             }
           ] = import_manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import_manifest)
  end

  test "review-gates out-of-range confidence factors before policy handoff" do
    [command, downlink] =
      ContactIntent.from_activities(
        [
          %{
            id: :downlink_clamped,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            start_s: 10.0,
            end_s: 20.0,
            contact_success_factor: 1.4,
            contact_success_factor_source: :operator_feedback
          },
          %{
            id: :command_clamped,
            type: :command,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            start_s: 5.0,
            end_s: 8.0,
            metadata: %{
              command_success: " False ",
              command_result: [:accepted, :adapter_rejected],
              command_success_factor: -0.25,
              command_success_factor_source: :command_adapter
            }
          }
        ],
        approval_policy: %{bundle: "command_contact_authority_v1"}
      )

    assert %{
             "id" => "command_clamped",
             "command_success" => false,
             "command_result" => "accepted,adapter_rejected",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "invalid_command_success_factor",
             "source_activity" => %{
               "metadata" => %{
                 "command_success_factor" => -0.25
               }
             },
             "approval_requirements" => [
               %{
                 "activity_context" => command_context
               }
             ]
           } = command

    refute Map.has_key?(command, "command_success_factor")
    assert command_context["invalid_activity_input_reason"] == "invalid_command_success_factor"
    refute Map.has_key?(command_context, "command_success_factor")

    assert %{
             "id" => "downlink_clamped",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "invalid_contact_success_factor",
             "source_activity" => %{"contact_success_factor" => 1.4},
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "invalid_activity_input_reason" => "invalid_contact_success_factor"
                 }
               }
             ]
           } = downlink

    refute Map.has_key?(downlink, "contact_success_factor")

    command_review = OperatorReview.from_contact_intent(command)
    downlink_import = CadenceImport.from_contact_intent(downlink)

    assert Enum.any?(
             command_review["rows"],
             &(&1["subject_id"] == "command_clamped" and
                 &1["invalid_activity_input_reason"] == "invalid_command_success_factor")
           )

    assert Enum.any?(
             downlink_import["rows"],
             &(&1["subject_id"] == "downlink_clamped" and
                 &1["invalid_activity_input_reason"] == "invalid_contact_success_factor")
           )

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(command)

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(downlink)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(command_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(downlink_import)
  end

  test "public facade builds policy-aware contact intents" do
    activities = [
      %{
        id: :provider_contact,
        type: :contact,
        direction: :downlink,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: 10.0,
        end_s: 70.0,
        source_window: %{id: :provider_window}
      }
    ]

    assert OrbitalDynamics.contact_intents_from_activities(
             activities,
             approval_policy: %{bundle: "contact_command_review_v1"}
           ) ==
             ContactIntent.from_activities(
               activities,
               approval_policy: %{bundle: "contact_command_review_v1"}
             )

    [intent] = OrbitalDynamics.contact_intents_from_activities(activities)

    assert intent["schema_contract"] == "contact_intent.v1"
    assert intent["ground_station_id"] == "equator_prime"
    assert intent["timeline_id"] == "timeline:leo_1:contact:equator_prime:provider_window"
    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} = Schema.validate_artifact(intent)
  end

  test "public facade builds one contact intent row" do
    activity = %{
      id: :cmd_1,
      type: :command,
      scenario_id: :leo_1,
      ground_station_id: :equator_prime,
      start_s: 10.0,
      end_s: 20.0
    }

    assert OrbitalDynamics.contact_intent_from_activity!(activity) ==
             ContactIntent.from_activity!(activity)
  end

  test "accepts activity-type-only command rows without downlink inference" do
    intent =
      ContactIntent.from_activity!(%{
        id: :provider_command,
        activity_type: :command,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: 10.0,
        end_s: 20.0
      })

    assert %{
             "activity_id" => "provider_command",
             "activity_type" => "command",
             "direction" => "command",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 10.0,
             "ends_at_s" => 20.0,
             "cadence_import" => %{"activity_type" => "command"}
           } = intent

    assert get_in(intent, ["timeline_identity", "activity_type"]) == "command"

    assert {:ok, %{"schema_contract" => "contact_intent.v1"}} =
             Schema.validate_artifact(intent)
  end

  test "rejects unsupported contact directions" do
    assert_raise ArgumentError, ~r/contact direction/, fn ->
      ContactIntent.from_activity!(%{
        id: "bad",
        type: "planned_contact",
        scenario_id: "leo_1",
        ground_station_id: "equator_prime",
        direction: "laser",
        starts_at_s: 0.0,
        ends_at_s: 10.0
      })
    end
  end

  defp json_capacity_value_paths(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end
end
