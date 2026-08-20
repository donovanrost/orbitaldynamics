defmodule OrbitalDynamics.Communications.LinkCapacityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Communications.LinkCapacity

  test "declares link capacity capabilities" do
    assert %{
             artifact_contract: "link_capacity_report.v1",
             summary_artifact_contract: "link_capacity_summary.v1",
             relay_data_path_summary_artifact_contract: "relay_data_path_summary.v1",
             validation_level: :artifact_contract,
             model: :fixed_rate_downlink_capacity_summary,
             station_unavailable_aliases: station_unavailable_aliases,
             station_availability_precedence: station_availability_precedence,
             station_capacity_fraction_paths: station_capacity_fraction_paths,
             station_capacity_percent_paths: station_capacity_percent_paths,
             station_capacity_value_paths: station_capacity_value_paths,
             source_station_capacity_fraction_paths: source_station_capacity_fraction_paths,
             source_station_capacity_percent_paths: source_station_capacity_percent_paths,
             source_station_capacity_value_paths: source_station_capacity_value_paths,
             required_downlink_policy_paths: required_downlink_policy_paths,
             contact_required_downlink_paths: contact_required_downlink_paths,
             downlink_completion_source_paths: downlink_completion_source_paths,
             downlink_completion_sources_paths: downlink_completion_sources_paths,
             actual_throughput_fields: actual_throughput_fields,
             actual_throughput_model_paths: actual_throughput_model_paths,
             actual_data_rate_fields: actual_data_rate_fields,
             actual_duration_fields: actual_duration_fields,
             actual_completion_fraction_paths: actual_completion_fraction_paths,
             provider_direction_aliases: provider_direction_aliases,
             provider_result_map_value_keys: provider_result_map_value_keys,
             contact_stable_identity_fields: contact_stable_identity_fields,
             relay_data_path_generated_id_scope: relay_data_path_generated_id_scope,
             relay_data_path_statuses: relay_data_path_statuses,
             relay_data_path_model_limits: relay_data_path_model_limits,
             public_facades: public_facades,
             row_semantics: row_semantics,
             known_limits: known_limits
           } = LinkCapacity.capabilities()

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
    assert ["throughput_model", "availability"] in station_capacity_fraction_paths
    assert ["throughput_model", "station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["throughput_model", "capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_model", "availability"] in station_capacity_fraction_paths
    assert ["capacity_model", "station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["activity_context", "availability"] in station_capacity_fraction_paths
    assert ["activity_context", "capacity_fraction"] in station_capacity_fraction_paths
    assert ["station_capacity_fraction"] in station_capacity_fraction_paths
    assert ["capacity_fraction"] in station_capacity_fraction_paths

    assert ["throughput_model", "station_capacity_percent"] in station_capacity_percent_paths
    assert ["throughput_model", "capacity_percent"] in station_capacity_percent_paths
    assert ["capacity_model", "station_capacity_percent"] in station_capacity_percent_paths
    assert ["activity_context", "capacity_percent"] in station_capacity_percent_paths
    assert ["station_capacity_percent"] in station_capacity_percent_paths
    assert ["capacity_percent"] in station_capacity_percent_paths

    assert %{unit: :fraction, path: ["availability"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_pack_capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["throughput_model", "availability"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["throughput_model", "station_capacity_fraction"]} in station_capacity_value_paths

    assert %{unit: :percent, path: ["throughput_model", "capacity_percent"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_model", "availability"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["activity_context", "availability"]} in station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_fraction"]} in station_capacity_value_paths
    assert %{unit: :percent, path: ["capacity_percent"]} in station_capacity_value_paths

    assert ["availability"] in source_station_capacity_fraction_paths
    assert ["capacity_pack_capacity_fraction"] in source_station_capacity_fraction_paths
    assert ["station_capacity_fraction"] in source_station_capacity_fraction_paths
    assert ["capacity_fraction"] in source_station_capacity_fraction_paths
    assert ["capacity_percent"] in source_station_capacity_percent_paths
    assert ["station_capacity_percent"] in source_station_capacity_percent_paths

    assert %{unit: :fraction, path: ["availability"]} in source_station_capacity_value_paths

    assert %{unit: :fraction, path: ["capacity_pack_capacity_fraction"]} in source_station_capacity_value_paths
    assert %{unit: :fraction, path: ["capacity_fraction"]} in source_station_capacity_value_paths
    assert %{unit: :percent, path: ["capacity_percent"]} in source_station_capacity_value_paths

    assert required_downlink_policy_paths == [
             ["required_downlink_mb"],
             ["required_downlink_mb_by_ground_station"]
           ]

    assert contact_required_downlink_paths == [
             ["required_downlink_mb"],
             ["metadata", "required_downlink_mb"],
             ["throughput_model", "required_downlink_mb"]
           ]

    assert ["downlink_completion_source"] in downlink_completion_source_paths
    assert ["metadata", "downlink_completion_source"] in downlink_completion_source_paths
    assert ["throughput_model", "downlink_completion_source"] in downlink_completion_source_paths
    assert ["activity_context", "downlink_completion_source"] in downlink_completion_source_paths

    assert ["downlink_completion_sources"] in downlink_completion_sources_paths
    assert ["metadata", "downlink_completion_sources"] in downlink_completion_sources_paths

    assert ["throughput_model", "downlink_completion_sources"] in downlink_completion_sources_paths

    assert ["activity_context", "downlink_completion_sources"] in downlink_completion_sources_paths

    assert actual_throughput_fields == [
             "actual_throughput_mb",
             "actual_downlink_mb",
             "actual_data_volume_mb",
             "delivered_data_mb",
             "received_data_mb"
           ]

    assert actual_throughput_model_paths == [
             ["throughput_model", "actual_throughput_mb"],
             ["throughput_model", "actual_downlink_mb"],
             ["throughput_model", "actual_data_volume_mb"],
             ["throughput_model", "delivered_data_mb"],
             ["throughput_model", "received_data_mb"]
           ]

    assert actual_data_rate_fields == [
             "actual_data_rate_mb_s",
             "actual_downlink_rate_mb_s",
             "delivered_rate_mb_s",
             "received_rate_mb_s",
             "actual_data_rate_mbps",
             "actual_downlink_rate_mbps",
             "delivered_rate_mbps",
             "received_rate_mbps"
           ]

    assert actual_duration_fields == ["actual_duration_s", "actual_contact_duration_s"]

    assert actual_completion_fraction_paths == [
             ["completed_fraction"],
             ["completion_fraction"],
             ["contact_completion_fraction"],
             ["throughput_model", "completed_fraction"],
             ["throughput_model", "completion_fraction"],
             ["throughput_model", "contact_completion_fraction"]
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

    assert contact_stable_identity_fields == [
             "scenario_id",
             "spacecraft_id",
             "satellite_id",
             "ground_station_id"
           ]

    assert :invalid_contact_input_review in row_semantics
    assert :feedback_unit_interval_input_validation in row_semantics
    assert :contact_stable_identity_fields in row_semantics
    assert :status_aware_contact_capacity_effects in row_semantics
    assert :link_capacity_triage_summary in row_semantics
    assert :link_capacity_summary_station_count in row_semantics
    assert :link_capacity_summary_contact_count in row_semantics
    assert :link_capacity_summary_effective_contact_count in row_semantics
    assert :link_capacity_summary_ignored_contact_count in row_semantics
    assert :link_capacity_summary_selected_contact_count in row_semantics
    assert :link_capacity_summary_ignored_selected_contact_count in row_semantics
    assert :link_capacity_summary_required_downlink_contact_count in row_semantics
    assert :link_capacity_summary_actual_throughput_contact_count in row_semantics
    assert :link_capacity_summary_actual_completion_contact_count in row_semantics
    assert :link_capacity_summary_invalid_contact_input_count in row_semantics
    assert :link_capacity_summary_invalid_selected_contact_input_count in row_semantics
    assert :link_capacity_summary_invalid_policy_required_downlink_station_count in row_semantics
    assert :link_capacity_summary_routing_id_sets in row_semantics
    assert :link_capacity_summary_actual_completion_station_routing in row_semantics
    assert :link_capacity_summary_unresolved_actual_station_routing in row_semantics
    assert :link_capacity_summary_station_reservation_context in row_semantics
    assert :link_capacity_summary_station_reservation_owner_status_routing in row_semantics
    assert :link_capacity_summary_capacity_adjusted_throughput_routing in row_semantics
    assert :link_capacity_summary_station_calendar_provider_routing in row_semantics
    assert :station_calendar_reservation_expiration_context in row_semantics
    assert :status_ignored_reason_counts in row_semantics
    assert :ignored_contact_reason_counts in row_semantics
    assert :ignored_selected_contact_reason_counts in row_semantics
    assert :station_capacity_value_paths in row_semantics
    assert :station_calendar_direction_capacity_context in row_semantics
    assert :per_contact_downlink_requirement in row_semantics
    assert :downlink_completion_source_lineage in row_semantics
    assert :invalid_policy_required_downlink_station_requirement in row_semantics
    assert :realized_selected_downlink_throughput in row_semantics
    assert :actual_throughput_aliases in row_semantics
    assert :actual_data_rate_duration_aliases in row_semantics
    assert :unresolved_realized_selected_downlink_throughput in row_semantics
    assert :actual_downlink_shortfall in row_semantics
    assert :actual_downlink_completion_ratio in row_semantics
    assert :realized_selected_downlink_completion_fraction in row_semantics
    assert :actual_completion_fraction_aliases in row_semantics
    assert :unresolved_realized_selected_downlink_completion_fraction in row_semantics
    assert :data_volume_alias_capacity_summary in row_semantics
    assert :duration_data_rate_capacity_summary in row_semantics
    assert :realized_data_rate_capacity_summary in row_semantics
    assert :provider_direction_aliases in row_semantics
    assert :provider_result_map_value_keys in row_semantics
    assert :link_capacity_summary_row_derived_counts in row_semantics
    assert :link_capacity_row_count_list_consistency in row_semantics
    assert :artifact_only_relay_data_path_summary in row_semantics
    assert :relay_data_path_row_derived_counts in row_semantics
    assert :relay_data_path_custody_latency_risk_routing in row_semantics
    assert :relay_data_path_generated_route_id_invariant in row_semantics

    assert relay_data_path_generated_id_scope == %{
             scope: "relay_data_path_summary.v1.rows.generated_route_id",
             generated_id_field: "route_id",
             explicit_id_fields: ["route_id", "id", "data_path_id"],
             readable_prefix_fields: ["source_spacecraft_id", "ground_downlink_contact_id"],
             fingerprint_fields: [
               "source_spacecraft_id",
               "relay_chain_spacecraft_ids",
               "ground_station_id",
               "ground_downlink_contact_id",
               "latency_s",
               "latency_limit_s",
               "product_ids",
               "collection_ids"
             ],
             semantic_invariants: [
               "source_record_order_must_not_change_generated_route_id",
               "semantic_route_evidence_changes_must_change_generated_route_id",
               "explicit_route_id_takes_precedence_over_generated_route_id"
             ]
           }

    assert relay_data_path_statuses == %{
             custody: ["confirmed", "pending", "missing_ack", "failed", "unknown"],
             latency: ["within_limit", "exceeds_limit", "not_evaluated", "unknown"],
             risk: ["nominal", "review", "high", "unknown"]
           }

    assert relay_data_path_model_limits == [
             "artifact_level_relay_data_path_summary",
             "no_crosslink_visibility_model",
             "no_relay_scheduling",
             "no_custody_acknowledgement_delivery",
             "no_provider_reservation",
             "no_schedule_mutation"
           ]

    assert :link_capacity_report in public_facades
    assert :link_capacity_summary in public_facades
    assert :relay_data_path_summary in public_facades

    assert :fixed_rate_summary in known_limits
    assert :no_link_budget_model in known_limits
    assert :limited_realized_selected_throughput_reconciliation in known_limits
    assert :limited_realized_selected_completion_fraction_reconciliation in known_limits
    assert :no_full_realized_contact_reconciliation in known_limits
    assert :no_provider_reservation in known_limits
    assert :no_schedule_mutation in known_limits
  end

  test "builds artifact-only relay data-path summaries" do
    routes = [
      %{
        source_spacecraft_id: :sat_a,
        relay_chain_spacecraft_ids: [:relay_2, :relay_1],
        ground_station_id: :dss_14,
        ground_downlink_contact_id: :downlink_1,
        custody_status: :acknowledged,
        latency_s: "180",
        latency_limit_s: 240,
        product_ids: [:image_alpha],
        collection_id: :collection_alpha
      },
      %{
        id: :route_direct,
        source: %{spacecraft_id: :sat_b},
        ground_downlink: %{station_id: :dss_35, id: :downlink_2},
        custody: %{status: "missing acknowledgement"},
        delivery_latency_s: 500,
        max_latency_s: 300,
        risk_reasons: ["operator review queued"],
        product_id: :image_beta
      }
    ]

    summary = LinkCapacity.relay_data_path_summary(routes, source: "relay_ops")

    assert %{"route_ids" => [relay_route_id, "route_direct"]} = summary
    assert String.starts_with?(relay_route_id, "relay_data_path:sat_a:downlink_1:")
    assert relay_route_id =~ ~r/^relay_data_path:sat_a:downlink_1:[0-9a-f]{12}$/

    reordered_summary =
      LinkCapacity.relay_data_path_summary(
        [
          %{
            id: :route_inserted,
            source_spacecraft_id: :sat_inserted,
            ground_station_id: :dss_99,
            ground_downlink_contact_id: :downlink_inserted
          }
          | Enum.reverse(routes)
        ],
        source: "relay_ops"
      )

    assert reordered_summary["rows"]
           |> Enum.find(&(&1["source_spacecraft_id"] == "sat_a"))
           |> Map.fetch!("route_id") == relay_route_id

    changed_semantic_summary =
      routes
      |> update_in([Access.at(0), :latency_limit_s], fn _limit -> 360 end)
      |> LinkCapacity.relay_data_path_summary(source: "relay_ops")

    refute changed_semantic_summary["rows"]
           |> Enum.find(&(&1["source_spacecraft_id"] == "sat_a"))
           |> Map.fetch!("route_id") == relay_route_id

    explicit_id_summary =
      routes
      |> update_in([Access.at(1), :delivery_latency_s], fn _latency -> 900 end)
      |> LinkCapacity.relay_data_path_summary(source: "relay_ops")

    assert explicit_id_summary["rows"]
           |> Enum.find(&(&1["source_spacecraft_id"] == "sat_b"))
           |> Map.fetch!("route_id") == "route_direct"

    assert %{
             "schema_contract" => "relay_data_path_summary.v1",
             "schema_version" => 1,
             "model" => "artifact_only_relay_data_path_summary",
             "source" => "relay_ops",
             "route_count" => 2,
             "relay_route_count" => 1,
             "direct_downlink_route_count" => 1,
             "custody_status_counts" => %{"confirmed" => 1, "missing_ack" => 1},
             "latency_status_counts" => %{"exceeds_limit" => 1, "within_limit" => 1},
             "risk_status_counts" => %{"high" => 1, "nominal" => 1},
             "route_ids" => [
               ^relay_route_id,
               "route_direct"
             ],
             "source_spacecraft_ids" => ["sat_a", "sat_b"],
             "relay_spacecraft_ids" => ["relay_1", "relay_2"],
             "ground_station_ids" => ["dss_14", "dss_35"],
             "ground_downlink_contact_ids" => ["downlink_1", "downlink_2"],
             "route_ids_by_custody_status" => %{
               "confirmed" => [^relay_route_id],
               "missing_ack" => ["route_direct"]
             },
             "route_ids_by_latency_status" => %{
               "exceeds_limit" => ["route_direct"],
               "within_limit" => [^relay_route_id]
             },
             "route_ids_by_risk_status" => %{
               "high" => ["route_direct"],
               "nominal" => [^relay_route_id]
             },
             "route_ids_by_ground_station_id" => %{
               "dss_14" => [^relay_route_id],
               "dss_35" => ["route_direct"]
             },
             "maximum_latency_s" => 500.0,
             "maximum_latency_limit_s" => 300.0,
             "model_limits" => model_limits,
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
               "crosslink_visibility_model" => "not_evaluated",
               "custody_acknowledgement_delivery" => "not_performed",
               "provider_reservation" => "not_performed",
               "operator_authority" => "not_granted_by_summary"
             },
             "rows" => [
               %{
                 "route_id" => ^relay_route_id,
                 "source_spacecraft_id" => "sat_a",
                 "relay_chain_spacecraft_ids" => ["relay_2", "relay_1"],
                 "relay_hop_count" => 2,
                 "ground_station_id" => "dss_14",
                 "ground_downlink_contact_id" => "downlink_1",
                 "custody_status" => "confirmed",
                 "latency_s" => 180.0,
                 "latency_limit_s" => 240.0,
                 "latency_status" => "within_limit",
                 "risk_status" => "nominal",
                 "risk_reasons" => [],
                 "product_ids" => ["image_alpha"],
                 "collection_ids" => ["collection_alpha"]
               },
               %{
                 "route_id" => "route_direct",
                 "source_spacecraft_id" => "sat_b",
                 "relay_chain_spacecraft_ids" => [],
                 "relay_hop_count" => 0,
                 "ground_station_id" => "dss_35",
                 "ground_downlink_contact_id" => "downlink_2",
                 "custody_status" => "missing_ack",
                 "latency_s" => 500.0,
                 "latency_limit_s" => 300.0,
                 "latency_status" => "exceeds_limit",
                 "risk_status" => "high",
                 "risk_reasons" => [
                   "custody_missing_ack",
                   "latency_exceeds_limit",
                   "operator review queued"
                 ],
                 "product_ids" => ["image_beta"],
                 "collection_ids" => []
               }
             ]
           } = summary

    assert model_limits == LinkCapacity.capabilities().relay_data_path_model_limits
    assert OrbitalDynamics.relay_data_path_summary(routes, source: "relay_ops") == summary
    assert LinkCapacity.relay_data_path_summary(summary) == summary
    assert read_json!("study_results/relay_data_path_summary_v1.json") == summary

    assert {:ok, %{"schema_contract" => "relay_data_path_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert {:ok, schema} = Schema.json_schema("relay_data_path_summary.v1")

    assert get_in(schema, ["properties", "model", "const"]) ==
             "artifact_only_relay_data_path_summary"

    assert get_in(schema, ["properties", "model_limits", "const"]) == model_limits

    assert get_in(schema, ["properties", "assumptions", "required"]) == [
             "execution_boundary",
             "crosslink_visibility_model",
             "custody_acknowledgement_delivery",
             "provider_reservation",
             "operator_authority"
           ]

    assert get_in(schema, [
             "properties",
             "assumptions",
             "properties",
             "provider_reservation",
             "const"
           ]) == "not_performed"

    stale_route_count = Map.put(summary, "route_count", 99)

    assert {:error, stale_route_count_report} = Schema.validate_artifact(stale_route_count)

    assert Enum.any?(
             stale_route_count_report["errors"],
             &(&1["path"] == "$.route_count" and &1["message"] == "must equal 2")
           )

    stale_route_map =
      Map.put(summary, "route_ids_by_latency_status", %{"within_limit" => ["route_direct"]})

    assert {:error, stale_route_map_report} = Schema.validate_artifact(stale_route_map)

    assert Enum.any?(
             stale_route_map_report["errors"],
             &(&1["path"] == "$.route_ids_by_latency_status" and
                 &1["message"] == "must equal row-derived route_ids_by_latency_status")
           )

    malformed_route_id = put_in(summary, ["rows", Access.at(0), "route_id"], "bad route id")

    assert {:error, malformed_route_id_report} = Schema.validate_artifact(malformed_route_id)

    assert Enum.any?(
             malformed_route_id_report["errors"],
             &(&1["path"] == "$.rows[0].route_id" and &1["message"] =~ "stable ID")
           )

    forged_provider_reservation =
      put_in(summary, ["assumptions", "provider_reservation"], "reserved")

    assert {:error, forged_provider_reservation_report} =
             Schema.validate_artifact(forged_provider_reservation)

    assert Enum.any?(
             forged_provider_reservation_report["errors"],
             &(&1["path"] == "$.assumptions.provider_reservation" and
                 &1["message"] == "must equal \"not_performed\"")
           )

    assert_raise ArgumentError, ~r/relay data path routes must be a list/, fn ->
      LinkCapacity.relay_data_path_summary(:not_routes)
    end
  end

  test "counts planned and actual data-volume aliases as downlink capacity evidence" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :science_downlink,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            planned_data_volume_mb: 120.0
          }
        ],
        [
          %{
            id: :science_downlink,
            type: :downlink,
            ground_station_id: :equator_prime,
            actual_data_volume_mb: 90.0
          }
        ],
        policy: %{required_downlink_mb_by_ground_station: %{equator_prime: 100.0}},
        source: "timeline_feedback"
      )

    assert %{
             "estimated_throughput_mb" => 120.0,
             "selected_estimated_throughput_mb" => 120.0,
             "actual_throughput_mb" => 90.0,
             "actual_downlink_shortfall_mb" => 10.0,
             "actual_downlink_completion_ratio" => 0.9,
             "actual_downlink_requirement_status" => "shortfall",
             "actual_throughput_contact_ids" => ["science_downlink"],
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "estimated_throughput_mb" => 120.0,
                 "selected_estimated_throughput_mb" => 120.0,
                 "actual_throughput_mb" => 90.0,
                 "actual_downlink_shortfall_mb" => 10.0,
                 "actual_downlink_completion_ratio" => 0.9,
                 "actual_downlink_requirement_status" => "shortfall",
                 "actual_throughput_contact_ids" => ["science_downlink"]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    expected_capability_assumptions = link_capacity_capability_assumptions()

    expected_station_unavailable_aliases =
      expected_capability_assumptions["station_unavailable_aliases"]

    expected_station_availability_precedence =
      expected_capability_assumptions["station_availability_precedence"]

    expected_station_capacity_value_paths =
      expected_capability_assumptions["station_capacity_value_paths"]

    expected_source_station_capacity_value_paths =
      expected_capability_assumptions["source_station_capacity_value_paths"]

    expected_provider_direction_aliases =
      expected_capability_assumptions["provider_direction_aliases"]

    assert %{
             "schema_contract" => "link_capacity_summary.v1",
             "model" => "artifact_only_link_capacity_summary",
             "source_artifact_type" => "link_capacity_report.v1",
             "source" => "timeline_feedback",
             "model_limits" => summary_model_limits,
             "station_count" => 1,
             "contact_count" => 1,
             "effective_contact_count" => 1,
             "ignored_contact_count" => 0,
             "selected_contact_count" => 1,
             "ignored_selected_contact_count" => 0,
             "required_downlink_contact_count" => 0,
             "actual_throughput_contact_count" => 1,
             "actual_completion_contact_count" => 0,
             "invalid_contact_input_count" => 0,
             "invalid_selected_contact_input_count" => 0,
             "invalid_policy_required_downlink_station_count" => 0,
             "downlink_requirement_status" => "satisfied",
             "actual_downlink_requirement_status" => "shortfall",
             "selected_downlink_shortfall_mb" => +0.0,
             "actual_downlink_shortfall_mb" => 10.0,
             "capacity_adjusted_throughput_mb" => 120.0,
             "selected_capacity_adjusted_throughput_mb" => 120.0,
             "unused_capacity_adjusted_throughput_mb" => +0.0,
             "contact_ids" => ["science_downlink"],
             "selected_contact_ids" => ["science_downlink"],
             "ignored_contact_ids" => [],
             "ignored_selected_contact_ids" => [],
             "required_downlink_contact_ids" => [],
             "actual_throughput_contact_ids" => ["science_downlink"],
             "actual_completion_contact_ids" => [],
             "ground_station_ids" => ["equator_prime"],
             "shortfall_ground_station_ids" => [],
             "actual_shortfall_ground_station_ids" => ["equator_prime"],
             "selected_downlink_shortfall_mb_by_ground_station_id" => %{
               "equator_prime" => +0.0
             },
             "actual_downlink_shortfall_mb_by_ground_station_id" => %{
               "equator_prime" => 10.0
             },
             "selected_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["science_downlink"]
             },
             "capacity_adjusted_throughput_mb_by_ground_station_id" => %{
               "equator_prime" => 120.0
             },
             "selected_capacity_adjusted_throughput_mb_by_ground_station_id" => %{
               "equator_prime" => 120.0
             },
             "unused_capacity_adjusted_throughput_mb_by_ground_station_id" => %{
               "equator_prime" => +0.0
             },
             "actual_throughput_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["science_downlink"]
             },
             "actual_completion_contact_ids_by_ground_station_id" => %{},
             "assumptions" => %{
               "execution_boundary" =>
                 "artifact_only_no_provider_reservation_or_schedule_mutation",
               "source" => "link_capacity_report.v1",
               "operator_authority" => "not_granted_by_summary",
               "station_unavailable_aliases" => ^expected_station_unavailable_aliases,
               "station_availability_precedence" => ^expected_station_availability_precedence,
               "station_capacity_value_paths" => ^expected_station_capacity_value_paths,
               "source_station_capacity_value_paths" =>
                 ^expected_source_station_capacity_value_paths,
               "provider_direction_aliases" => ^expected_provider_direction_aliases
             }
           } = summary = LinkCapacity.summary(report)

    assert OrbitalDynamics.link_capacity_summary(report) == summary
    assert read_json!("study_results/link_capacity_summary_v1.json") == summary

    expected_model_limits =
      LinkCapacity.capabilities()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&to_string/1)

    assert summary_model_limits == expected_model_limits

    assert {:ok, %{"schema_contract" => "link_capacity_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert {:ok, link_capacity_summary_schema} = Schema.json_schema("link_capacity_summary.v1")

    assert get_in(link_capacity_summary_schema, ["properties", "model", "const"]) ==
             "artifact_only_link_capacity_summary"

    assert get_in(link_capacity_summary_schema, ["properties", "model_limits", "const"]) ==
             expected_model_limits

    assert get_in(link_capacity_summary_schema, [
             "properties",
             "model_limits",
             "items",
             "enum"
           ]) == expected_model_limits

    assert get_in(link_capacity_summary_schema, [
             "properties",
             "assumptions",
             "properties",
             "station_capacity_value_paths",
             "const"
           ]) == expected_capability_assumptions["station_capacity_value_paths"]

    assert get_in(link_capacity_summary_schema, [
             "properties",
             "assumptions",
             "properties",
             "provider_direction_aliases",
             "const"
           ]) == expected_capability_assumptions["provider_direction_aliases"]

    stale_summary_provider_direction_aliases =
      put_in(summary, ["assumptions", "provider_direction_aliases"], %{"dl" => "command"})

    assert {:error, stale_summary_provider_direction_aliases_report} =
             Schema.validate_artifact(stale_summary_provider_direction_aliases)

    assert Enum.any?(
             stale_summary_provider_direction_aliases_report["errors"],
             &(&1["path"] == "$.assumptions.provider_direction_aliases" and
                 &1["message"] == "must match LinkCapacity provider direction aliases")
           )

    summary_without_optional_capability_assumptions =
      drop_link_capacity_capability_assumptions(summary)

    assert {:ok, %{"schema_contract" => "link_capacity_summary.v1"}} =
             Schema.validate_artifact(summary_without_optional_capability_assumptions)

    stale_summary_model_limits = Map.put(summary, "model_limits", ["artifact_level_only"])

    assert {:error, stale_summary_model_limits_report} =
             Schema.validate_artifact(stale_summary_model_limits)

    assert Enum.any?(
             stale_summary_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match link capacity capability model limits")
           )

    stale_summary_model = Map.put(summary, "model", "stale_link_capacity_summary")

    assert {:error, stale_summary_model_report} = Schema.validate_artifact(stale_summary_model)

    assert Enum.any?(
             stale_summary_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] == "must equal \"artifact_only_link_capacity_summary\"")
           )

    stale_summary_count = Map.put(summary, "actual_throughput_contact_count", 99)

    assert {:error, stale_summary_count_report} = Schema.validate_artifact(stale_summary_count)

    assert Enum.any?(
             stale_summary_count_report["errors"],
             &match?(
               %{
                 "path" => "$.actual_throughput_contact_count",
                 "message" => "must equal actual_throughput_contact_ids count"
               },
               &1
             )
           )

    stale_summary_total = Map.put(summary, "capacity_adjusted_throughput_mb", 99.0)

    assert {:error, stale_summary_total_report} = Schema.validate_artifact(stale_summary_total)

    assert Enum.any?(
             stale_summary_total_report["errors"],
             &match?(
               %{
                 "path" => "$.capacity_adjusted_throughput_mb",
                 "message" =>
                   "must equal capacity_adjusted_throughput_mb_by_ground_station_id total"
               },
               &1
             )
           )

    stale_id_report =
      Map.merge(report, %{
        "required_downlink_contact_ids" => ["stale_required"],
        "actual_throughput_contact_ids" => ["stale_actual"]
      })

    assert %{
             "required_downlink_contact_ids" => [],
             "actual_throughput_contact_ids" => ["science_downlink"]
           } = LinkCapacity.summary(stale_id_report)

    stale_count_report =
      Map.merge(report, %{
        "contact_count" => 99,
        "effective_contact_count" => 99,
        "ignored_contact_count" => 99,
        "selected_contact_count" => 99,
        "ignored_selected_contact_count" => 99,
        "required_downlink_contact_count" => 99,
        "actual_throughput_contact_count" => 99,
        "actual_completion_contact_count" => 99,
        "invalid_contact_input_count" => 99,
        "invalid_selected_contact_input_count" => 99,
        "invalid_policy_required_downlink_station_count" => 99
      })

    assert %{
             "contact_count" => 1,
             "effective_contact_count" => 1,
             "ignored_contact_count" => 0,
             "selected_contact_count" => 1,
             "ignored_selected_contact_count" => 0,
             "required_downlink_contact_count" => 0,
             "actual_throughput_contact_count" => 1,
             "actual_completion_contact_count" => 0,
             "invalid_contact_input_count" => 0,
             "invalid_selected_contact_input_count" => 0,
             "invalid_policy_required_downlink_station_count" => 0
           } = LinkCapacity.summary(stale_count_report)

    assert LinkCapacity.summary(summary) == summary
    assert OrbitalDynamics.link_capacity_summary(summary) == summary

    atom_keyed_summary =
      Map.new(summary, fn {key, value} -> {String.to_atom(key), value} end)

    assert LinkCapacity.summary(atom_keyed_summary) == summary
    assert OrbitalDynamics.link_capacity_summary(atom_keyed_summary) == summary

    assert OrbitalDynamics.link_capacity_summary(
             [
               %{
                 id: :science_downlink,
                 type: :downlink,
                 scenario_id: :leo_1,
                 ground_station_id: :equator_prime,
                 planned_data_volume_mb: 120.0
               }
             ],
             [
               %{
                 id: :science_downlink,
                 type: :downlink,
                 ground_station_id: :equator_prime,
                 actual_data_volume_mb: 90.0
               }
             ],
             policy: %{required_downlink_mb_by_ground_station: %{equator_prime: 100.0}},
             source: "timeline_feedback"
           ) == summary
  end

  test "accepts activity-type-only downlink rows for capacity summaries" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :provider_downlink,
            activity_type: :downlink,
            scenario_id: :leo_1,
            station_id: :equator_prime,
            estimated_throughput_mb: 100.0
          }
        ],
        [
          %{
            id: :provider_downlink,
            activity_type: :downlink,
            station_id: :equator_prime,
            actual_throughput_mb: 80.0
          }
        ],
        source: "provider.timeline_rows"
      )

    assert %{
             "contact_count" => 1,
             "selected_contact_count" => 1,
             "invalid_contact_input_count" => 0,
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "contact_ids" => ["provider_downlink"],
                 "selected_contact_ids" => ["provider_downlink"],
                 "estimated_throughput_mb" => 100.0,
                 "actual_throughput_mb" => 80.0
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "counts nested throughput-model estimates in capacity summaries" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :provider_downlink,
            activity_type: :downlink,
            scenario_id: :leo_1,
            station_id: :equator_prime,
            throughput_model: %{estimated_throughput_mb: 100.0},
            capacity_pack_capacity_fraction: 0.5
          }
        ],
        [
          %{
            id: :provider_downlink,
            activity_type: :downlink,
            station_id: :equator_prime,
            throughput_model: %{estimated_throughput_mb: 100.0},
            capacity_pack_capacity_fraction: 0.5
          }
        ],
        source: "provider.timeline_rows"
      )

    assert %{
             "contact_count" => 1,
             "selected_contact_count" => 1,
             "estimated_throughput_mb" => 100.0,
             "capacity_adjusted_throughput_mb" => 50.0,
             "selected_estimated_throughput_mb" => 100.0,
             "selected_capacity_adjusted_throughput_mb" => 50.0,
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "estimated_throughput_mb" => 100.0,
                 "capacity_adjusted_throughput_mb" => 50.0,
                 "selected_estimated_throughput_mb" => 100.0,
                 "selected_capacity_adjusted_throughput_mb" => 50.0
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "uses source station-calendar capacity-pack fractions in capacity summaries" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :source_entry_capacity,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0,
            source_station_calendar_entry: %{
              id: :provider_entry_capacity,
              capacity_pack_capacity_fraction: 0.25
            }
          },
          %{
            id: :source_overlap_capacity,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 80.0,
            source_station_calendar_overlaps: [
              %{
                id: :provider_overlap_capacity,
                capacity_pack_capacity_fraction: 0.5
              }
            ]
          }
        ],
        [],
        source: "source_station_calendar.capacity_pack"
      )

    assert %{
             "contact_count" => 2,
             "estimated_throughput_mb" => 180.0,
             "capacity_adjusted_throughput_mb" => 65.0,
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "contact_count" => 2,
                 "estimated_throughput_mb" => 180.0,
                 "capacity_adjusted_throughput_mb" => 65.0,
                 "capacity_fraction_min" => 0.25,
                 "capacity_fraction_max" => 0.5,
                 "contact_ids" => ["source_entry_capacity", "source_overlap_capacity"]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "uses numeric availability capacity aliases in capacity summaries" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :direct_availability_capacity,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0,
            availability: "0.25"
          },
          %{
            id: :source_entry_availability_capacity,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 80.0,
            source_station_calendar_entry: %{
              id: :provider_entry_availability,
              availability: 0.5
            }
          },
          %{
            id: :source_overlap_nested_availability_capacity,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 40.0,
            source_station_calendar_overlaps: [
              %{
                id: :provider_overlap_availability,
                capacity_model: %{"availability" => "0.75"}
              }
            ]
          }
        ],
        [],
        source: "source_station_calendar.availability_capacity"
      )

    assert %{
             "contact_count" => 3,
             "estimated_throughput_mb" => 220.0,
             "capacity_adjusted_throughput_mb" => 95.0,
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "contact_count" => 3,
                 "estimated_throughput_mb" => 220.0,
                 "capacity_adjusted_throughput_mb" => 95.0,
                 "capacity_fraction_min" => 0.25,
                 "capacity_fraction_max" => 0.75,
                 "contact_ids" => [
                   "direct_availability_capacity",
                   "source_entry_availability_capacity",
                   "source_overlap_nested_availability_capacity"
                 ]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "derives fixed-rate throughput from data rate and contact duration" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :explicit_rate,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 10.0,
            ends_at_s: 70.0,
            data_rate_mbps: 16.0
          },
          %{
            id: :nested_rate,
            activity_type: :downlink,
            scenario_id: :leo_1,
            station_id: :equator_prime,
            throughput_model: %{
              data_rate_mb_s: 1.5,
              duration_s: 40.0,
              station_capacity_fraction: 0.5
            }
          },
          %{
            id: :explicit_throughput_wins,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            starts_at_s: 0.0,
            ends_at_s: 100.0,
            estimated_throughput_mb: 30.0,
            data_rate_mbps: 800.0
          }
        ],
        [
          %{id: :explicit_rate, type: :downlink, ground_station_id: :equator_prime},
          %{id: :nested_rate, type: :downlink, ground_station_id: :equator_prime}
        ],
        source: "provider.data_rate"
      )

    assert %{
             "contact_count" => 3,
             "selected_contact_count" => 2,
             "estimated_throughput_mb" => 210.0,
             "selected_estimated_throughput_mb" => 180.0,
             "capacity_adjusted_throughput_mb" => 180.0,
             "selected_capacity_adjusted_throughput_mb" => 150.0,
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "estimated_throughput_mb" => 210.0,
                 "selected_estimated_throughput_mb" => 180.0,
                 "capacity_adjusted_throughput_mb" => 180.0,
                 "selected_capacity_adjusted_throughput_mb" => 150.0
               }
             ],
             "assumptions" => %{
               "data_rate_throughput_model" => data_rate_throughput_model
             }
           } = report

    assert data_rate_throughput_model =~ "data_rate_mbps"

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "derives realized selected throughput from actual data rate and duration" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :science_downlink,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0
          },
          %{
            id: :nested_actual_rate,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 50.0
          }
        ],
        [
          %{
            id: :science_downlink,
            type: :downlink,
            ground_station_id: :equator_prime,
            actual_data_rate_mbps: 8.0,
            actual_duration_s: 60.0
          },
          %{
            id: :nested_actual_rate,
            type: :downlink,
            ground_station_id: :equator_prime,
            throughput_model: %{
              actual_data_rate_mb_s: 0.5,
              actual_duration_s: 30.0
            }
          }
        ],
        policy: %{required_downlink_mb_by_ground_station: %{equator_prime: 80.0}},
        source: "provider.actual_data_rate"
      )

    expected_derivations = [
      %{
        "contact_id" => "nested_actual_rate",
        "derivation" => "actual_data_rate_mb_s * duration_s",
        "rate_unit" => "MB/s",
        "actual_data_rate_mb_s" => 0.5,
        "duration_s" => 30.0,
        "actual_throughput_mb" => 15.0
      },
      %{
        "contact_id" => "science_downlink",
        "derivation" => "actual_data_rate_mbps * duration_s / 8",
        "rate_unit" => "Mbps",
        "actual_data_rate_mbps" => 8.0,
        "duration_s" => 60.0,
        "actual_throughput_mb" => 60.0
      }
    ]

    assert %{
             "actual_throughput_mb" => 75.0,
             "actual_downlink_shortfall_mb" => 5.0,
             "actual_downlink_requirement_status" => "shortfall",
             "actual_throughput_contact_ids" => ["nested_actual_rate", "science_downlink"],
             "actual_data_rate_throughput_derivations" => ^expected_derivations,
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "actual_throughput_mb" => 75.0,
                 "actual_downlink_shortfall_mb" => 5.0,
                 "actual_downlink_requirement_status" => "shortfall",
                 "actual_throughput_contact_ids" => [
                   "nested_actual_rate",
                   "science_downlink"
                 ],
                 "actual_data_rate_throughput_derivations" => ^expected_derivations
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_link_capacity_report(report)

    assert [
             %{
               "actual_throughput_mb" => 75.0,
               "actual_data_rate_throughput_derivations" => ^expected_derivations
             }
           ] = review["rows"]

    manifest = CadenceImport.from_link_capacity_report(report)

    assert [
             %{
               "actual_throughput_mb" => 75.0,
               "actual_data_rate_throughput_derivations" => ^expected_derivations,
               "source_review_row" => %{
                 "actual_data_rate_throughput_derivations" => ^expected_derivations
               }
             }
           ] = manifest["rows"]
  end

  test "uses selected downlink rows for station ignored-selected reason counts" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :dl_1,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0
          }
        ],
        [
          %{
            id: :dl_1,
            type: :downlink,
            ground_station_id: :equator_prime,
            status: :completed,
            actual_throughput_mb: 90.0
          }
        ],
        source: "selected_feedback"
      )

    assert %{
             "selected_contact_count" => 0,
             "ignored_selected_contact_count" => 1,
             "ignored_selected_contact_ids" => ["dl_1"],
             "ignored_selected_contact_reason_counts" => %{
               "activity_status_completed" => 1
             },
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "contact_ids" => ["dl_1"],
                 "selected_contact_count" => 0,
                 "ignored_selected_contact_count" => 1,
                 "ignored_selected_contact_ids" => ["dl_1"],
                 "ignored_selected_contact_reason_counts" => %{
                   "activity_status_completed" => 1
                 }
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    mismatched_reason_counts =
      Map.put(report, "ignored_selected_contact_reason_counts", %{
        "activity_status_failed" => 1
      })

    assert {:error, reason_count_report} = Schema.validate_artifact(mismatched_reason_counts)

    assert Enum.any?(
             reason_count_report["errors"],
             &(&1["path"] == "$.ignored_selected_contact_reason_counts" and
                 &1["message"] ==
                   "must equal row-derived ignored_selected_contact_reason_counts")
           )

    negative_reason_count =
      put_in(report, ["ignored_selected_contact_reason_counts", "activity_status_completed"], -1)

    assert {:error, negative_reason_count_report} =
             Schema.validate_artifact(negative_reason_count)

    assert Enum.any?(
             negative_reason_count_report["errors"],
             &(&1["path"] ==
                 "$.ignored_selected_contact_reason_counts.activity_status_completed")
           )
  end

  test "clamps declared station capacity fractions before building capacity rows" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :over_capacity,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0,
            throughput_model: %{station_capacity_percent: 150}
          },
          %{
            id: :negative_capacity,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 50.0,
            capacity_percent: -25
          }
        ],
        [],
        source: "capacity_fraction_clamp"
      )

    assert %{
             "capacity_adjusted_throughput_mb" => 100.0,
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "capacity_adjusted_throughput_mb" => 100.0,
                 "capacity_fraction_min" => capacity_fraction_min,
                 "capacity_fraction_max" => 1.0
               }
             ]
           } = report

    assert capacity_fraction_min == 0.0

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "does not choose conflicting source station-calendar overlap capacity" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :ambiguous_capacity,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0,
            station_calendar_entry_ambiguous: true,
            source_station_calendar_overlaps: [
              %{id: :capacity_low, capacity_fraction: 0.25},
              %{id: :capacity_high, capacity_fraction: 0.75}
            ]
          }
        ],
        [],
        source: "source_station_calendar.ambiguous_capacity"
      )

    assert %{
             "capacity_adjusted_throughput_mb" => 100.0,
             "rows" => [
               %{
                 "capacity_adjusted_throughput_mb" => 100.0,
                 "capacity_fraction_min" => 1.0,
                 "capacity_fraction_max" => 1.0
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves invalid candidate and selected downlink inputs for review" do
    candidates = [
      %{
        id: :valid_dl,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0
      },
      %{
        id: :missing_station,
        type: :downlink,
        scenario_id: :leo_1,
        spacecraft: %{id: :sat_1},
        estimated_throughput_mb: 50.0
      },
      {:bad_candidate_shape, :not_a_map}
    ]

    selected = [
      %{id: :valid_dl, type: :downlink, ground_station_id: :equator_prime},
      %{type: :downlink, ground_station_id: :equator_prime, actual_throughput_mb: 10.0},
      {:bad_selected_shape, :not_a_map}
    ]

    report =
      LinkCapacity.report(candidates, selected,
        source: "invalid_test",
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "contact_count" => 1,
             "selected_contact_count" => 1,
             "invalid_contact_input_count" => 2,
             "invalid_contact_input_ids" => ["missing_contact_id:3", "missing_station"],
             "invalid_selected_contact_input_count" => 2,
             "invalid_selected_contact_input_ids" => [
               "missing_contact_id:2",
               "missing_contact_id:3"
             ],
             "invalid_contact_inputs" => invalid_candidate_inputs,
             "invalid_selected_contact_inputs" => invalid_selected_inputs
           } = report

    assert %{
             "invalid_contact_input_ids" => ["missing_contact_id:3", "missing_station"],
             "invalid_selected_contact_input_ids" => [
               "missing_contact_id:2",
               "missing_contact_id:3"
             ],
             "ground_station_ids" => ["equator_prime"],
             "contact_ids" => ["valid_dl"],
             "selected_contact_ids" => ["valid_dl"]
           } = LinkCapacity.summary(report)

    stale_invalid_id_report =
      report
      |> Map.put("invalid_contact_input_ids", ["stale_candidate"])
      |> Map.put("invalid_selected_contact_input_ids", ["stale_selected"])

    assert %{
             "invalid_contact_input_ids" => ["missing_contact_id:3", "missing_station"],
             "invalid_selected_contact_input_ids" => [
               "missing_contact_id:2",
               "missing_contact_id:3"
             ]
           } = LinkCapacity.summary(stale_invalid_id_report)

    assert %{
             "contact_id" => "missing_station",
             "input_role" => "candidate",
             "spacecraft_id" => "sat_1",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "missing_ground_station_id",
             "required_operator_action" => "review_invalid_link_capacity_input",
             "approval_status" => "operator_review_required",
             "approval_rule_matches" => [
               %{"rule_id" => "invalid_link_capacity_input_review"}
             ],
             "policy_decision" => %{"policy_bundle_id" => "ground_network_allocation_v1"},
             "source_contact_candidate" => %{"id" => "missing_station"}
           } = Enum.find(invalid_candidate_inputs, &(&1["contact_id"] == "missing_station"))

    assert %{
             "contact_id" => "missing_contact_id:2",
             "input_role" => "selected",
             "invalid_contact_input_reason" => "missing_contact_id"
           } = Enum.find(invalid_selected_inputs, &(&1["contact_id"] == "missing_contact_id:2"))

    assert %{
             "contact_id" => "missing_contact_id:3",
             "input_role" => "candidate",
             "invalid_contact_input_reason" => "invalid_contact_shape",
             "source_contact_candidate" => %{
               "invalid_contact_shape" => true,
               "raw_input" => "{:bad_candidate_shape, :not_a_map}"
             }
           } = Enum.find(invalid_candidate_inputs, &(&1["contact_id"] == "missing_contact_id:3"))

    assert %{
             "contact_id" => "missing_contact_id:3",
             "input_role" => "selected",
             "invalid_contact_input_reason" => "invalid_contact_shape",
             "source_contact_candidate" => %{
               "invalid_contact_shape" => true,
               "raw_input" => "{:bad_selected_shape, :not_a_map}"
             }
           } = Enum.find(invalid_selected_inputs, &(&1["contact_id"] == "missing_contact_id:3"))

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_link_capacity_report(report)
    review_row = Enum.find(review["rows"], &(&1["contact_id"] == "missing_station"))

    assert %{
             "review_type" => "link_capacity_review",
             "required_operator_action" => "review_invalid_link_capacity_input",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "missing_ground_station_id",
             "approval_rule_matches" => [
               %{"rule_id" => "invalid_link_capacity_input_review"}
             ],
             "source_policy_decision" => %{"policy_bundle_id" => "ground_network_allocation_v1"},
             "source_contact_candidate" => %{"id" => "missing_station"}
           } = review_row

    manifest = CadenceImport.from_link_capacity_report(report)
    import_row = Enum.find(manifest["rows"], &(&1["contact_id"] == "missing_station"))

    assert %{
             "import_action" => "review_link_capacity",
             "invalid_contact_input" => true,
             "invalid_contact_input_reason" => "missing_ground_station_id",
             "approval_rule_matches" => [
               %{"rule_id" => "invalid_link_capacity_input_review"}
             ],
             "source_policy_decision" => %{"policy_bundle_id" => "ground_network_allocation_v1"},
             "source_contact_candidate" => %{"id" => "missing_station"}
           } = import_row
  end

  test "review-gates out-of-range feedback and completion fractions" do
    candidates = [
      %{
        id: :valid_dl,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0
      },
      %{
        id: :invalid_feedback_dl,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 50.0,
        metadata: %{
          contact_success_factor: 1.4,
          command_success_factor: -0.25
        }
      }
    ]

    selected = [
      %{
        id: :valid_dl,
        type: :downlink,
        ground_station_id: :equator_prime,
        actual_throughput_mb: 80.0,
        completed_fraction: 0.8
      },
      %{
        id: :invalid_completion_dl,
        type: :downlink,
        ground_station_id: :equator_prime,
        actual_throughput_mb: 20.0,
        throughput_model: %{contact_completion_fraction: 1.2}
      }
    ]

    report =
      LinkCapacity.report(candidates, selected,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert report["contact_count"] == 1
    assert report["selected_contact_count"] == 1
    assert report["actual_completion_contact_ids"] == ["valid_dl"]
    assert_in_delta report["actual_completion_fraction"], 0.8, 1.0e-12

    assert [
             %{
               "contact_id" => "invalid_feedback_dl",
               "input_role" => "candidate",
               "invalid_contact_input" => true,
               "invalid_contact_input_reason" => "invalid_contact_success_factor",
               "source_contact_candidate" => %{
                 "metadata" => %{
                   "contact_success_factor" => 1.4,
                   "command_success_factor" => -0.25
                 }
               }
             }
           ] = report["invalid_contact_inputs"]

    assert [
             %{
               "contact_id" => "invalid_completion_dl",
               "input_role" => "selected",
               "invalid_contact_input" => true,
               "invalid_contact_input_reason" => "invalid_contact_completion_fraction",
               "source_contact_candidate" => %{
                 "throughput_model" => %{"contact_completion_fraction" => 1.2}
               }
             }
           ] = report["invalid_selected_contact_inputs"]

    review = OperatorReview.from_link_capacity_report(report)
    manifest = CadenceImport.from_link_capacity_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "invalid_feedback_dl" and
                 &1["invalid_contact_input_reason"] == "invalid_contact_success_factor")
           )

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "invalid_completion_dl" and
                 &1["invalid_contact_input_reason"] == "invalid_contact_completion_fraction")
           )

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "actual_completion_contact_ids" => ["valid_dl"],
             "actual_completion_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["valid_dl"]
             }
           } = LinkCapacity.summary(report)

    stale_actual_completion_summary_report =
      Map.put(report, "actual_completion_contact_ids", ["stale_completion"])

    assert %{
             "actual_completion_contact_ids" => ["valid_dl"],
             "actual_completion_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["valid_dl"]
             }
           } = LinkCapacity.summary(stale_actual_completion_summary_report)

    assert {:error, stale_actual_completion_report} =
             Schema.validate_artifact(stale_actual_completion_summary_report)

    assert Enum.any?(
             stale_actual_completion_report["errors"],
             &(&1["path"] == "$.actual_completion_contact_ids" and
                 &1["message"] == "must equal row-derived actual_completion_contact_ids")
           )

    stale_actual_completion_count_report = Map.put(report, "actual_completion_contact_count", 99)

    assert {:error, stale_actual_completion_count_errors} =
             Schema.validate_artifact(stale_actual_completion_count_report)

    assert Enum.any?(
             stale_actual_completion_count_errors["errors"],
             &(&1["path"] == "$.actual_completion_contact_count" and
                 &1["message"] == "must equal row-derived actual_completion_contact_count")
           )

    stale_actual_throughput_count_report = Map.put(report, "actual_throughput_contact_count", 99)

    assert {:error, stale_actual_throughput_count_errors} =
             Schema.validate_artifact(stale_actual_throughput_count_report)

    assert Enum.any?(
             stale_actual_throughput_count_errors["errors"],
             &(&1["path"] == "$.actual_throughput_contact_count" and
                 &1["message"] == "must equal row-derived actual_throughput_contact_count")
           )

    stale_row_actual_throughput_count_report =
      put_in(report, ["rows", Access.at(0), "actual_throughput_contact_count"], 99)

    assert {:error, stale_row_actual_throughput_count_errors} =
             Schema.validate_artifact(stale_row_actual_throughput_count_report)

    assert Enum.any?(
             stale_row_actual_throughput_count_errors["errors"],
             &(&1["path"] == "$.rows[0].actual_throughput_contact_count" and
                 &1["message"] == "must equal actual_throughput_contact_ids count")
           )
  end

  test "preserves malformed link capacity identity fields for review" do
    candidates = [
      %{
        id: "bad contact id",
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0
      },
      %{
        id: :bad_station,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: "bad station id",
        estimated_throughput_mb: 50.0
      },
      %{
        id: :bad_scenario,
        type: :downlink,
        scenario_id: "bad scenario id",
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 25.0
      }
    ]

    selected = [
      %{
        id: "bad selected contact id",
        type: :downlink,
        ground_station_id: :equator_prime,
        actual_throughput_mb: 10.0
      },
      %{
        id: :bad_selected_station,
        type: :downlink,
        ground_station_id: "bad selected station id",
        actual_throughput_mb: 5.0
      }
    ]

    report = LinkCapacity.report(candidates, selected, source: "malformed_identity_test")

    assert %{
             "contact_count" => 0,
             "selected_contact_count" => 0,
             "invalid_contact_input_count" => 3,
             "invalid_contact_input_ids" => [
               "bad_scenario",
               "bad_station",
               "invalid_contact_id:1"
             ],
             "invalid_selected_contact_input_count" => 2,
             "invalid_selected_contact_input_ids" => [
               "bad_selected_station",
               "invalid_contact_id:1"
             ],
             "invalid_contact_inputs" => invalid_candidate_inputs,
             "invalid_selected_contact_inputs" => invalid_selected_inputs
           } = report

    assert %{
             "contact_id" => "invalid_contact_id:1",
             "input_role" => "candidate",
             "invalid_contact_input_reason" => "invalid_contact_id",
             "source_contact_candidate" => %{"id" => "bad contact id"}
           } = Enum.find(invalid_candidate_inputs, &(&1["contact_id"] == "invalid_contact_id:1"))

    bad_station_row =
      Enum.find(invalid_candidate_inputs, &(&1["contact_id"] == "bad_station"))

    assert %{
             "invalid_contact_input_reason" => "invalid_ground_station_id",
             "source_contact_candidate" => %{"ground_station_id" => "bad station id"}
           } = bad_station_row

    refute Map.has_key?(bad_station_row, "ground_station_id")

    bad_scenario_row =
      Enum.find(invalid_candidate_inputs, &(&1["contact_id"] == "bad_scenario"))

    assert %{
             "invalid_contact_input_reason" => "invalid_scenario_id",
             "source_contact_candidate" => %{"scenario_id" => "bad scenario id"}
           } = bad_scenario_row

    refute Map.has_key?(bad_scenario_row, "scenario_id")

    assert %{
             "contact_id" => "bad_selected_station",
             "input_role" => "selected",
             "invalid_contact_input_reason" => "invalid_ground_station_id",
             "source_contact_candidate" => %{
               "ground_station_id" => "bad selected station id"
             }
           } = Enum.find(invalid_selected_inputs, &(&1["contact_id"] == "bad_selected_station"))

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    stale_invalid_policy_summary_report =
      Map.put(report, "invalid_policy_required_downlink_station_ids", [
        "z bad station",
        "bad station",
        "bad station"
      ])

    assert %{
             "invalid_policy_required_downlink_station_count" => 2,
             "invalid_policy_required_downlink_station_ids" => ["bad station", "z bad station"]
           } = LinkCapacity.summary(stale_invalid_policy_summary_report)

    duplicate_invalid_policy_ids =
      report
      |> Map.put("invalid_policy_required_downlink_station_count", 2)
      |> Map.put("invalid_policy_required_downlink_station_ids", ["bad station", "bad station"])

    assert {:error, duplicate_invalid_policy_ids_report} =
             Schema.validate_artifact(duplicate_invalid_policy_ids)

    assert Enum.any?(
             duplicate_invalid_policy_ids_report["errors"],
             &(&1["path"] == "$.invalid_policy_required_downlink_station_ids" and
                 &1["message"] ==
                   "must equal deterministic invalid_policy_required_downlink_station_ids")
           )

    mismatched_invalid_policy_count =
      Map.put(report, "invalid_policy_required_downlink_station_count", 2)

    assert {:error, mismatched_invalid_policy_count_report} =
             Schema.validate_artifact(mismatched_invalid_policy_count)

    assert Enum.any?(
             mismatched_invalid_policy_count_report["errors"],
             &(&1["path"] == "$.invalid_policy_required_downlink_station_count" and
                 &1["message"] ==
                   "must equal invalid_policy_required_downlink_station_ids count")
           )

    review = OperatorReview.from_link_capacity_report(report)

    assert Enum.any?(
             review["rows"],
             &(&1["contact_id"] == "bad_station" and
                 &1["invalid_contact_input_reason"] == "invalid_ground_station_id" and
                 get_in(&1, ["source_contact_candidate", "ground_station_id"]) ==
                   "bad station id")
           )

    manifest = CadenceImport.from_link_capacity_report(report)

    assert Enum.any?(
             manifest["rows"],
             &(&1["contact_id"] == "bad_selected_station" and
                 &1["invalid_contact_input_reason"] == "invalid_ground_station_id" and
                 get_in(&1, ["source_contact_candidate", "ground_station_id"]) ==
                   "bad selected station id")
           )
  end

  test "uses throughput-bearing provider contacts as downlink capacity inputs" do
    candidates = [
      %{
        id: :provider_dl,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 10.0
      },
      %{
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 5.0
      }
    ]

    selected = [
      %{
        contact_id: :provider_dl,
        ground_station_id: :equator_prime,
        actual_throughput_mb: 8.0
      },
      %{
        ground_station_id: :equator_prime,
        actual_throughput_mb: 2.0
      }
    ]

    report = LinkCapacity.report(candidates, selected, source: "provider_contacts")

    assert %{
             "contact_count" => 1,
             "effective_contact_count" => 1,
             "selected_contact_count" => 1,
             "estimated_throughput_mb" => 10.0,
             "selected_estimated_throughput_mb" => 10.0,
             "actual_throughput_mb" => 8.0,
             "actual_throughput_contact_ids" => ["provider_dl"],
             "invalid_contact_input_count" => 1,
             "invalid_contact_input_ids" => ["missing_contact_id:2"],
             "invalid_selected_contact_input_count" => 1,
             "invalid_selected_contact_input_ids" => ["missing_contact_id:2"],
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "contact_count" => 1,
                 "effective_contact_count" => 1,
                 "contact_ids" => ["provider_dl"],
                 "selected_contact_ids" => ["provider_dl"],
                 "actual_throughput_mb" => 8.0
               }
             ],
             "invalid_contact_inputs" => invalid_candidate_inputs,
             "invalid_selected_contact_inputs" => invalid_selected_inputs
           } = report

    assert %{
             "contact_id" => "missing_contact_id:2",
             "input_role" => "candidate",
             "direction" => "downlink",
             "invalid_contact_input_reason" => "missing_contact_id",
             "source_contact_candidate" => %{
               "ground_station_id" => "equator_prime",
               "estimated_throughput_mb" => 5.0
             }
           } = hd(invalid_candidate_inputs)

    assert %{
             "contact_id" => "missing_contact_id:2",
             "input_role" => "selected",
             "direction" => "downlink",
             "invalid_contact_input_reason" => "missing_contact_id",
             "source_contact_candidate" => %{
               "ground_station_id" => "equator_prime",
               "actual_throughput_mb" => 2.0
             }
           } = hd(invalid_selected_inputs)

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_link_capacity_report(report)

    assert Enum.any?(
             review["rows"],
             &match?(
               %{
                 "input_role" => "candidate",
                 "contact_id" => "missing_contact_id:2",
                 "required_operator_action" => "review_invalid_link_capacity_input",
                 "invalid_contact_input_reason" => "missing_contact_id"
               },
               &1
             )
           )

    assert Enum.any?(
             review["rows"],
             &match?(
               %{
                 "input_role" => "selected",
                 "contact_id" => "missing_contact_id:2",
                 "required_operator_action" => "review_invalid_link_capacity_input",
                 "invalid_contact_input_reason" => "missing_contact_id"
               },
               &1
             )
           )

    manifest = CadenceImport.from_link_capacity_report(report)

    assert Enum.any?(
             manifest["rows"],
             &match?(
               %{
                 "import_action" => "review_link_capacity",
                 "input_role" => "candidate",
                 "contact_id" => "missing_contact_id:2",
                 "invalid_contact_input_reason" => "missing_contact_id"
               },
               &1
             )
           )

    assert Enum.any?(
             manifest["rows"],
             &match?(
               %{
                 "import_action" => "review_link_capacity",
                 "input_role" => "selected",
                 "contact_id" => "missing_contact_id:2",
                 "invalid_contact_input_reason" => "missing_contact_id"
               },
               &1
             )
           )
  end

  test "rejects link capacity summaries that diverge from rows and invalid input evidence" do
    candidates = [
      %{
        id: :dl_1,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0,
        station_capacity_fraction: 0.5
      },
      %{
        id: :dl_ignored,
        type: :downlink,
        ground_station_id: :deep_space_net,
        estimated_throughput_mb: 20.0,
        status: :completed
      },
      %{
        id: :dup_dl,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 5.0
      },
      %{
        id: :dup_dl,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 6.0
      },
      %{id: :missing_station, type: :downlink, estimated_throughput_mb: 10.0}
    ]

    selected = [
      %{
        id: :dl_1,
        type: :downlink,
        ground_station_id: :equator_prime,
        actual_throughput_mb: 40.0,
        completed_fraction: 0.5
      },
      %{id: :dup_dl, type: :downlink, ground_station_id: :equator_prime},
      %{type: :downlink, ground_station_id: :equator_prime, actual_throughput_mb: 2.0}
    ]

    report = LinkCapacity.report(candidates, selected)

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    invalid_contact_count = Map.put(report, "contact_count", 99)

    assert {:error, contact_count_report} = Schema.validate_artifact(invalid_contact_count)

    assert Enum.any?(
             contact_count_report["errors"],
             &(&1["path"] == "$.contact_count" and
                 &1["message"] == "must equal row-derived contact_count")
           )

    invalid_throughput = Map.put(report, "estimated_throughput_mb", 999.0)

    assert {:error, throughput_report} = Schema.validate_artifact(invalid_throughput)

    assert Enum.any?(
             throughput_report["errors"],
             &(&1["path"] == "$.estimated_throughput_mb" and
                 &1["message"] == "must equal row-derived estimated_throughput_mb")
           )

    invalid_ignored_ids = Map.put(report, "ignored_contact_ids", ["other_contact"])

    assert {:error, ignored_ids_report} = Schema.validate_artifact(invalid_ignored_ids)

    assert Enum.any?(
             ignored_ids_report["errors"],
             &(&1["path"] == "$.ignored_contact_ids" and
                 &1["message"] == "must equal row-derived ignored_contact_ids")
           )

    invalid_actual_ids = Map.put(report, "actual_throughput_contact_ids", ["other_contact"])

    assert {:error, actual_ids_report} = Schema.validate_artifact(invalid_actual_ids)

    assert Enum.any?(
             actual_ids_report["errors"],
             &(&1["path"] == "$.actual_throughput_contact_ids" and
                 &1["message"] == "must equal row-derived actual_throughput_contact_ids")
           )

    invalid_input_ids = Map.put(report, "invalid_contact_input_ids", ["other_contact"])

    assert {:error, invalid_input_ids_report} = Schema.validate_artifact(invalid_input_ids)

    assert Enum.any?(
             invalid_input_ids_report["errors"],
             &(&1["path"] == "$.invalid_contact_input_ids" and
                 &1["message"] == "must equal row-derived invalid_contact_input_ids")
           )
  end

  test "builds fixed-rate link capacity reports from atom or string keyed contacts" do
    contacts = [
      %{
        id: :dl_1,
        type: :downlink,
        scenario_id: :leo_1,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0,
        throughput_model: %{station_capacity_fraction: 0.5}
      },
      %{
        "id" => "dl_2",
        "type" => "downlink",
        "scenario_id" => "leo_2",
        "ground_station_id" => "equator_prime",
        "estimated_throughput_mb" => 50.0,
        "capacity_percent" => "25"
      },
      %{
        id: :obs_1,
        type: :observe,
        scenario_id: :leo_1,
        target_id: :target_alpha
      }
    ]

    report =
      LinkCapacity.report(contacts, [hd(contacts)],
        source: "unit_test.contacts",
        policy: %{downlink_rate_mb_s: 2.0}
      )

    expected_capability_assumptions = link_capacity_capability_assumptions()

    expected_station_unavailable_aliases =
      expected_capability_assumptions["station_unavailable_aliases"]

    expected_station_availability_precedence =
      expected_capability_assumptions["station_availability_precedence"]

    expected_station_capacity_value_paths =
      expected_capability_assumptions["station_capacity_value_paths"]

    expected_source_station_capacity_value_paths =
      expected_capability_assumptions["source_station_capacity_value_paths"]

    expected_provider_direction_aliases =
      expected_capability_assumptions["provider_direction_aliases"]

    assert %{
             "schema_contract" => "link_capacity_report.v1",
             "model" => "fixed_rate_downlink_capacity_summary",
             "source" => "unit_test.contacts",
             "contact_count" => 2,
             "selected_contact_count" => 1,
             "estimated_throughput_mb" => 150.0,
             "selected_estimated_throughput_mb" => 100.0,
             "capacity_adjusted_throughput_mb" => 62.5,
             "selected_capacity_adjusted_throughput_mb" => 50.0,
             "unused_capacity_adjusted_throughput_mb" => 12.5,
             "selected_capacity_utilization_fraction" => 0.8,
             "selection_utilization_status" => "partial_capacity_selected",
             "model_limits" => model_limits,
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "contact_count" => 2,
                 "selected_contact_count" => 1,
                 "estimated_throughput_mb" => 150.0,
                 "selected_estimated_throughput_mb" => 100.0,
                 "capacity_adjusted_throughput_mb" => 62.5,
                 "selected_capacity_adjusted_throughput_mb" => 50.0,
                 "unused_capacity_adjusted_throughput_mb" => 12.5,
                 "selected_capacity_utilization_fraction" => 0.8,
                 "selection_utilization_status" => "partial_capacity_selected",
                 "capacity_fraction_min" => 0.25,
                 "capacity_fraction_max" => 0.5,
                 "contact_ids" => ["dl_1", "dl_2"],
                 "selected_contact_ids" => ["dl_1"]
               }
             ],
             "assumptions" => %{
               "downlink_rate_mb_s" => 2.0,
               "link_budget_model" => "none",
               "reservation_model" => "provider_reservation_identity_context_only",
               "station_unavailable_aliases" => ^expected_station_unavailable_aliases,
               "station_availability_precedence" => ^expected_station_availability_precedence,
               "station_capacity_value_paths" => ^expected_station_capacity_value_paths,
               "source_station_capacity_value_paths" =>
                 ^expected_source_station_capacity_value_paths,
               "provider_direction_aliases" => ^expected_provider_direction_aliases
             }
           } = report

    assert "no_link_budget_model" in model_limits
    assert "no_schedule_mutation" in model_limits

    expected_model_limits =
      LinkCapacity.capabilities()
      |> Map.fetch!(:known_limits)
      |> Enum.map(&to_string/1)

    assert model_limits == expected_model_limits

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, link_capacity_report_schema} = Schema.json_schema("link_capacity_report.v1")

    assert get_in(link_capacity_report_schema, ["properties", "model_limits", "oneOf"]) == [
             %{"const" => expected_model_limits},
             %{"const" => LinkCapacity.report_model_limits([:present])}
           ]

    assert get_in(link_capacity_report_schema, [
             "properties",
             "model_limits",
             "items",
             "enum"
           ]) == expected_model_limits

    assert get_in(link_capacity_report_schema, [
             "properties",
             "assumptions",
             "properties",
             "station_availability_precedence",
             "const"
           ]) == expected_capability_assumptions["station_availability_precedence"]

    assert get_in(link_capacity_report_schema, [
             "properties",
             "assumptions",
             "properties",
             "source_station_capacity_value_paths",
             "const"
           ]) == expected_capability_assumptions["source_station_capacity_value_paths"]

    stale_report_station_capacity_paths =
      put_in(report, ["assumptions", "station_capacity_value_paths"], [
        %{"unit" => "fraction", "path" => ["stale_capacity"]}
      ])

    assert {:error, stale_report_station_capacity_paths_report} =
             Schema.validate_artifact(stale_report_station_capacity_paths)

    assert Enum.any?(
             stale_report_station_capacity_paths_report["errors"],
             &(&1["path"] == "$.assumptions.station_capacity_value_paths" and
                 &1["message"] == "must match LinkCapacity station capacity value paths")
           )

    report_without_optional_capability_assumptions =
      drop_link_capacity_capability_assumptions(report)

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report_without_optional_capability_assumptions)

    stale_report_model_limits = Map.put(report, "model_limits", ["artifact_level_only"])

    assert {:error, stale_report_model_limits_report} =
             Schema.validate_artifact(stale_report_model_limits)

    assert Enum.any?(
             stale_report_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match link capacity capability model limits")
           )
  end

  test "counts planned-contact downlinks and excludes non-downlink contact directions" do
    contacts = [
      %{
        id: :native_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 20.0
      },
      %{
        id: :planned_downlink,
        type: :planned_contact,
        direction: "Down Link",
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 30.0,
        station_capacity_fraction: 0.5
      },
      %{
        id: :direction_only_downlink,
        direction: "Down Link",
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 12.0,
        station_capacity_fraction: 0.25
      },
      %{
        id: :planned_command,
        type: :planned_contact,
        direction: :command,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0
      },
      %{
        id: :direction_only_uplink,
        direction: "Up Link",
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0
      },
      %{
        id: :direction_only_tracking,
        direction: "Track-ing",
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0
      }
    ]

    report = LinkCapacity.report(contacts, [Enum.at(contacts, 1), Enum.at(contacts, 2)])

    assert %{
             "contact_count" => 3,
             "selected_contact_count" => 2,
             "estimated_throughput_mb" => 62.0,
             "selected_estimated_throughput_mb" => 42.0,
             "capacity_adjusted_throughput_mb" => 38.0,
             "selected_capacity_adjusted_throughput_mb" => 18.0,
             "unused_capacity_adjusted_throughput_mb" => 20.0,
             "selection_utilization_status" => "partial_capacity_selected",
             "rows" => [
               %{
                 "contact_ids" => [
                   "direction_only_downlink",
                   "native_downlink",
                   "planned_downlink"
                 ],
                 "selected_contact_ids" => ["direction_only_downlink", "planned_downlink"]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes station-calendar direction aliases in capacity context" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :dl_alias_context,
            type: :planned_contact,
            direction: "Down Link",
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 30.0,
            station_calendar_directions: ["Down Link"],
            source_station_calendar_entry: %{
              id: :calendar_downlink,
              station_calendar_directions: ["Down Link"]
            }
          },
          %{
            id: :dl_provider_short_alias,
            type: :planned_contact,
            direction: "dl",
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 20.0,
            station_calendar_directions: ["down"],
            source_station_calendar_entry: %{
              id: :calendar_downlink_short,
              station_calendar_directions: ["downlinking"]
            }
          }
        ],
        []
      )

    assert %{
             "contact_count" => 2,
             "rows" => [
               %{
                 "contact_ids" => ["dl_alias_context", "dl_provider_short_alias"],
                 "station_calendar_directions" => ["downlink"]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "audits terminal or rejected downlinks without counting available or selected capacity" do
    contacts = [
      %{
        id: :active_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0,
        station_capacity_fraction: 0.5,
        status: :planned
      },
      %{
        id: :canceled_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 200.0,
        status: :canceled
      },
      %{
        id: :rejected_downlink,
        type: :planned_contact,
        direction: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 50.0,
        approval_status: :rejected
      },
      %{
        id: :completed_rejected_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 80.0,
        status: :completed,
        approval_status: :rejected
      }
    ]

    report = LinkCapacity.report(contacts, contacts)

    assert %{
             "contact_count" => 4,
             "effective_contact_count" => 1,
             "ignored_contact_count" => 3,
             "ignored_contact_ids" => [
               "canceled_downlink",
               "completed_rejected_downlink",
               "rejected_downlink"
             ],
             "ignored_contact_reason_counts" => %{
               "activity_status_canceled" => 1,
               "approval_status_rejected" => 2
             },
             "selected_contact_count" => 1,
             "ignored_selected_contact_count" => 3,
             "ignored_selected_contact_ids" => [
               "canceled_downlink",
               "completed_rejected_downlink",
               "rejected_downlink"
             ],
             "ignored_selected_contact_reason_counts" => %{
               "activity_status_canceled" => 1,
               "approval_status_rejected" => 2
             },
             "estimated_throughput_mb" => 100.0,
             "selected_estimated_throughput_mb" => 100.0,
             "capacity_adjusted_throughput_mb" => 50.0,
             "selected_capacity_adjusted_throughput_mb" => 50.0,
             "unused_capacity_adjusted_throughput_mb" => +0.0,
             "selection_utilization_status" => "fully_selected",
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "contact_count" => 4,
                 "effective_contact_count" => 1,
                 "ignored_contact_count" => 3,
                 "ignored_contact_ids" => [
                   "canceled_downlink",
                   "completed_rejected_downlink",
                   "rejected_downlink"
                 ],
                 "ignored_contact_reason_counts" => %{
                   "activity_status_canceled" => 1,
                   "approval_status_rejected" => 2
                 },
                 "selected_contact_count" => 1,
                 "ignored_selected_contact_count" => 3,
                 "ignored_selected_contact_ids" => [
                   "canceled_downlink",
                   "completed_rejected_downlink",
                   "rejected_downlink"
                 ],
                 "ignored_selected_contact_reason_counts" => %{
                   "activity_status_canceled" => 1,
                   "approval_status_rejected" => 2
                 },
                 "estimated_throughput_mb" => 100.0,
                 "selected_estimated_throughput_mb" => 100.0,
                 "capacity_adjusted_throughput_mb" => 50.0,
                 "selected_capacity_adjusted_throughput_mb" => 50.0,
                 "contact_ids" => [
                   "active_downlink",
                   "canceled_downlink",
                   "completed_rejected_downlink",
                   "rejected_downlink"
                 ],
                 "selected_contact_ids" => ["active_downlink"]
               }
             ],
             "assumptions" => %{
               "contact_status_model" =>
                 "terminal_or_approval_rejected_downlinks_are_audited_with_zero_available_or_selected_capacity_and_reason_counts"
             }
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    stale_summary_report =
      report
      |> Map.put("ignored_contact_reason_counts", %{"activity_status_failed" => 9})
      |> Map.put("ignored_selected_contact_reason_counts", %{"activity_status_failed" => 9})
      |> Map.put("ignored_contact_ids", ["stale_ignored_contact"])
      |> Map.put("ignored_selected_contact_ids", ["stale_ignored_selected"])

    assert %{
             "ignored_contact_ids" => [
               "canceled_downlink",
               "completed_rejected_downlink",
               "rejected_downlink"
             ],
             "ignored_selected_contact_ids" => [
               "canceled_downlink",
               "completed_rejected_downlink",
               "rejected_downlink"
             ],
             "ignored_contact_reason_counts" => %{
               "activity_status_canceled" => 1,
               "approval_status_rejected" => 2
             },
             "ignored_selected_contact_reason_counts" => %{
               "activity_status_canceled" => 1,
               "approval_status_rejected" => 2
             }
           } = LinkCapacity.summary(stale_summary_report)

    invalid_ignored_reason_count =
      put_in(report, ["ignored_contact_reason_counts", "approval_status_rejected"], -1)

    assert {:error, ignored_reason_count_report} =
             Schema.validate_artifact(invalid_ignored_reason_count)

    assert Enum.any?(
             ignored_reason_count_report["errors"],
             &(&1["path"] == "$.ignored_contact_reason_counts.approval_status_rejected")
           )

    invalid_row_reason_count =
      put_in(
        report,
        ["rows", Access.at(0), "ignored_contact_reason_counts", "approval_status_rejected"],
        -1
      )

    assert {:error, row_reason_count_report} =
             Schema.validate_artifact(invalid_row_reason_count)

    assert Enum.any?(
             row_reason_count_report["errors"],
             &(&1["path"] ==
                 "$.rows[0].ignored_contact_reason_counts.approval_status_rejected")
           )
  end

  test "summarizes station-id-only provider contacts" do
    contacts = [
      %{
        id: :provider_contact,
        type: :contact,
        direction: :downlink,
        station_id: :equator_prime,
        estimated_throughput_mb: 40.0,
        station_capacity_fraction: 0.5
      }
    ]

    report = LinkCapacity.report(contacts, contacts)

    assert %{
             "contact_count" => 1,
             "selected_contact_count" => 1,
             "estimated_throughput_mb" => 40.0,
             "selected_estimated_throughput_mb" => 40.0,
             "capacity_adjusted_throughput_mb" => 20.0,
             "selected_capacity_adjusted_throughput_mb" => 20.0,
             "selected_capacity_utilization_fraction" => 1.0,
             "selection_utilization_status" => "fully_selected",
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "contact_ids" => ["provider_contact"],
                 "selected_contact_ids" => ["provider_contact"]
               }
             ]
           } = report

    assert report["unused_capacity_adjusted_throughput_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "summarizes provider contacts with nested station identity" do
    contacts = [
      %{
        id: :provider_nested_station,
        type: :contact,
        direction: :downlink,
        station: %{id: :equator_prime},
        estimated_throughput_mb: 40.0
      },
      %{
        id: :provider_nested_ground_station,
        type: :contact,
        direction: :downlink,
        ground_station: %{ground_station_id: :equator_prime},
        estimated_throughput_mb: 20.0
      }
    ]

    report = LinkCapacity.report(contacts, contacts)

    assert %{
             "contact_count" => 2,
             "selected_contact_count" => 2,
             "estimated_throughput_mb" => 60.0,
             "selected_estimated_throughput_mb" => 60.0,
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "contact_ids" => [
                   "provider_nested_ground_station",
                   "provider_nested_station"
                 ],
                 "selected_contact_ids" => [
                   "provider_nested_ground_station",
                   "provider_nested_station"
                 ]
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "excludes duplicate and unmatched selected contact ids from selected capacity totals" do
    contacts = [
      %{
        id: :dup_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0
      },
      %{
        id: :dup_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 50.0,
        station_capacity_fraction: 0.5
      },
      %{
        id: :unique_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 40.0,
        station_capacity_fraction: 0.25
      }
    ]

    selected_contacts = [
      hd(contacts),
      Enum.at(contacts, 2),
      %{
        id: :missing_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 500.0
      }
    ]

    report =
      LinkCapacity.report(contacts, selected_contacts,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "contact_count" => 3,
             "selected_contact_count" => 1,
             "estimated_throughput_mb" => 190.0,
             "selected_estimated_throughput_mb" => 40.0,
             "capacity_adjusted_throughput_mb" => 135.0,
             "selected_capacity_adjusted_throughput_mb" => 10.0,
             "unused_capacity_adjusted_throughput_mb" => 125.0,
             "selection_utilization_status" => "partial_capacity_selected",
             "duplicate_contact_id_count" => 1,
             "duplicate_contact_candidate_count" => 2,
             "ambiguous_selected_contact_id_count" => 1,
             "ambiguous_selected_contact_ids" => ["dup_downlink"],
             "unmatched_selected_contact_count" => 1,
             "unmatched_selected_contact_ids" => ["missing_downlink"],
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "selected_contact_count" => 1,
                 "selected_contact_ids" => ["unique_downlink"],
                 "unused_capacity_adjusted_throughput_mb" => 125.0,
                 "selection_utilization_status" => "partial_capacity_selected",
                 "duplicate_contact_ids" => ["dup_downlink"],
                 "duplicate_contact_candidate_count" => 2,
                 "ambiguous_selected_contact_ids" => ["dup_downlink"],
                 "ambiguous_selected_contact_id_count" => 1,
                 "approval_requirements" => [
                   %{
                     "activity_context" => %{
                       "contact_ids" => ["dup_downlink", "dup_downlink", "unique_downlink"],
                       "selected_contact_ids" => ["unique_downlink"],
                       "duplicate_contact_ids" => ["dup_downlink"],
                       "duplicate_contact_candidate_count" => 2,
                       "ambiguous_selected_contact_ids" => ["dup_downlink"],
                       "ambiguous_selected_contact_id_count" => 1,
                       "unused_capacity_adjusted_throughput_mb" => 125.0,
                       "selection_utilization_status" => "partial_capacity_selected"
                     }
                   }
                 ]
               }
             ]
           } = report

    assert_in_delta report["selected_capacity_utilization_fraction"], 10.0 / 135.0, 1.0e-12

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    stale_ambiguous_summary_report =
      Map.put(report, "ambiguous_selected_contact_ids", ["stale_ambiguous_selected"])

    assert %{"ambiguous_selected_contact_ids" => ["dup_downlink"]} =
             LinkCapacity.summary(stale_ambiguous_summary_report)

    stale_unmatched_summary_report =
      Map.put(report, "unmatched_selected_contact_ids", [
        "z_missing_downlink",
        "missing_downlink",
        "missing_downlink"
      ])

    assert %{
             "unmatched_selected_contact_ids" => ["missing_downlink", "z_missing_downlink"]
           } = LinkCapacity.summary(stale_unmatched_summary_report)

    duplicate_unmatched_selected_ids =
      report
      |> Map.put("unmatched_selected_contact_count", 2)
      |> Map.put("unmatched_selected_contact_ids", ["missing_downlink", "missing_downlink"])

    assert {:error, duplicate_unmatched_selected_ids_report} =
             Schema.validate_artifact(duplicate_unmatched_selected_ids)

    assert Enum.any?(
             duplicate_unmatched_selected_ids_report["errors"],
             &(&1["path"] == "$.unmatched_selected_contact_ids" and
                 &1["message"] == "must equal deterministic unmatched_selected_contact_ids")
           )

    mismatched_unmatched_selected_count =
      Map.put(report, "unmatched_selected_contact_count", 2)

    assert {:error, mismatched_unmatched_selected_count_report} =
             Schema.validate_artifact(mismatched_unmatched_selected_count)

    assert Enum.any?(
             mismatched_unmatched_selected_count_report["errors"],
             &(&1["path"] == "$.unmatched_selected_contact_count" and
                 &1["message"] == "must equal unmatched_selected_contact_ids count")
           )

    review = OperatorReview.from_link_capacity_report(report)

    assert [
             %{
               "duplicate_contact_ids" => ["dup_downlink"],
               "ambiguous_selected_contact_ids" => ["dup_downlink"],
               "unused_capacity_adjusted_throughput_mb" => 125.0,
               "selection_utilization_status" => "partial_capacity_selected",
               "source_link_capacity" => %{"ambiguous_selected_contact_ids" => ["dup_downlink"]}
             },
             %{
               "source" => "link_capacity_report.unmatched_selected_contact_ids",
               "required_operator_action" => "resolve_unmatched_selected_contacts",
               "unmatched_selected_contact_count" => 1,
               "unmatched_selected_contact_ids" => ["missing_downlink"],
               "source_link_capacity" => %{
                 "unmatched_selected_contact_ids" => ["missing_downlink"]
               }
             }
           ] = review["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    manifest = CadenceImport.from_link_capacity_report(report)

    assert [
             %{
               "duplicate_contact_ids" => ["dup_downlink"],
               "ambiguous_selected_contact_ids" => ["dup_downlink"],
               "unused_capacity_adjusted_throughput_mb" => 125.0,
               "selection_utilization_status" => "partial_capacity_selected",
               "source_link_capacity" => %{"ambiguous_selected_contact_ids" => ["dup_downlink"]}
             },
             %{
               "import_action" => "review_link_capacity",
               "source" => "link_capacity_report.unmatched_selected_contact_ids",
               "required_operator_action" => "resolve_unmatched_selected_contacts",
               "unmatched_selected_contact_count" => 1,
               "unmatched_selected_contact_ids" => ["missing_downlink"],
               "source_link_capacity" => %{
                 "unmatched_selected_contact_ids" => ["missing_downlink"]
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "classifies reduced-capacity rows with approval policy" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :dl_1,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0,
            station_calendar_entry_id: :calendar_row_1,
            station_calendar_provider_id: :ops_calendar,
            station_calendar_provider_entry_id: :provider_window_1,
            station_calendar_directions: [:downlink],
            throughput_model: %{station_capacity_fraction: 0.4}
          },
          %{
            id: :dl_2,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 50.0,
            source_station_calendar_entry: %{
              id: :calendar_row_2,
              provider_id: :ops_calendar,
              provider_entry_id: :provider_window_2,
              station_calendar_directions: [:downlink]
            },
            station_capacity_fraction: 0.8
          }
        ],
        [],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [
             %{
               "ground_station_id" => "equator_prime",
               "capacity_fraction_min" => 0.4,
               "station_calendar_entry_ids" => ["calendar_row_1", "calendar_row_2"],
               "station_calendar_provider_ids" => ["ops_calendar"],
               "station_calendar_provider_entry_ids" => ["provider_window_1", "provider_window_2"],
               "station_calendar_directions" => ["downlink"],
               "unused_capacity_adjusted_throughput_mb" => 80.0,
               "selection_utilization_status" => "unselected_capacity",
               "approval_status" => "operator_review_required",
               "approval_requirements" => [
                 %{
                   "activity_type" => "link_capacity_summary",
                   "requirement_type" => "contact_schedule_change",
                   "activity_context" => %{
                     "station_calendar_entry_ids" => ["calendar_row_1", "calendar_row_2"],
                     "station_calendar_provider_ids" => ["ops_calendar"],
                     "station_calendar_provider_entry_ids" => [
                       "provider_window_1",
                       "provider_window_2"
                     ],
                     "station_calendar_directions" => ["downlink"]
                   },
                   "policy_classification" => "operator_review_required"
                 }
               ],
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "severe_capacity_reduction_review",
                   "station_availability" => "reduced_capacity",
                   "capacity_fraction" => 0.4
                 }
               ],
               "policy_decision" => %{
                 "schema_contract" => "policy_decision.v1",
                 "policy_bundle_id" => "ground_network_allocation_v1"
               }
             }
           ] = report["rows"]

    assert hd(report["rows"])["selected_capacity_utilization_fraction"] == 0.0

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_link_capacity_report(report)

    assert [
             %{
               "review_type" => "link_capacity_review",
               "station_calendar_entry_ids" => ["calendar_row_1", "calendar_row_2"],
               "station_calendar_provider_ids" => ["ops_calendar"],
               "station_calendar_provider_entry_ids" => ["provider_window_1", "provider_window_2"],
               "station_calendar_directions" => ["downlink"],
               "source_link_capacity" => %{
                 "station_calendar_entry_ids" => ["calendar_row_1", "calendar_row_2"],
                 "station_calendar_provider_ids" => ["ops_calendar"],
                 "station_calendar_provider_entry_ids" => [
                   "provider_window_1",
                   "provider_window_2"
                 ],
                 "station_calendar_directions" => ["downlink"]
               }
             }
           ] = review["rows"]

    manifest = CadenceImport.from_link_capacity_report(report)

    assert [
             %{
               "import_action" => "review_link_capacity",
               "station_calendar_entry_ids" => ["calendar_row_1", "calendar_row_2"],
               "station_calendar_provider_ids" => ["ops_calendar"],
               "station_calendar_provider_entry_ids" => ["provider_window_1", "provider_window_2"],
               "station_calendar_directions" => ["downlink"],
               "source_link_capacity" => %{
                 "station_calendar_entry_ids" => ["calendar_row_1", "calendar_row_2"],
                 "station_calendar_provider_ids" => ["ops_calendar"],
                 "station_calendar_provider_entry_ids" => [
                   "provider_window_1",
                   "provider_window_2"
                 ],
                 "station_calendar_directions" => ["downlink"]
               }
             }
           ] = manifest["rows"]
  end

  test "preserves station reservation evidence in capacity review and import rows" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :dl_reserved_owned,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0,
            station_availability: "Reserved",
            station_reservation_id: :reservation_42,
            station_reservation_expires_at_s: "420.0",
            station_reserved_by: :mission_ops,
            station_reservation_status: :Confirmed,
            station_reservation_match_status: "Owned"
          },
          %{
            id: :dl_reserved_nested,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 50.0,
            source_station_calendar_entry: %{
              id: :calendar_reserved_1,
              provider_id: :ops_calendar,
              provider_entry_id: :provider_reserved_1,
              availability: "Reserved",
              reserved_by: :network_partner,
              reservation_status: "Held",
              reservation_match_status: "Unmatched",
              expires_at: "540.0"
            }
          }
        ],
        []
      )

    assert [
             %{
               "ground_station_id" => "equator_prime",
               "station_availability" => "reserved",
               "station_calendar_entry_ids" => ["calendar_reserved_1"],
               "station_calendar_provider_ids" => ["ops_calendar"],
               "station_calendar_provider_entry_ids" => ["provider_reserved_1"],
               "station_reservation_ids" => ["calendar_reserved_1", "reservation_42"],
               "station_reservation_expires_at_s" => [420.0, 540.0],
               "station_reserved_bys" => ["mission_ops", "network_partner"],
               "station_reservation_statuses" => ["confirmed", "held"],
               "station_reservation_match_statuses" => ["owned", "unmatched"]
             }
           ] = report["rows"]

    assert %{
             "station_reservation_ids" => ["calendar_reserved_1", "reservation_42"],
             "station_reservation_expires_at_s" => [420.0, 540.0],
             "station_reserved_bys" => ["mission_ops", "network_partner"],
             "station_reservation_statuses" => ["confirmed", "held"],
             "station_reservation_match_status_counts" => %{
               "owned" => 1,
               "unmatched" => 1
             }
           } = report

    assert get_in(report, ["assumptions", "reservation_model"]) ==
             "provider_reservation_identity_context_only"

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "station_calendar_entry_ids" => ["calendar_reserved_1"],
             "station_calendar_provider_ids" => ["ops_calendar"],
             "station_calendar_provider_entry_ids" => ["provider_reserved_1"],
             "station_reservation_ids" => ["calendar_reserved_1", "reservation_42"],
             "station_reservation_expires_at_s" => [420.0, 540.0],
             "station_reserved_bys" => ["mission_ops", "network_partner"],
             "station_reservation_statuses" => ["confirmed", "held"],
             "station_reservation_match_status_counts" => %{
               "owned" => 1,
               "unmatched" => 1
             },
             "ground_station_ids_by_station_availability" => %{
               "reserved" => ["equator_prime"]
             },
             "ground_station_ids_by_reservation_match_status" => %{
               "owned" => ["equator_prime"],
               "unmatched" => ["equator_prime"]
             },
             "ground_station_ids_by_reservation_status" => %{
               "confirmed" => ["equator_prime"],
               "held" => ["equator_prime"]
             },
             "ground_station_ids_by_reserved_by" => %{
               "mission_ops" => ["equator_prime"],
               "network_partner" => ["equator_prime"]
             },
             "station_calendar_entry_ids_by_ground_station_id" => %{
               "equator_prime" => ["calendar_reserved_1"]
             },
             "station_calendar_provider_ids_by_ground_station_id" => %{
               "equator_prime" => ["ops_calendar"]
             },
             "station_calendar_provider_entry_ids_by_ground_station_id" => %{
               "equator_prime" => ["provider_reserved_1"]
             },
             "station_reservation_ids_by_ground_station_id" => %{
               "equator_prime" => ["calendar_reserved_1", "reservation_42"]
             }
           } = summary = LinkCapacity.summary(report)

    stale_provider_summary =
      Map.put(summary, "station_calendar_provider_ids", ["stale_provider"])

    assert {:error, stale_provider_summary_errors} =
             Schema.validate_artifact(stale_provider_summary)

    assert Enum.any?(
             stale_provider_summary_errors["errors"],
             &(&1["path"] == "$.station_calendar_provider_ids" and
                 &1["message"] ==
                   "must equal station_calendar_provider_ids_by_ground_station_id values")
           )

    stale_provider_entry_summary =
      Map.put(summary, "station_calendar_provider_entry_ids", ["stale_provider_entry"])

    assert {:error, stale_provider_entry_summary_errors} =
             Schema.validate_artifact(stale_provider_entry_summary)

    assert Enum.any?(
             stale_provider_entry_summary_errors["errors"],
             &(&1["path"] == "$.station_calendar_provider_entry_ids" and
                 &1["message"] ==
                   "must equal station_calendar_provider_entry_ids_by_ground_station_id values")
           )

    stale_summary_report =
      Map.put(report, "station_reservation_match_status_counts", %{"overlap" => 9})

    assert %{
             "station_reservation_match_status_counts" => %{
               "owned" => 1,
               "unmatched" => 1
             }
           } = LinkCapacity.summary(stale_summary_report)

    stale_reservation_summary_report =
      Map.merge(report, %{
        "station_reservation_ids" => ["stale_reservation"],
        "station_reservation_expires_at_s" => [999.0],
        "station_reserved_bys" => ["stale_owner"],
        "station_reservation_statuses" => ["stale_status"]
      })

    assert %{
             "station_reservation_ids" => ["calendar_reserved_1", "reservation_42"],
             "station_reservation_expires_at_s" => [420.0, 540.0],
             "station_reserved_bys" => ["mission_ops", "network_partner"],
             "station_reservation_statuses" => ["confirmed", "held"]
           } = LinkCapacity.summary(stale_reservation_summary_report)

    assert {:error, stale_reservation_report} =
             Schema.validate_artifact(stale_reservation_summary_report)

    assert Enum.any?(
             stale_reservation_report["errors"],
             &(&1["path"] == "$.station_reservation_ids" and
                 &1["message"] == "must equal row-derived station_reservation_ids")
           )

    no_reservation_report =
      LinkCapacity.report(
        [
          %{
            id: :dl_clear,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 25.0
          }
        ],
        []
      )

    stale_no_row_reservation_report =
      Map.merge(no_reservation_report, %{
        "station_reservation_ids" => ["stale_reservation"],
        "station_reservation_expires_at_s" => [999.0],
        "station_reserved_bys" => ["stale_owner"],
        "station_reservation_statuses" => ["stale_status"]
      })

    assert %{
             "station_reservation_ids" => [],
             "station_reservation_expires_at_s" => [],
             "station_reserved_bys" => [],
             "station_reservation_statuses" => []
           } = LinkCapacity.summary(stale_no_row_reservation_report)

    assert {:error, stale_no_row_reservation_errors} =
             Schema.validate_artifact(stale_no_row_reservation_report)

    assert Enum.any?(
             stale_no_row_reservation_errors["errors"],
             &(&1["path"] == "$.station_reservation_ids" and
                 &1["message"] == "must equal row-derived station_reservation_ids")
           )

    review = OperatorReview.from_link_capacity_report(report)

    assert [
             %{
               "station_reservation_ids" => ["calendar_reserved_1", "reservation_42"],
               "station_reservation_expires_at_s" => [420.0, 540.0],
               "station_reserved_bys" => ["mission_ops", "network_partner"],
               "station_reservation_statuses" => ["confirmed", "held"],
               "station_reservation_match_statuses" => ["owned", "unmatched"],
               "source_link_capacity" => %{
                 "station_reservation_ids" => ["calendar_reserved_1", "reservation_42"],
                 "station_reservation_expires_at_s" => [420.0, 540.0],
                 "station_reserved_bys" => ["mission_ops", "network_partner"],
                 "station_reservation_statuses" => ["confirmed", "held"],
                 "station_reservation_match_statuses" => ["owned", "unmatched"]
               }
             }
           ] = review["rows"]

    manifest = CadenceImport.from_link_capacity_report(report)

    assert [
             %{
               "station_reservation_ids" => ["calendar_reserved_1", "reservation_42"],
               "station_reservation_expires_at_s" => [420.0, 540.0],
               "station_reserved_bys" => ["mission_ops", "network_partner"],
               "station_reservation_statuses" => ["confirmed", "held"],
               "station_reservation_match_statuses" => ["owned", "unmatched"],
               "source_link_capacity" => %{
                 "station_reservation_ids" => ["calendar_reserved_1", "reservation_42"],
                 "station_reservation_expires_at_s" => [420.0, 540.0],
                 "station_reserved_bys" => ["mission_ops", "network_partner"],
                 "station_reservation_statuses" => ["confirmed", "held"],
                 "station_reservation_match_statuses" => ["owned", "unmatched"]
               }
             }
           ] = manifest["rows"]
  end

  test "preserves wrapped station-calendar reservation expiration evidence" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :dl_wrapped_reserved,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0,
            source_station_calendar_entry: %{
              id: :calendar_reserved_entry,
              expires_at: "420.0"
            },
            source_station_calendar_overlaps: [
              %{
                id: :wrapped_station_overlap,
                source_station_calendar_overlaps: [
                  %{
                    id: :calendar_reserved_overlap,
                    reservation_expires_at_s: "540.0"
                  }
                ]
              }
            ]
          }
        ],
        []
      )

    assert [
             %{
               "ground_station_id" => "equator_prime",
               "station_reservation_expires_at_s" => [420.0, 540.0]
             }
           ] = report["rows"]

    assert %{"station_reservation_expires_at_s" => [420.0, 540.0]} = report

    assert %{"station_reservation_expires_at_s" => [420.0, 540.0]} =
             LinkCapacity.summary(report)

    review = OperatorReview.from_link_capacity_report(report)

    assert [
             %{
               "station_reservation_expires_at_s" => [420.0, 540.0],
               "source_link_capacity" => %{
                 "station_reservation_expires_at_s" => [420.0, 540.0]
               }
             }
           ] = review["rows"]

    manifest = CadenceImport.from_link_capacity_report(report)

    assert [
             %{
               "station_reservation_expires_at_s" => [420.0, 540.0],
               "source_link_capacity" => %{
                 "station_reservation_expires_at_s" => [420.0, 540.0]
               }
             }
           ] = manifest["rows"]

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "applies direct station-calendar outage evidence to capacity summaries" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :dl_status_outage,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0,
            station_calendar_status: "Offline"
          },
          %{
            id: :dl_nested_outage,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 50.0,
            station_availability: "Available",
            source_station_calendar_entry: %{
              id: :nested_provider_outage,
              provider_id: :ops_calendar,
              provider_entry_id: :provider_outage_1,
              availability: "Offline"
            }
          }
        ],
        [],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert [row] = report["rows"]

    assert %{
             "ground_station_id" => "equator_prime",
             "contact_count" => 2,
             "effective_contact_count" => 2,
             "estimated_throughput_mb" => 150.0,
             "station_availability" => "unavailable",
             "station_calendar_entry_ids" => ["nested_provider_outage"],
             "station_calendar_provider_ids" => ["ops_calendar"],
             "station_calendar_provider_entry_ids" => ["provider_outage_1"],
             "approval_status" => "blocked_by_policy",
             "approval_rule_matches" => [
               %{
                 "rule_id" => "unavailable_station_contact_block",
                 "station_availability" => "unavailable"
               }
             ]
           } = row

    assert row["capacity_adjusted_throughput_mb"] == 0.0
    assert row["capacity_fraction_min"] == 0.0
    assert row["capacity_fraction_max"] == 0.0

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "summary derives station reservation routing from source station-calendar provenance" do
    summary =
      LinkCapacity.summary(%{
        "schema_contract" => "link_capacity_report.v1",
        "source" => "unit_test.source_station_calendar_provenance",
        "rows" => [
          %{
            "ground_station_id" => "equator_prime",
            "contact_count" => 1,
            "effective_contact_count" => 1,
            "selected_contact_count" => 1,
            "contact_ids" => ["equator_contact_1"],
            "selected_contact_ids" => ["equator_contact_1"],
            "capacity_adjusted_throughput_mb" => 0.0,
            "source_station_calendar_entry" => %{
              "id" => "calendar_reserved_1",
              "provider_id" => "ops_calendar",
              "provider_entry_id" => "provider_reserved_1",
              "availability" => "Reserved",
              "reservation_id" => "reservation_1",
              "reserved_by" => "network_partner",
              "reservation_status" => "Held",
              "reservation_match_status" => "Unmatched"
            }
          },
          %{
            "ground_station_id" => "equator_prime",
            "contact_count" => 1,
            "effective_contact_count" => 1,
            "selected_contact_count" => 1,
            "contact_ids" => ["equator_contact_2"],
            "selected_contact_ids" => ["equator_contact_2"],
            "capacity_adjusted_throughput_mb" => 0.0,
            "source_station_calendar_entry" => %{
              "id" => "calendar_reserved_1b",
              "provider_id" => "backup_calendar",
              "provider_entry_id" => "provider_reserved_1b",
              "availability" => "Reserved",
              "reservation_id" => "reservation_1b",
              "reserved_by" => "backup_partner",
              "reservation_status" => "Tentative",
              "reservation_match_status" => "Overlap"
            }
          },
          %{
            "ground_station_id" => "polar_prime",
            "contact_count" => 1,
            "effective_contact_count" => 1,
            "selected_contact_count" => 1,
            "contact_ids" => ["polar_contact_1"],
            "selected_contact_ids" => ["polar_contact_1"],
            "capacity_adjusted_throughput_mb" => 0.0,
            "source_station_calendar_overlaps" => [
              %{
                "id" => "maintenance_1",
                "availability" => "Maintenance"
              },
              %{
                "id" => "calendar_reserved_2",
                "availability" => "Reserved",
                "reservation_id" => "reservation_2",
                "reservation_status" => "Confirmed",
                "reservation_match_status" => "Owned"
              }
            ]
          },
          %{
            "ground_station_id" => "clear_prime",
            "contact_count" => 1,
            "effective_contact_count" => 1,
            "selected_contact_count" => 1,
            "contact_ids" => ["clear_contact_1"],
            "selected_contact_ids" => ["clear_contact_1"],
            "capacity_adjusted_throughput_mb" => 1.0,
            "source_station_calendar_entry" => %{
              "id" => "available_1",
              "availability" => "Available"
            }
          }
        ]
      })

    assert summary["station_calendar_entry_ids"] == [
             "available_1",
             "calendar_reserved_1",
             "calendar_reserved_1b",
             "calendar_reserved_2",
             "maintenance_1"
           ]

    assert summary["station_calendar_provider_ids"] == ["backup_calendar", "ops_calendar"]

    assert summary["station_calendar_provider_entry_ids"] == [
             "provider_reserved_1",
             "provider_reserved_1b"
           ]

    assert summary["station_reservation_ids"] == [
             "reservation_1",
             "reservation_1b",
             "reservation_2"
           ]

    assert summary["station_reserved_bys"] == ["backup_partner", "network_partner"]
    assert summary["station_reservation_statuses"] == ["confirmed", "held", "tentative"]

    assert summary["station_reservation_match_status_counts"] == %{
             "owned" => 1,
             "overlap" => 1,
             "unmatched" => 1
           }

    assert summary["ground_station_ids_by_station_availability"] == %{
             "reserved" => ["equator_prime"],
             "unavailable" => ["polar_prime"]
           }

    assert summary["ground_station_ids_by_reservation_match_status"] == %{
             "overlap" => ["equator_prime"],
             "owned" => ["polar_prime"],
             "unmatched" => ["equator_prime"]
           }

    assert summary["ground_station_ids_by_reservation_status"] == %{
             "confirmed" => ["polar_prime"],
             "held" => ["equator_prime"],
             "tentative" => ["equator_prime"]
           }

    assert summary["ground_station_ids_by_reserved_by"] == %{
             "backup_partner" => ["equator_prime"],
             "network_partner" => ["equator_prime"]
           }

    assert summary["station_calendar_entry_ids_by_ground_station_id"] == %{
             "clear_prime" => ["available_1"],
             "equator_prime" => ["calendar_reserved_1", "calendar_reserved_1b"],
             "polar_prime" => ["calendar_reserved_2", "maintenance_1"]
           }

    assert summary["station_calendar_provider_ids_by_ground_station_id"] == %{
             "equator_prime" => ["backup_calendar", "ops_calendar"]
           }

    assert summary["station_calendar_provider_entry_ids_by_ground_station_id"] == %{
             "equator_prime" => ["provider_reserved_1", "provider_reserved_1b"]
           }

    assert summary["station_reservation_ids_by_ground_station_id"] == %{
             "equator_prime" => ["reservation_1", "reservation_1b"],
             "polar_prime" => ["reservation_2"]
           }

    assert {:ok, %{"schema_contract" => "link_capacity_summary.v1"}} =
             Schema.validate_artifact(summary)
  end

  test "summary canonicalizes maintenance availability before reduced capacity" do
    summary =
      LinkCapacity.summary(%{
        "schema_contract" => "link_capacity_report.v1",
        "rows" => [
          %{
            "ground_station_id" => "equator_prime",
            "station_availability" => "maintenance",
            "capacity_fraction_min" => 0.5
          },
          %{
            "ground_station_id" => "polar_prime",
            "station_availability" => "offline",
            "capacity_fraction_min" => 0.25
          }
        ]
      })

    assert summary["ground_station_ids_by_station_availability"] == %{
             "unavailable" => ["equator_prime", "polar_prime"]
           }
  end

  test "carries contact feedback evidence into capacity policy, review, and import rows" do
    contacts = [
      %{
        id: :dl_failed_feedback,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0,
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
      }
    ]

    report =
      LinkCapacity.report(contacts, [],
        approval_policy: %{policy_bundle_id: "command_contact_authority_v1"}
      )

    assert [
             %{
               "ground_station_id" => "equator_prime",
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
           ] = report["rows"]

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

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_link_capacity_report(report)

    assert [
             %{
               "review_type" => "link_capacity_review",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "source_link_capacity" => %{
                 "contact_success" => false,
                 "contact_result" => "accepted,dropped",
                 "command_success" => false
               }
             }
           ] = review["rows"]

    manifest = CadenceImport.from_link_capacity_report(report)

    assert [
             %{
               "import_action" => "review_link_capacity",
               "contact_success" => false,
               "contact_result" => "accepted,dropped",
               "contact_success_factor" => 0.25,
               "contact_success_factor_source" => "operational_feedback_contact_success",
               "command_success" => false,
               "command_result" => "accepted,rejected",
               "command_success_factor" => 0.5,
               "command_success_factor_source" => "operational_feedback_command_success",
               "source_link_capacity" => %{
                 "contact_success" => false,
                 "contact_result" => "accepted,dropped",
                 "command_success" => false
               },
               "source_review_row" => %{
                 "contact_success" => false,
                 "contact_result" => "accepted,dropped",
                 "command_success" => false
               }
             }
           ] = manifest["rows"]
  end

  test "compares selected capacity against declared downlink requirements" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :dl_1,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0,
            station_capacity_fraction: 0.5
          },
          %{
            id: :dl_2,
            type: :downlink,
            ground_station_id: :new_mexico,
            estimated_throughput_mb: 80.0
          }
        ],
        [
          %{
            id: :dl_1,
            type: :downlink,
            ground_station_id: :equator_prime
          }
        ],
        policy: %{
          required_downlink_mb_by_ground_station: %{
            equator_prime: 75.0,
            new_mexico: 20.0
          }
        }
      )

    assert %{
             "required_downlink_mb" => 95.0,
             "selected_downlink_shortfall_mb" => 45.0,
             "downlink_requirement_status" => "shortfall"
           } = report

    assert [
             %{
               "ground_station_id" => "equator_prime",
               "required_downlink_mb" => 75.0,
               "selected_downlink_shortfall_mb" => 25.0,
               "downlink_requirement_status" => "shortfall"
             },
             %{
               "ground_station_id" => "new_mexico",
               "required_downlink_mb" => 20.0,
               "selected_downlink_shortfall_mb" => 20.0,
               "downlink_requirement_status" => "shortfall"
             }
           ] = report["rows"]

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_link_capacity_report(report)

    assert [
             %{
               "ground_station_id" => "equator_prime",
               "required_downlink_mb" => 75.0,
               "selected_downlink_shortfall_mb" => 25.0,
               "downlink_requirement_status" => "shortfall",
               "reason" => "review equator_prime downlink capacity shortfall of 25.0 MB"
             },
             %{
               "ground_station_id" => "new_mexico",
               "required_downlink_mb" => 20.0,
               "selected_downlink_shortfall_mb" => 20.0,
               "downlink_requirement_status" => "shortfall"
             }
           ] = review["rows"]

    manifest = CadenceImport.from_link_capacity_report(report)

    assert [
             %{
               "ground_station_id" => "equator_prime",
               "required_downlink_mb" => 75.0,
               "selected_downlink_shortfall_mb" => 25.0,
               "downlink_requirement_status" => "shortfall"
             },
             %{
               "ground_station_id" => "new_mexico",
               "required_downlink_mb" => 20.0,
               "selected_downlink_shortfall_mb" => 20.0,
               "downlink_requirement_status" => "shortfall"
             }
           ] = manifest["rows"]
  end

  test "emits station rows for policy-required stations without candidate contacts" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :dl_1,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0
          }
        ],
        [],
        policy: %{
          required_downlink_mb_by_ground_station: %{
            equator_prime: 40.0,
            hawaii: 15.0
          }
        }
      )

    assert %{
             "required_downlink_mb" => 55.0,
             "selected_downlink_shortfall_mb" => 55.0,
             "downlink_requirement_status" => "shortfall"
           } = report

    hawaii_row = Enum.find(report["rows"], &(&1["ground_station_id"] == "hawaii"))

    assert %{
             "ground_station_id" => "hawaii",
             "contact_count" => 0,
             "effective_contact_count" => 0,
             "selected_contact_count" => 0,
             "capacity_adjusted_throughput_mb" => 0,
             "selected_capacity_adjusted_throughput_mb" => 0,
             "selection_utilization_status" => "no_downlink_capacity",
             "required_downlink_mb" => 15.0,
             "selected_downlink_shortfall_mb" => 15.0,
             "downlink_requirement_status" => "shortfall"
           } = hawaii_row

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_link_capacity_report(report)

    assert Enum.any?(
             review["rows"],
             &match?(
               %{
                 "ground_station_id" => "hawaii",
                 "required_downlink_mb" => 15.0,
                 "selected_downlink_shortfall_mb" => 15.0,
                 "reason" => "review hawaii downlink capacity shortfall of 15.0 MB"
               },
               &1
             )
           )

    manifest = CadenceImport.from_link_capacity_report(report)

    assert Enum.any?(
             manifest["rows"],
             &match?(
               %{
                 "ground_station_id" => "hawaii",
                 "required_downlink_mb" => 15.0,
                 "selected_downlink_shortfall_mb" => 15.0,
                 "downlink_requirement_status" => "shortfall"
               },
               &1
             )
           )
  end

  test "preserves malformed station-scoped policy requirements as invalid metadata" do
    report =
      LinkCapacity.report(
        [
          %{
            id: :dl_1,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 100.0
          }
        ],
        [],
        policy: %{
          required_downlink_mb_by_ground_station: %{
            "equator_prime" => 40.0,
            "bad station" => 15.0
          }
        }
      )

    assert %{
             "required_downlink_mb" => 40.0,
             "selected_downlink_shortfall_mb" => 40.0,
             "downlink_requirement_status" => "shortfall",
             "invalid_policy_required_downlink_station_count" => 1,
             "invalid_policy_required_downlink_station_ids" => ["bad station"]
           } = report

    refute Enum.any?(report["rows"], &(&1["ground_station_id"] == "bad station"))

    assert [
             %{
               "ground_station_id" => "equator_prime",
               "required_downlink_mb" => 40.0,
               "selected_downlink_shortfall_mb" => 40.0,
               "downlink_requirement_status" => "shortfall"
             }
           ] = report["rows"]

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_link_capacity_report(report)

    assert Enum.any?(
             review["rows"],
             &match?(
               %{
                 "action" => "review_invalid_link_capacity_policy",
                 "required_operator_action" => "review_invalid_link_capacity_policy",
                 "invalid_policy_required_downlink_station_count" => 1,
                 "invalid_policy_required_downlink_station_ids" => ["bad station"],
                 "source_link_capacity" => %{
                   "invalid_policy_required_downlink_station_count" => 1,
                   "invalid_policy_required_downlink_station_ids" => ["bad station"]
                 }
               },
               &1
             )
           )

    manifest = CadenceImport.from_link_capacity_report(report)

    assert Enum.any?(
             manifest["rows"],
             &match?(
               %{
                 "source_review_action" => "review_invalid_link_capacity_policy",
                 "invalid_policy_required_downlink_station_count" => 1,
                 "invalid_policy_required_downlink_station_ids" => ["bad station"],
                 "source_link_capacity" => %{
                   "invalid_policy_required_downlink_station_count" => 1,
                   "invalid_policy_required_downlink_station_ids" => ["bad station"]
                 }
               },
               &1
             )
           )
  end

  test "uses per-contact downlink requirements when policy does not override them" do
    completion_sources = [
      "candidate_refresh.objectives.collection_latency",
      "operational_feedback_downlink_demand"
    ]

    contacts = [
      %{
        id: :dl_required_1,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0,
        station_capacity_fraction: 0.5,
        required_downlink_mb: 70.0,
        downlink_completion_sources: ["candidate_refresh.objectives.collection_latency"]
      },
      %{
        id: :dl_required_2,
        type: :planned_contact,
        direction: :downlink,
        ground_station_id: :new_mexico,
        estimated_throughput_mb: 30.0,
        throughput_model: %{
          required_downlink_mb: 20.0,
          downlink_completion_source: :operational_feedback_downlink_demand
        }
      },
      %{
        id: :dl_canceled,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 200.0,
        required_downlink_mb: 200.0,
        status: :canceled
      }
    ]

    report =
      LinkCapacity.report(contacts, [hd(contacts)],
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "required_downlink_mb" => 90.0,
             "required_downlink_contact_count" => 2,
             "required_downlink_contact_ids" => ["dl_required_1", "dl_required_2"],
             "downlink_completion_source" => "link_capacity.contact.required_downlink_mb",
             "downlink_completion_sources" => ^completion_sources,
             "selected_capacity_adjusted_throughput_mb" => 50.0,
             "selected_downlink_shortfall_mb" => 40.0,
             "downlink_requirement_status" => "shortfall"
           } = report

    equator_row =
      Enum.find(report["rows"], &(&1["ground_station_id"] == "equator_prime"))

    new_mexico_row =
      Enum.find(report["rows"], &(&1["ground_station_id"] == "new_mexico"))

    assert %{
             "required_downlink_mb" => 70.0,
             "required_downlink_contact_count" => 1,
             "required_downlink_contact_ids" => ["dl_required_1"],
             "downlink_completion_source" => "link_capacity.contact.required_downlink_mb",
             "downlink_completion_sources" => ["candidate_refresh.objectives.collection_latency"],
             "selected_downlink_shortfall_mb" => 20.0,
             "downlink_requirement_status" => "shortfall",
             "approval_requirements" => [
               %{
                 "activity_context" => %{
                   "downlink_completion_source" => "link_capacity.contact.required_downlink_mb",
                   "downlink_completion_sources" => [
                     "candidate_refresh.objectives.collection_latency"
                   ]
                 }
               }
             ]
           } = equator_row

    assert %{
             "required_downlink_mb" => 20.0,
             "required_downlink_contact_count" => 1,
             "required_downlink_contact_ids" => ["dl_required_2"],
             "downlink_completion_sources" => ["operational_feedback_downlink_demand"],
             "selected_downlink_shortfall_mb" => 20.0,
             "downlink_requirement_status" => "shortfall"
           } = new_mexico_row

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "required_downlink_contact_ids" => ["dl_required_1", "dl_required_2"],
             "required_downlink_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_required_1"],
               "new_mexico" => ["dl_required_2"]
             }
           } = LinkCapacity.summary(report)

    stale_required_summary_report =
      Map.put(report, "required_downlink_contact_ids", ["stale_required"])

    assert %{
             "required_downlink_contact_ids" => ["dl_required_1", "dl_required_2"],
             "required_downlink_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_required_1"],
               "new_mexico" => ["dl_required_2"]
             }
           } = LinkCapacity.summary(stale_required_summary_report)

    assert {:error, stale_required_report} =
             Schema.validate_artifact(stale_required_summary_report)

    assert Enum.any?(
             stale_required_report["errors"],
             &(&1["path"] == "$.required_downlink_contact_ids" and
                 &1["message"] == "must equal row-derived required_downlink_contact_ids")
           )

    stale_required_count_report = Map.put(report, "required_downlink_contact_count", 99)

    assert {:error, stale_required_count_errors} =
             Schema.validate_artifact(stale_required_count_report)

    assert Enum.any?(
             stale_required_count_errors["errors"],
             &(&1["path"] == "$.required_downlink_contact_count" and
                 &1["message"] == "must equal row-derived required_downlink_contact_count")
           )

    review = OperatorReview.from_link_capacity_report(report)

    assert Enum.any?(
             review["rows"],
             &match?(
               %{
                 "ground_station_id" => "equator_prime",
                 "required_downlink_contact_count" => 1,
                 "required_downlink_contact_ids" => ["dl_required_1"],
                 "downlink_completion_source" => "link_capacity.contact.required_downlink_mb",
                 "downlink_completion_sources" => [
                   "candidate_refresh.objectives.collection_latency"
                 ],
                 "reason" => "review equator_prime downlink capacity shortfall of 20.0 MB"
               },
               &1
             )
           )

    manifest = CadenceImport.from_link_capacity_report(report)

    assert Enum.any?(
             manifest["rows"],
             &match?(
               %{
                 "ground_station_id" => "equator_prime",
                 "required_downlink_contact_count" => 1,
                 "required_downlink_contact_ids" => ["dl_required_1"],
                 "downlink_completion_source" => "link_capacity.contact.required_downlink_mb",
                 "downlink_completion_sources" => [
                   "candidate_refresh.objectives.collection_latency"
                 ],
                 "source_link_capacity" => %{
                   "required_downlink_contact_ids" => ["dl_required_1"],
                   "downlink_completion_sources" => [
                     "candidate_refresh.objectives.collection_latency"
                   ]
                 }
               },
               &1
             )
           )
  end

  test "explicit downlink requirement policy overrides per-contact requirements" do
    contacts = [
      %{
        id: :dl_required_1,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 20.0,
        required_downlink_mb: 10.0
      }
    ]

    report =
      LinkCapacity.report(contacts, contacts, policy: %{required_downlink_mb: 100.0})

    assert %{
             "required_downlink_mb" => 100.0,
             "required_downlink_contact_count" => 1,
             "required_downlink_contact_ids" => ["dl_required_1"],
             "selected_downlink_shortfall_mb" => 80.0,
             "downlink_requirement_status" => "shortfall"
           } = report
  end

  test "reconciles actual throughput from uniquely matched selected downlinks" do
    contacts = [
      %{
        id: :dl_required_1,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0,
        required_downlink_mb: 75.0
      },
      %{
        id: :dl_required_2,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 50.0,
        required_downlink_mb: 25.0
      }
    ]

    selected_contacts = [
      %{
        id: :dl_required_1,
        type: :downlink,
        ground_station_id: :equator_prime,
        status: :completed,
        actual_throughput_mb: 40.0,
        completed_fraction: 0.4
      },
      %{
        id: :dl_required_2,
        type: :downlink,
        ground_station_id: :equator_prime,
        status: :completed,
        actual_throughput_mb: 25.0,
        throughput_model: %{contact_completion_fraction: 1.0}
      }
    ]

    report =
      LinkCapacity.report(contacts, selected_contacts,
        approval_policy: %{policy_bundle_id: "ground_network_allocation_v1"}
      )

    assert %{
             "required_downlink_mb" => 100.0,
             "selected_downlink_shortfall_mb" => 100.0,
             "actual_throughput_mb" => 65.0,
             "actual_throughput_contact_count" => 2,
             "actual_throughput_contact_ids" => ["dl_required_1", "dl_required_2"],
             "actual_completion_contact_count" => 2,
             "actual_completion_contact_ids" => ["dl_required_1", "dl_required_2"],
             "actual_downlink_shortfall_mb" => 35.0,
             "actual_downlink_completion_ratio" => 0.65,
             "actual_downlink_requirement_status" => "shortfall",
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "actual_throughput_mb" => 65.0,
                 "actual_throughput_contact_count" => 2,
                 "actual_throughput_contact_ids" => ["dl_required_1", "dl_required_2"],
                 "actual_completion_contact_count" => 2,
                 "actual_completion_contact_ids" => ["dl_required_1", "dl_required_2"],
                 "approval_status" => "operator_review_required",
                 "actual_downlink_shortfall_mb" => 35.0,
                 "actual_downlink_completion_ratio" => 0.65,
                 "actual_downlink_requirement_status" => "shortfall"
               }
             ]
           } = report

    assert_in_delta report["actual_completion_fraction"], 0.7, 1.0e-12
    assert_in_delta hd(report["rows"])["actual_completion_fraction"], 0.7, 1.0e-12
    assert report["selected_capacity_adjusted_throughput_mb"] == 0.0

    assert [
             %{
               "rule_id" => "low_actual_downlink_completion_review",
               "actual_completion_fraction" => actual_completion_fraction
             }
           ] = hd(report["rows"])["approval_rule_matches"]

    assert_in_delta actual_completion_fraction, 0.7, 1.0e-12

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    review = OperatorReview.from_link_capacity_report(report)

    assert [
             %{
               "actual_throughput_mb" => 65.0,
               "actual_throughput_contact_ids" => ["dl_required_1", "dl_required_2"],
               "actual_completion_contact_ids" => ["dl_required_1", "dl_required_2"],
               "actual_downlink_shortfall_mb" => 35.0,
               "actual_downlink_completion_ratio" => 0.65,
               "actual_downlink_requirement_status" => "shortfall",
               "reason" => "review equator_prime actual downlink throughput shortfall of 35.0 MB"
             }
           ] = review["rows"]

    assert_in_delta hd(review["rows"])["actual_completion_fraction"], 0.7, 1.0e-12

    manifest = CadenceImport.from_link_capacity_report(report)

    assert [
             %{
               "actual_throughput_mb" => 65.0,
               "actual_throughput_contact_count" => 2,
               "actual_throughput_contact_ids" => ["dl_required_1", "dl_required_2"],
               "actual_completion_contact_count" => 2,
               "actual_completion_contact_ids" => ["dl_required_1", "dl_required_2"],
               "actual_downlink_shortfall_mb" => 35.0,
               "actual_downlink_completion_ratio" => 0.65,
               "actual_downlink_requirement_status" => "shortfall",
               "source_review_row" => %{
                 "actual_throughput_mb" => 65.0,
                 "actual_completion_contact_count" => 2,
                 "actual_downlink_completion_ratio" => 0.65,
                 "actual_downlink_shortfall_mb" => 35.0
               }
             }
           ] = manifest["rows"]

    assert_in_delta hd(manifest["rows"])["actual_completion_fraction"], 0.7, 1.0e-12

    assert_in_delta get_in(hd(manifest["rows"]), [
                      "source_review_row",
                      "actual_completion_fraction"
                    ]),
                    0.7,
                    1.0e-12

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "reconciles selected actual throughput aliases" do
    contacts = [
      %{
        id: :dl_alias_1,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0,
        required_downlink_mb: 75.0
      },
      %{
        id: :dl_alias_2,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 50.0,
        required_downlink_mb: 25.0
      }
    ]

    selected_contacts = [
      %{
        id: :dl_alias_1,
        type: :downlink,
        ground_station_id: :equator_prime,
        status: :completed,
        delivered_data_mb: 40.0
      },
      %{
        id: :dl_alias_2,
        type: :downlink,
        ground_station_id: :equator_prime,
        status: :completed,
        throughput_model: %{received_data_mb: 25.0}
      }
    ]

    report = LinkCapacity.report(contacts, selected_contacts)

    assert %{
             "actual_throughput_mb" => 65.0,
             "actual_throughput_contact_count" => 2,
             "actual_throughput_contact_ids" => ["dl_alias_1", "dl_alias_2"],
             "actual_downlink_shortfall_mb" => 35.0,
             "actual_downlink_requirement_status" => "shortfall"
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes numeric string throughput capacity and completion evidence" do
    candidates = [
      %{
        id: :provider_dl,
        type: :downlink,
        scenario_id: :leo_1,
        station_id: :equator_prime,
        start_s: "100.0",
        end_s: "160.0",
        estimated_throughput_mb: "100.0",
        throughput_model: %{station_capacity_percent: "50"}
      }
    ]

    selected_contacts = [
      %{
        id: :provider_dl,
        type: :downlink,
        ground_station_id: :equator_prime,
        actual_throughput_mb: "40.0",
        completed_fraction: "0.4"
      }
    ]

    report = LinkCapacity.report(candidates, selected_contacts, source: "numeric_string_test")

    assert %{
             "contact_count" => 1,
             "selected_contact_count" => 1,
             "estimated_throughput_mb" => 100.0,
             "selected_estimated_throughput_mb" => 100.0,
             "capacity_adjusted_throughput_mb" => 50.0,
             "selected_capacity_adjusted_throughput_mb" => 50.0,
             "actual_throughput_mb" => 40.0,
             "actual_completion_fraction" => 0.4,
             "actual_throughput_contact_ids" => ["provider_dl"],
             "rows" => [
               %{
                 "ground_station_id" => "equator_prime",
                 "capacity_fraction_min" => 0.5,
                 "capacity_fraction_max" => 0.5,
                 "estimated_throughput_mb" => 100.0,
                 "capacity_adjusted_throughput_mb" => 50.0
               }
             ]
           } = report

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "routes unresolved selected actual throughput evidence for review" do
    contacts = [
      %{
        id: :unique_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0
      },
      %{
        id: :dup_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 40.0
      },
      %{
        id: :dup_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 60.0
      }
    ]

    selected_contacts = [
      %{
        id: :unique_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        status: :completed,
        actual_throughput_mb: 20.0,
        completed_fraction: 0.5
      },
      %{
        id: :missing_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        status: :completed,
        actual_throughput_mb: 8.0,
        completed_fraction: 0.25
      },
      %{
        id: :dup_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        status: :completed,
        actual_throughput_mb: 9.0,
        completed_fraction: 0.75
      }
    ]

    report =
      LinkCapacity.report(contacts, selected_contacts, policy: %{required_downlink_mb: 50.0})

    assert %{
             "actual_throughput_mb" => 20.0,
             "actual_throughput_contact_count" => 1,
             "actual_throughput_contact_ids" => ["unique_downlink"],
             "unmatched_actual_throughput_contact_count" => 1,
             "unmatched_actual_throughput_contact_ids" => ["missing_downlink"],
             "ambiguous_actual_throughput_contact_count" => 1,
             "ambiguous_actual_throughput_contact_ids" => ["dup_downlink"],
             "actual_completion_fraction" => 0.5,
             "actual_completion_contact_count" => 1,
             "actual_completion_contact_ids" => ["unique_downlink"],
             "unmatched_actual_completion_contact_count" => 1,
             "unmatched_actual_completion_contact_ids" => ["missing_downlink"],
             "ambiguous_actual_completion_contact_count" => 1,
             "ambiguous_actual_completion_contact_ids" => ["dup_downlink"],
             "actual_downlink_completion_ratio" => 0.4,
             "actual_downlink_shortfall_mb" => 30.0,
             "actual_downlink_requirement_status" => "shortfall"
           } = report

    assert report["assumptions"]["unresolved_actual_throughput_model"] =~
             "preserved as unmatched or ambiguous evidence"

    assert report["assumptions"]["unresolved_actual_completion_fraction_model"] =~
             "preserved as unmatched or ambiguous evidence"

    assert [
             %{
               "ground_station_id" => "equator_prime",
               "actual_throughput_contact_ids" => ["unique_downlink"],
               "unmatched_actual_throughput_contact_count" => 1,
               "unmatched_actual_throughput_contact_ids" => ["missing_downlink"],
               "ambiguous_actual_throughput_contact_count" => 1,
               "ambiguous_actual_throughput_contact_ids" => ["dup_downlink"],
               "actual_completion_contact_ids" => ["unique_downlink"],
               "unmatched_actual_completion_contact_count" => 1,
               "unmatched_actual_completion_contact_ids" => ["missing_downlink"],
               "ambiguous_actual_completion_contact_count" => 1,
               "ambiguous_actual_completion_contact_ids" => ["dup_downlink"]
             }
           ] = report["rows"]

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    stale_unresolved_summary_report =
      report
      |> Map.put("unmatched_actual_throughput_contact_ids", ["stale_missing_throughput"])
      |> Map.put("ambiguous_actual_throughput_contact_ids", ["stale_ambiguous_throughput"])
      |> Map.put("unmatched_actual_completion_contact_ids", ["stale_missing_completion"])
      |> Map.put("ambiguous_actual_completion_contact_ids", ["stale_ambiguous_completion"])

    assert %{
             "unmatched_actual_throughput_contact_count" => 1,
             "unmatched_actual_throughput_contact_ids" => ["missing_downlink"],
             "ambiguous_actual_throughput_contact_count" => 1,
             "ambiguous_actual_throughput_contact_ids" => ["dup_downlink"],
             "unmatched_actual_completion_contact_count" => 1,
             "unmatched_actual_completion_contact_ids" => ["missing_downlink"],
             "ambiguous_actual_completion_contact_count" => 1,
             "ambiguous_actual_completion_contact_ids" => ["dup_downlink"],
             "unmatched_actual_throughput_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["missing_downlink"]
             },
             "ambiguous_actual_throughput_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dup_downlink"]
             },
             "unmatched_actual_completion_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["missing_downlink"]
             },
             "ambiguous_actual_completion_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dup_downlink"]
             }
           } = LinkCapacity.summary(stale_unresolved_summary_report)

    assert {:error, stale_unresolved_errors} =
             Schema.validate_artifact(stale_unresolved_summary_report)

    assert Enum.any?(
             stale_unresolved_errors["errors"],
             &(&1["path"] == "$.unmatched_actual_throughput_contact_ids" and
                 &1["message"] ==
                   "must equal row-derived unmatched_actual_throughput_contact_ids")
           )

    assert Enum.any?(
             stale_unresolved_errors["errors"],
             &(&1["path"] == "$.ambiguous_actual_completion_contact_ids" and
                 &1["message"] ==
                   "must equal row-derived ambiguous_actual_completion_contact_ids")
           )

    stale_unresolved_count_report =
      report
      |> Map.put("unmatched_actual_throughput_contact_count", 99)
      |> Map.put("ambiguous_actual_throughput_contact_count", 99)
      |> Map.put("unmatched_actual_completion_contact_count", 99)
      |> Map.put("ambiguous_actual_completion_contact_count", 99)

    assert {:error, stale_unresolved_count_errors} =
             Schema.validate_artifact(stale_unresolved_count_report)

    assert %{
             "unmatched_actual_throughput_contact_count" => 1,
             "ambiguous_actual_throughput_contact_count" => 1,
             "unmatched_actual_completion_contact_count" => 1,
             "ambiguous_actual_completion_contact_count" => 1
           } = LinkCapacity.summary(stale_unresolved_count_report)

    assert Enum.any?(
             stale_unresolved_count_errors["errors"],
             &(&1["path"] == "$.unmatched_actual_throughput_contact_count" and
                 &1["message"] ==
                   "must equal row-derived unmatched_actual_throughput_contact_count")
           )

    assert Enum.any?(
             stale_unresolved_count_errors["errors"],
             &(&1["path"] == "$.ambiguous_actual_completion_contact_count" and
                 &1["message"] ==
                   "must equal row-derived ambiguous_actual_completion_contact_count")
           )

    review = OperatorReview.from_link_capacity_report(report)

    assert Enum.any?(
             review["rows"],
             &match?(
               %{
                 "source" => "link_capacity_report.unmatched_actual_throughput_contact_ids",
                 "required_operator_action" => "resolve_unmatched_actual_throughput_contacts",
                 "unmatched_actual_throughput_contact_count" => 1,
                 "unmatched_actual_throughput_contact_ids" => ["missing_downlink"],
                 "source_link_capacity" => %{
                   "unmatched_actual_throughput_contact_ids" => ["missing_downlink"]
                 }
               },
               &1
             )
           )

    assert Enum.any?(
             review["rows"],
             &match?(
               %{
                 "source" => "link_capacity_report.unmatched_actual_completion_contact_ids",
                 "required_operator_action" => "resolve_unmatched_actual_completion_contacts",
                 "unmatched_actual_completion_contact_count" => 1,
                 "unmatched_actual_completion_contact_ids" => ["missing_downlink"],
                 "source_link_capacity" => %{
                   "unmatched_actual_completion_contact_ids" => ["missing_downlink"]
                 }
               },
               &1
             )
           )

    assert Enum.any?(
             review["rows"],
             &match?(
               %{
                 "source" => "link_capacity_report.ambiguous_actual_throughput_contact_ids",
                 "required_operator_action" => "resolve_ambiguous_actual_throughput_contacts",
                 "ambiguous_actual_throughput_contact_count" => 1,
                 "ambiguous_actual_throughput_contact_ids" => ["dup_downlink"],
                 "source_link_capacity" => %{
                   "ambiguous_actual_throughput_contact_ids" => ["dup_downlink"]
                 }
               },
               &1
             )
           )

    assert Enum.any?(
             review["rows"],
             &match?(
               %{
                 "source" => "link_capacity_report.ambiguous_actual_completion_contact_ids",
                 "required_operator_action" => "resolve_ambiguous_actual_completion_contacts",
                 "ambiguous_actual_completion_contact_count" => 1,
                 "ambiguous_actual_completion_contact_ids" => ["dup_downlink"],
                 "source_link_capacity" => %{
                   "ambiguous_actual_completion_contact_ids" => ["dup_downlink"]
                 }
               },
               &1
             )
           )

    manifest = CadenceImport.from_link_capacity_report(report)

    assert Enum.any?(
             manifest["rows"],
             &match?(
               %{
                 "import_action" => "review_link_capacity",
                 "source" => "link_capacity_report.unmatched_actual_throughput_contact_ids",
                 "required_operator_action" => "resolve_unmatched_actual_throughput_contacts",
                 "unmatched_actual_throughput_contact_ids" => ["missing_downlink"],
                 "source_review_row" => %{
                   "unmatched_actual_throughput_contact_ids" => ["missing_downlink"]
                 }
               },
               &1
             )
           )

    assert Enum.any?(
             manifest["rows"],
             &match?(
               %{
                 "import_action" => "review_link_capacity",
                 "source" => "link_capacity_report.unmatched_actual_completion_contact_ids",
                 "required_operator_action" => "resolve_unmatched_actual_completion_contacts",
                 "unmatched_actual_completion_contact_ids" => ["missing_downlink"],
                 "source_review_row" => %{
                   "unmatched_actual_completion_contact_ids" => ["missing_downlink"]
                 }
               },
               &1
             )
           )

    assert Enum.any?(
             manifest["rows"],
             &match?(
               %{
                 "import_action" => "review_link_capacity",
                 "source" => "link_capacity_report.ambiguous_actual_throughput_contact_ids",
                 "required_operator_action" => "resolve_ambiguous_actual_throughput_contacts",
                 "ambiguous_actual_throughput_contact_ids" => ["dup_downlink"],
                 "source_review_row" => %{
                   "ambiguous_actual_throughput_contact_ids" => ["dup_downlink"]
                 }
               },
               &1
             )
           )

    assert Enum.any?(
             manifest["rows"],
             &match?(
               %{
                 "import_action" => "review_link_capacity",
                 "source" => "link_capacity_report.ambiguous_actual_completion_contact_ids",
                 "required_operator_action" => "resolve_ambiguous_actual_completion_contacts",
                 "ambiguous_actual_completion_contact_ids" => ["dup_downlink"],
                 "source_review_row" => %{
                   "ambiguous_actual_completion_contact_ids" => ["dup_downlink"]
                 }
               },
               &1
             )
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "omits station unresolved actual evidence fields when no unresolved feedback exists" do
    contacts = [
      %{
        id: :unique_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        estimated_throughput_mb: 100.0
      }
    ]

    selected_contacts = [
      %{
        id: :unique_downlink,
        type: :downlink,
        ground_station_id: :equator_prime,
        status: :completed,
        actual_throughput_mb: 20.0,
        completed_fraction: 0.5
      }
    ]

    report = LinkCapacity.report(contacts, selected_contacts)

    assert [
             %{
               "ground_station_id" => "equator_prime",
               "actual_throughput_contact_ids" => ["unique_downlink"],
               "actual_completion_contact_ids" => ["unique_downlink"]
             } = row
           ] = report["rows"]

    refute Map.has_key?(row, "unmatched_actual_throughput_contact_count")
    refute Map.has_key?(row, "unmatched_actual_throughput_contact_ids")
    refute Map.has_key?(row, "ambiguous_actual_throughput_contact_count")
    refute Map.has_key?(row, "ambiguous_actual_throughput_contact_ids")
    refute Map.has_key?(row, "unmatched_actual_completion_contact_count")
    refute Map.has_key?(row, "unmatched_actual_completion_contact_ids")
    refute Map.has_key?(row, "ambiguous_actual_completion_contact_count")
    refute Map.has_key?(row, "ambiguous_actual_completion_contact_ids")

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "public facade builds link capacity reports" do
    report =
      OrbitalDynamics.link_capacity_report(
        [
          %{
            id: :dl_1,
            type: :downlink,
            ground_station_id: :equator_prime,
            estimated_throughput_mb: 10.0
          }
        ],
        [],
        source: "facade_test"
      )

    assert %{
             "source" => "facade_test",
             "contact_count" => 1,
             "selected_contact_count" => 0,
             "rows" => [%{"contact_ids" => ["dl_1"], "selected_contact_ids" => []}]
           } = report

    refute Enum.any?(report, fn {_key, value} -> is_nil(value) end)

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)

    assert LinkCapacity.report(report) == report
    assert OrbitalDynamics.link_capacity_report(report) == report

    atom_keyed_report =
      Map.new(report, fn {key, value} -> {String.to_atom(key), value} end)

    assert LinkCapacity.report(atom_keyed_report) == report
    assert OrbitalDynamics.link_capacity_report(atom_keyed_report) == report
  end

  test "returns empty capacity report when no downlink contacts are present" do
    report =
      LinkCapacity.report([
        %{id: :obs_1, type: :observe, target_id: :target_alpha},
        %{id: :cmd_1, type: :command, ground_station_id: :equator_prime}
      ])

    assert report["contact_count"] == 0
    assert report["selected_contact_count"] == 0
    assert report["estimated_throughput_mb"] == 0
    assert report["selected_estimated_throughput_mb"] == 0
    assert report["capacity_adjusted_throughput_mb"] == 0
    assert report["selected_capacity_adjusted_throughput_mb"] == 0
    assert report["unused_capacity_adjusted_throughput_mb"] == 0.0
    assert report["selected_capacity_utilization_fraction"] == 0.0
    assert report["selection_utilization_status"] == "no_downlink_capacity"
    assert report["rows"] == []

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "preserves downlink contacts without stable IDs for review" do
    report =
      LinkCapacity.report([
        %{
          type: :downlink,
          ground_station_id: :equator_prime,
          estimated_throughput_mb: 10.0
        }
      ])

    assert %{
             "contact_count" => 0,
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

    assert {:ok, %{"schema_contract" => "link_capacity_report.v1"}} =
             Schema.validate_artifact(report)
  end

  defp link_capacity_capability_assumptions do
    capabilities = LinkCapacity.capabilities()

    %{
      "station_unavailable_aliases" => capabilities.station_unavailable_aliases,
      "station_availability_precedence" => capabilities.station_availability_precedence,
      "station_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.station_capacity_value_paths),
      "source_station_capacity_value_paths" =>
        json_capacity_value_paths(capabilities.source_station_capacity_value_paths),
      "provider_direction_aliases" => capabilities.provider_direction_aliases
    }
  end

  defp json_capacity_value_paths(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp drop_link_capacity_capability_assumptions(artifact) do
    update_in(artifact, ["assumptions"], fn assumptions ->
      Map.drop(assumptions, [
        "station_unavailable_aliases",
        "station_availability_precedence",
        "station_capacity_value_paths",
        "source_station_capacity_value_paths",
        "provider_direction_aliases"
      ])
    end)
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
