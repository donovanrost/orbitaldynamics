defmodule OrbitalDynamics.Communications.CommandWindowTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Communications.CommandWindow
  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.MissionPlan.Activity
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.Schema

  test "declares artifact-only command window capabilities" do
    assert %{
             artifact_contract: "command_window_report.v1",
             validation_level: :artifact_contract,
             source_activity_types: source_activity_types,
             command_window_activity_types: command_window_activity_types,
             source_directions: source_directions,
             station_unavailable_aliases: station_unavailable_aliases,
             station_availability_precedence: station_availability_precedence,
             station_capacity_fraction_paths: station_capacity_fraction_paths,
             station_capacity_percent_paths: station_capacity_percent_paths,
             station_capacity_value_paths: station_capacity_value_paths,
             source_station_capacity_fraction_paths: source_station_capacity_fraction_paths,
             source_station_capacity_percent_paths: source_station_capacity_percent_paths,
             source_station_capacity_value_paths: source_station_capacity_value_paths,
             station_reservation_expiration_fields: station_reservation_expiration_fields,
             station_calendar_reservation_expiration_fields:
               station_calendar_reservation_expiration_fields,
             provider_direction_aliases: provider_direction_aliases,
             provider_result_map_value_keys: provider_result_map_value_keys,
             row_semantics: row_semantics,
             known_limits: known_limits
           } = CommandWindow.capabilities()

    assert "command" in source_activity_types
    assert "planned_contact" in source_activity_types
    assert command_window_activity_types == ["command", "tracking", "health_check"]
    assert "uplink" in source_directions
    assert station_unavailable_aliases == ["outage", "down", "offline"]

    assert station_availability_precedence == %{
             "unavailable" => 5,
             "maintenance" => 5,
             "reserved" => 4,
             "reduced_capacity" => 3,
             "available" => 1
           }

    assert ["capacity_pack_capacity_fraction"] in station_capacity_fraction_paths
    assert ["station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_fraction"] in station_capacity_fraction_paths

    assert ["source_activity", "capacity_pack_capacity_fraction"] in station_capacity_fraction_paths

    assert ["source_activity", "capacity_fraction"] in station_capacity_fraction_paths
    assert ["throughput_model", "station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_model", "capacity_fraction"] in station_capacity_fraction_paths
    assert ["activity_context", "capacity_fraction"] in station_capacity_fraction_paths

    assert ["station_capacity_percent"] in station_capacity_percent_paths
    assert ["capacity_percent"] in station_capacity_percent_paths
    assert ["source_activity", "capacity_percent"] in station_capacity_percent_paths
    assert ["throughput_model", "station_capacity_percent"] in station_capacity_percent_paths
    assert ["capacity_model", "capacity_percent"] in station_capacity_percent_paths
    assert ["activity_context", "capacity_percent"] in station_capacity_percent_paths

    assert %{unit: :fraction, path: ["capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_pack_capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :percent, path: ["capacity_percent"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["source_activity", "capacity_fraction"]} in station_capacity_value_paths

    assert %{
             unit: :fraction,
             path: ["source_activity", "capacity_pack_capacity_fraction"]
           } in station_capacity_value_paths

    assert %{unit: :percent, path: ["source_activity", "capacity_percent"]} in station_capacity_value_paths

    assert ["source_station_calendar_entry", "capacity_pack_capacity_fraction"] in source_station_capacity_fraction_paths

    assert ["source_station_calendar_entry", "capacity_fraction"] in source_station_capacity_fraction_paths

    assert ["source_station_calendar_entry", "capacity_model", "capacity_fraction"] in source_station_capacity_fraction_paths

    assert ["source_station_calendar_overlaps", "throughput_model", "station_capacity_fraction"] in source_station_capacity_fraction_paths

    assert [
             "activity_context",
             "source_station_calendar_entry",
             "activity_context",
             "capacity_fraction"
           ] in source_station_capacity_fraction_paths

    assert ["source_station_calendar_entry", "capacity_percent"] in source_station_capacity_percent_paths

    assert ["source_activity", "source_station_calendar_entry", "capacity_percent"] in source_station_capacity_percent_paths

    assert ["activity_context", "source_station_calendar_overlaps", "capacity_percent"] in source_station_capacity_percent_paths

    assert %{
             unit: :fraction,
             path: ["source_station_calendar_entry", "capacity_fraction"]
           } in source_station_capacity_value_paths

    assert %{
             unit: :fraction,
             path: ["source_station_calendar_entry", "capacity_pack_capacity_fraction"]
           } in source_station_capacity_value_paths

    assert %{
             unit: :percent,
             path: ["activity_context", "source_station_calendar_overlaps", "capacity_percent"]
           } in source_station_capacity_value_paths

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

    assert Map.take(provider_direction_aliases, [
             "cmd",
             "commanding",
             "commands",
             "sband_command",
             "s_band_command",
             "up",
             "up_link",
             "dl",
             "down",
             "downlinking",
             "down_link",
             "track",
             "track_ing",
             "tracking_pass",
             "health",
             "healthcheck",
             "health_check_window"
           ]) == %{
             "cmd" => "command",
             "commanding" => "command",
             "commands" => "command",
             "sband_command" => "command",
             "s_band_command" => "command",
             "up" => "uplink",
             "up_link" => "uplink",
             "dl" => "downlink",
             "down" => "downlink",
             "downlinking" => "downlink",
             "down_link" => "downlink",
             "track" => "tracking",
             "track_ing" => "tracking",
             "tracking_pass" => "tracking",
             "health" => "health_check",
             "healthcheck" => "health_check",
             "health_check_window" => "health_check"
           }

    assert "result" in provider_result_map_value_keys
    assert "provider_status" in provider_result_map_value_keys
    assert "provider_outcome" in provider_result_map_value_keys
    assert "diagnostics" in provider_result_map_value_keys

    assert :required_operator_action in row_semantics
    assert :command_window_activity_types in row_semantics
    assert :timeline_identity in row_semantics
    assert :timeline_integrity_review in row_semantics
    assert :invalid_activity_input_review in row_semantics
    assert :declared_station_calendar_overlay in row_semantics
    assert :station_reservation_context in row_semantics
    assert :station_calendar_reservation_expiration_context in row_semantics
    assert :station_reservation_expiration_aliases in row_semantics
    assert :station_calendar_reservation_expiration_aliases in row_semantics
    assert :station_calendar_provider_context in row_semantics
    assert :station_calendar_provider_list_input in row_semantics
    assert :station_calendar_review_precedence in row_semantics
    assert :station_calendar_direction_context in row_semantics
    assert :station_capacity_value_paths in row_semantics
    assert :source_station_capacity_value_paths in row_semantics
    assert :provider_direction_aliases in row_semantics
    assert :provider_result_map_value_keys in row_semantics
    assert :command_window_activity_id_routing in row_semantics
    assert :command_window_review_action_id_routing in row_semantics
    assert :no_command_execution in known_limits
    assert :no_schedule_mutation in known_limits
  end

  test "builds command window report rows from command tracking uplink and health activities" do
    report =
      CommandWindow.report(
        [
          Activity.observe!(:obs_1, 10.0, 20.0, :target_a),
          Activity.command!(:cmd_1, 30.0, 40.0,
            ground_station_id: :dss_14,
            approval_status: :pending,
            source_window_id: :cmd_window_1,
            dependencies: [
              :health_gate,
              %{activity_id: :obs_1, timeline_id: :"timeline:obs_1"}
            ],
            metadata: %{
              exclusive_with: [%{id: :uplink_1, timeline_id: :"timeline:uplink_1"}]
            }
          ),
          %{
            id: :track_1,
            type: :tracking,
            scenario_id: :leo_1,
            starts_at_s: 50.0,
            ends_at_s: 60.0,
            ground_station_id: :dss_14,
            direction: :tracking,
            approval_status: :approved,
            cadence_import: %{activity_type: :tracking, external_id: :track_1}
          },
          Activity.planned_contact!(:uplink_1, 70.0, 80.0, :dss_14, :uplink,
            approval_status: :approved,
            locked?: true
          ),
          Activity.health_check!(:health_1, 90.0, 100.0)
        ],
        source: "mission_plan.activities",
        source_assumption: "operator supplied mission-plan activities"
      )

    assert report["schema_contract"] == "command_window_report.v1"
    assert report["source"] == "mission_plan.activities"
    assert report["window_count"] == 4
    assert report["command_count"] == 1
    assert report["tracking_count"] == 1
    assert report["uplink_count"] == 1
    assert report["health_check_count"] == 1

    assert report["activity_ids_by_window_type"] == %{
             "command_window" => ["cmd_1"],
             "health_check_window" => ["health_1"],
             "tracking_window" => ["track_1"],
             "uplink_window" => ["uplink_1"]
           }

    assert report["review_required_count"] == 2

    assert report["review_activity_ids_by_required_operator_action"] == %{
             "prepare_cadence_import" => ["uplink_1"],
             "review_command_contact" => ["cmd_1"]
           }

    assert report["source_window_lineage_count"] == 1
    assert "no_command_execution" in report["model_limits"]
    assert "no_provider_reservation" in report["model_limits"]

    expected_model_limits =
      CommandWindow.capabilities()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&to_string/1)

    assert report["model_limits"] == expected_model_limits

    refute Enum.any?(report["rows"], &(&1["activity_id"] == "obs_1"))

    assert %{
             "activity_id" => "cmd_1",
             "window_type" => "command_window",
             "direction" => "command",
             "ground_station_id" => "dss_14",
             "source_window_id" => "cmd_window_1",
             "dependency_activity_ids" => ["health_gate", "obs_1"],
             "dependency_timeline_ids" => ["timeline:obs_1"],
             "exclusive_with_activity_ids" => ["uplink_1"],
             "exclusive_with_timeline_ids" => ["timeline:uplink_1"],
             "required_operator_action" => "review_command_contact",
             "operator_action_reason" => "command_boundary_requires_review",
             "cadence_import_status" => "missing",
             "execution_boundary" => "planned_not_commanded",
             "activity_context" => %{
               "command_window_id" => "command_window:cmd_1",
               "command_window_type" => "command_window",
               "starts_at_s" => 30.0,
               "ends_at_s" => 40.0,
               "source_window_id" => "cmd_window_1",
               "dependency_activity_ids" => ["health_gate", "obs_1"],
               "dependency_timeline_ids" => ["timeline:obs_1"],
               "exclusive_with_activity_ids" => ["uplink_1"],
               "exclusive_with_timeline_ids" => ["timeline:uplink_1"],
               "timeline_identity" => %{
                 "activity_id" => "cmd_1",
                 "timeline_id" => "timeline:command:dss_14:cmd_window_1",
                 "source_window_id" => "cmd_window_1"
               }
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_1"))

    assert %{
             "activity_id" => "track_1",
             "window_type" => "tracking_window",
             "required_operator_action" => "monitor_activity",
             "cadence_import_status" => "present",
             "cadence_import_type" => "tracking"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "track_1"))

    assert %{
             "activity_id" => "uplink_1",
             "window_type" => "uplink_window",
             "required_operator_action" => "prepare_cadence_import",
             "activity_context" => %{
               "command_window_id" => "command_window:uplink_1",
               "command_window_type" => "uplink_window"
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "uplink_1"))

    assert %{
             "activity_id" => "health_1",
             "window_type" => "health_check_window",
             "required_operator_action" => "monitor_activity"
           } = Enum.find(report["rows"], &(&1["activity_id"] == "health_1"))

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, schema} = Schema.json_schema("command_window_report.v1")

    assert get_in(schema, ["properties", "model_limits", "items", "enum"]) ==
             expected_model_limits

    assert get_in(schema, ["properties", "activity_ids_by_window_type", "type"]) == "object"

    assert get_in(
             schema,
             [
               "properties",
               "review_activity_ids_by_required_operator_action",
               "additionalProperties",
               "type"
             ]
           ) == "array"

    invalid_model_limits = Map.put(report, "model_limits", ["no_schedule_mutation"])

    assert {:error, validation_report} = Schema.validate_artifact(invalid_model_limits)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] =~ "must match command window report model limits")
           )

    invalid_window_ids =
      Map.put(report, "activity_ids_by_window_type", %{"command_window" => ["stale_cmd"]})

    assert {:error, invalid_window_ids_report} = Schema.validate_artifact(invalid_window_ids)

    assert Enum.any?(
             invalid_window_ids_report["errors"],
             &(&1["path"] == "$.activity_ids_by_window_type" and
                 &1["message"] == "must equal row-derived activity_ids_by_window_type")
           )

    invalid_review_ids =
      Map.put(report, "review_activity_ids_by_required_operator_action", %{
        "review_command_contact" => ["stale_cmd"]
      })

    assert {:error, invalid_review_ids_report} = Schema.validate_artifact(invalid_review_ids)

    assert Enum.any?(
             invalid_review_ids_report["errors"],
             &(&1["path"] == "$.review_activity_ids_by_required_operator_action" and
                 &1["message"] ==
                   "must equal row-derived review_activity_ids_by_required_operator_action")
           )
  end

  test "preserves malformed command-window activity inputs for operator review" do
    report =
      CommandWindow.report(
        [
          %{
            type: :command,
            scenario_id: :leo_1,
            starts_at_s: 15.0,
            ends_at_s: 25.0,
            ground_station_id: :dss_14,
            direction: :command
          },
          %{
            id: :uplink_missing_type,
            scenario_id: :leo_1,
            start_s: 30.0,
            end_s: 40.0,
            station_id: :dss_43,
            direction: :uplink
          },
          "not a command-window activity"
        ],
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert report["window_count"] == 2
    assert report["invalid_activity_input_count"] == 1

    assert report["invalid_activity_input_ids"] == [
             "missing_activity_id:1"
           ]

    assert report["review_required_count"] == 2

    command_row = Enum.find(report["rows"], &(&1["activity_id"] == "missing_activity_id:1"))
    uplink_row = Enum.find(report["rows"], &(&1["activity_id"] == "uplink_missing_type"))

    assert %{
             "activity_type" => "invalid_activity_input",
             "window_type" => "command_window",
             "direction" => "command",
             "ground_station_id" => "dss_14",
             "starts_at_s" => 15.0,
             "ends_at_s" => 25.0,
             "required_operator_action" => "review_invalid_activity_input",
             "operator_action_reason" => "missing_activity_id",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "source_activity" => %{"type" => "command", "direction" => "command"},
             "approval_status" => "operator_review_required",
             "approval_requirements" => [
               %{
                 "action" => "review_invalid_activity_input",
                 "requirement_type" => "command_review",
                 "policy_classification" => "operator_review_required"
               }
             ],
             "policy_decision" => %{"policy_bundle_id" => "command_contact_authority_v1"}
           } = command_row

    assert Enum.any?(
             command_row["approval_rule_matches"],
             &(&1["rule_id"] == "invalid_command_window_input_review" and
                 &1["required_authority"] == "mission_planning_authority")
           )

    assert %{
             "window_type" => "uplink_window",
             "activity_type" => "planned_contact",
             "direction" => "uplink",
             "ground_station_id" => "dss_43",
             "starts_at_s" => 30.0,
             "ends_at_s" => 40.0,
             "required_operator_action" => "review_command_contact",
             "operator_action_reason" => "command_boundary_requires_review",
             "approval_requirements" => [
               %{
                 "action" => "review_command_contact",
                 "requirement_type" => "command_review"
               }
             ]
           } = uplink_row

    review = OperatorReview.from_command_window_report(report)
    import = CadenceImport.from_command_window_report(report)

    review_rows = Map.new(review["rows"], &{&1["activity_id"], &1})

    assert %{
             "required_operator_action" => "review_invalid_activity_input",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "source_policy_decision" => %{"policy_bundle_id" => "command_contact_authority_v1"},
             "source_activity" => %{"type" => "command"},
             "source_command_window" => %{
               "activity_id" => "missing_activity_id:1",
               "invalid_activity_input" => true
             }
           } = review_rows["missing_activity_id:1"]

    assert Enum.any?(
             review_rows["missing_activity_id:1"]["approval_rule_matches"],
             &(&1["rule_id"] == "invalid_command_window_input_review")
           )

    assert %{
             "required_operator_action" => "review_command_contact",
             "approval_requirements" => [
               %{"requirement_type" => "command_review"}
             ],
             "source_command_window" => %{
               "activity_type" => "planned_contact",
               "direction" => "uplink"
             }
           } = review_rows["uplink_missing_type"]

    import_rows = Map.new(import["rows"], &{&1["activity_id"], &1})

    assert %{
             "source_review_action" => "review_invalid_activity_input",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_id",
             "source_policy_decision" => %{"policy_bundle_id" => "command_contact_authority_v1"},
             "source_activity" => %{"type" => "command"},
             "source_command_window" => %{
               "activity_id" => "missing_activity_id:1",
               "invalid_activity_input" => true
             }
           } = import_rows["missing_activity_id:1"]

    assert Enum.any?(
             import_rows["missing_activity_id:1"]["approval_rule_matches"],
             &(&1["rule_id"] == "invalid_command_window_input_review")
           )

    assert %{
             "source_review_action" => "review_command_contact",
             "approval_requirements" => [
               %{"requirement_type" => "command_review"}
             ],
             "source_command_window" => %{
               "activity_type" => "planned_contact",
               "direction" => "uplink"
             }
           } = import_rows["uplink_missing_type"]

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "preserves station reservation and provider-calendar context on command window handoff rows" do
    report =
      CommandWindow.report(
        [
          %{
            id: :uplink_reserved,
            type: :planned_contact,
            scenario_id: :leo_1,
            starts_at_s: 30.0,
            ends_at_s: 40.0,
            ground_station_id: :dss_14,
            direction: "Up Link",
            station_contention_status: :reserved_overlap,
            station_calendar_entry_id: :calendar_uplink_42,
            station_calendar_provider_id: :provider_a,
            station_calendar_provider_entry_id: :provider_uplink_42,
            station_calendar_directions: ["commands"],
            station_calendar_status: :reserved,
            station_calendar_trust_boundary_status: :declared,
            trust_boundary: :ground_partner_api,
            provenance: %{
              source: :station_calendar_provider,
              provider_id: :provider_a,
              trust_boundary: :ground_partner_api
            },
            source_station_calendar_entry: %{
              id: :provider_uplink_42,
              directions: ["s-band command"],
              provenance: %{trust_boundary: :ground_partner_api}
            },
            station_reservation_id: :reservation_42,
            station_reserved_by: :ops_team_b,
            station_reservation_status: :confirmed,
            station_reservation_match_status: :matched
          }
        ],
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert [
             %{
               "activity_id" => "uplink_reserved",
               "window_type" => "uplink_window",
               "station_contention_status" => "reserved_overlap",
               "station_calendar_entry_id" => "calendar_uplink_42",
               "station_calendar_provider_id" => "provider_a",
               "station_calendar_provider_entry_id" => "provider_uplink_42",
               "station_calendar_directions" => ["command"],
               "station_calendar_status" => "reserved",
               "station_calendar_trust_boundary_status" => "declared",
               "trust_boundary" => "ground_partner_api",
               "source_station_calendar_entry" => %{
                 "id" => "provider_uplink_42",
                 "directions" => ["command"]
               },
               "station_reservation_id" => "reservation_42",
               "station_reserved_by" => "ops_team_b",
               "station_reservation_status" => "confirmed",
               "station_reservation_match_status" => "matched",
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "station_calendar_entry_id" => "calendar_uplink_42",
                     "station_calendar_directions" => ["command"],
                     "station_reservation_id" => "reservation_42",
                     "station_reservation_match_status" => "matched"
                   }
                 }
               ],
               "activity_context" => %{
                 "station_calendar_entry_id" => "calendar_uplink_42",
                 "station_calendar_directions" => ["command"],
                 "station_reservation_id" => "reservation_42",
                 "station_reservation_match_status" => "matched"
               }
             }
           ] = report["rows"]

    review = OperatorReview.from_command_window_report(report)
    import = CadenceImport.from_command_window_report(report)

    assert [
             %{
               "activity_id" => "uplink_reserved",
               "station_calendar_entry_id" => "calendar_uplink_42",
               "station_calendar_directions" => ["command"],
               "station_reservation_id" => "reservation_42",
               "station_reservation_match_status" => "matched",
               "source_activity_context" => %{
                 "station_calendar_entry_id" => "calendar_uplink_42",
                 "station_calendar_directions" => ["command"],
                 "station_reservation_id" => "reservation_42",
                 "station_reservation_match_status" => "matched"
               }
             }
           ] = review["rows"]

    assert [
             %{
               "activity_id" => "uplink_reserved",
               "station_calendar_entry_id" => "calendar_uplink_42",
               "station_calendar_directions" => ["command"],
               "station_reservation_id" => "reservation_42",
               "station_reservation_match_status" => "matched",
               "import_activity_context" => %{
                 "station_calendar_entry_id" => "calendar_uplink_42",
                 "station_calendar_directions" => ["command"],
                 "station_reservation_id" => "reservation_42",
                 "station_reservation_match_status" => "matched"
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "treats provider-shaped health-check contacts as command windows" do
    report =
      CommandWindow.report(
        [
          %{
            id: :health_provider_contact,
            type: :planned_contact,
            scenario_id: :leo_1,
            starts_at_s: "30.0",
            ends_at_s: "40.0",
            station_id: :dss_14,
            direction: "Health Check",
            station_calendar_entry_id: :health_check_calendar_1,
            station_calendar_directions: ["Health Check"],
            station_availability: :reduced_capacity,
            source_station_calendar_entry: %{
              id: :health_check_calendar_1,
              capacity_pack_capacity_fraction: "0.5"
            }
          }
        ],
        approval_policy: %{policy_bundle_id: "contact_command_review_v1"}
      )

    assert "health_check" in CommandWindow.capabilities().source_directions
    assert report["window_count"] == 1
    assert report["health_check_count"] == 1
    assert report["review_required_count"] == 1

    assert [
             %{
               "activity_id" => "health_provider_contact",
               "activity_type" => "planned_contact",
               "window_type" => "health_check_window",
               "direction" => "health_check",
               "ground_station_id" => "dss_14",
               "starts_at_s" => 30.0,
               "ends_at_s" => 40.0,
               "station_availability" => "reduced_capacity",
               "capacity_fraction" => 0.5,
               "source_station_calendar_entry" => %{
                 "capacity_pack_capacity_fraction" => "0.5"
               },
               "station_calendar_entry_id" => "health_check_calendar_1",
               "station_calendar_directions" => ["health_check"],
               "approval_requirements" => [
                 %{
                   "requirement_type" => "health_check_review",
                   "activity_context" => %{
                     "command_window_type" => "health_check_window",
                     "capacity_fraction" => 0.5,
                     "direction" => "health_check",
                     "ground_station_id" => "dss_14",
                     "station_calendar_entry_id" => "health_check_calendar_1",
                     "station_calendar_directions" => ["health_check"]
                   }
                 }
               ]
             }
           ] = report["rows"]

    review = OperatorReview.from_command_window_report(report)
    import = CadenceImport.from_command_window_report(report)

    assert [
             %{
               "review_type" => "command_window_review",
               "activity_id" => "health_provider_contact",
               "window_type" => "health_check_window",
               "direction" => "health_check",
               "capacity_fraction" => 0.5,
               "source_command_window" => %{
                 "window_type" => "health_check_window",
                 "direction" => "health_check",
                 "capacity_fraction" => 0.5
               }
             }
           ] = review["rows"]

    assert [
             %{
               "import_action" => "review_command_window",
               "activity_id" => "health_provider_contact",
               "window_type" => "health_check_window",
               "direction" => "health_check",
               "capacity_fraction" => 0.5,
               "source_command_window" => %{
                 "window_type" => "health_check_window",
                 "direction" => "health_check",
                 "capacity_fraction" => 0.5
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "passes station reservation match evidence into approval policy routing" do
    approval_policy = %{
      action_rules: [
        %{
          id: :owned_reservation_command_review,
          station_reservation_ids: [:reservation_42],
          station_reserved_bys: [:ops_team_b],
          station_reservation_match_statuses: [:matched],
          classification: :operator_review_required,
          reason: "owned reservation command windows require contact-schedule authority"
        }
      ]
    }

    report =
      CommandWindow.report(
        [
          %{
            id: :uplink_reserved,
            type: :planned_contact,
            scenario_id: :leo_1,
            starts_at_s: 30.0,
            ends_at_s: 40.0,
            ground_station_id: :dss_14,
            direction: :uplink,
            station_contention_status: :reserved_overlap,
            station_reservation_id: :reservation_42,
            station_reserved_by: :ops_team_b,
            station_reservation_status: :confirmed,
            station_reservation_match_status: :matched
          }
        ],
        approval_policy: approval_policy
      )

    assert [
             %{
               "activity_id" => "uplink_reserved",
               "approval_status" => "operator_review_required",
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "station_reservation_id" => "reservation_42",
                     "station_reserved_by" => "ops_team_b",
                     "station_reservation_match_status" => "matched"
                   }
                 }
               ],
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "owned_reservation_command_review",
                   "station_reservation_id" => "reservation_42",
                   "station_reservation_ids" => ["reservation_42"],
                   "station_reserved_by" => "ops_team_b",
                   "station_reservation_status" => "confirmed",
                   "station_reservation_match_status" => "matched"
                 }
               ]
             }
           ] = report["rows"]

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes provider reservation aliases before approval policy routing" do
    approval_policy = %{
      action_rules: [
        %{
          id: :provider_owned_reservation_command_review,
          station_reservation_ids: [:reservation_42],
          station_reserved_bys: [:ops_team_b],
          station_reservation_statuses: [:confirmed],
          station_reservation_match_statuses: [:matched],
          classification: :operator_review_required,
          reason: "provider reservation aliases require contact-schedule authority"
        }
      ]
    }

    report =
      CommandWindow.report(
        [
          %{
            id: :uplink_provider_reserved,
            type: :planned_contact,
            scenario_id: :leo_1,
            starts_at_s: 30.0,
            ends_at_s: 40.0,
            ground_station_id: :dss_14,
            direction: :uplink,
            station_availability: :reserved,
            station_contention_status: "Reserved Overlap",
            reservation_id: :reservation_42,
            reserved_by: :ops_team_b,
            reservation_status: "Confirmed",
            reservation_match_status: "Matched"
          }
        ],
        approval_policy: approval_policy
      )

    assert [
             %{
               "activity_id" => "uplink_provider_reserved",
               "required_operator_action" => "review_command_contact",
               "station_availability" => "reserved",
               "station_contention_status" => "reserved_overlap",
               "station_reservation_id" => "reservation_42",
               "station_reserved_by" => "ops_team_b",
               "station_reservation_status" => "confirmed",
               "station_reservation_match_status" => "matched",
               "approval_status" => "operator_review_required",
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "station_reservation_id" => "reservation_42",
                     "station_reserved_by" => "ops_team_b",
                     "station_reservation_status" => "confirmed",
                     "station_reservation_match_status" => "matched"
                   }
                 }
               ],
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "provider_owned_reservation_command_review",
                   "station_reservation_id" => "reservation_42",
                   "station_reservation_ids" => ["reservation_42"],
                   "station_reserved_by" => "ops_team_b",
                   "station_reservation_status" => "confirmed",
                   "station_reservation_match_status" => "matched"
                 }
               ]
             }
           ] = report["rows"]

    review = OperatorReview.from_command_window_report(report)
    [review_row] = review["rows"]

    assert %{
             "station_reservation_id" => "reservation_42",
             "station_reserved_by" => "ops_team_b",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "matched"
           } = review_row

    import = CadenceImport.from_command_window_report(report)
    [import_row] = import["rows"]

    assert %{
             "station_reservation_id" => "reservation_42",
             "station_reserved_by" => "ops_team_b",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "matched"
           } = import_row

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "derives reservation context from nested provider calendar evidence" do
    approval_policy = %{
      action_rules: [
        %{
          id: :provider_reservation_overlap_review,
          station_reservation_ids: [:reservation_42],
          station_reserved_bys: [:ops_team_b],
          station_reservation_statuses: [:confirmed],
          station_reservation_match_statuses: [:overlap],
          classification: :operator_review_required,
          reason: "nested provider reservation requires ground-network review"
        }
      ]
    }

    report =
      CommandWindow.report(
        [
          %{
            id: :tracking_nested_reserved,
            type: :tracking,
            scenario_id: :leo_1,
            starts_at_s: 90.0,
            ends_at_s: 120.0,
            ground_station_id: :dss_14,
            direction: :tracking,
            approval_status: :approved,
            cadence_import: %{
              activity_type: :tracking,
              external_id: :tracking_nested_reserved
            },
            source_station_calendar_entry: %{
              id: :provider_reservation_1,
              availability: :reserved,
              reservation_id: :reservation_42,
              reservation_expires_at_s: "420.0",
              reserved_by: :ops_team_b,
              reservation_status: "Confirmed"
            }
          }
        ],
        approval_policy: approval_policy
      )

    assert [
             %{
               "activity_id" => "tracking_nested_reserved",
               "required_operator_action" => "review_command_window_station_calendar",
               "operator_action_reason" => "station_calendar_reserved_command_window",
               "station_availability" => "reserved",
               "station_calendar_status" => "reserved",
               "station_reservation_id" => "reservation_42",
               "station_reservation_expires_at_s" => 420.0,
               "station_calendar_reservation_expires_at_s" => [420.0],
               "station_reserved_by" => "ops_team_b",
               "station_reservation_status" => "confirmed",
               "station_reservation_match_status" => "overlap",
               "source_station_calendar_entry" => %{
                 "id" => "provider_reservation_1",
                 "availability" => "reserved",
                 "reservation_id" => "reservation_42",
                 "station_reservation_id" => "reservation_42",
                 "reserved_by" => "ops_team_b",
                 "station_reserved_by" => "ops_team_b",
                 "reservation_status" => "confirmed",
                 "station_reservation_status" => "confirmed"
               },
               "approval_status" => "operator_review_required",
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "station_reservation_id" => "reservation_42",
                     "station_reservation_expires_at_s" => 420.0,
                     "station_calendar_reservation_expires_at_s" => [420.0],
                     "station_reserved_by" => "ops_team_b",
                     "station_reservation_status" => "confirmed",
                     "station_reservation_match_status" => "overlap"
                   }
                 }
               ],
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "provider_reservation_overlap_review",
                   "station_reservation_id" => "reservation_42",
                   "station_calendar_reservation_expires_at_s" => [420.0],
                   "station_reserved_by" => "ops_team_b",
                   "station_reservation_status" => "confirmed",
                   "station_reservation_match_status" => "overlap"
                 }
               ]
             }
           ] = report["rows"]

    review = OperatorReview.from_command_window_report(report)
    [review_row] = review["rows"]

    assert %{
             "station_availability" => "reserved",
             "station_reservation_id" => "reservation_42",
             "station_reservation_expires_at_s" => 420.0,
             "station_calendar_reservation_expires_at_s" => [420.0],
             "station_reserved_by" => "ops_team_b",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "overlap"
           } = review_row

    import = CadenceImport.from_command_window_report(report)
    [import_row] = import["rows"]

    assert %{
             "station_availability" => "reserved",
             "station_reservation_id" => "reservation_42",
             "station_reservation_expires_at_s" => 420.0,
             "station_calendar_reservation_expires_at_s" => [420.0],
             "station_reserved_by" => "ops_team_b",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "overlap"
           } = import_row

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "derives reservation overlap lists from nested provider calendar overlaps" do
    approval_policy = %{
      action_rules: [
        %{
          id: :provider_reservation_list_review,
          station_calendar_reservation_ids: [:reservation_b],
          station_calendar_reserved_bys: [:ops_team_b],
          station_calendar_reservation_statuses: [:confirmed],
          classification: :operator_review_required,
          reason: "nested provider reservation overlap list requires review"
        }
      ]
    }

    report =
      CommandWindow.report(
        [
          %{
            id: :tracking_multi_reserved,
            type: :tracking,
            scenario_id: :leo_1,
            starts_at_s: 90.0,
            ends_at_s: 120.0,
            ground_station_id: :dss_14,
            direction: :tracking,
            approval_status: :approved,
            cadence_import: %{
              activity_type: :tracking,
              external_id: :tracking_multi_reserved
            },
            source_station_calendar_overlaps: [
              %{
                id: :provider_reservation_a,
                availability: :reserved,
                reservation_id: :reservation_a,
                reservation_hold_expires_at_s: "420.0",
                reserved_by: :ops_team_a,
                reservation_status: :tentative
              },
              %{
                id: :provider_reservation_b,
                status: :reserved,
                reservation_id: :reservation_b,
                expires_at: "540.0",
                reserved_by: :ops_team_b,
                reservation_status: "Confirmed"
              }
            ]
          }
        ],
        approval_policy: approval_policy
      )

    assert [
             %{
               "activity_id" => "tracking_multi_reserved",
               "required_operator_action" => "review_command_window_station_calendar",
               "operator_action_reason" => "station_calendar_reserved_command_window",
               "station_availability" => "reserved",
               "station_calendar_status" => "reserved",
               "station_calendar_reservation_overlap_count" => 2,
               "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
               "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
               "station_calendar_reservation_statuses" => ["confirmed", "tentative"],
               "station_calendar_reservation_expires_at_s" => [420.0, 540.0],
               "approval_status" => "operator_review_required",
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "station_calendar_reservation_overlap_count" => 2,
                     "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
                     "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
                     "station_calendar_reservation_statuses" => ["confirmed", "tentative"],
                     "station_calendar_reservation_expires_at_s" => [420.0, 540.0]
                   }
                 }
               ],
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "provider_reservation_list_review",
                   "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
                   "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
                   "station_calendar_reservation_statuses" => ["confirmed", "tentative"]
                 }
               ]
             }
           ] = report["rows"]

    review = OperatorReview.from_command_window_report(report)
    [review_row] = review["rows"]

    assert %{
             "station_calendar_reservation_overlap_count" => 2,
             "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
             "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
             "station_calendar_reservation_statuses" => ["confirmed", "tentative"],
             "station_calendar_reservation_expires_at_s" => [420.0, 540.0]
           } = review_row

    import = CadenceImport.from_command_window_report(report)
    [import_row] = import["rows"]

    assert %{
             "station_calendar_reservation_overlap_count" => 2,
             "station_calendar_reservation_ids" => ["reservation_a", "reservation_b"],
             "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
             "station_calendar_reservation_statuses" => ["confirmed", "tentative"],
             "station_calendar_reservation_expires_at_s" => [420.0, 540.0]
           } = import_row

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "command window reports preserve timeline integrity review signals" do
    report =
      CommandWindow.report(
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
            id: :obs_cycle,
            type: :observe,
            scenario_id: :leo_1,
            starts_at_s: 35.0,
            ends_at_s: 45.0,
            target_id: :target_a,
            dependencies: [:cmd_1]
          },
          %{
            id: :cmd_1,
            type: :command,
            scenario_id: :leo_1,
            starts_at_s: 30.0,
            ends_at_s: 40.0,
            ground_station_id: :dss_14,
            dependencies: [:obs_cycle, :health_gate, :missing_gate],
            exclusive_with: [:dl_conflict]
          },
          %{
            id: :dl_conflict,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 32.0,
            ends_at_s: 38.0,
            ground_station_id: :dss_14
          }
        ],
        validate_missing_dependencies?: true
      )

    assert report["window_count"] == 2
    assert report["review_required_count"] == 1
    assert get_in(report, ["assumptions", "missing_dependency_validation"]) == "enabled"

    assert %{
             "activity_id" => "cmd_1",
             "required_operator_action" => "review_timeline_integrity",
             "operator_action_reason" => "timeline_integrity_issue",
             "superseded_required_operator_action" => "review_command_contact",
             "superseded_operator_action_reason" => "command_boundary_requires_review",
             "timeline_integrity_status" => "review_required",
             "missing_dependency_activity_ids" => ["missing_gate"],
             "dependency_cycle_activity_ids" => ["obs_cycle"],
             "dependency_order_violation_activity_ids" => ["health_gate"],
             "exclusivity_violation_activity_ids" => ["dl_conflict"],
             "dependency_activity_ids" => ["health_gate", "missing_gate", "obs_cycle"],
             "exclusive_with_activity_ids" => ["dl_conflict"],
             "activity_context" => %{
               "dependency_cycle_activity_ids" => ["obs_cycle"],
               "timeline_integrity_status" => "review_required"
             }
           } = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_1"))

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_command_window_report(report)
    import = CadenceImport.from_command_window_report(report)

    assert [
             %{
               "review_type" => "command_window_review",
               "activity_id" => "cmd_1",
               "required_operator_action" => "review_timeline_integrity",
               "timeline_integrity_status" => "review_required",
               "missing_dependency_activity_ids" => ["missing_gate"],
               "dependency_cycle_activity_ids" => ["obs_cycle"],
               "dependency_order_violation_activity_ids" => ["health_gate"],
               "exclusivity_violation_activity_ids" => ["dl_conflict"],
               "source_command_window" => %{
                 "activity_id" => "cmd_1",
                 "timeline_integrity_status" => "review_required"
               }
             }
           ] = review["rows"]

    assert [
             %{
               "import_action" => "review_command_window",
               "activity_id" => "cmd_1",
               "required_operator_action" => "review_timeline_integrity",
               "timeline_integrity_status" => "review_required",
               "missing_dependency_activity_ids" => ["missing_gate"],
               "dependency_cycle_activity_ids" => ["obs_cycle"],
               "dependency_order_violation_activity_ids" => ["health_gate"],
               "exclusivity_violation_activity_ids" => ["dl_conflict"],
               "source_command_window" => %{
                 "activity_id" => "cmd_1",
                 "timeline_integrity_status" => "review_required"
               }
             }
           ] = import["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "classifies command window review rows with approval policy" do
    report =
      CommandWindow.report(
        [
          %{
            id: :cmd_1,
            type: :command,
            scenario_id: :leo_1,
            ground_station_id: :dss_14,
            direction: :command,
            starts_at_s: 30.0,
            ends_at_s: 40.0,
            status: :planned,
            approval_status: :pending,
            source_window_id: :cmd_window_1,
            metadata: %{
              command_success: "false",
              command_result: [:accepted, :rejected],
              command_success_factor: "0.25",
              command_success_factor_source: :"operational_feedback.command_success_rate.activity"
            }
          },
          Activity.health_check!(:health_1, 90.0, 100.0, approval_status: :pending),
          %{
            id: :track_1,
            type: :tracking,
            starts_at_s: 110.0,
            ends_at_s: 120.0,
            ground_station_id: :dss_14,
            direction: :tracking,
            approval_status: :approved,
            cadence_import: %{activity_type: :tracking, external_id: :track_1}
          }
        ],
        approval_policy: %{policy_bundle_id: "contact_command_review_v1"}
      )

    assert report["window_count"] == 3
    assert report["review_required_count"] == 2

    command_row = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_1"))
    health_row = Enum.find(report["rows"], &(&1["activity_id"] == "health_1"))
    tracking_row = Enum.find(report["rows"], &(&1["activity_id"] == "track_1"))

    assert %{
             "approval_status" => "operator_review_required",
             "approval_requirements" => [
               %{
                 "requirement_type" => "command_review",
                 "policy_classification" => "operator_review_required"
               }
             ],
             "approval_rule_matches" => [
               %{
                 "rule_id" => "command_health_review",
                 "requirement_type" => "command_review"
               }
             ],
             "policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "policy_bundle_id" => "contact_command_review_v1"
             }
           } = command_row

    assert [
             %{
               "activity_context" => %{
                 "activity_id" => "cmd_1",
                 "starts_at_s" => 30.0,
                 "ends_at_s" => 40.0,
                 "source_window_id" => "cmd_window_1",
                 "timeline_identity" => %{
                   "activity_id" => "cmd_1",
                   "source_window_id" => "cmd_window_1"
                 },
                 "command_success" => false,
                 "command_result" => "accepted,rejected",
                 "command_success_factor" => 0.25,
                 "command_success_factor_source" =>
                   "operational_feedback.command_success_rate.activity"
               }
             }
           ] = command_row["approval_requirements"]

    assert %{
             "command_success" => false,
             "command_result" => "accepted,rejected",
             "command_success_factor" => 0.25,
             "command_success_factor_source" =>
               "operational_feedback.command_success_rate.activity",
             "activity_context" => %{
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.25
             }
           } = command_row

    assert %{
             "approval_status" => "operator_review_required",
             "approval_requirements" => [
               %{
                 "requirement_type" => "health_check_review",
                 "policy_classification" => "operator_review_required"
               }
             ],
             "approval_rule_matches" => [
               %{
                 "rule_id" => "command_health_review",
                 "requirement_type" => "health_check_review"
               }
             ]
           } = health_row

    refute Map.has_key?(tracking_row, "policy_decision")

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves provider contact result failures on command-window review rows" do
    report =
      CommandWindow.report([
        %{
          id: :uplink_dropped,
          type: :planned_contact,
          direction: :uplink,
          scenario_id: :leo_1,
          ground_station_id: :dss_14,
          starts_at_s: 70.0,
          ends_at_s: 80.0,
          status: :completed,
          approval_status: :approved,
          contact_result: ["accepted", " DROPPED "]
        }
      ])

    assert report["review_required_count"] == 1

    assert %{
             "activity_id" => "uplink_dropped",
             "window_type" => "uplink_window",
             "status" => "completed",
             "contact_result" => "accepted,DROPPED",
             "required_operator_action" => "review_terminal_activity_exception",
             "operator_action_reason" => "contact_result_dropped_requires_review",
             "activity_context" => %{"contact_result" => "accepted,DROPPED"}
           } = List.first(report["rows"])

    review = OperatorReview.from_command_window_report(report)
    import = CadenceImport.from_command_window_report(report)

    assert %{
             "review_type" => "command_window_review",
             "activity_id" => "uplink_dropped",
             "contact_result" => "accepted,DROPPED",
             "required_operator_action" => "review_terminal_activity_exception",
             "reason" => "contact_result_dropped_requires_review"
           } = List.first(review["rows"])

    assert %{
             "import_action" => "review_command_window",
             "activity_id" => "uplink_dropped",
             "contact_result" => "accepted,DROPPED",
             "required_operator_action" => "review_terminal_activity_exception"
           } = List.first(import["rows"])

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "normalizes map-valued provider results on command-window rows" do
    report =
      CommandWindow.report([
        %{
          id: :uplink_provider_map,
          type: :planned_contact,
          direction: :uplink,
          scenario_id: :leo_1,
          ground_station_id: :dss_14,
          starts_at_s: 70.0,
          ends_at_s: 80.0,
          status: :completed,
          approval_status: :approved,
          contact_result: %{
            outcome: :accepted,
            provider_status: :"NO-CONTACT"
          }
        },
        %{
          id: :cmd_provider_map,
          type: :command,
          direction: :command,
          scenario_id: :leo_1,
          ground_station_id: :dss_14,
          starts_at_s: 90.0,
          ends_at_s: 100.0,
          status: :planned,
          approval_status: :pending,
          metadata: %{
            command_result: %{
              status: :rejected,
              details: %{message: "timed out"}
            }
          }
        }
      ])

    uplink = Enum.find(report["rows"], &(&1["activity_id"] == "uplink_provider_map"))
    command = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_provider_map"))

    assert %{
             "contact_result" => "accepted,NO-CONTACT",
             "required_operator_action" => "review_terminal_activity_exception",
             "operator_action_reason" => "contact_result_no_contact_requires_review",
             "activity_context" => %{"contact_result" => "accepted,NO-CONTACT"}
           } = uplink

    assert %{
             "command_result" => "rejected,timed out",
             "activity_context" => %{"command_result" => "rejected,timed out"}
           } = command

    review = OperatorReview.from_command_window_report(report)
    import = CadenceImport.from_command_window_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["activity_id"] == "uplink_provider_map" and
                 &1["contact_result"] == "accepted,NO-CONTACT")
           )

    assert Enum.any?(
             import["rows"],
             &(&1["activity_id"] == "cmd_provider_map" and
                 &1["command_result"] == "rejected,timed out")
           )

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "keeps blocked terminal command windows in review handoff" do
    report =
      CommandWindow.report([
        %{
          id: :cmd_blocked_executed,
          type: :command,
          direction: :command,
          scenario_id: :leo_1,
          ground_station_id: :dss_14,
          starts_at_s: 70.0,
          ends_at_s: 80.0,
          status: :executed,
          approval_status: :blocked_by_policy
        },
        %{
          id: :cmd_status_blocked,
          type: :command,
          direction: :command,
          scenario_id: :leo_1,
          ground_station_id: :dss_14,
          starts_at_s: 90.0,
          ends_at_s: 100.0,
          status: :blocked_by_policy,
          approval_status: :approved
        }
      ])

    assert report["review_required_count"] == 2
    rows = Map.new(report["rows"], &{&1["activity_id"], &1})

    assert %{
             "activity_id" => "cmd_blocked_executed",
             "window_type" => "command_window",
             "status" => "executed",
             "approval_status" => "blocked_by_policy",
             "required_operator_action" => "resolve_blocked_activity",
             "operator_action_reason" => "approval_status_blocked_by_policy"
           } = rows["cmd_blocked_executed"]

    assert %{
             "activity_id" => "cmd_status_blocked",
             "window_type" => "command_window",
             "status" => "blocked_by_policy",
             "approval_status" => "approved",
             "required_operator_action" => "resolve_blocked_activity",
             "operator_action_reason" => "activity_status_blocked_by_policy"
           } = rows["cmd_status_blocked"]

    review = OperatorReview.from_command_window_report(report)
    import = CadenceImport.from_command_window_report(report)
    review_rows = Map.new(review["rows"], &{&1["activity_id"], &1})
    import_rows = Map.new(import["rows"], &{&1["activity_id"], &1})

    assert %{
             "review_type" => "command_window_review",
             "activity_id" => "cmd_blocked_executed",
             "approval_status" => "blocked_by_policy",
             "required_operator_action" => "resolve_blocked_activity",
             "reason" => "approval_status_blocked_by_policy"
           } = review_rows["cmd_blocked_executed"]

    assert %{
             "review_type" => "command_window_review",
             "activity_id" => "cmd_status_blocked",
             "status" => "blocked_by_policy",
             "required_operator_action" => "resolve_blocked_activity",
             "reason" => "activity_status_blocked_by_policy"
           } = review_rows["cmd_status_blocked"]

    assert %{
             "import_action" => "review_command_window",
             "activity_id" => "cmd_blocked_executed",
             "approval_status" => "blocked_by_policy",
             "required_operator_action" => "resolve_blocked_activity",
             "import_status" => "blocked_missing_cadence_import"
           } = import_rows["cmd_blocked_executed"]

    assert %{
             "import_action" => "review_command_window",
             "activity_id" => "cmd_status_blocked",
             "status" => "blocked_by_policy",
             "required_operator_action" => "resolve_blocked_activity",
             "import_status" => "blocked_missing_cadence_import"
           } = import_rows["cmd_status_blocked"]

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "classifies command contact authority by command window direction" do
    report =
      CommandWindow.report(
        [
          %{
            id: :cmd_1,
            type: :command,
            starts_at_s: 30.0,
            ends_at_s: 40.0,
            ground_station_id: :dss_14,
            direction: :command,
            approval_status: :pending,
            command_success: false,
            command_success_factor: 0.25,
            command_success_factor_source: "operational_feedback.command_success_rate"
          },
          Activity.planned_contact!(:uplink_1, 70.0, 80.0, :dss_14, :uplink,
            approval_status: :approved
          ),
          %{
            id: :track_1,
            type: :tracking,
            starts_at_s: 110.0,
            ends_at_s: 120.0,
            ground_station_id: :dss_14,
            direction: :tracking,
            approval_status: :approved
          },
          Activity.health_check!(:health_1, 130.0, 140.0, approval_status: :pending)
        ],
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    command_row = Enum.find(report["rows"], &(&1["activity_id"] == "cmd_1"))
    uplink_row = Enum.find(report["rows"], &(&1["activity_id"] == "uplink_1"))
    tracking_row = Enum.find(report["rows"], &(&1["activity_id"] == "track_1"))
    health_row = Enum.find(report["rows"], &(&1["activity_id"] == "health_1"))

    assert Enum.any?(
             command_row["approval_rule_matches"],
             &(&1["rule_id"] == "command_uplink_authority_review" and
                 &1["direction"] == "command" and
                 &1["required_authority"] == "command_authority")
           )

    assert Enum.any?(
             command_row["approval_rule_matches"],
             &(&1["rule_id"] == "low_command_success_confidence_review" and
                 &1["command_success_factor"] == 0.25 and
                 &1["required_authority"] == "command_authority")
           )

    assert Enum.any?(
             command_row["approval_rule_matches"],
             &(&1["rule_id"] == "failed_command_success_review" and
                 &1["command_success"] == false and
                 &1["required_authority"] == "command_authority")
           )

    assert Enum.any?(
             uplink_row["approval_rule_matches"],
             &(&1["rule_id"] == "command_uplink_authority_review" and
                 &1["direction"] == "uplink" and
                 &1["required_authority"] == "command_authority")
           )

    assert Enum.any?(
             tracking_row["approval_rule_matches"],
             &(&1["rule_id"] == "tracking_coordination_review" and
                 &1["direction"] == "tracking" and
                 &1["required_authority"] == "tracking_coordination_authority")
           )

    assert Enum.any?(
             health_row["approval_rule_matches"],
             &(&1["rule_id"] == "health_command_authority_review" and
                 &1["required_authority"] == "command_authority")
           )

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "builds command windows from station-id-only provider activities" do
    report =
      CommandWindow.report(
        [
          %{
            id: :provider_tracking,
            type: :tracking,
            direction: :tracking,
            scenario_id: :leo_1,
            station_id: :dss_14,
            start_s: 10.0,
            end_s: 20.0,
            approval_status: :pending,
            source_window_id: :tracking_window_1
          }
        ],
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert %{
             "window_count" => 1,
             "tracking_count" => 1,
             "rows" => [
               %{
                 "activity_id" => "provider_tracking",
                 "window_type" => "tracking_window",
                 "ground_station_id" => "dss_14",
                 "timeline_id" => "timeline:leo_1:tracking:dss_14:tracking_window_1",
                 "activity_context" => %{
                   "ground_station_id" => "dss_14",
                   "timeline_identity" => %{
                     "subject_id" => "dss_14"
                   }
                 },
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "ground_station_id" => "dss_14",
                       "window_type" => "tracking_window"
                     }
                   }
                 ]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes numeric string timing confidence and capacity inputs" do
    report =
      CommandWindow.report([
        %{
          id: :cmd_string_numbers,
          type: :command,
          scenario_id: :leo_1,
          station_id: :dss_14,
          start_s: "10.0",
          end_s: "20.5",
          metadata: %{command_success: "0", command_success_factor: "0.25"},
          capacity_fraction: "0.5"
        }
      ])

    assert %{
             "activity_id" => "cmd_string_numbers",
             "starts_at_s" => 10.0,
             "ends_at_s" => 20.5,
             "command_success" => false,
             "command_success_factor" => 0.25,
             "capacity_fraction" => 0.5,
             "activity_context" => %{
               "starts_at_s" => 10.0,
               "ends_at_s" => 20.5,
               "command_success" => false,
               "command_success_factor" => 0.25,
               "capacity_fraction" => 0.5
             }
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "derives station availability from direct station calendar status evidence" do
    report =
      CommandWindow.report(
        [
          %{
            id: :tracking_direct_outage,
            type: :tracking,
            scenario_id: :leo_1,
            starts_at_s: 100.0,
            ends_at_s: 160.0,
            ground_station_id: :dss_14,
            direction: :tracking,
            status: :planned,
            approval_status: :approved,
            cadence_import: %{activity_type: :tracking, external_id: :tracking_direct_outage},
            station_availability: :available,
            station_calendar_status: "Offline",
            station_calendar_entry_id: :direct_outage_1,
            station_calendar_provider_id: :ground_partner_a,
            station_calendar_provider_entry_id: :provider_outage_1,
            source_station_calendar_entry: %{
              id: :provider_outage_1,
              availability: "Offline"
            }
          }
        ],
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert %{
             "review_required_count" => 1,
             "rows" => [
               %{
                 "activity_id" => "tracking_direct_outage",
                 "window_type" => "tracking_window",
                 "required_operator_action" => "review_command_window_station_calendar",
                 "operator_action_reason" => "station_calendar_unavailable_command_window",
                 "station_availability" => "unavailable",
                 "station_calendar_status" => "unavailable",
                 "station_calendar_entry_id" => "direct_outage_1",
                 "station_calendar_provider_id" => "ground_partner_a",
                 "station_calendar_provider_entry_id" => "provider_outage_1",
                 "source_station_calendar_entry" => %{
                   "id" => "provider_outage_1",
                   "availability" => "unavailable"
                 },
                 "activity_context" => %{
                   "station_availability" => "unavailable",
                   "station_calendar_status" => "unavailable",
                   "station_calendar_entry_id" => "direct_outage_1"
                 },
                 "approval_status" => "blocked_by_policy",
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "station_availability" => "unavailable",
                       "station_calendar_status" => "unavailable",
                       "station_calendar_entry_id" => "direct_outage_1"
                     }
                   }
                 ]
               } = row
             ]
           } = report

    assert Enum.any?(
             row["approval_rule_matches"],
             &(&1["rule_id"] == "command_window_station_calendar_block" and
                 &1["classification"] == "blocked_by_policy" and
                 &1["station_availability"] == "unavailable")
           )

    review = OperatorReview.from_command_window_report(report)
    [review_row] = review["rows"]

    assert %{
             "required_operator_action" => "review_command_window_station_calendar",
             "station_availability" => "unavailable",
             "station_calendar_status" => "unavailable",
             "station_calendar_entry_id" => "direct_outage_1",
             "source_activity_context" => %{
               "station_availability" => "unavailable",
               "station_calendar_status" => "unavailable"
             }
           } = review_row

    import = CadenceImport.from_command_window_report(report)
    [import_row] = import["rows"]

    assert %{
             "source_review_action" => "review_command_window_station_calendar",
             "station_availability" => "unavailable",
             "station_calendar_status" => "unavailable",
             "station_calendar_entry_id" => "direct_outage_1",
             "import_activity_context" => %{
               "station_availability" => "unavailable",
               "station_calendar_status" => "unavailable"
             }
           } = import_row

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "applies declared station-calendar overlays to command window review rows" do
    report =
      CommandWindow.report(
        [
          %{
            id: :tracking_maintenance,
            type: :tracking,
            scenario_id: :leo_1,
            starts_at_s: 100.0,
            ends_at_s: 160.0,
            ground_station_id: :dss_14,
            direction: :tracking,
            approval_status: :approved,
            cadence_import: %{activity_type: :tracking, external_id: :tracking_maintenance}
          }
        ],
        station_calendar: [
          %{
            id: :dss_14_maintenance,
            ground_station_id: :dss_14,
            status: :maintenance,
            starts_at_s: 90.0,
            ends_at_s: 170.0,
            provenance: %{trust_boundary: :declared_provider}
          }
        ],
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert %{
             "station_calendar_report" => %{
               "schema_contract" => "station_calendar_report.v1",
               "affected_contact_count" => 1
             },
             "review_required_count" => 1,
             "rows" => [
               %{
                 "activity_id" => "tracking_maintenance",
                 "window_type" => "tracking_window",
                 "required_operator_action" => "review_command_window_station_calendar",
                 "operator_action_reason" => "station_calendar_unavailable_command_window",
                 "station_availability" => "unavailable",
                 "station_calendar_entry_id" => "dss_14_maintenance",
                 "source_station_calendar_entry" => %{
                   "id" => "dss_14_maintenance",
                   "availability" => "unavailable",
                   "status" => "maintenance"
                 },
                 "activity_context" => %{
                   "station_availability" => "unavailable",
                   "station_calendar_entry_id" => "dss_14_maintenance"
                 },
                 "approval_status" => "blocked_by_policy",
                 "policy_decision" => %{
                   "classification" => "blocked_by_policy",
                   "policy_bundle_id" => "command_contact_authority_v1"
                 },
                 "approval_requirements" => [
                   %{
                     "action" => "review_command_window_station_calendar",
                     "activity_context" => %{
                       "station_availability" => "unavailable",
                       "station_calendar_entry_id" => "dss_14_maintenance"
                     }
                   }
                 ]
               }
             ]
           } = report

    row = hd(report["rows"])

    assert Enum.any?(
             row["approval_rule_matches"],
             &(&1["rule_id"] == "command_window_station_calendar_block" and
                 &1["classification"] == "blocked_by_policy" and
                 &1["station_availability"] == "unavailable" and
                 &1["required_operator_action"] == "review_command_window_station_calendar" and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    review = OperatorReview.from_command_window_report(report)
    review_row = hd(review["rows"])

    assert %{
             "review_type" => "command_window_review",
             "required_operator_action" => "review_command_window_station_calendar",
             "station_availability" => "unavailable",
             "station_calendar_entry_id" => "dss_14_maintenance"
           } = review_row

    import = CadenceImport.from_command_window_report(report)
    import_row = hd(import["rows"])

    assert %{
             "import_action" => "review_command_window",
             "required_operator_action" => "review_command_window_station_calendar",
             "station_availability" => "unavailable",
             "station_calendar_entry_id" => "dss_14_maintenance"
           } = import_row

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "applies station-calendar provider lists to command window review rows" do
    report =
      CommandWindow.report(
        [
          %{
            id: :cmd_provider_list,
            type: :command,
            scenario_id: :leo_1,
            starts_at_s: 100.0,
            ends_at_s: 160.0,
            ground_station_id: :dss_14,
            direction: :uplink,
            approval_status: :approved,
            cadence_import: %{activity_type: :command, external_id: :cmd_provider_list}
          }
        ],
        station_calendar: [
          %{
            schema_contract: "station_calendar_provider.v1",
            id: :aux_calendar,
            trust_boundary: :declared_provider,
            entries: [
              %{
                id: :aux_available,
                station_id: :polar_aux,
                status: :available,
                starts_at_s: 90.0,
                ends_at_s: 170.0
              }
            ]
          },
          %{
            schema_contract: "station_calendar_provider.v1",
            id: :ops_calendar,
            trust_boundary: :declared_provider,
            entries: [
              %{
                id: :dss_14_uplink_reservation,
                station_id: :dss_14,
                availability: :reserved,
                directions: [:uplink],
                starts_at_s: 90.0,
                ends_at_s: 170.0,
                reservation_id: :provider_cmd_reservation,
                reserved_by: :ops_calendar,
                reservation_status: :confirmed
              }
            ]
          }
        ]
      )

    assert %{
             "station_calendar_report" => %{
               "calendar_entry_count" => 2,
               "affected_contact_count" => 1
             },
             "review_required_count" => 1,
             "rows" => [
               %{
                 "activity_id" => "cmd_provider_list",
                 "window_type" => "command_window",
                 "required_operator_action" => "review_command_window_station_calendar",
                 "operator_action_reason" => "station_calendar_reserved_command_window",
                 "station_calendar_entry_id" => "dss_14_uplink_reservation",
                 "station_calendar_provider_id" => "ops_calendar",
                 "station_calendar_provider_entry_id" => "dss_14_uplink_reservation",
                 "station_calendar_directions" => ["uplink"],
                 "station_calendar_reservation_ids" => ["provider_cmd_reservation"],
                 "station_calendar_reserved_by" => ["ops_calendar"],
                 "station_calendar_reservation_statuses" => ["confirmed"],
                 "source_station_calendar_entry" => %{
                   "id" => "dss_14_uplink_reservation",
                   "provenance" => %{
                     "source" => "station_calendar_provider",
                     "provider_id" => "ops_calendar",
                     "trust_boundary" => "declared_provider"
                   }
                 },
                 "activity_context" => %{
                   "station_calendar_provider_id" => "ops_calendar",
                   "station_calendar_provider_entry_id" => "dss_14_uplink_reservation",
                   "station_calendar_reservation_ids" => ["provider_cmd_reservation"]
                 }
               }
             ]
           } = report

    review = OperatorReview.from_command_window_report(report)
    import = CadenceImport.from_command_window_report(report)

    assert %{
             "review_type" => "command_window_review",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "dss_14_uplink_reservation",
             "station_calendar_reservation_ids" => ["provider_cmd_reservation"]
           } = hd(review["rows"])

    assert %{
             "import_action" => "review_command_window",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "dss_14_uplink_reservation",
             "station_calendar_reservation_ids" => ["provider_cmd_reservation"]
           } = hd(import["rows"])

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "station-calendar review supersedes missing cadence import without dropping import context" do
    report =
      CommandWindow.report(
        [
          %{
            id: :cmd_missing_import_reserved,
            type: :command,
            scenario_id: :leo_1,
            starts_at_s: 100.0,
            ends_at_s: 160.0,
            ground_station_id: :dss_14,
            direction: :uplink,
            approval_status: :approved
          }
        ],
        station_calendar: [
          %{
            schema_contract: "station_calendar_provider.v1",
            id: :ops_calendar,
            trust_boundary: :declared_provider,
            entries: [
              %{
                id: :dss_14_reserved,
                station_id: :dss_14,
                availability: :reserved,
                directions: [:uplink],
                starts_at_s: 90.0,
                ends_at_s: 170.0,
                reservation_id: :reservation_1,
                reserved_by: :ops_calendar,
                reservation_status: :confirmed
              }
            ]
          }
        ]
      )

    assert %{
             "review_required_count" => 1,
             "rows" => [
               %{
                 "activity_id" => "cmd_missing_import_reserved",
                 "cadence_import_status" => "missing",
                 "required_operator_action" => "review_command_window_station_calendar",
                 "operator_action_reason" => "station_calendar_reserved_command_window",
                 "superseded_required_operator_action" => "prepare_cadence_import",
                 "superseded_operator_action_reason" => "cadence_import_missing",
                 "station_calendar_provider_id" => "ops_calendar",
                 "station_calendar_provider_entry_id" => "dss_14_reserved",
                 "station_calendar_reservation_ids" => ["reservation_1"]
               }
             ]
           } = report

    review = OperatorReview.from_command_window_report(report)
    import = CadenceImport.from_command_window_report(report)

    assert %{
             "required_operator_action" => "review_command_window_station_calendar",
             "cadence_import_status" => "missing",
             "superseded_required_operator_action" => "prepare_cadence_import",
             "station_calendar_provider_id" => "ops_calendar"
           } = hd(review["rows"])

    assert %{
             "import_action" => "review_command_window",
             "required_operator_action" => "review_command_window_station_calendar",
             "cadence_import_status" => "missing",
             "superseded_required_operator_action" => "prepare_cadence_import",
             "station_calendar_provider_id" => "ops_calendar"
           } = hd(import["rows"])

    assert {:ok, %{"schema_contract" => "command_window_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "public facade builds command window reports" do
    report =
      OrbitalDynamics.command_window_report([
        %{id: "cmd_1", type: "command", starts_at_s: 0.0, ends_at_s: 10.0}
      ])

    assert report["window_count"] == 1
    assert [%{"window_type" => "command_window"}] = report["rows"]
    assert CommandWindow.report(report) == report
    assert OrbitalDynamics.command_window_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert CommandWindow.report(atom_keyed_report) == report
    assert OrbitalDynamics.command_window_report(atom_keyed_report) == report
  end

  test "rejects non-list activities" do
    assert_raise ArgumentError,
                 ~r/command window report must be a command_window_report.v1 map/,
                 fn ->
                   CommandWindow.report(%{})
                 end
  end
end
