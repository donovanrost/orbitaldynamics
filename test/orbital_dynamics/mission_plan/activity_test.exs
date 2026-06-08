defmodule OrbitalDynamics.MissionPlan.ActivityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Frame
  alias OrbitalDynamics.MissionPlan.Activity

  test "declares typed activity capabilities" do
    assert %{
             model: :typed_mission_plan_activity,
             validation_level: :artifact_contract,
             activity_types: activity_types,
             activity_statuses: activity_statuses,
             approval_statuses: approval_statuses,
             contact_directions: contact_directions,
             artifact_boundaries: artifact_boundaries,
             type_aliases: type_aliases,
             lifecycle_event_aliases: lifecycle_event_aliases,
             activity_status_aliases: activity_status_aliases,
             approval_status_aliases: approval_status_aliases,
             transition_helpers: transition_helpers,
             public_facades: public_facades,
             time_aliases: time_aliases,
             unit_interval_fields: unit_interval_fields,
             unit_interval_field_aliases: unit_interval_field_aliases,
             preserved_fields: preserved_fields,
             known_limits: known_limits
           } = Activity.capabilities()

    assert :planned_contact in activity_types
    assert :impulsive_burn in activity_types
    assert :attitude in activity_types
    assert :approved in activity_statuses
    assert :completed in activity_statuses
    assert :failed in activity_statuses
    assert :cancelled in activity_statuses
    assert :blocked_by_policy in activity_statuses
    assert :locked in approval_statuses
    assert :operator_review_required in approval_statuses
    assert :blocked_by_policy in approval_statuses
    assert :downlink in contact_directions
    assert :health_check in contact_directions
    assert Activity.capabilities().contact_direction_aliases["cmd"] == :command
    assert Activity.capabilities().contact_direction_aliases["commands"] == :command
    assert Activity.capabilities().contact_direction_aliases["s_band_command"] == :command
    assert Activity.capabilities().contact_direction_aliases["dl"] == :downlink
    assert Activity.capabilities().contact_direction_aliases["downlinking"] == :downlink
    assert Activity.capabilities().contact_direction_aliases["up_link"] == :uplink
    assert Activity.capabilities().contact_direction_aliases["track_ing"] == :tracking
    assert Activity.capabilities().contact_direction_aliases["tracking_pass"] == :tracking
    assert Activity.capabilities().contact_direction_aliases["healthcheck"] == :health_check
    assert :from_string_keyed_map in artifact_boundaries
    assert :activity_type_alias in artifact_boundaries
    assert {:activity_type, :type} in type_aliases
    assert lifecycle_event_aliases["completed"] == :record_completion
    assert lifecycle_event_aliases["failed"] == :record_failure
    assert lifecycle_event_aliases["cancelled"] == :cancel
    assert lifecycle_event_aliases["executed"] == :record_execution
    assert lifecycle_event_aliases["partially_executed"] == :record_partial
    assert lifecycle_event_aliases["in_progress"] == :start_execution
    assert lifecycle_event_aliases["timed_out"] == :record_failure
    assert lifecycle_event_aliases["succeeded"] == :record_completion
    assert lifecycle_event_aliases["aborted"] == :record_failure
    assert lifecycle_event_aliases["skipped"] == :record_miss
    assert activity_status_aliases["succeeded"] == :completed
    assert activity_status_aliases["in_progress"] == :executing
    assert activity_status_aliases["timed_out"] == :failed
    assert activity_status_aliases["partially_executed"] == :partial
    assert approval_status_aliases["review_required"] == :operator_review_required
    assert approval_status_aliases["under_review"] == :operator_review_required
    assert approval_status_aliases["policy_blocked"] == :blocked_by_policy
    assert approval_status_aliases["no_review_required"] == :not_required
    assert :status_transition in transition_helpers
    assert :transition_status in transition_helpers
    assert :approval_transition in transition_helpers
    assert :transition_approval_status in transition_helpers
    assert :precondition_summary in transition_helpers
    assert :apply_lifecycle_event in transition_helpers
    assert :start_execution in transition_helpers
    assert :record_execution in transition_helpers
    assert :record_completion in transition_helpers
    assert :record_partial in transition_helpers
    assert :record_failure in transition_helpers
    assert :record_miss in transition_helpers
    assert :delay in transition_helpers
    assert :lock in transition_helpers

    assert :approval_updates_preserve_terminal_or_executed_status in Activity.capabilities().lifecycle_preservation_semantics

    assert :lock_updates_preserve_terminal_or_executed_status in Activity.capabilities().lifecycle_preservation_semantics
    assert :mission_plan_activity_status_transition in public_facades
    assert :mission_plan_activity_transition_status in public_facades
    assert :mission_plan_activity_approval_transition in public_facades
    assert :mission_plan_activity_transition_approval_status in public_facades
    assert :mission_plan_activity_precondition_summary in public_facades
    assert :mission_plan_activity_apply_lifecycle_event in public_facades
    assert :mission_plan_activity_start_execution in public_facades
    assert :mission_plan_activity_record_completion in public_facades
    assert :mission_plan_activity_cancel in public_facades
    assert {:start_s, :starts_at_s} in time_aliases
    assert :storage_margin in unit_interval_fields
    assert :battery_state_of_charge in unit_interval_fields

    assert unit_interval_field_aliases.storage_margin == [
             :storage_margin,
             :storage_capacity_margin
           ]

    assert unit_interval_field_aliases.downlink_margin == [
             :downlink_margin,
             :downlink_capacity_margin
           ]

    assert unit_interval_field_aliases.battery_state_of_charge == [
             :battery_state_of_charge,
             :battery_soc
           ]

    assert :timeline_id in preserved_fields
    assert :scenario_id in preserved_fields
    assert :spacecraft_id in preserved_fields
    assert :resource_id in preserved_fields
    assert :resource_source_quality in preserved_fields
    assert :resource_trust_boundary in preserved_fields
    assert :resource_trust_boundary_status in preserved_fields
    assert :resource_provenance in preserved_fields
    assert :resource_blocking_dimension in preserved_fields
    assert :fuel_margin in preserved_fields
    assert :power_margin in preserved_fields
    assert :storage_margin in preserved_fields
    assert :downlink_margin in preserved_fields
    assert :battery_capacity_wh in preserved_fields
    assert :battery_energy_used_wh in preserved_fields
    assert :battery_energy_generated_wh in preserved_fields
    assert :battery_state_of_charge in preserved_fields
    assert :spacecraft_available in preserved_fields
    assert :payload_available in preserved_fields
    assert :antenna_available in preserved_fields
    assert :degraded in preserved_fields
    assert :mode in preserved_fields
    assert :incompatible_activity_types in preserved_fields
    assert :suppressed_activity_types in preserved_fields
    assert :collection_id in preserved_fields
    assert :product_id in preserved_fields
    assert :product_ids in preserved_fields
    assert :payload_id in preserved_fields
    assert :instrument_id in preserved_fields
    assert :target_priority in preserved_fields
    assert :target_priority_source in preserved_fields
    assert :target_priority_objective_ids in preserved_fields
    assert :target_priority_objective_type in preserved_fields
    assert :observation_objective_count in preserved_fields
    assert :observation_objective_ids in preserved_fields
    assert :observation_objective_source in preserved_fields
    assert :observation_objective_types in preserved_fields
    assert :contact_success in preserved_fields
    assert :contact_result in preserved_fields
    assert :contact_success_factor in preserved_fields
    assert :contact_success_factor_source in preserved_fields
    assert :command_success in preserved_fields
    assert :command_result in preserved_fields
    assert :command_success_factor in preserved_fields
    assert :command_success_factor_source in preserved_fields
    assert :observation_success in preserved_fields
    assert :observation_result in preserved_fields
    assert :observation_success_factor in preserved_fields
    assert :observation_success_factor_source in preserved_fields
    assert :image_quality_score in preserved_fields
    assert :image_quality_status in preserved_fields
    assert :image_quality_source in preserved_fields
    assert :cloud_cover_fraction in preserved_fields
    assert :blur_score in preserved_fields
    assert :maneuver_success in preserved_fields
    assert :maneuver_result in preserved_fields
    assert :maneuver_success_factor in preserved_fields
    assert :maneuver_success_factor_source in preserved_fields
    assert :feedback_weight in preserved_fields
    assert :feedback_weight_source in preserved_fields
    assert :data_volume_mb in preserved_fields
    assert :planned_data_volume_mb in preserved_fields
    assert :planned_volume_mb in preserved_fields
    assert :actual_data_volume_mb in preserved_fields
    assert :actual_volume_mb in preserved_fields
    assert :estimated_data_volume_mb in preserved_fields
    assert :estimated_storage_mb in preserved_fields
    assert :estimated_downlink_mb in preserved_fields
    assert :required_downlink_mb in preserved_fields
    assert :target_data_volume_mb in preserved_fields
    assert :selected_data_volume_mb in preserved_fields
    assert :selected_data_volume_shortfall_mb in preserved_fields
    assert :downlink_requirement_status in preserved_fields
    assert :downlink_completion_sources in preserved_fields
    assert :collection_ends_at_s in preserved_fields
    assert :planned_delivery_at_s in preserved_fields
    assert :actual_delivery_at_s in preserved_fields
    assert :max_latency_s in preserved_fields
    assert :planned_latency_s in preserved_fields
    assert :actual_latency_s in preserved_fields
    assert :collection_latency_objective_count in preserved_fields
    assert :collection_latency_objective_ids in preserved_fields
    assert :collection_latency_objective_source in preserved_fields
    assert :collection_latency_objective_types in preserved_fields
    assert :planned_estimated_throughput_mb in preserved_fields
    assert :actual_throughput_mb in preserved_fields
    assert :link_protocol in preserved_fields
    assert :frequency_band in preserved_fields
    assert :modulation in preserved_fields
    assert :coding_scheme in preserved_fields
    assert :polarization in preserved_fields
    assert :data_rate_mbps in preserved_fields
    assert :downlink_rate_mbps in preserved_fields
    assert :data_rate_mb_s in preserved_fields
    assert :downlink_rate_mb_s in preserved_fields
    assert :actual_data_rate_mbps in preserved_fields
    assert :actual_downlink_rate_mbps in preserved_fields
    assert :actual_data_rate_mb_s in preserved_fields
    assert :actual_downlink_rate_mb_s in preserved_fields
    assert :delivered_rate_mbps in preserved_fields
    assert :received_rate_mbps in preserved_fields
    assert :delivered_rate_mb_s in preserved_fields
    assert :received_rate_mb_s in preserved_fields
    assert :actual_duration_s in preserved_fields
    assert :actual_contact_duration_s in preserved_fields
    assert :contact_duration_s in preserved_fields
    assert :link_margin_db in preserved_fields
    assert :snr_db in preserved_fields
    assert :eb_no_db in preserved_fields
    assert :bit_error_rate in preserved_fields
    assert :packet_loss_rate in preserved_fields
    assert :frame_loss_rate in preserved_fields
    assert :carrier_lock in preserved_fields
    assert :symbol_lock in preserved_fields
    assert :link_quality_status in preserved_fields
    assert :pointing_mode in preserved_fields
    assert :pointing_target_id in preserved_fields
    assert :boresight_axis in preserved_fields
    assert :off_nadir_angle_deg in preserved_fields
    assert :slew_angle_deg in preserved_fields
    assert :slew_rate_deg_s in preserved_fields
    assert :pointing_error_deg in preserved_fields
    assert :pointing_status in preserved_fields
    assert :pointing_model in preserved_fields
    assert :pointing_source in preserved_fields
    assert :pointing_confidence in preserved_fields
    assert :thermal_zone_id in preserved_fields
    assert :temperature_c in preserved_fields
    assert :planned_temperature_c in preserved_fields
    assert :actual_temperature_c in preserved_fields
    assert :min_operating_temperature_c in preserved_fields
    assert :max_operating_temperature_c in preserved_fields
    assert :thermal_margin_c in preserved_fields
    assert :thermal_status in preserved_fields
    assert :thermal_model in preserved_fields
    assert :thermal_source in preserved_fields
    assert :thermal_confidence in preserved_fields
    assert :eclipse_overlap_fraction in preserved_fields
    assert :eclipse_overlap_s in preserved_fields
    assert :lighting_condition in preserved_fields
    assert :lighting_condition_detail in preserved_fields
    assert :lighting_condition_model in preserved_fields
    assert :lighting_detail_model in preserved_fields
    assert :lighting_confidence in preserved_fields
    assert :command_window_id in preserved_fields
    assert :command_window_type in preserved_fields
    assert :command_window in preserved_fields
    assert :dependency_activity_ids in preserved_fields
    assert :dependency_timeline_ids in preserved_fields
    assert :exclusive_with_activity_ids in preserved_fields
    assert :exclusive_with_timeline_ids in preserved_fields
    assert :source_window_type in preserved_fields
    assert :source_window in preserved_fields
    assert :cadence_import in preserved_fields
    assert :execution_uncertainty in preserved_fields
    assert :no_command_execution in known_limits

    assert get_in(OrbitalDynamics.capability_catalog(), [
             :planning,
             :mission_plan_activity,
             :model
           ]) ==
             :typed_mission_plan_activity

    activity_status_values = Enum.map(activity_statuses, &Atom.to_string/1)

    assert MapSet.subset?(
             MapSet.new(OrbitalDynamics.Timeline.capabilities().activity_statuses),
             MapSet.new(activity_status_values)
           )
  end

  test "creates interval activities" do
    activity =
      Activity.observe!(:image_target, 10.0, 20.0, :target_a,
        metadata: %{mode: :nadir},
        status: :approved,
        approval_status: :approved,
        locked?: true,
        dependencies: [:slew_target],
        exclusivity_group: :payload,
        source_window_id: :window_1,
        source_window_type: :target_visibility,
        source_window: %{id: :window_1, detector: :target_visibility, confidence: :declared},
        cadence_import: %{
          external_id: :cadence_window_1,
          activity_type: :observation,
          provider: :cadence
        },
        provenance: %{source: :candidate_refresh}
      )

    assert activity.type == :observe
    assert activity.start_s == 10.0
    assert activity.end_s == 20.0
    assert activity.target_id == :target_a
    assert activity.metadata == %{mode: :nadir}
    assert activity.status == :approved
    assert activity.approval_status == :approved
    assert activity.locked?
    assert activity.dependencies == [:slew_target]
    assert activity.exclusivity_group == :payload
    assert activity.source_window_id == :window_1
    assert activity.source_window_type == :target_visibility

    assert activity.source_window == %{
             id: :window_1,
             detector: :target_visibility,
             confidence: :declared
           }

    assert activity.cadence_import == %{
             external_id: :cadence_window_1,
             activity_type: :observation,
             provider: :cadence
           }

    assert activity.provenance == %{source: :candidate_refresh}
    assert Activity.interval(activity) == {10.0, 20.0}

    assert %{
             status: :approved,
             approval_status: :approved,
             locked: true,
             dependencies: [:slew_target],
             exclusivity_group: :payload,
             source_window_id: :window_1,
             source_window_type: :target_visibility,
             source_window: %{id: :window_1, detector: :target_visibility},
             cadence_import: %{external_id: :cadence_window_1, activity_type: :observation},
             provenance: %{source: :candidate_refresh}
           } = Activity.to_map(activity)
  end

  test "derives source-window identity from nested provider windows" do
    activity =
      Activity.observe!(:image_target, 10.0, 20.0, :target_a,
        source_window: %{
          window_id: :window_nested,
          kind: :target_visibility,
          confidence: :declared
        }
      )

    assert activity.source_window_id == :window_nested
    assert activity.source_window_type == :target_visibility

    assert %{
             "source_window_id" => "window_nested",
             "source_window_type" => "target_visibility",
             "source_window" => %{
               "window_id" => "window_nested",
               "kind" => "target_visibility",
               "confidence" => "declared"
             }
           } = Activity.to_artifact_map(activity)

    assert %Activity{
             source_window_id: "provider_window",
             source_window_type: "ground_station_access"
           } =
             Activity.from_map!(%{
               "id" => "cmd_provider_window",
               "type" => "command",
               "start_s" => 0.0,
               "end_s" => 10.0,
               "source_window" => %{
                 "id" => "provider_window",
                 "window_type" => "ground_station_access"
               }
             })
  end

  test "creates command tracking health and planned-contact activities" do
    command = Activity.command!(:cmd_window, 10.0, 20.0, ground_station_id: :dss_14)

    uplink_command =
      Activity.command!(:uplink_window, 20.0, 25.0,
        ground_station_id: :dss_14,
        direction: :uplink
      )

    tracking = Activity.tracking!(:track_pass, 30.0, 40.0, :dss_14)
    health_check = Activity.health_check!(:health_poll, 50.0, 55.0)
    contact = Activity.planned_contact!(:uplink_pass, 60.0, 90.0, :dss_14, :uplink)

    assert command.type == :command
    assert command.direction == :command
    assert command.ground_station_id == :dss_14
    assert uplink_command.type == :command
    assert uplink_command.direction == :uplink

    assert tracking.type == :tracking
    assert tracking.direction == :tracking

    assert health_check.type == :health_check
    assert health_check.status == :planned

    assert contact.type == :planned_contact
    assert contact.direction == :uplink
  end

  test "normalizes provider-style contact direction strings" do
    assert %Activity{direction: :uplink} =
             Activity.planned_contact!(
               :uplink_pass,
               10.0,
               20.0,
               :equator_prime,
               " Up-Link "
             )

    assert %Activity{direction: :command} =
             Activity.command!(:cmd_pass, 30.0, 40.0,
               ground_station_id: :equator_prime,
               direction: "s-band command"
             )

    assert %Activity{direction: :downlink} =
             Activity.planned_contact!(
               :downlink_pass,
               40.0,
               45.0,
               :equator_prime,
               "dl"
             )

    assert %Activity{direction: :command} =
             Activity.from_map!(%{
               "id" => "cmd_alias",
               "type" => "planned_contact",
               "starts_at_s" => 50.0,
               "ends_at_s" => 60.0,
               "station" => %{"id" => "equator_prime"},
               "direction" => "cmd"
             })

    assert %Activity{direction: :tracking} =
             Activity.from_map!(%{
               "id" => "tracking_alias",
               "type" => "planned_contact",
               "starts_at_s" => 70.0,
               "ends_at_s" => 80.0,
               "ground_station_id" => "equator_prime",
               "direction" => "tracking-pass"
             })

    assert %Activity{
             type: :health_check,
             direction: :health_check,
             ground_station_id: "equator_prime"
           } =
             Activity.from_map!(%{
               "id" => "health_alias",
               "type" => "planned_contact",
               "starts_at_s" => 90.0,
               "ends_at_s" => 95.0,
               "station_id" => "equator_prime",
               "direction" => "Health Check Window"
             })

    assert %Activity{
             type: :health_check,
             direction: :health_check,
             ground_station_id: "equator_prime"
           } =
             Activity.from_map!(%{
               "id" => "typed_health_alias",
               "type" => "health_check",
               "starts_at_s" => 100.0,
               "ends_at_s" => 105.0,
               "station" => %{"id" => "equator_prime"},
               "direction" => "healthcheck"
             })
  end

  test "creates first-class attitude activities with pointing evidence" do
    activity =
      Activity.attitude!(:target_hold, 10.0, 35.0,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        attitude_mode: :target_track,
        attitude_target_id: :target_a,
        roll_deg: 1.0,
        pitch_deg: -0.5,
        yaw_deg: 3.25,
        attitude_error_deg: 0.05,
        attitude_status: :within_tolerance,
        attitude_model: :declared_euler_attitude,
        attitude_source: :mission_plan,
        attitude_confidence: 0.9,
        source_window_id: :attitude_window_1
      )

    assert activity.type == :attitude
    assert activity.attitude_mode == :target_track
    assert activity.attitude_target_id == :target_a
    assert activity.roll_deg == 1.0
    assert activity.pitch_deg == -0.5
    assert activity.yaw_deg == 3.25
    assert activity.attitude_error_deg == 0.05
    assert activity.attitude_status == :within_tolerance

    assert %{
             "type" => "attitude",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "sat_1",
             "attitude_mode" => "target_track",
             "attitude_target_id" => "target_a",
             "roll_deg" => 1.0,
             "pitch_deg" => -0.5,
             "yaw_deg" => 3.25,
             "attitude_error_deg" => 0.05,
             "attitude_status" => "within_tolerance",
             "attitude_model" => "declared_euler_attitude",
             "attitude_source" => "mission_plan",
             "attitude_confidence" => 0.9,
             "source_window_id" => "attitude_window_1"
           } = Activity.to_artifact_map(activity)

    from_artifact =
      Activity.from_map!(%{
        "id" => "hold_from_artifact",
        "type" => "attitude",
        "starts_at_s" => "40.0",
        "ends_at_s" => "55.0",
        "scenario_id" => "leo_1",
        "spacecraft_id" => "sat_1",
        "pointing_mode" => "sun_hold",
        "pointing_target_id" => "sun_vector",
        "pointing_error_deg" => "0.1",
        "pointing_status" => "declared",
        "pointing_confidence" => "0.8"
      })

    assert from_artifact.type == :attitude
    assert from_artifact.attitude_mode == "sun_hold"
    assert from_artifact.attitude_target_id == "sun_vector"
    assert from_artifact.attitude_error_deg == 0.1
    assert from_artifact.attitude_confidence == 0.8

    assert_raise ArgumentError, ~r/attitude_target_id must be nil or an identifier/, fn ->
      Activity.attitude!(:bad_target, 60.0, 70.0, attitude_target_id: "")
    end
  end

  test "preserves MB/s rate aliases without rewriting them into Mbps fields" do
    activity =
      Activity.from_map!(%{
        "id" => "dl_rate_alias",
        "type" => "planned_contact",
        "starts_at_s" => 10.0,
        "ends_at_s" => 70.0,
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "data_rate_mb_s" => "8.0",
        "downlink_rate_mb_s" => "6.0",
        "actual_data_rate_mb_s" => "4.0",
        "actual_duration_s" => "55.0"
      })

    assert activity.data_rate_mb_s == 8.0
    assert activity.downlink_rate_mb_s == 6.0
    assert activity.actual_data_rate_mb_s == 4.0
    assert activity.actual_duration_s == 55.0
    assert is_nil(activity.data_rate_mbps)
    assert is_nil(activity.downlink_rate_mbps)

    artifact = Activity.to_artifact_map(activity)
    assert artifact["data_rate_mb_s"] == 8.0
    assert artifact["downlink_rate_mb_s"] == 6.0
    assert artifact["actual_data_rate_mb_s"] == 4.0
    assert artifact["actual_duration_s"] == 55.0
    refute Map.has_key?(artifact, "data_rate_mbps")
    refute Map.has_key?(artifact, "downlink_rate_mbps")
  end

  test "updates lifecycle state through typed pure helpers" do
    activity = Activity.command!(:cmd_window, 10.0, 20.0, ground_station_id: :dss_14)

    assert %Activity{status: :approved, approval_status: :approved} =
             approved = Activity.approve!(activity)

    assert %Activity{status: :locked, approval_status: :locked, locked?: true} =
             Activity.lock!(approved)

    assert %Activity{status: :executed, approval_status: :approved, locked?: false} =
             Activity.record_execution!(approved)

    assert %Activity{status: :executing} = Activity.start_execution!(activity)
    assert %Activity{status: :completed} = Activity.record_completion!(activity)
    assert %Activity{status: :partial} = Activity.record_partial!(activity)
    assert %Activity{status: :failed} = Activity.record_failure!(activity)
    assert %Activity{status: :missed} = Activity.record_miss!(activity)
    assert %Activity{status: :delayed} = Activity.delay!(activity)

    assert %Activity{status: :executing} =
             Activity.apply_lifecycle_event!(activity, :start_execution)

    assert %Activity{status: :completed} = Activity.apply_lifecycle_event!(activity, :completed)

    assert %Activity{status: :completed} =
             Activity.apply_lifecycle_event!(activity, "Record Completion")

    assert %Activity{status: :partial} =
             Activity.apply_lifecycle_event!(activity, "record-partial")

    assert %Activity{status: :approved, approval_status: :approved} =
             Activity.apply_lifecycle_event!(activity, " approve ")

    assert %Activity{status: :completed} = Activity.apply_lifecycle_event!(activity, "Completed")
    assert %Activity{status: :executed} = Activity.apply_lifecycle_event!(activity, "executed")
    assert %Activity{status: :failed} = Activity.apply_lifecycle_event!(activity, "failure")
    assert %Activity{status: :failed} = Activity.apply_lifecycle_event!(activity, "timed out")
    assert %Activity{status: :failed} = Activity.apply_lifecycle_event!(activity, "aborted")
    assert %Activity{status: :completed} = Activity.apply_lifecycle_event!(activity, "succeeded")
    assert %Activity{status: :missed} = Activity.apply_lifecycle_event!(activity, "skipped")

    assert %Activity{status: :executing} =
             Activity.apply_lifecycle_event!(activity, "in progress")

    assert %Activity{status: :missed} = Activity.apply_lifecycle_event!(activity, "missed")
    assert %Activity{status: :canceled} = Activity.apply_lifecycle_event!(activity, "cancelled")

    assert %Activity{status: :partial} =
             Activity.apply_lifecycle_event!(activity, "partially executed")

    assert %Activity{status: :planned, approval_status: :rejected} =
             Activity.reject!(activity)

    assert %Activity{status: :canceled} = Activity.cancel!(activity)
    assert %Activity{status: :failed} = Activity.put_status!(activity, :failed)
    assert %Activity{status: :completed} = Activity.put_status!(activity, "Succeeded")
    assert %Activity{status: :failed} = Activity.put_status!(activity, "timed out")
    assert %Activity{status: :partial} = Activity.put_status!(activity, "partially-executed")

    assert %Activity{approval_status: :operator_review_required} =
             Activity.put_approval_status!(activity, "operator_review_required")

    assert %Activity{approval_status: :operator_review_required} =
             Activity.put_approval_status!(activity, "under review")

    assert_raise ArgumentError, ~r/status must be one of/, fn ->
      Activity.put_status!(activity, :garbage)
    end

    assert_raise ArgumentError, ~r/lifecycle event must be one of/, fn ->
      Activity.apply_lifecycle_event!(activity, :garbage)
    end

    assert_raise ArgumentError, ~r/approval_status must be one of/, fn ->
      Activity.put_approval_status!(activity, :garbage)
    end
  end

  test "validates safe lifecycle status transitions without mutating schedules" do
    activity = Activity.command!(:cmd_window, 10.0, 20.0, ground_station_id: :dss_14)

    assert %{
             "model" => "typed_activity_status_transition_validation",
             "field" => "status",
             "from" => "planned",
             "to" => "executing",
             "from_category" => "planned",
             "to_category" => "executing",
             "safe_to_apply" => true,
             "requires_operator_review" => false,
             "operator_action_reason" => "status_transition_allowed",
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_transition_validation"
             }
           } = Activity.status_transition(activity, "In Progress")

    assert %Activity{status: :partial} =
             Activity.transition_status!(activity, "partially executed")

    completed = Activity.record_completion!(activity)

    assert %{
             "from" => "completed",
             "to" => "planned",
             "from_category" => "terminal_or_executed",
             "to_category" => "planned",
             "safe_to_apply" => false,
             "requires_operator_review" => true,
             "operator_action_reason" => "terminal_or_executed_status_change_requires_review"
           } = Activity.status_transition(completed, :planned)

    assert_raise ArgumentError,
                 ~r/unsafe lifecycle status transition completed -> planned: terminal_or_executed_status_change_requires_review/,
                 fn ->
                   Activity.transition_status!(completed, :planned)
                 end

    blocked = Activity.put_status!(activity, :blocked_by_policy)

    assert %{
             "from" => "blocked_by_policy",
             "to" => "planned",
             "from_category" => "blocked",
             "safe_to_apply" => false,
             "operator_action_reason" => "blocked_status_clear_requires_review"
           } = Activity.status_transition(blocked, :planned)

    assert %{
             "from" => "planned",
             "to" => "blocked_by_policy",
             "to_category" => "blocked",
             "safe_to_apply" => false,
             "operator_action_reason" => "policy_block_requires_review"
           } = Activity.status_transition(activity, :blocked_by_policy)
  end

  test "validates safe approval status transitions without granting authority" do
    activity = Activity.command!(:cmd_window, 10.0, 20.0, ground_station_id: :dss_14)

    assert %{
             "model" => "typed_activity_approval_transition_validation",
             "field" => "approval_status",
             "from" => "not_required",
             "to" => "operator_review_required",
             "from_category" => "not_required",
             "to_category" => "review_required",
             "safe_to_apply" => true,
             "requires_operator_review" => false,
             "operator_action_reason" => "approval_transition_allowed",
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_transition_validation"
             }
           } = Activity.approval_transition(activity, "under review")

    assert %Activity{approval_status: :operator_review_required} =
             Activity.transition_approval_status!(activity, "under review")

    review_required = Activity.put_approval_status!(activity, :operator_review_required)

    assert %{
             "from" => "operator_review_required",
             "to" => "approved",
             "from_category" => "review_required",
             "to_category" => "approval_granted",
             "safe_to_apply" => false,
             "requires_operator_review" => true,
             "operator_action_reason" => "approval_grant_requires_operator_authority"
           } = Activity.approval_transition(review_required, :approved)

    assert_raise ArgumentError,
                 ~r/unsafe approval status transition operator_review_required -> approved: approval_grant_requires_operator_authority/,
                 fn ->
                   Activity.transition_approval_status!(review_required, :approved)
                 end

    blocked = Activity.put_approval_status!(activity, :blocked_by_policy)

    assert %{
             "from" => "blocked_by_policy",
             "to" => "pending",
             "from_category" => "blocked",
             "safe_to_apply" => false,
             "operator_action_reason" => "blocked_approval_clear_requires_review"
           } = Activity.approval_transition(blocked, :pending)
  end

  test "summarizes typed activity state and resource preconditions" do
    clear = Activity.command!(:cmd_clear, 10.0, 20.0, ground_station_id: :dss_14)

    assert %{
             "model" => "typed_activity_precondition_summary",
             "activity_id" => "cmd_clear",
             "activity_type" => "command",
             "precondition_status" => "clear",
             "blocked_precondition_count" => 0,
             "review_precondition_count" => 0,
             "blocked_precondition_types" => [],
             "review_precondition_types" => [],
             "preconditions" => [],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "operator_authority" => "not_granted_by_precondition_summary",
               "resource_authority" => "not_reserved_by_precondition_summary"
             }
           } = Activity.precondition_summary(clear)

    review =
      Activity.command!(:cmd_review, 30.0, 40.0,
        ground_station_id: :dss_14,
        degraded: true
      )

    assert %{
             "precondition_status" => "review_required",
             "blocked_precondition_count" => 0,
             "review_precondition_count" => 1,
             "review_precondition_types" => ["degraded_mode"],
             "preconditions" => [
               %{
                 "type" => "degraded_mode",
                 "status" => "review_required",
                 "field" => "degraded"
               }
             ]
           } = Activity.precondition_summary(review)

    blocked =
      Activity.command!(:cmd_blocked, 50.0, 60.0,
        ground_station_id: :dss_14,
        payload_available: false,
        degraded: true,
        resource_blocking_dimension: :power,
        power_margin: 0.0,
        suppressed_activity_types: [:command],
        metadata: %{
          command_authority_status: :operator_required,
          required_authority: :flight_director,
          command_authorized: false,
          command_safety_status: :unsafe,
          command_safety_checked: false
        }
      )

    assert %{
             "precondition_status" => "blocked",
             "blocked_precondition_count" => 5,
             "review_precondition_count" => 3,
             "blocked_precondition_types" => [
               "activity_type_suppressed",
               "command_safety_failed",
               "payload_unavailable",
               "power_margin_depleted",
               "resource_block_declared"
             ],
             "review_precondition_types" => [
               "command_authority_missing",
               "command_safety_unchecked",
               "degraded_mode"
             ]
           } = summary = Activity.precondition_summary(blocked)

    assert Enum.any?(summary["preconditions"], fn
             %{
               "type" => "resource_block_declared",
               "status" => "blocked",
               "field" => "resource_blocking_dimension",
               "value" => "power"
             } ->
               true

             _other ->
               false
           end)

    assert Enum.any?(summary["preconditions"], fn
             %{
               "type" => "activity_type_suppressed",
               "status" => "blocked",
               "field" => "suppressed_activity_types",
               "value" => "command"
             } ->
               true

             _other ->
               false
           end)

    assert %{
             "type" => "command_authority_missing",
             "status" => "review_required",
             "field" => "command_authorized",
             "reason" => "command authority is explicitly not granted",
             "value" => false
           } in summary["preconditions"]

    assert %{
             "type" => "command_safety_failed",
             "status" => "blocked",
             "field" => "command_safety_status",
             "reason" => "command safety status is explicitly unsafe or failed",
             "value" => "unsafe"
           } in summary["preconditions"]

    assert %{
             "type" => "command_safety_unchecked",
             "status" => "review_required",
             "field" => "command_safety_checked",
             "reason" => "command safety check requires review before command handoff",
             "value" => false
           } in summary["preconditions"]

    assert summary ==
             blocked
             |> Activity.to_artifact_map()
             |> OrbitalDynamics.mission_plan_activity_precondition_summary()
  end

  test "approval and lock helpers preserve terminal lifecycle status" do
    completed =
      :dl_done
      |> Activity.downlink!(10.0, 20.0, :equator_prime)
      |> Activity.record_completion!()

    assert %Activity{status: :completed, approval_status: :approved, locked?: false} =
             Activity.approve!(completed)

    assert %Activity{status: :completed, approval_status: :locked, locked?: true} =
             Activity.lock!(completed)

    failed =
      :cmd_failed
      |> Activity.command!(30.0, 40.0, ground_station_id: :equator_prime)
      |> Activity.record_failure!()

    assert %Activity{status: :failed, approval_status: :locked, locked?: true} =
             Activity.apply_lifecycle_event!(failed, :lock)

    rejected =
      :obs_rejected
      |> Activity.observe!(50.0, 60.0, :target_a)
      |> Activity.reject!()
      |> Activity.put_status!(:rejected)

    assert %Activity{status: :rejected, approval_status: :approved} =
             Activity.apply_lifecycle_event!(rejected, :approve)
  end

  test "accepts operational timeline lifecycle vocabulary at artifact boundaries" do
    activity =
      Activity.from_map!(%{
        "id" => "missed_contact",
        "type" => "planned_contact",
        "start_s" => 100.0,
        "end_s" => 160.0,
        "ground_station_id" => "dss_14",
        "direction" => "downlink",
        "status" => "completed",
        "approval_status" => "operator_review_required"
      })

    assert activity.status == :completed
    assert activity.approval_status == :operator_review_required

    assert %{
             "status" => "completed",
             "approval_status" => "operator_review_required"
           } = Activity.to_artifact_map(activity)

    assert Activity.from_map!(%{
             "id" => "provider_started_cmd",
             "type" => "command",
             "start_s" => 170.0,
             "end_s" => 190.0,
             "ground_station_id" => "dss_14",
             "direction" => "uplink",
             "status" => "In Progress"
           }).status == :executing

    assert Activity.from_map!(%{
             "id" => "provider_success_cmd",
             "type" => "command",
             "start_s" => 200.0,
             "end_s" => 220.0,
             "ground_station_id" => "dss_14",
             "direction" => "uplink",
             "status" => :succeeded
           }).status == :completed

    assert Activity.from_map!(%{
             "id" => "provider_timeout_cmd",
             "type" => "command",
             "start_s" => 230.0,
             "end_s" => 250.0,
             "ground_station_id" => "dss_14",
             "direction" => "uplink",
             "status" => "timed-out"
           }).status == :failed

    assert Activity.from_map!(%{
             "id" => "provider_partial_cmd",
             "type" => "command",
             "start_s" => 255.0,
             "end_s" => 257.0,
             "ground_station_id" => "dss_14",
             "direction" => "uplink",
             "status" => "partially executed"
           }).status == :partial

    assert Activity.from_map!(%{
             "id" => "provider_review_cmd",
             "type" => "command",
             "start_s" => 260.0,
             "end_s" => 280.0,
             "ground_station_id" => "dss_14",
             "direction" => "uplink",
             "approval_status" => "Review Required"
           }).approval_status == :operator_review_required

    assert Activity.from_map!(%{
             "id" => "provider_under_review_cmd",
             "type" => "command",
             "start_s" => 285.0,
             "end_s" => 287.0,
             "ground_station_id" => "dss_14",
             "direction" => "uplink",
             "approval_status" => "under review"
           }).approval_status == :operator_review_required

    assert Activity.from_map!(%{
             "id" => "provider_blocked_cmd",
             "type" => "command",
             "start_s" => 290.0,
             "end_s" => 310.0,
             "ground_station_id" => "dss_14",
             "direction" => "uplink",
             "approval_status" => :policy_blocked
           }).approval_status == :blocked_by_policy

    assert Activity.command!(:provider_no_review_cmd, 320.0, 340.0,
             ground_station_id: "dss_14",
             approval_status: "No Review Required"
           ).approval_status == :not_required
  end

  test "accepts activity_type as a typed activity ingress alias" do
    activity =
      Activity.from_map!(%{
        "id" => "provider_health_window",
        "activity_type" => "planned_contact",
        "start_s" => 100.0,
        "end_s" => 160.0,
        "station" => %{"id" => "dss_14"},
        "direction" => "Health Check Window"
      })

    assert activity.type == :health_check
    assert activity.ground_station_id == "dss_14"
    assert activity.direction == :health_check

    assert %{
             "id" => "provider_health_window",
             "type" => "health_check",
             "ground_station_id" => "dss_14",
             "direction" => "health_check"
           } = Activity.to_artifact_map(activity)
  end

  test "accepts provider-shaped target station and spacecraft objects at artifact ingress" do
    observation =
      Activity.from_map!(%{
        "id" => "obs_1",
        "type" => "observe",
        "start_s" => 10.0,
        "end_s" => 20.0,
        "target" => %{"id" => "target_a"},
        "spacecraft" => %{"id" => "sat_1"}
      })

    downlink =
      Activity.from_map!(%{
        "id" => "dl_1",
        "type" => "downlink",
        "start_s" => 30.0,
        "end_s" => 40.0,
        "station" => %{"id" => "equator_prime"},
        "satellite" => %{"satellite_id" => "sat_2"}
      })

    contact =
      Activity.from_map!(%{
        "id" => "contact_1",
        "type" => "planned_contact",
        "start_s" => 50.0,
        "end_s" => 60.0,
        "spacecraft_id" => "sat_explicit",
        "ground_station" => %{"station_id" => "dss_14"},
        "spacecraft" => %{"id" => "sat_nested"},
        "direction" => "command"
      })

    command =
      Activity.from_map!(%{
        id: :cmd_1,
        type: :command,
        start_s: 70.0,
        end_s: 80.0,
        station: %{station_id: :dss_24},
        satellite: %{id: :leo_2}
      })

    assert observation.target_id == "target_a"
    assert observation.spacecraft_id == "sat_1"
    assert downlink.ground_station_id == "equator_prime"
    assert downlink.spacecraft_id == "sat_2"
    assert contact.ground_station_id == "dss_14"
    assert contact.spacecraft_id == "sat_explicit"
    assert command.ground_station_id == :dss_24
    assert command.spacecraft_id == :leo_2

    assert %{"target_id" => "target_a", "spacecraft_id" => "sat_1"} =
             Activity.to_artifact_map(observation)

    assert %{"ground_station_id" => "equator_prime", "spacecraft_id" => "sat_2"} =
             Activity.to_artifact_map(downlink)

    assert %{"ground_station_id" => "dss_14", "spacecraft_id" => "sat_explicit"} =
             Activity.to_artifact_map(contact)

    assert %{"ground_station_id" => "dss_24", "spacecraft_id" => "leo_2"} =
             Activity.to_artifact_map(command)
  end

  test "creates impulsive burn activities" do
    frame = Frame.earth_inertial_j2000()

    activity =
      Activity.impulsive_burn!(:raise_apogee, 60.0, {0.0, 0.01, 0.0},
        frame: frame,
        execution_uncertainty: %{
          timing_3sigma_s: 2.0,
          delta_v_3sigma_km_s: [0.0, 0.0001, 0.0],
          source: :operator_estimate
        }
      )

    assert activity.type == :impulsive_burn
    assert activity.epoch_s == 60.0
    assert activity.delta_v_km_s == {0.0, 0.01, 0.0}
    assert activity.frame == frame
    assert activity.execution_uncertainty.timing_3sigma_s == 2.0
    assert Activity.interval(activity) == {60.0, 60.0}

    assert %{
             execution_uncertainty: %{
               timing_3sigma_s: 2.0,
               delta_v_3sigma_km_s: delta_v_3sigma_km_s
             }
           } = Activity.to_map(activity)

    assert delta_v_3sigma_km_s == [0.0, 0.0001, 0.0]
  end

  test "normalizes string keyed activity maps into typed activities" do
    activity =
      Activity.from_map!(%{
        "id" => "dl_1",
        "type" => "planned_contact",
        "starts_at_s" => 100.0,
        "ends_at_s" => 160.0,
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "status" => "approved",
        "approval_status" => "approved",
        "locked" => "true",
        "timeline_id" => "timeline:dl_1",
        "scenario_id" => "leo_1",
        "spacecraft_id" => "sat_1",
        "resource_id" => "payload_bus",
        "source_quality" => "declared",
        "trust_boundary" => "operator_supplied",
        "trust_boundary_status" => "declared",
        "resource_provenance" => %{"source" => "mission_database"},
        "resource_blocking_dimension" => "power",
        "fuel_margin" => "0.72",
        "power_margin" => "0.35",
        "storage_capacity_margin" => "0.42",
        "downlink_capacity_margin" => "0.51",
        "battery_capacity_wh" => "240.0",
        "battery_energy_used_wh" => "88.0",
        "estimated_energy_generated_wh" => "45.0",
        "battery_soc" => "0.68",
        "spacecraft_available?" => "true",
        "payload_available?" => "false",
        "antenna_available?" => "true",
        "degraded?" => "true",
        "mode" => "payload_safe",
        "incompatible_activity_types" => ["observe"],
        "suppressed_activity_types" => ["downlink"],
        "collection" => "collection_alpha",
        "data_product_id" => "image_alpha_1",
        "data_product_ids" => ["image_alpha_1", "image_alpha_2"],
        "payload" => "camera_a",
        "instrument" => "wide_field",
        "priority" => "4.5",
        "target_priority_source" => "operator_objective",
        "target_priority_objective_ids" => ["latency:collection_alpha"],
        "target_priority_objective_type" => "collection_latency",
        "contact_success" => "false",
        "contact_result" => "carrier_lock_lost",
        "contact_success_factor" => "0.25",
        "contact_success_factor_source" => "provider_feedback",
        "command_success" => "true",
        "command_result" => "accepted",
        "command_success_factor" => "0.9",
        "command_success_factor_source" => "operator_review",
        "observation_success" => "true",
        "observation_result" => "usable",
        "observation_success_factor" => "0.8",
        "observation_success_factor_source" => "image_quality_review",
        "product_quality_score" => "0.84",
        "product_quality_status" => "usable",
        "product_quality_source" => "provider_observation_review",
        "cloud_fraction" => "0.18",
        "image_blur_score" => "0.06",
        "maneuver_success" => "false",
        "maneuver_result" => "delta_v_shortfall",
        "maneuver_success_factor" => "0.4",
        "maneuver_success_factor_source" => "maneuver_review",
        "feedback_weight" => "0.7",
        "feedback_weight_source" => "operator_weight",
        "data_volume_mb" => "120.0",
        "planned_volume_mb" => "120.0",
        "actual_storage_mb" => "90.0",
        "actual_volume_mb" => "90.0",
        "estimated_data_volume_mb" => "110.0",
        "estimated_storage_mb" => "115.0",
        "estimated_downlink_mb" => "118.0",
        "target_data_volume_mb" => "140.0",
        "selected_data_volume_mb" => "90.0",
        "selected_data_volume_shortfall_mb" => "50.0",
        "min_downlink_mb" => "100.0",
        "downlink_requirement_status" => "shortfall",
        "downlink_completion_sources" => ["provider.collection:collection_alpha"],
        "observed_ends_at_s" => "360.0",
        "planned_downlink_at_s" => "540.0",
        "received_at_s" => "550.0",
        "required_latency_s" => "240.0",
        "planned_latency_s" => "180.0",
        "actual_latency_s" => "190.0",
        "estimated_throughput_mb" => "118.0",
        "received_throughput_mb" => "96.0",
        "link_protocol" => "space_packet",
        "rf_band" => "x_band",
        "modulation" => "qpsk",
        "coding_scheme" => "ldpc",
        "polarization" => "rhcp",
        "data_rate_mbps" => "64.0",
        "downlink_rate_mbps" => "48.0",
        "data_rate_mb_s" => "8.0",
        "downlink_rate_mb_s" => "6.0",
        "actual_data_rate_mbps" => "32.0",
        "actual_downlink_rate_mbps" => "28.0",
        "actual_data_rate_mb_s" => "4.0",
        "actual_downlink_rate_mb_s" => "3.5",
        "delivered_rate_mbps" => "24.0",
        "received_rate_mbps" => "20.0",
        "delivered_rate_mb_s" => "3.0",
        "received_rate_mb_s" => "2.5",
        "actual_duration_s" => "55.0",
        "actual_contact_duration_s" => "54.0",
        "contact_duration_s" => "60.0",
        "link_margin_d_b" => "3.5",
        "snr_db" => "12.0",
        "ebn0_db" => "9.0",
        "ber" => "1.0e-6",
        "packet_loss_rate" => "0.01",
        "frame_loss_rate" => "0.02",
        "carrier_locked" => "true",
        "symbol_locked" => "true",
        "rf_status" => "nominal",
        "attitude_mode" => "target_track",
        "attitude_target_id" => "target_a",
        "sensor_axis" => "+Z",
        "look_angle_deg" => "12.5",
        "slew_angle_deg" => "5.0",
        "slew_rate_deg_s" => "0.25",
        "attitude_error_deg" => "0.05",
        "attitude_status" => "declared",
        "attitude_model" => "operator_supplied",
        "attitude_source" => "mission_database",
        "attitude_confidence" => "0.9",
        "thermal_component_id" => "payload_bus",
        "temp_c" => "18.5",
        "predicted_temperature_c" => "19.0",
        "measured_temp_c" => "21.0",
        "minimum_operating_temperature_c" => "-5.0",
        "maximum_operating_temperature_c" => "40.0",
        "temperature_margin_c" => "19.0",
        "temperature_status" => "nominal",
        "temperature_model" => "operator_supplied",
        "temperature_source" => "mission_database",
        "temperature_confidence" => "0.8",
        "eclipsed_fraction" => "0.35",
        "eclipse_overlap_seconds" => "21.0",
        "lighting_status" => "partial_eclipse",
        "lighting_detail" => "mixed_lighting",
        "lighting_model" => "sampled_eclipse_overlap_tag",
        "lighting_detail_source" => "sampled_eclipse_overlap_fraction_tag",
        "lighting_confidence_label" => "bounded_by_sampled_eclipse_overlap",
        "command_window" => %{
          "id" => "command_window:dl_1",
          "type" => "downlink_command_context",
          "provider" => "cadence"
        },
        "dependencies" => ["cmd_ready"],
        "dependency_timeline_ids" => ["timeline:cmd_ready"],
        "exclusive_with_activity_ids" => ["dl_conflict"],
        "exclusive_with_timeline_ids" => ["timeline:dl_conflict"],
        "exclusivity_group" => "station_contact",
        "source_window_id" => "window:leo_1:equator_prime:1",
        "source_window_type" => "ground_station_access",
        "source_window" => %{
          "id" => "window:leo_1:equator_prime:1",
          "type" => "ground_station_access",
          "provider" => "candidate_refresh.v1"
        },
        "cadence_import" => %{
          "external_id" => "cadence:contact:dl_1",
          "activity_type" => "contact",
          "schema_contract" => "cadence_import_manifest.v1"
        },
        "execution_uncertainty" => %{"timing_3sigma_s" => 2.0},
        "provenance" => %{"source" => "candidate_refresh.v1"},
        "metadata" => %{"source" => "provider_row"},
        "allow_overlap?" => "false"
      })

    assert %Activity{
             id: "dl_1",
             type: :planned_contact,
             start_s: 100.0,
             end_s: 160.0,
             ground_station_id: "equator_prime",
             direction: :downlink,
             status: :approved,
             approval_status: :approved,
             locked?: true,
             timeline_id: "timeline:dl_1",
             scenario_id: "leo_1",
             spacecraft_id: "sat_1",
             resource_id: "payload_bus",
             resource_source_quality: "declared",
             resource_trust_boundary: "operator_supplied",
             resource_trust_boundary_status: "declared",
             resource_provenance: %{"source" => "mission_database"},
             resource_blocking_dimension: "power",
             fuel_margin: 0.72,
             power_margin: 0.35,
             storage_margin: 0.42,
             downlink_margin: 0.51,
             battery_capacity_wh: 240.0,
             battery_energy_used_wh: 88.0,
             battery_energy_generated_wh: 45.0,
             battery_state_of_charge: 0.68,
             spacecraft_available: true,
             payload_available: false,
             antenna_available: true,
             degraded: true,
             mode: "payload_safe",
             incompatible_activity_types: ["observe"],
             suppressed_activity_types: ["downlink"],
             collection_id: "collection_alpha",
             product_id: "image_alpha_1",
             product_ids: ["image_alpha_1", "image_alpha_2"],
             payload_id: "camera_a",
             instrument_id: "wide_field",
             target_priority: 4.5,
             target_priority_source: "operator_objective",
             target_priority_objective_ids: ["latency:collection_alpha"],
             target_priority_objective_type: "collection_latency",
             contact_success: false,
             contact_result: "carrier_lock_lost",
             contact_success_factor: 0.25,
             contact_success_factor_source: "provider_feedback",
             command_success: true,
             command_result: "accepted",
             command_success_factor: 0.9,
             command_success_factor_source: "operator_review",
             observation_success: true,
             observation_result: "usable",
             observation_success_factor: 0.8,
             observation_success_factor_source: "image_quality_review",
             image_quality_score: 0.84,
             image_quality_status: "usable",
             image_quality_source: "provider_observation_review",
             cloud_cover_fraction: 0.18,
             blur_score: 0.06,
             maneuver_success: false,
             maneuver_result: "delta_v_shortfall",
             maneuver_success_factor: 0.4,
             maneuver_success_factor_source: "maneuver_review",
             feedback_weight: 0.7,
             feedback_weight_source: "operator_weight",
             data_volume_mb: 120.0,
             planned_data_volume_mb: 120.0,
             planned_volume_mb: 120.0,
             actual_data_volume_mb: 90.0,
             actual_volume_mb: 90.0,
             estimated_data_volume_mb: 110.0,
             estimated_storage_mb: 115.0,
             estimated_downlink_mb: 118.0,
             required_downlink_mb: 140.0,
             target_data_volume_mb: 140.0,
             min_downlink_mb: 100.0,
             selected_data_volume_mb: 90.0,
             selected_data_volume_shortfall_mb: 50.0,
             downlink_requirement_status: "shortfall",
             downlink_completion_sources: ["provider.collection:collection_alpha"],
             collection_ends_at_s: 360.0,
             planned_delivery_at_s: 540.0,
             actual_delivery_at_s: 550.0,
             max_latency_s: 240.0,
             planned_latency_s: 180.0,
             actual_latency_s: 190.0,
             planned_estimated_throughput_mb: 118.0,
             actual_throughput_mb: 96.0,
             link_protocol: "space_packet",
             frequency_band: "x_band",
             modulation: "qpsk",
             coding_scheme: "ldpc",
             polarization: "rhcp",
             data_rate_mbps: 64.0,
             downlink_rate_mbps: 48.0,
             data_rate_mb_s: 8.0,
             downlink_rate_mb_s: 6.0,
             actual_data_rate_mbps: 32.0,
             actual_downlink_rate_mbps: 28.0,
             actual_data_rate_mb_s: 4.0,
             actual_downlink_rate_mb_s: 3.5,
             delivered_rate_mbps: 24.0,
             received_rate_mbps: 20.0,
             delivered_rate_mb_s: 3.0,
             received_rate_mb_s: 2.5,
             actual_duration_s: 55.0,
             actual_contact_duration_s: 54.0,
             contact_duration_s: 60.0,
             link_margin_db: 3.5,
             snr_db: 12.0,
             eb_no_db: 9.0,
             bit_error_rate: 1.0e-6,
             packet_loss_rate: 0.01,
             frame_loss_rate: 0.02,
             carrier_lock: true,
             symbol_lock: true,
             link_quality_status: "nominal",
             pointing_mode: "target_track",
             pointing_target_id: "target_a",
             boresight_axis: "+Z",
             off_nadir_angle_deg: 12.5,
             slew_angle_deg: 5.0,
             slew_rate_deg_s: 0.25,
             pointing_error_deg: 0.05,
             pointing_status: "declared",
             pointing_model: "operator_supplied",
             pointing_source: "mission_database",
             pointing_confidence: 0.9,
             thermal_zone_id: "payload_bus",
             temperature_c: 18.5,
             planned_temperature_c: 19.0,
             actual_temperature_c: 21.0,
             min_operating_temperature_c: -5.0,
             max_operating_temperature_c: 40.0,
             thermal_margin_c: 19.0,
             thermal_status: "nominal",
             thermal_model: "operator_supplied",
             thermal_source: "mission_database",
             thermal_confidence: 0.8,
             eclipse_overlap_fraction: 0.35,
             eclipse_overlap_s: 21.0,
             lighting_condition: "partial_eclipse",
             lighting_condition_detail: "mixed_lighting",
             lighting_condition_model: "sampled_eclipse_overlap_tag",
             lighting_detail_model: "sampled_eclipse_overlap_fraction_tag",
             lighting_confidence: "bounded_by_sampled_eclipse_overlap",
             command_window_id: "command_window:dl_1",
             command_window_type: "downlink_command_context",
             command_window: %{
               "id" => "command_window:dl_1",
               "type" => "downlink_command_context",
               "provider" => "cadence"
             },
             dependencies: ["cmd_ready"],
             dependency_activity_ids: ["cmd_ready"],
             dependency_timeline_ids: ["timeline:cmd_ready"],
             exclusive_with_activity_ids: ["dl_conflict"],
             exclusive_with_timeline_ids: ["timeline:dl_conflict"],
             exclusivity_group: "station_contact",
             source_window_id: "window:leo_1:equator_prime:1",
             source_window_type: "ground_station_access",
             source_window: %{
               "id" => "window:leo_1:equator_prime:1",
               "type" => "ground_station_access",
               "provider" => "candidate_refresh.v1"
             },
             cadence_import: %{
               "external_id" => "cadence:contact:dl_1",
               "activity_type" => "contact",
               "schema_contract" => "cadence_import_manifest.v1"
             },
             execution_uncertainty: %{"timing_3sigma_s" => 2.0},
             provenance: %{"source" => "candidate_refresh.v1"},
             metadata: %{"source" => "provider_row"},
             allow_overlap?: false
           } = activity

    assert Activity.to_artifact_map(activity)["timeline_id"] == "timeline:dl_1"
    assert Activity.to_artifact_map(activity)["collection_id"] == "collection_alpha"
    assert Activity.to_artifact_map(activity)["product_ids"] == ["image_alpha_1", "image_alpha_2"]
    assert Activity.to_artifact_map(activity)["target_priority"] == 4.5
    assert Activity.to_artifact_map(activity)["target_priority_source"] == "operator_objective"

    assert Activity.to_artifact_map(activity)["target_priority_objective_ids"] == [
             "latency:collection_alpha"
           ]

    assert Activity.to_artifact_map(activity)["target_priority_objective_type"] ==
             "collection_latency"

    assert Activity.to_artifact_map(activity)["battery_energy_generated_wh"] == 45.0
    assert Activity.to_artifact_map(activity)["contact_success"] == false
    assert Activity.to_artifact_map(activity)["contact_success_factor"] == 0.25
    assert Activity.to_artifact_map(activity)["command_success"] == true
    assert Activity.to_artifact_map(activity)["command_success_factor"] == 0.9
    assert Activity.to_artifact_map(activity)["observation_success"] == true
    assert Activity.to_artifact_map(activity)["observation_success_factor"] == 0.8
    assert Activity.to_artifact_map(activity)["image_quality_score"] == 0.84
    assert Activity.to_artifact_map(activity)["image_quality_status"] == "usable"

    assert Activity.to_artifact_map(activity)["image_quality_source"] ==
             "provider_observation_review"

    assert Activity.to_artifact_map(activity)["cloud_cover_fraction"] == 0.18
    assert Activity.to_artifact_map(activity)["blur_score"] == 0.06
    assert Activity.to_artifact_map(activity)["maneuver_success"] == false
    assert Activity.to_artifact_map(activity)["maneuver_success_factor"] == 0.4
    assert Activity.to_artifact_map(activity)["feedback_weight"] == 0.7

    assert Activity.to_artifact_map(activity)["data_volume_mb"] == 120.0
    assert Activity.to_artifact_map(activity)["target_data_volume_mb"] == 140.0
    assert Activity.to_artifact_map(activity)["selected_data_volume_mb"] == 90.0
    assert Activity.to_artifact_map(activity)["selected_data_volume_shortfall_mb"] == 50.0
    assert Activity.to_artifact_map(activity)["downlink_requirement_status"] == "shortfall"
    assert Activity.to_artifact_map(activity)["actual_data_volume_mb"] == 90.0
    assert Activity.to_artifact_map(activity)["planned_estimated_throughput_mb"] == 118.0
    assert Activity.to_artifact_map(activity)["actual_throughput_mb"] == 96.0
    assert Activity.to_artifact_map(activity)["frequency_band"] == "x_band"
    assert Activity.to_artifact_map(activity)["data_rate_mbps"] == 64.0
    assert Activity.to_artifact_map(activity)["downlink_rate_mbps"] == 48.0
    assert Activity.to_artifact_map(activity)["data_rate_mb_s"] == 8.0
    assert Activity.to_artifact_map(activity)["downlink_rate_mb_s"] == 6.0
    assert Activity.to_artifact_map(activity)["actual_data_rate_mbps"] == 32.0
    assert Activity.to_artifact_map(activity)["actual_downlink_rate_mbps"] == 28.0
    assert Activity.to_artifact_map(activity)["actual_data_rate_mb_s"] == 4.0
    assert Activity.to_artifact_map(activity)["actual_downlink_rate_mb_s"] == 3.5
    assert Activity.to_artifact_map(activity)["delivered_rate_mbps"] == 24.0
    assert Activity.to_artifact_map(activity)["received_rate_mbps"] == 20.0
    assert Activity.to_artifact_map(activity)["delivered_rate_mb_s"] == 3.0
    assert Activity.to_artifact_map(activity)["received_rate_mb_s"] == 2.5
    assert Activity.to_artifact_map(activity)["actual_duration_s"] == 55.0
    assert Activity.to_artifact_map(activity)["actual_contact_duration_s"] == 54.0
    assert Activity.to_artifact_map(activity)["contact_duration_s"] == 60.0
    assert Activity.to_artifact_map(activity)["link_margin_db"] == 3.5
    assert Activity.to_artifact_map(activity)["eb_no_db"] == 9.0
    assert Activity.to_artifact_map(activity)["carrier_lock"] == true
    assert Activity.to_artifact_map(activity)["link_quality_status"] == "nominal"
    assert Activity.to_artifact_map(activity)["resource_source_quality"] == "declared"
    assert Activity.to_artifact_map(activity)["resource_trust_boundary"] == "operator_supplied"
    assert Activity.to_artifact_map(activity)["resource_blocking_dimension"] == "power"
    assert Activity.to_artifact_map(activity)["battery_state_of_charge"] == 0.68
    assert Activity.to_artifact_map(activity)["payload_available"] == false
    assert Activity.to_artifact_map(activity)["suppressed_activity_types"] == ["downlink"]
    assert Activity.to_artifact_map(activity)["pointing_mode"] == "target_track"
    assert Activity.to_artifact_map(activity)["off_nadir_angle_deg"] == 12.5
    assert Activity.to_artifact_map(activity)["thermal_zone_id"] == "payload_bus"
    assert Activity.to_artifact_map(activity)["actual_temperature_c"] == 21.0
    assert Activity.to_artifact_map(activity)["eclipse_overlap_fraction"] == 0.35
    assert Activity.to_artifact_map(activity)["eclipse_overlap_s"] == 21.0
    assert Activity.to_artifact_map(activity)["lighting_condition"] == "partial_eclipse"
    assert Activity.to_artifact_map(activity)["lighting_condition_detail"] == "mixed_lighting"

    assert Activity.to_artifact_map(activity)["lighting_condition_model"] ==
             "sampled_eclipse_overlap_tag"

    assert Activity.to_artifact_map(activity)["lighting_detail_model"] ==
             "sampled_eclipse_overlap_fraction_tag"

    assert Activity.to_artifact_map(activity)["lighting_confidence"] ==
             "bounded_by_sampled_eclipse_overlap"

    assert Activity.to_artifact_map(activity)["command_window_id"] == "command_window:dl_1"

    assert Activity.to_artifact_map(activity)["command_window_type"] ==
             "downlink_command_context"

    assert Activity.to_artifact_map(activity)["command_window"] == %{
             "id" => "command_window:dl_1",
             "type" => "downlink_command_context",
             "provider" => "cadence"
           }

    normalized = OrbitalDynamics.normalize_timeline_activity(Activity.to_artifact_map(activity))

    assert normalized["timeline_identity"]["timeline_id"] == "timeline:dl_1"
    assert normalized["timeline_identity"]["scenario_id"] == "leo_1"
    assert normalized["activity_context"]["collection_id"] == "collection_alpha"
    assert normalized["activity_context"]["product_id"] == "image_alpha_1"
    assert normalized["activity_context"]["payload_id"] == "camera_a"
    assert normalized["activity_context"]["instrument_id"] == "wide_field"
    assert normalized["activity_context"]["target_priority"] == 4.5
    assert normalized["activity_context"]["target_priority_source"] == "operator_objective"

    assert normalized["activity_context"]["target_priority_objective_ids"] == [
             "latency:collection_alpha"
           ]

    assert normalized["activity_context"]["target_priority_objective_type"] ==
             "collection_latency"

    assert normalized["activity_context"]["contact_success"] == false
    assert normalized["activity_context"]["contact_result"] == "carrier_lock_lost"
    assert normalized["activity_context"]["contact_success_factor"] == 0.25
    assert normalized["activity_context"]["contact_success_factor_source"] == "provider_feedback"
    assert normalized["activity_context"]["command_success"] == true
    assert normalized["activity_context"]["command_result"] == "accepted"
    assert normalized["activity_context"]["command_success_factor"] == 0.9
    assert normalized["activity_context"]["command_success_factor_source"] == "operator_review"
    assert normalized["activity_context"]["observation_success"] == true
    assert normalized["activity_context"]["observation_result"] == "usable"
    assert normalized["activity_context"]["observation_success_factor"] == 0.8

    assert normalized["activity_context"]["observation_success_factor_source"] ==
             "image_quality_review"

    assert normalized["activity_context"]["image_quality_score"] == 0.84
    assert normalized["activity_context"]["image_quality_status"] == "usable"
    assert normalized["activity_context"]["image_quality_source"] == "provider_observation_review"
    assert normalized["activity_context"]["cloud_cover_fraction"] == 0.18
    assert normalized["activity_context"]["blur_score"] == 0.06

    assert normalized["activity_context"]["maneuver_success"] == false
    assert normalized["activity_context"]["maneuver_result"] == "delta_v_shortfall"
    assert normalized["activity_context"]["maneuver_success_factor"] == 0.4
    assert normalized["activity_context"]["maneuver_success_factor_source"] == "maneuver_review"
    assert normalized["activity_context"]["feedback_weight"] == 0.7
    assert normalized["activity_context"]["feedback_weight_source"] == "operator_weight"

    assert normalized["activity_context"]["resource_id"] == "payload_bus"
    assert normalized["activity_context"]["resource_source_quality"] == "declared"
    assert normalized["activity_context"]["resource_trust_boundary"] == "operator_supplied"
    assert normalized["activity_context"]["resource_trust_boundary_status"] == "declared"

    assert normalized["activity_context"]["resource_provenance"] == %{
             "source" => "mission_database"
           }

    assert normalized["activity_context"]["resource_blocking_dimension"] == "power"
    assert normalized["activity_context"]["fuel_margin"] == 0.72
    assert normalized["activity_context"]["power_margin"] == 0.35
    assert normalized["activity_context"]["storage_margin"] == 0.42
    assert normalized["activity_context"]["downlink_margin"] == 0.51
    assert normalized["activity_context"]["battery_capacity_wh"] == 240.0
    assert normalized["activity_context"]["battery_energy_used_wh"] == 88.0
    assert normalized["activity_context"]["battery_energy_generated_wh"] == 45.0
    assert normalized["activity_context"]["battery_state_of_charge"] == 0.68
    assert normalized["activity_context"]["spacecraft_available"] == true
    assert normalized["activity_context"]["payload_available"] == false
    assert normalized["activity_context"]["antenna_available"] == true
    assert normalized["activity_context"]["degraded"] == true
    assert normalized["activity_context"]["mode"] == "payload_safe"
    assert normalized["activity_context"]["incompatible_activity_types"] == ["observe"]
    assert normalized["activity_context"]["suppressed_activity_types"] == ["downlink"]
    assert normalized["activity_context"]["data_volume_mb"] == 120.0
    assert normalized["activity_context"]["planned_data_volume_mb"] == 120.0
    assert normalized["activity_context"]["actual_data_volume_mb"] == 90.0
    assert normalized["activity_context"]["target_data_volume_mb"] == 140.0
    assert normalized["activity_context"]["selected_data_volume_mb"] == 90.0
    assert normalized["activity_context"]["selected_data_volume_shortfall_mb"] == 50.0
    assert normalized["activity_context"]["downlink_requirement_status"] == "shortfall"

    assert normalized["activity_context"]["downlink_completion_sources"] == [
             "provider.collection:collection_alpha"
           ]

    assert normalized["activity_context"]["data_volume_delta_mb"] == -30.0
    assert normalized["activity_context"]["data_volume_completion_fraction"] == 0.75
    assert normalized["activity_context"]["collection_ends_at_s"] == 360.0
    assert normalized["activity_context"]["planned_delivery_at_s"] == 540.0
    assert normalized["activity_context"]["actual_delivery_at_s"] == 550.0
    assert normalized["activity_context"]["max_latency_s"] == 240.0
    assert normalized["activity_context"]["planned_latency_s"] == 180.0
    assert normalized["activity_context"]["actual_latency_s"] == 190.0
    assert normalized["activity_context"]["latency_delta_s"] == 10.0
    assert normalized["activity_context"]["latency_margin_s"] == 50.0
    assert normalized["activity_context"]["planned_estimated_throughput_mb"] == 118.0
    assert normalized["activity_context"]["actual_throughput_mb"] == 96.0
    assert normalized["activity_context"]["throughput_delta_mb"] == -22.0
    assert normalized["activity_context"]["link_protocol"] == "space_packet"
    assert normalized["activity_context"]["frequency_band"] == "x_band"
    assert normalized["activity_context"]["modulation"] == "qpsk"
    assert normalized["activity_context"]["coding_scheme"] == "ldpc"
    assert normalized["activity_context"]["polarization"] == "rhcp"
    assert normalized["activity_context"]["data_rate_mbps"] == 64.0
    assert normalized["activity_context"]["downlink_rate_mbps"] == 48.0
    assert normalized["activity_context"]["data_rate_mb_s"] == 8.0
    assert normalized["activity_context"]["downlink_rate_mb_s"] == 6.0
    assert normalized["activity_context"]["actual_data_rate_mbps"] == 32.0
    assert normalized["activity_context"]["actual_downlink_rate_mbps"] == 28.0
    assert normalized["activity_context"]["actual_data_rate_mb_s"] == 4.0
    assert normalized["activity_context"]["actual_downlink_rate_mb_s"] == 3.5
    assert normalized["activity_context"]["delivered_rate_mbps"] == 24.0
    assert normalized["activity_context"]["received_rate_mbps"] == 20.0
    assert normalized["activity_context"]["delivered_rate_mb_s"] == 3.0
    assert normalized["activity_context"]["received_rate_mb_s"] == 2.5
    assert normalized["activity_context"]["actual_duration_s"] == 55.0
    assert normalized["activity_context"]["actual_contact_duration_s"] == 54.0
    assert normalized["activity_context"]["contact_duration_s"] == 60.0
    assert normalized["activity_context"]["link_margin_db"] == 3.5
    assert normalized["activity_context"]["snr_db"] == 12.0
    assert normalized["activity_context"]["eb_no_db"] == 9.0
    assert normalized["activity_context"]["bit_error_rate"] == 1.0e-6
    assert normalized["activity_context"]["packet_loss_rate"] == 0.01
    assert normalized["activity_context"]["frame_loss_rate"] == 0.02
    assert normalized["activity_context"]["carrier_lock"] == true
    assert normalized["activity_context"]["symbol_lock"] == true
    assert normalized["activity_context"]["link_quality_status"] == "nominal"
    assert normalized["activity_context"]["pointing_mode"] == "target_track"
    assert normalized["activity_context"]["pointing_target_id"] == "target_a"
    assert normalized["activity_context"]["boresight_axis"] == "+Z"
    assert normalized["activity_context"]["off_nadir_angle_deg"] == 12.5
    assert normalized["activity_context"]["slew_rate_deg_s"] == 0.25
    assert normalized["activity_context"]["pointing_confidence"] == 0.9
    assert normalized["activity_context"]["thermal_zone_id"] == "payload_bus"
    assert normalized["activity_context"]["planned_temperature_c"] == 19.0
    assert normalized["activity_context"]["actual_temperature_c"] == 21.0
    assert normalized["activity_context"]["thermal_margin_c"] == 19.0
    assert normalized["activity_context"]["thermal_confidence"] == 0.8
    assert normalized["activity_context"]["eclipse_overlap_fraction"] == 0.35
    assert normalized["activity_context"]["eclipse_overlap_s"] == 21.0
    assert normalized["activity_context"]["lighting_condition"] == "partial_eclipse"
    assert normalized["activity_context"]["lighting_condition_detail"] == "mixed_lighting"

    assert normalized["activity_context"]["lighting_condition_model"] ==
             "sampled_eclipse_overlap_tag"

    assert normalized["activity_context"]["lighting_detail_model"] ==
             "sampled_eclipse_overlap_fraction_tag"

    assert normalized["activity_context"]["lighting_confidence"] ==
             "bounded_by_sampled_eclipse_overlap"

    assert normalized["activity_context"]["command_window_id"] == "command_window:dl_1"

    assert normalized["activity_context"]["command_window_type"] ==
             "downlink_command_context"
  end

  test "accepts command window aliases at artifact ingress" do
    activity =
      Activity.from_map!(%{
        "id" => "cmd_1",
        "type" => "command",
        "start_s" => 10.0,
        "end_s" => 20.0,
        "window_type" => "uplink_window",
        "command_window_ref" => "command_window:cmd_1"
      })

    assert activity.command_window_id == "command_window:cmd_1"
    assert activity.command_window_type == "uplink_window"
    assert Activity.to_artifact_map(activity)["command_window_id"] == "command_window:cmd_1"
    assert Activity.to_artifact_map(activity)["command_window_type"] == "uplink_window"
  end

  test "canonicalizes battery energy generation aliases at artifact ingress" do
    aliases = [
      "battery_energy_generated_wh",
      "energy_generated_wh",
      "estimated_energy_generated_wh",
      "estimated_battery_energy_generated_wh",
      "planned_energy_generated_wh"
    ]

    for {field, index} <- Enum.with_index(aliases, 1) do
      activity =
        Activity.from_map!(%{
          "id" => "battery_generation_alias_#{index}",
          "type" => "command",
          "start_s" => 10.0,
          "end_s" => 20.0,
          field => "#{40 + index}.5"
        })

      assert activity.battery_energy_generated_wh == 40 + index + 0.5
      assert Activity.to_artifact_map(activity)["battery_energy_generated_wh"] == 40 + index + 0.5

      refute Map.has_key?(Activity.to_artifact_map(activity), field) and
               field != "battery_energy_generated_wh"
    end
  end

  test "canonicalizes cadence import aliases at artifact ingress" do
    activity =
      Activity.from_map!(%{
        "id" => "cmd_import_alias",
        "type" => "command",
        "start_s" => 10.0,
        "end_s" => 20.0,
        "cadence_import" => %{
          "id" => "cadence:cmd_import_alias",
          "import_type" => "command",
          "contract" => "proposed_contact.v1",
          "provider" => "cadence",
          "adapter" => "cadence_command_adapter",
          "trust_boundary" => "orbital_dynamics_to_cadence_adapter"
        }
      })

    assert activity.cadence_import == %{
             "external_id" => "cadence:cmd_import_alias",
             "activity_type" => "command",
             "schema_contract" => "proposed_contact.v1",
             "provider" => "cadence",
             "adapter" => "cadence_command_adapter",
             "trust_boundary" => "orbital_dynamics_to_cadence_adapter"
           }

    artifact_map = Activity.to_artifact_map(activity)

    assert artifact_map["cadence_import"] == activity.cadence_import
    refute Map.has_key?(artifact_map["cadence_import"], "id")
    refute Map.has_key?(artifact_map["cadence_import"], "import_type")
    refute Map.has_key?(artifact_map["cadence_import"], "contract")
  end

  test "rejects malformed lighting numeric fields at artifact ingress" do
    assert_raise ArgumentError, ~r/number fields must be numbers/, fn ->
      Activity.from_map!(%{
        "id" => "obs_bad_lighting",
        "type" => "observe",
        "start_s" => 10.0,
        "end_s" => 20.0,
        "target_id" => "target_a",
        "eclipse_overlap_fraction" => "not-a-number"
      })
    end
  end

  test "accepts persistent timeline id aliases at artifact ingress" do
    activity =
      Activity.from_map!(%{
        "id" => "cmd_1",
        "type" => "command",
        "start_s" => 10.0,
        "end_s" => 20.0,
        "persistent_id" => "timeline:cmd_1"
      })

    assert activity.timeline_id == "timeline:cmd_1"
    assert Activity.to_artifact_map(activity)["timeline_id"] == "timeline:cmd_1"
  end

  test "round trips explicit dependency and exclusivity stable-id arrays" do
    activity =
      Activity.command!(:cmd_execute, 20.0, 30.0,
        scenario_id: :leo_1,
        spacecraft_id: :sat_1,
        dependency_activity_ids: [:cmd_prepare],
        dependency_timeline_ids: [:"timeline:cmd_prepare"],
        exclusive_with_activity_ids: [:dl_conflict],
        exclusive_with_timeline_ids: [:"timeline:dl_conflict"]
      )

    assert activity.dependencies == [:cmd_prepare]
    assert activity.scenario_id == :leo_1
    assert activity.spacecraft_id == :sat_1
    assert activity.dependency_activity_ids == [:cmd_prepare]
    assert activity.dependency_timeline_ids == [:"timeline:cmd_prepare"]
    assert activity.exclusive_with_activity_ids == [:dl_conflict]
    assert activity.exclusive_with_timeline_ids == [:"timeline:dl_conflict"]

    artifact_map = Activity.to_artifact_map(activity)

    assert %{
             "scenario_id" => "leo_1",
             "spacecraft_id" => "sat_1",
             "dependencies" => ["cmd_prepare"],
             "dependency_activity_ids" => ["cmd_prepare"],
             "dependency_timeline_ids" => ["timeline:cmd_prepare"],
             "exclusive_with_activity_ids" => ["dl_conflict"],
             "exclusive_with_timeline_ids" => ["timeline:dl_conflict"]
           } = artifact_map

    assert %Activity{
             scenario_id: "leo_1",
             spacecraft_id: "sat_1",
             dependencies: ["cmd_prepare"],
             dependency_activity_ids: ["cmd_prepare"],
             dependency_timeline_ids: ["timeline:cmd_prepare"],
             exclusive_with_activity_ids: ["dl_conflict"],
             exclusive_with_timeline_ids: ["timeline:dl_conflict"]
           } = Activity.from_map!(artifact_map)

    normalized = OrbitalDynamics.normalize_timeline_activity(artifact_map)

    assert normalized["dependency_activity_ids"] == ["cmd_prepare"]
    assert normalized["scenario_id"] == "leo_1"
    assert normalized["spacecraft_id"] == "sat_1"
    assert normalized["timeline_identity"]["scenario_id"] == "leo_1"
    assert normalized["dependency_timeline_ids"] == ["timeline:cmd_prepare"]
    assert normalized["exclusive_with_activity_ids"] == ["dl_conflict"]
    assert normalized["exclusive_with_timeline_ids"] == ["timeline:dl_conflict"]
  end

  test "normalizes provider scalar dependency and exclusivity id strings" do
    activity =
      Activity.from_map!(%{
        "id" => "cmd_execute",
        "type" => "command",
        "start_s" => 20.0,
        "end_s" => 30.0,
        "depends_on_activity_ids" => "cmd_prepare, obs_calibrate",
        "depends_on_timeline_ids" => "timeline:cmd_prepare, timeline:obs_calibrate",
        "exclusive_with" => "dl_conflict, cmd_conflict",
        "exclusive_with_timeline_ids" => "timeline:dl_conflict"
      })

    assert activity.dependencies == ["cmd_prepare", "obs_calibrate"]
    assert activity.dependency_activity_ids == ["cmd_prepare", "obs_calibrate"]
    assert activity.dependency_timeline_ids == ["timeline:cmd_prepare", "timeline:obs_calibrate"]
    assert activity.exclusive_with_activity_ids == ["dl_conflict", "cmd_conflict"]
    assert activity.exclusive_with_timeline_ids == ["timeline:dl_conflict"]

    artifact_map = Activity.to_artifact_map(activity)

    assert artifact_map["dependencies"] == ["cmd_prepare", "obs_calibrate"]
    assert artifact_map["dependency_activity_ids"] == ["cmd_prepare", "obs_calibrate"]

    assert artifact_map["dependency_timeline_ids"] == [
             "timeline:cmd_prepare",
             "timeline:obs_calibrate"
           ]

    assert artifact_map["exclusive_with_activity_ids"] == ["dl_conflict", "cmd_conflict"]
    assert artifact_map["exclusive_with_timeline_ids"] == ["timeline:dl_conflict"]

    constructor_activity =
      Activity.command!(:cmd_constructor, 40.0, 50.0,
        dependency_activity_ids: "cmd_prepare, obs_calibrate",
        exclusive_with: "dl_conflict"
      )

    assert constructor_activity.dependencies == ["cmd_prepare", "obs_calibrate"]
    assert constructor_activity.dependency_activity_ids == ["cmd_prepare", "obs_calibrate"]
    assert constructor_activity.exclusive_with_activity_ids == ["dl_conflict"]
  end

  test "derives canonical dependency ids from legacy dependency objects" do
    activity =
      Activity.command!(:cmd_execute, 20.0, 30.0,
        dependencies: [
          :cmd_prepare,
          %{activity_id: :obs_calibrate, timeline_id: :"timeline:obs_calibrate"}
        ]
      )

    assert activity.dependencies == [
             :cmd_prepare,
             %{activity_id: :obs_calibrate, timeline_id: :"timeline:obs_calibrate"}
           ]

    assert activity.dependency_activity_ids == [:cmd_prepare, :obs_calibrate]

    artifact_map = Activity.to_artifact_map(activity)

    assert artifact_map["dependency_activity_ids"] == ["cmd_prepare", "obs_calibrate"]

    assert %Activity{
             dependencies: [
               "cmd_prepare",
               %{"activity_id" => "obs_calibrate", "timeline_id" => "timeline:obs_calibrate"}
             ],
             dependency_activity_ids: ["cmd_prepare", "obs_calibrate"]
           } = Activity.from_map!(artifact_map)
  end

  test "preserves explicit false canonical booleans over alias booleans at artifact ingress" do
    activity =
      Activity.from_map!(%{
        "id" => "cmd_unlocked",
        "type" => "command",
        "start_s" => 10.0,
        "end_s" => 20.0,
        "locked" => "false",
        "locked?" => "true",
        "allow_overlap?" => "0"
      })

    refute activity.locked?
    refute activity.allow_overlap?

    atom_keyed_activity =
      Activity.from_map!(%{
        :id => "cmd_atom_unlocked",
        :type => "command",
        :start_s => 30.0,
        :end_s => 40.0,
        :locked => false,
        "locked" => "true",
        :allow_overlap? => false,
        "allow_overlap?" => "true"
      })

    refute atom_keyed_activity.locked?
    refute atom_keyed_activity.allow_overlap?
  end

  test "normalizes numeric string activity timing delta-v and uncertainty at artifact ingress" do
    contact =
      Activity.from_map!(%{
        "id" => "dl_2",
        "type" => "planned_contact",
        "starts_at_s" => "100.5",
        "ends_at_s" => "160.25",
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "execution_uncertainty" => %{
          "timing_3sigma_s" => "2.5",
          "delta_v_3sigma_km_s" => ["0.001", "0.002", "0.003"],
          "delta_v_3sigma_magnitude_km_s" => "0.0037",
          "source" => "operator_estimate"
        }
      })

    assert contact.start_s == 100.5
    assert contact.end_s == 160.25

    assert contact.execution_uncertainty == %{
             "timing_3sigma_s" => 2.5,
             "delta_v_3sigma_km_s" => [0.001, 0.002, 0.003],
             "delta_v_3sigma_magnitude_km_s" => 0.0037,
             "source" => "operator_estimate"
           }

    burn =
      Activity.from_map!(%{
        "id" => "trim_burn",
        "type" => "impulsive_burn",
        "epoch_s" => "60.0",
        "delta_v_km_s" => ["0.0", "0.01", "-0.001"],
        "frame" => "eci_j2000"
      })

    assert burn.epoch_s == 60.0
    assert burn.delta_v_km_s == {0.0, 0.01, -0.001}
  end

  test "round trips typed activities through JSON-facing artifact maps" do
    activity =
      Activity.impulsive_burn!(:raise_apogee, 60.0, {0.0, 0.01, 0.0},
        frame: Frame.earth_inertial_j2000(),
        execution_uncertainty: %{timing_3sigma_s: 2.0, delta_v_3sigma_km_s: [0.0, 0.0001, 0.0]},
        provenance: %{source: :operator_estimate}
      )

    artifact_map = Activity.to_artifact_map(activity)

    assert artifact_map["id"] == "raise_apogee"
    assert artifact_map["type"] == "impulsive_burn"
    assert artifact_map["epoch_s"] == 60.0
    assert artifact_map["delta_v_km_s"] == [0.0, 0.01, 0.0]
    assert artifact_map["frame"] == "eci_j2000"

    assert artifact_map["execution_uncertainty"] == %{
             "timing_3sigma_s" => 2.0,
             "delta_v_3sigma_km_s" => [0.0, 0.0001, 0.0]
           }

    assert artifact_map["provenance"] == %{"source" => "operator_estimate"}

    round_tripped = Activity.from_map!(artifact_map)

    assert round_tripped.id == "raise_apogee"
    assert round_tripped.type == activity.type
    assert round_tripped.epoch_s == activity.epoch_s
    assert round_tripped.delta_v_km_s == activity.delta_v_km_s
    assert round_tripped.frame == activity.frame

    assert round_tripped.execution_uncertainty == %{
             "timing_3sigma_s" => 2.0,
             "delta_v_3sigma_km_s" => [0.0, 0.0001, 0.0]
           }

    assert round_tripped.provenance == %{"source" => "operator_estimate"}
  end

  test "top-level API exposes typed activity artifact ingress and egress" do
    activity =
      OrbitalDynamics.mission_plan_activity_from_map(%{
        "id" => "cmd_pass",
        "type" => "command",
        "start_s" => 10.0,
        "end_s" => 20.0,
        "ground_station_id" => "dss_14",
        "direction" => "uplink",
        "approval_status" => "pending"
      })

    assert activity.type == :command
    assert activity.direction == :uplink
    assert activity.approval_status == :pending

    assert OrbitalDynamics.mission_plan_activity_from_map!(%{
             "id" => "cmd_pass_bang",
             "type" => "command",
             "start_s" => 10.0,
             "end_s" => 20.0
           }).type == :command

    assert %{
             "id" => "cmd_pass",
             "type" => "command",
             "ground_station_id" => "dss_14",
             "direction" => "uplink",
             "approval_status" => "pending"
           } = OrbitalDynamics.mission_plan_activity_to_artifact_map(activity)
  end

  test "top-level API exposes typed activity lifecycle helpers" do
    activity = %{
      "id" => "cmd_lifecycle",
      "type" => "command",
      "start_s" => 10.0,
      "end_s" => 20.0,
      "ground_station_id" => "dss_14",
      "direction" => "uplink"
    }

    assert %Activity{status: :approved, approval_status: :approved} =
             OrbitalDynamics.mission_plan_activity_approve(activity)

    assert %Activity{status: :approved, approval_status: :approved} =
             OrbitalDynamics.mission_plan_activity_approve!(activity)

    assert %Activity{status: :locked, approval_status: :locked, locked?: true} =
             OrbitalDynamics.mission_plan_activity_lock(activity)

    assert %Activity{status: :locked, approval_status: :locked, locked?: true} =
             OrbitalDynamics.mission_plan_activity_lock!(activity)

    assert %Activity{status: :executing} =
             OrbitalDynamics.mission_plan_activity_start_execution(activity)

    assert %Activity{status: :executing} =
             OrbitalDynamics.mission_plan_activity_start_execution!(activity)

    assert %Activity{status: :executed} =
             OrbitalDynamics.mission_plan_activity_record_execution(activity)

    assert %Activity{status: :executed} =
             OrbitalDynamics.mission_plan_activity_record_execution!(activity)

    assert %Activity{status: :completed} =
             OrbitalDynamics.mission_plan_activity_record_completion(activity)

    assert %Activity{status: :completed} =
             OrbitalDynamics.mission_plan_activity_record_completion!(activity)

    assert %Activity{status: :partial} =
             OrbitalDynamics.mission_plan_activity_record_partial(activity)

    assert %Activity{status: :partial} =
             OrbitalDynamics.mission_plan_activity_record_partial!(activity)

    assert %Activity{status: :failed} =
             OrbitalDynamics.mission_plan_activity_record_failure(activity)

    assert %Activity{status: :failed} =
             OrbitalDynamics.mission_plan_activity_record_failure!(activity)

    assert %Activity{status: :missed} =
             OrbitalDynamics.mission_plan_activity_record_miss(activity)

    assert %Activity{status: :missed} =
             OrbitalDynamics.mission_plan_activity_record_miss!(activity)

    assert %Activity{status: :delayed} = OrbitalDynamics.mission_plan_activity_delay(activity)
    assert %Activity{status: :delayed} = OrbitalDynamics.mission_plan_activity_delay!(activity)
    assert %Activity{status: :canceled} = OrbitalDynamics.mission_plan_activity_cancel(activity)
    assert %Activity{status: :canceled} = OrbitalDynamics.mission_plan_activity_cancel!(activity)

    assert %Activity{status: :completed} =
             OrbitalDynamics.mission_plan_activity_apply_lifecycle_event(
               activity,
               "record completion"
             )

    assert %Activity{status: :completed} =
             OrbitalDynamics.mission_plan_activity_apply_lifecycle_event!(
               activity,
               "record completion"
             )

    assert %Activity{status: :executed} =
             OrbitalDynamics.mission_plan_activity_apply_lifecycle_event!(activity, :executed)

    assert %Activity{status: :canceled} =
             OrbitalDynamics.mission_plan_activity_apply_lifecycle_event!(activity, "cancelled")

    assert %Activity{status: :executing} =
             OrbitalDynamics.mission_plan_activity_apply_lifecycle_event!(activity, "in progress")

    assert %Activity{status: :failed} =
             OrbitalDynamics.mission_plan_activity_apply_lifecycle_event!(activity, "timed out")

    assert %Activity{status: :completed} =
             OrbitalDynamics.mission_plan_activity_apply_lifecycle_event!(activity, "succeeded")

    assert %Activity{status: :missed} =
             OrbitalDynamics.mission_plan_activity_apply_lifecycle_event!(activity, "skipped")

    assert %Activity{status: :failed} =
             OrbitalDynamics.mission_plan_activity_put_status(activity, :failed)

    assert %Activity{status: :failed} =
             OrbitalDynamics.mission_plan_activity_put_status!(activity, :failed)

    assert %Activity{status: :completed} =
             OrbitalDynamics.mission_plan_activity_put_status!(activity, "succeeded")

    assert %Activity{status: :failed} =
             OrbitalDynamics.mission_plan_activity_put_status!(activity, "timed out")

    assert %{
             "from" => "planned",
             "to" => "executing",
             "safe_to_apply" => true
           } = OrbitalDynamics.mission_plan_activity_status_transition(activity, "In Progress")

    assert %Activity{status: :executing} =
             OrbitalDynamics.mission_plan_activity_transition_status(activity, "In Progress")

    assert %Activity{status: :executing} =
             OrbitalDynamics.mission_plan_activity_transition_status!(activity, "In Progress")

    completed_activity = Map.put(activity, "status", "completed")

    assert %{
             "from" => "completed",
             "to" => "planned",
             "safe_to_apply" => false,
             "operator_action_reason" => "terminal_or_executed_status_change_requires_review"
           } =
             OrbitalDynamics.mission_plan_activity_status_transition(completed_activity, :planned)

    assert_raise ArgumentError,
                 ~r/unsafe lifecycle status transition completed -> planned/,
                 fn ->
                   OrbitalDynamics.mission_plan_activity_transition_status!(
                     completed_activity,
                     :planned
                   )
                 end

    assert %Activity{approval_status: :operator_review_required} =
             OrbitalDynamics.mission_plan_activity_put_approval_status(
               activity,
               "operator_review_required"
             )

    assert %Activity{approval_status: :operator_review_required} =
             OrbitalDynamics.mission_plan_activity_put_approval_status!(
               activity,
               "operator_review_required"
             )

    assert %Activity{approval_status: :blocked_by_policy} =
             OrbitalDynamics.mission_plan_activity_put_approval_status!(
               activity,
               "policy blocked"
             )

    assert %{
             "from" => "not_required",
             "to" => "operator_review_required",
             "safe_to_apply" => true
           } =
             OrbitalDynamics.mission_plan_activity_approval_transition(
               activity,
               "review required"
             )

    assert %Activity{approval_status: :operator_review_required} =
             OrbitalDynamics.mission_plan_activity_transition_approval_status(
               activity,
               "review required"
             )

    assert %Activity{approval_status: :operator_review_required} =
             OrbitalDynamics.mission_plan_activity_transition_approval_status!(
               activity,
               "review required"
             )

    approved_activity = Map.put(activity, "approval_status", "operator_review_required")

    assert %{
             "from" => "operator_review_required",
             "to" => "approved",
             "safe_to_apply" => false,
             "operator_action_reason" => "approval_grant_requires_operator_authority"
           } =
             OrbitalDynamics.mission_plan_activity_approval_transition(
               approved_activity,
               :approved
             )

    assert_raise ArgumentError,
                 ~r/unsafe approval status transition operator_review_required -> approved/,
                 fn ->
                   OrbitalDynamics.mission_plan_activity_transition_approval_status!(
                     approved_activity,
                     :approved
                   )
                 end

    assert %Activity{status: :planned, approval_status: :rejected} =
             OrbitalDynamics.mission_plan_activity_reject!(activity)

    assert %Activity{status: :planned, approval_status: :rejected} =
             OrbitalDynamics.mission_plan_activity_reject(activity)

    assert_raise ArgumentError, ~r/status must be one of/, fn ->
      OrbitalDynamics.mission_plan_activity_put_status!(activity, :garbage)
    end
  end

  test "rejects invalid activity fields" do
    assert_raise ArgumentError, ~r/end_s must be greater/, fn ->
      Activity.downlink!(:downlink, 20.0, 10.0, :dss_14)
    end

    assert_raise ArgumentError, ~r/delta_v_km_s/, fn ->
      Activity.impulsive_burn!(:bad_burn, 60.0, {0.0, 0.0})
    end

    assert_raise ArgumentError, ~r/status must be one of/, fn ->
      Activity.health_check!(:bad_status, 10.0, 20.0, status: :garbage)
    end

    assert_raise ArgumentError, ~r/dependencies must be a list/, fn ->
      Activity.command!(:bad_dependencies, 10.0, 20.0, dependencies: ["ok", ""])
    end

    assert_raise ArgumentError, ~r/scenario_id must be nil or an identifier/, fn ->
      Activity.command!(:bad_scope, 10.0, 20.0, scenario_id: "")
    end

    assert_raise ArgumentError, ~r/dependency_timeline_ids must be a list/, fn ->
      Activity.command!(:bad_dependency_timelines, 10.0, 20.0,
        dependency_timeline_ids: ["timeline:ok", ""]
      )
    end

    assert_raise ArgumentError, ~r/dependency_activity_ids must be a list/, fn ->
      Activity.from_map!(%{
        "id" => "bad_comma_dependency",
        "type" => "command",
        "start_s" => 0.0,
        "end_s" => 1.0,
        "dependency_activity_ids" => "cmd_ok, ,"
      })
    end

    assert_raise ArgumentError, ~r/product_ids must be a list/, fn ->
      Activity.command!(:bad_product_ids, 10.0, 20.0, product_ids: ["product:ok", ""])
    end

    assert_raise ArgumentError, ~r/storage_margin must be nil or between 0\.0 and 1\.0/, fn ->
      Activity.command!(:bad_storage_margin, 10.0, 20.0, storage_margin: 128.0)
    end

    assert_raise ArgumentError, ~r/storage_margin must be between 0\.0 and 1\.0/, fn ->
      Activity.from_map!(%{
        "id" => "bad_storage_capacity_margin",
        "type" => "command",
        "start_s" => 0.0,
        "end_s" => 1.0,
        "storage_capacity_margin" => "1.2"
      })
    end

    assert_raise ArgumentError,
                 ~r/battery_energy_generated_wh must be nil or a non-negative number/,
                 fn ->
                   Activity.command!(
                     :bad_battery_generation,
                     10.0,
                     20.0,
                     battery_energy_generated_wh: -1.0
                   )
                 end

    assert_raise ArgumentError,
                 ~r/battery_energy_generated_wh must be a non-negative number/,
                 fn ->
                   Activity.from_map!(%{
                     "id" => "bad_battery_generation_alias",
                     "type" => "command",
                     "start_s" => 0.0,
                     "end_s" => 1.0,
                     "planned_energy_generated_wh" => "-1.0"
                   })
                 end

    assert_raise ArgumentError, ~r/battery_state_of_charge must be between 0\.0 and 1\.0/, fn ->
      Activity.from_map!(%{
        "id" => "bad_soc",
        "type" => "command",
        "start_s" => 0.0,
        "end_s" => 1.0,
        "battery_soc" => "1.2"
      })
    end

    assert_raise ArgumentError, ~r/pointing_confidence must be nil or a number/, fn ->
      Activity.observe!(:bad_pointing, 10.0, 20.0, :target_a, pointing_confidence: :high)
    end

    assert_raise ArgumentError, ~r/thermal_confidence must be nil or a number/, fn ->
      Activity.observe!(:bad_thermal, 10.0, 20.0, :target_a, thermal_confidence: :high)
    end

    assert_raise ArgumentError, ~r/actual_throughput_mb must be nil or a number/, fn ->
      Activity.downlink!(:bad_throughput, 10.0, 20.0, :ground_station_a,
        actual_throughput_mb: :unknown
      )
    end

    assert_raise ArgumentError, ~r/payload_available must be nil or a boolean/, fn ->
      Activity.observe!(:bad_payload_availability, 10.0, 20.0, :target_a,
        payload_available: :unknown
      )
    end

    assert_raise ArgumentError, ~r/exclusive_with_activity_ids must be a list/, fn ->
      Activity.command!(:bad_exclusions, 10.0, 20.0, exclusive_with_activity_ids: ["ok", ""])
    end

    assert_raise ArgumentError, ~r/execution_uncertainty must be nil or a map/, fn ->
      Activity.impulsive_burn!(:bad_uncertainty, 60.0, {0.0, 0.01, 0.0},
        execution_uncertainty: :unknown
      )
    end

    assert_raise ArgumentError, ~r/activity must be a map/, fn ->
      Activity.from_map!(:not_a_map)
    end

    assert_raise ArgumentError, ~r/type must be one of/, fn ->
      Activity.from_map!(%{"id" => "bad", "type" => "garbage", "start_s" => 0.0, "end_s" => 1.0})
    end

    assert_raise ArgumentError, ~r/health_check direction must be health_check/, fn ->
      Activity.from_map!(%{
        "id" => "bad_health_direction",
        "type" => "health_check",
        "start_s" => 0.0,
        "end_s" => 1.0,
        "direction" => "downlink"
      })
    end

    assert_raise ArgumentError, ~r/dependencies must be a list/, fn ->
      Activity.from_map!(%{
        "id" => "bad_deps",
        "type" => "command",
        "start_s" => 0.0,
        "end_s" => 1.0,
        "dependencies" => ["ok", ""]
      })
    end

    assert_raise ArgumentError, ~r/exclusive_with_timeline_ids must be a list/, fn ->
      Activity.from_map!(%{
        "id" => "bad_exclusive_timeline",
        "type" => "command",
        "start_s" => 0.0,
        "end_s" => 1.0,
        "exclusive_with_timeline_ids" => ["timeline:ok", ""]
      })
    end

    assert_raise ArgumentError, ~r/start_s must be a number/, fn ->
      Activity.from_map!(%{
        "id" => "bad_time",
        "type" => "command",
        "start_s" => "not numeric",
        "end_s" => 1.0
      })
    end

    assert_raise ArgumentError, ~r/boolean field must be a boolean/, fn ->
      Activity.from_map!(%{
        "id" => "bad_boolean",
        "type" => "command",
        "start_s" => 0.0,
        "end_s" => 1.0,
        "locked" => "maybe"
      })
    end

    assert_raise ArgumentError, ~r/delta_v_km_s/, fn ->
      Activity.from_map!(%{
        "id" => "bad_delta_v",
        "type" => "impulsive_burn",
        "epoch_s" => "60.0",
        "delta_v_km_s" => ["0.0", "bad", "0.0"]
      })
    end
  end
end
