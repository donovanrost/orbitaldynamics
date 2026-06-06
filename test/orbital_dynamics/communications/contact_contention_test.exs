defmodule OrbitalDynamics.Communications.ContactContentionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Communications.ContactContention

  test "declares contact contention capabilities" do
    assert %{
             artifact_contract: "contact_contention_report.v1",
             resolution_artifact_contract: "contact_contention_resolution_report.v1",
             resolution_summary_artifact_contract: "contact_contention_resolution_summary.v1",
             validation_level: :artifact_contract,
             contact_types: contact_types,
             public_facades: public_facades,
             row_review_statuses: ["operator_review_required"],
             station_unavailable_aliases: station_unavailable_aliases,
             station_availability_precedence: station_availability_precedence,
             station_capacity_fraction_paths: station_capacity_fraction_paths,
             station_capacity_percent_paths: station_capacity_percent_paths,
             station_capacity_value_paths: station_capacity_value_paths,
             source_station_capacity_fraction_paths: source_station_capacity_fraction_paths,
             source_station_capacity_percent_paths: source_station_capacity_percent_paths,
             source_station_capacity_value_paths: source_station_capacity_value_paths,
             required_capacity_fraction_paths: required_capacity_fraction_paths,
             required_capacity_percent_paths: required_capacity_percent_paths,
             required_capacity_value_paths: required_capacity_value_paths,
             required_capacity_fraction_source_values: required_capacity_fraction_source_values,
             station_reservation_priority_match_statuses:
               station_reservation_priority_match_statuses,
             station_reservation_priority_statuses: station_reservation_priority_statuses,
             resolution_selection_rules: resolution_selection_rules,
             resolution_tie_breakers: resolution_tie_breakers,
             default_resolution_priority_fields: default_resolution_priority_fields,
             resolution_priority_override_aliases: resolution_priority_override_aliases,
             provider_direction_aliases: provider_direction_aliases,
             provider_result_map_value_keys: provider_result_map_value_keys,
             contact_stable_identity_fields: contact_stable_identity_fields,
             command_contact_directions: command_contact_directions,
             row_semantics: row_semantics,
             known_limits: known_limits
           } = ContactContention.capabilities()

    assert contact_types == ["downlink", "planned_contact", "tracking", "command", "health_check"]
    assert "health_check" in ContactContention.capabilities().contact_directions
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
    assert ["throughput_model", "station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_model", "capacity_fraction"] in station_capacity_fraction_paths
    assert ["activity_context", "capacity_fraction"] in station_capacity_fraction_paths

    assert ["station_capacity_percent"] in station_capacity_percent_paths
    assert ["capacity_percent"] in station_capacity_percent_paths
    assert ["throughput_model", "station_capacity_percent"] in station_capacity_percent_paths
    assert ["capacity_model", "capacity_percent"] in station_capacity_percent_paths
    assert ["activity_context", "capacity_percent"] in station_capacity_percent_paths

    assert source_station_capacity_fraction_paths == station_capacity_fraction_paths
    assert source_station_capacity_percent_paths == station_capacity_percent_paths
    assert source_station_capacity_value_paths == station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_pack_capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :percent, path: ["capacity_percent"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["activity_context", "capacity_fraction"]} in source_station_capacity_value_paths

    assert %{unit: :percent, path: ["capacity_model", "station_capacity_percent"]} in source_station_capacity_value_paths

    assert ["required_capacity_fraction"] in required_capacity_fraction_paths
    assert ["required_station_capacity_fraction"] in required_capacity_fraction_paths
    assert ["station_capacity_requirement"] in required_capacity_fraction_paths
    assert ["throughput_model", "required_capacity_fraction"] in required_capacity_fraction_paths
    assert ["capacity_model", "station_capacity_requirement"] in required_capacity_fraction_paths

    assert ["activity_context", "required_station_capacity_fraction"] in required_capacity_fraction_paths

    assert ["required_capacity_percent"] in required_capacity_percent_paths
    assert ["required_station_capacity_percent"] in required_capacity_percent_paths
    assert ["station_capacity_requirement_percent"] in required_capacity_percent_paths

    assert ["throughput_model", "required_station_capacity_percent"] in required_capacity_percent_paths

    assert ["capacity_model", "required_capacity_percent"] in required_capacity_percent_paths

    assert ["activity_context", "station_capacity_requirement_percent"] in required_capacity_percent_paths

    assert %{unit: :fraction, path: ["required_station_capacity_fraction"]} in required_capacity_value_paths

    assert %{unit: :percent, path: ["throughput_model", "required_capacity_percent"]} in required_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_model", "station_capacity_requirement"]} in required_capacity_value_paths

    assert %{unit: :percent, path: ["activity_context", "station_capacity_requirement_percent"]} in required_capacity_value_paths

    assert required_capacity_fraction_source_values == [
             "contact_required_capacity_fraction",
             "throughput_model",
             "capacity_model",
             "activity_context"
           ]

    assert "scenario_id" in contact_stable_identity_fields
    assert "spacecraft_id" in contact_stable_identity_fields
    assert "satellite_id" in contact_stable_identity_fields
    assert "ground_station_id" in contact_stable_identity_fields
    assert "source_window_id" in contact_stable_identity_fields

    assert command_contact_directions == ["command", "uplink"]

    assert station_reservation_priority_match_statuses == ["matched", "owned", "owner_matched"]
    assert station_reservation_priority_statuses == ["approved", "confirmed", "reserved", "held"]
    assert "highest_score_earliest_start" in resolution_selection_rules
    assert "highest_priority_highest_score" in resolution_selection_rules
    assert "ends_at_s" in resolution_tie_breakers
    assert "policy_contact_priority" in resolution_tie_breakers
    assert "command_contact_priority" in resolution_tie_breakers
    assert "station_reservation_priority" in resolution_tie_breakers

    assert default_resolution_priority_fields == [
             "contention_priority",
             "contact_priority",
             "activity_priority",
             "target_priority",
             "priority",
             "station_reservation_priority",
             "command_contact_priority"
           ]

    assert resolution_priority_override_aliases == [
             "priority_overrides",
             "contact_priority_overrides",
             "contact_priorities",
             "priority_by_contact_id"
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

    assert :contact_contention_resolution_summary in public_facades
    assert :invalid_contact_input_review in row_semantics
    assert :contention_overlap_metrics in row_semantics
    assert :same_spacecraft_overlap_group in row_semantics
    assert :priority_aware_resolution_recommendation in row_semantics
    assert :policy_contact_priority_resolution in row_semantics
    assert :command_contact_priority_resolution in row_semantics
    assert :station_reservation_priority_resolution in row_semantics
    assert :realized_data_rate_throughput_preservation in row_semantics
    assert :numeric_string_time_normalization in row_semantics
    assert :station_calendar_direction_context in row_semantics
    assert :station_capacity_value_paths in row_semantics
    assert :source_station_capacity_value_paths in row_semantics
    assert :required_capacity_value_paths in row_semantics
    assert :required_capacity_fraction_source_values in row_semantics
    assert :contact_stable_identity_fields in row_semantics
    assert :command_contact_directions in row_semantics
    assert :provider_direction_aliases in row_semantics
    assert :provider_result_map_value_keys in row_semantics
    assert :contact_contention_resolution_summary in row_semantics
    assert :contact_contention_resolution_conflict_group_count in row_semantics
    assert :contact_contention_resolution_recommendation_count in row_semantics
    assert :contact_contention_resolution_review_recommendation_count in row_semantics
    assert :contact_contention_resolution_capacity_pack_demand_summary in row_semantics
    assert :contact_contention_resolution_capacity_pack_status_routing in row_semantics
    assert :contact_contention_resolution_capacity_pack_source_routing in row_semantics
    assert :contact_contention_resolution_resource_scope_counts in row_semantics
    assert :contact_contention_resolution_resource_scope_routing in row_semantics
    assert :contact_contention_resolution_selection_reason_counts in row_semantics
    assert :contact_contention_resolution_selection_reason_routing in row_semantics
    assert :contact_contention_resolution_action_counts in row_semantics
    assert :contact_contention_resolution_action_routing in row_semantics
    assert :contact_contention_resolution_group_routing in row_semantics
    assert :contact_contention_resolution_routing_id_sets in row_semantics
    assert :contact_contention_resolution_summary_row_derived_counts in row_semantics
    assert :no_provider_reservation in known_limits
    assert :no_candidate_suppression in known_limits
    assert :no_schedule_mutation in known_limits
  end

  test "preserves invalid contact-like inputs for review instead of dropping them" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0
      },
      %{
        id: :missing_station,
        type: :downlink,
        scenario_id: :leo_1,
        starts_at_s: 180.0,
        ends_at_s: 220.0
      },
      %{
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 240.0,
        ends_at_s: 280.0
      },
      {:bad_contact_shape, :not_a_map},
      %{id: :metadata_only, type: :metadata}
    ]

    {annotated, report} = ContactContention.annotate_contacts(contacts, source: "invalid_test")

    assert Enum.map(annotated, &Map.get(&1, "id")) == [
             "dl_1",
             "missing_station",
             nil,
             nil,
             "metadata_only"
           ]

    assert %{
             "input_contact_count" => 4,
             "conflict_group_count" => 0,
             "invalid_contact_input_count" => 3,
             "invalid_contact_input_ids" => [
               "missing_station",
               "missing_contact_id:3",
               "missing_contact_id:4"
             ],
             "invalid_contact_inputs" => invalid_rows
           } = report

    assert %{
             "contact_id" => "missing_station",
             "required_operator_action" => "review_invalid_contact_contention_input",
             "approval_status" => "operator_review_required",
             "operator_action_reason" => "missing_ground_station_id",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "missing_ground_station_id",
             "source_contact_candidate" => %{"id" => "missing_station"}
           } = Enum.find(invalid_rows, &(&1["contact_id"] == "missing_station"))

    assert %{
             "contact_id" => "missing_contact_id:3",
             "invalid_contact_input_reason" => "missing_contact_id"
           } = Enum.find(invalid_rows, &(&1["contact_id"] == "missing_contact_id:3"))

    assert %{
             "contact_id" => "missing_contact_id:4",
             "invalid_contact_input_reason" => "invalid_contact_shape",
             "source_contact_candidate" => %{
               "invalid_contact_shape" => true,
               "raw_input" => "{:bad_contact_shape, :not_a_map}"
             }
           } = Enum.find(invalid_rows, &(&1["contact_id"] == "missing_contact_id:4"))

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_review_status =
      put_in(
        report,
        ["invalid_contact_inputs", Access.at(0), "review_status"],
        "ready_without_review"
      )

    assert {:error, invalid_review_status_report} =
             Schema.validate_artifact(invalid_review_status)

    assert Enum.any?(
             invalid_review_status_report["errors"],
             &(&1["path"] == "$.invalid_contact_inputs[0].review_status")
           )

    review = OperatorReview.from_contact_contention_report(report)
    review_row = Enum.find(review["rows"], &(&1["contact_id"] == "missing_station"))

    assert %{
             "review_type" => "contact_contention_review",
             "required_operator_action" => "review_invalid_contact_contention_input",
             "invalid_contact_input_reason" => "missing_ground_station_id",
             "source_invalid_contact_input" => %{"contact_id" => "missing_station"}
           } = review_row

    manifest = CadenceImport.from_contact_contention_report(report)
    import_row = Enum.find(manifest["rows"], &(&1["contact_id"] == "missing_station"))

    assert %{
             "import_action" => "review_contact_contention",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "missing_ground_station_id",
             "source_invalid_contact_input" => %{"contact_id" => "missing_station"}
           } = import_row
  end

  test "preserves malformed contact contention identity fields for review" do
    contacts = [
      %{
        id: "bad contact id",
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0
      },
      %{
        id: :bad_station,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: "bad station id",
        starts_at_s: 180.0,
        ends_at_s: 220.0
      },
      %{
        id: :bad_source_window,
        type: :tracking,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        source_window_id: "bad source window",
        starts_at_s: 240.0,
        ends_at_s: 280.0
      },
      %{
        id: :bad_scenario,
        type: :command,
        scenario_id: "bad scenario id",
        ground_station_id: :equator_prime,
        starts_at_s: 300.0,
        ends_at_s: 340.0
      }
    ]

    {_annotated, report} = ContactContention.annotate_contacts(contacts)

    assert %{
             "input_contact_count" => 4,
             "conflict_group_count" => 0,
             "invalid_contact_input_count" => 4,
             "invalid_contact_input_ids" => [
               "invalid_contact_id:1",
               "bad_station",
               "bad_source_window",
               "bad_scenario"
             ],
             "invalid_contact_inputs" => invalid_rows
           } = report

    assert %{
             "contact_id" => "invalid_contact_id:1",
             "operator_action_reason" => "invalid_contact_id",
             "invalid_contact_input_reason" => "invalid_contact_id",
             "source_contact_candidate" => %{"id" => "bad contact id"}
           } = Enum.find(invalid_rows, &(&1["contact_id"] == "invalid_contact_id:1"))

    bad_station_row = Enum.find(invalid_rows, &(&1["contact_id"] == "bad_station"))

    assert %{
             "operator_action_reason" => "invalid_ground_station_id",
             "invalid_contact_input_reason" => "invalid_ground_station_id",
             "source_contact_candidate" => %{"ground_station_id" => "bad station id"}
           } = bad_station_row

    refute Map.has_key?(bad_station_row, "ground_station_id")
    assert bad_station_row["ground_station_ids"] == []

    bad_source_window_row =
      Enum.find(invalid_rows, &(&1["contact_id"] == "bad_source_window"))

    assert %{
             "operator_action_reason" => "invalid_source_window_id",
             "invalid_contact_input_reason" => "invalid_source_window_id",
             "source_contact_candidate" => %{"source_window_id" => "bad source window"}
           } = bad_source_window_row

    bad_scenario_row = Enum.find(invalid_rows, &(&1["contact_id"] == "bad_scenario"))

    assert %{
             "operator_action_reason" => "invalid_scenario_id",
             "invalid_contact_input_reason" => "invalid_scenario_id",
             "source_contact_candidate" => %{"scenario_id" => "bad scenario id"}
           } = bad_scenario_row

    refute Map.has_key?(bad_scenario_row, "scenario_id")
    assert bad_scenario_row["scenario_ids"] == []

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_contact_contention_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "bad_source_window" and
                 &1["invalid_contact_input_reason"] == "invalid_source_window_id" and
                 get_in(&1, [
                   "source_invalid_contact_input",
                   "source_contact_candidate",
                   "source_window_id"
                 ]) == "bad source window")
           )

    manifest = CadenceImport.from_contact_contention_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "bad_station" and
                 &1["invalid_contact_input_reason"] == "invalid_ground_station_id" and
                 get_in(&1, [
                   "source_invalid_contact_input",
                   "source_contact_candidate",
                   "ground_station_id"
                 ]) == "bad station id")
           )
  end

  test "annotates same-station contention from atom or string keyed contacts" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 2.0,
        source_window_id: :window_1
      },
      %{
        "id" => "dl_2",
        "type" => "downlink",
        "scenario_id" => "leo_2",
        "ground_station_id" => "equator_prime",
        "starts_at_s" => 150.0,
        "ends_at_s" => 210.0,
        "score" => 3.0,
        "source_window_id" => "window_2"
      },
      %{
        id: :dl_3,
        type: :downlink,
        scenario_id: :leo_3,
        ground_station_id: :deep_space_net,
        starts_at_s: 150.0,
        ends_at_s: 210.0,
        score: 10.0,
        source_window_id: :window_3
      }
    ]

    {annotated, report} = ContactContention.annotate_contacts(contacts, source: "unit_test")

    assert [
             %{
               "id" => "dl_1",
               "schedule_conflict_status" => "contention_detected",
               "contention_group_ids" => ["station:equator_prime:contention:1"]
             },
             %{
               "id" => "dl_2",
               "schedule_conflict_status" => "contention_detected",
               "contention_group_ids" => ["station:equator_prime:contention:1"]
             },
             %{"id" => "dl_3"}
           ] = annotated

    refute Map.has_key?(List.last(annotated), "contention_group_ids")

    assert %{
             "schema_contract" => "contact_contention_report.v1",
             "model" => "single_station_interval_overlap",
             "input_contact_count" => 3,
             "conflicted_contact_count" => 2,
             "conflict_group_count" => 1,
             "model_limits" => model_limits,
             "provenance" => %{"source" => "unit_test"},
             "conflict_groups" => [
               %{
                 "id" => "station:equator_prime:contention:1",
                 "ground_station_id" => "equator_prime",
                 "contact_count" => 2,
                 "starts_at_s" => 100.0,
                 "ends_at_s" => 210.0,
                 "contention_window_s" => 110.0,
                 "total_contact_duration_s" => 130.0,
                 "overlap_duration_s" => 20.0,
                 "max_concurrent_contacts" => 2,
                 "overlap_contact_pair_count" => 1,
                 "direction" => "downlink",
                 "required_operator_action" => "review_contact_contention",
                 "approval_status" => "operator_review_required",
                 "operator_action_reason" => "same_station_overlapping_contact_windows",
                 "contact_ids" => ["dl_1", "dl_2"],
                 "source_window_ids" => ["window_1", "window_2"],
                 "scenario_ids" => ["leo_1", "leo_2"]
               }
             ]
           } = report

    assert "no_provider_reservation" in model_limits
    assert "no_candidate_suppression" in model_limits

    expected_model_limits =
      ContactContention.capabilities()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&to_string/1)

    assert model_limits == expected_model_limits

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, contact_contention_report_schema} =
             Schema.json_schema("contact_contention_report.v1")

    assert get_in(contact_contention_report_schema, ["properties", "model", "const"]) ==
             "single_station_interval_overlap"

    stale_report_model = Map.put(report, "model", "stale_contact_contention_report")

    assert {:error, stale_report_model_errors} = Schema.validate_artifact(stale_report_model)

    assert Enum.any?(
             stale_report_model_errors["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"single_station_interval_overlap\"")
           )

    resolution = ContactContention.resolution_report(contacts, report)

    assert [
             %{
               "group_id" => "station:equator_prime:contention:1",
               "contention_window_s" => 110.0,
               "total_contact_duration_s" => 130.0,
               "overlap_duration_s" => 20.0,
               "max_concurrent_contacts" => 2,
               "overlap_contact_pair_count" => 1
             }
           ] = resolution["recommendations"]

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    review = OperatorReview.from_contact_contention_report(report)
    [review_row] = review["rows"]

    assert %{
             "contention_window_s" => 110.0,
             "total_contact_duration_s" => 130.0,
             "overlap_duration_s" => 20.0,
             "max_concurrent_contacts" => 2,
             "overlap_contact_pair_count" => 1
           } = review_row

    manifest = CadenceImport.from_contact_contention_report(report)
    [import_row] = manifest["rows"]

    assert %{
             "contention_window_s" => 110.0,
             "total_contact_duration_s" => 130.0,
             "overlap_duration_s" => 20.0,
             "max_concurrent_contacts" => 2,
             "overlap_contact_pair_count" => 1
           } = import_row
  end

  test "computes overlap pressure metrics for chained station contention" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 0.0,
        ends_at_s: 10.0
      },
      %{
        id: :dl_2,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 5.0,
        ends_at_s: 15.0
      },
      %{
        id: :dl_3,
        type: :downlink,
        scenario_id: :leo_3,
        ground_station_id: :equator_prime,
        starts_at_s: 12.0,
        ends_at_s: 20.0
      }
    ]

    {_annotated, report} = ContactContention.annotate_contacts(contacts)

    assert [
             %{
               "contact_ids" => ["dl_1", "dl_2", "dl_3"],
               "contention_window_s" => 20.0,
               "total_contact_duration_s" => 28.0,
               "overlap_duration_s" => 8.0,
               "max_concurrent_contacts" => 2,
               "overlap_contact_pair_count" => 2
             }
           ] = report["conflict_groups"]

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "ground-network policy classifies plain same-station contention groups and recommendations" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 2.0,
        source_window_id: :window_1
      },
      %{
        id: :dl_2,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 160.0,
        score: 9.0,
        source_window_id: :window_2
      }
    ]

    {_annotated, report} =
      ContactContention.annotate_contacts(contacts,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "approval_status" => "operator_review_required",
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "same_station_contact_contention_review",
                   "resource_scope" => "ground_station",
                   "required_operator_action" => "review_contact_contention"
                 }
               ],
               "policy_decision" => %{
                 "schema_contract" => "policy_decision.v1",
                 "policy_bundle_id" => "ground_network_allocation_v1"
               }
             }
           ] = report["conflict_groups"]

    review = OperatorReview.from_contact_contention_report(report)
    [review_row] = review["rows"]

    assert %{
             "approval_rule_matches" => [
               %{"rule_id" => "same_station_contact_contention_review"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             }
           } = review_row

    manifest = CadenceImport.from_contact_contention_report(report)
    [import_row] = manifest["rows"]

    assert %{
             "approval_rule_matches" => [
               %{"rule_id" => "same_station_contact_contention_review"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             }
           } = import_row

    resolution =
      ContactContention.resolution_report(contacts, report,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "same_station_contact_contention_review",
                   "required_operator_action" => "recommend_preferred_contact_for_operator_review"
                 }
               ],
               "policy_decision" => %{
                 "policy_bundle_id" => "ground_network_allocation_v1"
               }
             }
           ] = resolution["recommendations"]

    resolution_review = OperatorReview.from_contact_contention_resolution_report(resolution)
    [resolution_review_row] = resolution_review["rows"]

    assert %{
             "approval_rule_matches" => [
               %{"rule_id" => "same_station_contact_contention_review"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             }
           } = resolution_review_row

    resolution_manifest = CadenceImport.from_contact_contention_resolution_report(resolution)
    [resolution_import_row] = resolution_manifest["rows"]

    assert %{
             "approval_rule_matches" => [
               %{"rule_id" => "same_station_contact_contention_review"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             }
           } = resolution_import_row

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "derives station availability from direct station calendar status in contention policy" do
    contacts = [
      %{
        id: :direct_outage_contention,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 8.0,
        required_capacity_fraction: 0.6,
        station_availability: :available,
        station_calendar_status: "Offline",
        capacity_percent: "40",
        station_calendar_provider_id: :ground_partner_a,
        station_calendar_provider_entry_id: :provider_outage_1,
        source_station_calendar_entry: %{
          id: :provider_outage_1,
          availability: "Offline",
          capacity_pack_capacity_fraction: "0.3"
        }
      },
      %{
        id: :available_overlap,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 160.0,
        score: 9.0,
        required_capacity_percent: "25",
        station_calendar_status: :available,
        station_capacity_fraction: "0.8"
      }
    ]

    {_annotated, report} =
      ContactContention.annotate_contacts(contacts,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "station_availability" => "unavailable",
               "station_calendar_status" => "unavailable",
               "capacity_fraction" => 0.3,
               "capacity_fraction_min" => 0.3,
               "capacity_fraction_max" => 0.8,
               "station_calendar_provider_ids" => ["ground_partner_a"],
               "station_calendar_provider_entry_ids" => ["provider_outage_1"],
               "approval_status" => "blocked_by_policy",
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "station_availability" => "unavailable",
                     "station_calendar_status" => "unavailable",
                     "capacity_fraction" => 0.3,
                     "capacity_fraction_min" => 0.3,
                     "capacity_fraction_max" => 0.8
                   }
                 }
               ],
               "source_contact_candidates" => source_contacts
             } = group
           ] = report["conflict_groups"]

    assert Enum.any?(
             group["approval_rule_matches"],
             &(&1["rule_id"] == "unavailable_station_contact_block")
           )

    assert %{
             "station_availability" => "available",
             "station_calendar_status" => "unavailable",
             "source_station_calendar_entry" => %{
               "id" => "provider_outage_1",
               "availability" => "unavailable",
               "capacity_pack_capacity_fraction" => "0.3"
             }
           } = Enum.find(source_contacts, &(&1["id"] == "direct_outage_contention"))

    review = OperatorReview.from_contact_contention_report(report)
    [review_row] = review["rows"]

    assert %{
             "station_availability" => "unavailable",
             "station_calendar_status" => "unavailable",
             "capacity_fraction" => 0.3,
             "capacity_fraction_min" => 0.3,
             "capacity_fraction_max" => 0.8,
             "approval_status" => "blocked_by_policy",
             "source_contention_group" => %{
               "station_availability" => "unavailable",
               "station_calendar_status" => "unavailable",
               "capacity_fraction" => 0.3
             }
           } = review_row

    assert Enum.any?(
             review_row["approval_rule_matches"],
             &(&1["rule_id"] == "unavailable_station_contact_block")
           )

    manifest = CadenceImport.from_contact_contention_report(report)
    [import_row] = manifest["rows"]

    assert %{
             "station_availability" => "unavailable",
             "station_calendar_status" => "unavailable",
             "capacity_fraction" => 0.3,
             "capacity_fraction_min" => 0.3,
             "capacity_fraction_max" => 0.8,
             "approval_status" => "blocked_by_policy"
           } = import_row

    assert Enum.any?(
             import_row["approval_rule_matches"],
             &(&1["rule_id"] == "unavailable_station_contact_block")
           )

    resolution =
      ContactContention.resolution_report(contacts, report,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "station_availability" => "unavailable",
               "station_calendar_status" => "unavailable",
               "capacity_fraction" => 0.3,
               "capacity_fraction_min" => 0.3,
               "capacity_fraction_max" => 0.8,
               "review_status" => "blocked_by_policy"
             } = recommendation
           ] = resolution["recommendations"]

    assert Enum.any?(
             recommendation["approval_rule_matches"],
             &(&1["rule_id"] == "unavailable_station_contact_block")
           )

    resolution_review = OperatorReview.from_contact_contention_resolution_report(resolution)
    [resolution_review_row] = resolution_review["rows"]

    assert %{
             "station_availability" => "unavailable",
             "station_calendar_status" => "unavailable",
             "capacity_fraction" => 0.3,
             "capacity_fraction_min" => 0.3,
             "capacity_fraction_max" => 0.8,
             "approval_status" => "blocked_by_policy"
           } = resolution_review_row

    resolution_manifest = CadenceImport.from_contact_contention_resolution_report(resolution)
    [resolution_import_row] = resolution_manifest["rows"]

    assert %{
             "station_availability" => "unavailable",
             "station_calendar_status" => "unavailable",
             "capacity_fraction" => 0.3,
             "capacity_fraction_min" => 0.3,
             "capacity_fraction_max" => 0.8,
             "approval_status" => "blocked_by_policy"
           } = resolution_import_row

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    assert %{
             "capacity_pack_required_capacity_fraction" => 0.85,
             "capacity_pack_selected_required_capacity_fraction" => 0.25,
             "capacity_pack_deferred_required_capacity_fraction" => 0.6,
             "capacity_pack_required_capacity_fraction_by_status" => %{
               "deferred" => 0.6,
               "selected" => 0.25
             },
             "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.85
             },
             "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.25
             },
             "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
               "equator_prime" => 0.6
             },
             "required_capacity_fraction_source_counts" => %{
               "contact_required_capacity_fraction" => 2
             },
             "required_capacity_fraction_contact_ids_by_source" => %{
               "contact_required_capacity_fraction" => [
                 "available_overlap",
                 "direct_outage_contention"
               ]
             }
           } = capacity_summary = ContactContention.resolution_summary(resolution)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_summary.v1"}} =
             Schema.validate_artifact(capacity_summary)

    stale_capacity_summary =
      Map.put(capacity_summary, "capacity_pack_required_capacity_fraction", 99.0)

    assert {:error, stale_capacity_summary_report} =
             Schema.validate_artifact(stale_capacity_summary)

    assert Enum.any?(
             stale_capacity_summary_report["errors"],
             &match?(
               %{
                 "path" => "$.capacity_pack_required_capacity_fraction",
                 "message" =>
                   "must equal capacity_pack_required_capacity_fraction_by_status total"
               },
               &1
             )
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "detects provider contact contention without explicit type or direction" do
    contacts = [
      %{
        id: :provider_1,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        estimated_throughput_mb: 100.0,
        source_window_id: :provider_window_1,
        station_calendar_entry_id: :calendar_row_1,
        station_calendar_provider_id: :provider_calendar,
        station_calendar_provider_entry_id: :provider_entry_1,
        station_calendar_overlap_entry_ids: [:provider_entry_1, :reservation_entry_1],
        station_calendar_directions: [:downlink],
        station_calendar_reservation_ids: [:reservation_1],
        station_calendar_reserved_by: ["ops"],
        station_calendar_reservation_statuses: ["reserved"],
        station_calendar_trust_boundary_status: "declared"
      },
      %{
        id: :provider_2,
        scenario_id: :leo_2,
        station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 170.0,
        estimated_throughput_mb: 80.0,
        source_window_id: :provider_window_2,
        station_calendar_entry_id: :calendar_row_2,
        station_calendar_provider_id: :provider_calendar,
        station_calendar_provider_entry_id: :provider_entry_2,
        station_calendar_overlap_entry_ids: [:provider_entry_2, :reservation_entry_2],
        station_calendar_directions: [:downlink],
        station_calendar_reservation_ids: [:reservation_2],
        station_calendar_reserved_by: ["science"],
        station_calendar_reservation_statuses: ["tentative"],
        station_calendar_trust_boundary_status: "missing"
      },
      %{
        scenario_id: :leo_3,
        station_id: :equator_prime,
        starts_at_s: 180.0,
        ends_at_s: 220.0,
        actual_throughput_mb: 12.0
      }
    ]

    {annotated, report} =
      ContactContention.annotate_contacts(contacts,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "id" => "provider_1",
               "contention_group_ids" => ["station:equator_prime:contention:1"]
             },
             %{
               "id" => "provider_2",
               "contention_group_ids" => ["station:equator_prime:contention:1"]
             },
             %{"ground_station_id" => "equator_prime"}
           ] = annotated

    assert %{
             "input_contact_count" => 3,
             "conflicted_contact_count" => 2,
             "conflict_group_count" => 1,
             "invalid_contact_input_count" => 1,
             "invalid_contact_input_ids" => ["missing_contact_id:3"],
             "conflict_groups" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "direction" => "downlink",
                 "contact_ids" => ["provider_1", "provider_2"],
                 "source_window_ids" => ["provider_window_1", "provider_window_2"],
                 "station_calendar_entry_ids" => ["calendar_row_1", "calendar_row_2"],
                 "station_calendar_provider_ids" => ["provider_calendar"],
                 "station_calendar_provider_entry_ids" => [
                   "provider_entry_1",
                   "provider_entry_2"
                 ],
                 "station_calendar_overlap_entry_ids" => [
                   "provider_entry_1",
                   "provider_entry_2",
                   "reservation_entry_1",
                   "reservation_entry_2"
                 ],
                 "station_calendar_directions" => ["downlink"],
                 "station_calendar_reservation_ids" => ["reservation_1", "reservation_2"],
                 "station_calendar_reserved_by" => ["ops", "science"],
                 "station_calendar_reservation_statuses" => ["reserved", "tentative"],
                 "station_calendar_trust_boundary_statuses" => ["declared", "missing"],
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "station_calendar_directions" => ["downlink"]
                     }
                   }
                 ]
               }
             ],
             "invalid_contact_inputs" => [
               %{
                 "contact_id" => "missing_contact_id:3",
                 "direction" => "downlink",
                 "invalid_contact_input_reason" => "missing_contact_id",
                 "source_contact_candidate" => %{
                   "ground_station_id" => "equator_prime",
                   "actual_throughput_mb" => 12.0
                 }
               }
             ]
           } = report

    invalid_row = List.first(report["invalid_contact_inputs"])

    assert %{
             "approval_status" => "operator_review_required",
             "approval_rule_matches" => [
               %{
                 "rule_id" => "invalid_contact_contention_input_review",
                 "required_operator_action" => "review_invalid_contact_contention_input"
               }
             ],
             "policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "policy_bundle_id" => "ground_network_allocation_v1"
             }
           } = invalid_row

    report_review = OperatorReview.from_contact_contention_report(report)

    invalid_review_row =
      Enum.find(report_review["rows"], &(&1["contact_id"] == "missing_contact_id:3"))

    assert %{
             "required_operator_action" => "review_invalid_contact_contention_input",
             "approval_rule_matches" => [
               %{"rule_id" => "invalid_contact_contention_input_review"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             }
           } = invalid_review_row

    import = CadenceImport.from_contact_contention_report(report)
    invalid_import_row = Enum.find(import["rows"], &(&1["contact_id"] == "missing_contact_id:3"))

    assert %{
             "import_action" => "review_contact_contention",
             "approval_rule_matches" => [
               %{"rule_id" => "invalid_contact_contention_input_review"}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             }
           } = invalid_import_row

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    resolution =
      ContactContention.resolution_report(contacts, report,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "recommendations" => [
               %{
                 "station_calendar_provider_ids" => ["provider_calendar"],
                 "station_calendar_provider_entry_ids" => [
                   "provider_entry_1",
                   "provider_entry_2"
                 ],
                 "station_calendar_directions" => ["downlink"],
                 "station_calendar_reservation_ids" => ["reservation_1", "reservation_2"],
                 "station_calendar_trust_boundary_statuses" => ["declared", "missing"],
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "station_calendar_directions" => ["downlink"]
                     }
                   }
                 ]
               }
             ]
           } = resolution

    resolution_review = OperatorReview.from_contact_contention_resolution_report(resolution)
    [resolution_review_row] = resolution_review["rows"]

    assert %{
             "station_calendar_directions" => ["downlink"],
             "source_recommendation" => %{"station_calendar_directions" => ["downlink"]}
           } = resolution_review_row

    resolution_manifest = CadenceImport.from_contact_contention_resolution_report(resolution)
    [resolution_import_row] = resolution_manifest["rows"]

    assert %{
             "station_calendar_directions" => ["downlink"],
             "source_recommendation" => %{"station_calendar_directions" => ["downlink"]}
           } = resolution_import_row

    review = OperatorReview.from_contact_contention_report(report)

    review_row =
      Enum.find(review["rows"], &(&1["source"] == "contact_contention_report.conflict_groups"))

    assert %{
             "station_calendar_provider_ids" => ["provider_calendar"],
             "station_calendar_provider_entry_ids" => ["provider_entry_1", "provider_entry_2"],
             "station_calendar_directions" => ["downlink"],
             "station_calendar_reservation_ids" => ["reservation_1", "reservation_2"],
             "source_contention_group" => %{
               "station_calendar_directions" => ["downlink"],
               "station_calendar_trust_boundary_statuses" => ["declared", "missing"]
             }
           } = review_row

    manifest = CadenceImport.from_contact_contention_report(report)

    import_row =
      Enum.find(manifest["rows"], &(&1["source"] == "contact_contention_report.conflict_groups"))

    assert %{
             "station_calendar_provider_ids" => ["provider_calendar"],
             "station_calendar_provider_entry_ids" => ["provider_entry_1", "provider_entry_2"],
             "station_calendar_directions" => ["downlink"],
             "station_calendar_reservation_ids" => ["reservation_1", "reservation_2"],
             "source_contention_group" => %{
               "station_calendar_directions" => ["downlink"],
               "station_calendar_trust_boundary_statuses" => ["declared", "missing"]
             }
           } = import_row

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(resolution_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(resolution_manifest)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "builds deterministic resolution recommendations without mutating candidates" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 2.0
      },
      %{
        id: :dl_2,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 160.0,
        score: 9.0
      }
    ]

    {annotated, report} =
      ContactContention.annotate_contacts(contacts,
        approval_policy: %{policy_bundle_id: "contact_command_review_v1"}
      )

    resolution = ContactContention.resolution_report(contacts, report)

    assert Enum.map(contacts, &Map.has_key?(&1, :contention_group_ids)) == [false, false]
    assert Enum.all?(annotated, &(&1["schedule_conflict_status"] == "contention_detected"))

    assert %{
             "schema_contract" => "contact_contention_resolution_report.v1",
             "model" => "deterministic_contact_contention_recommendation",
             "policy" => %{
               "selection_rule" => "highest_score_earliest_start",
               "action" => "recommend_preferred_contact_for_operator_review",
               "priority_fields" => priority_fields
             },
             "conflict_group_count" => 1,
             "recommendation_count" => 1,
             "model_limits" => model_limits,
             "recommendations" => [
               %{
                 "group_id" => "station:equator_prime:contention:1",
                 "selected_contact_id" => "dl_2",
                 "selected_scenario_id" => "leo_2",
                 "deferred_contact_ids" => ["dl_1"],
                 "candidate_count" => 2,
                 "selection_reason" => "highest_score_earliest_start",
                 "review_status" => "operator_review_required"
               }
             ],
             "assumptions" => %{
               "candidate_mutation" => "none",
               "boundary" => "recommendation_only_no_station_reservation"
             }
           } = resolution

    assert "command_contact_priority" in priority_fields
    assert "no_provider_reservation" in model_limits
    assert "no_schedule_mutation" in model_limits

    expected_model_limits =
      ContactContention.capabilities()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&to_string/1)

    assert model_limits == expected_model_limits

    assert {:ok, contact_contention_resolution_report_schema} =
             Schema.json_schema("contact_contention_resolution_report.v1")

    assert get_in(contact_contention_resolution_report_schema, ["properties", "model", "const"]) ==
             "deterministic_contact_contention_recommendation"

    stale_resolution_model =
      Map.put(resolution, "model", "stale_contact_contention_resolution_recommendation")

    assert {:error, stale_resolution_model_errors} =
             Schema.validate_artifact(stale_resolution_model)

    assert Enum.any?(
             stale_resolution_model_errors["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"deterministic_contact_contention_recommendation\"")
           )

    summary = ContactContention.resolution_summary(resolution)

    assert %{
             "schema_contract" => "contact_contention_resolution_summary.v1",
             "model" => "artifact_only_contact_contention_resolution_summary",
             "source_artifact_type" => "contact_contention_resolution_report.v1",
             "model_limits" => summary_model_limits,
             "conflict_group_count" => 1,
             "recommendation_count" => 1,
             "recommendation_group_ids" => ["station:equator_prime:contention:1"],
             "review_group_ids" => ["station:equator_prime:contention:1"],
             "selected_contact_ids" => ["dl_2"],
             "selected_contact_ids_by_group_id" => %{
               "station:equator_prime:contention:1" => ["dl_2"]
             },
             "deferred_contact_ids" => ["dl_1"],
             "deferred_contact_ids_by_group_id" => %{
               "station:equator_prime:contention:1" => ["dl_1"]
             },
             "ambiguous_group_ids" => [],
             "ambiguous_duplicate_contact_ids" => [],
             "ambiguous_duplicate_contact_ids_by_group_id" => %{},
             "review_contact_ids" => ["dl_1", "dl_2"],
             "review_contact_ids_by_group_id" => %{
               "station:equator_prime:contention:1" => ["dl_1", "dl_2"]
             },
             "review_recommendation_count" => 1,
             "resource_scope_counts" => %{"ground_station" => 1},
             "selected_contact_ids_by_resource_scope" => %{"ground_station" => ["dl_2"]},
             "deferred_contact_ids_by_resource_scope" => %{"ground_station" => ["dl_1"]},
             "review_contact_ids_by_resource_scope" => %{"ground_station" => ["dl_1", "dl_2"]},
             "selection_reason_counts" => %{"highest_score_earliest_start" => 1},
             "selected_contact_ids_by_selection_reason" => %{
               "highest_score_earliest_start" => ["dl_2"]
             },
             "action_counts" => %{"recommend_preferred_contact_for_operator_review" => 1},
             "review_contact_ids_by_action" => %{
               "recommend_preferred_contact_for_operator_review" => ["dl_1", "dl_2"]
             },
             "assumptions" => %{
               "candidate_mutation" => "none",
               "operator_authority" => "not_granted_by_summary"
             }
           } = summary

    assert summary_model_limits == expected_model_limits

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert {:ok, contact_contention_resolution_summary_schema} =
             Schema.json_schema("contact_contention_resolution_summary.v1")

    assert get_in(contact_contention_resolution_summary_schema, ["properties", "model", "const"]) ==
             "artifact_only_contact_contention_resolution_summary"

    assert get_in(contact_contention_resolution_summary_schema, [
             "properties",
             "model_limits",
             "const"
           ]) == expected_model_limits

    assert get_in(contact_contention_resolution_summary_schema, [
             "properties",
             "model_limits",
             "items",
             "enum"
           ]) == expected_model_limits

    assert ContactContention.resolution_summary(contacts, report) == summary
    assert OrbitalDynamics.contact_contention_resolution_summary(resolution) == summary
    assert OrbitalDynamics.contact_contention_resolution_summary(contacts, report) == summary

    stale_summary_model_limits = Map.put(summary, "model_limits", ["artifact_level_only"])

    assert {:error, stale_summary_model_limits_report} =
             Schema.validate_artifact(stale_summary_model_limits)

    assert Enum.any?(
             stale_summary_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match contact contention resolution summary model limits")
           )

    stale_summary_model =
      Map.put(summary, "model", "stale_contact_contention_resolution_summary")

    assert {:error, stale_summary_model_report} = Schema.validate_artifact(stale_summary_model)

    assert Enum.any?(
             stale_summary_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_contact_contention_resolution_summary\"")
           )

    stale_summary_count = Map.put(summary, "recommendation_count", 99)

    assert {:error, stale_summary_count_report} = Schema.validate_artifact(stale_summary_count)

    assert Enum.any?(
             stale_summary_count_report["errors"],
             &match?(
               %{
                 "path" => "$.recommendation_count",
                 "message" => "must equal recommendation_group_ids count"
               },
               &1
             )
           )

    stale_summary_routing =
      put_in(summary, ["selected_contact_ids_by_group_id"], %{"stale" => ["stale_selected"]})

    assert {:error, stale_summary_routing_report} =
             Schema.validate_artifact(stale_summary_routing)

    assert Enum.any?(
             stale_summary_routing_report["errors"],
             &match?(
               %{
                 "path" => "$.selected_contact_ids",
                 "message" => "must equal selected_contact_ids_by_group_id values"
               },
               &1
             )
           )

    stale_summary_resolution =
      resolution
      |> Map.put("conflict_group_count", 9)
      |> Map.put("recommendation_count", 0)
      |> Map.put("selected_contact_ids_by_group_id", %{"stale" => ["stale_selected"]})
      |> Map.put("deferred_contact_ids_by_group_id", %{"stale" => ["stale_deferred"]})
      |> Map.put("ambiguous_duplicate_contact_ids_by_group_id", %{"stale" => ["stale_dup"]})
      |> Map.put("review_contact_ids_by_group_id", %{"stale" => ["stale_review"]})
      |> Map.put("selected_contact_ids_by_resource_scope", %{"stale" => ["stale_selected"]})
      |> Map.put("deferred_contact_ids_by_resource_scope", %{"stale" => ["stale_deferred"]})
      |> Map.put("review_contact_ids_by_resource_scope", %{"stale" => ["stale_review"]})
      |> Map.put("selected_contact_ids_by_selection_reason", %{"stale" => ["stale_selected"]})
      |> Map.put("review_contact_ids_by_action", %{"stale" => ["stale_review"]})
      |> Map.put("capacity_pack_required_capacity_fraction_by_status", %{"stale" => 99.0})
      |> Map.put("required_capacity_fraction_source_counts", %{"stale" => 99})
      |> Map.put("required_capacity_fraction_contact_ids_by_source", %{
        "stale" => ["stale_contact"]
      })

    assert %{
             "conflict_group_count" => 1,
             "recommendation_count" => 1,
             "recommendation_group_ids" => ["station:equator_prime:contention:1"],
             "review_group_ids" => ["station:equator_prime:contention:1"],
             "selected_contact_ids_by_group_id" => %{
               "station:equator_prime:contention:1" => ["dl_2"]
             },
             "deferred_contact_ids_by_group_id" => %{
               "station:equator_prime:contention:1" => ["dl_1"]
             },
             "ambiguous_duplicate_contact_ids_by_group_id" => %{},
             "review_contact_ids_by_group_id" => %{
               "station:equator_prime:contention:1" => ["dl_1", "dl_2"]
             },
             "selected_contact_ids_by_resource_scope" => %{"ground_station" => ["dl_2"]},
             "deferred_contact_ids_by_resource_scope" => %{"ground_station" => ["dl_1"]},
             "review_contact_ids_by_resource_scope" => %{"ground_station" => ["dl_1", "dl_2"]},
             "selected_contact_ids_by_selection_reason" => %{
               "highest_score_earliest_start" => ["dl_2"]
             },
             "review_contact_ids_by_action" => %{
               "recommend_preferred_contact_for_operator_review" => ["dl_1", "dl_2"]
             },
             "capacity_pack_required_capacity_fraction_by_status" => %{},
             "required_capacity_fraction_source_counts" => %{},
             "required_capacity_fraction_contact_ids_by_source" => %{}
           } = ContactContention.resolution_summary(stale_summary_resolution)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)
  end

  test "resolution policy tie breakers affect deterministic contact selection" do
    contacts = [
      %{
        id: :a_long_contact,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 180.0,
        score: 10.0
      },
      %{
        id: :z_short_contact,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 140.0,
        score: 10.0
      }
    ]

    report = ContactContention.report(contacts)

    default_resolution = ContactContention.resolution_report(contacts, report)

    assert [
             %{
               "selected_contact_id" => "a_long_contact",
               "deferred_contact_ids" => ["z_short_contact"]
             }
           ] = default_resolution["recommendations"]

    tie_breaker_resolution =
      ContactContention.resolution_report(contacts, report,
        policy: %{tie_breakers: [:ends_at_s, :id]}
      )

    assert %{
             "policy" => %{"tie_breakers" => ["ends_at_s", "id"]},
             "recommendations" => [
               %{
                 "selected_contact_id" => "z_short_contact",
                 "deferred_contact_ids" => ["a_long_contact"]
               }
             ]
           } = tie_breaker_resolution

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(tie_breaker_resolution)
  end

  test "normalizes unsupported resolution policy into schema-valid effective policy evidence" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 180.0,
        score: 10.0
      },
      %{
        id: :dl_2,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 110.0,
        ends_at_s: 150.0,
        score: 8.0
      }
    ]

    report = ContactContention.report(contacts)

    resolution =
      ContactContention.resolution_report(contacts, report,
        policy: %{
          selection_rule: :unsupported_policy_rule,
          tie_breakers: [:ends_at_s, :unsupported_tie_breaker, 42],
          action: nil
        }
      )

    assert %{
             "policy" => %{
               "selection_rule" => "highest_score_earliest_start",
               "requested_selection_rule" => "unsupported_policy_rule",
               "tie_breakers" => ["ends_at_s"],
               "ignored_tie_breakers" => ["unsupported_tie_breaker", "42"],
               "policy_warnings" => [
                 "unsupported_selection_rule_defaulted",
                 "unsupported_tie_breakers_ignored"
               ],
               "action" => "recommend_preferred_contact_for_operator_review"
             },
             "recommendations" => [
               %{
                 "selected_contact_id" => "dl_1",
                 "selection_reason" => "highest_score_earliest_start",
                 "resolution_selection_rule" => "highest_score_earliest_start",
                 "resolution_tie_breakers" => ["ends_at_s"],
                 "requested_selection_rule" => "unsupported_policy_rule",
                 "ignored_tie_breakers" => ["unsupported_tie_breaker", "42"],
                 "policy_warnings" => [
                   "unsupported_selection_rule_defaulted",
                   "unsupported_tie_breakers_ignored"
                 ]
               }
             ]
           } = resolution

    review = OperatorReview.from_contact_contention_resolution_report(resolution)

    assert %{
             "review_type" => "contact_contention_recommendation",
             "selection_reason" => "highest_score_earliest_start",
             "resolution_selection_rule" => "highest_score_earliest_start",
             "resolution_tie_breakers" => ["ends_at_s"],
             "requested_selection_rule" => "unsupported_policy_rule",
             "ignored_tie_breakers" => ["unsupported_tie_breaker", "42"],
             "policy_warnings" => [
               "unsupported_selection_rule_defaulted",
               "unsupported_tie_breakers_ignored"
             ],
             "source_recommendation" => %{
               "requested_selection_rule" => "unsupported_policy_rule"
             }
           } = hd(review["rows"])

    manifest = CadenceImport.from_contact_contention_resolution_report(resolution)

    assert %{
             "import_action" => "review_contact_contention_resolution",
             "selection_reason" => "highest_score_earliest_start",
             "resolution_selection_rule" => "highest_score_earliest_start",
             "resolution_tie_breakers" => ["ends_at_s"],
             "requested_selection_rule" => "unsupported_policy_rule",
             "ignored_tie_breakers" => ["unsupported_tie_breaker", "42"],
             "policy_warnings" => [
               "unsupported_selection_rule_defaulted",
               "unsupported_tie_breakers_ignored"
             ],
             "source_recommendation" => %{
               "requested_selection_rule" => "unsupported_policy_rule"
             }
           } = hd(manifest["rows"])

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "accepts keyword resolution policy and records malformed policy input as warning evidence" do
    contacts = [
      %{
        id: :late_high,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 190.0,
        score: 99.0
      },
      %{
        id: :early_low,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 1.0
      }
    ]

    report = ContactContention.report(contacts)

    keyword_policy_resolution =
      ContactContention.resolution_report(contacts, report,
        policy: [selection_rule: :earliest_start_highest_score]
      )

    assert [
             %{
               "selected_contact_id" => "early_low",
               "selection_reason" => "earliest_start_highest_score"
             }
           ] = keyword_policy_resolution["recommendations"]

    malformed_policy_resolution =
      ContactContention.resolution_report(contacts, report, policy: :bad_policy)

    assert %{
             "policy" => %{
               "selection_rule" => "highest_score_earliest_start",
               "ignored_policy_input" => ":bad_policy",
               "policy_warnings" => ["unsupported_policy_input_ignored"]
             },
             "recommendations" => [
               %{
                 "selected_contact_id" => "late_high",
                 "selection_reason" => "highest_score_earliest_start"
               }
             ]
           } = malformed_policy_resolution

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(keyword_policy_resolution)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(malformed_policy_resolution)
  end

  test "priority-aware resolution can select lower score mission-priority contacts" do
    contacts = [
      %{
        id: :routine_downlink,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 12.0,
        contention_priority: 1.0
      },
      %{
        id: :urgent_command,
        type: :command,
        direction: :uplink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        score: 2.0,
        contention_priority: 10.0
      }
    ]

    report = ContactContention.report(contacts)

    resolution =
      ContactContention.resolution_report(contacts, report,
        policy: %{selection_rule: :highest_priority_highest_score}
      )

    assert %{
             "policy" => %{
               "selection_rule" => "highest_priority_highest_score",
               "priority_fields" => priority_fields
             },
             "recommendations" => [
               %{
                 "selected_contact_id" => "urgent_command",
                 "selected_priority" => 10.0,
                 "selected_priority_source" => "contention_priority",
                 "deferred_contact_ids" => ["routine_downlink"],
                 "deferred_contact_priorities" => [
                   %{
                     "contact_id" => "routine_downlink",
                     "priority" => 1.0,
                     "priority_source" => "contention_priority"
                   }
                 ],
                 "selection_reason" => "highest_priority_highest_score"
               }
             ]
           } = resolution

    assert "contention_priority" in priority_fields

    review = OperatorReview.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "resource_scope" => "ground_station",
               "ground_station_ids" => ["equator_prime"],
               "selected_contact_id" => "urgent_command",
               "selected_priority" => 10.0,
               "selected_priority_source" => "contention_priority",
               "candidate_count" => 2,
               "selection_reason" => "highest_priority_highest_score",
               "deferred_contact_priorities" => [
                 %{"contact_id" => "routine_downlink", "priority" => 1.0}
               ],
               "source_recommendation" => %{
                 "selected_priority" => 10.0
               }
             }
           ] = review["rows"]

    manifest = CadenceImport.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "import_action" => "review_contact_contention_resolution",
               "resource_scope" => "ground_station",
               "ground_station_ids" => ["equator_prime"],
               "selected_contact_id" => "urgent_command",
               "selected_priority" => 10.0,
               "selected_priority_source" => "contention_priority",
               "candidate_count" => 2,
               "selection_reason" => "highest_priority_highest_score",
               "deferred_contact_priorities" => [
                 %{"contact_id" => "routine_downlink", "priority" => 1.0}
               ],
               "source_recommendation" => %{"selected_priority" => 10.0}
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "priority-aware resolution reports requested priority fields without numeric evidence" do
    contacts = [
      %{
        id: :routine_downlink,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 20.0
      },
      %{
        id: :priority_command,
        type: :command,
        direction: :uplink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        score: 2.0,
        priority: "5.0"
      }
    ]

    report = ContactContention.report(contacts)

    resolution =
      ContactContention.resolution_report(contacts, report,
        policy: %{
          selection_rule: :highest_priority_highest_score,
          priority_fields: [:missing_priority, :priority]
        }
      )

    assert %{
             "policy" => %{
               "priority_fields" => ["missing_priority", "priority"],
               "requested_priority_fields" => ["missing_priority", "priority"]
             },
             "recommendations" => [
               %{
                 "selected_contact_id" => "priority_command",
                 "selected_priority" => 5.0,
                 "selected_priority_source" => "priority",
                 "requested_priority_fields" => ["missing_priority", "priority"],
                 "priority_field_evidence_counts" => %{
                   "missing_priority" => 0,
                   "priority" => 1
                 },
                 "priority_fields_without_numeric_evidence_count" => 1,
                 "priority_fields_without_numeric_evidence" => ["missing_priority"]
               }
             ]
           } = resolution

    review = OperatorReview.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "selected_contact_id" => "priority_command",
               "selected_priority_source" => "priority",
               "requested_priority_fields" => ["missing_priority", "priority"],
               "priority_field_evidence_counts" => %{
                 "missing_priority" => 0,
                 "priority" => 1
               },
               "priority_fields_without_numeric_evidence_count" => 1,
               "priority_fields_without_numeric_evidence" => ["missing_priority"],
               "source_recommendation" => %{
                 "priority_fields_without_numeric_evidence_count" => 1,
                 "priority_fields_without_numeric_evidence" => ["missing_priority"]
               }
             }
           ] = review["rows"]

    manifest = CadenceImport.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "import_action" => "review_contact_contention_resolution",
               "selected_contact_id" => "priority_command",
               "selected_priority_source" => "priority",
               "requested_priority_fields" => ["missing_priority", "priority"],
               "priority_field_evidence_counts" => %{
                 "missing_priority" => 0,
                 "priority" => 1
               },
               "priority_fields_without_numeric_evidence_count" => 1,
               "priority_fields_without_numeric_evidence" => ["missing_priority"],
               "source_recommendation" => %{
                 "priority_field_evidence_counts" => %{
                   "missing_priority" => 0,
                   "priority" => 1
                 },
                 "priority_fields_without_numeric_evidence_count" => 1
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "priority-aware resolution can use policy contact priority overrides" do
    contacts = [
      %{
        id: :routine_downlink,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 12.0
      },
      %{
        id: :priority_command,
        type: :command,
        direction: :uplink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        score: 2.0
      }
    ]

    report = ContactContention.report(contacts)

    resolution =
      ContactContention.resolution_report(contacts, report,
        policy: %{
          selection_rule: :highest_priority_highest_score,
          contact_priorities: %{
            priority_command: "10.0",
            routine_downlink: 1.0,
            ignored_bad_priority: "high"
          }
        }
      )

    assert %{
             "policy" => %{
               "selection_rule" => "highest_priority_highest_score",
               "priority_fields" => ["policy_contact_priority" | _],
               "priority_override_count" => 2,
               "priority_override_contact_ids" => ["priority_command", "routine_downlink"],
               "ignored_priority_override_count" => 1,
               "ignored_priority_override_keys" => ["ignored_bad_priority"],
               "ignored_priority_override_contact_ids" => ["ignored_bad_priority"],
               "policy_warnings" => ["invalid_priority_overrides_ignored"]
             },
             "recommendations" => [
               %{
                 "selected_contact_id" => "priority_command",
                 "selected_priority" => 10.0,
                 "selected_priority_source" => "policy_contact_priority",
                 "deferred_contact_ids" => ["routine_downlink"],
                 "deferred_contact_priorities" => [
                   %{
                     "contact_id" => "routine_downlink",
                     "priority" => 1.0,
                     "priority_source" => "policy_contact_priority"
                   }
                 ],
                 "resolution_priority_override_count" => 2,
                 "resolution_priority_override_contact_ids" => [
                   "priority_command",
                   "routine_downlink"
                 ],
                 "ignored_priority_override_count" => 1,
                 "ignored_priority_override_keys" => ["ignored_bad_priority"],
                 "ignored_priority_override_contact_ids" => ["ignored_bad_priority"],
                 "policy_warnings" => ["invalid_priority_overrides_ignored"]
               }
             ]
           } = resolution

    review = OperatorReview.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "selected_contact_id" => "priority_command",
               "selected_priority_source" => "policy_contact_priority",
               "resolution_priority_override_count" => 2,
               "resolution_priority_override_contact_ids" => [
                 "priority_command",
                 "routine_downlink"
               ],
               "ignored_priority_override_count" => 1,
               "ignored_priority_override_keys" => ["ignored_bad_priority"],
               "ignored_priority_override_contact_ids" => ["ignored_bad_priority"],
               "policy_warnings" => ["invalid_priority_overrides_ignored"],
               "source_recommendation" => %{
                 "selected_priority_source" => "policy_contact_priority",
                 "ignored_priority_override_keys" => ["ignored_bad_priority"]
               }
             }
           ] = review["rows"]

    manifest = CadenceImport.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "import_action" => "review_contact_contention_resolution",
               "selected_contact_id" => "priority_command",
               "selected_priority_source" => "policy_contact_priority",
               "resolution_priority_override_count" => 2,
               "resolution_priority_override_contact_ids" => [
                 "priority_command",
                 "routine_downlink"
               ],
               "ignored_priority_override_count" => 1,
               "ignored_priority_override_keys" => ["ignored_bad_priority"],
               "ignored_priority_override_contact_ids" => ["ignored_bad_priority"],
               "policy_warnings" => ["invalid_priority_overrides_ignored"],
               "source_recommendation" => %{
                 "selected_priority_source" => "policy_contact_priority",
                 "ignored_priority_override_keys" => ["ignored_bad_priority"]
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    invalid_policy_count = put_in(resolution, ["policy", "priority_override_count"], 99)

    assert {:error, policy_count_report} = Schema.validate_artifact(invalid_policy_count)

    assert Enum.any?(
             policy_count_report["errors"],
             &(&1["path"] == "$.policy.priority_override_count")
           )

    invalid_policy_ids =
      put_in(resolution, ["policy", "priority_override_contact_ids"], ["priority_command"])

    assert {:error, policy_ids_report} = Schema.validate_artifact(invalid_policy_ids)

    assert Enum.any?(
             policy_ids_report["errors"],
             &(&1["path"] == "$.policy.priority_override_contact_ids")
           )

    invalid_recommendation_count =
      put_in(
        resolution,
        ["recommendations", Access.at(0), "resolution_priority_override_count"],
        99
      )

    assert {:error, recommendation_count_report} =
             Schema.validate_artifact(invalid_recommendation_count)

    assert Enum.any?(
             recommendation_count_report["errors"],
             &(&1["path"] == "$.recommendations[0].resolution_priority_override_count")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "priority-aware resolution can prefer command contacts without caller precomputed priority" do
    contacts = [
      %{
        id: :routine_downlink,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 20.0
      },
      %{
        id: :command_contact,
        type: :planned_contact,
        direction: :uplink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        score: 1.0
      }
    ]

    report = ContactContention.report(contacts)

    resolution =
      ContactContention.resolution_report(contacts, report,
        policy: %{
          selection_rule: :highest_priority_highest_score,
          priority_fields: [:command_contact_priority]
        }
      )

    assert %{
             "policy" => %{
               "selection_rule" => "highest_priority_highest_score",
               "priority_fields" => ["command_contact_priority"]
             },
             "recommendations" => [
               %{
                 "selected_contact_id" => "command_contact",
                 "selected_priority" => 1.0,
                 "selected_priority_source" => "command_contact_priority",
                 "deferred_contact_ids" => ["routine_downlink"],
                 "deferred_contact_priorities" => [
                   %{
                     "contact_id" => "routine_downlink",
                     "priority" => deferred_priority,
                     "priority_source" => "command_contact_priority"
                   }
                 ],
                 "selection_reason" => "highest_priority_highest_score"
               }
             ]
           } = resolution

    assert deferred_priority == 0.0

    review = OperatorReview.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "selected_contact_id" => "command_contact",
               "selected_priority" => 1.0,
               "selected_priority_source" => "command_contact_priority",
               "deferred_contact_priorities" => [
                 %{"contact_id" => "routine_downlink", "priority" => review_deferred_priority}
               ]
             }
           ] = review["rows"]

    assert review_deferred_priority == 0.0

    manifest = CadenceImport.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "import_action" => "review_contact_contention_resolution",
               "selected_contact_id" => "command_contact",
               "selected_priority_source" => "command_contact_priority"
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "contention resolution parses numeric string scores and priorities" do
    contacts = [
      %{
        id: :high_priority_low_score,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        priority: "7.5",
        score: "1.0"
      },
      %{
        id: :low_priority_high_score,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        priority: "5.0",
        score: "99.0"
      }
    ]

    report = ContactContention.report(contacts)

    resolution =
      ContactContention.resolution_report(contacts, report,
        policy: %{
          selection_rule: :highest_priority_highest_score,
          priority_fields: [:priority]
        }
      )

    assert %{
             "recommendations" => [
               %{
                 "selected_contact_id" => "high_priority_low_score",
                 "selected_priority" => 7.5,
                 "selected_priority_source" => "priority",
                 "deferred_contact_ids" => ["low_priority_high_score"],
                 "source_contact_candidates" => source_candidates,
                 "deferred_contact_priorities" => [
                   %{
                     "contact_id" => "low_priority_high_score",
                     "priority" => 5.0,
                     "priority_source" => "priority"
                   }
                 ]
               }
             ]
           } = resolution

    assert Enum.map(source_candidates, & &1["score"]) == [1.0, 99.0]
    assert Enum.map(source_candidates, & &1["priority"]) == [7.5, 5.0]

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)
  end

  test "priority-aware resolution can prefer direct station reservation matches" do
    contacts = [
      %{
        id: :high_score_unreserved,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 20.0
      },
      %{
        id: :reserved_candidate,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        score: 2.0,
        station_reservation_id: :reservation_alpha,
        station_reserved_by: :leo_2,
        station_reservation_status: "Confirmed",
        station_reservation_match_status: "Matched",
        station_calendar_reservation_statuses: ["Confirmed"],
        station_calendar_reservation_expires_at_s: [360.0],
        source_station_calendar_entry: %{
          id: :reserved_window,
          availability: "Reserved",
          reservation_status: "Confirmed",
          reservation_expires_at_s: 360.0
        }
      }
    ]

    report = ContactContention.report(contacts)

    assert %{
             "conflict_groups" => [
               %{
                 "station_reservation_ids" => ["reservation_alpha"],
                 "station_reserved_bys" => ["leo_2"],
                 "station_reservation_statuses" => ["confirmed"],
                 "station_reservation_match_statuses" => ["matched"],
                 "station_calendar_reservation_expires_at_s" => [360.0]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    resolution =
      ContactContention.resolution_report(contacts, report,
        policy: %{selection_rule: :highest_priority_highest_score}
      )

    assert %{
             "policy" => %{
               "selection_rule" => "highest_priority_highest_score",
               "priority_fields" => priority_fields
             },
             "recommendations" => [
               %{
                 "selected_contact_id" => "reserved_candidate",
                 "selected_priority" => 1.0,
                 "selected_priority_source" => "station_reservation_priority",
                 "deferred_contact_ids" => ["high_score_unreserved"],
                 "deferred_contact_priorities" => [
                   %{
                     "contact_id" => "high_score_unreserved",
                     "priority" => deferred_priority,
                     "priority_source" => "command_contact_priority"
                   }
                 ],
                 "selection_reason" => "highest_priority_highest_score",
                 "station_reservation_ids" => ["reservation_alpha"],
                 "station_reserved_bys" => ["leo_2"],
                 "station_reservation_statuses" => ["confirmed"],
                 "station_reservation_match_statuses" => ["matched"],
                 "station_calendar_reservation_expires_at_s" => [360.0],
                 "source_contact_candidates" => source_contact_candidates
               }
             ]
           } = resolution

    assert deferred_priority == 0.0
    assert "station_reservation_priority" in priority_fields

    assert %{
             "station_reservation_id" => "reservation_alpha",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "matched",
             "station_calendar_reservation_expires_at_s" => [360.0]
           } = Enum.find(source_contact_candidates, &(&1["id"] == "reserved_candidate"))

    review = OperatorReview.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "selected_contact_id" => "reserved_candidate",
               "selected_priority" => 1.0,
               "selected_priority_source" => "station_reservation_priority",
               "station_reservation_ids" => ["reservation_alpha"],
               "station_reserved_bys" => ["leo_2"],
               "station_reservation_statuses" => ["confirmed"],
               "station_reservation_match_statuses" => ["matched"],
               "station_calendar_reservation_expires_at_s" => [360.0],
               "source_recommendation" => %{
                 "selected_priority_source" => "station_reservation_priority"
               }
             }
           ] = review["rows"]

    manifest = CadenceImport.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "import_action" => "review_contact_contention_resolution",
               "selected_contact_id" => "reserved_candidate",
               "selected_priority" => 1.0,
               "selected_priority_source" => "station_reservation_priority",
               "station_reservation_ids" => ["reservation_alpha"],
               "station_reserved_bys" => ["leo_2"],
               "station_reservation_statuses" => ["confirmed"],
               "station_reservation_match_statuses" => ["matched"],
               "station_calendar_reservation_expires_at_s" => [360.0]
             }
           ] = manifest["rows"]

    invalid_report =
      put_in(
        report,
        ["conflict_groups", Access.at(0), "station_calendar_reservation_expires_at_s"],
        ["360"]
      )

    assert {:error, invalid_report_errors} = Schema.validate_artifact(invalid_report)

    assert Enum.any?(
             invalid_report_errors["errors"],
             &(&1["path"] ==
                 "$.conflict_groups[0].station_calendar_reservation_expires_at_s[0]" and
                 &1["message"] == "must be a number")
           )

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "priority-aware resolution treats owner-matched station reservations as direct matches" do
    contacts = [
      %{
        id: :high_score_unreserved,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 20.0
      },
      %{
        id: :owner_matched_candidate,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        score: 2.0,
        station_reservation_id: :reservation_owner,
        station_reserved_by: :leo_2,
        station_reservation_status: :reserved,
        station_reservation_match_status: :owner_matched
      }
    ]

    report = ContactContention.report(contacts)

    resolution =
      ContactContention.resolution_report(contacts, report,
        policy: %{selection_rule: :highest_priority_highest_score}
      )

    assert %{
             "recommendations" => [
               %{
                 "selected_contact_id" => "owner_matched_candidate",
                 "selected_priority" => 1.0,
                 "selected_priority_source" => "station_reservation_priority",
                 "deferred_contact_ids" => ["high_score_unreserved"],
                 "station_reservation_match_statuses" => ["owner_matched"],
                 "source_contact_candidates" => source_contact_candidates
               }
             ]
           } = resolution

    assert %{
             "station_reservation_id" => "reservation_owner",
             "station_reservation_status" => "reserved",
             "station_reservation_match_status" => "owner_matched"
           } = Enum.find(source_contact_candidates, &(&1["id"] == "owner_matched_candidate"))

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)
  end

  test "station reservation priority ignores aggregate provider-calendar reservation lists" do
    contacts = [
      %{
        id: :aggregate_only,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 20.0,
        station_calendar_reservation_ids: [:reservation_alpha],
        station_calendar_reservation_statuses: [:confirmed]
      },
      %{
        id: :ordinary_contact,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        score: 2.0
      }
    ]

    report = ContactContention.report(contacts)

    resolution =
      ContactContention.resolution_report(contacts, report,
        policy: %{
          selection_rule: :highest_priority_highest_score,
          priority_fields: [:station_reservation_priority]
        }
      )

    assert %{
             "recommendations" => [
               %{
                 "selected_contact_id" => "aggregate_only",
                 "deferred_contact_ids" => ["ordinary_contact"]
               } = recommendation
             ]
           } = resolution

    refute Map.has_key?(recommendation, "selected_priority")
    refute Map.has_key?(recommendation, "selected_priority_source")
    assert recommendation["deferred_contact_priorities"] == []

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)
  end

  test "station reservation priority accepts reservation status aliases" do
    contacts = [
      %{
        id: :high_score_unreserved,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 20.0
      },
      %{
        id: :alias_reserved_candidate,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 150.0,
        score: 2.0,
        reservation_id: :reservation_alpha,
        reserved_by: :leo_2,
        reservation_status: :confirmed,
        reservation_match_status: :matched
      }
    ]

    report = ContactContention.report(contacts)

    resolution =
      ContactContention.resolution_report(contacts, report,
        policy: %{
          selection_rule: :highest_priority_highest_score,
          priority_fields: [:station_reservation_priority]
        }
      )

    assert %{
             "conflict_groups" => [
               %{
                 "station_reservation_ids" => ["reservation_alpha"],
                 "station_reserved_bys" => ["leo_2"],
                 "station_reservation_statuses" => ["confirmed"],
                 "station_reservation_match_statuses" => ["matched"]
               }
             ]
           } = report

    assert %{
             "recommendations" => [
               %{
                 "selected_contact_id" => "alias_reserved_candidate",
                 "selected_priority" => 1.0,
                 "selected_priority_source" => "station_reservation_priority",
                 "deferred_contact_ids" => ["high_score_unreserved"],
                 "station_reservation_ids" => ["reservation_alpha"],
                 "station_reserved_bys" => ["leo_2"],
                 "station_reservation_statuses" => ["confirmed"],
                 "station_reservation_match_statuses" => ["matched"]
               }
             ]
           } = resolution

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)
  end

  test "station reservation priority tie breaker can resolve equal-score contacts" do
    contacts = [
      %{
        id: :ordinary_contact,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 10.0
      },
      %{
        id: :reserved_candidate,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 150.0,
        score: 10.0,
        station_reservation_id: :reservation_alpha,
        station_reservation_status: :confirmed
      }
    ]

    report = ContactContention.report(contacts)

    resolution =
      ContactContention.resolution_report(contacts, report,
        policy: %{
          selection_rule: :highest_score_earliest_start,
          tie_breakers: [:station_reservation_priority, :id]
        }
      )

    assert %{
             "policy" => %{
               "selection_rule" => "highest_score_earliest_start",
               "tie_breakers" => ["station_reservation_priority", "id"]
             },
             "recommendations" => [
               %{
                 "selected_contact_id" => "reserved_candidate",
                 "deferred_contact_ids" => ["ordinary_contact"],
                 "station_reservation_ids" => ["reservation_alpha"]
               }
             ]
           } = resolution

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)
  end

  test "detects same-spacecraft contention across different stations" do
    contacts = [
      %{
        id: :dl_equator,
        type: :downlink,
        spacecraft: %{id: :sat_1},
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 2.0,
        source_window_id: :window_equator
      },
      %{
        id: :dl_dsn,
        type: :downlink,
        satellite: %{satellite_id: :sat_1},
        scenario_id: :leo_1,
        ground_station_id: :deep_space_net,
        starts_at_s: 130.0,
        ends_at_s: 180.0,
        score: 5.0,
        source_window_id: :window_dsn
      },
      %{
        id: :dl_other_spacecraft,
        type: :downlink,
        spacecraft_id: :sat_2,
        scenario_id: :leo_2,
        ground_station_id: :deep_space_net,
        starts_at_s: 220.0,
        ends_at_s: 270.0,
        score: 10.0,
        source_window_id: :window_other
      }
    ]

    {annotated, report} = ContactContention.annotate_contacts(contacts)
    resolution = ContactContention.resolution_report(contacts, report)

    assert [
             %{
               "id" => "dl_equator",
               "contention_group_ids" => ["spacecraft:sat_1:contention:1"]
             },
             %{
               "id" => "dl_dsn",
               "contention_group_ids" => ["spacecraft:sat_1:contention:1"]
             },
             %{"id" => "dl_other_spacecraft"}
           ] = annotated

    assert %{
             "conflict_group_count" => 1,
             "conflict_groups" => [
               %{
                 "id" => "spacecraft:sat_1:contention:1",
                 "resource_scope" => "spacecraft",
                 "ground_station_id" => "multi_station",
                 "ground_station_ids" => ["deep_space_net", "equator_prime"],
                 "spacecraft_id" => "sat_1",
                 "spacecraft_ids" => ["sat_1"],
                 "operator_action_reason" => "same_spacecraft_overlapping_contact_windows",
                 "contact_ids" => ["dl_equator", "dl_dsn"]
               }
             ]
           } = report

    assert %{
             "recommendations" => [
               %{
                 "group_id" => "spacecraft:sat_1:contention:1",
                 "resource_scope" => "spacecraft",
                 "spacecraft_id" => "sat_1",
                 "ground_station_ids" => ["deep_space_net", "equator_prime"],
                 "selected_contact_id" => "dl_dsn",
                 "deferred_contact_ids" => ["dl_equator"]
               }
             ]
           } = resolution

    review = OperatorReview.from_contact_contention_report(report)
    review_row = List.first(review["rows"])

    assert %{
             "review_type" => "contact_contention_review",
             "resource_scope" => "spacecraft",
             "ground_station_id" => "multi_station",
             "ground_station_ids" => ["deep_space_net", "equator_prime"],
             "spacecraft_id" => "sat_1",
             "spacecraft_ids" => ["sat_1"],
             "contact_ids" => ["dl_equator", "dl_dsn"]
           } = review_row

    manifest = CadenceImport.from_contact_contention_report(report)
    import_row = List.first(manifest["rows"])

    assert %{
             "import_action" => "review_contact_contention",
             "resource_scope" => "spacecraft",
             "ground_station_id" => "multi_station",
             "ground_station_ids" => ["deep_space_net", "equator_prime"],
             "spacecraft_id" => "sat_1",
             "spacecraft_ids" => ["sat_1"],
             "contact_ids" => ["dl_equator", "dl_dsn"]
           } = import_row

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "reports duplicate contact ids as ambiguous contention identity" do
    contacts = [
      %{
        id: :dup_contact,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 10.0,
        source_window_id: :window_dup_a
      },
      %{
        id: :dup_contact,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 180.0,
        score: 1.0,
        source_window_id: :window_dup_b
      },
      %{
        id: :unique_contact,
        type: :downlink,
        scenario_id: :leo_3,
        ground_station_id: :equator_prime,
        starts_at_s: 130.0,
        ends_at_s: 190.0,
        score: 5.0,
        source_window_id: :window_unique
      }
    ]

    {annotated, report} =
      ContactContention.annotate_contacts(contacts,
        approval_policy: %{policy_bundle_id: "contact_command_review_v1"}
      )

    assert Enum.all?(
             annotated,
             &(&1["contention_group_ids"] == ["station:equator_prime:contention:1"])
           )

    assert %{
             "conflicted_contact_count" => 3,
             "duplicate_contact_id_count" => 1,
             "duplicate_contact_candidate_count" => 2,
             "conflict_groups" => [
               %{
                 "contact_count" => 3,
                 "contact_ids" => ["dup_contact", "dup_contact", "unique_contact"],
                 "duplicate_contact_ids" => ["dup_contact"],
                 "duplicate_contact_id_count" => 1,
                 "duplicate_contact_candidate_count" => 2,
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "contact_ids" => ["dup_contact", "dup_contact", "unique_contact"],
                       "duplicate_contact_ids" => ["dup_contact"],
                       "duplicate_contact_id_count" => 1,
                       "duplicate_contact_candidate_count" => 2
                     }
                   }
                 ],
                 "source_contact_candidates" => source_contact_candidates
               }
             ]
           } = report

    assert Enum.map(source_contact_candidates, & &1["id"]) == [
             "dup_contact",
             "dup_contact",
             "unique_contact"
           ]

    resolution =
      ContactContention.resolution_report(contacts, report,
        approval_policy: %{policy_bundle_id: "contact_command_review_v1"}
      )

    assert %{
             "recommendations" => [
               %{
                 "group_id" => "station:equator_prime:contention:1",
                 "candidate_count" => 3,
                 "deferred_contact_ids" => [],
                 "selection_reason" => "duplicate_contact_id_requires_operator_review",
                 "resolution_status" => "ambiguous_contact_identity",
                 "resolution_issue" => "duplicate_contact_id",
                 "duplicate_contact_ids" => ["dup_contact"],
                 "duplicate_contact_id_count" => 1,
                 "duplicate_contact_candidate_count" => 2,
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "resolution_status" => "ambiguous_contact_identity",
                       "resolution_issue" => "duplicate_contact_id",
                       "duplicate_contact_ids" => ["dup_contact"],
                       "duplicate_contact_id_count" => 1,
                       "duplicate_contact_candidate_count" => 2
                     }
                   }
                 ],
                 "duplicate_contact_candidates" => duplicate_contact_candidates,
                 "action" => "review_ambiguous_contact_contention_identity"
               }
             ]
           } = resolution

    refute Map.has_key?(hd(resolution["recommendations"]), "selected_contact_id")
    assert Enum.map(duplicate_contact_candidates, & &1["id"]) == ["dup_contact", "dup_contact"]

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    stale_ambiguous_summary_resolution =
      resolution
      |> Map.put("ambiguous_duplicate_contact_ids_by_group_id", %{"stale" => ["stale_dup"]})

    assert %{
             "ambiguous_group_ids" => ["station:equator_prime:contention:1"],
             "ambiguous_duplicate_contact_ids" => ["dup_contact"],
             "ambiguous_duplicate_contact_ids_by_group_id" => %{
               "station:equator_prime:contention:1" => ["dup_contact"]
             }
           } = ContactContention.resolution_summary(stale_ambiguous_summary_resolution)

    mismatched_duplicate_group_count =
      put_in(report, ["conflict_groups", Access.at(0), "duplicate_contact_ids"], [])

    assert {:error, mismatched_duplicate_group_count_report} =
             Schema.validate_artifact(mismatched_duplicate_group_count)

    assert Enum.any?(
             mismatched_duplicate_group_count_report["errors"],
             &(&1["path"] == "$.conflict_groups[0].duplicate_contact_id_count" and
                 &1["message"] == "must equal 0")
           )

    missing_duplicate_recommendation_evidence =
      update_in(
        resolution,
        ["recommendations", Access.at(0)],
        &Map.delete(&1, "duplicate_contact_candidates")
      )

    assert {:error, missing_duplicate_recommendation_evidence_report} =
             Schema.validate_artifact(missing_duplicate_recommendation_evidence)

    assert Enum.any?(
             missing_duplicate_recommendation_evidence_report["errors"],
             &(&1["path"] == "$.recommendations[0].duplicate_contact_candidates" and
                 &1["message"] == "is required")
           )

    invalid_duplicate_contact_id =
      put_in(
        resolution,
        ["recommendations", Access.at(0), "duplicate_contact_ids"],
        ["bad contact id"]
      )

    assert {:error, invalid_duplicate_contact_id_report} =
             Schema.validate_artifact(invalid_duplicate_contact_id)

    assert Enum.any?(
             invalid_duplicate_contact_id_report["errors"],
             &(&1["path"] == "$.recommendations[0].duplicate_contact_ids[0]" and
                 &1["message"] =~ "must match stable ID pattern")
           )

    review = OperatorReview.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "resolution_status" => "ambiguous_contact_identity",
               "duplicate_contact_ids" => ["dup_contact"],
               "source_recommendation" => %{
                 "duplicate_contact_candidates" => [
                   %{"id" => "dup_contact"},
                   %{"id" => "dup_contact"}
                 ]
               }
             }
           ] = review["rows"]

    manifest = CadenceImport.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "resolution_status" => "ambiguous_contact_identity",
               "duplicate_contact_ids" => ["dup_contact"],
               "source_recommendation" => %{
                 "duplicate_contact_candidates" => [
                   %{"id" => "dup_contact"},
                   %{"id" => "dup_contact"}
                 ]
               }
             }
           ] = manifest["rows"]
  end

  test "keeps generated contention identities stable across source contact ordering" do
    contacts = [
      %{
        id: :dup_contact,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_a,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 1.0,
        source_window_id: :window_b
      },
      %{
        id: :dup_contact,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft_id: :sat_a,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 1.0,
        source_window_id: :window_a
      },
      %{
        id: :unique_contact,
        type: :downlink,
        scenario_id: :leo_2,
        spacecraft_id: :sat_b,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 180.0,
        score: 1.0,
        source_window_id: :window_c
      }
    ]

    assert contact_contention_identity_projection(contacts) ==
             contact_contention_identity_projection(Enum.reverse(contacts))

    assert %{
             groups: [
               %{
                 "id" => "station:equator_prime:contention:1",
                 source_window_ids: ["window_a", "window_b", "window_c"]
               }
             ],
             recommendations: [
               %{
                 "group_id" => "station:equator_prime:contention:1",
                 duplicate_source_window_ids: ["window_a", "window_b"]
               }
             ]
           } = contact_contention_identity_projection(contacts)
  end

  test "includes direct command and tracking station windows in contention groups" do
    contacts = [
      %{
        id: :cmd_window,
        type: :command,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 3.0
      },
      %{
        id: :tracking_window,
        type: :tracking,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 180.0,
        score: 4.0
      }
    ]

    {annotated, report} =
      ContactContention.annotate_contacts(contacts,
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert Enum.all?(annotated, &(&1["schedule_conflict_status"] == "contention_detected"))

    assert [
             %{
               "contact_ids" => ["cmd_window", "tracking_window"],
               "direction" => "mixed",
               "required_operator_action" => "review_contact_contention"
             }
           ] = report["conflict_groups"]

    resolution = ContactContention.resolution_report(annotated, report)

    assert [
             %{
               "selected_contact_id" => "tracking_window",
               "deferred_contact_ids" => ["cmd_window"]
             }
           ] = resolution["recommendations"]

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)
  end

  test "includes direction-only station windows in contention groups" do
    contacts = [
      %{
        id: :cmd_direction_only,
        direction: :command,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 3.0
      },
      %{
        id: :tracking_direction_only,
        direction: :tracking,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 180.0,
        score: 4.0
      }
    ]

    {annotated, report} =
      ContactContention.annotate_contacts(contacts,
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert Enum.all?(annotated, &(&1["schedule_conflict_status"] == "contention_detected"))

    assert %{
             "input_contact_count" => 2,
             "conflicted_contact_count" => 2,
             "conflict_group_count" => 1,
             "conflict_groups" => [
               %{
                 "contact_ids" => ["cmd_direction_only", "tracking_direction_only"],
                 "direction" => "mixed",
                 "directions" => ["command", "tracking"],
                 "required_operator_action" => "review_contact_contention",
                 "approval_requirements" => [
                   %{
                     "requirement_type" => "command_review",
                     "activity_context" => %{
                       "direction" => "mixed",
                       "directions" => ["command", "tracking"]
                     }
                   }
                 ],
                 "approval_rule_matches" => rule_matches
               }
             ]
           } = report

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "command_uplink_authority_review" and
                 &1["direction"] == "mixed" and
                 &1["directions"] == ["mixed", "command", "tracking"])
           )

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "includes health-check contacts in contention groups and policy review" do
    contacts = [
      %{
        id: :typed_health_check,
        type: :health_check,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 3.0
      },
      %{
        id: :provider_health_check,
        type: :planned_contact,
        direction: :health_check,
        scenario_id: :leo_2,
        station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 180.0,
        score: 4.0
      }
    ]

    {annotated, report} =
      ContactContention.annotate_contacts(contacts,
        approval_policy: %{policy_bundle_id: "contact_command_review_v1"}
      )

    assert Enum.all?(annotated, &(&1["schedule_conflict_status"] == "contention_detected"))

    assert %{
             "input_contact_count" => 2,
             "conflicted_contact_count" => 2,
             "conflict_group_count" => 1,
             "conflict_groups" => [
               %{
                 "contact_ids" => ["typed_health_check", "provider_health_check"],
                 "direction" => "health_check",
                 "directions" => ["health_check"],
                 "approval_requirements" => [
                   %{
                     "requirement_type" => "health_check_review",
                     "activity_context" => %{
                       "direction" => "health_check",
                       "directions" => ["health_check"]
                     }
                   }
                 ],
                 "approval_rule_matches" => [
                   %{
                     "rule_id" => "command_health_review",
                     "requirement_type" => "health_check_review"
                   }
                 ]
               }
             ]
           } = report

    resolution =
      ContactContention.resolution_report(contacts, report,
        approval_policy: %{policy_bundle_id: "contact_command_review_v1"}
      )

    assert [
             %{
               "direction" => "health_check",
               "directions" => ["health_check"],
               "selected_contact_id" => "provider_health_check",
               "approval_requirements" => [
                 %{
                   "requirement_type" => "health_check_review",
                   "activity_context" => %{"direction" => "health_check"}
                 }
               ],
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "command_health_review",
                   "requirement_type" => "health_check_review"
                 }
               ]
             }
           ] = resolution["recommendations"]

    review = OperatorReview.from_contact_contention_resolution_report(resolution)
    manifest = CadenceImport.from_contact_contention_resolution_report(resolution)

    assert Enum.any?(
             review["rows"],
             &(&1["direction"] == "health_check" and
                 get_in(&1, [
                   "source_recommendation",
                   "approval_requirements",
                   Access.at(0),
                   "requirement_type"
                 ]) == "health_check_review")
           )

    assert Enum.any?(
             manifest["rows"],
             &(&1["direction"] == "health_check" and
                 get_in(&1, [
                   "source_recommendation",
                   "approval_requirements",
                   Access.at(0),
                   "requirement_type"
                 ]) == "health_check_review")
           )

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "classifies uplink contention and resolution requirements as command review" do
    contacts = [
      %{
        id: :uplink_early,
        direction: :uplink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 3.0
      },
      %{
        id: :uplink_late,
        direction: :uplink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 180.0,
        score: 4.0
      }
    ]

    {_annotated, report} =
      ContactContention.annotate_contacts(contacts,
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert [
             %{
               "direction" => "uplink",
               "directions" => ["uplink"],
               "approval_requirements" => [
                 %{
                   "requirement_type" => "command_review",
                   "activity_context" => %{
                     "direction" => "uplink",
                     "directions" => ["uplink"]
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
           ] = report["conflict_groups"]

    resolution =
      ContactContention.resolution_report(contacts, report,
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert [
             %{
               "direction" => "uplink",
               "directions" => ["uplink"],
               "selected_contact_id" => "uplink_late",
               "approval_requirements" => [
                 %{
                   "requirement_type" => "command_review",
                   "activity_context" => %{
                     "direction" => "uplink",
                     "directions" => ["uplink"]
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
           ] = resolution["recommendations"]

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    review = OperatorReview.from_contact_contention_resolution_report(resolution)

    assert Enum.any?(
             review["rows"],
             &(&1["direction"] == "uplink" and
                 get_in(&1, [
                   "source_recommendation",
                   "approval_requirements",
                   Access.at(0),
                   "requirement_type"
                 ]) == "command_review")
           )

    manifest = CadenceImport.from_contact_contention_resolution_report(resolution)

    assert Enum.any?(
             manifest["rows"],
             &(&1["direction"] == "uplink" and
                 get_in(&1, [
                   "source_recommendation",
                   "approval_requirements",
                   Access.at(0),
                   "requirement_type"
                 ]) == "command_review")
           )
  end

  test "normalizes station-id-only provider contacts in contention groups" do
    contacts = [
      %{
        id: :provider_a,
        type: :contact,
        direction: :downlink,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 2.0
      },
      %{
        id: :provider_b,
        type: :contact,
        direction: :downlink,
        scenario_id: :leo_2,
        station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 180.0,
        score: 3.0
      }
    ]

    {annotated, report} = ContactContention.annotate_contacts(contacts)

    assert Enum.all?(annotated, &(&1["schedule_conflict_status"] == "contention_detected"))
    assert Enum.all?(annotated, &(&1["ground_station_id"] == "equator_prime"))

    assert %{
             "input_contact_count" => 2,
             "conflicted_contact_count" => 2,
             "conflict_groups" => [
               %{
                 "id" => "station:equator_prime:contention:1",
                 "ground_station_id" => "equator_prime",
                 "contact_ids" => ["provider_a", "provider_b"],
                 "direction" => "downlink"
               }
             ]
           } = report

    resolution = ContactContention.resolution_report(contacts, report)

    assert [
             %{
               "group_id" => "station:equator_prime:contention:1",
               "ground_station_id" => "equator_prime",
               "selected_contact_id" => "provider_b",
               "deferred_contact_ids" => ["provider_a"]
             }
           ] = resolution["recommendations"]

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)
  end

  test "normalizes provider-shaped station objects in contention groups" do
    contacts = [
      %{
        id: :provider_nested_a,
        direction: :downlink,
        scenario_id: :leo_1,
        station: %{id: :equator_prime},
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 2.0
      },
      %{
        id: :provider_nested_b,
        direction: :downlink,
        scenario_id: :leo_2,
        ground_station: %{ground_station_id: :equator_prime},
        starts_at_s: 120.0,
        ends_at_s: 180.0,
        score: 3.0
      }
    ]

    {annotated, report} = ContactContention.annotate_contacts(contacts)

    assert Enum.all?(annotated, &(&1["ground_station_id"] == "equator_prime"))
    assert Enum.all?(annotated, &(&1["schedule_conflict_status"] == "contention_detected"))

    assert [
             %{
               "id" => "station:equator_prime:contention:1",
               "ground_station_id" => "equator_prime",
               "contact_ids" => ["provider_nested_a", "provider_nested_b"],
               "source_contact_candidates" => [
                 %{"station" => %{"id" => "equator_prime"}},
                 %{"ground_station" => %{"ground_station_id" => "equator_prime"}}
               ]
             }
           ] = report["conflict_groups"]

    resolution = ContactContention.resolution_report(contacts, report)

    assert [
             %{
               "group_id" => "station:equator_prime:contention:1",
               "selected_contact_id" => "provider_nested_b",
               "deferred_contact_ids" => ["provider_nested_a"]
             }
           ] = resolution["recommendations"]

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)
  end

  test "preserves malformed nested station identity as invalid contention input" do
    contacts = [
      %{
        id: :bad_nested_station,
        direction: :downlink,
        scenario_id: :leo_1,
        station: %{id: "bad station id"},
        starts_at_s: 100.0,
        ends_at_s: 170.0
      }
    ]

    {_annotated, report} = ContactContention.annotate_contacts(contacts)

    assert %{
             "invalid_contact_input_count" => 1,
             "invalid_contact_inputs" => [
               %{
                 "contact_id" => "bad_nested_station",
                 "invalid_contact_input_reason" => "invalid_ground_station_id",
                 "source_contact_candidate" => %{
                   "station" => %{"id" => "bad station id"},
                   "ground_station_id" => "bad station id"
                 }
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "accepts activity-type-only tracking rows without downlink inference" do
    contacts = [
      %{
        id: :provider_tracking_a,
        activity_type: :tracking,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: 100.0,
        end_s: 170.0,
        score: 2.0
      },
      %{
        id: :provider_tracking_b,
        activity_type: :tracking,
        scenario_id: :leo_2,
        station_id: :equator_prime,
        start_s: 120.0,
        end_s: 180.0,
        score: 3.0
      }
    ]

    {annotated, report} = ContactContention.annotate_contacts(contacts)

    assert Enum.all?(annotated, &(&1["type"] == "tracking"))

    assert [
             %{
               "id" => "station:equator_prime:contention:1",
               "direction" => "tracking",
               "contact_ids" => ["provider_tracking_a", "provider_tracking_b"]
             }
           ] = report["conflict_groups"]

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes clean numeric-string timing aliases before contention review" do
    contacts = [
      %{
        id: :provider_string_a,
        activity_type: :downlink,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: "100.0",
        end_s: "170.0",
        score: "2.0"
      },
      %{
        id: :provider_string_b,
        direction: :downlink,
        scenario_id: :leo_2,
        ground_station: %{id: :equator_prime},
        starts_at_s: "120.0",
        ends_at_s: "180.0",
        score: "9.0"
      }
    ]

    {annotated, report} = ContactContention.annotate_contacts(contacts)

    assert Enum.map(annotated, &Map.take(&1, ["id", "starts_at_s", "ends_at_s"])) == [
             %{"id" => "provider_string_a", "starts_at_s" => 100.0, "ends_at_s" => 170.0},
             %{"id" => "provider_string_b", "starts_at_s" => 120.0, "ends_at_s" => 180.0}
           ]

    assert [
             %{
               "id" => "station:equator_prime:contention:1",
               "starts_at_s" => 100.0,
               "ends_at_s" => 180.0,
               "contact_ids" => ["provider_string_a", "provider_string_b"],
               "source_contact_candidates" => source_candidates
             }
           ] = report["conflict_groups"]

    assert Enum.map(source_candidates, & &1["score"]) == [2.0, 9.0]

    resolution = ContactContention.resolution_report(contacts, report)

    assert [
             %{
               "group_id" => "station:equator_prime:contention:1",
               "selected_contact_id" => "provider_string_b",
               "deferred_contact_ids" => ["provider_string_a"]
             }
           ] = resolution["recommendations"]

    review = OperatorReview.from_contact_contention_report(report)
    [review_row] = review["rows"]

    assert %{
             "starts_at_s" => 100.0,
             "ends_at_s" => 180.0,
             "contact_ids" => ["provider_string_a", "provider_string_b"]
           } = review_row

    manifest = CadenceImport.from_contact_contention_report(report)
    [import_row] = manifest["rows"]

    assert %{
             "starts_at_s" => 100.0,
             "ends_at_s" => 180.0,
             "contact_ids" => ["provider_string_a", "provider_string_b"]
           } = import_row

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)
  end

  test "normalizes provider direction aliases before contention grouping" do
    contacts = [
      %{
        id: :provider_command_a,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        direction: "commands",
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 1.0
      },
      %{
        id: :provider_command_b,
        scenario_id: :leo_2,
        station_id: :equator_prime,
        direction: "s-band command",
        starts_at_s: 120.0,
        ends_at_s: 180.0,
        score: 2.0
      }
    ]

    {annotated, report} = ContactContention.annotate_contacts(contacts)

    assert Enum.map(annotated, & &1["direction"]) == ["command", "command"]

    assert [
             %{
               "id" => "station:equator_prime:contention:1",
               "direction" => "command",
               "directions" => ["command"],
               "contact_ids" => ["provider_command_a", "provider_command_b"]
             }
           ] = report["conflict_groups"]

    resolution = ContactContention.resolution_report(contacts, report)

    assert [
             %{
               "group_id" => "station:equator_prime:contention:1",
               "direction" => "command",
               "selected_contact_id" => "provider_command_b",
               "deferred_contact_ids" => ["provider_command_a"]
             }
           ] = resolution["recommendations"]

    review = OperatorReview.from_contact_contention_report(report)
    [review_row] = review["rows"]

    assert %{
             "direction" => "command",
             "directions" => ["command"],
             "operator_action_reason" => "same_station_overlapping_contact_windows"
           } = review_row

    manifest = CadenceImport.from_contact_contention_report(report)
    [import_row] = manifest["rows"]

    assert %{
             "direction" => "command",
             "directions" => ["command"],
             "contact_ids" => ["provider_command_a", "provider_command_b"]
           } = import_row

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)
  end

  test "classifies contention groups and resolution recommendations with approval policy" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 2.0
      },
      %{
        id: :dl_2,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 160.0,
        score: 9.0
      }
    ]

    {_annotated, report} =
      ContactContention.annotate_contacts(contacts,
        approval_policy: %{policy_bundle_id: "contact_command_review_v1"}
      )

    assert [
             %{
               "approval_status" => "operator_review_required",
               "approval_requirements" => [
                 %{
                   "requirement_type" => "contact_schedule_change",
                   "policy_classification" => "operator_review_required"
                 }
               ],
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "contact_schedule_review",
                   "requirement_type" => "contact_schedule_change"
                 }
               ],
               "policy_decision" => %{
                 "schema_contract" => "policy_decision.v1",
                 "policy_bundle_id" => "contact_command_review_v1"
               }
             }
           ] = report["conflict_groups"]

    resolution =
      ContactContention.resolution_report(contacts, report,
        approval_policy: %{policy_bundle_id: "contact_command_review_v1"}
      )

    assert [
             %{
               "review_status" => "operator_review_required",
               "approval_requirements" => [
                 %{
                   "activity_type" => "contact_contention_resolution",
                   "requirement_type" => "contact_schedule_change",
                   "policy_classification" => "operator_review_required"
                 }
               ],
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "contact_schedule_review",
                   "requirement_type" => "contact_schedule_change"
                 }
               ],
               "policy_decision" => %{
                 "schema_contract" => "policy_decision.v1",
                 "policy_bundle_id" => "contact_command_review_v1"
               }
             }
           ] = resolution["recommendations"]

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    stale_candidate_count =
      put_in(resolution, ["recommendations", Access.at(0), "candidate_count"], 99)

    assert {:error, stale_candidate_count_report} =
             Schema.validate_artifact(stale_candidate_count)

    assert Enum.any?(
             stale_candidate_count_report["errors"],
             &(&1["path"] == "$.recommendations[0].candidate_count" and
                 &1["message"] == "must equal source_contact_candidates count")
           )

    stale_deferred_ids =
      put_in(resolution, ["recommendations", Access.at(0), "deferred_contact_ids"], [])

    assert {:error, stale_deferred_ids_report} =
             Schema.validate_artifact(stale_deferred_ids)

    assert Enum.any?(
             stale_deferred_ids_report["errors"],
             &(&1["path"] == "$.recommendations[0].candidate_count" and
                 &1["message"] == "must equal selected plus deferred contact count")
           )
  end

  test "carries contact feedback evidence into contention policy, review, and import rows" do
    contacts = [
      %{
        id: :dl_failed_feedback,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 170.0,
        score: 2.0,
        actual_data_rate_mbps: 8.0,
        actual_duration_s: 60.0,
        metadata: %{
          contact_success: " FALSE ",
          contact_result: %{
            outcome: :accepted,
            provider_status: :dropped
          },
          contact_success_factor: "0.25",
          contact_success_factor_source: :operational_feedback_contact_success,
          command_success: " False ",
          command_result: %{
            outcome: :accepted,
            status: :rejected
          },
          command_success_factor: "0.5",
          command_success_factor_source: :operational_feedback_command_success
        }
      },
      %{
        id: :dl_nominal,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 160.0,
        score: 9.0
      }
    ]

    {_annotated, report} =
      ContactContention.annotate_contacts(contacts,
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    throughput_derivation = %{
      "contact_id" => "dl_failed_feedback",
      "derivation" => "actual_data_rate_mbps * duration_s / 8",
      "rate_unit" => "Mbps",
      "actual_data_rate_mbps" => 8.0,
      "duration_s" => 60.0,
      "actual_throughput_mb" => 60.0
    }

    assert [
             %{
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "actual_throughput_mb" => 60.0,
               "actual_data_rate_throughput_derivations" => [^throughput_derivation],
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
                     "command_success_factor_source" => "operational_feedback_command_success",
                     "actual_throughput_mb" => 60.0,
                     "actual_data_rate_throughput_derivations" => [^throughput_derivation]
                   }
                 }
               ]
             } = group
           ] = report["conflict_groups"]

    assert Enum.any?(
             group["approval_rule_matches"],
             &(&1["rule_id"] == "failed_contact_success_review" and
                 &1["contact_success"] == false)
           )

    assert Enum.any?(
             group["approval_rule_matches"],
             &(&1["rule_id"] == "low_contact_success_confidence_review" and
                 &1["contact_success_factor"] == 0.25)
           )

    assert {:ok, %{"schema_contract" => "contact_contention_report.v1"}} =
             Schema.validate_artifact(report)

    resolution =
      ContactContention.resolution_report(contacts, report,
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert [
             %{
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "actual_throughput_mb" => 60.0,
               "actual_data_rate_throughput_derivations" => [^throughput_derivation],
               "source_contact_candidates" => source_contact_candidates,
               "approval_requirements" => [
                 %{
                   "activity_context" => %{
                     "contact_success" => false,
                     "contact_result" => "accepted,dropped",
                     "contact_success_factor" => 0.25,
                     "command_success" => false,
                     "command_success_factor" => 0.5,
                     "actual_throughput_mb" => 60.0,
                     "actual_data_rate_throughput_derivations" => [^throughput_derivation]
                   }
                 }
               ]
             } = recommendation
           ] = resolution["recommendations"]

    assert Enum.any?(source_contact_candidates, &(&1["id"] == "dl_failed_feedback"))

    assert Enum.any?(
             recommendation["approval_rule_matches"],
             &(&1["rule_id"] == "failed_contact_success_review" and
                 &1["contact_success"] == false)
           )

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             Schema.validate_artifact(resolution)

    review = OperatorReview.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "review_type" => "contact_contention_recommendation",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "actual_throughput_mb" => 60.0,
               "actual_data_rate_throughput_derivations" => [^throughput_derivation],
               "source_recommendation" => %{
                 "source_contact_candidates" => ^source_contact_candidates
               }
             }
           ] = review["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    manifest = CadenceImport.from_contact_contention_resolution_report(resolution)

    assert [
             %{
               "import_action" => "review_contact_contention_resolution",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "actual_throughput_mb" => 60.0,
               "actual_data_rate_throughput_derivations" => [^throughput_derivation],
               "source_recommendation" => %{
                 "source_contact_candidates" => ^source_contact_candidates
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "supports earliest-start resolution policy and public facade" do
    contacts = [
      %{
        id: :late_high,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 190.0,
        score: 99.0
      },
      %{
        id: :early_low,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 160.0,
        score: 1.0
      }
    ]

    report = OrbitalDynamics.contact_contention_report(contacts)

    assert ContactContention.report(report) == report
    assert OrbitalDynamics.contact_contention_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert ContactContention.report(atom_keyed_report) == report
    assert OrbitalDynamics.contact_contention_report(atom_keyed_report) == report

    resolution =
      OrbitalDynamics.contact_contention_resolution_report(contacts, report,
        policy: %{selection_rule: :earliest_start_highest_score}
      )

    assert ContactContention.resolution_report(resolution) == resolution
    assert OrbitalDynamics.contact_contention_resolution_report(resolution) == resolution

    atom_keyed_resolution =
      Map.new(resolution, fn {key, value} -> {String.to_atom(key), value} end)

    assert ContactContention.resolution_report(atom_keyed_resolution) == resolution

    assert OrbitalDynamics.contact_contention_resolution_report(atom_keyed_resolution) ==
             resolution

    assert [
             %{
               "selected_contact_id" => "early_low",
               "deferred_contact_ids" => ["late_high"],
               "selection_reason" => "earliest_start_highest_score"
             }
           ] = resolution["recommendations"]
  end

  test "returns empty reports when contacts do not overlap" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 120.0
      },
      %{
        id: :dl_2,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 120.0,
        ends_at_s: 150.0
      }
    ]

    {annotated, report} = ContactContention.annotate_contacts(contacts)

    assert Enum.map(annotated, & &1["id"]) == ["dl_1", "dl_2"]
    refute Enum.any?(annotated, &Map.has_key?(&1, "contention_group_ids"))
    assert report["conflicted_contact_count"] == 0
    assert report["conflict_group_count"] == 0
    assert report["conflict_groups"] == []

    resolution = ContactContention.resolution_report(contacts, report)
    assert resolution["recommendation_count"] == 0
    assert resolution["recommendations"] == []
  end

  test "blocks contact candidates without stable IDs for review" do
    contacts = [
      %{
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        starts_at_s: 100.0,
        ends_at_s: 120.0
      },
      %{
        id: :dl_2,
        type: :downlink,
        scenario_id: :leo_2,
        ground_station_id: :equator_prime,
        starts_at_s: 110.0,
        ends_at_s: 130.0
      }
    ]

    {_annotated, report} = ContactContention.annotate_contacts(contacts)

    assert %{
             "input_contact_count" => 2,
             "conflict_group_count" => 0,
             "invalid_contact_input_count" => 1,
             "invalid_contact_input_ids" => ["missing_contact_id:1"],
             "invalid_contact_inputs" => [
               %{
                 "contact_id" => "missing_contact_id:1",
                 "invalid_contact_input_reason" => "missing_contact_id",
                 "source_contact_candidate" => %{"type" => "downlink"}
               }
             ]
           } = report
  end

  defp contact_contention_identity_projection(contacts) do
    {_annotated, report} = ContactContention.annotate_contacts(contacts)
    resolution = ContactContention.resolution_report(contacts, report)

    %{
      groups:
        Enum.map(report["conflict_groups"], fn group ->
          group
          |> Map.take([
            "id",
            "resource_scope",
            "ground_station_id",
            "spacecraft_id",
            "starts_at_s",
            "ends_at_s",
            "contact_ids",
            "duplicate_contact_ids",
            "source_window_ids"
          ])
          |> Map.put(
            :source_window_ids,
            Enum.map(group["source_contact_candidates"], & &1["source_window_id"])
          )
        end),
      recommendations:
        Enum.map(resolution["recommendations"], fn recommendation ->
          recommendation
          |> Map.take([
            "group_id",
            "resource_scope",
            "ground_station_id",
            "spacecraft_id",
            "starts_at_s",
            "ends_at_s",
            "selected_contact_id",
            "deferred_contact_ids",
            "duplicate_contact_ids",
            "resolution_status",
            "resolution_issue"
          ])
          |> Map.put(
            :source_window_ids,
            Enum.map(recommendation["source_contact_candidates"], & &1["source_window_id"])
          )
          |> Map.put(
            :duplicate_source_window_ids,
            recommendation
            |> Map.get("duplicate_contact_candidates", [])
            |> Enum.map(& &1["source_window_id"])
          )
        end)
    }
  end
end
