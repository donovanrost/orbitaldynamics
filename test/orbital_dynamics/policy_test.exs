defmodule OrbitalDynamics.PolicyTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Policy, Schema}

  defmodule StructBackedPolicy do
    defstruct policy_bundle_id: "ground_network_allocation_v1"
  end

  test "declares policy capabilities" do
    assert %{
             artifact_contract: "policy_decision.v1",
             validation_level: :artifact_contract,
             classifications: classifications,
             cadence_import_statuses: cadence_import_statuses,
             match_dimensions: match_dimensions,
             fallback_policy_fields: fallback_policy_fields,
             escalation_fields: escalation_fields,
             adapter_hooks: adapter_hooks,
             policy_bundles: policy_bundles,
             provider_result_map_value_keys: provider_result_map_value_keys,
             known_limits: known_limits
           } = Policy.capabilities()

    assert classifications == [
             "auto_approvable",
             "operator_review_required",
             "blocked_by_policy"
           ]

    assert cadence_import_statuses ==
             OrbitalDynamics.CadenceImport.capability().cadence_import_statuses

    assert Policy.capabilities().direction_aliases["up_link"] == "uplink"
    assert Policy.capabilities().direction_aliases["cmd"] == "command"
    assert Policy.capabilities().direction_aliases["track_ing"] == "tracking"
    assert Policy.capabilities().direction_aliases["healthcheck"] == "health_check"

    assert :requirement_types in match_dimensions
    assert :risk_types in match_dimensions
    assert :spacecraft_ids in match_dimensions
    assert :target_ids in match_dimensions
    assert :locked in match_dimensions
    assert :degraded in match_dimensions
    assert :payload_available in match_dimensions
    assert :antenna_available in match_dimensions
    assert :approval_statuses in match_dimensions
    assert :statuses in match_dimensions
    assert :policy_classification in match_dimensions
    assert :policy_classifications in match_dimensions
    assert :resource_pressure_statuses in match_dimensions
    assert :resource_pressure_types in match_dimensions
    assert :resource_source_qualities in match_dimensions
    assert :resource_trust_boundary_statuses in match_dimensions
    assert :first_resource_pressure_kinds in match_dimensions
    assert :direction in match_dimensions
    assert :ground_station_ids in match_dimensions
    assert :station_ids in match_dimensions
    assert :station_contention_statuses in match_dimensions
    assert :station_reservation_id in match_dimensions
    assert :station_reservation_ids in match_dimensions
    assert :station_reserved_by in match_dimensions
    assert :station_reserved_bys in match_dimensions
    assert :station_reservation_statuses in match_dimensions
    assert :station_reservation_match_status in match_dimensions
    assert :station_reservation_match_statuses in match_dimensions
    assert :station_calendar_reserved_by in match_dimensions
    assert :station_calendar_reserved_bys in match_dimensions
    assert :station_calendar_reservation_status in match_dimensions
    assert :station_calendar_reservation_statuses in match_dimensions
    assert :station_calendar_entry_ambiguous in match_dimensions
    assert :station_calendar_ambiguous_entry_id in match_dimensions
    assert :station_calendar_ambiguous_entry_ids in match_dimensions
    assert :station_calendar_ambiguous_entry_count_min in match_dimensions
    assert :station_calendar_ambiguous_entry_count_max in match_dimensions
    assert :contention_window_s_min in match_dimensions
    assert :total_contact_duration_s_min in match_dimensions
    assert :overlap_duration_s_min in match_dimensions
    assert :max_concurrent_contacts_min in match_dimensions
    assert :overlap_contact_pair_count_min in match_dimensions
    assert :station_calendar_trust_boundary_statuses in match_dimensions
    assert :station_calendar_direction in match_dimensions
    assert :station_calendar_directions in match_dimensions
    assert :resource_scopes in match_dimensions
    assert :selection_reasons in match_dimensions
    assert :selected_priority_sources in match_dimensions
    assert :priority_field_without_numeric_evidence in match_dimensions
    assert :priority_fields_without_numeric_evidence_count_min in match_dimensions
    assert :priority_fields_without_numeric_evidence in match_dimensions
    assert :resolution_statuses in match_dimensions
    assert :resolution_issues in match_dimensions
    assert :station_calendar_provider_ids in match_dimensions
    assert :station_calendar_provider_entry_ids in match_dimensions
    assert :station_calendar_reservation_ids in match_dimensions
    assert :required_operator_action in match_dimensions
    assert :required_operator_actions in match_dimensions
    assert :operator_action_reason in match_dimensions
    assert :operator_action_reasons in match_dimensions
    assert :allocation_status in match_dimensions
    assert :allocation_statuses in match_dimensions
    assert :effective_allocation_status in match_dimensions
    assert :effective_allocation_statuses in match_dimensions
    assert :allocation_reason in match_dimensions
    assert :allocation_reasons in match_dimensions
    assert :suppressed_reason in match_dimensions
    assert :suppressed_reasons in match_dimensions
    assert :resource_blocking_dimension in match_dimensions
    assert :resource_blocking_dimensions in match_dimensions
    assert :transition_decision in match_dimensions
    assert :transition_decisions in match_dimensions
    assert :application_status in match_dimensions
    assert :application_statuses in match_dimensions
    assert :planned_protection_decision in match_dimensions
    assert :planned_protection_decisions in match_dimensions
    assert :planned_protection_category in match_dimensions
    assert :planned_protection_categories in match_dimensions
    assert :timeline_integrity_status in match_dimensions
    assert :timeline_integrity_statuses in match_dimensions
    assert :timeline_integrity_issue_type in match_dimensions
    assert :timeline_integrity_issue_types in match_dimensions
    assert :source_timeline_integrity_status in match_dimensions
    assert :source_timeline_integrity_statuses in match_dimensions
    assert :source_timeline_integrity_issue_type in match_dimensions
    assert :source_timeline_integrity_issue_types in match_dimensions
    assert :replacement_timeline_integrity_status in match_dimensions
    assert :replacement_timeline_integrity_statuses in match_dimensions
    assert :replacement_timeline_integrity_issue_type in match_dimensions
    assert :replacement_timeline_integrity_issue_types in match_dimensions
    assert :source_protection_decision in match_dimensions
    assert :source_protection_decisions in match_dimensions
    assert :source_protection_category in match_dimensions
    assert :source_protection_categories in match_dimensions
    assert :replacement_protection_decision in match_dimensions
    assert :replacement_protection_decisions in match_dimensions
    assert :replacement_protection_category in match_dimensions
    assert :replacement_protection_categories in match_dimensions
    assert :review_queue in match_dimensions
    assert :review_queues in match_dimensions
    assert :review_queue_key in match_dimensions
    assert :review_queue_keys in match_dimensions
    assert :cadence_import_status in match_dimensions
    assert :cadence_import_statuses in match_dimensions
    assert :contact_success in match_dimensions
    assert :contact_result in match_dimensions
    assert :contact_results in match_dimensions
    assert :actual_completion_fraction_min in match_dimensions
    assert :actual_completion_fraction_max in match_dimensions
    assert :contact_success_factor_min in match_dimensions
    assert :contact_success_factor_max in match_dimensions
    assert :command_success in match_dimensions
    assert :command_result in match_dimensions
    assert :command_results in match_dimensions
    assert :command_success_factor_min in match_dimensions
    assert :command_success_factor_max in match_dimensions
    assert :observation_success_factor_min in match_dimensions
    assert :observation_success_factor_max in match_dimensions
    assert :observation_result in match_dimensions
    assert :observation_results in match_dimensions
    assert :maneuver_success_factor_min in match_dimensions
    assert :maneuver_success_factor_max in match_dimensions
    assert :maneuver_result in match_dimensions
    assert :maneuver_results in match_dimensions
    assert :blocked_risk_types in fallback_policy_fields
    assert :escalation_level in escalation_fields
    assert :escalation_queue in escalation_fields
    assert :required_authority in escalation_fields
    assert :sla_s in escalation_fields
    assert :organization_policy_bundle in adapter_hooks
    assert :inline_policy_bundle in adapter_hooks
    assert "contact_command_review_v1" in policy_bundles
    assert "command_contact_authority_v1" in policy_bundles
    assert "conservative_ops_v1" in policy_bundles
    assert "degraded_payload_guard_v1" in policy_bundles
    assert "ground_network_allocation_v1" in policy_bundles
    assert "maneuver_authority_v1" in policy_bundles
    assert "mission_ops_escalation_v1" in policy_bundles
    assert "operator_review_queue_authority_v1" in policy_bundles
    assert "resource_projection_authority_v1" in policy_bundles
    assert "timeline_protection_v1" in policy_bundles
    assert "result" in provider_result_map_value_keys
    assert "provider_status" in provider_result_map_value_keys
    assert "provider_outcome" in provider_result_map_value_keys
    assert "diagnostics" in provider_result_map_value_keys
    assert :artifact_classification_only in known_limits
    assert :no_command_execution in known_limits
    assert :no_multi_step_workflow_execution in known_limits
    refute :policy_bundles_not_versioned in known_limits
  end

  test "exposes versioned approval policy bundles" do
    assert %{
             "schema_contract" => "policy_bundle.v1",
             "id" => "contact_command_review_v1",
             "approval_policy" => %{
               "action_rules" => [_contact_rule, _command_rule, _invalid_input_rule]
             }
           } = Policy.bundle!("contact_command_review_v1")

    assert Enum.map(Policy.bundles(), & &1["id"]) == [
             "command_contact_authority_v1",
             "conservative_ops_v1",
             "contact_command_review_v1",
             "default_v1",
             "degraded_payload_guard_v1",
             "ground_network_allocation_v1",
             "maneuver_authority_v1",
             "mission_ops_escalation_v1",
             "operator_review_queue_authority_v1",
             "resource_projection_authority_v1",
             "timeline_protection_v1"
           ]

    assert Enum.all?(Policy.bundles(), fn bundle ->
             match?(
               {:ok, %{"schema_contract" => "policy_bundle.v1"}},
               Schema.validate_artifact(bundle)
             )
           end)

    assert_raise ArgumentError, ~r/unknown policy bundle/, fn ->
      Policy.bundle!("missing_bundle")
    end
  end

  test "public facades expose policy bundles and decisions" do
    requirement = %{
      "activity_id" => "dl_1",
      "activity_type" => "downlink",
      "action" => "schedule_contact",
      "requirement_type" => "ground_station_unavailable",
      "activity_context" => %{
        "station_availability" => "unavailable",
        "ground_station_id" => "equator_prime"
      }
    }

    assert OrbitalDynamics.policy_bundles() == Policy.bundles()

    assert OrbitalDynamics.policy_bundle!("ground_network_allocation_v1") ==
             Policy.bundle!("ground_network_allocation_v1")

    assert OrbitalDynamics.policy_bundle_artifact!("ground_network_allocation_v1") ==
             Policy.bundle_artifact!("ground_network_allocation_v1")

    assert Policy.bundle_artifact!("ground_network_allocation_v1")["model_limits"] ==
             Policy.capabilities().known_limits |> Enum.map(&to_string/1)

    assert OrbitalDynamics.policy_bundle_artifacts() == Policy.bundle_artifacts()

    assert OrbitalDynamics.organization_policy_bundle("org_ops_v1", %{}) ==
             Policy.organization_policy_bundle("org_ops_v1", %{})

    assert Policy.organization_policy_bundle("org_ops_v1", %{})["model_limits"] ==
             Policy.capabilities().known_limits |> Enum.map(&to_string/1)

    assert OrbitalDynamics.normalize_approval_policy(%{bundle: "ground_network_allocation_v1"}) ==
             Policy.normalize_approval_policy(%{bundle: "ground_network_allocation_v1"})

    assert OrbitalDynamics.policy_decision(
             [requirement],
             [],
             %{"id" => "station_calendar", "events" => []},
             %{},
             %{bundle: "ground_network_allocation_v1"}
           ) ==
             Policy.decide(
               [requirement],
               [],
               %{"id" => "station_calendar", "events" => []},
               %{},
               %{bundle: "ground_network_allocation_v1"}
             )

    {_status, _requirements, _matches, decision} =
      OrbitalDynamics.policy_decision(
        [requirement],
        [],
        %{"id" => "station_calendar", "events" => []},
        %{},
        %{bundle: "ground_network_allocation_v1"}
      )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)

    assert decision["model_limits"] ==
             Policy.capabilities().known_limits |> Enum.map(&to_string/1)
  end

  test "supports inline organization-specific policy bundles" do
    bundle =
      Policy.organization_policy_bundle(
        "org:mission_ops:authority:v1",
        %{
          auto_approvable_risk_limit: 0,
          auto_approvable_approval_count_limit: 0,
          operator_review_risk_limit: 1,
          blocked_risk_types: [],
          action_rules: [
            %{
              id: "org_command_station_review",
              requirement_types: ["command_review"],
              station_ids: ["equator_prime"],
              classification: "operator_review_required",
              reason: "organization requires equator prime command review",
              escalation_queue: "org_mission_ops",
              escalation_role: "duty_officer",
              required_authority: "org_command_authority",
              sla_s: 300
            }
          ]
        },
        organization_id: "mission_ops",
        adapter: "example_policy_adapter",
        policy_source: "operator_config"
      )

    assert {:ok, %{"schema_contract" => "policy_bundle.v1"}} = Schema.validate_artifact(bundle)

    requirement = %{
      "activity_id" => "cmd_1",
      "activity_type" => "command",
      "action" => "review_command",
      "requirement_type" => "command_review",
      "activity_context" => %{"station_id" => "equator_prime", "direction" => "command"}
    }

    {status, [enriched_requirement], matches, decision} =
      Policy.decide([requirement], [], %{"id" => "branch", "events" => []}, %{}, %{
        "policy_bundle" => bundle
      })

    assert status == "operator_review_required"
    assert enriched_requirement["policy_classification"] == "operator_review_required"

    assert [
             %{
               "rule_id" => "org_command_station_review",
               "ground_station_id" => "equator_prime",
               "escalation_queue" => "org_mission_ops",
               "required_authority" => "org_command_authority",
               "policy_bundle_provenance_source" => "organization_policy_adapter",
               "policy_bundle_adapter" => "example_policy_adapter",
               "policy_bundle_organization_id" => "mission_ops",
               "policy_bundle_policy_source" => "operator_config",
               "policy_bundle_trust_boundary" => "organization_policy_adapter"
             }
           ] = matches

    assert %{
             "schema_contract" => "policy_decision.v1",
             "policy_bundle_id" => "org:mission_ops:authority:v1",
             "policy_bundle_provenance" => %{
               "source" => "organization_policy_adapter",
               "adapter" => "example_policy_adapter",
               "organization_id" => "mission_ops",
               "policy_source" => "operator_config",
               "trust_boundary" => "organization_policy_adapter"
             },
             "escalations" => [
               %{
                 "rule_id" => "org_command_station_review",
                 "escalation_queue" => "org_mission_ops"
               }
             ]
           } = decision

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "normalizes clean numeric string runtime policy thresholds" do
    normalized =
      Policy.normalize_approval_policy(%{
        "auto_approvable_risk_limit" => "0",
        "auto_approvable_approval_count_limit" => "0",
        "operator_review_risk_limit" => "2",
        "action_rules" => [
          %{
            "id" => "low_command_confidence_review",
            "requirement_types" => ["command_review"],
            "command_success_factor_max" => "0.3",
            "classification" => "operator_review_required",
            "escalation_queue" => "mission_operations",
            "sla_s" => "600"
          },
          %{
            "id" => "ambiguous_station_review",
            "station_calendar_ambiguous_entry_count_min" => "1",
            "contention_window_s_min" => "120",
            "total_contact_duration_s_min" => "300.5",
            "overlap_duration_s_min" => "45.25",
            "max_concurrent_contacts_min" => "3",
            "overlap_contact_pair_count_min" => "2",
            "classification" => "operator_review_required"
          }
        ]
      })

    assert normalized["auto_approvable_risk_limit"] == 0
    assert normalized["auto_approvable_approval_count_limit"] == 0
    assert normalized["operator_review_risk_limit"] == 2

    rules_by_id = Map.new(normalized["action_rules"], &{&1["id"], &1})

    assert rules_by_id["low_command_confidence_review"]["command_success_factor_max"] == 0.3
    assert rules_by_id["low_command_confidence_review"]["sla_s"] == 600.0

    assert rules_by_id["ambiguous_station_review"]["station_calendar_ambiguous_entry_count_min"] ==
             1

    assert rules_by_id["ambiguous_station_review"]["contention_window_s_min"] == 120.0
    assert rules_by_id["ambiguous_station_review"]["total_contact_duration_s_min"] == 300.5
    assert rules_by_id["ambiguous_station_review"]["overlap_duration_s_min"] == 45.25
    assert rules_by_id["ambiguous_station_review"]["max_concurrent_contacts_min"] == 3
    assert rules_by_id["ambiguous_station_review"]["overlap_contact_pair_count_min"] == 2

    {status, [requirement], matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "cmd_low_confidence",
            "activity_type" => "command",
            "action" => "approve_command_window",
            "requirement_type" => "command_review",
            "activity_context" => %{
              "command_success_factor" => 0.25,
              "command_success_factor_source" => "provider_command_feedback"
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        normalized
      )

    assert status == "operator_review_required"
    assert requirement["policy_classification"] == "operator_review_required"

    assert [
             %{
               "rule_id" => "low_command_confidence_review",
               "command_success_factor" => 0.25,
               "command_success_factor_source" => "provider_command_feedback",
               "sla_s" => 600.0
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "drops nil provider tokens from list-valued policy selectors" do
    normalized =
      Policy.normalize_approval_policy(%{
        action_rules: [
          %{
            id: "tracking_outage_review",
            directions: [nil, "Track-ing"],
            station_availabilities: [nil, :reserved],
            classification: "operator_review_required"
          }
        ]
      })

    assert [
             %{
               "id" => "tracking_outage_review",
               "directions" => ["tracking"],
               "station_availabilities" => ["reserved"]
             }
           ] = normalized["action_rules"]
  end

  test "organization policy bundles normalize clean numeric string thresholds" do
    bundle =
      Policy.organization_policy_bundle(
        "org_numeric_policy_v1",
        %{
          auto_approvable_risk_limit: "0",
          auto_approvable_approval_count_limit: "0",
          operator_review_risk_limit: "1",
          action_rules: [
            %{
              id: "org_low_maneuver_confidence_review",
              maneuver_success_factor_max: "0.8",
              station_calendar_ambiguous_entry_count_max: "2",
              classification: "operator_review_required",
              escalation_queue: "flight_dynamics",
              required_authority: "maneuver_authority",
              sla_s: "900"
            }
          ]
        },
        organization_id: "mission_ops",
        adapter: "example_policy_adapter"
      )

    assert {:ok, %{"schema_contract" => "policy_bundle.v1"}} = Schema.validate_artifact(bundle)

    assert %{
             "auto_approvable_risk_limit" => 0,
             "auto_approvable_approval_count_limit" => 0,
             "operator_review_risk_limit" => 1,
             "action_rules" => [
               %{
                 "maneuver_success_factor_max" => 0.8,
                 "station_calendar_ambiguous_entry_count_max" => 2,
                 "required_authority" => "maneuver_authority",
                 "sla_s" => 900.0
               }
             ]
           } = bundle["approval_policy"]
  end

  test "rejects malformed inline policy bundles" do
    assert_raise ArgumentError, ~r/inline policy bundle requires a non-empty id/, fn ->
      Policy.normalize_approval_policy(%{"policy_bundle" => %{"approval_policy" => %{}}})
    end

    assert_raise ArgumentError, ~r/inline policy bundle requires an approval_policy map/, fn ->
      Policy.normalize_approval_policy(%{"policy_bundle" => %{"id" => "org_policy"}})
    end
  end

  test "rejects malformed runtime action rule fields before classification" do
    assert_raise ArgumentError, ~r/policy action rule 1 must be a map/, fn ->
      Policy.normalize_approval_policy(%{action_rules: [:bad_rule]})
    end

    assert_raise ArgumentError, ~r/policy action rule id must be a stable identifier/, fn ->
      Policy.normalize_approval_policy(%{
        action_rules: [
          %{
            id: "bad rule id",
            requirement_types: ["contact_schedule_change"],
            classification: "operator_review_required"
          }
        ]
      })
    end

    assert_raise ArgumentError, ~r/policy action rule ids must be unique: duplicate_rule/, fn ->
      Policy.normalize_approval_policy(%{
        action_rules: [
          %{
            id: "duplicate_rule",
            requirement_types: ["contact_schedule_change"],
            classification: "operator_review_required"
          },
          %{
            id: "duplicate_rule",
            requirement_types: ["command_review"],
            classification: "blocked_by_policy"
          }
        ]
      })
    end

    assert_raise ArgumentError,
                 ~r/policy action rule contact_success_factor_max must be a number from 0.0 to 1.0/,
                 fn ->
                   Policy.decide(
                     [
                       %{
                         "activity_id" => "contact_1",
                         "activity_type" => "downlink",
                         "action" => "schedule_contact",
                         "requirement_type" => "contact_schedule_change",
                         "activity_context" => %{"contact_success_factor" => 0.25}
                       }
                     ],
                     [],
                     %{"id" => "branch", "events" => []},
                     %{},
                     %{
                       action_rules: [
                         %{
                           id: "bad_contact_threshold",
                           requirement_types: ["contact_schedule_change"],
                           contact_success_factor_max: "low",
                           classification: "operator_review_required"
                         }
                       ]
                     }
                   )
                 end

    assert_raise ArgumentError,
                 ~r/policy action rule station_calendar_ambiguous_entry_count_min must be a non-negative integer/,
                 fn ->
                   Policy.normalize_approval_policy(%{
                     action_rules: [
                       %{
                         id: "bad_ambiguity_count",
                         station_calendar_ambiguous_entry_count_min: -1,
                         classification: "operator_review_required"
                       }
                     ]
                   })
                 end

    assert_raise ArgumentError,
                 ~r/policy action rule overlap_duration_s_min must be a non-negative number/,
                 fn ->
                   Policy.normalize_approval_policy(%{
                     action_rules: [
                       %{
                         id: "bad_overlap_duration",
                         overlap_duration_s_min: -0.1,
                         classification: "operator_review_required"
                       }
                     ]
                   })
                 end

    assert_raise ArgumentError, ~r/policy action rule command_success must be a boolean/, fn ->
      Policy.normalize_approval_policy(%{
        action_rules: [
          %{
            id: "bad_command_boolean",
            requirement_types: ["command_review"],
            command_success: "false",
            classification: "operator_review_required"
          }
        ]
      })
    end

    assert_raise ArgumentError, ~r/policy action rule action must be a non-empty string/, fn ->
      Policy.normalize_approval_policy(%{
        action_rules: [
          %{
            id: "bad_action_field",
            action: 42,
            classification: "operator_review_required"
          }
        ]
      })
    end

    assert_raise ArgumentError,
                 ~r/policy action rule requirement_types must be a list of non-empty strings/,
                 fn ->
                   Policy.normalize_approval_policy(%{
                     action_rules: [
                       %{
                         id: "bad_requirement_types",
                         requirement_types: ["command_review", 42],
                         classification: "operator_review_required"
                       }
                     ]
                   })
                 end

    assert_raise ArgumentError,
                 ~r/policy action rule review_queue_keys must be a list of non-empty strings/,
                 fn ->
                   Policy.normalize_approval_policy(%{
                     action_rules: [
                       %{
                         id: "bad_review_queue_keys",
                         review_queue_keys: ["ok", 42],
                         classification: "operator_review_required"
                       }
                     ]
                   })
                 end

    assert_raise ArgumentError,
                 ~r/policy action rule cadence_import_statuses must be a list of non-empty strings/,
                 fn ->
                   Policy.normalize_approval_policy(%{
                     action_rules: [
                       %{
                         id: "bad_cadence_import_statuses",
                         cadence_import_statuses: ["missing", 42],
                         classification: "operator_review_required"
                       }
                     ]
                   })
                 end

    assert_raise ArgumentError,
                 ~r/policy action rule cadence_import_status must be one of/,
                 fn ->
                   Policy.normalize_approval_policy(%{
                     action_rules: [
                       %{
                         id: "bad_cadence_import_status",
                         cadence_import_status: "provider_custom",
                         classification: "operator_review_required"
                       }
                     ]
                   })
                 end

    assert_raise ArgumentError,
                 ~r/policy action rule cadence_import_statuses must use values from/,
                 fn ->
                   Policy.normalize_approval_policy(%{
                     action_rules: [
                       %{
                         id: "bad_cadence_import_status_value",
                         cadence_import_statuses: ["missing", "provider_custom"],
                         classification: "operator_review_required"
                       }
                     ]
                   })
                 end

    assert_raise ArgumentError,
                 ~r/policy action rule policy_classification must be one of/,
                 fn ->
                   Policy.normalize_approval_policy(%{
                     action_rules: [
                       %{
                         id: "bad_policy_classification",
                         event_type: "downlink_completion_gap",
                         policy_classification: "provider_custom",
                         classification: "operator_review_required"
                       }
                     ]
                   })
                 end

    assert_raise ArgumentError,
                 ~r/policy action rule policy_classifications must use values from/,
                 fn ->
                   Policy.normalize_approval_policy(%{
                     action_rules: [
                       %{
                         id: "bad_policy_classifications",
                         event_type: "downlink_completion_gap",
                         policy_classifications: ["blocked_by_policy", "provider_custom"],
                         classification: "operator_review_required"
                       }
                     ]
                   })
                 end

    assert_raise ArgumentError, ~r/policy action rule sla_s must be a number/, fn ->
      Policy.normalize_approval_policy(%{
        action_rules: [
          %{
            id: "bad_sla",
            requirement_types: ["command_review"],
            escalation_queue: "mission_operations",
            sla_s: "soon",
            classification: "operator_review_required"
          }
        ]
      })
    end
  end

  test "rejects malformed runtime fallback policy fields before classification" do
    assert_raise ArgumentError,
                 ~r/approval policy auto_approvable_risk_limit must be a non-negative integer/,
                 fn ->
                   Policy.normalize_approval_policy(%{auto_approvable_risk_limit: "zero"})
                 end

    assert_raise ArgumentError,
                 ~r/approval policy operator_review_risk_limit must be a non-negative integer/,
                 fn ->
                   Policy.decide([], [], %{"id" => "branch", "events" => []}, %{}, %{
                     operator_review_risk_limit: -1
                   })
                 end

    assert_raise ArgumentError,
                 ~r/approval policy blocked_risk_types must be a list of strings/,
                 fn ->
                   Policy.normalize_approval_policy(%{blocked_risk_types: "no_viable_downlink"})
                 end

    assert_raise ArgumentError,
                 ~r/approval policy blocked_risk_types must be a list of strings/,
                 fn ->
                   Policy.normalize_approval_policy(%{blocked_risk_types: ["safe", 42]})
                 end
  end

  test "normalizes struct-backed approval policies" do
    {status, _requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "dl_1",
            "activity_type" => "downlink",
            "action" => "schedule_contact",
            "requirement_type" => "ground_station_unavailable",
            "activity_context" => %{
              "station_availability" => "unavailable",
              "ground_station_id" => "equator_prime"
            }
          }
        ],
        [],
        %{"id" => "station_calendar", "events" => []},
        %{},
        %StructBackedPolicy{}
      )

    assert status == "blocked_by_policy"
    assert decision["policy_bundle_id"] == "ground_network_allocation_v1"
    assert Enum.any?(matches, &(&1["rule_id"] == "unavailable_station_contact_block"))
  end

  test "rejects invalid policy bundle contracts" do
    invalid_bundle =
      Policy.bundle!("contact_command_review_v1")
      |> put_in(["approval_policy", "action_rules", Access.at(0), "classification"], "maybe")

    assert {:error, report} = Schema.validate_artifact(invalid_bundle)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[0].classification")
           )

    duplicate_rule_bundle =
      Policy.bundle!("contact_command_review_v1")
      |> put_in(
        ["approval_policy", "action_rules", Access.at(1), "id"],
        get_in(Policy.bundle!("contact_command_review_v1"), [
          "approval_policy",
          "action_rules",
          Access.at(0),
          "id"
        ])
      )

    assert {:error, duplicate_rule_report} = Schema.validate_artifact(duplicate_rule_bundle)

    assert Enum.any?(
             duplicate_rule_report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[1].id" and
                 &1["message"] == "must be unique within action_rules")
           )
  end

  test "rejects invalid degraded payload policy rule fields" do
    invalid_bundle =
      Policy.bundle!("degraded_payload_guard_v1")
      |> put_in(["approval_policy", "action_rules", Access.at(0), "degraded"], "true")
      |> put_in(["approval_policy", "action_rules", Access.at(0), "spacecraft_ids"], [42])
      |> put_in(["approval_policy", "action_rules", Access.at(0), "target_ids"], [42])
      |> put_in(["approval_policy", "action_rules", Access.at(1), "payload_available"], "false")
      |> put_in(["approval_policy", "action_rules", Access.at(2), "antenna_available"], "false")
      |> put_in(["approval_policy", "action_rules", Access.at(3), "requirement_type"], [
        "command_review"
      ])

    assert {:error, report} = Schema.validate_artifact(invalid_bundle)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[0].degraded")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[0].spacecraft_ids[0]")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[0].target_ids[0]")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[1].payload_available")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[2].antenna_available")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[3].requirement_type")
           )
  end

  test "rejects invalid escalation policy rule fields" do
    invalid_bundle =
      Policy.bundle!("mission_ops_escalation_v1")
      |> put_in(["approval_policy", "action_rules", Access.at(0), "sla_s"], "soon")
      |> put_in(["approval_policy", "action_rules", Access.at(1), "escalation_queue"], 42)

    assert {:error, report} = Schema.validate_artifact(invalid_bundle)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[0].sla_s")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[1].escalation_queue")
           )
  end

  test "rejects invalid ground network allocation policy rule fields" do
    invalid_bundle =
      Policy.bundle!("ground_network_allocation_v1")
      |> put_in(["approval_policy", "action_rules", Access.at(0), "station_availabilities"], [
        42
      ])
      |> put_in(["approval_policy", "action_rules", Access.at(1), "station_ids"], [
        "equator_prime",
        42
      ])
      |> put_in(["approval_policy", "action_rules", Access.at(2), "capacity_fraction_max"], "low")
      |> put_in(
        ["approval_policy", "action_rules", Access.at(3), "actual_completion_fraction_max"],
        "low"
      )
      |> put_in(
        [
          "approval_policy",
          "action_rules",
          Access.at(4),
          "station_calendar_trust_boundary_status"
        ],
        42
      )
      |> put_in(
        ["approval_policy", "action_rules", Access.at(5), "overlap_duration_s_min"],
        -1.0
      )
      |> put_in(
        ["approval_policy", "action_rules", Access.at(6), "max_concurrent_contacts_min"],
        1.5
      )
      |> put_in(
        [
          "approval_policy",
          "action_rules",
          Access.at(7),
          "priority_fields_without_numeric_evidence_count_min"
        ],
        -1
      )

    assert {:error, report} = Schema.validate_artifact(invalid_bundle)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[0].station_availabilities[0]")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[1].station_ids[1]")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[2].capacity_fraction_max")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[3].actual_completion_fraction_max")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.approval_policy.action_rules[4].station_calendar_trust_boundary_status")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[5].overlap_duration_s_min")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[6].max_concurrent_contacts_min")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.approval_policy.action_rules[7].priority_fields_without_numeric_evidence_count_min")
           )
  end

  test "rejects invalid contact and command confidence policy rule fields" do
    invalid_bundle =
      Policy.bundle!("command_contact_authority_v1")
      |> put_in(["approval_policy", "action_rules", Access.at(1), "command_success"], "false")
      |> put_in(
        ["approval_policy", "action_rules", Access.at(2), "command_success_factor_max"],
        "low"
      )
      |> put_in(["approval_policy", "action_rules", Access.at(3), "command_results"], [
        "rejected",
        42
      ])
      |> put_in(["approval_policy", "action_rules", Access.at(4), "contact_success"], "false")
      |> put_in(
        ["approval_policy", "action_rules", Access.at(5), "contact_success_factor_max"],
        "low"
      )
      |> put_in(["approval_policy", "action_rules", Access.at(6), "contact_results"], [
        "dropped",
        42
      ])

    assert {:error, report} = Schema.validate_artifact(invalid_bundle)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[1].command_success")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[2].command_success_factor_max")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[3].command_results[1]")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[4].contact_success")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[5].contact_success_factor_max")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[6].contact_results[1]")
           )
  end

  test "rejects out-of-range contact and command confidence policy thresholds" do
    invalid_bundle =
      Policy.bundle!("command_contact_authority_v1")
      |> put_in(
        ["approval_policy", "action_rules", Access.at(2), "command_success_factor_max"],
        1.2
      )
      |> put_in(
        ["approval_policy", "action_rules", Access.at(5), "contact_success_factor_max"],
        -0.1
      )

    assert {:error, report} = Schema.validate_artifact(invalid_bundle)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[2].command_success_factor_max")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[5].contact_success_factor_max")
           )
  end

  test "rejects invalid observation and maneuver confidence policy rule fields" do
    invalid_bundle =
      Policy.bundle!("maneuver_authority_v1")
      |> put_in(
        ["approval_policy", "action_rules", Access.at(0), "observation_success_factor_max"],
        "low"
      )
      |> put_in(
        ["approval_policy", "action_rules", Access.at(1), "maneuver_success_factor_min"],
        "high"
      )
      |> put_in(["approval_policy", "action_rules", Access.at(3), "maneuver_results"], [
        "failed",
        42
      ])

    assert {:error, report} = Schema.validate_artifact(invalid_bundle)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.approval_policy.action_rules[0].observation_success_factor_max")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[1].maneuver_success_factor_min")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[3].maneuver_results[1]")
           )
  end

  test "rejects out-of-range observation and maneuver confidence policy thresholds" do
    invalid_bundle =
      Policy.bundle!("maneuver_authority_v1")
      |> put_in(
        ["approval_policy", "action_rules", Access.at(0), "observation_success_factor_max"],
        1.2
      )
      |> put_in(
        ["approval_policy", "action_rules", Access.at(1), "maneuver_success_factor_min"],
        -0.1
      )

    assert {:error, report} = Schema.validate_artifact(invalid_bundle)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] ==
                 "$.approval_policy.action_rules[0].observation_success_factor_max")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[1].maneuver_success_factor_min")
           )
  end

  test "classifies approval requirements with action rules" do
    policy = %{
      action_rules: [
        %{
          id: "contact_auto",
          action: "approve_moved_contact",
          classification: "auto_approvable",
          reason: "contact move has low operational risk"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "dl_1",
            "activity_type" => "downlink",
            "action" => "approve_moved_contact",
            "reason" => "missed contact"
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "auto_approvable"
    assert [%{"policy_classification" => "auto_approvable"}] = requirements
    assert [%{"rule_id" => "contact_auto"}] = matches
    assert decision["schema_contract"] == "policy_decision.v1"
    assert decision["classification"] == "auto_approvable"
  end

  test "matches approval requirements by deterministic review queue context" do
    review_queue_key =
      "resource_projection_review|review_resource_projection|operator_review_required"

    policy = %{
      action_rules: [
        %{
          id: "resource_projection_queue_priority",
          review_queue_keys: [review_queue_key],
          classification: "operator_review_required",
          reason: "resource projection review queue requires resource-planning triage",
          escalation_queue: "resource_planning",
          escalation_role: "resource_planner"
        }
      ]
    }

    {status, [requirement], matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "review_resource_projection",
            "activity_type" => "operator_review",
            "action" => "route_review_queue",
            "requirement_type" => "operator_review_queue",
            "activity_context" => %{
              "review_queue" => "resource_projection_review",
              "review_queue_key" => review_queue_key
            }
          }
        ],
        [],
        %{"id" => "queue_policy_branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"
    assert requirement["policy_classification"] == "operator_review_required"

    assert [
             %{
               "rule_id" => "resource_projection_queue_priority",
               "review_queue" => "resource_projection_review",
               "review_queue_key" => ^review_queue_key,
               "escalation_queue" => "resource_planning"
             }
           ] = matches

    assert %{
             "schema_contract" => "policy_decision.v1",
             "classification" => "operator_review_required",
             "rule_matches" => ^matches
           } = decision

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches approval requirements by Cadence import status" do
    {status, [requirement], matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "cmd_1",
            "activity_type" => "command",
            "action" => "review_command",
            "requirement_type" => "command_review",
            "activity_context" => %{
              "direction" => "command",
              "cadence_import_status" => "missing"
            }
          }
        ],
        [],
        %{"id" => "cadence_import_policy_branch", "events" => []},
        %{},
        %{
          action_rules: [
            %{
              id: "missing_import_boundary",
              cadence_import_statuses: ["missing", "invalid"],
              classification: "operator_review_required",
              reason: "missing Cadence import metadata requires adapter review",
              escalation_queue: "mission_planning",
              escalation_role: "mission_planner",
              required_authority: "cadence_import_boundary_authority"
            }
          ]
        }
      )

    assert status == "operator_review_required"
    assert requirement["policy_classification"] == "operator_review_required"

    assert [
             %{
               "rule_id" => "missing_import_boundary",
               "cadence_import_status" => "missing",
               "escalation_queue" => "mission_planning",
               "required_authority" => "cadence_import_boundary_authority"
             }
           ] = matches

    assert %{
             "schema_contract" => "policy_decision.v1",
             "classification" => "operator_review_required",
             "rule_matches" => ^matches
           } = decision

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches approval requirements from list-valued review and import context" do
    review_queue_key =
      "resource_projection_review|review_resource_projection|operator_review_required"

    {status, [requirement], matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "review_resource_projection",
            "activity_type" => "operator_review",
            "action" => "route_review_queue",
            "requirement_type" => "operator_review_queue",
            "activity_context" => %{
              "review_queues" => ["resource_projection_review", "review_resource_projection"],
              "review_queue_keys" => [review_queue_key],
              "cadence_import_statuses" => ["missing", "invalid"],
              "statuses" => ["queued", "pending"],
              "approval_statuses" => ["operator_review_required"]
            }
          }
        ],
        [],
        %{"id" => "queue_policy_branch", "events" => []},
        %{},
        %{
          action_rules: [
            %{
              id: "list_context_review_queue_priority",
              review_queue: "resource_projection_review",
              review_queue_key: review_queue_key,
              cadence_import_status: "missing",
              statuses: ["pending"],
              approval_status: "operator_review_required",
              classification: "operator_review_required",
              reason: "list-valued review/import context requires triage"
            }
          ]
        }
      )

    assert status == "operator_review_required"
    assert requirement["policy_classification"] == "operator_review_required"

    assert [
             %{
               "rule_id" => "list_context_review_queue_priority",
               "review_queues" => ["resource_projection_review", "review_resource_projection"],
               "review_queue_keys" => [^review_queue_key],
               "cadence_import_statuses" => ["missing", "invalid"],
               "statuses" => ["queued", "pending"],
               "approval_statuses" => ["operator_review_required"]
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "operator review queue authority bundle routes deterministic review queues" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "review_resource_projection",
            "activity_type" => "operator_review",
            "action" => "review_resource_projection",
            "requirement_type" => "operator_review_queue",
            "activity_context" => %{
              "review_queue" => "review_resource_projection",
              "review_queue_key" =>
                "resource_projection_review|review_resource_projection|operator_review_required"
            }
          },
          %{
            "activity_id" => "review_invalid_resource_filter_summary",
            "activity_type" => "operator_review",
            "action" => "review_invalid_resource_filter_summary",
            "requirement_type" => "operator_review_queue",
            "activity_context" => %{
              "review_queue" => "review_invalid_resource_filter_summary",
              "review_queue_key" =>
                "resource_suppression|review_invalid_resource_filter_summary|operator_review_required"
            }
          },
          %{
            "activity_id" => "review_invalid_resource_projection_summary",
            "activity_type" => "operator_review",
            "action" => "review_invalid_resource_projection_summary",
            "requirement_type" => "operator_review_queue",
            "activity_context" => %{
              "review_queue" => "review_invalid_resource_projection_summary",
              "review_queue_key" =>
                "resource_projection_review|review_invalid_resource_projection_summary|operator_review_required"
            }
          },
          %{
            "activity_id" => "review_suppressed_candidate",
            "activity_type" => "operator_review",
            "action" => "review_suppressed_candidate",
            "requirement_type" => "operator_review_queue",
            "activity_context" => %{
              "review_queue" => "review_suppressed_candidate",
              "review_queue_key" =>
                "resource_suppression|review_suppressed_candidate|operator_review_required"
            }
          },
          %{
            "activity_id" => "review_policy_escalation",
            "activity_type" => "operator_review",
            "action" => "review_policy_escalation",
            "requirement_type" => "operator_review_queue",
            "activity_context" => %{
              "review_queue" => "review_policy_escalation",
              "review_queue_key" =>
                "policy_escalation|review_policy_escalation|operator_review_required"
            }
          },
          %{
            "activity_id" => "review_timeline_integrity",
            "activity_type" => "operator_review",
            "action" => "review_timeline_integrity",
            "requirement_type" => "operator_review_queue",
            "activity_context" => %{
              "review_queue" => "review_timeline_integrity",
              "review_queue_key" =>
                "realized_feedback|review_timeline_integrity|operator_review_required"
            }
          },
          %{
            "activity_id" => "review_contact_allocation",
            "activity_type" => "operator_review",
            "action" => "review_contact_allocation",
            "requirement_type" => "operator_review_queue",
            "activity_context" => %{
              "review_queue" => "review_contact_allocation",
              "review_queue_key" =>
                "contact_allocation_review|review_contact_allocation|operator_review_required"
            }
          },
          %{
            "activity_id" => "review_maneuver_exception",
            "activity_type" => "operator_review",
            "action" => "review_maneuver_exception",
            "requirement_type" => "operator_review_queue",
            "activity_context" => %{
              "review_queue" => "review_maneuver_exception",
              "review_queue_key" =>
                "realized_feedback|review_maneuver_exception|operator_review_required"
            }
          },
          %{
            "activity_id" => "review_invalid_maneuver_recommendation",
            "activity_type" => "operator_review",
            "action" => "review_invalid_maneuver_recommendation",
            "requirement_type" => "operator_review_queue",
            "activity_context" => %{
              "review_queue" => "review_invalid_maneuver_recommendation",
              "review_queue_key" =>
                "maneuver_review|review_invalid_maneuver_recommendation|operator_review_required"
            }
          }
        ],
        [],
        %{"id" => "queue_policy_branch", "events" => []},
        %{},
        %{policy_bundle_id: "operator_review_queue_authority_v1"}
      )

    assert status == "operator_review_required"
    assert Enum.all?(requirements, &(&1["policy_classification"] == "operator_review_required"))
    assert decision["policy_bundle_id"] == "operator_review_queue_authority_v1"

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "resource_review_queue_authority" and
                 &1["activity_id"] == "review_resource_projection" and
                 &1["review_queue"] == "review_resource_projection" and
                 &1["escalation_queue"] == "mission_planning" and
                 &1["required_authority"] == "resource_model_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "policy_escalation_review_queue_authority" and
                 &1["activity_id"] == "review_policy_escalation" and
                 &1["review_queue_key"] ==
                   "policy_escalation|review_policy_escalation|operator_review_required" and
                 &1["escalation_queue"] == "mission_operations" and
                 &1["required_authority"] == "mission_operations_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "resource_review_queue_authority" and
                 &1["activity_id"] == "review_invalid_resource_filter_summary" and
                 &1["review_queue"] == "review_invalid_resource_filter_summary" and
                 &1["required_authority"] == "resource_model_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "resource_review_queue_authority" and
                 &1["activity_id"] == "review_invalid_resource_projection_summary" and
                 &1["review_queue"] == "review_invalid_resource_projection_summary" and
                 &1["required_authority"] == "resource_model_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "resource_review_queue_authority" and
                 &1["activity_id"] == "review_suppressed_candidate" and
                 &1["review_queue"] == "review_suppressed_candidate" and
                 &1["required_authority"] == "resource_model_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "timeline_review_queue_authority" and
                 &1["activity_id"] == "review_timeline_integrity" and
                 &1["review_queue"] == "review_timeline_integrity" and
                 &1["escalation_queue"] == "mission_planning" and
                 &1["required_authority"] == "timeline_protection_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "ground_network_review_queue_authority" and
                 &1["activity_id"] == "review_contact_allocation" and
                 &1["review_queue"] == "review_contact_allocation" and
                 &1["escalation_queue"] == "ground_network" and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "maneuver_review_queue_authority" and
                 &1["activity_id"] == "review_maneuver_exception" and
                 &1["review_queue"] == "review_maneuver_exception" and
                 &1["escalation_queue"] == "flight_dynamics" and
                 &1["required_authority"] == "maneuver_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "maneuver_review_queue_authority" and
                 &1["activity_id"] == "review_invalid_maneuver_recommendation" and
                 &1["review_queue"] == "review_invalid_maneuver_recommendation" and
                 &1["required_authority"] == "maneuver_authority")
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "classifies observation and maneuver confidence factors with action rules" do
    policy = %{
      action_rules: [
        %{
          id: "low_observation_confidence_review",
          activity_types: ["observe"],
          observation_success_factor_max: 0.6,
          classification: "operator_review_required",
          reason: "low observation confidence requires payload planning review"
        },
        %{
          id: "low_maneuver_confidence_block",
          activity_types: ["impulsive_burn"],
          maneuver_success_factor_max: 0.3,
          classification: "blocked_by_policy",
          reason: "low maneuver confidence blocks branch promotion"
        },
        %{
          id: "failed_observation_result_review",
          activity_types: ["observe"],
          observation_results: ["failed"],
          classification: "operator_review_required",
          reason: "failed observation result requires payload review"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "obs_low",
            "activity_type" => "observe",
            "action" => "approve_observation_reassignment",
            "requirement_type" => "observation_reassignment",
            "activity_context" => %{
              "target_id" => "target_a",
              "observation_success_factor" => 0.5,
              "observation_success_factor_source" =>
                "operational_feedback.observation_success_rate.target"
            }
          },
          %{
            "activity_id" => "obs_ok",
            "activity_type" => "observe",
            "action" => "approve_observation_reassignment",
            "requirement_type" => "observation_reassignment",
            "activity_context" => %{
              "target_id" => "target_b",
              "observation_success_factor" => 0.9,
              "observation_success_factor_source" =>
                "operational_feedback.observation_success_rate.target"
            }
          },
          %{
            "activity_id" => "burn_low",
            "activity_type" => "impulsive_burn",
            "action" => "approve_delayed_maneuver",
            "requirement_type" => "maneuver_timing_change",
            "source_activity_context" => %{
              "maneuver_success_factor" => 0.2,
              "maneuver_success_factor_source" => "realized_activity.completed_fraction"
            }
          },
          %{
            "activity_id" => "obs_failed_result",
            "activity_type" => "observe",
            "action" => "approve_observation_reassignment",
            "requirement_type" => "observation_reassignment",
            "activity_context" => %{
              "target_id" => "target_c",
              "observation_result" => "accepted, failed"
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "blocked_by_policy"

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "obs_low" and
                 &1["policy_classification"] == "operator_review_required")
           )

    refute Enum.any?(
             requirements,
             &(&1["activity_id"] == "obs_ok" and &1["policy_classification"])
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "burn_low" and
                 &1["policy_classification"] == "blocked_by_policy")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "obs_failed_result" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "low_observation_confidence_review" and
                 &1["activity_id"] == "obs_low" and
                 &1["target_id"] == "target_a" and
                 &1["observation_success_factor"] == 0.5 and
                 &1["observation_success_factor_source"] ==
                   "operational_feedback.observation_success_rate.target")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "low_maneuver_confidence_block" and
                 &1["activity_id"] == "burn_low" and
                 &1["maneuver_success_factor"] == 0.2 and
                 &1["maneuver_success_factor_source"] == "realized_activity.completed_fraction")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "failed_observation_result_review" and
                 &1["activity_id"] == "obs_failed_result" and
                 &1["observation_result"] == "accepted, failed" and
                 &1["observation_results"] == ["accepted", "failed"])
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "classifies approval requirements with reusable policy bundles" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "cmd_1",
            "activity_type" => "command",
            "action" => "approve_command_window",
            "requirement_type" => "command_review",
            "reason" => "command window requires review"
          },
          %{
            "activity_id" => "health_1",
            "activity_type" => "health_check",
            "action" => "approve_health_check",
            "requirement_type" => "health_check_review",
            "reason" => "health check requires review"
          },
          %{
            "activity_id" => "missing_activity_id:1",
            "activity_type" => "invalid_activity_input",
            "action" => "review_invalid_activity_input",
            "requirement_type" => "operator_review",
            "reason" => "contact intent input requires review: missing_activity_id"
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        %{policy_bundle_id: "contact_command_review_v1"}
      )

    assert status == "operator_review_required"
    assert Enum.all?(requirements, &(&1["policy_classification"] == "operator_review_required"))
    assert Enum.count(matches, &(&1["rule_id"] == "command_health_review")) == 2
    assert Enum.count(matches, &(&1["rule_id"] == "invalid_contact_intent_input_review")) == 1
    assert decision["policy_bundle_id"] == "contact_command_review_v1"
  end

  test "command contact authority bundle classifies contact direction authority" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "cmd_pass",
            "activity_type" => "planned_contact",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "activity_context" => %{
              "direction" => "command",
              "ground_station_id" => "equator_prime"
            }
          },
          %{
            "activity_id" => "cmd_low_confidence",
            "activity_type" => "command",
            "action" => "review_command_contact",
            "requirement_type" => "command_review",
            "activity_context" => %{
              "direction" => "command",
              "ground_station_id" => "equator_prime",
              "command_success" => false,
              "command_success_factor" => 0.25,
              "command_success_factor_source" => "operational_feedback.command_success_rate"
            }
          },
          %{
            "activity_id" => "uplink_pass",
            "activity_type" => "planned_contact",
            "action" => "review_contact_intent",
            "requirement_type" => "downstream_window_review",
            "activity_context" => %{
              "direction" => "uplink",
              "ground_station_id" => "equator_prime"
            }
          },
          %{
            "activity_id" => "cmd_provider_rejected",
            "activity_type" => "command",
            "action" => "review_command_contact",
            "requirement_type" => "command_review",
            "activity_context" => %{
              "direction" => "command",
              "ground_station_id" => "equator_prime",
              "command_result" => %{
                "outcome" => "accepted",
                "provider_status" => "timed-out"
              }
            }
          },
          %{
            "activity_id" => "tracking_pass",
            "activity_type" => "tracking",
            "action" => "review_tracking_window",
            "requirement_type" => "contact_schedule_change",
            "activity_context" => %{
              "direction" => "tracking",
              "ground_station_id" => "equator_prime"
            }
          },
          %{
            "activity_id" => "mixed_command_tracking_contention",
            "activity_type" => "contact_contention",
            "action" => "review_contact_contention",
            "requirement_type" => "command_review",
            "activity_context" => %{
              "direction" => "mixed",
              "directions" => ["command", "tracking"],
              "ground_station_id" => "equator_prime"
            }
          },
          %{
            "activity_id" => "downlink_pass",
            "activity_type" => "downlink",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "activity_context" => %{
              "direction" => "downlink",
              "ground_station_id" => "equator_prime"
            }
          },
          %{
            "activity_id" => "downlink_low_confidence",
            "activity_type" => "downlink",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "activity_context" => %{
              "direction" => "downlink",
              "ground_station_id" => "equator_prime",
              "contact_success" => false,
              "contact_success_factor" => 0.25,
              "contact_success_factor_source" => "operational_feedback.contact_success_rate"
            }
          },
          %{
            "activity_id" => "contact_provider_dropped",
            "activity_type" => "downlink",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "activity_context" => %{
              "direction" => "downlink",
              "ground_station_id" => "equator_prime",
              "contact_result" => %{
                "outcome" => "accepted",
                "provider_status" => "NO-CONTACT"
              }
            }
          },
          %{
            "activity_id" => "health_poll",
            "activity_type" => "health_check",
            "action" => "approve_health_check",
            "requirement_type" => "health_check_review"
          },
          %{
            "activity_id" => "missing_import_cmd",
            "activity_type" => "command",
            "action" => "review_command",
            "requirement_type" => "command_review",
            "activity_context" => %{
              "direction" => "command",
              "cadence_import_status" => "missing"
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert status == "operator_review_required"
    assert decision["policy_bundle_id"] == "command_contact_authority_v1"
    assert Enum.all?(requirements, &(&1["policy_classification"] == "operator_review_required"))

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "command_uplink_authority_review" and
                 &1["activity_id"] == "cmd_pass" and
                 &1["direction"] == "command" and
                 &1["required_authority"] == "command_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "failed_command_success_review" and
                 &1["activity_id"] == "cmd_low_confidence" and
                 &1["command_success"] == false and
                 &1["required_authority"] == "command_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "low_command_success_confidence_review" and
                 &1["activity_id"] == "cmd_low_confidence" and
                 &1["command_success_factor"] == 0.25 and
                 &1["command_success_factor_source"] ==
                   "operational_feedback.command_success_rate" and
                 &1["required_authority"] == "command_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "command_uplink_authority_review" and
                 &1["activity_id"] == "uplink_pass" and
                 &1["direction"] == "uplink")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "command_result_failure_review" and
                 &1["activity_id"] == "cmd_provider_rejected" and
                 &1["command_result"] == "accepted,timed_out" and
                 &1["command_results"] == ["accepted", "timed_out"] and
                 &1["required_authority"] == "command_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "command_uplink_authority_review" and
                 &1["activity_id"] == "mixed_command_tracking_contention" and
                 &1["direction"] == "mixed" and
                 &1["directions"] == ["mixed", "command", "tracking"])
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "tracking_coordination_review" and
                 &1["direction"] == "tracking" and
                 &1["required_authority"] == "tracking_coordination_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "downlink_schedule_authority_review" and
                 &1["direction"] == "downlink" and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "failed_contact_success_review" and
                 &1["activity_id"] == "downlink_low_confidence" and
                 &1["contact_success"] == false and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "low_contact_success_confidence_review" and
                 &1["activity_id"] == "downlink_low_confidence" and
                 &1["contact_success_factor"] == 0.25 and
                 &1["contact_success_factor_source"] ==
                   "operational_feedback.contact_success_rate" and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "contact_result_failure_review" and
                 &1["activity_id"] == "contact_provider_dropped" and
                 &1["contact_result"] == "accepted,no_contact" and
                 &1["contact_results"] == ["accepted", "no_contact"] and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "health_command_authority_review" and
                 &1["activity_type"] == "health_check")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "missing_cadence_import_review" and
                 &1["activity_id"] == "missing_import_cmd" and
                 &1["cadence_import_status"] == "missing" and
                 &1["required_authority"] == "cadence_import_boundary_authority")
           )

    assert Enum.any?(
             decision["escalations"],
             &(&1["rule_id"] == "tracking_coordination_review" and
                 &1["escalation_queue"] == "tracking_operations")
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "command contact authority bundle classifies command-window station-calendar reviews" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "tracking_maintenance",
            "activity_type" => "tracking",
            "action" => "review_command_window_station_calendar",
            "requirement_type" => "contact_schedule_change",
            "reason" => "tracking window overlaps unavailable station time",
            "activity_context" => %{
              "required_operator_action" => "review_command_window_station_calendar",
              "operator_action_reason" => "station_calendar_unavailable_command_window",
              "direction" => "tracking",
              "ground_station_id" => "equator_prime",
              "station_availability" => "unavailable"
            }
          },
          %{
            "activity_id" => "command_reduced_capacity",
            "activity_type" => "command",
            "action" => "review_command_window_station_calendar",
            "requirement_type" => "command_review",
            "reason" => "command window overlaps reduced-capacity station time",
            "activity_context" => %{
              "required_operator_action" => "review_command_window_station_calendar",
              "operator_action_reason" => "station_calendar_reduced_capacity_command_window",
              "direction" => "command",
              "ground_station_id" => "equator_prime",
              "station_availability" => "reduced_capacity",
              "capacity_fraction" => 0.5
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert status == "blocked_by_policy"
    assert decision["policy_bundle_id"] == "command_contact_authority_v1"

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "tracking_maintenance" and
                 &1["policy_classification"] == "blocked_by_policy")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "command_reduced_capacity" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "command_window_station_calendar_block" and
                 &1["activity_id"] == "tracking_maintenance" and
                 &1["required_operator_action"] == "review_command_window_station_calendar" and
                 &1["station_availability"] == "unavailable" and
                 &1["direction"] == "tracking" and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "command_window_station_calendar_review" and
                 &1["activity_id"] == "command_reduced_capacity" and
                 &1["required_operator_action"] == "review_command_window_station_calendar" and
                 &1["station_availability"] == "reduced_capacity" and
                 &1["capacity_fraction"] == 0.5 and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "conservative bundle matches planner-emitted repair actions" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "obs_1",
            "activity_type" => "observe",
            "action" => "approve_reassigned_observation",
            "requirement_type" => "observation_reassignment",
            "reason" => "observation reassigned"
          },
          %{
            "activity_id" => "burn_1",
            "activity_type" => "impulsive_burn",
            "action" => "approve_delayed_maneuver",
            "requirement_type" => "maneuver_timing_change",
            "reason" => "maneuver delayed"
          },
          %{
            "activity_id" => "obs_cancel",
            "activity_type" => "observe",
            "action" => "cancel",
            "requirement_type" => "cancellation",
            "reason" => "activity canceled"
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        %{policy_bundle_id: "conservative_ops_v1"}
      )

    assert status == "operator_review_required"
    assert Enum.all?(requirements, &(&1["policy_classification"] == "operator_review_required"))
    assert decision["policy_bundle_id"] == "conservative_ops_v1"
    assert Enum.count(matches, &(&1["rule_id"] == "all_requirements_review")) == 3
  end

  test "classifies protected timeline context with reusable policy bundles" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "obs_1",
            "activity_type" => "observe",
            "action" => "approve_observation_reassignment",
            "reason" => "observation moved",
            "source_activity_context" => %{
              "approval_status" => "approved",
              "locked" => true,
              "status" => "planned"
            }
          },
          %{
            "activity_id" => "dl_done",
            "activity_type" => "downlink",
            "action" => "approve_cancel_activity",
            "reason" => "completed contact would be canceled",
            "source_activity_context" => %{"status" => "completed"}
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        %{policy_bundle_id: "timeline_protection_v1"}
      )

    assert status == "blocked_by_policy"
    assert decision["policy_bundle_id"] == "timeline_protection_v1"
    assert Enum.any?(matches, &(&1["rule_id"] == "locked_timeline_item_review"))
    assert Enum.any?(matches, &(&1["rule_id"] == "approved_timeline_item_review"))
    assert Enum.any?(matches, &(&1["rule_id"] == "executed_timeline_item_block"))
    assert Enum.any?(matches, &(&1["approval_status"] == "approved"))
    assert Enum.any?(matches, &(&1["locked"] == true))
    assert Enum.any?(matches, &(&1["status"] == "completed"))

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "locked_timeline_item_review" and
                 &1["escalation_queue"] == "mission_planning" and
                 &1["required_authority"] == "timeline_protection_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "executed_timeline_item_block" and
                 &1["escalation_level"] == "flight_director" and
                 &1["required_authority"] == "flight_director")
           )

    assert Enum.any?(
             decision["escalations"],
             &(&1["rule_id"] == "locked_timeline_item_review" and
                 &1["escalation_queue"] == "mission_planning")
           )

    assert Enum.any?(
             decision["escalations"],
             &(&1["rule_id"] == "executed_timeline_item_block" and
                 &1["escalation_queue"] == "mission_operations")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "dl_done" and
                 &1["policy_classification"] == "blocked_by_policy")
           )
  end

  test "blocks degraded payload activity while exempting command and health review" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "obs_degraded",
            "activity_type" => "observe",
            "action" => "approve_observation_reassignment",
            "requirement_type" => "observation_reassignment",
            "reason" => "observation would move onto degraded spacecraft",
            "source_activity_context" => %{
              "degraded" => true,
              "payload_available" => false
            }
          },
          %{
            "activity_id" => "cmd_safe",
            "activity_type" => "command",
            "action" => "approve_command_window",
            "requirement_type" => "command_review",
            "reason" => "safe-mode command review",
            "source_activity_context" => %{"degraded" => true}
          },
          %{
            "activity_id" => "health_poll",
            "activity_type" => "health_check",
            "action" => "approve_health_check",
            "requirement_type" => "health_check_review",
            "reason" => "safe-mode health check",
            "source_activity_context" => %{"degraded" => true}
          },
          %{
            "activity_id" => "dl_antenna_off",
            "activity_type" => "downlink",
            "action" => "approve_moved_contact",
            "requirement_type" => "contact_schedule_change",
            "reason" => "downlink would move onto spacecraft without antenna availability",
            "source_activity_context" => %{"antenna_available" => false}
          },
          %{
            "activity_id" => "tracking_antenna_off",
            "activity_type" => "tracking",
            "action" => "approve_tracking_window",
            "requirement_type" => "tracking_review",
            "reason" => "tracking would move onto spacecraft without antenna availability",
            "source_activity_context" => %{"antenna_available" => false}
          },
          %{
            "activity_id" => "bad_resource_candidate",
            "activity_type" => "invalid_candidate_input",
            "action" => "review_invalid_resource_filter_input",
            "requirement_type" => "operator_review",
            "reason" => "invalid resource-filter candidate input"
          },
          %{
            "activity_id" => "resource_filter:invalid_resource_summary:sat_1",
            "activity_type" => "resource_filter_invalid_summary",
            "action" => "review_invalid_resource_filter_summary",
            "requirement_type" => "operator_review",
            "reason" => "invalid resource-filter summary input"
          }
        ],
        [%{"type" => "spacecraft_degraded", "reason" => "spacecraft in safe mode"}],
        %{"id" => "branch", "events" => []},
        %{},
        %{policy_bundle_id: "degraded_payload_guard_v1"}
      )

    assert status == "blocked_by_policy"
    assert decision["policy_bundle_id"] == "degraded_payload_guard_v1"
    assert decision["risk_count"] == 0

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "degraded_payload_observation_block" and
                 &1["degraded"] == true)
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "payload_unavailable_observation_block" and
                 &1["payload_available"] == false)
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "antenna_unavailable_contact_block" and
                 &1["activity_id"] == "dl_antenna_off" and &1["antenna_available"] == false)
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "antenna_unavailable_contact_block" and
                 &1["activity_id"] == "tracking_antenna_off" and
                 &1["antenna_available"] == false)
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "degraded_command_health_exemption" and
                 &1["activity_type"] == "command")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "degraded_command_health_exemption" and
                 &1["activity_type"] == "health_check")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "invalid_resource_filter_candidate_input_review" and
                 &1["activity_id"] == "bad_resource_candidate")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "invalid_resource_filter_summary_input_review" and
                 &1["activity_id"] == "resource_filter:invalid_resource_summary:sat_1")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "obs_degraded" and
                 &1["policy_classification"] == "blocked_by_policy")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "dl_antenna_off" and
                 &1["policy_classification"] == "blocked_by_policy")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "cmd_safe" and
                 &1["policy_classification"] == "auto_approvable")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "health_poll" and
                 &1["policy_classification"] == "auto_approvable")
           )
  end

  test "emits artifact-only escalation summaries from mission ops bundle" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "cmd_1",
            "activity_type" => "command",
            "action" => "approve_command_window",
            "requirement_type" => "command_review",
            "reason" => "command window requires review"
          },
          %{
            "activity_id" => "health_1",
            "activity_type" => "health_check",
            "action" => "approve_health_check",
            "requirement_type" => "health_check_review",
            "reason" => "health check requires review"
          },
          %{
            "activity_id" => "target_urgent",
            "activity_type" => "observe",
            "action" => "approve_strategic_addition",
            "requirement_type" => "strategic_addition",
            "reason" => "new high-priority collection request"
          }
        ],
        [%{"type" => "no_viable_downlink", "reason" => "downlink path not available"}],
        %{"id" => "branch", "events" => []},
        %{},
        %{policy_bundle_id: "mission_ops_escalation_v1"}
      )

    assert status == "blocked_by_policy"
    assert decision["policy_bundle_id"] == "mission_ops_escalation_v1"

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "cmd_1" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "command_authority_escalation" and
                 &1["escalation_queue"] == "mission_operations" and
                 &1["required_authority"] == "command_authority" and
                 &1["sla_s"] == 900)
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "command_authority_escalation" and
                 &1["activity_type"] == "health_check")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "strategic_priority_escalation" and
                 &1["escalation_queue"] == "mission_planning")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "downlink_loss_director_escalation" and
                 &1["classification"] == "blocked_by_policy")
           )

    assert Enum.any?(
             decision["escalations"],
             &(&1["rule_id"] == "downlink_loss_director_escalation" and
                 &1["escalation_level"] == "flight_director")
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "mission ops bundle escalates reserved station contact contention" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "cmd_reserved",
            "activity_type" => "planned_contact",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "reason" => "command contact overlaps provider reservation",
            "activity_context" => %{
              "direction" => "command",
              "ground_station_id" => "equator_prime",
              "station_contention_status" => "Reserved Overlap",
              "station_reservation_status" => "Confirmed"
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        %{policy_bundle_id: "mission_ops_escalation_v1"}
      )

    assert status == "operator_review_required"
    assert decision["policy_bundle_id"] == "mission_ops_escalation_v1"

    assert [
             %{
               "activity_id" => "cmd_reserved",
               "policy_classification" => "operator_review_required",
               "approval_rule_matches" => rule_matches
             }
           ] = requirements

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "reserved_station_contact_escalation" and
                 &1["station_contention_status"] == "reserved_overlap" and
                 &1["station_reservation_status"] == "confirmed")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "reserved_station_contact_escalation" and
                 &1["escalation_queue"] == "ground_network" and
                 &1["required_authority"] == "contact_schedule_authority" and
                 &1["sla_s"] == 600)
           )

    assert Enum.any?(
             decision["escalations"],
             &(&1["rule_id"] == "reserved_station_contact_escalation" and
                 &1["escalation_level"] == "ops_lead")
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "mission ops bundle prioritizes high-overlap contact contention" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "station:equator_prime:contention:priority",
            "activity_type" => "contact_contention_resolution",
            "action" => "recommend_preferred_contact_for_operator_review",
            "requirement_type" => "contact_schedule_change",
            "reason" => "high overlap station contention requires priority review",
            "activity_context" => %{
              "resource_scope" => "ground_station",
              "ground_station_id" => "equator_prime",
              "contention_window_s" => 180.0,
              "total_contact_duration_s" => 360.0,
              "overlap_duration_s" => 75.0,
              "max_concurrent_contacts" => 3,
              "overlap_contact_pair_count" => 4
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        %{policy_bundle_id: "mission_ops_escalation_v1"}
      )

    assert status == "operator_review_required"

    assert [
             %{
               "activity_id" => "station:equator_prime:contention:priority",
               "policy_classification" => "operator_review_required",
               "approval_rule_matches" => rule_matches
             }
           ] = requirements

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "contact_execution_coordination" and
                 &1["sla_s"] == 1800)
           )

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "high_overlap_contact_contention_escalation" and
                 &1["overlap_duration_s"] == 75.0 and
                 &1["max_concurrent_contacts"] == 3 and
                 &1["overlap_contact_pair_count"] == 4 and
                 &1["escalation_queue"] == "ground_network_priority" and
                 &1["sla_s"] == 600)
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "high_overlap_contact_contention_escalation" and
                 &1["activity_id"] == "station:equator_prime:contention:priority" and
                 &1["contention_window_s"] == 180.0 and
                 &1["total_contact_duration_s"] == 360.0)
           )

    assert Enum.any?(
             decision["escalations"],
             &(&1["rule_id"] == "high_overlap_contact_contention_escalation" and
                 &1["escalation_queue"] == "ground_network_priority")
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches station reservation identity owner and match status evidence" do
    policy = %{
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

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "uplink_reserved",
            "activity_type" => "planned_contact",
            "action" => "review_command_contact",
            "requirement_type" => "command_review",
            "reason" => "uplink uses reserved provider station time",
            "activity_context" => %{
              "direction" => "uplink",
              "ground_station_id" => "dss_14",
              "station_reservation_id" => "reservation_42",
              "station_reserved_by" => "ops_team_b",
              "station_reservation_status" => "Confirmed",
              "station_reservation_match_status" => "Matched"
            }
          }
        ],
        [],
        %{"id" => "command_window", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"
    assert decision["classification"] == "operator_review_required"

    assert [
             %{
               "activity_id" => "uplink_reserved",
               "policy_classification" => "operator_review_required"
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "owned_reservation_command_review",
               "station_reservation_id" => "reservation_42",
               "station_reservation_ids" => ["reservation_42"],
               "station_reserved_by" => "ops_team_b",
               "station_reserved_bys" => ["ops_team_b"],
               "station_reservation_status" => "confirmed",
               "station_reservation_match_status" => "matched"
             }
           ] = matches
  end

  test "matches station reservation owner lists from aggregated approval context" do
    policy = %{
      action_rules: [
        %{
          id: :aggregated_owner_reservation_review,
          station_reserved_bys: [:ops_team_b],
          station_reservation_statuses: [:confirmed],
          station_reservation_match_statuses: [:matched],
          classification: :operator_review_required,
          reason: "aggregated reservation owners require contact-schedule authority"
        }
      ]
    }

    {status, _requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "station:equator_prime:contention:reserved",
            "activity_type" => "contact_contention_resolution",
            "action" => "review_contact_contention_resolution",
            "requirement_type" => "contact_schedule_change",
            "reason" => "reserved station contention requires review",
            "activity_context" => %{
              "ground_station_id" => "equator_prime",
              "station_reserved_bys" => ["ops_team_a", "ops_team_b"],
              "station_reservation_statuses" => ["Tentative", "Confirmed"],
              "station_reservation_match_statuses" => ["Overlap", "Matched"]
            }
          }
        ],
        [],
        %{"id" => "contact_contention", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"
    assert decision["classification"] == "operator_review_required"

    assert [
             %{
               "rule_id" => "aggregated_owner_reservation_review",
               "activity_id" => "station:equator_prime:contention:reserved",
               "station_reserved_bys" => ["ops_team_a", "ops_team_b"],
               "station_reservation_statuses" => ["tentative", "confirmed"],
               "station_reservation_match_statuses" => ["overlap", "matched"]
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches station availability and contention lists from aggregated approval context" do
    policy = %{
      action_rules: [
        %{
          id: :aggregated_station_state_review,
          station_availabilities: [:maintenance],
          station_contention_statuses: [:reserved_overlap],
          classification: :operator_review_required,
          reason: "aggregated station state requires ground-network review"
        }
      ]
    }

    {status, _requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "station:equator_prime:contention:state",
            "activity_type" => "contact_contention_resolution",
            "action" => "review_contact_contention_resolution",
            "requirement_type" => "contact_schedule_change",
            "reason" => "mixed station-calendar state requires review",
            "activity_context" => %{
              "ground_station_id" => "equator_prime",
              "station_availabilities" => ["available", "Maintenance"],
              "station_contention_statuses" => ["none", "Reserved Overlap"]
            }
          }
        ],
        [],
        %{"id" => "contact_contention", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"
    assert decision["classification"] == "operator_review_required"

    assert [
             %{
               "rule_id" => "aggregated_station_state_review",
               "activity_id" => "station:equator_prime:contention:state",
               "station_availabilities" => ["available", "maintenance"],
               "station_contention_statuses" => ["none", "reserved_overlap"]
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches provider calendar reservation owner and status lists" do
    policy = %{
      action_rules: [
        %{
          id: :provider_calendar_owner_status_review,
          station_calendar_entry_ambiguous: true,
          station_calendar_ambiguous_entry_count_min: 2,
          station_calendar_ambiguous_entry_ids: [:equator_reserved_b],
          station_calendar_reserved_bys: [:ops_team_b],
          station_calendar_reservation_statuses: ["Confirmed"],
          classification: :operator_review_required,
          reason: "confirmed provider reservations require ground-network review"
        }
      ]
    }

    {status, _requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "dl_1",
            "activity_type" => "downlink",
            "action" => "review_station_reservation_overlap",
            "requirement_type" => "contact_schedule_change",
            "reason" => "contact overlaps ambiguous provider reservations",
            "activity_context" => %{
              "ground_station_id" => "equator_prime",
              "station_calendar_entry_ambiguous" => true,
              "station_calendar_ambiguous_entry_count" => 2,
              "station_calendar_ambiguous_entry_ids" => [
                "equator_reserved_a",
                "equator_reserved_b"
              ],
              "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
              "station_calendar_reservation_statuses" => ["Tentative", "Confirmed"]
            }
          }
        ],
        [],
        %{"id" => "station_calendar", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"
    assert decision["classification"] == "operator_review_required"

    assert [
             %{
               "rule_id" => "provider_calendar_owner_status_review",
               "station_calendar_entry_ambiguous" => true,
               "station_calendar_ambiguous_entry_count" => 2,
               "station_calendar_ambiguous_entry_ids" => [
                 "equator_reserved_a",
                 "equator_reserved_b"
               ],
               "station_calendar_reserved_by" => ["ops_team_a", "ops_team_b"],
               "station_calendar_reserved_bys" => ["ops_team_a", "ops_team_b"],
               "station_calendar_reservation_status" => "tentative",
               "station_calendar_reservation_statuses" => ["tentative", "confirmed"]
             }
           ] = matches
  end

  test "ground network allocation bundle classifies station availability and capacity" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "dl_blocked",
            "activity_type" => "downlink",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "reason" => "contact overlaps unavailable station interval",
            "activity_context" => %{
              "ground_station_id" => "equator_prime",
              "station_availability" => "unavailable"
            }
          },
          %{
            "activity_id" => "dl_reduced",
            "activity_type" => "downlink",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "reason" => "contact overlaps severe capacity reduction",
            "activity_context" => %{
              "ground_station_id" => "equator_prime",
              "station_availability" => "reduced_capacity",
              "capacity_fraction" => 0.4
            }
          },
          %{
            "activity_id" => "dl_capacity_insufficient",
            "activity_type" => "downlink",
            "action" => "review_contact_allocation",
            "requirement_type" => "contact_schedule_change",
            "reason" => "contact requires more capacity than the reduced station interval offers",
            "activity_context" => %{
              "ground_station_id" => "equator_prime",
              "station_availability" => "reduced_capacity",
              "capacity_fraction" => 0.5,
              "required_capacity_fraction" => 0.75,
              "allocation_status" => "blocked",
              "effective_allocation_status" => "blocked",
              "allocation_reason" => "ground_station_reduced_capacity_insufficient",
              "suppressed_reason" => "ground_station_reduced_capacity_insufficient"
            }
          },
          %{
            "activity_id" => "cmd_reserved",
            "activity_type" => "planned_contact",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "reason" => "contact overlaps reserved station interval",
            "activity_context" => %{
              "direction" => "command",
              "ground_station_id" => "equator_prime",
              "station_availability" => "reserved",
              "station_contention_status" => "reserved_overlap",
              "station_reservation_status" => "confirmed"
            }
          },
          %{
            "activity_id" => "dl_low_completion",
            "activity_type" => "link_capacity_summary",
            "action" => "review_link_capacity_summary",
            "requirement_type" => "contact_schedule_change",
            "reason" => "selected downlink realized completion is low",
            "activity_context" => %{
              "ground_station_id" => "equator_prime",
              "actual_completion_fraction" => 0.5
            }
          },
          %{
            "activity_id" => "invalid_link_capacity_input",
            "activity_type" => "link_capacity",
            "action" => "review_invalid_link_capacity_input",
            "requirement_type" => "contact_schedule_change",
            "reason" => "link-capacity candidate input is missing station identity",
            "activity_context" => %{
              "input_role" => "candidate",
              "required_operator_action" => "review_invalid_link_capacity_input",
              "invalid_contact_input" => true,
              "invalid_contact_input_reason" => "missing_ground_station_id"
            }
          },
          %{
            "activity_id" => "dl_missing_station_trust",
            "activity_type" => "planned_contact",
            "action" => "review_contact_allocation",
            "requirement_type" => "contact_schedule_change",
            "reason" => "station calendar provider did not declare trust boundary",
            "activity_context" => %{
              "ground_station_id" => "equator_prime",
              "station_calendar_trust_boundary_status" => "missing"
            }
          },
          %{
            "activity_id" => "cmd_provider_calendar_direction",
            "activity_type" => "planned_contact",
            "action" => "review_contact_allocation",
            "requirement_type" => "contact_schedule_change",
            "reason" => "command station calendar direction requires review",
            "activity_context" => %{
              "ground_station_id" => "equator_prime",
              "direction" => "downlink",
              "station_calendar_directions" => ["command"]
            }
          },
          %{
            "activity_id" => "plain_station_contention",
            "activity_type" => "contact_contention",
            "action" => "review_contact_contention",
            "requirement_type" => "contact_schedule_change",
            "reason" => "same station overlapping contact windows",
            "activity_context" => %{
              "resource_scope" => "ground_station",
              "ground_station_id" => "equator_prime",
              "required_operator_action" => "review_contact_contention",
              "operator_action_reason" => "same_station_overlapping_contact_windows"
            }
          },
          %{
            "activity_id" => "high_overlap_station_contention",
            "activity_type" => "contact_contention_resolution",
            "action" => "recommend_preferred_contact_for_operator_review",
            "requirement_type" => "contact_schedule_change",
            "reason" => "same station contention has high overlap pressure",
            "activity_context" => %{
              "resource_scope" => "ground_station",
              "ground_station_id" => "equator_prime",
              "required_operator_action" => "recommend_preferred_contact_for_operator_review",
              "operator_action_reason" => "same_station_overlapping_contact_windows",
              "contention_window_s" => 180.0,
              "total_contact_duration_s" => 360.0,
              "overlap_duration_s" => 75.0,
              "max_concurrent_contacts" => 3,
              "overlap_contact_pair_count" => 4
            }
          },
          %{
            "activity_id" => "declared_provider_contention",
            "activity_type" => "contact_contention_resolution",
            "action" => "recommend_preferred_contact_for_operator_review",
            "requirement_type" => "contact_schedule_change",
            "reason" => "provider-calendar contention requires review",
            "activity_context" => %{
              "ground_station_id" => "equator_prime",
              "resource_scope" => "ground_station",
              "station_calendar_provider_ids" => ["provider_calendar"],
              "station_calendar_trust_boundary_statuses" => ["declared"]
            }
          },
          %{
            "activity_id" => "duplicate_contact_identity",
            "activity_type" => "contact_contention_resolution",
            "action" => "review_ambiguous_contact_contention_identity",
            "requirement_type" => "contact_schedule_change",
            "reason" => "duplicate contact identities are ambiguous",
            "activity_context" => %{
              "ground_station_id" => "equator_prime",
              "resolution_status" => "ambiguous_contact_identity",
              "resolution_issue" => "duplicate_contact_id"
            }
          },
          %{
            "activity_id" => "invalid_contact_contention_input",
            "activity_type" => "contact_contention",
            "action" => "review_invalid_contact_contention_input",
            "requirement_type" => "contact_schedule_change",
            "reason" => "contact contention input is missing station identity",
            "activity_context" => %{
              "required_operator_action" => "review_invalid_contact_contention_input",
              "operator_action_reason" => "missing_ground_station_id",
              "invalid_contact_input" => true,
              "invalid_contact_input_reason" => "missing_ground_station_id"
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert status == "blocked_by_policy"
    assert decision["policy_bundle_id"] == "ground_network_allocation_v1"

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "dl_blocked" and
                 &1["policy_classification"] == "blocked_by_policy")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "dl_reduced" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "dl_capacity_insufficient" and
                 &1["policy_classification"] == "blocked_by_policy")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "cmd_reserved" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "dl_low_completion" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "dl_missing_station_trust" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "invalid_link_capacity_input" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "cmd_provider_calendar_direction" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "declared_provider_contention" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "plain_station_contention" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "high_overlap_station_contention" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "duplicate_contact_identity" and
                 &1["policy_classification"] == "blocked_by_policy")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "invalid_contact_contention_input" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "unavailable_station_contact_block" and
                 &1["station_availability"] == "unavailable")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "severe_capacity_reduction_review" and
                 &1["capacity_fraction"] == 0.4)
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "reduced_station_capacity_insufficient_block" and
                 &1["activity_id"] == "dl_capacity_insufficient" and
                 &1["capacity_fraction"] == 0.5 and
                 &1["required_capacity_fraction"] == 0.75 and
                 &1["allocation_status"] == "blocked" and
                 &1["effective_allocation_status"] == "blocked" and
                 &1["allocation_reason"] == "ground_station_reduced_capacity_insufficient" and
                 &1["suppressed_reason"] == "ground_station_reduced_capacity_insufficient" and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "reserved_station_contact_review" and
                 &1["station_contention_status"] == "reserved_overlap")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "low_actual_downlink_completion_review" and
                 &1["actual_completion_fraction"] == 0.5)
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "missing_station_calendar_trust_review" and
                 &1["station_calendar_trust_boundary_status"] == "missing")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "command_station_calendar_direction_review" and
                 &1["activity_id"] == "cmd_provider_calendar_direction" and
                 &1["direction"] == "downlink" and
                 &1["station_calendar_direction"] == "command" and
                 &1["station_calendar_directions"] == ["command"])
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "same_station_contact_contention_review" and
                 &1["activity_id"] == "plain_station_contention" and
                 &1["resource_scope"] == "ground_station" and
                 &1["required_operator_action"] == "review_contact_contention")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "high_overlap_contact_contention_review" and
                 &1["activity_id"] == "high_overlap_station_contention" and
                 &1["resource_scope"] == "ground_station" and
                 &1["contention_window_s"] == 180.0 and
                 &1["total_contact_duration_s"] == 360.0 and
                 &1["overlap_duration_s"] == 75.0 and
                 &1["max_concurrent_contacts"] == 3 and
                 &1["overlap_contact_pair_count"] == 4 and
                 &1["escalation_queue"] == "ground_network_priority" and
                 &1["sla_s"] == 600)
           )

    refute Enum.any?(
             matches,
             &(&1["rule_id"] == "high_overlap_contact_contention_review" and
                 &1["activity_id"] == "plain_station_contention")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "declared_provider_calendar_contention_review" and
                 &1["station_calendar_provider_ids"] == ["provider_calendar"] and
                 &1["station_calendar_trust_boundary_statuses"] == ["declared"])
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "duplicate_contact_identity_block" and
                 &1["resolution_status"] == "ambiguous_contact_identity" and
                 &1["resolution_issue"] == "duplicate_contact_id")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "invalid_contact_contention_input_review" and
                 &1["required_operator_action"] ==
                   "review_invalid_contact_contention_input" and
                 &1["operator_action_reason"] == "missing_ground_station_id")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "invalid_link_capacity_input_review" and
                 &1["activity_id"] == "invalid_link_capacity_input" and
                 &1["action"] == "review_invalid_link_capacity_input" and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "classifies station-calendar trust-boundary status with action rules" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "dl_missing_station_trust",
            "activity_type" => "planned_contact",
            "action" => "review_contact_allocation",
            "requirement_type" => "contact_schedule_change",
            "reason" => "station calendar provider did not declare trust boundary",
            "activity_context" => %{
              "ground_station_id" => "equator_prime",
              "station_availability" => "reduced_capacity",
              "station_calendar_trust_boundary_status" => "missing"
            }
          }
        ],
        [],
        %{"id" => "contact_allocation", "events" => []},
        %{},
        %{
          action_rules: [
            %{
              id: :missing_station_calendar_trust_review,
              station_calendar_trust_boundary_status: :missing,
              classification: :operator_review_required,
              reason: "station calendar trust boundary missing"
            }
          ]
        }
      )

    assert status == "operator_review_required"

    assert [
             %{
               "activity_id" => "dl_missing_station_trust",
               "policy_classification" => "operator_review_required"
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "missing_station_calendar_trust_review",
               "station_calendar_trust_boundary_status" => "missing"
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "resource projection authority bundle classifies pressure trust and source evidence" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "resource_projection:leo_1",
            "activity_type" => "resource_projection",
            "action" => "review_resource_projection",
            "requirement_type" => "operator_review",
            "reason" => "resource projection has storage and downlink pressure",
            "activity_context" => %{
              "spacecraft_id" => "leo_1",
              "resource_pressure_status" => "storage_and_downlink_pressure",
              "resource_pressure_types" => ["storage_overflow", "downlink_shortfall"],
              "resource_source_quality" => "unknown",
              "resource_trust_boundary_status" => "missing",
              "first_resource_pressure_kind" => "storage_overflow"
            }
          },
          %{
            "activity_id" => "missing_activity_id:2",
            "activity_type" => "resource_projection_invalid_activity",
            "action" => "review_invalid_resource_projection_input",
            "requirement_type" => "operator_review",
            "reason" => "resource projection activity input is missing identity",
            "activity_context" => %{
              "required_operator_action" => "review_invalid_resource_projection_input",
              "invalid_activity_input" => true,
              "invalid_activity_input_reason" => "missing_activity_id"
            }
          },
          %{
            "activity_id" => "resource_projection:invalid_resource_summary:leo_2",
            "activity_type" => "resource_projection_invalid_summary",
            "action" => "review_invalid_resource_projection_summary",
            "requirement_type" => "operator_review",
            "reason" => "resource projection summary input has invalid energy evidence",
            "activity_context" => %{
              "resource_summary_id" => "leo_2",
              "required_operator_action" => "review_invalid_resource_projection_summary",
              "invalid_resource_summary_input" => true,
              "invalid_resource_summary_input_reason" => "negative_battery_energy_used_wh"
            }
          }
        ],
        [],
        %{"id" => "resource_projection", "events" => []},
        %{},
        %{policy_bundle_id: "resource_projection_authority_v1"}
      )

    assert status == "blocked_by_policy"
    assert decision["policy_bundle_id"] == "resource_projection_authority_v1"

    assert %{
             "activity_id" => "resource_projection:leo_1",
             "policy_classification" => "blocked_by_policy",
             "approval_rule_matches" => rule_matches
           } =
             Enum.find(requirements, &(&1["activity_id"] == "resource_projection:leo_1"))

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "missing_resource_trust_boundary_review" and
                 &1["resource_trust_boundary_status"] == "missing")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "unknown_resource_source_quality_review" and
                 &1["resource_source_quality"] == "unknown")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "resource_pressure_review" and
                 &1["resource_pressure_types"] == ["storage_overflow", "downlink_shortfall"])
           )

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "combined_resource_pressure_director_block" and
                 &1["resource_pressure_status"] == "storage_and_downlink_pressure" and
                 &1["required_authority"] == "flight_director")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "first_storage_pressure_review" and
                 &1["first_resource_pressure_kind"] == "storage_overflow")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "invalid_resource_projection_activity_input_review" and
                 &1["activity_id"] == "missing_activity_id:2" and
                 &1["action"] == "review_invalid_resource_projection_input" and
                 &1["required_authority"] == "resource_model_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "invalid_resource_projection_summary_input_review" and
                 &1["activity_id"] == "resource_projection:invalid_resource_summary:leo_2" and
                 &1["action"] == "review_invalid_resource_projection_summary" and
                 &1["required_authority"] == "resource_model_authority")
           )

    assert Enum.any?(
             decision["escalations"],
             &(&1["rule_id"] == "combined_resource_pressure_director_block" and
                 &1["escalation_queue"] == "mission_operations")
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches resource and provenance list-valued requirement context" do
    policy = %{
      action_rules: [
        %{
          id: "aggregated_resource_provenance_review",
          resource_pressure_statuses: ["storage_and_downlink_pressure"],
          resource_pressure_types: ["storage_overflow"],
          resource_source_qualities: ["unknown"],
          resource_trust_boundaries: ["declared_resource_summary"],
          resource_trust_boundary_statuses: ["missing"],
          first_resource_pressure_kinds: ["storage_overflow"],
          feedback_sources: ["prior_plan.source_resource_projection"],
          feedback_scopes: ["resource_projection"],
          trust_boundaries: ["adapter_declared"],
          source_event_types: ["resource_projection_pressure"],
          classification: "operator_review_required",
          reason: "aggregated resource provenance requires review"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "resource_projection:aggregate",
            "activity_type" => "resource_projection",
            "action" => "review_resource_projection",
            "requirement_type" => "operator_review",
            "reason" => "aggregated resource provenance requires review",
            "activity_context" => %{
              "resource_pressure_statuses" => [
                "storage_and_downlink_pressure",
                "power_margin_pressure"
              ],
              "resource_pressure_types" => ["storage_overflow", "downlink_shortfall"],
              "resource_source_qualities" => ["unknown", "declared"],
              "resource_trust_boundaries" => ["declared_resource_summary"],
              "resource_trust_boundary_statuses" => ["missing"],
              "first_resource_pressure_kinds" => ["storage_overflow"],
              "feedback_sources" => ["prior_plan.source_resource_projection"],
              "feedback_scopes" => ["resource_projection"],
              "trust_boundaries" => ["adapter_declared"],
              "source_event_types" => ["resource_projection_pressure"]
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "activity_id" => "resource_projection:aggregate",
               "policy_classification" => "operator_review_required",
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "aggregated_resource_provenance_review",
                   "resource_pressure_statuses" => [
                     "storage_and_downlink_pressure",
                     "power_margin_pressure"
                   ],
                   "resource_pressure_types" => ["storage_overflow", "downlink_shortfall"],
                   "resource_source_qualities" => ["unknown", "declared"],
                   "resource_trust_boundaries" => ["declared_resource_summary"],
                   "resource_trust_boundary_statuses" => ["missing"],
                   "first_resource_pressure_kinds" => ["storage_overflow"],
                   "feedback_sources" => ["prior_plan.source_resource_projection"],
                   "feedback_scopes" => ["resource_projection"],
                   "trust_boundaries" => ["adapter_declared"],
                   "source_event_types" => ["resource_projection_pressure"]
                 }
               ]
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "aggregated_resource_provenance_review",
               "activity_id" => "resource_projection:aggregate",
               "resource_pressure_statuses" => [
                 "storage_and_downlink_pressure",
                 "power_margin_pressure"
               ],
               "resource_pressure_types" => ["storage_overflow", "downlink_shortfall"],
               "resource_source_qualities" => ["unknown", "declared"],
               "resource_trust_boundaries" => ["declared_resource_summary"],
               "resource_trust_boundary_statuses" => ["missing"],
               "first_resource_pressure_kinds" => ["storage_overflow"],
               "feedback_sources" => ["prior_plan.source_resource_projection"],
               "feedback_scopes" => ["resource_projection"],
               "trust_boundaries" => ["adapter_declared"],
               "source_event_types" => ["resource_projection_pressure"]
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches resource suppression policy rules by suppressed reason and blocking dimension" do
    policy = %{
      action_rules: [
        %{
          id: :antenna_resource_suppression_review,
          suppressed_reasons: [:antenna_unavailable],
          resource_blocking_dimensions: [:antenna],
          classification: :operator_review_required,
          reason: "antenna suppressions require ground-network review"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "planned_downlink",
            "activity_type" => "planned_contact",
            "action" => "review_suppressed_contact",
            "requirement_type" => "contact_schedule_change",
            "reason" => "antenna unavailable",
            "activity_context" => %{
              "suppressed_reason" => "antenna_unavailable",
              "resource_blocking_dimension" => "antenna",
              "direction" => "downlink"
            }
          }
        ],
        [],
        %{"id" => "resource_filter", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"
    assert decision["classification"] == "operator_review_required"

    assert [
             %{
               "activity_id" => "planned_downlink",
               "policy_classification" => "operator_review_required"
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "antenna_resource_suppression_review",
               "suppressed_reason" => "antenna_unavailable",
               "resource_blocking_dimension" => "antenna"
             }
           ] = matches
  end

  test "maneuver authority bundle escalates maneuver timing changes" do
    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "burn_1",
            "activity_type" => "impulsive_burn",
            "action" => "approve_delayed_maneuver",
            "requirement_type" => "maneuver_timing_change",
            "reason" => "maneuver timing moved by repair"
          },
          %{
            "activity_id" => "bad_maneuver",
            "activity_type" => "invalid_maneuver_recommendation",
            "action" => "review_invalid_maneuver_recommendation",
            "requirement_type" => "maneuver_authority_review",
            "reason" => "invalid maneuver recommendation input"
          },
          %{
            "activity_id" => "burn_failed_result",
            "activity_type" => "impulsive_burn",
            "action" => "approve_delayed_maneuver",
            "requirement_type" => "maneuver_timing_change",
            "reason" => "provider reported maneuver failure",
            "source_activity_context" => %{
              "maneuver_result" => "accepted, failed"
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        %{policy_bundle_id: "maneuver_authority_v1"}
      )

    assert status == "operator_review_required"
    assert decision["policy_bundle_id"] == "maneuver_authority_v1"

    assert %{
             "activity_id" => "burn_1",
             "policy_classification" => "operator_review_required",
             "approval_rule_matches" => rule_matches
           } = Enum.find(requirements, &(&1["activity_id"] == "burn_1"))

    assert %{
             "activity_id" => "bad_maneuver",
             "policy_classification" => "operator_review_required",
             "approval_rule_matches" => invalid_rule_matches
           } = Enum.find(requirements, &(&1["activity_id"] == "bad_maneuver"))

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "maneuver_timing_authority_review" and
                 &1["requirement_type"] == "maneuver_timing_change")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "impulsive_burn_authority_review" and
                 &1["activity_type"] == "impulsive_burn" and
                 &1["required_authority"] == "maneuver_authority" and
                 &1["sla_s"] == 1800)
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "invalid_maneuver_recommendation_review" and
                 &1["activity_id"] == "bad_maneuver" and
                 &1["action"] == "review_invalid_maneuver_recommendation" and
                 &1["required_authority"] == "maneuver_authority" and
                 &1["sla_s"] == 1200)
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "maneuver_result_failure_review" and
                 &1["activity_id"] == "burn_failed_result" and
                 &1["maneuver_result"] == "accepted, failed" and
                 &1["maneuver_results"] == ["accepted", "failed"] and
                 &1["required_authority"] == "maneuver_authority")
           )

    assert Enum.any?(
             invalid_rule_matches,
             &(&1["rule_id"] == "invalid_maneuver_recommendation_review" and
                 &1["activity_id"] == "bad_maneuver")
           )

    assert Enum.any?(
             decision["escalations"],
             &(&1["rule_id"] == "maneuver_timing_authority_review" and
                 &1["escalation_queue"] == "flight_dynamics")
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "blocks when fallback policy sees a blocked risk type" do
    {status, _requirements, _matches, decision} =
      Policy.decide(
        [],
        [%{"type" => "no_viable_downlink", "reason" => "no contact path"}],
        %{"id" => "branch", "events" => []},
        %{},
        %{}
      )

    assert status == "blocked_by_policy"
    assert decision["risk_count"] == 1
  end

  test "fallback policy blocks schema-validation errors but leaves warnings reviewable" do
    policy = %{blocked_risk_types: ["schema_validation_blocked"]}

    {blocked_status, _requirements, _matches, blocked_decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "schema_validation_pressure",
            "feedback_scope" => "schema_validation",
            "validation_status" => "fail",
            "issue_severity" => "error",
            "error_count" => 1
          }
        ],
        %{"id" => "schema_error", "events" => []},
        %{},
        policy
      )

    assert blocked_status == "blocked_by_policy"
    assert blocked_decision["classification"] == "blocked_by_policy"

    {review_status, _requirements, _matches, review_decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "schema_validation_pressure",
            "feedback_scope" => "schema_validation",
            "validation_status" => "warning",
            "issue_severity" => "warning",
            "error_count" => 0,
            "warning_count" => 1
          }
        ],
        %{"id" => "schema_warning", "events" => []},
        %{},
        policy
      )

    assert review_status == "operator_review_required"
    assert review_decision["classification"] == "operator_review_required"
  end

  test "fallback policy blocks import-readiness blockers but leaves review-only import readiness reviewable" do
    policy = %{blocked_risk_types: ["import_readiness_blocked"]}

    for {branch_id, risk} <- [
          {"operational_readiness_import_blocked",
           %{
             "type" => "operational_readiness_pressure",
             "feedback_scope" => "operational_readiness",
             "readiness_gate_id" => "cadence_import",
             "operational_readiness_status" => "review_required",
             "import_classification" => "review_only",
             "import_blocked" => true,
             "blocked_import_count" => 1,
             "invalid_cadence_import_count" => 0,
             "import_status_counts" => %{"blocked_missing_cadence_import" => 1},
             "cadence_import_status_counts" => %{"missing" => 1},
             "required_operator_action" => "review_operational_readiness"
           }},
          {"quality_gate_import_invalid",
           %{
             "type" => "quality_gate_pressure",
             "feedback_scope" => "quality_gate",
             "gate_id" => "cadence_import",
             "quality_gate_status" => "review_required",
             "import_classification" => "review_only",
             "import_blocked" => true,
             "blocked_import_count" => 0,
             "invalid_cadence_import_count" => 1,
             "cadence_import_status_counts" => %{"invalid" => 1},
             "blocked_import_quality_gate_row_ids" => ["quality_gate:cadence_import:blocked"],
             "required_operator_action" => "review_operational_readiness"
           }}
        ] do
      {blocked_status, _requirements, _matches, blocked_decision} =
        Policy.decide(
          [],
          [risk],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert blocked_status == "blocked_by_policy"
      assert blocked_decision["classification"] == "blocked_by_policy"
    end

    for {branch_id, risk} <- [
          {"review_only_readiness_import_invalid",
           %{
             "type" => "operational_readiness_pressure",
             "feedback_scope" => "operational_readiness",
             "readiness_gate_id" => "cadence_import",
             "operational_readiness_status" => "review_required",
             "import_classification" => "review_only",
             "import_blocked" => false,
             "blocked_import_count" => 0,
             "invalid_cadence_import_count" => 1,
             "import_status_counts" => %{"review_required_before_import" => 1},
             "cadence_import_status_counts" => %{"invalid" => 1},
             "required_operator_action" => "review_operational_readiness"
           }},
          {"review_only_quality_gate_import_invalid",
           %{
             "type" => "quality_gate_pressure",
             "feedback_scope" => "quality_gate",
             "gate_id" => "cadence_import",
             "quality_gate_status" => "review_required",
             "import_classification" => "review_only",
             "import_blocked" => false,
             "blocked_import_count" => 0,
             "invalid_cadence_import_count" => 1,
             "import_status_counts" => %{"review_required_before_import" => 1},
             "cadence_import_status_counts" => %{"invalid" => 1},
             "blocked_import_quality_gate_row_ids" => [],
             "required_operator_action" => "review_operational_readiness"
           }}
        ] do
      {review_status, _requirements, _matches, review_decision} =
        Policy.decide(
          [],
          [risk],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert review_status == "operator_review_required"
      assert review_decision["classification"] == "operator_review_required"
    end
  end

  test "fallback policy blocks invalid refresh-budget pressure but leaves drops and limits reviewable" do
    policy = %{blocked_risk_types: ["refresh_budget_blocked"]}

    {blocked_status, _requirements, _matches, blocked_decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "refresh_budget_pressure",
            "feedback_scope" => "refresh_budget",
            "refresh_budget_status" => "invalid",
            "candidate_limit_status" => "invalid",
            "invalid_candidate_limit_policy" => true,
            "invalid_candidate_limit_policy_count" => 1,
            "dropped_candidate_count" => 2
          }
        ],
        %{"id" => "invalid_refresh_budget", "events" => []},
        %{},
        policy
      )

    assert blocked_status == "blocked_by_policy"
    assert blocked_decision["classification"] == "blocked_by_policy"

    {review_status, _requirements, _matches, review_decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "refresh_budget_pressure",
            "feedback_scope" => "refresh_budget",
            "refresh_budget_status" => "dropped",
            "candidate_limit_status" => "dropped",
            "invalid_candidate_limit_policy" => false,
            "invalid_candidate_limit_policy_count" => 0,
            "dropped_candidate_count" => 2
          }
        ],
        %{"id" => "dropped_refresh_budget", "events" => []},
        %{},
        policy
      )

    assert review_status == "operator_review_required"
    assert review_decision["classification"] == "operator_review_required"

    {limited_status, _requirements, _matches, limited_decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "refresh_budget_pressure",
            "feedback_scope" => "refresh_budget",
            "refresh_budget_status" => "limited",
            "candidate_limit_status" => "limited",
            "invalid_candidate_limit_policy" => false,
            "invalid_candidate_limit_policy_count" => 0,
            "dropped_candidate_count" => 0,
            "branch_local_candidate_limit_applied" => true
          }
        ],
        %{"id" => "limited_refresh_budget", "events" => []},
        %{},
        policy
      )

    assert limited_status == "operator_review_required"
    assert limited_decision["classification"] == "operator_review_required"
  end

  test "fallback policy blocks stale refresh-freshness pressure but leaves unknown reviewable" do
    policy = %{blocked_risk_types: ["refresh_freshness_blocked"]}

    {blocked_status, _requirements, _matches, blocked_decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "refresh_freshness_pressure",
            "feedback_scope" => "refresh_freshness",
            "freshness_status" => "stale",
            "state_quality_status" => "stale",
            "freshness_statuses" => ["stale"],
            "stale_reason_count" => 1,
            "unknown_reason_count" => 0,
            "branch_local_stale_pressure" => true
          }
        ],
        %{"id" => "stale_refresh_freshness", "events" => []},
        %{},
        policy
      )

    assert blocked_status == "blocked_by_policy"
    assert blocked_decision["classification"] == "blocked_by_policy"

    {review_status, _requirements, _matches, review_decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "refresh_freshness_pressure",
            "feedback_scope" => "refresh_freshness",
            "freshness_status" => "unknown",
            "state_quality_status" => "unknown",
            "freshness_statuses" => ["unknown"],
            "stale_reason_count" => 0,
            "unknown_reason_count" => 1,
            "branch_local_unknown_pressure" => true
          }
        ],
        %{"id" => "unknown_refresh_freshness", "events" => []},
        %{},
        policy
      )

    assert review_status == "operator_review_required"
    assert review_decision["classification"] == "operator_review_required"
  end

  test "fallback policy blocks expired station-reservation pressure but leaves active reviewable" do
    policy = %{blocked_risk_types: ["station_reservation_expiration_blocked"]}

    for {branch_id, expiration_status} <- [
          {"expired_station_reservation", "expired"},
          {"missing_station_reservation", "missing"}
        ] do
      {blocked_status, _requirements, _matches, blocked_decision} =
        Policy.decide(
          [],
          [
            %{
              "type" => "downlink_completion_gap",
              "feedback_scope" => "station_reservation_hold_import_readiness",
              "station_reservation_id" => "#{expiration_status}_reservation",
              "station_reservation_expiration_status" => expiration_status,
              "station_reservation_expiration_statuses" => [expiration_status],
              "station_reservation_hold_expiration_status" => expiration_status,
              "station_reservation_hold_expiration_statuses" => [expiration_status],
              "required_operator_action" => "review_station_reservation_overlap"
            }
          ],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert blocked_status == "blocked_by_policy"
      assert blocked_decision["classification"] == "blocked_by_policy"
    end

    {review_status, _requirements, _matches, review_decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "downlink_completion_gap",
            "feedback_scope" => "station_reservation_hold_import_readiness",
            "station_reservation_id" => "active_reservation",
            "station_reservation_expiration_status" => "active",
            "station_reservation_expiration_statuses" => ["active"],
            "station_reservation_hold_expiration_status" => "active",
            "station_reservation_hold_expiration_statuses" => ["active"],
            "required_operator_action" => "review_station_reservation_overlap"
          }
        ],
        %{"id" => "active_station_reservation", "events" => []},
        %{},
        policy
      )

    assert review_status == "operator_review_required"
    assert review_decision["classification"] == "operator_review_required"
  end

  test "fallback policy blocks blocked provider counteroffer pressure but leaves active reviewable" do
    policy = %{blocked_risk_types: ["provider_counteroffer_blocked"]}

    for {branch_id, risk} <- [
          {"blocked_provider_counteroffer_import",
           %{
             "type" => "provider_counteroffer_pressure",
             "feedback_scope" => "provider_counteroffer",
             "provider_counteroffer_id" => "counteroffer_blocked_import",
             "provider_counteroffer_import_status" => "blocked",
             "import_readiness_status" => "blocked",
             "import_classification" => "blocked",
             "provider_counteroffer_lock_deadline_status" => "active",
             "counteroffer_lock_deadline_status_counts" => %{"active" => 1},
             "required_operator_action" => "review_provider_counteroffer"
           }},
          {"expired_provider_counteroffer_lock",
           %{
             "type" => "provider_counteroffer_review",
             "feedback_scope" => "provider_counteroffer",
             "provider_counteroffer_id" => "counteroffer_expired_lock",
             "provider_counteroffer_import_status" => "review_required_before_import",
             "import_readiness_status" => "review_required",
             "import_classification" => "review_only",
             "provider_counteroffer_lock_deadline_status" => "expired",
             "counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
             "required_operator_action" => "review_provider_counteroffer"
           }}
        ] do
      {blocked_status, _requirements, _matches, blocked_decision} =
        Policy.decide(
          [],
          [risk],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert blocked_status == "blocked_by_policy"
      assert blocked_decision["classification"] == "blocked_by_policy"
    end

    {review_status, _requirements, _matches, review_decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "provider_counteroffer_pressure",
            "feedback_scope" => "provider_counteroffer",
            "provider_counteroffer_id" => "counteroffer_active_review",
            "provider_counteroffer_import_status" => "review_required_before_import",
            "import_readiness_status" => "review_required",
            "import_classification" => "review_only",
            "provider_counteroffer_lock_deadline_status" => "active",
            "counteroffer_lock_deadline_status_counts" => %{"active" => 1},
            "required_operator_action" => "review_provider_counteroffer"
          }
        ],
        %{"id" => "active_provider_counteroffer", "events" => []},
        %{},
        policy
      )

    assert review_status == "operator_review_required"
    assert review_decision["classification"] == "operator_review_required"
  end

  test "fallback policy blocks provider reservation review pressure but leaves request-ready reviewable" do
    policy = %{blocked_risk_types: ["provider_reservation_request_blocked"]}

    for {branch_id, risk} <- [
          {"provider_reservation_review_required",
           %{
             "type" => "provider_reservation_request_review",
             "feedback_scope" => "contact_allocation_provider_reservation_request",
             "contact_id" => "dl_provider_review",
             "station_reservation_id" => "reservation_review",
             "station_reservation_match_status" => "overlap",
             "provider_reservation_request_status" => "review_required",
             "provider_reservation_row_scope" => "review",
             "required_operator_action" => "review_provider_reservation_request"
           }},
          {"provider_reservation_unmatched_request",
           %{
             "type" => "provider_reservation_request_review",
             "feedback_scope" => "contact_allocation_provider_reservation_request",
             "contact_id" => "dl_provider_unmatched",
             "station_reservation_id" => "reservation_unmatched",
             "station_reservation_match_status" => "unmatched",
             "provider_reservation_request_status" => "request_ready",
             "provider_reservation_row_scope" => "request",
             "required_operator_action" => "review_provider_reservation_request"
           }}
        ] do
      {blocked_status, _requirements, _matches, blocked_decision} =
        Policy.decide(
          [],
          [risk],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert blocked_status == "blocked_by_policy"
      assert blocked_decision["classification"] == "blocked_by_policy"
    end

    {review_status, _requirements, _matches, review_decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "provider_reservation_request_review",
            "feedback_scope" => "contact_allocation_provider_reservation_request",
            "contact_id" => "dl_provider_request_ready",
            "station_reservation_id" => "reservation_request_ready",
            "station_reservation_match_status" => "matched",
            "provider_reservation_request_status" => "request_ready",
            "provider_reservation_row_scope" => "request",
            "required_operator_action" => "review_provider_reservation_request"
          }
        ],
        %{"id" => "request_ready_provider_reservation", "events" => []},
        %{},
        policy
      )

    assert review_status == "operator_review_required"
    assert review_decision["classification"] == "operator_review_required"
  end

  test "fallback policy blocks station reservation conflicts but leaves ownership matches reviewable" do
    policy = %{blocked_risk_types: ["station_reservation_conflict_blocked"]}

    for match_status <- [
          "overlap",
          "conflict",
          "unmatched",
          "unmatched_overlap",
          "owner_mismatch"
        ] do
      {blocked_status, _requirements, _matches, blocked_decision} =
        Policy.decide(
          [],
          [
            %{
              "type" => "downlink_completion_gap",
              "feedback_scope" => "contact_allocation",
              "station_reservation_match_status" => match_status
            }
          ],
          %{"id" => "reservation_#{match_status}", "events" => []},
          %{},
          policy
        )

      assert blocked_status == "blocked_by_policy"
      assert blocked_decision["classification"] == "blocked_by_policy"
    end

    for {branch_id, risk} <- [
          {"reservation_conflict_reason",
           %{
             "type" => "downlink_completion_gap",
             "feedback_scope" => "contact_allocation",
             "derivation_reasons" => ["contact_allocation_reservation_conflict"]
           }},
          {"reservation_conflict_source",
           %{
             "type" => "downlink_completion_gap",
             "feedback_scope" => "contact_allocation",
             "feedback_source" =>
               "mission_state.source_contact_allocation_reservation_conflict_summary"
           }}
        ] do
      {blocked_status, _requirements, _matches, blocked_decision} =
        Policy.decide(
          [],
          [risk],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert blocked_status == "blocked_by_policy"
      assert blocked_decision["classification"] == "blocked_by_policy"
    end

    for match_status <- ["matched", "owner_matched", "owned", "owner", "unknown"] do
      {review_status, _requirements, _matches, review_decision} =
        Policy.decide(
          [],
          [
            %{
              "type" => "downlink_completion_gap",
              "feedback_scope" => "contact_allocation",
              "station_reservation_match_status" => match_status,
              "feedback_source" => "mission_state.source_contact_allocation_summary"
            }
          ],
          %{"id" => "reservation_#{match_status}", "events" => []},
          %{},
          policy
        )

      assert review_status == "operator_review_required"
      assert review_decision["classification"] == "operator_review_required"
    end
  end

  test "fallback policy blocks explicit activity precondition failures but leaves review pressure reviewable" do
    policy = %{blocked_risk_types: ["timeline_activity_precondition_blocked"]}

    for {branch_id, risk} <- [
          {"blocked_count",
           %{
             "type" => "timeline_activity_precondition_review",
             "feedback_scope" => "timeline_activity_precondition",
             "precondition_status" => "review_required",
             "blocked_precondition_count" => 1,
             "review_precondition_count" => 2
           }},
          {"blocked_status",
           %{
             "type" => "timeline_activity_precondition_review",
             "precondition_status" => "blocked",
             "blocked_precondition_count" => 0
           }},
          {"blocked_action",
           %{
             "feedback_scope" => "timeline_activity_precondition",
             "precondition_status" => "unknown",
             "required_operator_action" => "review_blocked_activity_precondition"
           }}
        ] do
      {blocked_status, _requirements, _matches, blocked_decision} =
        Policy.decide(
          [],
          [risk],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert blocked_status == "blocked_by_policy"
      assert blocked_decision["classification"] == "blocked_by_policy"
    end

    for {branch_id, risk} <- [
          {"review_only",
           %{
             "type" => "timeline_activity_precondition_review",
             "feedback_scope" => "timeline_activity_precondition",
             "precondition_status" => "review_required",
             "blocked_precondition_count" => 0,
             "review_precondition_count" => 2,
             "required_operator_action" => "review_activity_precondition"
           }},
          {"unknown",
           %{
             "type" => "timeline_activity_precondition_review",
             "feedback_scope" => "timeline_activity_precondition",
             "precondition_status" => "unknown"
           }}
        ] do
      {review_status, _requirements, _matches, review_decision} =
        Policy.decide(
          [],
          [risk],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert review_status == "operator_review_required"
      assert review_decision["classification"] == "operator_review_required"
    end
  end

  test "fallback policy blocks policy-blocked operational timelines but leaves review counts reviewable" do
    policy = %{blocked_risk_types: ["operational_timeline_policy_blocked"]}

    for {branch_id, risk} <- [
          {"blocked_activity_status",
           %{
             "type" => "operational_timeline_pressure",
             "activity_status_counts" => %{"blocked_by_policy" => 1}
           }},
          {"blocked_approval_status",
           %{
             "feedback_scope" => "operational_timeline",
             "approval_status_counts" => %{"blocked_by_policy" => 2}
           }}
        ] do
      {blocked_status, _requirements, _matches, blocked_decision} =
        Policy.decide(
          [],
          [risk],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert blocked_status == "blocked_by_policy"
      assert blocked_decision["classification"] == "blocked_by_policy"
    end

    for {branch_id, risk} <- [
          {"review_required",
           %{
             "type" => "operational_timeline_pressure",
             "feedback_scope" => "operational_timeline",
             "activity_status_counts" => %{"planned" => 1},
             "approval_status_counts" => %{"operator_review_required" => 1}
           }},
          {"not_evaluated",
           %{
             "type" => "operational_timeline_pressure",
             "feedback_scope" => "operational_timeline",
             "approval_status_counts" => %{"not_evaluated" => 1}
           }},
          {"unknown",
           %{
             "type" => "operational_timeline_pressure",
             "feedback_scope" => "operational_timeline",
             "approval_status_counts" => %{"provider_unknown" => 1}
           }}
        ] do
      {review_status, _requirements, _matches, review_decision} =
        Policy.decide(
          [],
          [risk],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert review_status == "operator_review_required"
      assert review_decision["classification"] == "operator_review_required"
    end
  end

  test "fallback policy blocks unavailable contact-filter replay but leaves review states reviewable" do
    policy = %{blocked_risk_types: ["contact_filter_blocked"]}

    for {branch_id, risk} <- [
          {"unavailable_availability",
           %{
             "type" => "downlink_completion_gap",
             "feedback_scope" => "contact_filter",
             "station_suppression_availability_counts" => %{"unavailable" => 1}
           }},
          {"unavailable_status",
           %{
             "type" => "downlink_completion_gap",
             "feedback_scope" => "contact_filter",
             "station_suppression_status_counts" => %{"unavailable" => 2}
           }},
          {"maintenance_status",
           %{
             "type" => "downlink_completion_gap",
             "feedback_scope" => "contact_filter",
             "station_suppression_status_counts" => %{"maintenance" => 1}
           }}
        ] do
      {blocked_status, _requirements, _matches, blocked_decision} =
        Policy.decide(
          [],
          [risk],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert blocked_status == "blocked_by_policy"
      assert blocked_decision["classification"] == "blocked_by_policy"
    end

    for {branch_id, risk} <- [
          {"reserved",
           %{
             "type" => "downlink_completion_gap",
             "feedback_scope" => "contact_filter",
             "station_suppression_availability_counts" => %{"reserved" => 1},
             "station_suppression_status_counts" => %{"reserved" => 1}
           }},
          {"reduced_capacity",
           %{
             "type" => "downlink_completion_gap",
             "feedback_scope" => "contact_filter",
             "station_suppression_availability_counts" => %{"reduced_capacity" => 1}
           }},
          {"unknown_provider_status",
           %{
             "type" => "downlink_completion_gap",
             "feedback_scope" => "contact_filter",
             "station_suppression_status_counts" => %{"provider_unknown" => 1}
           }}
        ] do
      {review_status, _requirements, _matches, review_decision} =
        Policy.decide(
          [],
          [risk],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert review_status == "operator_review_required"
      assert review_decision["classification"] == "operator_review_required"
    end
  end

  test "fallback policy blocks unavailable station-calendar pressure but leaves review states reviewable" do
    policy = %{blocked_risk_types: ["station_calendar_unavailable_blocked"]}

    for {branch_id, risk} <- [
          {"direct_outage", %{"type" => "ground_station_outage"}},
          {"unavailable_availability",
           %{
             "type" => "station_calendar_pressure",
             "feedback_scope" => "station_calendar",
             "affected_contact_availability_counts" => %{"unavailable" => 1}
           }},
          {"unavailable_status",
           %{
             "type" => "station_calendar_pressure",
             "station_calendar_status_counts" => %{"unavailable" => 2}
           }},
          {"maintenance_status",
           %{
             "feedback_scope" => "station_calendar",
             "station_calendar_status_counts" => %{"maintenance" => 1}
           }}
        ] do
      {blocked_status, _requirements, _matches, blocked_decision} =
        Policy.decide(
          [],
          [risk],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert blocked_status == "blocked_by_policy"
      assert blocked_decision["classification"] == "blocked_by_policy"
    end

    for {branch_id, risk} <- [
          {"reserved",
           %{
             "type" => "station_calendar_pressure",
             "feedback_scope" => "station_calendar",
             "affected_contact_availability_counts" => %{"reserved" => 1},
             "station_calendar_status_counts" => %{"reserved" => 1}
           }},
          {"reduced_capacity",
           %{
             "type" => "station_calendar_pressure",
             "feedback_scope" => "station_calendar",
             "affected_contact_availability_counts" => %{"reduced_capacity" => 1}
           }},
          {"unknown_provider_status",
           %{
             "type" => "station_calendar_pressure",
             "feedback_scope" => "station_calendar",
             "station_calendar_status_counts" => %{"provider_unknown" => 1}
           }}
        ] do
      {review_status, _requirements, _matches, review_decision} =
        Policy.decide(
          [],
          [risk],
          %{"id" => branch_id, "events" => []},
          %{},
          policy
        )

      assert review_status == "operator_review_required"
      assert review_decision["classification"] == "operator_review_required"
    end
  end

  test "matches requirement types grouped risk types and grouped event types" do
    policy = %{
      action_rules: [
        %{
          id: "typed_contact_review",
          requirement_type: "contact_schedule_change",
          classification: "operator_review_required",
          reason: "typed contact changes require review"
        },
        %{
          id: "resource_block",
          risk_types: ["fuel_margin_low", "downlink_capacity_low"],
          classification: "blocked_by_policy",
          reason: "resource state too risky"
        },
        %{
          id: "ops_event_review",
          event_types: ["ground_station_outage", "reduced_station_capacity"],
          classification: "operator_review_required",
          reason: "ground network event requires review"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "dl_1",
            "activity_type" => "downlink",
            "action" => "approve_moved_contact",
            "requirement_type" => "contact_schedule_change",
            "reason" => "missed contact"
          }
        ],
        [%{"type" => "downlink_capacity_low", "reason" => "capacity margin below target"}],
        %{
          "id" => "branch",
          "events" => [%{"type" => "ground_station_outage", "ground_station_id" => "equator"}]
        },
        %{},
        policy
      )

    assert status == "blocked_by_policy"
    assert [%{"policy_classification" => "operator_review_required"}] = requirements
    assert decision["classification"] == "blocked_by_policy"
    assert Enum.any?(matches, &(&1["rule_id"] == "typed_contact_review"))
    assert Enum.any?(matches, &(&1["rule_id"] == "resource_block"))
    assert Enum.any?(matches, &(&1["rule_id"] == "ops_event_review"))
    assert Enum.any?(matches, &(&1["requirement_type"] == "contact_schedule_change"))
  end

  test "matches risk rules by station alias without crossing stations" do
    policy = %{
      action_rules: [
        %{
          id: "equator_capacity_block",
          risk_types: ["downlink_capacity_low"],
          station_id: "equator_prime",
          classification: "blocked_by_policy",
          reason: "equator capacity shortfall blocks branch promotion"
        }
      ]
    }

    {status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "downlink_capacity_low",
            "reason" => "capacity margin below target",
            "station_id" => "equator_prime"
          },
          %{
            "type" => "downlink_capacity_low",
            "reason" => "separate provider site below target",
            "station_id" => "deep_space_net"
          }
        ],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "blocked_by_policy"

    assert [
             %{
               "rule_id" => "equator_capacity_block",
               "risk_type" => "downlink_capacity_low",
               "risk_reason" => "capacity margin below target",
               "ground_station_id" => "equator_prime"
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches risk rules by spacecraft without crossing spacecraft" do
    policy = %{
      action_rules: [
        %{
          id: "leo_1_payload_block",
          risk_types: ["payload_unavailable"],
          spacecraft_id: "leo_1",
          classification: "blocked_by_policy",
          reason: "leo_1 payload outage blocks branch promotion"
        }
      ]
    }

    {status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "payload_unavailable",
            "reason" =>
              "spacecraft leo_1 payload_available false constrains generated candidates",
            "spacecraft_id" => "leo_1"
          },
          %{
            "type" => "payload_unavailable",
            "reason" =>
              "spacecraft leo_2 payload_available false constrains generated candidates",
            "spacecraft_id" => "leo_2"
          }
        ],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "blocked_by_policy"

    assert [
             %{
               "rule_id" => "leo_1_payload_block",
               "risk_type" => "payload_unavailable",
               "spacecraft_id" => "leo_1"
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches risk rules by target without crossing targets" do
    policy = %{
      action_rules: [
        %{
          id: "target_a_observation_review",
          risk_types: ["observation_success_rate_low"],
          target_id: "target_a",
          classification: "operator_review_required",
          reason: "target_a observation feedback requires review"
        }
      ]
    }

    {status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "observation_success_rate_low",
            "reason" => "target target_a observation success feedback factor 0.5",
            "target_id" => "target_a"
          },
          %{
            "type" => "observation_success_rate_low",
            "reason" => "target target_b observation success feedback factor 0.5",
            "target_id" => "target_b"
          }
        ],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "rule_id" => "target_a_observation_review",
               "risk_type" => "observation_success_rate_low",
               "target_id" => "target_a"
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches risk rules by direction without crossing command and downlink evidence" do
    policy = %{
      action_rules: [
        %{
          id: "downlink_confidence_review",
          risk_types: ["contact_success_rate_low"],
          directions: ["downlink"],
          classification: "operator_review_required",
          reason: "downlink confidence risk requires ground-network review"
        }
      ]
    }

    {status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "contact_success_rate_low",
            "reason" => "command link confidence is low",
            "direction" => "command",
            "station_id" => "equator_prime"
          },
          %{
            "type" => "contact_success_rate_low",
            "reason" => "downlink confidence is low",
            "directions" => ["downlink"],
            "station_id" => "equator_prime"
          }
        ],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "rule_id" => "downlink_confidence_review",
               "risk_type" => "contact_success_rate_low",
               "risk_reason" => "downlink confidence is low",
               "direction" => "downlink",
               "directions" => ["downlink"]
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches approval rules by list-valued identity context" do
    policy = %{
      action_rules: [
        %{
          id: "scoped_aggregate_review",
          ground_station_ids: ["equator_prime"],
          spacecraft_ids: ["leo_1"],
          target_ids: ["target_a"],
          classification: "operator_review_required",
          reason: "aggregated scoped approval evidence requires review"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "aggregate_scope",
            "activity_type" => "planned_contact",
            "action" => "review_contact",
            "requirement_type" => "contact_schedule_change",
            "activity_context" => %{
              "station_ids" => ["equator_prime", "deep_space_net"],
              "scenario_ids" => ["leo_1", "leo_2"],
              "target_ids" => ["target_a", "target_b"]
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "activity_id" => "aggregate_scope",
               "policy_classification" => "operator_review_required",
               "approval_rule_matches" => rule_matches
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "scoped_aggregate_review",
               "activity_id" => "aggregate_scope",
               "ground_station_ids" => ["equator_prime", "deep_space_net"],
               "spacecraft_ids" => ["leo_1", "leo_2"],
               "target_ids" => ["target_a", "target_b"]
             }
           ] = matches

    assert rule_matches == matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "orders scoped risk matches by canonical evidence" do
    policy = %{
      action_rules: [
        %{
          id: "target_feedback_review",
          risk_types: ["observation_success_rate_low"],
          target_ids: ["target_a", "target_b"],
          classification: "operator_review_required",
          reason: "target feedback requires review"
        }
      ]
    }

    {_status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [
          %{
            "type" => "observation_success_rate_low",
            "reason" => "target target_b observation success feedback factor 0.5",
            "target_id" => "target_b"
          },
          %{
            "type" => "observation_success_rate_low",
            "reason" => "target target_a observation success feedback factor 0.5",
            "target_id" => "target_a"
          }
        ],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert Enum.map(matches, & &1["target_id"]) == ["target_a", "target_b"]
    assert Enum.map(decision["rule_matches"], & &1["target_id"]) == ["target_a", "target_b"]

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "orders contention policy matches by canonical routing evidence" do
    policy = %{
      action_rules: [
        %{
          id: "contention_route",
          resource_scopes: ["ground_station", "spacecraft"],
          station_calendar_provider_ids: ["provider_a", "provider_b", "provider_z"],
          classification: "operator_review_required",
          reason: "contention routing requires deterministic review order"
        }
      ]
    }

    {_status, _requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "contention_case",
            "activity_type" => "contact_contention_resolution",
            "action" => "review_contact_contention",
            "activity_context" => %{
              "resource_scope" => "spacecraft",
              "station_calendar_provider_ids" => ["provider_z"]
            }
          },
          %{
            "activity_id" => "contention_case",
            "activity_type" => "contact_contention_resolution",
            "action" => "review_contact_contention",
            "activity_context" => %{
              "resource_scope" => "ground_station",
              "station_calendar_provider_ids" => ["provider_b"]
            }
          },
          %{
            "activity_id" => "contention_case",
            "activity_type" => "contact_contention_resolution",
            "action" => "review_contact_contention",
            "activity_context" => %{
              "resource_scope" => "ground_station",
              "station_calendar_provider_ids" => ["provider_a"]
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert Enum.map(matches, &{&1["resource_scope"], &1["station_calendar_provider_ids"]}) == [
             {"ground_station", ["provider_a"]},
             {"ground_station", ["provider_b"]},
             {"spacecraft", ["provider_z"]}
           ]

    assert Enum.map(
             decision["rule_matches"],
             &{&1["resource_scope"], &1["station_calendar_provider_ids"]}
           ) == [
             {"ground_station", ["provider_a"]},
             {"ground_station", ["provider_b"]},
             {"spacecraft", ["provider_z"]}
           ]

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches branch event rules by station alias without crossing stations" do
    policy = %{
      action_rules: [
        %{
          id: "equator_outage_review",
          event_types: ["ground_station_outage"],
          station_id: "equator_prime",
          classification: "operator_review_required",
          reason: "equator outage requires ground-network review"
        }
      ]
    }

    {_status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [],
        %{
          "id" => "branch",
          "events" => [
            %{
              "type" => "ground_station_outage",
              "station_id" => "equator_prime"
            },
            %{
              "type" => "ground_station_outage",
              "station_id" => "deep_space_net"
            }
          ]
        },
        %{},
        policy
      )

    assert [
             %{
               "rule_id" => "equator_outage_review",
               "event_type" => "ground_station_outage",
               "ground_station_id" => "equator_prime"
             }
           ] = matches

    assert decision["classification"] == "operator_review_required"
  end

  test "matches branch event rules by direction without crossing event types" do
    policy = %{
      action_rules: [
        %{
          id: "command_event_review",
          event_types: ["contact_success_feedback"],
          directions: ["command", "uplink"],
          classification: "operator_review_required",
          reason: "command feedback events require command authority review"
        }
      ]
    }

    {_status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [],
        %{
          "id" => "branch",
          "events" => [
            %{
              "type" => "contact_success_feedback",
              "direction" => "downlink",
              "station_id" => "equator_prime"
            },
            %{
              "type" => "contact_success_feedback",
              "directions" => ["command", "tracking"],
              "station_id" => "equator_prime"
            }
          ]
        },
        %{},
        policy
      )

    assert [
             %{
               "rule_id" => "command_event_review",
               "event_type" => "contact_success_feedback",
               "direction" => "command",
               "directions" => ["command", "tracking"]
             }
           ] = matches

    assert decision["classification"] == "operator_review_required"

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches branch event rules by target without crossing targets" do
    policy = %{
      action_rules: [
        %{
          id: "target_a_urgent_review",
          event_types: ["urgent_target"],
          target_id: "target_a",
          classification: "operator_review_required",
          reason: "target_a urgent event requires review"
        }
      ]
    }

    {_status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [],
        %{
          "id" => "branch",
          "events" => [
            %{"type" => "urgent_target", "target_id" => "target_b"},
            %{"type" => "urgent_target", "target_id" => "target_a"}
          ]
        },
        %{},
        policy
      )

    assert [
             %{
               "rule_id" => "target_a_urgent_review",
               "event_type" => "urgent_target",
               "target_id" => "target_a"
             }
           ] = matches

    assert decision["classification"] == "operator_review_required"

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches branch event rules by spacecraft without crossing spacecraft" do
    policy = %{
      action_rules: [
        %{
          id: "leo_1_degraded_review",
          event_types: ["degraded_spacecraft"],
          spacecraft_id: "leo_1",
          classification: "operator_review_required",
          reason: "leo_1 degraded branch requires review"
        }
      ]
    }

    {_status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [],
        %{
          "id" => "branch",
          "events" => [
            %{"type" => "degraded_spacecraft", "scenario_id" => "leo_2"},
            %{"type" => "degraded_spacecraft", "scenario_id" => "leo_1"}
          ]
        },
        %{},
        policy
      )

    assert [
             %{
               "rule_id" => "leo_1_degraded_review",
               "event_type" => "degraded_spacecraft",
               "spacecraft_id" => "leo_1"
             }
           ] = matches

    assert decision["classification"] == "operator_review_required"

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches approval requirements by target without crossing targets" do
    policy = %{
      action_rules: [
        %{
          id: "target_a_strategic_review",
          requirement_types: ["strategic_addition"],
          target_id: "target_a",
          classification: "operator_review_required",
          reason: "target_a strategic addition requires review"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "obs_b",
            "activity_type" => "observe",
            "action" => "approve_strategic_addition",
            "requirement_type" => "strategic_addition",
            "activity_context" => %{"target_id" => "target_b"}
          },
          %{
            "activity_id" => "obs_a",
            "activity_type" => "observe",
            "action" => "approve_strategic_addition",
            "requirement_type" => "strategic_addition",
            "activity_context" => %{"target_id" => "target_a"}
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "obs_a" and
                 &1["policy_classification"] == "operator_review_required")
           )

    refute Enum.any?(
             requirements,
             &(&1["activity_id"] == "obs_b" and &1["policy_classification"])
           )

    assert [
             %{
               "rule_id" => "target_a_strategic_review",
               "activity_id" => "obs_a",
               "target_id" => "target_a"
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches approval requirements by spacecraft without crossing spacecraft" do
    policy = %{
      action_rules: [
        %{
          id: "leo_1_command_review",
          requirement_types: ["command_review"],
          spacecraft_id: "leo_1",
          classification: "operator_review_required",
          reason: "leo_1 command review"
        }
      ]
    }

    {_status, _requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "cmd_2",
            "activity_type" => "command",
            "action" => "approve_command",
            "requirement_type" => "command_review",
            "source_activity_context" => %{"spacecraft_id" => "leo_2"}
          },
          %{
            "activity_id" => "cmd_1",
            "activity_type" => "command",
            "action" => "approve_command",
            "requirement_type" => "command_review",
            "source_activity_context" => %{"scenario_id" => "leo_1"}
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert [
             %{
               "rule_id" => "leo_1_command_review",
               "activity_id" => "cmd_1",
               "spacecraft_id" => "leo_1"
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches feasibility rules by target without crossing targets" do
    policy = %{
      action_rules: [
        %{
          id: "target_a_placeholder_review",
          feasibility_status: "unvalidated_placeholder",
          target_id: "target_a",
          classification: "operator_review_required",
          reason: "target_a placeholder requires review"
        }
      ]
    }

    {status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [],
        %{"id" => "branch", "events" => []},
        %{
          "strategic_additions" => [
            %{
              "id" => "obs_b",
              "type" => "observe",
              "target_id" => "target_b",
              "feasibility" => %{"status" => "unvalidated_placeholder"}
            },
            %{
              "id" => "obs_a",
              "type" => "observe",
              "target_id" => "target_a",
              "feasibility" => %{"status" => "unvalidated_placeholder"}
            }
          ]
        },
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "rule_id" => "target_a_placeholder_review",
               "activity_id" => "obs_a",
               "feasibility_status" => "unvalidated_placeholder",
               "target_id" => "target_a"
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches feasibility rules by direction without crossing candidate additions" do
    policy = %{
      action_rules: [
        %{
          id: "validated_downlink_candidate_review",
          feasibility_status: "validated_candidate_window",
          directions: ["downlink"],
          classification: "operator_review_required",
          reason: "validated downlink additions require ground-network review"
        }
      ]
    }

    {status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [],
        %{"id" => "branch", "events" => []},
        %{
          "strategic_additions" => [
            %{
              "id" => "cmd_candidate",
              "type" => "planned_contact",
              "direction" => "command",
              "feasibility" => %{"status" => "validated_candidate_window"}
            },
            %{
              "id" => "dl_candidate",
              "type" => "downlink",
              "direction" => "downlink",
              "feasibility" => %{"status" => "validated_candidate_window"}
            }
          ]
        },
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "rule_id" => "validated_downlink_candidate_review",
               "activity_id" => "dl_candidate",
               "direction" => "downlink",
               "directions" => ["downlink"],
               "feasibility_status" => "validated_candidate_window"
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches feedback provenance on branch events, approval context, and feasibility" do
    policy = %{
      action_rules: [
        %{
          id: "tradeoff_event_review",
          event_type: "downlink_completion_gap",
          feedback_source: "prior_plan.source_objective_tradeoff_report",
          trust_boundary: "ops_tradeoff_review",
          classification: "operator_review_required",
          reason: "objective tradeoff event needs review"
        },
        %{
          id: "tradeoff_requirement_review",
          feedback_sources: ["prior_plan.source_objective_tradeoff_report"],
          feedback_scope: "objective_tradeoff",
          source_event_type: "downlink_completion_gap",
          classification: "operator_review_required",
          reason: "objective tradeoff approval context needs review"
        },
        %{
          id: "tradeoff_feasibility_review",
          feasibility_status: "validated_candidate_window",
          feedback_source: "prior_plan.source_objective_tradeoff_report",
          feedback_scope: "objective_tradeoff",
          source_event_type: "downlink_completion_gap",
          classification: "operator_review_required",
          reason: "objective tradeoff strategic addition needs review"
        }
      ]
    }

    {status, _requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "dl_tradeoff",
            "activity_type" => "downlink",
            "action" => "approve_strategic_addition",
            "requirement_type" => "strategic_addition",
            "activity_context" => %{
              "feedback_source" => "prior_plan.source_objective_tradeoff_report",
              "feedback_scope" => "objective_tradeoff",
              "source_event_type" => "downlink_completion_gap"
            }
          }
        ],
        [],
        %{
          "id" => "branch",
          "events" => [
            %{
              "type" => "downlink_completion_gap",
              "feedback_source" => "prior_plan.source_objective_tradeoff_report",
              "feedback_scope" => "objective_tradeoff",
              "trust_boundary" => "ops_tradeoff_review"
            }
          ]
        },
        %{
          "strategic_additions" => [
            %{
              "id" => "dl_tradeoff",
              "type" => "downlink",
              "feasibility" => %{
                "status" => "validated_candidate_window",
                "feedback_source" => "prior_plan.source_objective_tradeoff_report",
                "feedback_scope" => "objective_tradeoff",
                "trust_boundary" => "ops_tradeoff_review",
                "source_event_type" => "downlink_completion_gap"
              }
            },
            %{
              "id" => "dl_other",
              "type" => "downlink",
              "feasibility" => %{
                "status" => "validated_candidate_window",
                "feedback_source" => "prior_plan.source_constraint_report",
                "feedback_scope" => "constraint_report",
                "source_event_type" => "downlink_completion_gap"
              }
            }
          ]
        },
        policy
      )

    assert status == "operator_review_required"

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "tradeoff_event_review" and
                 &1["event_type"] == "downlink_completion_gap" and
                 &1["feedback_source"] == "prior_plan.source_objective_tradeoff_report" and
                 &1["trust_boundary"] == "ops_tradeoff_review")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "tradeoff_requirement_review" and
                 &1["activity_id"] == "dl_tradeoff" and
                 &1["feedback_scope"] == "objective_tradeoff" and
                 &1["source_event_type"] == "downlink_completion_gap")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "tradeoff_feasibility_review" and
                 &1["activity_id"] == "dl_tradeoff" and
                 &1["feasibility_status"] == "validated_candidate_window" and
                 &1["feedback_source"] == "prior_plan.source_objective_tradeoff_report")
           )

    refute Enum.any?(matches, &(&1["activity_id"] == "dl_other"))

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches branch event approval and allocation status selectors" do
    policy = %{
      action_rules: [
        %{
          id: "policy_blocked_allocation_pressure",
          event_types: ["downlink_completion_gap"],
          approval_statuses: ["blocked_by_policy"],
          allocation_status: "allocated",
          effective_allocation_statuses: ["policy_blocked"],
          classification: "blocked_by_policy",
          reason: "policy-blocked allocation pressure cannot be promoted"
        }
      ]
    }

    {status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [],
        %{
          "id" => "branch",
          "events" => [
            %{
              "type" => "downlink_completion_gap",
              "approval_status" => "blocked_by_policy",
              "allocation_status" => "allocated",
              "effective_allocation_status" => "policy_blocked",
              "allocation_reason" => "selected_by_contention_resolution"
            }
          ]
        },
        %{},
        policy
      )

    assert status == "blocked_by_policy"

    assert [
             %{
               "rule_id" => "policy_blocked_allocation_pressure",
               "event_type" => "downlink_completion_gap",
               "approval_status" => "blocked_by_policy",
               "allocation_status" => "allocated",
               "effective_allocation_status" => "policy_blocked",
               "allocation_reason" => "selected_by_contention_resolution"
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches branch event embedded policy classification selectors" do
    policy = %{
      action_rules: [
        %{
          id: "embedded_policy_decision_block",
          event_types: ["downlink_completion_gap"],
          policy_classifications: ["blocked_by_policy"],
          classification: "blocked_by_policy",
          reason: "embedded policy decision blocks branch promotion"
        }
      ]
    }

    {status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [],
        %{
          "id" => "branch",
          "events" => [
            %{
              "type" => "downlink_completion_gap",
              "policy_classification" => "blocked_by_policy"
            }
          ]
        },
        %{},
        policy
      )

    assert status == "blocked_by_policy"

    assert [
             %{
               "rule_id" => "embedded_policy_decision_block",
               "event_type" => "downlink_completion_gap",
               "policy_classification" => "blocked_by_policy"
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches approval requirement policy classification selectors without overmatching" do
    policy = %{
      action_rules: [
        %{
          id: "blocked_requirement_policy_classification",
          policy_classifications: ["blocked_by_policy"],
          classification: "operator_review_required",
          reason: "blocked requirements require policy review"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "blocked_contact",
            "activity_type" => "planned_contact",
            "action" => "review_blocked_contact",
            "requirement_type" => "contact_schedule_change",
            "policy_classification" => "blocked_by_policy"
          },
          %{
            "activity_id" => "review_contact",
            "activity_type" => "planned_contact",
            "action" => "review_contact",
            "requirement_type" => "contact_schedule_change",
            "policy_classification" => "operator_review_required"
          }
        ],
        [],
        %{"id" => "requirements", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "rule_id" => "blocked_requirement_policy_classification",
               "activity_id" => "blocked_contact",
               "policy_classification" => "blocked_by_policy"
             }
           ] = matches

    assert Enum.find(requirements, &(&1["activity_id"] == "blocked_contact"))[
             "policy_classification"
           ] == "operator_review_required"

    assert Enum.find(requirements, &(&1["activity_id"] == "review_contact"))[
             "policy_classification"
           ] == "operator_review_required"

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches feasibility rules by spacecraft and station without crossing scope" do
    policy = %{
      action_rules: [
        %{
          id: "leo_1_equator_placeholder_review",
          feasibility_status: "unvalidated_placeholder",
          spacecraft_id: "leo_1",
          station_id: "equator_prime",
          classification: "operator_review_required",
          reason: "leo_1 equator placeholder requires review"
        }
      ]
    }

    {_status, _requirements, matches, decision} =
      Policy.decide(
        [],
        [],
        %{"id" => "branch", "events" => []},
        %{
          "strategic_additions" => [
            %{
              "id" => "dl_other_spacecraft",
              "type" => "downlink",
              "scenario_id" => "leo_2",
              "ground_station_id" => "equator_prime",
              "feasibility" => %{"status" => "unvalidated_placeholder"}
            },
            %{
              "id" => "dl_other_station",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "ground_station_id" => "deep_space_net",
              "feasibility" => %{"status" => "unvalidated_placeholder"}
            },
            %{
              "id" => "dl_match",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "station_id" => "equator_prime",
              "feasibility" => %{"status" => "unvalidated_placeholder"}
            }
          ]
        },
        policy
      )

    assert [
             %{
               "rule_id" => "leo_1_equator_placeholder_review",
               "activity_id" => "dl_match",
               "feasibility_status" => "unvalidated_placeholder",
               "ground_station_id" => "equator_prime",
               "spacecraft_id" => "leo_1"
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches contact authority rules by direction and ground station context" do
    policy = %{
      action_rules: [
        %{
          id: "uplink_station_review",
          directions: ["uplink", "command"],
          ground_station_ids: ["equator_prime", "deep_space_net"],
          classification: "operator_review_required",
          reason: "uplink and command contacts require station authority review"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "uplink_1",
            "activity_type" => "planned_contact",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "reason" => "uplink intent requires review",
            "activity_context" => %{
              "direction" => "uplink",
              "ground_station_id" => "equator_prime"
            }
          },
          %{
            "activity_id" => "downlink_1",
            "activity_type" => "downlink",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "reason" => "downlink intent requires review",
            "activity_context" => %{
              "direction" => "downlink",
              "ground_station_id" => "equator_prime"
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"
    assert decision["classification"] == "operator_review_required"

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "uplink_1" and
                 &1["policy_classification"] == "operator_review_required")
           )

    refute Enum.any?(
             requirements,
             &(&1["activity_id"] == "downlink_1" and &1["policy_classification"])
           )

    assert [
             %{
               "rule_id" => "uplink_station_review",
               "direction" => "uplink",
               "ground_station_id" => "equator_prime"
             }
           ] = matches
  end

  test "normalizes provider-style direction aliases before policy matching" do
    policy = %{
      action_rules: [
        %{
          id: "provider_direction_review",
          directions: [:up_link, "commanding"],
          station_calendar_directions: ["CMD"],
          classification: "operator_review_required",
          reason: "provider direction aliases require canonical command authority"
        },
        %{
          id: "provider_tracking_health_review",
          directions: ["Track-ing"],
          station_calendar_directions: ["Health Check Window"],
          classification: "operator_review_required",
          reason: "provider tracking and health-check aliases require canonical authority"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "uplink_alias_1",
            "activity_type" => "planned_contact",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "reason" => "provider aliases should match canonical policy",
            "activity_context" => %{
              "direction" => " Up-Link ",
              "station_calendar_directions" => ["commanding"]
            }
          },
          %{
            "activity_id" => "tracking_alias_1",
            "activity_type" => "tracking",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "reason" => "provider tracking aliases should match canonical policy",
            "activity_context" => %{
              "direction" => "TRACK",
              "station_calendar_direction" => "healthcheck"
            }
          },
          %{
            "activity_id" => "downlink_alias_miss",
            "activity_type" => "planned_contact",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "reason" => "provider alias should not cross canonical direction families",
            "activity_context" => %{
              "direction" => "down link",
              "station_calendar_direction" => "healthcheck"
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "uplink_alias_1" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "tracking_alias_1" and
                 &1["policy_classification"] == "operator_review_required")
           )

    refute Enum.any?(
             requirements,
             &(&1["activity_id"] == "downlink_alias_miss" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "provider_direction_review" and
                 &1["direction"] == "uplink" and
                 &1["directions"] == ["uplink"] and
                 &1["station_calendar_direction"] == "command" and
                 &1["station_calendar_directions"] == ["command"])
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "provider_tracking_health_review" and
                 &1["direction"] == "tracking" and
                 &1["directions"] == ["tracking"] and
                 &1["station_calendar_direction"] == "health_check" and
                 &1["station_calendar_directions"] == ["health_check"])
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches contact authority rules against provider station-id context" do
    policy = %{
      action_rules: [
        %{
          id: "provider_station_review",
          directions: ["downlink"],
          ground_station_id: "equator_prime",
          classification: "operator_review_required",
          reason: "provider station contact requires station authority review"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "provider_downlink_1",
            "activity_type" => "contact",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "reason" => "provider contact requires review",
            "activity_context" => %{
              "direction" => "downlink",
              "station_id" => "equator_prime"
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"
    assert decision["classification"] == "operator_review_required"

    assert [
             %{
               "activity_id" => "provider_downlink_1",
               "policy_classification" => "operator_review_required"
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "provider_station_review",
               "direction" => "downlink",
               "ground_station_id" => "equator_prime"
             }
           ] = matches
  end

  test "normalizes provider station-id policy rules into canonical station matches" do
    policy = %{
      action_rules: [
        %{
          id: "provider_rule_station_alias",
          directions: ["downlink"],
          station_id: "equator_prime",
          classification: "operator_review_required",
          reason: "provider station alias should match canonical requirements"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "downlink_1",
            "activity_type" => "downlink",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "reason" => "contact requires review",
            "activity_context" => %{
              "direction" => "downlink",
              "ground_station_id" => "equator_prime"
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"
    assert decision["classification"] == "operator_review_required"

    assert [
             %{
               "activity_id" => "downlink_1",
               "policy_classification" => "operator_review_required"
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "provider_rule_station_alias",
               "direction" => "downlink",
               "ground_station_id" => "equator_prime"
             }
           ] = matches
  end

  test "matches contention policy rules by resource scope resolution and provider calendar context" do
    policy = %{
      action_rules: [
        %{
          id: "provider_reservation_contention_review",
          resource_scopes: ["ground_station"],
          required_operator_actions: ["review_contact_contention"],
          operator_action_reasons: ["same_station_overlapping_contact_windows"],
          allocation_statuses: ["deferred"],
          effective_allocation_statuses: ["deferred"],
          allocation_reasons: ["same_station_contention"],
          selection_reasons: ["highest_priority_highest_score"],
          selected_priority_sources: ["command_contact_priority"],
          station_calendar_provider_ids: ["provider_calendar"],
          station_calendar_provider_entry_ids: ["provider_entry_1"],
          station_calendar_reservation_ids: ["reservation_1"],
          station_calendar_trust_boundary_statuses: ["declared"],
          station_calendar_directions: ["command"],
          classification: "operator_review_required",
          reason: "provider reservation contention requires ground-network authority review",
          escalation_queue: "ground_network",
          required_authority: "contact_schedule_authority"
        },
        %{
          id: "duplicate_contact_identity_block",
          resolution_issues: ["duplicate_contact_id"],
          classification: "blocked_by_policy",
          reason: "ambiguous duplicate contact identities cannot be auto-routed"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "station:equator_prime:contention:1",
            "activity_type" => "contact_contention_resolution",
            "action" => "recommend_preferred_contact_for_operator_review",
            "requirement_type" => "contact_schedule_change",
            "reason" => "resolve provider station contention",
            "activity_context" => %{
              "resource_scope" => "ground_station",
              "direction" => "uplink",
              "required_operator_action" => "review_contact_contention",
              "operator_action_reason" => "same_station_overlapping_contact_windows",
              "allocation_status" => "deferred",
              "effective_allocation_status" => "deferred",
              "allocation_reason" => "same_station_contention",
              "ground_station_id" => "equator_prime",
              "selection_reason" => "highest_priority_highest_score",
              "selected_priority_source" => "command_contact_priority",
              "station_calendar_provider_ids" => ["provider_calendar"],
              "station_calendar_provider_entry_ids" => ["provider_entry_1"],
              "station_calendar_reservation_ids" => ["reservation_1"],
              "station_calendar_trust_boundary_statuses" => ["declared", "missing"],
              "station_calendar_directions" => ["command"]
            }
          },
          %{
            "activity_id" => "station:equator_prime:contention:ambiguous",
            "activity_type" => "contact_contention_resolution",
            "action" => "review_ambiguous_contact_contention_identity",
            "requirement_type" => "contact_schedule_change",
            "reason" => "resolve ambiguous duplicate contact identity",
            "activity_context" => %{
              "resource_scope" => "ground_station",
              "resolution_status" => "ambiguous_contact_identity",
              "resolution_issue" => "duplicate_contact_id",
              "station_calendar_provider_ids" => ["other_provider"]
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "blocked_by_policy"
    assert decision["classification"] == "blocked_by_policy"

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "station:equator_prime:contention:1" and
                 &1["policy_classification"] == "operator_review_required")
           )

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "station:equator_prime:contention:ambiguous" and
                 &1["policy_classification"] == "blocked_by_policy")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "provider_reservation_contention_review" and
                 &1["resource_scope"] == "ground_station" and
                 &1["required_operator_action"] == "review_contact_contention" and
                 &1["operator_action_reason"] == "same_station_overlapping_contact_windows" and
                 &1["allocation_status"] == "deferred" and
                 &1["effective_allocation_status"] == "deferred" and
                 &1["allocation_reason"] == "same_station_contention" and
                 &1["selection_reason"] == "highest_priority_highest_score" and
                 &1["selected_priority_source"] == "command_contact_priority" and
                 &1["station_calendar_provider_ids"] == ["provider_calendar"] and
                 &1["station_calendar_provider_entry_ids"] == ["provider_entry_1"] and
                 &1["station_calendar_reservation_id"] == "reservation_1" and
                 &1["station_calendar_reservation_ids"] == ["reservation_1"] and
                 &1["station_calendar_trust_boundary_statuses"] == ["declared", "missing"] and
                 &1["station_calendar_direction"] == "command" and
                 &1["station_calendar_directions"] == ["command"] and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "duplicate_contact_identity_block" and
                 &1["resolution_status"] == "ambiguous_contact_identity" and
                 &1["resolution_issue"] == "duplicate_contact_id")
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches contention policy rules by missing priority-field evidence" do
    policy = %{
      action_rules: [
        %{
          id: "missing_priority_field_review",
          activity_types: ["contact_allocation"],
          allocation_statuses: ["allocated"],
          priority_fields_without_numeric_evidence_count_min: 1,
          priority_fields_without_numeric_evidence: ["missing_priority"],
          classification: "operator_review_required",
          reason: "declared contact-priority field had no numeric evidence",
          escalation_queue: "ground_network",
          required_authority: "contact_schedule_authority"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "priority_command",
            "activity_type" => "contact_allocation",
            "action" => "review_contact_allocation",
            "requirement_type" => "contact_schedule_change",
            "activity_context" => %{
              "allocation_status" => "allocated",
              "priority_fields_without_numeric_evidence_count" => 2,
              "priority_fields_without_numeric_evidence" => [
                "missing_priority",
                "other_missing_priority"
              ],
              "selected_priority_source" => "priority"
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "activity_id" => "priority_command",
               "policy_classification" => "operator_review_required"
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "missing_priority_field_review",
               "priority_fields_without_numeric_evidence_count" => 2,
               "priority_fields_without_numeric_evidence" => [
                 "missing_priority",
                 "other_missing_priority"
               ],
               "required_authority" => "contact_schedule_authority"
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches allocation and suppression list-valued requirement context" do
    policy = %{
      action_rules: [
        %{
          id: "aggregated_allocation_suppression_review",
          activity_types: ["contact_allocation"],
          resource_scopes: ["ground_station"],
          selection_reasons: ["highest_priority_highest_score"],
          selected_priority_sources: ["command_contact_priority"],
          priority_fields_without_numeric_evidence: ["missing_priority"],
          resolution_statuses: ["ambiguous_contact_identity"],
          resolution_issues: ["duplicate_contact_id"],
          required_operator_actions: ["review_contact_allocation"],
          operator_action_reasons: ["same_station_overlapping_contact_windows"],
          allocation_statuses: ["deferred"],
          effective_allocation_statuses: ["policy_blocked"],
          allocation_reasons: ["policy_blocked"],
          suppressed_reasons: ["antenna_unavailable"],
          resource_blocking_dimensions: ["antenna"],
          classification: "operator_review_required",
          reason: "aggregated allocation suppression evidence requires review",
          required_authority: "contact_schedule_authority"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "allocation:aggregate",
            "activity_type" => "contact_allocation",
            "action" => "review_contact_allocation",
            "requirement_type" => "contact_schedule_change",
            "activity_context" => %{
              "resource_scopes" => ["ground_station"],
              "selection_reasons" => ["highest_priority_highest_score"],
              "selected_priority_sources" => ["command_contact_priority"],
              "priority_fields_without_numeric_evidence" => [
                "missing_priority",
                "other_missing_priority"
              ],
              "resolution_statuses" => ["ambiguous_contact_identity"],
              "resolution_issues" => ["duplicate_contact_id"],
              "required_operator_actions" => ["review_contact_allocation"],
              "operator_action_reasons" => ["same_station_overlapping_contact_windows"],
              "allocation_statuses" => ["deferred", "allocated"],
              "effective_allocation_statuses" => ["policy_blocked"],
              "allocation_reasons" => ["policy_blocked"],
              "suppressed_reasons" => ["antenna_unavailable"],
              "resource_blocking_dimensions" => ["antenna"]
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "activity_id" => "allocation:aggregate",
               "policy_classification" => "operator_review_required",
               "approval_rule_matches" => rule_matches
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "aggregated_allocation_suppression_review",
               "resource_scopes" => ["ground_station"],
               "selection_reasons" => ["highest_priority_highest_score"],
               "selected_priority_sources" => ["command_contact_priority"],
               "priority_fields_without_numeric_evidence" => [
                 "missing_priority",
                 "other_missing_priority"
               ],
               "resolution_statuses" => ["ambiguous_contact_identity"],
               "resolution_issues" => ["duplicate_contact_id"],
               "required_operator_actions" => ["review_contact_allocation"],
               "operator_action_reasons" => ["same_station_overlapping_contact_windows"],
               "allocation_statuses" => ["deferred", "allocated"],
               "effective_allocation_statuses" => ["policy_blocked"],
               "allocation_reasons" => ["policy_blocked"],
               "suppressed_reasons" => ["antenna_unavailable"],
               "resource_blocking_dimensions" => ["antenna"],
               "required_authority" => "contact_schedule_authority"
             }
           ] = matches

    assert rule_matches == matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "ground-network bundle reviews any missing priority-field evidence by count" do
    {status, _requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "priority_command",
            "activity_type" => "contact_allocation",
            "action" => "review_contact_allocation",
            "requirement_type" => "contact_schedule_change",
            "activity_context" => %{
              "allocation_status" => "allocated",
              "priority_fields_without_numeric_evidence_count" => 1,
              "priority_fields_without_numeric_evidence" => ["mission_priority"]
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert status == "operator_review_required"

    assert Enum.any?(
             matches,
             &(&1["rule_id"] == "missing_priority_field_evidence_review" and
                 &1["priority_fields_without_numeric_evidence_count"] == 1 and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches contention policy rules by overlap pressure metrics" do
    policy = %{
      action_rules: [
        %{
          id: "high_overlap_contention_review",
          activity_types: ["contact_contention_resolution"],
          required_operator_actions: ["review_contact_contention"],
          contention_window_s_min: 90,
          total_contact_duration_s_min: 180,
          overlap_duration_s_min: 30,
          max_concurrent_contacts_min: 3,
          overlap_contact_pair_count_min: 2,
          classification: "operator_review_required",
          reason: "high-overlap station contention requires ground-network authority",
          escalation_queue: "ground_network"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "station:equator_prime:contention:low",
            "activity_type" => "contact_contention_resolution",
            "action" => "recommend_preferred_contact_for_operator_review",
            "requirement_type" => "contact_schedule_change",
            "reason" => "low-pressure station contention",
            "activity_context" => %{
              "required_operator_action" => "review_contact_contention",
              "contention_window_s" => 95.0,
              "total_contact_duration_s" => 190.0,
              "overlap_duration_s" => 20.0,
              "max_concurrent_contacts" => 2,
              "overlap_contact_pair_count" => 1
            }
          },
          %{
            "activity_id" => "station:equator_prime:contention:high",
            "activity_type" => "contact_contention_resolution",
            "action" => "recommend_preferred_contact_for_operator_review",
            "requirement_type" => "contact_schedule_change",
            "reason" => "high-pressure station contention",
            "activity_context" => %{
              "required_operator_action" => "review_contact_contention",
              "contention_window_s" => 120.0,
              "total_contact_duration_s" => 260.0,
              "overlap_duration_s" => 45.0,
              "max_concurrent_contacts" => 3,
              "overlap_contact_pair_count" => 3
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert Enum.any?(
             requirements,
             &(&1["activity_id"] == "station:equator_prime:contention:high" and
                 &1["policy_classification"] == "operator_review_required")
           )

    refute Enum.any?(
             matches,
             &(&1["activity_id"] == "station:equator_prime:contention:low")
           )

    assert [
             %{
               "rule_id" => "high_overlap_contention_review",
               "activity_id" => "station:equator_prime:contention:high",
               "contention_window_s" => 120.0,
               "total_contact_duration_s" => 260.0,
               "overlap_duration_s" => 45.0,
               "max_concurrent_contacts" => 3,
               "overlap_contact_pair_count" => 3,
               "escalation_queue" => "ground_network"
             }
           ] = matches

    assert decision["rule_matches"] == matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches station-calendar direction separately from contact direction" do
    policy = %{
      action_rules: [
        %{
          id: "calendar_command_contact_review",
          station_calendar_directions: ["command"],
          classification: "operator_review_required",
          reason: "command station-calendar evidence requires authority review"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "contact:command-over-downlink-calendar",
            "activity_type" => "planned_contact",
            "action" => "review_contact",
            "requirement_type" => "contact_schedule_change",
            "reason" => "contact direction is command but provider calendar is downlink",
            "activity_context" => %{
              "direction" => "command",
              "station_calendar_directions" => ["downlink"]
            }
          },
          %{
            "activity_id" => "contact:downlink-over-command-calendar",
            "activity_type" => "planned_contact",
            "action" => "review_contact",
            "requirement_type" => "contact_schedule_change",
            "reason" => "provider calendar direction is command",
            "activity_context" => %{
              "direction" => "downlink",
              "station_calendar_directions" => ["command"]
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "activity_id" => "contact:downlink-over-command-calendar",
               "policy_classification" => "operator_review_required"
             }
           ] =
             Enum.filter(
               requirements,
               &(&1["policy_classification"] == "operator_review_required")
             )

    assert [
             %{
               "rule_id" => "calendar_command_contact_review",
               "activity_id" => "contact:downlink-over-command-calendar",
               "direction" => "downlink",
               "station_calendar_direction" => "command",
               "station_calendar_directions" => ["command"]
             }
           ] = matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches timeline transition application policy rules" do
    policy = %{
      action_rules: [
        %{
          id: "preserved_source_transition_review",
          transition_decisions: ["preserve_source"],
          application_status: "source_preserved_pending_review",
          classification: "operator_review_required",
          reason: "preserved source timeline transition requires planning review",
          escalation_queue: "mission_planning",
          required_authority: "timeline_protection_authority"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "timeline:cmd_lock",
            "activity_type" => "timeline_transition",
            "action" => "review_timeline_change",
            "requirement_type" => "operator_review",
            "reason" => "protected command transition preserved the source activity",
            "activity_context" => %{
              "transition_decision" => "preserve_source",
              "application_status" => "source_preserved_pending_review"
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "activity_id" => "timeline:cmd_lock",
               "policy_classification" => "operator_review_required",
               "approval_rule_matches" => rule_matches
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "preserved_source_transition_review",
               "transition_decision" => "preserve_source",
               "application_status" => "source_preserved_pending_review",
               "escalation_queue" => "mission_planning",
               "required_authority" => "timeline_protection_authority"
             }
           ] = matches

    assert rule_matches == matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches nested timeline protection decision policy context" do
    policy = %{
      action_rules: [
        %{
          id: "protected_source_mutable_replacement_review",
          source_protection_decisions: ["preserve"],
          source_protection_categories: ["locked_or_approved"],
          replacement_protection_decision: "mutable",
          replacement_protection_category: "none",
          classification: "operator_review_required",
          reason: "protected source replacement needs timeline authority",
          required_authority: "timeline_protection_authority"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "timeline:cmd_lock",
            "activity_type" => "timeline_transition",
            "action" => "review_timeline_change",
            "requirement_type" => "operator_review",
            "reason" => "source protection decision preserved the locked activity",
            "activity_context" => %{
              "source_protection_decision" => %{
                "activity_id" => "cmd_lock",
                "protection_decision" => "preserve",
                "protection_category" => "locked_or_approved",
                "reason" => "activity_locked_or_approved"
              },
              "replacement_protection_decision" => %{
                "activity_id" => "cmd_lock",
                "protection_decision" => "mutable",
                "protection_category" => "none",
                "reason" => "no_timeline_protection"
              }
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "activity_id" => "timeline:cmd_lock",
               "policy_classification" => "operator_review_required",
               "approval_rule_matches" => rule_matches
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "protected_source_mutable_replacement_review",
               "source_protection_decision" => "preserve",
               "source_protection_category" => "locked_or_approved",
               "replacement_protection_decision" => "mutable",
               "replacement_protection_category" => "none",
               "required_authority" => "timeline_protection_authority"
             }
           ] = matches

    assert rule_matches == matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches planned timeline protection policy context" do
    policy = %{
      action_rules: [
        %{
          id: "executed_planned_feedback_review",
          planned_protection_decisions: ["preserve"],
          planned_protection_category: "executed",
          classification: "operator_review_required",
          reason: "executed planned activity feedback requires timeline authority",
          escalation_queue: "mission_planning",
          required_authority: "timeline_protection_authority"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "timeline:cmd_done",
            "activity_type" => "realized_feedback",
            "action" => "review_realized_feedback",
            "requirement_type" => "operator_review",
            "reason" => "planned activity protection preserved executed work",
            "activity_context" => %{
              "planned_protection_decision" => "preserve",
              "planned_protection_category" => "executed"
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "activity_id" => "timeline:cmd_done",
               "policy_classification" => "operator_review_required",
               "approval_rule_matches" => rule_matches
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "executed_planned_feedback_review",
               "planned_protection_decision" => "preserve",
               "planned_protection_category" => "executed",
               "escalation_queue" => "mission_planning",
               "required_authority" => "timeline_protection_authority"
             }
           ] = matches

    assert rule_matches == matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches timeline protection list-valued requirement context" do
    policy = %{
      action_rules: [
        %{
          id: "aggregated_timeline_protection_review",
          transition_decisions: ["preserve_source"],
          application_statuses: ["source_preserved_pending_review"],
          planned_protection_decisions: ["preserve"],
          planned_protection_categories: ["executed"],
          timeline_integrity_statuses: ["review_required"],
          timeline_integrity_issue_types: ["dependency_cycle"],
          source_timeline_integrity_statuses: ["review_required"],
          source_timeline_integrity_issue_types: ["exclusivity_group_overlap"],
          replacement_timeline_integrity_statuses: ["review_required"],
          replacement_timeline_integrity_issue_types: ["dependency_cycle"],
          source_protection_decisions: ["preserve"],
          source_protection_categories: ["locked_or_approved"],
          replacement_protection_decisions: ["mutable"],
          replacement_protection_categories: ["none"],
          classification: "operator_review_required",
          reason: "aggregated timeline protection evidence requires review",
          required_authority: "timeline_protection_authority"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "timeline:aggregate",
            "activity_type" => "timeline_transition",
            "action" => "review_timeline_change",
            "requirement_type" => "operator_review",
            "activity_context" => %{
              "transition_decisions" => ["preserve_source", "apply_replacement"],
              "application_statuses" => ["source_preserved_pending_review"],
              "planned_protection_decisions" => ["preserve"],
              "planned_protection_categories" => ["executed"],
              "timeline_integrity_statuses" => ["review_required"],
              "timeline_integrity_issue_types" => ["dependency_cycle"],
              "source_timeline_integrity_statuses" => ["review_required"],
              "source_timeline_integrity_issue_types" => ["exclusivity_group_overlap"],
              "replacement_timeline_integrity_statuses" => ["review_required"],
              "replacement_timeline_integrity_issue_types" => ["dependency_cycle"],
              "source_protection_decisions" => ["preserve"],
              "source_protection_categories" => ["locked_or_approved"],
              "replacement_protection_decisions" => ["mutable"],
              "replacement_protection_categories" => ["none"]
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "activity_id" => "timeline:aggregate",
               "policy_classification" => "operator_review_required",
               "approval_rule_matches" => rule_matches
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "aggregated_timeline_protection_review",
               "transition_decisions" => ["preserve_source", "apply_replacement"],
               "application_statuses" => ["source_preserved_pending_review"],
               "planned_protection_decisions" => ["preserve"],
               "planned_protection_categories" => ["executed"],
               "timeline_integrity_statuses" => ["review_required"],
               "timeline_integrity_issue_types" => ["dependency_cycle"],
               "source_timeline_integrity_statuses" => ["review_required"],
               "source_timeline_integrity_issue_types" => ["exclusivity_group_overlap"],
               "replacement_timeline_integrity_statuses" => ["review_required"],
               "replacement_timeline_integrity_issue_types" => ["dependency_cycle"],
               "source_protection_decisions" => ["preserve"],
               "source_protection_categories" => ["locked_or_approved"],
               "replacement_protection_decisions" => ["mutable"],
               "replacement_protection_categories" => ["none"],
               "required_authority" => "timeline_protection_authority"
             }
           ] = matches

    assert rule_matches == matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches timeline integrity policy context" do
    policy = %{
      action_rules: [
        %{
          id: "timeline_dependency_cycle_review",
          timeline_integrity_statuses: ["review_required"],
          timeline_integrity_issue_type: "dependency_cycle",
          classification: "operator_review_required",
          reason: "dependency cycles require planning review",
          escalation_queue: "mission_planning",
          required_authority: "timeline_protection_authority"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "timeline:obs_cycle",
            "activity_type" => "operational_timeline",
            "action" => "review_timeline_integrity",
            "requirement_type" => "operator_review",
            "reason" => "timeline dependency cycle requires review",
            "activity_context" => %{
              "timeline_integrity_status" => "review_required",
              "timeline_integrity_issue_types" => ["dependency_cycle", "exclusivity_overlap"],
              "dependency_cycle_activity_ids" => ["obs_cycle"]
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "activity_id" => "timeline:obs_cycle",
               "policy_classification" => "operator_review_required",
               "approval_rule_matches" => rule_matches
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "timeline_dependency_cycle_review",
               "timeline_integrity_status" => "review_required",
               "timeline_integrity_issue_types" => [
                 "dependency_cycle",
                 "exclusivity_overlap"
               ],
               "escalation_queue" => "mission_planning",
               "required_authority" => "timeline_protection_authority"
             }
           ] = matches

    assert rule_matches == matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end

  test "matches prefixed timeline integrity policy context" do
    policy = %{
      action_rules: [
        %{
          id: "replacement_exclusivity_review",
          replacement_timeline_integrity_status: "review_required",
          replacement_timeline_integrity_issue_types: ["exclusivity_group_overlap"],
          classification: "operator_review_required",
          reason: "replacement exclusivity issue requires planning review",
          escalation_queue: "mission_planning",
          required_authority: "timeline_protection_authority"
        }
      ]
    }

    {status, requirements, matches, decision} =
      Policy.decide(
        [
          %{
            "activity_id" => "timeline:replacement_obs",
            "activity_type" => "timeline_diff",
            "action" => "review_timeline_integrity",
            "requirement_type" => "operator_review",
            "reason" => "replacement activity has an exclusivity group overlap",
            "activity_context" => %{
              "replacement_timeline_integrity_status" => "review_required",
              "replacement_timeline_integrity_issue_types" => [
                "exclusivity_group_overlap"
              ],
              "replacement_exclusivity_violation_activity_ids" => ["obs_conflict"]
            }
          }
        ],
        [],
        %{"id" => "branch", "events" => []},
        %{},
        policy
      )

    assert status == "operator_review_required"

    assert [
             %{
               "activity_id" => "timeline:replacement_obs",
               "policy_classification" => "operator_review_required",
               "approval_rule_matches" => rule_matches
             }
           ] = requirements

    assert [
             %{
               "rule_id" => "replacement_exclusivity_review",
               "replacement_timeline_integrity_status" => "review_required",
               "replacement_timeline_integrity_issue_types" => [
                 "exclusivity_group_overlap"
               ],
               "escalation_queue" => "mission_planning",
               "required_authority" => "timeline_protection_authority"
             }
           ] = matches

    assert rule_matches == matches

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(decision)
  end
end
