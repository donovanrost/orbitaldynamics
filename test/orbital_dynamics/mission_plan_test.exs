defmodule OrbitalDynamics.MissionPlanTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.MissionPlan
  alias OrbitalDynamics.MissionPlan.Activity
  alias OrbitalDynamics.{Epoch, Frame, Scenario, Spacecraft, StateVector}

  test "declares typed activity precondition semantics for public facades" do
    assert %{
             precondition_statuses: precondition_statuses,
             precondition_types: precondition_types,
             precondition_row_semantics: precondition_row_semantics,
             public_facades: public_facades
           } = Activity.capabilities()

    assert precondition_statuses == ["blocked", "clear", "review_required"]
    assert "payload_unavailable" in precondition_types
    assert "fuel_margin_depleted" in precondition_types
    assert "resource_block_declared" in precondition_types
    assert "activity_type_incompatible" in precondition_types
    assert "command_authority_missing" in precondition_types
    assert "command_safety_failed" in precondition_types
    assert "command_safety_unchecked" in precondition_types
    assert "degraded_mode" in precondition_types
    assert "subsystem_state_required" in precondition_types
    assert :precondition_rows in precondition_row_semantics
    assert :blocked_precondition_types in precondition_row_semantics
    assert :mission_plan_activity_precondition_summary in public_facades

    assert %{planning: %{mission_plan_activity: %{precondition_types: ^precondition_types}}} =
             OrbitalDynamics.capability_catalog()

    summary =
      OrbitalDynamics.mission_plan_activity_precondition_summary(%{
        "id" => "cmd_preflight",
        "activity_type" => "command",
        "starts_at_s" => 0.0,
        "ends_at_s" => 10.0,
        "payload_available" => "false",
        "degraded" => "true",
        "fuel_margin" => "0.0",
        "resource_blocking_dimension" => "payload_power",
        "incompatible_activity_types" => "command",
        "metadata" => %{
          "command_authority_status" => "operator_required",
          "required_authority" => "flight_director",
          "command_authorized" => "false",
          "command_safety_status" => "unsafe",
          "command_safety_checked" => "false",
          "activity_template" => %{
            "schema_contract" => "activity_template.v1",
            "id" => "command_template",
            "activity_type" => "command",
            "subsystem_state_hints" => %{
              "required_states" => [
                %{"subsystem" => "thermal"},
                %{
                  "subsystem" => "commanding",
                  "state" => "armed",
                  "reason" => "template requires armed commanding state",
                  "blocking" => true
                }
              ],
              "produced_states" => [
                %{"subsystem" => "commanding", "state" => "executed"}
              ]
            }
          }
        }
      })

    assert %{
             "model" => "typed_activity_precondition_summary",
             "activity_id" => "cmd_preflight",
             "activity_type" => "command",
             "precondition_status" => "blocked",
             "blocked_precondition_types" => blocked_types,
             "review_precondition_types" => [
               "command_authority_missing",
               "command_safety_unchecked",
               "degraded_mode",
               "subsystem_state_required"
             ],
             "preconditions" => preconditions
           } = summary

    assert Enum.sort(blocked_types) == [
             "activity_type_incompatible",
             "command_safety_failed",
             "fuel_margin_depleted",
             "payload_unavailable",
             "resource_block_declared"
           ]

    assert Enum.all?(preconditions, &(&1["status"] in precondition_statuses))
    assert Enum.all?(preconditions, &(&1["type"] in precondition_types))

    assert %{
             "type" => "subsystem_state_required",
             "status" => "review_required",
             "field" => "activity_template.subsystem_state_hints.required_states[1]",
             "reason" => "template requires armed commanding state",
             "value" => %{
               "subsystem" => "commanding",
               "state" => "armed",
               "blocking" => true
             }
           } in preconditions

    assert %{
             "type" => "command_authority_missing",
             "status" => "review_required",
             "field" => "command_authorized",
             "reason" => "command authority is explicitly not granted",
             "value" => false
           } in preconditions

    assert %{
             "type" => "command_safety_failed",
             "status" => "blocked",
             "field" => "command_safety_status",
             "reason" => "command safety status is explicitly unsafe or failed",
             "value" => "unsafe"
           } in preconditions

    assert %{
             "type" => "command_safety_unchecked",
             "status" => "review_required",
             "field" => "command_safety_checked",
             "reason" => "command safety check requires review before command handoff",
             "value" => false
           } in preconditions

    refute Enum.any?(preconditions, &(&1["type"] == "subsystem_state_produced"))
  end

  test "round trips collection latency objective context through typed activities" do
    activity =
      Activity.from_map!(%{
        "id" => "obs_latency_objective",
        "activity_type" => "observe",
        "target_id" => "target_a",
        "starts_at_s" => 10.0,
        "ends_at_s" => 40.0,
        "collection_latency_objective_count" => "2",
        "collection_latency_objective_ids" => "objective:delivery_latency,objective:customer_sla",
        "collection_latency_objective_source" => "mission_sla",
        "collection_latency_objective_types" => ["max latency", :customer_delivery]
      })

    assert %Activity{
             collection_latency_objective_count: 2,
             collection_latency_objective_ids: [
               "objective:delivery_latency",
               "objective:customer_sla"
             ],
             collection_latency_objective_source: "mission_sla",
             collection_latency_objective_types: ["max latency", :customer_delivery]
           } = activity

    assert %{
             "collection_latency_objective_count" => 2,
             "collection_latency_objective_ids" => [
               "objective:delivery_latency",
               "objective:customer_sla"
             ],
             "collection_latency_objective_source" => "mission_sla",
             "collection_latency_objective_types" => ["max latency", "customer_delivery"]
           } = Activity.to_artifact_map(activity)

    report = OrbitalDynamics.Timeline.operational_report([activity])

    assert %{
             "activity_context" => %{
               "collection_latency_objective_count" => 2,
               "collection_latency_objective_ids" => [
                 "objective:delivery_latency",
                 "objective:customer_sla"
               ],
               "collection_latency_objective_source" => "mission_sla",
               "collection_latency_objective_types" => ["max latency", "customer_delivery"]
             }
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(report)
  end

  test "round trips observation objective context through typed activities" do
    activity =
      Activity.from_map!(%{
        "id" => "obs_objective_context",
        "activity_type" => "observe",
        "target_id" => "target_a",
        "starts_at_s" => 50.0,
        "ends_at_s" => 90.0,
        "observation_objective_count" => "2",
        "observation_objective_ids" => "objective:target_coverage,objective:image_quality",
        "observation_objective_source" => "campaign_objectives",
        "observation_objective_types" => ["target coverage", :image_quality]
      })

    assert %Activity{
             observation_objective_count: 2,
             observation_objective_ids: [
               "objective:target_coverage",
               "objective:image_quality"
             ],
             observation_objective_source: "campaign_objectives",
             observation_objective_types: ["target coverage", :image_quality]
           } = activity

    assert %{
             "observation_objective_count" => 2,
             "observation_objective_ids" => [
               "objective:target_coverage",
               "objective:image_quality"
             ],
             "observation_objective_source" => "campaign_objectives",
             "observation_objective_types" => ["target coverage", "image_quality"]
           } = Activity.to_artifact_map(activity)

    report = OrbitalDynamics.Timeline.operational_report([activity])

    assert %{
             "activity_context" => %{
               "observation_objective_count" => 2,
               "observation_objective_ids" => [
                 "objective:target_coverage",
                 "objective:image_quality"
               ],
               "observation_objective_source" => "campaign_objectives",
               "observation_objective_types" => ["target coverage", "image_quality"]
             }
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(report)
  end

  test "round trips station capacity fraction context through typed activities" do
    activity =
      Activity.from_map!(%{
        "id" => "reduced_capacity_contact",
        "activity_type" => "planned_contact",
        "ground_station_id" => "gs_a",
        "direction" => "downlink",
        "starts_at_s" => 100.0,
        "ends_at_s" => 160.0,
        "capacity_fraction" => "0.75",
        "station_capacity_fraction" => 0.5,
        "capacity_pack_capacity_fraction" => "0.4"
      })

    assert %Activity{
             capacity_fraction: 0.75,
             station_capacity_fraction: 0.5,
             capacity_pack_capacity_fraction: 0.4
           } = activity

    assert %{
             "capacity_fraction" => 0.75,
             "station_capacity_fraction" => 0.5,
             "capacity_pack_capacity_fraction" => 0.4
           } = Activity.to_artifact_map(activity)

    report = OrbitalDynamics.Timeline.operational_report([activity])

    assert %{
             "activity_context" => %{
               "capacity_fraction" => 0.75,
               "station_capacity_fraction" => 0.5,
               "capacity_pack_capacity_fraction" => 0.4
             }
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(report)
  end

  test "round trips station calendar identity and status context through typed activities" do
    activity =
      Activity.from_map!(%{
        "id" => "reserved_provider_contact",
        "activity_type" => "planned_contact",
        "ground_station_id" => "gs_a",
        "direction" => "downlink",
        "starts_at_s" => 170.0,
        "ends_at_s" => 230.0,
        "station_availability" => :reserved,
        "station_calendar_entry_id" => "calendar:entry_a",
        "station_calendar_provider_id" => "provider:partner_a",
        "station_calendar_provider_entry_id" => "provider_entry:partner_a:170",
        "station_calendar_status" => :reserved_overlap,
        "station_calendar_trust_boundary_status" => "declared"
      })

    assert %Activity{
             station_availability: :reserved,
             station_calendar_entry_id: "calendar:entry_a",
             station_calendar_provider_id: "provider:partner_a",
             station_calendar_provider_entry_id: "provider_entry:partner_a:170",
             station_calendar_status: :reserved_overlap,
             station_calendar_trust_boundary_status: "declared"
           } = activity

    assert %{
             "station_availability" => "reserved",
             "station_calendar_entry_id" => "calendar:entry_a",
             "station_calendar_provider_id" => "provider:partner_a",
             "station_calendar_provider_entry_id" => "provider_entry:partner_a:170",
             "station_calendar_status" => "reserved_overlap",
             "station_calendar_trust_boundary_status" => "declared"
           } = Activity.to_artifact_map(activity)

    report = OrbitalDynamics.Timeline.operational_report([activity])

    assert %{
             "activity_context" => %{
               "station_availability" => "reserved",
               "station_calendar_entry_id" => "calendar:entry_a",
               "station_calendar_provider_id" => "provider:partner_a",
               "station_calendar_provider_entry_id" => "provider_entry:partner_a:170",
               "station_calendar_status" => "reserved_overlap",
               "station_calendar_trust_boundary_status" => "declared"
             }
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(report)
  end

  test "round trips station calendar directions and source entry through typed activities" do
    activity =
      Activity.from_map!(%{
        "id" => "provider_direction_contact",
        "activity_type" => "planned_contact",
        "ground_station_id" => "gs_a",
        "direction" => "downlink",
        "starts_at_s" => 240.0,
        "ends_at_s" => 300.0,
        "station_calendar_directions" => "downlink",
        "source_station_calendar_entry" => %{
          "id" => "calendar:source_entry_a",
          "station_calendar_provider_id" => "provider:partner_a",
          "direction" => "command",
          "availability" => "reserved"
        }
      })

    assert %Activity{
             station_calendar_directions: ["downlink"],
             source_station_calendar_entry: %{
               "id" => "calendar:source_entry_a",
               "station_calendar_provider_id" => "provider:partner_a",
               "direction" => "command",
               "availability" => "reserved"
             }
           } = activity

    assert %{
             "station_calendar_directions" => ["downlink"],
             "source_station_calendar_entry" => %{
               "id" => "calendar:source_entry_a",
               "station_calendar_provider_id" => "provider:partner_a",
               "direction" => "command",
               "availability" => "reserved"
             }
           } = Activity.to_artifact_map(activity)

    report = OrbitalDynamics.Timeline.operational_report([activity])

    assert %{
             "activity_context" => %{
               "station_calendar_directions" => ["command", "downlink"],
               "station_calendar_entry_id" => "calendar:source_entry_a",
               "source_station_calendar_entry" => %{
                 "id" => "calendar:source_entry_a",
                 "station_calendar_provider_id" => "provider:partner_a",
                 "direction" => "command",
                 "availability" => "reserved"
               }
             }
           } = List.first(report["rows"])

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             OrbitalDynamics.Schema.validate_artifact(report)
  end

  test "rejects malformed collection latency objective context at typed ingress" do
    assert_raise ArgumentError, ~r/collection_latency_objective_count/, fn ->
      Activity.from_map!(%{
        "id" => "bad_latency_count",
        "activity_type" => "observe",
        "target_id" => "target_a",
        "starts_at_s" => 10.0,
        "ends_at_s" => 40.0,
        "collection_latency_objective_count" => "-1"
      })
    end

    assert_raise ArgumentError, ~r/collection_latency_objective_ids/, fn ->
      Activity.from_map!(%{
        "id" => "bad_latency_objective_id",
        "activity_type" => "observe",
        "target_id" => "target_a",
        "starts_at_s" => 10.0,
        "ends_at_s" => 40.0,
        "collection_latency_objective_ids" => ["bad objective id"]
      })
    end
  end

  test "rejects malformed observation objective context at typed ingress" do
    assert_raise ArgumentError, ~r/observation_objective_count/, fn ->
      Activity.from_map!(%{
        "id" => "bad_observation_objective_count",
        "activity_type" => "observe",
        "target_id" => "target_a",
        "starts_at_s" => 10.0,
        "ends_at_s" => 40.0,
        "observation_objective_count" => "-1"
      })
    end

    assert_raise ArgumentError, ~r/observation_objective_ids/, fn ->
      Activity.from_map!(%{
        "id" => "bad_observation_objective_id",
        "activity_type" => "observe",
        "target_id" => "target_a",
        "starts_at_s" => 10.0,
        "ends_at_s" => 40.0,
        "observation_objective_ids" => ["bad objective id"]
      })
    end
  end

  test "rejects malformed station capacity fraction context at typed ingress" do
    for {field, value} <- [
          {"capacity_fraction", "1.1"},
          {"station_capacity_fraction", -0.1},
          {"capacity_pack_capacity_fraction", "not-a-number"}
        ] do
      assert_raise ArgumentError, ~r/#{field}/, fn ->
        Activity.from_map!(%{
          "id" => "bad_#{field}",
          "activity_type" => "planned_contact",
          "ground_station_id" => "gs_a",
          "direction" => "downlink",
          "starts_at_s" => 10.0,
          "ends_at_s" => 40.0,
          field => value
        })
      end
    end
  end

  test "rejects malformed station calendar identity and status context at typed ingress" do
    for {field, value} <- [
          {"station_calendar_entry_id", "bad calendar id"},
          {"station_calendar_provider_id", "bad provider id"},
          {"station_calendar_provider_entry_id", "bad provider entry id"},
          {"station_availability", ""},
          {"station_calendar_status", ""},
          {"station_calendar_trust_boundary_status", ""}
        ] do
      assert_raise ArgumentError, ~r/#{field}/, fn ->
        Activity.from_map!(%{
          "id" => "bad_#{field}",
          "activity_type" => "planned_contact",
          "ground_station_id" => "gs_a",
          "direction" => "downlink",
          "starts_at_s" => 10.0,
          "ends_at_s" => 40.0,
          field => value
        })
      end
    end
  end

  test "rejects malformed station calendar directions and source entry at typed ingress" do
    assert_raise ArgumentError, ~r/station_calendar_directions/, fn ->
      Activity.from_map!(%{
        "id" => "bad_station_calendar_directions",
        "activity_type" => "planned_contact",
        "ground_station_id" => "gs_a",
        "direction" => "downlink",
        "starts_at_s" => 10.0,
        "ends_at_s" => 40.0,
        "station_calendar_directions" => [%{"direction" => "downlink"}]
      })
    end

    assert_raise ArgumentError, ~r/source_station_calendar_entry/, fn ->
      Activity.from_map!(%{
        "id" => "bad_source_station_calendar_entry",
        "activity_type" => "planned_contact",
        "ground_station_id" => "gs_a",
        "direction" => "downlink",
        "starts_at_s" => 10.0,
        "ends_at_s" => 40.0,
        "source_station_calendar_entry" => ["not", "a", "map"]
      })
    end
  end

  test "preflights typed activity transitions through public facades" do
    completed_activity = %{
      "id" => "obs_alias",
      "activity_type" => "observe",
      "starts_at_s" => 0.0,
      "ends_at_s" => 10.0,
      "target_id" => "target_a",
      "status" => "succeeded",
      "approval_status" => "Review Required"
    }

    assert %{
             "model" => "typed_activity_status_transition_validation",
             "field" => "status",
             "from" => "completed",
             "to" => "partial",
             "from_category" => "terminal_or_executed",
             "to_category" => "terminal_or_executed",
             "safe_to_apply" => false,
             "requires_operator_review" => true,
             "operator_action_reason" => "terminal_or_executed_status_change_requires_review",
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_transition_validation"
             }
           } =
             OrbitalDynamics.mission_plan_activity_status_transition(
               completed_activity,
               "partially executed"
             )

    assert_raise ArgumentError,
                 ~r/unsafe lifecycle status transition completed -> partial/,
                 fn ->
                   OrbitalDynamics.mission_plan_activity_transition_status(
                     completed_activity,
                     "partially executed"
                   )
                 end

    executing_activity = %{completed_activity | "status" => "In Progress"}

    assert %Activity{status: :failed} =
             OrbitalDynamics.mission_plan_activity_transition_status(
               executing_activity,
               "timed-out"
             )

    assert %{
             "model" => "typed_activity_approval_transition_validation",
             "field" => "approval_status",
             "from" => "operator_review_required",
             "to" => "approved",
             "from_category" => "review_required",
             "to_category" => "approval_granted",
             "safe_to_apply" => false,
             "requires_operator_review" => true,
             "operator_action_reason" => "approval_grant_requires_operator_authority"
           } =
             OrbitalDynamics.mission_plan_activity_approval_transition(
               completed_activity,
               "approved"
             )

    assert_raise ArgumentError,
                 ~r/unsafe approval status transition operator_review_required -> approved/,
                 fn ->
                   OrbitalDynamics.mission_plan_activity_transition_approval_status(
                     completed_activity,
                     "approved"
                   )
                 end

    review_activity = %{completed_activity | "approval_status" => "No Review Required"}

    assert %Activity{approval_status: :operator_review_required} =
             OrbitalDynamics.mission_plan_activity_transition_approval_status(
               review_activity,
               "under review"
             )
  end

  test "compiles timeline burns into scenario maneuvers and preserves activity metadata" do
    plan =
      MissionPlan.new!(:ops_plan, spacecraft(), initial_state(),
        horizon_s: 180.0,
        output_step_s: 60.0,
        activities: [
          Activity.coast!(:initial_coast, 0.0, 50.0),
          Activity.impulsive_burn!(:raise_apogee, 60.0, {0.0, 0.01, 0.0},
            execution_uncertainty: %{timing_3sigma_s: 2.0}
          ),
          Activity.observe!(:observe_target, 90.0, 120.0, :target_a),
          Activity.downlink!(:downlink_pass, 130.0, 160.0, :dss_14)
        ],
        metadata: %{objective: :checkout}
      )

    assert {:ok, %Scenario{} = scenario} = MissionPlan.to_scenario(plan)
    assert scenario.id == :ops_plan
    assert scenario.duration_s == 180.0
    assert scenario.output_step_s == 60.0

    assert [maneuver] = scenario.maneuvers
    assert maneuver.id == :raise_apogee
    assert maneuver.epoch.seconds_since_j2000 == 60.0
    assert maneuver.delta_v_km_s == {0.0, 0.01, 0.0}

    assert %{execution_uncertainty: %{timing_3sigma_s: 2.0}} =
             get_in(scenario.metadata, [:mission_plan, :activities])
             |> Enum.find(&(&1.id == :raise_apogee))

    assert %{scenario_id: :ops_plan, spacecraft_id: :sat_1} =
             get_in(scenario.metadata, [:mission_plan, :activities])
             |> Enum.find(&(&1.id == :downlink_pass))

    assert get_in(scenario.metadata, [:mission_plan, :metadata]) == %{objective: :checkout}

    assert [
             %{id: :initial_coast, type: :coast},
             %{id: :observe_target, type: :observe},
             %{id: :downlink_pass, type: :downlink}
           ] = get_in(scenario.metadata, [:mission_plan, :non_dynamics_activities])
  end

  test "compiled scenario runs through existing propagation" do
    plan =
      MissionPlan.new!(:burn_plan, spacecraft(), initial_state(),
        horizon_s: 120.0,
        output_step_s: 60.0,
        activities: [
          Activity.impulsive_burn!(:raise_apogee, 55.0, {0.0, 0.01, 0.0})
        ]
      )

    scenario = MissionPlan.to_scenario!(plan)

    assert {:ok, trajectory} = OrbitalDynamics.propagate(scenario, max_step_s: 10.0)
    assert trajectory.scenario_id == :burn_plan
    assert trajectory.assumptions.maneuver_count == 1
  end

  test "rejects overlapping interval activities unless overlap is explicit" do
    assert_raise ArgumentError, ~r/overlapping_activities/, fn ->
      MissionPlan.new!(:bad_plan, spacecraft(), initial_state(),
        horizon_s: 120.0,
        output_step_s: 60.0,
        activities: [
          Activity.observe!(:observe, 10.0, 40.0, :target_a),
          Activity.downlink!(:downlink, 20.0, 50.0, :dss_14)
        ]
      )
    end

    plan =
      MissionPlan.new!(:allowed_plan, spacecraft(), initial_state(),
        horizon_s: 120.0,
        output_step_s: 60.0,
        activities: [
          Activity.observe!(:observe, 10.0, 40.0, :target_a, allow_overlap?: true),
          Activity.downlink!(:downlink, 20.0, 50.0, :dss_14)
        ]
      )

    assert :ok = MissionPlan.validate(plan)
  end

  test "rejects activity scope that conflicts with the parent mission plan" do
    assert_raise ArgumentError, ~r/activity_scope_conflict/, fn ->
      MissionPlan.new!(:ops_plan, spacecraft(), initial_state(),
        horizon_s: 120.0,
        output_step_s: 60.0,
        activities: [
          Activity.observe!(:observe, 10.0, 40.0, :target_a, spacecraft_id: :other_sat)
        ]
      )
    end
  end

  test "rejects missing dependency activity references before compilation" do
    assert_raise ArgumentError,
                 ~r/activity_timeline_integrity.*missing_dependency_activity/,
                 fn ->
                   MissionPlan.new!(:dependency_plan, spacecraft(), initial_state(),
                     horizon_s: 120.0,
                     output_step_s: 60.0,
                     activities: [
                       Activity.command!(:cmd_execute, 30.0, 40.0,
                         dependency_activity_ids: [:cmd_prepare]
                       )
                     ]
                   )
                 end
  end

  test "rejects missing dependency timeline references before compilation" do
    assert_raise ArgumentError,
                 ~r/activity_timeline_integrity.*missing_dependency_timeline/,
                 fn ->
                   MissionPlan.new!(:dependency_timeline_plan, spacecraft(), initial_state(),
                     horizon_s: 120.0,
                     output_step_s: 60.0,
                     activities: [
                       Activity.command!(:cmd_execute, 30.0, 40.0,
                         dependency_timeline_ids: ["timeline:cmd_prepare"]
                       )
                     ]
                   )
                 end
  end

  test "rejects dependency order violations before compilation" do
    assert_raise ArgumentError, ~r/activity_timeline_integrity.*dependency_order_violation/, fn ->
      MissionPlan.new!(:dependency_order_plan, spacecraft(), initial_state(),
        horizon_s: 120.0,
        output_step_s: 60.0,
        activities: [
          Activity.command!(:cmd_prepare, 50.0, 60.0),
          Activity.command!(:cmd_execute, 30.0, 40.0, dependency_activity_ids: [:cmd_prepare])
        ]
      )
    end
  end

  test "rejects dependency cycles before compilation" do
    assert_raise ArgumentError, ~r/activity_timeline_integrity.*dependency_cycle/, fn ->
      MissionPlan.new!(:dependency_cycle_plan, spacecraft(), initial_state(),
        horizon_s: 120.0,
        output_step_s: 60.0,
        activities: [
          Activity.command!(:cmd_prepare, 10.0, 20.0, dependency_activity_ids: [:cmd_execute]),
          Activity.command!(:cmd_execute, 30.0, 40.0, dependency_activity_ids: [:cmd_prepare])
        ]
      )
    end
  end

  test "rejects explicit exclusivity overlaps even when generic overlap is allowed" do
    assert_raise ArgumentError, ~r/activity_timeline_integrity.*exclusivity_overlap/, fn ->
      MissionPlan.new!(:exclusive_plan, spacecraft(), initial_state(),
        horizon_s: 120.0,
        output_step_s: 60.0,
        activities: [
          Activity.command!(:cmd_a, 10.0, 40.0,
            allow_overlap?: true,
            exclusive_with_activity_ids: [:cmd_b]
          ),
          Activity.command!(:cmd_b, 20.0, 50.0, allow_overlap?: true)
        ]
      )
    end

    assert_raise ArgumentError, ~r/activity_timeline_integrity.*exclusivity_group_overlap/, fn ->
      MissionPlan.new!(:exclusive_group_plan, spacecraft(), initial_state(),
        horizon_s: 120.0,
        output_step_s: 60.0,
        activities: [
          Activity.command!(:cmd_a, 10.0, 40.0,
            allow_overlap?: true,
            exclusivity_group: :ground_station_contact
          ),
          Activity.command!(:cmd_b, 20.0, 50.0,
            allow_overlap?: true,
            exclusivity_group: :ground_station_contact
          )
        ]
      )
    end
  end

  test "rejects activities outside the planning horizon" do
    assert_raise ArgumentError, ~r/activity_outside_horizon/, fn ->
      MissionPlan.new!(:bad_plan, spacecraft(), initial_state(),
        horizon_s: 120.0,
        output_step_s: 60.0,
        activities: [
          Activity.observe!(:late_observe, 100.0, 130.0, :target_a)
        ]
      )
    end
  end

  test "top-level API compiles mission plans" do
    plan =
      MissionPlan.new!(:api_plan, spacecraft(), initial_state(),
        horizon_s: 60.0,
        output_step_s: 60.0
      )

    assert {:ok, %Scenario{id: :api_plan}} = OrbitalDynamics.compile_plan(plan)
  end

  defp spacecraft do
    Spacecraft.new!(:sat_1, 250.0)
  end

  defp initial_state do
    StateVector.new!(
      {7000.0, 0.0, 0.0},
      {0.0, 7.5, 0.0},
      Epoch.new!(0.0, :tdb),
      Frame.earth_inertial_j2000()
    )
  end
end
