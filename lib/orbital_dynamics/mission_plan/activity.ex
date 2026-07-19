defmodule OrbitalDynamics.MissionPlan.Activity do
  @moduledoc """
  Typed mission timeline activities.

  The first activity model is intentionally operational rather than exhaustive.
  `:impulsive_burn` activities compile into maneuver structs. Operational
  activities are preserved as plan metadata with status, approval, lock,
  dependency, exclusivity, provenance, and source-window fields so downstream
  planners can reason about operator boundaries without owning execution.
  """

  alias OrbitalDynamics.{Frame, Vector3}
  alias OrbitalDynamics.MissionPlan.Activity.LifecycleTransition

  @activity_types [
    :coast,
    :impulsive_burn,
    :observe,
    :downlink,
    :slew,
    :attitude,
    :command,
    :tracking,
    :health_check,
    :planned_contact
  ]
  @approval_statuses [
    :approved,
    :auto_approvable,
    :locked,
    :pending,
    :operator_review_required,
    :not_evaluated,
    :blocked_by_policy,
    :not_required,
    :rejected
  ]
  @activity_statuses Enum.uniq(
                       [
                         :draft,
                         :planned,
                         :approved,
                         :delayed,
                         :invalid,
                         :executing,
                         :completed,
                         :partial,
                         :executed,
                         :missed,
                         :failed,
                         :canceled,
                         :cancelled,
                         :rejected
                       ] ++ @approval_statuses
                     )
  @contact_directions [:downlink, :uplink, :command, :tracking, :health_check]
  @contact_direction_aliases %{
    "cmd" => :command,
    "commanding" => :command,
    "commands" => :command,
    "sband_command" => :command,
    "s_band_command" => :command,
    "up" => :uplink,
    "up_link" => :uplink,
    "dl" => :downlink,
    "down" => :downlink,
    "downlinking" => :downlink,
    "down_link" => :downlink,
    "health" => :health_check,
    "health_check_window" => :health_check,
    "healthcheck" => :health_check,
    "track" => :tracking,
    "track_ing" => :tracking,
    "tracking_pass" => :tracking
  }
  @lifecycle_events [
    :approve,
    :reject,
    :lock,
    :start_execution,
    :record_execution,
    :record_completion,
    :record_partial,
    :record_failure,
    :record_miss,
    :delay,
    :cancel
  ]
  @lifecycle_event_aliases %{
    "abort" => :record_failure,
    "aborted" => :record_failure,
    "approved" => :approve,
    "cancelled" => :cancel,
    "canceled" => :cancel,
    "complete" => :record_completion,
    "completed" => :record_completion,
    "delay" => :delay,
    "delayed" => :delay,
    "done" => :record_completion,
    "dropped" => :record_failure,
    "error" => :record_failure,
    "execute" => :record_execution,
    "executed" => :record_execution,
    "fail" => :record_failure,
    "failed" => :record_failure,
    "failure" => :record_failure,
    "in_progress" => :start_execution,
    "lost" => :record_failure,
    "miss" => :record_miss,
    "missed" => :record_miss,
    "no_contact" => :record_failure,
    "ok" => :record_completion,
    "partial" => :record_partial,
    "partially_completed" => :record_partial,
    "partially_executed" => :record_partial,
    "skipped" => :record_miss,
    "started" => :start_execution,
    "success" => :record_completion,
    "succeeded" => :record_completion,
    "running" => :start_execution,
    "rejected" => :reject,
    "timed_out" => :record_failure,
    "timeout" => :record_failure
  }
  @activity_status_aliases %{
    "abort" => :failed,
    "aborted" => :failed,
    "complete" => :completed,
    "done" => :completed,
    "dropped" => :failed,
    "error" => :failed,
    "fail" => :failed,
    "failure" => :failed,
    "in_progress" => :executing,
    "lost" => :failed,
    "no_contact" => :failed,
    "ok" => :completed,
    "partially_completed" => :partial,
    "partially_executed" => :partial,
    "running" => :executing,
    "skipped" => :missed,
    "started" => :executing,
    "success" => :completed,
    "succeeded" => :completed,
    "timed_out" => :failed,
    "timeout" => :failed
  }
  @approval_status_aliases %{
    "auto_approve" => :auto_approvable,
    "auto_approved" => :approved,
    "blocked" => :blocked_by_policy,
    "blocked_by_rule" => :blocked_by_policy,
    "no_review" => :not_required,
    "no_review_required" => :not_required,
    "none" => :not_required,
    "operator_review" => :operator_review_required,
    "pending_review" => :operator_review_required,
    "policy_blocked" => :blocked_by_policy,
    "requires_review" => :operator_review_required,
    "review" => :operator_review_required,
    "review_required" => :operator_review_required,
    "under_review" => :operator_review_required
  }
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @status_preserving_approval_updates [
    :completed,
    :partial,
    :executed,
    :missed,
    :failed,
    :canceled,
    :cancelled,
    :rejected
  ]
  @unit_interval_fields [
    :fuel_margin,
    :power_margin,
    :storage_margin,
    :downlink_margin,
    :battery_state_of_charge
  ]
  @unit_interval_field_aliases %{
    fuel_margin: [:fuel_margin],
    power_margin: [:power_margin],
    storage_margin: [:storage_margin, :storage_capacity_margin],
    downlink_margin: [:downlink_margin, :downlink_capacity_margin],
    battery_state_of_charge: [:battery_state_of_charge, :battery_soc]
  }
  @battery_energy_generated_wh_aliases [
    :battery_energy_generated_wh,
    :energy_generated_wh,
    :estimated_energy_generated_wh,
    :estimated_battery_energy_generated_wh,
    :planned_energy_generated_wh
  ]
  @precondition_statuses ~w(blocked clear review_required)
  @precondition_types Enum.sort(
                        [
                          "activity_type_incompatible",
                          "activity_type_suppressed",
                          "antenna_unavailable",
                          "command_authority_missing",
                          "command_safety_failed",
                          "command_safety_unchecked",
                          "degraded_mode",
                          "payload_unavailable",
                          "resource_block_declared",
                          "spacecraft_unavailable",
                          "subsystem_state_required"
                        ] ++ Enum.map(@unit_interval_fields, &"#{&1}_depleted")
                      )
  @precondition_row_semantics [
    :precondition_status,
    :blocked_precondition_count,
    :review_precondition_count,
    :blocked_precondition_types,
    :review_precondition_types,
    :precondition_rows
  ]

  @enforce_keys [:id, :type]
  defstruct [
    :id,
    :type,
    :timeline_id,
    :scenario_id,
    :spacecraft_id,
    :resource_id,
    :resource_source_quality,
    :resource_trust_boundary,
    :resource_trust_boundary_status,
    :resource_provenance,
    :resource_blocking_dimension,
    :station_availability,
    :station_calendar_entry_id,
    :station_calendar_provider_id,
    :station_calendar_provider_entry_id,
    :station_calendar_directions,
    :station_calendar_status,
    :station_calendar_trust_boundary_status,
    :source_station_calendar_entry,
    :source_station_calendar_overlaps,
    :station_calendar_overlap_count,
    :station_calendar_overlap_entry_ids,
    :station_calendar_overlap_availabilities,
    :station_calendar_entry_ambiguous,
    :station_calendar_ambiguous_entry_count,
    :station_calendar_ambiguous_entry_ids,
    :station_contention_status,
    :station_calendar_reservation_overlap_count,
    :station_calendar_reservation_expires_at_s,
    :station_calendar_reservation_ids,
    :station_calendar_reserved_by,
    :station_calendar_reservation_statuses,
    :station_reservation_id,
    :station_reservation_expires_at_s,
    :station_reserved_by,
    :station_reservation_status,
    :station_reservation_match_status,
    :capacity_fraction,
    :station_capacity_fraction,
    :capacity_pack_capacity_fraction,
    :fuel_margin,
    :power_margin,
    :storage_margin,
    :downlink_margin,
    :battery_capacity_wh,
    :battery_energy_used_wh,
    :battery_energy_generated_wh,
    :battery_state_of_charge,
    :spacecraft_available,
    :payload_available,
    :antenna_available,
    :degraded,
    :mode,
    :incompatible_activity_types,
    :suppressed_activity_types,
    :collection_id,
    :product_id,
    :product_ids,
    :payload_id,
    :instrument_id,
    :target_priority,
    :target_priority_source,
    :target_priority_objective_ids,
    :target_priority_objective_type,
    :observation_objective_count,
    :observation_objective_ids,
    :observation_objective_source,
    :observation_objective_types,
    :contact_success,
    :contact_result,
    :contact_success_factor,
    :contact_success_factor_source,
    :command_success,
    :command_result,
    :command_success_factor,
    :command_success_factor_source,
    :observation_success,
    :observation_result,
    :observation_success_factor,
    :observation_success_factor_source,
    :image_quality_score,
    :image_quality_status,
    :image_quality_source,
    :cloud_cover_fraction,
    :blur_score,
    :maneuver_success,
    :maneuver_result,
    :maneuver_success_factor,
    :maneuver_success_factor_source,
    :feedback_weight,
    :feedback_weight_source,
    :data_volume_mb,
    :planned_data_volume_mb,
    :planned_volume_mb,
    :actual_data_volume_mb,
    :actual_volume_mb,
    :estimated_data_volume_mb,
    :estimated_storage_mb,
    :estimated_downlink_mb,
    :required_downlink_mb,
    :required_volume_mb,
    :required_data_volume_mb,
    :target_downlink_mb,
    :target_volume_mb,
    :target_data_volume_mb,
    :min_downlink_mb,
    :selected_downlink_mb,
    :selected_data_volume_mb,
    :selected_volume_mb,
    :delivered_data_volume_mb,
    :received_data_volume_mb,
    :selected_downlink_shortfall_mb,
    :selected_data_volume_shortfall_mb,
    :data_volume_shortfall_mb,
    :actual_data_volume_shortfall_mb,
    :missing_data_volume_mb,
    :required_data_volume_gap_mb,
    :downlink_requirement_status,
    :downlink_completion_source,
    :downlink_completion_sources,
    :collection_ends_at_s,
    :planned_delivery_at_s,
    :actual_delivery_at_s,
    :max_latency_s,
    :planned_latency_s,
    :actual_latency_s,
    :collection_latency_objective_count,
    :collection_latency_objective_ids,
    :collection_latency_objective_source,
    :collection_latency_objective_types,
    :planned_estimated_throughput_mb,
    :actual_throughput_mb,
    :link_protocol,
    :frequency_band,
    :modulation,
    :coding_scheme,
    :polarization,
    :data_rate_mbps,
    :downlink_rate_mbps,
    :data_rate_mb_s,
    :downlink_rate_mb_s,
    :actual_data_rate_mbps,
    :actual_downlink_rate_mbps,
    :actual_data_rate_mb_s,
    :actual_downlink_rate_mb_s,
    :delivered_rate_mbps,
    :received_rate_mbps,
    :delivered_rate_mb_s,
    :received_rate_mb_s,
    :actual_duration_s,
    :actual_contact_duration_s,
    :contact_duration_s,
    :link_margin_db,
    :snr_db,
    :eb_no_db,
    :bit_error_rate,
    :packet_loss_rate,
    :frame_loss_rate,
    :carrier_lock,
    :symbol_lock,
    :link_quality_status,
    :pointing_mode,
    :pointing_target_id,
    :boresight_axis,
    :off_nadir_angle_deg,
    :slew_angle_deg,
    :slew_rate_deg_s,
    :pointing_error_deg,
    :pointing_status,
    :pointing_model,
    :pointing_source,
    :pointing_confidence,
    :attitude_mode,
    :attitude_target_id,
    :roll_deg,
    :pitch_deg,
    :yaw_deg,
    :attitude_error_deg,
    :attitude_status,
    :attitude_model,
    :attitude_source,
    :attitude_confidence,
    :thermal_zone_id,
    :temperature_c,
    :planned_temperature_c,
    :actual_temperature_c,
    :min_operating_temperature_c,
    :max_operating_temperature_c,
    :thermal_margin_c,
    :thermal_status,
    :thermal_model,
    :thermal_source,
    :thermal_confidence,
    :eclipse_overlap_fraction,
    :eclipse_overlap_s,
    :lighting_condition,
    :lighting_condition_detail,
    :lighting_condition_model,
    :lighting_detail_model,
    :lighting_confidence,
    :command_window_id,
    :command_window_type,
    :command_window,
    :start_s,
    :end_s,
    :epoch_s,
    :delta_v_km_s,
    :frame,
    :target_id,
    :ground_station_id,
    :direction,
    :status,
    :approval_status,
    :locked?,
    :dependencies,
    :dependency_activity_ids,
    :dependency_timeline_ids,
    :exclusive_with_activity_ids,
    :exclusive_with_timeline_ids,
    :exclusivity_group,
    :source_window_id,
    :source_window_type,
    :source_window,
    :cadence_import,
    :execution_uncertainty,
    :provenance,
    metadata: %{},
    allow_overlap?: false
  ]

  @type t :: %__MODULE__{
          id: atom() | String.t(),
          type:
            :coast
            | :impulsive_burn
            | :observe
            | :downlink
            | :slew
            | :attitude
            | :command
            | :tracking
            | :health_check
            | :planned_contact,
          timeline_id: atom() | String.t() | nil,
          scenario_id: atom() | String.t() | nil,
          spacecraft_id: atom() | String.t() | nil,
          resource_id: atom() | String.t() | nil,
          resource_source_quality: atom() | String.t() | nil,
          resource_trust_boundary: atom() | String.t() | nil,
          resource_trust_boundary_status: atom() | String.t() | nil,
          resource_provenance: map() | nil,
          resource_blocking_dimension: atom() | String.t() | nil,
          station_availability: atom() | String.t() | nil,
          station_calendar_entry_id: atom() | String.t() | nil,
          station_calendar_provider_id: atom() | String.t() | nil,
          station_calendar_provider_entry_id: atom() | String.t() | nil,
          station_calendar_directions: [atom() | String.t()],
          station_calendar_status: atom() | String.t() | nil,
          station_calendar_trust_boundary_status: atom() | String.t() | nil,
          source_station_calendar_entry: map() | nil,
          source_station_calendar_overlaps: [map()],
          station_calendar_overlap_count: non_neg_integer() | nil,
          station_calendar_overlap_entry_ids: [atom() | String.t()],
          station_calendar_overlap_availabilities: [atom() | String.t()],
          station_calendar_entry_ambiguous: boolean() | nil,
          station_calendar_ambiguous_entry_count: non_neg_integer() | nil,
          station_calendar_ambiguous_entry_ids: [atom() | String.t()],
          station_contention_status: atom() | String.t() | nil,
          station_calendar_reservation_overlap_count: non_neg_integer() | nil,
          station_calendar_reservation_expires_at_s: [number()],
          station_calendar_reservation_ids: [atom() | String.t()],
          station_calendar_reserved_by: [atom() | String.t()],
          station_calendar_reservation_statuses: [atom() | String.t()],
          station_reservation_id: atom() | String.t() | nil,
          station_reservation_expires_at_s: number() | nil,
          station_reserved_by: atom() | String.t() | nil,
          station_reservation_status: atom() | String.t() | nil,
          station_reservation_match_status: atom() | String.t() | nil,
          capacity_fraction: number() | nil,
          station_capacity_fraction: number() | nil,
          capacity_pack_capacity_fraction: number() | nil,
          fuel_margin: number() | nil,
          power_margin: number() | nil,
          storage_margin: number() | nil,
          downlink_margin: number() | nil,
          battery_capacity_wh: number() | nil,
          battery_energy_used_wh: number() | nil,
          battery_energy_generated_wh: number() | nil,
          battery_state_of_charge: number() | nil,
          spacecraft_available: boolean() | nil,
          payload_available: boolean() | nil,
          antenna_available: boolean() | nil,
          degraded: boolean() | nil,
          mode: atom() | String.t() | nil,
          incompatible_activity_types: [atom() | String.t()],
          suppressed_activity_types: [atom() | String.t()],
          collection_id: atom() | String.t() | nil,
          product_id: atom() | String.t() | nil,
          product_ids: [atom() | String.t()],
          payload_id: atom() | String.t() | nil,
          instrument_id: atom() | String.t() | nil,
          target_priority: number() | nil,
          target_priority_source: atom() | String.t() | nil,
          target_priority_objective_ids: [atom() | String.t()],
          target_priority_objective_type: atom() | String.t() | nil,
          observation_objective_count: non_neg_integer() | nil,
          observation_objective_ids: [atom() | String.t()],
          observation_objective_source: atom() | String.t() | nil,
          observation_objective_types: [atom() | String.t()],
          contact_success: boolean() | nil,
          contact_result: atom() | String.t() | nil,
          contact_success_factor: number() | nil,
          contact_success_factor_source: atom() | String.t() | nil,
          command_success: boolean() | nil,
          command_result: atom() | String.t() | nil,
          command_success_factor: number() | nil,
          command_success_factor_source: atom() | String.t() | nil,
          observation_success: boolean() | nil,
          observation_result: atom() | String.t() | nil,
          observation_success_factor: number() | nil,
          observation_success_factor_source: atom() | String.t() | nil,
          image_quality_score: number() | nil,
          image_quality_status: atom() | String.t() | nil,
          image_quality_source: atom() | String.t() | nil,
          cloud_cover_fraction: number() | nil,
          blur_score: number() | nil,
          maneuver_success: boolean() | nil,
          maneuver_result: atom() | String.t() | nil,
          maneuver_success_factor: number() | nil,
          maneuver_success_factor_source: atom() | String.t() | nil,
          feedback_weight: number() | nil,
          feedback_weight_source: atom() | String.t() | nil,
          data_volume_mb: number() | nil,
          planned_data_volume_mb: number() | nil,
          planned_volume_mb: number() | nil,
          actual_data_volume_mb: number() | nil,
          actual_volume_mb: number() | nil,
          estimated_data_volume_mb: number() | nil,
          estimated_storage_mb: number() | nil,
          estimated_downlink_mb: number() | nil,
          required_downlink_mb: number() | nil,
          required_volume_mb: number() | nil,
          required_data_volume_mb: number() | nil,
          target_downlink_mb: number() | nil,
          target_volume_mb: number() | nil,
          target_data_volume_mb: number() | nil,
          min_downlink_mb: number() | nil,
          selected_downlink_mb: number() | nil,
          selected_data_volume_mb: number() | nil,
          selected_volume_mb: number() | nil,
          delivered_data_volume_mb: number() | nil,
          received_data_volume_mb: number() | nil,
          selected_downlink_shortfall_mb: number() | nil,
          selected_data_volume_shortfall_mb: number() | nil,
          data_volume_shortfall_mb: number() | nil,
          actual_data_volume_shortfall_mb: number() | nil,
          missing_data_volume_mb: number() | nil,
          required_data_volume_gap_mb: number() | nil,
          downlink_requirement_status: atom() | String.t() | nil,
          downlink_completion_source: atom() | String.t() | nil,
          downlink_completion_sources: [atom() | String.t()],
          collection_ends_at_s: number() | nil,
          planned_delivery_at_s: number() | nil,
          actual_delivery_at_s: number() | nil,
          max_latency_s: number() | nil,
          planned_latency_s: number() | nil,
          actual_latency_s: number() | nil,
          collection_latency_objective_count: non_neg_integer() | nil,
          collection_latency_objective_ids: [atom() | String.t()],
          collection_latency_objective_source: atom() | String.t() | nil,
          collection_latency_objective_types: [atom() | String.t()],
          planned_estimated_throughput_mb: number() | nil,
          actual_throughput_mb: number() | nil,
          link_protocol: atom() | String.t() | nil,
          frequency_band: atom() | String.t() | nil,
          modulation: atom() | String.t() | nil,
          coding_scheme: atom() | String.t() | nil,
          polarization: atom() | String.t() | nil,
          data_rate_mbps: number() | nil,
          downlink_rate_mbps: number() | nil,
          data_rate_mb_s: number() | nil,
          downlink_rate_mb_s: number() | nil,
          actual_data_rate_mbps: number() | nil,
          actual_downlink_rate_mbps: number() | nil,
          actual_data_rate_mb_s: number() | nil,
          actual_downlink_rate_mb_s: number() | nil,
          delivered_rate_mbps: number() | nil,
          received_rate_mbps: number() | nil,
          delivered_rate_mb_s: number() | nil,
          received_rate_mb_s: number() | nil,
          actual_duration_s: number() | nil,
          actual_contact_duration_s: number() | nil,
          contact_duration_s: number() | nil,
          link_margin_db: number() | nil,
          snr_db: number() | nil,
          eb_no_db: number() | nil,
          bit_error_rate: number() | nil,
          packet_loss_rate: number() | nil,
          frame_loss_rate: number() | nil,
          carrier_lock: boolean() | nil,
          symbol_lock: boolean() | nil,
          link_quality_status: atom() | String.t() | nil,
          pointing_mode: atom() | String.t() | nil,
          pointing_target_id: atom() | String.t() | nil,
          boresight_axis: atom() | String.t() | nil,
          off_nadir_angle_deg: number() | nil,
          slew_angle_deg: number() | nil,
          slew_rate_deg_s: number() | nil,
          pointing_error_deg: number() | nil,
          pointing_status: atom() | String.t() | nil,
          pointing_model: atom() | String.t() | nil,
          pointing_source: atom() | String.t() | nil,
          pointing_confidence: number() | nil,
          attitude_mode: atom() | String.t() | nil,
          attitude_target_id: atom() | String.t() | nil,
          roll_deg: number() | nil,
          pitch_deg: number() | nil,
          yaw_deg: number() | nil,
          attitude_error_deg: number() | nil,
          attitude_status: atom() | String.t() | nil,
          attitude_model: atom() | String.t() | nil,
          attitude_source: atom() | String.t() | nil,
          attitude_confidence: number() | nil,
          thermal_zone_id: atom() | String.t() | nil,
          temperature_c: number() | nil,
          planned_temperature_c: number() | nil,
          actual_temperature_c: number() | nil,
          min_operating_temperature_c: number() | nil,
          max_operating_temperature_c: number() | nil,
          thermal_margin_c: number() | nil,
          thermal_status: atom() | String.t() | nil,
          thermal_model: atom() | String.t() | nil,
          thermal_source: atom() | String.t() | nil,
          thermal_confidence: number() | nil,
          eclipse_overlap_fraction: number() | nil,
          eclipse_overlap_s: number() | nil,
          lighting_condition: atom() | String.t() | nil,
          lighting_condition_detail: atom() | String.t() | nil,
          lighting_condition_model: atom() | String.t() | nil,
          lighting_detail_model: atom() | String.t() | nil,
          lighting_confidence: number() | atom() | String.t() | nil,
          command_window_id: atom() | String.t() | nil,
          command_window_type: atom() | String.t() | nil,
          command_window: map() | nil,
          start_s: number() | nil,
          end_s: number() | nil,
          epoch_s: number() | nil,
          delta_v_km_s: Vector3.t() | nil,
          frame: Frame.t() | nil,
          target_id: atom() | String.t() | nil,
          ground_station_id: atom() | String.t() | nil,
          direction: :downlink | :uplink | :command | :tracking | :health_check | nil,
          status: atom(),
          approval_status: atom(),
          locked?: boolean(),
          dependencies: [atom() | String.t()] | String.t(),
          dependency_activity_ids: [atom() | String.t()] | String.t(),
          dependency_timeline_ids: [atom() | String.t()] | String.t(),
          exclusive_with_activity_ids: [atom() | String.t()] | String.t(),
          exclusive_with_timeline_ids: [atom() | String.t()] | String.t(),
          exclusivity_group: atom() | String.t() | nil,
          source_window_id: atom() | String.t() | nil,
          source_window_type: atom() | String.t() | nil,
          source_window: map() | nil,
          cadence_import: map() | nil,
          execution_uncertainty: map() | nil,
          provenance: map(),
          metadata: map(),
          allow_overlap?: boolean()
        }

  @doc """
  Declares the typed mission-plan activity model and artifact boundary helpers.
  """
  def capabilities do
    %{
      model: :typed_mission_plan_activity,
      validation_level: :artifact_contract,
      activity_types: @activity_types,
      activity_statuses: @activity_statuses,
      approval_statuses: @approval_statuses,
      contact_directions: @contact_directions,
      contact_direction_aliases: @contact_direction_aliases,
      artifact_boundaries: [
        :from_atom_keyed_map,
        :from_string_keyed_map,
        :activity_type_alias,
        :to_string_keyed_artifact_map
      ],
      type_aliases: [{:activity_type, :type}],
      lifecycle_event_aliases: @lifecycle_event_aliases,
      activity_status_aliases: @activity_status_aliases,
      approval_status_aliases: @approval_status_aliases,
      transition_helpers: [
        :put_status,
        :status_transition,
        :transition_status,
        :precondition_summary,
        :put_approval_status,
        :approval_transition,
        :transition_approval_status,
        :apply_lifecycle_event,
        :approve,
        :reject,
        :lock,
        :start_execution,
        :record_execution,
        :record_completion,
        :record_partial,
        :record_failure,
        :record_miss,
        :delay,
        :cancel
      ],
      lifecycle_preservation_semantics: [
        :approval_updates_preserve_terminal_or_executed_status,
        :lock_updates_preserve_terminal_or_executed_status
      ],
      precondition_statuses: @precondition_statuses,
      precondition_types: @precondition_types,
      precondition_row_semantics: @precondition_row_semantics,
      public_facades: [
        :mission_plan_activity_from_map,
        :mission_plan_activity_to_artifact_map,
        :mission_plan_activity_put_status,
        :mission_plan_activity_status_transition,
        :mission_plan_activity_transition_status,
        :mission_plan_activity_precondition_summary,
        :mission_plan_activity_put_approval_status,
        :mission_plan_activity_approval_transition,
        :mission_plan_activity_transition_approval_status,
        :mission_plan_activity_apply_lifecycle_event,
        :mission_plan_activity_approve,
        :mission_plan_activity_reject,
        :mission_plan_activity_lock,
        :mission_plan_activity_start_execution,
        :mission_plan_activity_record_execution,
        :mission_plan_activity_record_completion,
        :mission_plan_activity_record_partial,
        :mission_plan_activity_record_failure,
        :mission_plan_activity_record_miss,
        :mission_plan_activity_delay,
        :mission_plan_activity_cancel
      ],
      time_aliases: [
        {:start_s, :starts_at_s},
        {:end_s, :ends_at_s}
      ],
      unit_interval_fields: @unit_interval_fields,
      unit_interval_field_aliases: @unit_interval_field_aliases,
      preserved_fields: [
        :status,
        :approval_status,
        :locked,
        :timeline_id,
        :scenario_id,
        :spacecraft_id,
        :resource_id,
        :resource_source_quality,
        :resource_trust_boundary,
        :resource_trust_boundary_status,
        :resource_provenance,
        :resource_blocking_dimension,
        :station_availability,
        :station_calendar_entry_id,
        :station_calendar_provider_id,
        :station_calendar_provider_entry_id,
        :station_calendar_directions,
        :station_calendar_status,
        :station_calendar_trust_boundary_status,
        :source_station_calendar_entry,
        :source_station_calendar_overlaps,
        :station_calendar_overlap_count,
        :station_calendar_overlap_entry_ids,
        :station_calendar_overlap_availabilities,
        :station_calendar_entry_ambiguous,
        :station_calendar_ambiguous_entry_count,
        :station_calendar_ambiguous_entry_ids,
        :station_contention_status,
        :station_calendar_reservation_overlap_count,
        :station_calendar_reservation_expires_at_s,
        :station_calendar_reservation_ids,
        :station_calendar_reserved_by,
        :station_calendar_reservation_statuses,
        :station_reservation_id,
        :station_reservation_expires_at_s,
        :station_reserved_by,
        :station_reservation_status,
        :station_reservation_match_status,
        :capacity_fraction,
        :station_capacity_fraction,
        :capacity_pack_capacity_fraction,
        :fuel_margin,
        :power_margin,
        :storage_margin,
        :downlink_margin,
        :battery_capacity_wh,
        :battery_energy_used_wh,
        :battery_energy_generated_wh,
        :battery_state_of_charge,
        :spacecraft_available,
        :payload_available,
        :antenna_available,
        :degraded,
        :mode,
        :incompatible_activity_types,
        :suppressed_activity_types,
        :collection_id,
        :product_id,
        :product_ids,
        :payload_id,
        :instrument_id,
        :target_priority,
        :target_priority_source,
        :target_priority_objective_ids,
        :target_priority_objective_type,
        :observation_objective_count,
        :observation_objective_ids,
        :observation_objective_source,
        :observation_objective_types,
        :contact_success,
        :contact_result,
        :contact_success_factor,
        :contact_success_factor_source,
        :command_success,
        :command_result,
        :command_success_factor,
        :command_success_factor_source,
        :observation_success,
        :observation_result,
        :observation_success_factor,
        :observation_success_factor_source,
        :image_quality_score,
        :image_quality_status,
        :image_quality_source,
        :cloud_cover_fraction,
        :blur_score,
        :maneuver_success,
        :maneuver_result,
        :maneuver_success_factor,
        :maneuver_success_factor_source,
        :feedback_weight,
        :feedback_weight_source,
        :data_volume_mb,
        :planned_data_volume_mb,
        :planned_volume_mb,
        :actual_data_volume_mb,
        :actual_volume_mb,
        :estimated_data_volume_mb,
        :estimated_storage_mb,
        :estimated_downlink_mb,
        :required_downlink_mb,
        :required_volume_mb,
        :required_data_volume_mb,
        :target_downlink_mb,
        :target_volume_mb,
        :target_data_volume_mb,
        :min_downlink_mb,
        :selected_downlink_mb,
        :selected_data_volume_mb,
        :selected_volume_mb,
        :delivered_data_volume_mb,
        :received_data_volume_mb,
        :selected_downlink_shortfall_mb,
        :selected_data_volume_shortfall_mb,
        :data_volume_shortfall_mb,
        :actual_data_volume_shortfall_mb,
        :missing_data_volume_mb,
        :required_data_volume_gap_mb,
        :downlink_requirement_status,
        :downlink_completion_source,
        :downlink_completion_sources,
        :collection_ends_at_s,
        :planned_delivery_at_s,
        :actual_delivery_at_s,
        :max_latency_s,
        :planned_latency_s,
        :actual_latency_s,
        :collection_latency_objective_count,
        :collection_latency_objective_ids,
        :collection_latency_objective_source,
        :collection_latency_objective_types,
        :planned_estimated_throughput_mb,
        :actual_throughput_mb,
        :link_protocol,
        :frequency_band,
        :modulation,
        :coding_scheme,
        :polarization,
        :data_rate_mbps,
        :downlink_rate_mbps,
        :data_rate_mb_s,
        :downlink_rate_mb_s,
        :actual_data_rate_mbps,
        :actual_downlink_rate_mbps,
        :actual_data_rate_mb_s,
        :actual_downlink_rate_mb_s,
        :delivered_rate_mbps,
        :received_rate_mbps,
        :delivered_rate_mb_s,
        :received_rate_mb_s,
        :actual_duration_s,
        :actual_contact_duration_s,
        :contact_duration_s,
        :link_margin_db,
        :snr_db,
        :eb_no_db,
        :bit_error_rate,
        :packet_loss_rate,
        :frame_loss_rate,
        :carrier_lock,
        :symbol_lock,
        :link_quality_status,
        :pointing_mode,
        :pointing_target_id,
        :boresight_axis,
        :off_nadir_angle_deg,
        :slew_angle_deg,
        :slew_rate_deg_s,
        :pointing_error_deg,
        :pointing_status,
        :pointing_model,
        :pointing_source,
        :pointing_confidence,
        :attitude_mode,
        :attitude_target_id,
        :roll_deg,
        :pitch_deg,
        :yaw_deg,
        :attitude_error_deg,
        :attitude_status,
        :attitude_model,
        :attitude_source,
        :attitude_confidence,
        :thermal_zone_id,
        :temperature_c,
        :planned_temperature_c,
        :actual_temperature_c,
        :min_operating_temperature_c,
        :max_operating_temperature_c,
        :thermal_margin_c,
        :thermal_status,
        :thermal_model,
        :thermal_source,
        :thermal_confidence,
        :eclipse_overlap_fraction,
        :eclipse_overlap_s,
        :lighting_condition,
        :lighting_condition_detail,
        :lighting_condition_model,
        :lighting_detail_model,
        :lighting_confidence,
        :command_window_id,
        :command_window_type,
        :command_window,
        :dependencies,
        :dependency_activity_ids,
        :dependency_timeline_ids,
        :exclusive_with_activity_ids,
        :exclusive_with_timeline_ids,
        :exclusivity_group,
        :source_window_id,
        :source_window_type,
        :source_window,
        :cadence_import,
        :execution_uncertainty,
        :provenance,
        :metadata
      ],
      known_limits: [
        :artifact_level_only,
        :no_schedule_mutation,
        :no_command_execution
      ]
    }
  end

  @doc """
  Returns a copy of an activity with a validated lifecycle status.
  """
  def put_status!(%__MODULE__{} = activity, status) do
    Map.put(activity, :status, required_activity_status_atom!(status))
  end

  @doc """
  Describes whether a lifecycle status transition is safe to apply automatically.

  The result is artifact state only. It does not mutate schedules, approve
  external workflow, or execute commands.
  """
  def status_transition(%__MODULE__{} = activity, status) do
    from = activity.status || :planned
    to = required_activity_status_atom!(status)
    {safe_to_apply?, requires_review?, reason} = status_transition_review(from, to)

    %{
      "model" => "typed_activity_status_transition_validation",
      "field" => "status",
      "from" => Atom.to_string(from),
      "to" => Atom.to_string(to),
      "from_category" => lifecycle_status_category(from),
      "to_category" => lifecycle_status_category(to),
      "safe_to_apply" => safe_to_apply?,
      "requires_operator_review" => requires_review?,
      "operator_action_reason" => reason,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_transition_validation"
      }
    }
  end

  @doc """
  Returns a copy of an activity with a validated, safe lifecycle status transition.

  Use `put_status!/2` when a caller only needs value normalization. This helper
  additionally prevents automatic regressions from terminal, executed, invalid,
  or policy-blocked lifecycle states.
  """
  def transition_status!(%__MODULE__{} = activity, status) do
    transition = status_transition(activity, status)

    if transition["safe_to_apply"] do
      put_status!(activity, status)
    else
      raise ArgumentError,
            "unsafe lifecycle status transition #{transition["from"]} -> #{transition["to"]}: #{transition["operator_action_reason"]}"
    end
  end

  @doc """
  Summarizes explicit state and resource preconditions carried by an activity.

  The report is artifact state only. It does not mutate schedules, reserve
  resources, approve workflow, or execute commands.
  """
  def precondition_summary(%__MODULE__{} = activity) do
    preconditions =
      activity
      |> precondition_rows()
      |> Enum.sort_by(&{&1["status"], &1["type"], &1["field"]})

    blocked = Enum.filter(preconditions, &(&1["status"] == "blocked"))
    review = Enum.filter(preconditions, &(&1["status"] == "review_required"))

    %{
      "model" => "typed_activity_precondition_summary",
      "activity_id" => artifact_value(activity.id),
      "activity_type" => artifact_value(activity.type),
      "precondition_status" => precondition_status(blocked, review),
      "blocked_precondition_count" => length(blocked),
      "review_precondition_count" => length(review),
      "blocked_precondition_types" => precondition_types(blocked),
      "review_precondition_types" => precondition_types(review),
      "preconditions" => preconditions,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_precondition_summary",
        "resource_authority" => "not_reserved_by_precondition_summary"
      }
    }
  end

  @doc """
  Returns a copy of an activity with a validated approval status.
  """
  def put_approval_status!(%__MODULE__{} = activity, approval_status) do
    Map.put(
      activity,
      :approval_status,
      required_approval_status_atom!(approval_status)
    )
  end

  @doc """
  Describes whether an approval-status transition is safe to apply automatically.

  The result is artifact state only. It does not grant operator authority,
  execute commands, or mutate schedules.
  """
  def approval_transition(%__MODULE__{} = activity, approval_status) do
    from = activity.approval_status || :not_required
    to = required_approval_status_atom!(approval_status)
    {safe_to_apply?, requires_review?, reason} = approval_transition_review(from, to)

    %{
      "model" => "typed_activity_approval_transition_validation",
      "field" => "approval_status",
      "from" => Atom.to_string(from),
      "to" => Atom.to_string(to),
      "from_category" => approval_status_category(from),
      "to_category" => approval_status_category(to),
      "safe_to_apply" => safe_to_apply?,
      "requires_operator_review" => requires_review?,
      "operator_action_reason" => reason,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_transition_validation"
      }
    }
  end

  @doc """
  Returns a copy of an activity with a validated, safe approval-status transition.

  Use `put_approval_status!/2` when a caller only needs value normalization.
  This helper prevents automatic approval grants or clearing blocked, rejected,
  or locked approval states without explicit operator authority.
  """
  def transition_approval_status!(%__MODULE__{} = activity, approval_status) do
    transition = approval_transition(activity, approval_status)

    if transition["safe_to_apply"] do
      put_approval_status!(activity, approval_status)
    else
      raise ArgumentError,
            "unsafe approval status transition #{transition["from"]} -> #{transition["to"]}: #{transition["operator_action_reason"]}"
    end
  end

  @doc """
  Applies a normalized lifecycle event to an activity.

  This is artifact state only; it does not mutate schedules, approve external
  workflow, or execute commands.
  """
  def apply_lifecycle_event!(%__MODULE__{} = activity, event) do
    case lifecycle_event!(event) do
      :approve -> approve!(activity)
      :reject -> reject!(activity)
      :lock -> lock!(activity)
      :start_execution -> start_execution!(activity)
      :record_execution -> record_execution!(activity)
      :record_completion -> record_completion!(activity)
      :record_partial -> record_partial!(activity)
      :record_failure -> record_failure!(activity)
      :record_miss -> record_miss!(activity)
      :delay -> delay!(activity)
      :cancel -> cancel!(activity)
    end
  end

  @doc """
  Marks an activity approved without mutating schedules or executing work.
  """
  def approve!(%__MODULE__{} = activity) do
    activity
    |> put_approval_status!(:approved)
    |> maybe_put_status_unless_preserved(:approved)
  end

  @doc """
  Marks an activity rejected for operator review/audit.
  """
  def reject!(%__MODULE__{} = activity) do
    put_approval_status!(activity, :rejected)
  end

  @doc """
  Locks an activity so downstream planners can preserve it.
  """
  def lock!(%__MODULE__{} = activity) do
    activity
    |> put_approval_status!(:locked)
    |> Map.put(:locked?, true)
    |> maybe_put_status_unless_preserved(:locked)
  end

  defp maybe_put_status_unless_preserved(%__MODULE__{} = activity, status) do
    if activity.status in @status_preserving_approval_updates do
      activity
    else
      put_status!(activity, status)
    end
  end

  @doc """
  Records that an activity has entered execution.
  """
  def start_execution!(%__MODULE__{} = activity) do
    put_status!(activity, :executing)
  end

  @doc """
  Records that an activity has executed. This is artifact state only; it does not
  execute commands or mutate provider schedules.
  """
  def record_execution!(%__MODULE__{} = activity) do
    put_status!(activity, :executed)
  end

  @doc """
  Records that an activity completed successfully.
  """
  def record_completion!(%__MODULE__{} = activity) do
    put_status!(activity, :completed)
  end

  @doc """
  Records that an activity partially completed.
  """
  def record_partial!(%__MODULE__{} = activity) do
    put_status!(activity, :partial)
  end

  @doc """
  Records that an activity failed.
  """
  def record_failure!(%__MODULE__{} = activity) do
    put_status!(activity, :failed)
  end

  @doc """
  Records that an activity was missed.
  """
  def record_miss!(%__MODULE__{} = activity) do
    put_status!(activity, :missed)
  end

  @doc """
  Records that an activity was delayed.
  """
  def delay!(%__MODULE__{} = activity) do
    put_status!(activity, :delayed)
  end

  @doc """
  Records that an activity has been canceled.
  """
  def cancel!(%__MODULE__{} = activity) do
    put_status!(activity, :canceled)
  end

  defp status_transition_review(status, status),
    do: LifecycleTransition.status_review(status, status, @status_preserving_approval_updates)

  defp status_transition_review(from, to),
    do: LifecycleTransition.status_review(from, to, @status_preserving_approval_updates)

  defp lifecycle_status_category(status),
    do:
      LifecycleTransition.status_category(
        status,
        @status_preserving_approval_updates,
        @activity_statuses
      )

  defp approval_transition_review(from, to),
    do: LifecycleTransition.approval_review(from, to)

  defp approval_status_category(status),
    do: LifecycleTransition.approval_category(status)

  defp precondition_rows(%__MODULE__{} = activity) do
    []
    |> maybe_add_precondition(
      activity.spacecraft_available == false,
      "spacecraft_unavailable",
      "blocked",
      "spacecraft_available",
      "spacecraft availability is explicitly false"
    )
    |> maybe_add_precondition(
      activity.payload_available == false,
      "payload_unavailable",
      "blocked",
      "payload_available",
      "payload availability is explicitly false"
    )
    |> maybe_add_precondition(
      activity.antenna_available == false,
      "antenna_unavailable",
      "blocked",
      "antenna_available",
      "antenna availability is explicitly false"
    )
    |> maybe_add_precondition(
      activity.degraded == true,
      "degraded_mode",
      "review_required",
      "degraded",
      "activity is explicitly marked degraded"
    )
    |> maybe_add_precondition(
      not is_nil(activity.resource_blocking_dimension),
      "resource_block_declared",
      "blocked",
      "resource_blocking_dimension",
      "resource blocking dimension is explicitly declared",
      artifact_value(activity.resource_blocking_dimension)
    )
    |> maybe_add_margin_preconditions(activity)
    |> maybe_add_activity_type_membership_precondition(
      activity,
      activity.incompatible_activity_types,
      "activity_type_incompatible",
      "incompatible_activity_types",
      "activity type appears in incompatible activity types"
    )
    |> maybe_add_activity_type_membership_precondition(
      activity,
      activity.suppressed_activity_types,
      "activity_type_suppressed",
      "suppressed_activity_types",
      "activity type appears in suppressed activity types"
    )
    |> maybe_add_command_authority_precondition(activity)
    |> maybe_add_command_safety_preconditions(activity)
    |> add_activity_template_required_state_preconditions(activity)
  end

  defp maybe_add_command_authority_precondition(preconditions, %__MODULE__{} = activity) do
    case command_authority_precondition_evidence(activity) do
      nil ->
        preconditions

      {field, value, reason} ->
        maybe_add_precondition(
          preconditions,
          true,
          "command_authority_missing",
          "review_required",
          field,
          reason,
          value
        )
    end
  end

  defp command_authority_precondition_evidence(%__MODULE__{} = activity) do
    metadata = activity_command_metadata(activity)
    authorized? = metadata_boolean(metadata, :command_authorized, :authority_granted)
    status = metadata_token(metadata, :command_authority_status, :authority_status)
    status_value = metadata_value(metadata, :command_authority_status, :authority_status)

    required_authority =
      metadata_value(metadata, :required_authority, :required_escalation_authority)

    cond do
      authorized? == false ->
        {"command_authorized", false, "command authority is explicitly not granted"}

      status in [
        "missing",
        "authority_missing",
        "required",
        "operator_required",
        "review_required",
        "pending",
        "not_authorized",
        "unauthorized"
      ] ->
        {"command_authority_status", status_value,
         "command authority status requires operator review"}

      not is_nil(required_authority) and authorized? != true ->
        {"required_authority", required_authority, "required command authority is declared"}

      true ->
        nil
    end
  end

  defp maybe_add_command_safety_preconditions(preconditions, %__MODULE__{} = activity) do
    metadata = activity_command_metadata(activity)
    safety_status = metadata_token(metadata, :command_safety_status, :safety_status)
    safety_status_value = metadata_value(metadata, :command_safety_status, :safety_status)
    safety_checked? = metadata_boolean(metadata, :command_safety_checked, :safety_checked)

    preconditions
    |> maybe_add_precondition(
      safety_status in ["failed", "fail", "unsafe", "blocked", "rejected"],
      "command_safety_failed",
      "blocked",
      "command_safety_status",
      "command safety status is explicitly unsafe or failed",
      safety_status_value
    )
    |> maybe_add_precondition(
      safety_checked? == false or
        safety_status in ["missing", "required", "unchecked", "not_checked", "pending"],
      "command_safety_unchecked",
      "review_required",
      if(safety_checked? == false, do: "command_safety_checked", else: "command_safety_status"),
      "command safety check requires review before command handoff",
      if(safety_checked? == false, do: false, else: safety_status_value)
    )
  end

  defp activity_command_metadata(%__MODULE__{metadata: metadata}) when is_map(metadata) do
    artifact_value(metadata)
  end

  defp activity_command_metadata(_activity), do: %{}

  defp metadata_value(metadata, key, aliases) do
    aliases = List.wrap(aliases)

    Enum.reduce_while([key | aliases], nil, fn key, _acc ->
      value = field(metadata, key)

      if is_nil(value) do
        {:cont, nil}
      else
        {:halt, artifact_value(value)}
      end
    end)
  end

  defp metadata_token(metadata, key, aliases) do
    case metadata_value(metadata, key, aliases) do
      value when is_binary(value) -> normalized_token(value)
      value when is_atom(value) -> value |> Atom.to_string() |> normalized_token()
      _value -> nil
    end
  end

  defp metadata_boolean(metadata, key, aliases) do
    case metadata_value(metadata, key, aliases) do
      value when value in [true, "true", "1", 1] -> true
      value when value in [false, "false", "0", 0] -> false
      _value -> nil
    end
  end

  defp add_activity_template_required_state_preconditions(preconditions, %__MODULE__{} = activity) do
    activity
    |> activity_template_required_states()
    |> Enum.reduce(preconditions, fn {index, %{"subsystem" => subsystem, "state" => state} = hint},
                                     rows ->
      maybe_add_precondition(
        rows,
        true,
        "subsystem_state_required",
        "review_required",
        "activity_template.subsystem_state_hints.required_states[#{index}]",
        Map.get(hint, "reason") || "activity template declares required subsystem state",
        %{
          "subsystem" => subsystem,
          "state" => state,
          "blocking" => Map.get(hint, "blocking")
        }
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()
      )
    end)
  end

  defp activity_template_required_states(%__MODULE__{metadata: metadata}) when is_map(metadata) do
    metadata
    |> artifact_value()
    |> Map.get("activity_template")
    |> valid_activity_template_provenance()
    |> get_in(["subsystem_state_hints", "required_states"])
    |> valid_required_state_hints()
  end

  defp activity_template_required_states(_activity), do: []

  defp valid_activity_template_provenance(%{} = template) do
    if template["schema_contract"] == "activity_template.v1" and
         is_binary(template["id"]) and
         is_binary(template["activity_type"]) do
      template
    end
  end

  defp valid_activity_template_provenance(_template), do: nil

  defp valid_required_state_hints(hints) when is_list(hints) do
    hints
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%{"subsystem" => subsystem, "state" => state} = hint, index}
      when is_binary(subsystem) and is_binary(state) ->
        [{index, hint}]

      _hint ->
        []
    end)
  end

  defp valid_required_state_hints(_hints), do: []

  defp maybe_add_margin_preconditions(preconditions, %__MODULE__{} = activity) do
    @unit_interval_fields
    |> Enum.filter(&(Map.get(activity, &1) == 0.0))
    |> Enum.reduce(preconditions, fn field, rows ->
      maybe_add_precondition(
        rows,
        true,
        "#{field}_depleted",
        "blocked",
        Atom.to_string(field),
        "unit-interval resource margin is depleted",
        0.0
      )
    end)
  end

  defp maybe_add_activity_type_membership_precondition(
         preconditions,
         %__MODULE__{} = activity,
         activity_types,
         type,
         field,
         reason
       ) do
    normalized_activity_type = artifact_value(activity.type)
    normalized_activity_types = Enum.map(activity_types || [], &artifact_value/1)

    maybe_add_precondition(
      preconditions,
      normalized_activity_type in normalized_activity_types,
      type,
      "blocked",
      field,
      reason,
      normalized_activity_type
    )
  end

  defp maybe_add_precondition(preconditions, false, _type, _status, _field, _reason),
    do: preconditions

  defp maybe_add_precondition(preconditions, true, type, status, field, reason) do
    maybe_add_precondition(preconditions, true, type, status, field, reason, nil)
  end

  defp maybe_add_precondition(preconditions, false, _type, _status, _field, _reason, _value),
    do: preconditions

  defp maybe_add_precondition(preconditions, true, type, status, field, reason, value) do
    row =
      %{
        "type" => type,
        "status" => status,
        "field" => field,
        "reason" => reason,
        "value" => value
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    [row | preconditions]
  end

  defp precondition_status([_blocked | _rest], _review), do: "blocked"
  defp precondition_status([], [_review | _rest]), do: "review_required"
  defp precondition_status([], []), do: "clear"

  defp precondition_types(preconditions) do
    preconditions
    |> Enum.map(& &1["type"])
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp lifecycle_event!(event),
    do: LifecycleTransition.event!(event, @lifecycle_event_aliases, @lifecycle_events)

  def coast!(id, start_s, end_s, opts \\ []) do
    interval_activity!(id, :coast, start_s, end_s, opts)
  end

  def observe!(id, start_s, end_s, target_id, opts \\ []) do
    id
    |> interval_activity!(:observe, start_s, end_s, opts)
    |> Map.put(:target_id, required_identifier!(target_id, "target_id"))
  end

  def downlink!(id, start_s, end_s, ground_station_id, opts \\ []) do
    id
    |> interval_activity!(:downlink, start_s, end_s, opts)
    |> Map.put(:ground_station_id, required_identifier!(ground_station_id, "ground_station_id"))
    |> Map.put(:direction, :downlink)
  end

  def slew!(id, start_s, end_s, opts \\ []) do
    interval_activity!(id, :slew, start_s, end_s, opts)
  end

  def attitude!(id, start_s, end_s, opts \\ []) do
    interval_activity!(id, :attitude, start_s, end_s, canonical_attitude_opts(opts))
  end

  def command!(id, start_s, end_s, opts \\ []) do
    id
    |> interval_activity!(:command, start_s, end_s, opts)
    |> Map.put(:direction, Keyword.get(opts, :direction, :command) |> contact_direction!())
    |> maybe_put_ground_station(opts)
  end

  def tracking!(id, start_s, end_s, ground_station_id, opts \\ []) do
    id
    |> interval_activity!(:tracking, start_s, end_s, opts)
    |> Map.put(:ground_station_id, required_identifier!(ground_station_id, "ground_station_id"))
    |> Map.put(:direction, :tracking)
  end

  def health_check!(id, start_s, end_s, opts \\ []) do
    id
    |> interval_activity!(:health_check, start_s, end_s, opts)
    |> Map.put(
      :direction,
      Keyword.get(opts, :direction, :health_check) |> health_check_direction!()
    )
    |> maybe_put_ground_station(opts)
  end

  def planned_contact!(id, start_s, end_s, ground_station_id, direction, opts \\ []) do
    id
    |> interval_activity!(:planned_contact, start_s, end_s, opts)
    |> Map.put(:ground_station_id, required_identifier!(ground_station_id, "ground_station_id"))
    |> Map.put(:direction, contact_direction!(direction))
  end

  def impulsive_burn!(id, epoch_s, delta_v_km_s, opts \\ []) do
    metadata = Keyword.get(opts, :metadata, %{})
    allow_overlap? = Keyword.get(opts, :allow_overlap?, false)
    frame = Keyword.get(opts, :frame)
    common = common_fields!(opts)

    cond do
      invalid_identifier?(id) ->
        raise ArgumentError, "activity id is required"

      not non_negative_number?(epoch_s) ->
        raise ArgumentError, "epoch_s must be non-negative seconds"

      not Vector3.valid?(delta_v_km_s) ->
        raise ArgumentError, "delta_v_km_s must be a numeric {x, y, z} tuple"

      not (is_nil(frame) or match?(%Frame{}, frame)) ->
        raise ArgumentError, "frame must be nil or an OrbitalDynamics.Frame"

      not is_map(metadata) ->
        raise ArgumentError, "metadata must be a map"

      not is_boolean(allow_overlap?) ->
        raise ArgumentError, "allow_overlap? must be a boolean"

      true ->
        struct!(
          __MODULE__,
          Map.merge(common, %{
            id: id,
            type: :impulsive_burn,
            epoch_s: epoch_s,
            delta_v_km_s: delta_v_km_s,
            frame: frame,
            metadata: metadata,
            allow_overlap?: allow_overlap?
          })
        )
    end
  end

  def interval(%__MODULE__{type: :impulsive_burn, epoch_s: epoch_s}), do: {epoch_s, epoch_s}
  def interval(%__MODULE__{start_s: start_s, end_s: end_s}), do: {start_s, end_s}

  @doc """
  Builds a typed activity from an atom-keyed or string-keyed activity map.

  This is the JSON/artifact ingress companion to the constructor helpers. It
  accepts the local `start_s`/`end_s` fields emitted by `to_map/1` and the
  artifact-style `starts_at_s`/`ends_at_s` aliases used by planner reports.
  """
  def from_map!(%__MODULE__{} = activity), do: activity

  def from_map!(%{} = source) do
    type = required_enum_atom!(activity_type_field(source), @activity_types, "type")
    id = required_identifier!(field(source, :id), "activity id")
    opts = common_opts_from_map!(source)

    case type do
      :coast ->
        coast!(id, interval_start!(source), interval_end!(source), opts)

      :observe ->
        observe!(
          id,
          interval_start!(source),
          interval_end!(source),
          target_id_field(source),
          opts
        )

      :downlink ->
        downlink!(
          id,
          interval_start!(source),
          interval_end!(source),
          ground_station_id_field(source),
          opts
        )

      :slew ->
        slew!(id, interval_start!(source), interval_end!(source), opts)

      :attitude ->
        attitude!(
          id,
          interval_start!(source),
          interval_end!(source),
          canonical_attitude_opts(opts)
        )

      :command ->
        command!(id, interval_start!(source), interval_end!(source), opts)

      :tracking ->
        tracking!(
          id,
          interval_start!(source),
          interval_end!(source),
          ground_station_id_field(source),
          opts
        )

      :health_check ->
        health_check!(id, interval_start!(source), interval_end!(source), opts)

      :planned_contact ->
        if Keyword.get(opts, :direction) == :health_check do
          health_check!(id, interval_start!(source), interval_end!(source), opts)
        else
          planned_contact!(
            id,
            interval_start!(source),
            interval_end!(source),
            ground_station_id_field(source),
            field(source, :direction),
            opts
          )
        end

      :impulsive_burn ->
        impulsive_burn!(
          id,
          required_number!(field(source, :epoch_s), "epoch_s"),
          delta_v!(field(source, :delta_v_km_s)),
          Keyword.put(opts, :frame, frame_from_input!(field(source, :frame)))
        )
    end
  end

  def from_map!(_source), do: raise(ArgumentError, "activity must be a map")

  defp canonical_attitude_opts(opts) do
    opts
    |> put_missing_attitude_opt(:pointing_mode, :attitude_mode)
    |> put_missing_attitude_opt(:pointing_target_id, :attitude_target_id)
    |> put_missing_attitude_opt(:pointing_error_deg, :attitude_error_deg)
    |> put_missing_attitude_opt(:pointing_status, :attitude_status)
    |> put_missing_attitude_opt(:pointing_model, :attitude_model)
    |> put_missing_attitude_opt(:pointing_source, :attitude_source)
    |> put_missing_attitude_opt(:pointing_confidence, :attitude_confidence)
  end

  defp put_missing_attitude_opt(opts, source_key, target_key) do
    cond do
      Keyword.has_key?(opts, target_key) ->
        opts

      Keyword.has_key?(opts, source_key) ->
        Keyword.put(opts, target_key, Keyword.fetch!(opts, source_key))

      true ->
        opts
    end
  end

  def to_map(%__MODULE__{} = activity) do
    %{
      id: activity.id,
      type: activity.type,
      timeline_id: activity.timeline_id,
      scenario_id: activity.scenario_id,
      spacecraft_id: activity.spacecraft_id,
      resource_id: activity.resource_id,
      resource_source_quality: activity.resource_source_quality,
      resource_trust_boundary: activity.resource_trust_boundary,
      resource_trust_boundary_status: activity.resource_trust_boundary_status,
      resource_provenance: activity.resource_provenance,
      resource_blocking_dimension: activity.resource_blocking_dimension,
      station_availability: activity.station_availability,
      station_calendar_entry_id: activity.station_calendar_entry_id,
      station_calendar_provider_id: activity.station_calendar_provider_id,
      station_calendar_provider_entry_id: activity.station_calendar_provider_entry_id,
      station_calendar_directions: activity.station_calendar_directions,
      station_calendar_status: activity.station_calendar_status,
      station_calendar_trust_boundary_status: activity.station_calendar_trust_boundary_status,
      source_station_calendar_entry: activity.source_station_calendar_entry,
      source_station_calendar_overlaps: activity.source_station_calendar_overlaps,
      station_calendar_overlap_count: activity.station_calendar_overlap_count,
      station_calendar_overlap_entry_ids: activity.station_calendar_overlap_entry_ids,
      station_calendar_overlap_availabilities: activity.station_calendar_overlap_availabilities,
      station_calendar_entry_ambiguous: activity.station_calendar_entry_ambiguous,
      station_calendar_ambiguous_entry_count: activity.station_calendar_ambiguous_entry_count,
      station_calendar_ambiguous_entry_ids: activity.station_calendar_ambiguous_entry_ids,
      station_contention_status: activity.station_contention_status,
      station_calendar_reservation_overlap_count:
        activity.station_calendar_reservation_overlap_count,
      station_calendar_reservation_expires_at_s:
        activity.station_calendar_reservation_expires_at_s,
      station_calendar_reservation_ids: activity.station_calendar_reservation_ids,
      station_calendar_reserved_by: activity.station_calendar_reserved_by,
      station_calendar_reservation_statuses: activity.station_calendar_reservation_statuses,
      station_reservation_id: activity.station_reservation_id,
      station_reservation_expires_at_s: activity.station_reservation_expires_at_s,
      station_reserved_by: activity.station_reserved_by,
      station_reservation_status: activity.station_reservation_status,
      station_reservation_match_status: activity.station_reservation_match_status,
      capacity_fraction: activity.capacity_fraction,
      station_capacity_fraction: activity.station_capacity_fraction,
      capacity_pack_capacity_fraction: activity.capacity_pack_capacity_fraction,
      fuel_margin: activity.fuel_margin,
      power_margin: activity.power_margin,
      storage_margin: activity.storage_margin,
      downlink_margin: activity.downlink_margin,
      battery_capacity_wh: activity.battery_capacity_wh,
      battery_energy_used_wh: activity.battery_energy_used_wh,
      battery_energy_generated_wh: activity.battery_energy_generated_wh,
      battery_state_of_charge: activity.battery_state_of_charge,
      spacecraft_available: activity.spacecraft_available,
      payload_available: activity.payload_available,
      antenna_available: activity.antenna_available,
      degraded: activity.degraded,
      mode: activity.mode,
      incompatible_activity_types: activity.incompatible_activity_types,
      suppressed_activity_types: activity.suppressed_activity_types,
      collection_id: activity.collection_id,
      product_id: activity.product_id,
      product_ids: activity.product_ids,
      payload_id: activity.payload_id,
      instrument_id: activity.instrument_id,
      target_priority: activity.target_priority,
      target_priority_source: activity.target_priority_source,
      target_priority_objective_ids: activity.target_priority_objective_ids,
      target_priority_objective_type: activity.target_priority_objective_type,
      observation_objective_count: activity.observation_objective_count,
      observation_objective_ids: activity.observation_objective_ids,
      observation_objective_source: activity.observation_objective_source,
      observation_objective_types: activity.observation_objective_types,
      contact_success: activity.contact_success,
      contact_result: activity.contact_result,
      contact_success_factor: activity.contact_success_factor,
      contact_success_factor_source: activity.contact_success_factor_source,
      command_success: activity.command_success,
      command_result: activity.command_result,
      command_success_factor: activity.command_success_factor,
      command_success_factor_source: activity.command_success_factor_source,
      observation_success: activity.observation_success,
      observation_result: activity.observation_result,
      observation_success_factor: activity.observation_success_factor,
      observation_success_factor_source: activity.observation_success_factor_source,
      image_quality_score: activity.image_quality_score,
      image_quality_status: activity.image_quality_status,
      image_quality_source: activity.image_quality_source,
      cloud_cover_fraction: activity.cloud_cover_fraction,
      blur_score: activity.blur_score,
      maneuver_success: activity.maneuver_success,
      maneuver_result: activity.maneuver_result,
      maneuver_success_factor: activity.maneuver_success_factor,
      maneuver_success_factor_source: activity.maneuver_success_factor_source,
      feedback_weight: activity.feedback_weight,
      feedback_weight_source: activity.feedback_weight_source,
      data_volume_mb: activity.data_volume_mb,
      planned_data_volume_mb: activity.planned_data_volume_mb,
      planned_volume_mb: activity.planned_volume_mb,
      actual_data_volume_mb: activity.actual_data_volume_mb,
      actual_volume_mb: activity.actual_volume_mb,
      estimated_data_volume_mb: activity.estimated_data_volume_mb,
      estimated_storage_mb: activity.estimated_storage_mb,
      estimated_downlink_mb: activity.estimated_downlink_mb,
      required_downlink_mb: activity.required_downlink_mb,
      required_volume_mb: activity.required_volume_mb,
      required_data_volume_mb: activity.required_data_volume_mb,
      target_downlink_mb: activity.target_downlink_mb,
      target_volume_mb: activity.target_volume_mb,
      target_data_volume_mb: activity.target_data_volume_mb,
      min_downlink_mb: activity.min_downlink_mb,
      selected_downlink_mb: activity.selected_downlink_mb,
      selected_data_volume_mb: activity.selected_data_volume_mb,
      selected_volume_mb: activity.selected_volume_mb,
      delivered_data_volume_mb: activity.delivered_data_volume_mb,
      received_data_volume_mb: activity.received_data_volume_mb,
      selected_downlink_shortfall_mb: activity.selected_downlink_shortfall_mb,
      selected_data_volume_shortfall_mb: activity.selected_data_volume_shortfall_mb,
      data_volume_shortfall_mb: activity.data_volume_shortfall_mb,
      actual_data_volume_shortfall_mb: activity.actual_data_volume_shortfall_mb,
      missing_data_volume_mb: activity.missing_data_volume_mb,
      required_data_volume_gap_mb: activity.required_data_volume_gap_mb,
      downlink_requirement_status: activity.downlink_requirement_status,
      downlink_completion_source: activity.downlink_completion_source,
      downlink_completion_sources: activity.downlink_completion_sources,
      collection_ends_at_s: activity.collection_ends_at_s,
      planned_delivery_at_s: activity.planned_delivery_at_s,
      actual_delivery_at_s: activity.actual_delivery_at_s,
      max_latency_s: activity.max_latency_s,
      planned_latency_s: activity.planned_latency_s,
      actual_latency_s: activity.actual_latency_s,
      collection_latency_objective_count: activity.collection_latency_objective_count,
      collection_latency_objective_ids: activity.collection_latency_objective_ids,
      collection_latency_objective_source: activity.collection_latency_objective_source,
      collection_latency_objective_types: activity.collection_latency_objective_types,
      planned_estimated_throughput_mb: activity.planned_estimated_throughput_mb,
      actual_throughput_mb: activity.actual_throughput_mb,
      link_protocol: activity.link_protocol,
      frequency_band: activity.frequency_band,
      modulation: activity.modulation,
      coding_scheme: activity.coding_scheme,
      polarization: activity.polarization,
      data_rate_mbps: activity.data_rate_mbps,
      downlink_rate_mbps: activity.downlink_rate_mbps,
      data_rate_mb_s: activity.data_rate_mb_s,
      downlink_rate_mb_s: activity.downlink_rate_mb_s,
      actual_data_rate_mbps: activity.actual_data_rate_mbps,
      actual_downlink_rate_mbps: activity.actual_downlink_rate_mbps,
      actual_data_rate_mb_s: activity.actual_data_rate_mb_s,
      actual_downlink_rate_mb_s: activity.actual_downlink_rate_mb_s,
      delivered_rate_mbps: activity.delivered_rate_mbps,
      received_rate_mbps: activity.received_rate_mbps,
      delivered_rate_mb_s: activity.delivered_rate_mb_s,
      received_rate_mb_s: activity.received_rate_mb_s,
      actual_duration_s: activity.actual_duration_s,
      actual_contact_duration_s: activity.actual_contact_duration_s,
      contact_duration_s: activity.contact_duration_s,
      link_margin_db: activity.link_margin_db,
      snr_db: activity.snr_db,
      eb_no_db: activity.eb_no_db,
      bit_error_rate: activity.bit_error_rate,
      packet_loss_rate: activity.packet_loss_rate,
      frame_loss_rate: activity.frame_loss_rate,
      carrier_lock: activity.carrier_lock,
      symbol_lock: activity.symbol_lock,
      link_quality_status: activity.link_quality_status,
      pointing_mode: activity.pointing_mode,
      pointing_target_id: activity.pointing_target_id,
      boresight_axis: activity.boresight_axis,
      off_nadir_angle_deg: activity.off_nadir_angle_deg,
      slew_angle_deg: activity.slew_angle_deg,
      slew_rate_deg_s: activity.slew_rate_deg_s,
      pointing_error_deg: activity.pointing_error_deg,
      pointing_status: activity.pointing_status,
      pointing_model: activity.pointing_model,
      pointing_source: activity.pointing_source,
      pointing_confidence: activity.pointing_confidence,
      attitude_mode: activity.attitude_mode,
      attitude_target_id: activity.attitude_target_id,
      roll_deg: activity.roll_deg,
      pitch_deg: activity.pitch_deg,
      yaw_deg: activity.yaw_deg,
      attitude_error_deg: activity.attitude_error_deg,
      attitude_status: activity.attitude_status,
      attitude_model: activity.attitude_model,
      attitude_source: activity.attitude_source,
      attitude_confidence: activity.attitude_confidence,
      thermal_zone_id: activity.thermal_zone_id,
      temperature_c: activity.temperature_c,
      planned_temperature_c: activity.planned_temperature_c,
      actual_temperature_c: activity.actual_temperature_c,
      min_operating_temperature_c: activity.min_operating_temperature_c,
      max_operating_temperature_c: activity.max_operating_temperature_c,
      thermal_margin_c: activity.thermal_margin_c,
      thermal_status: activity.thermal_status,
      thermal_model: activity.thermal_model,
      thermal_source: activity.thermal_source,
      thermal_confidence: activity.thermal_confidence,
      eclipse_overlap_fraction: activity.eclipse_overlap_fraction,
      eclipse_overlap_s: activity.eclipse_overlap_s,
      lighting_condition: activity.lighting_condition,
      lighting_condition_detail: activity.lighting_condition_detail,
      lighting_condition_model: activity.lighting_condition_model,
      lighting_detail_model: activity.lighting_detail_model,
      lighting_confidence: activity.lighting_confidence,
      command_window_id: activity.command_window_id,
      command_window_type: activity.command_window_type,
      command_window: activity.command_window,
      start_s: activity.start_s,
      end_s: activity.end_s,
      epoch_s: activity.epoch_s,
      delta_v_km_s: activity.delta_v_km_s,
      frame: frame_name(activity.frame),
      target_id: activity.target_id,
      ground_station_id: activity.ground_station_id,
      direction: activity.direction,
      status: activity.status,
      approval_status: activity.approval_status,
      locked: activity.locked?,
      dependencies: activity.dependencies,
      dependency_activity_ids: activity.dependency_activity_ids,
      dependency_timeline_ids: activity.dependency_timeline_ids,
      exclusive_with_activity_ids: activity.exclusive_with_activity_ids,
      exclusive_with_timeline_ids: activity.exclusive_with_timeline_ids,
      exclusivity_group: activity.exclusivity_group,
      source_window_id: activity.source_window_id,
      source_window_type: activity.source_window_type,
      source_window: activity.source_window,
      cadence_import: activity.cadence_import,
      execution_uncertainty: activity.execution_uncertainty,
      provenance: activity.provenance,
      metadata: activity.metadata,
      allow_overlap?: activity.allow_overlap?
    }
    |> Enum.reject(fn
      {:product_ids, []} -> true
      {:incompatible_activity_types, []} -> true
      {:suppressed_activity_types, []} -> true
      {:target_priority_objective_ids, []} -> true
      {:observation_objective_ids, []} -> true
      {:observation_objective_types, []} -> true
      {:collection_latency_objective_ids, []} -> true
      {:collection_latency_objective_types, []} -> true
      {:station_calendar_directions, []} -> true
      {:source_station_calendar_overlaps, []} -> true
      {:station_calendar_overlap_entry_ids, []} -> true
      {:station_calendar_overlap_availabilities, []} -> true
      {:station_calendar_ambiguous_entry_ids, []} -> true
      {:station_calendar_reservation_expires_at_s, []} -> true
      {:station_calendar_reservation_ids, []} -> true
      {:station_calendar_reserved_by, []} -> true
      {:station_calendar_reservation_statuses, []} -> true
      {:downlink_completion_sources, []} -> true
      {_key, value} -> is_nil(value)
    end)
    |> Map.new()
  end

  @doc """
  Returns a string-keyed activity map for JSON-facing artifacts.
  """
  def to_artifact_map(%__MODULE__{} = activity) do
    activity
    |> to_map()
    |> Map.new(fn {key, value} -> {Atom.to_string(key), artifact_value(value)} end)
  end

  defp interval_activity!(id, type, start_s, end_s, opts) when type in @activity_types do
    metadata = Keyword.get(opts, :metadata, %{})
    allow_overlap? = Keyword.get(opts, :allow_overlap?, false)
    common = common_fields!(opts)

    cond do
      invalid_identifier?(id) ->
        raise ArgumentError, "activity id is required"

      not non_negative_number?(start_s) ->
        raise ArgumentError, "start_s must be non-negative seconds"

      not non_negative_number?(end_s) or end_s <= start_s ->
        raise ArgumentError, "end_s must be greater than start_s"

      not is_map(metadata) ->
        raise ArgumentError, "metadata must be a map"

      not is_boolean(allow_overlap?) ->
        raise ArgumentError, "allow_overlap? must be a boolean"

      true ->
        struct!(
          __MODULE__,
          Map.merge(common, %{
            id: id,
            type: type,
            start_s: start_s,
            end_s: end_s,
            metadata: metadata,
            allow_overlap?: allow_overlap?
          })
        )
    end
  end

  defp common_fields!(opts) do
    status = optional_activity_status_atom!(Keyword.get(opts, :status, :planned))

    approval_status =
      optional_approval_status_atom!(Keyword.get(opts, :approval_status, :not_required))

    locked? = Keyword.get(opts, :locked?, false)
    timeline_id = Keyword.get(opts, :timeline_id)
    scenario_id = Keyword.get(opts, :scenario_id)
    spacecraft_id = Keyword.get(opts, :spacecraft_id)
    resource_id = Keyword.get(opts, :resource_id)
    resource_source_quality = Keyword.get(opts, :resource_source_quality)
    resource_trust_boundary = Keyword.get(opts, :resource_trust_boundary)
    resource_trust_boundary_status = Keyword.get(opts, :resource_trust_boundary_status)
    resource_provenance = Keyword.get(opts, :resource_provenance)
    resource_blocking_dimension = Keyword.get(opts, :resource_blocking_dimension)
    station_availability = Keyword.get(opts, :station_availability)
    station_calendar_entry_id = Keyword.get(opts, :station_calendar_entry_id)
    station_calendar_provider_id = Keyword.get(opts, :station_calendar_provider_id)
    station_calendar_provider_entry_id = Keyword.get(opts, :station_calendar_provider_entry_id)
    station_calendar_directions = Keyword.get(opts, :station_calendar_directions, [])
    station_calendar_status = Keyword.get(opts, :station_calendar_status)

    station_calendar_trust_boundary_status =
      Keyword.get(opts, :station_calendar_trust_boundary_status)

    source_station_calendar_entry = Keyword.get(opts, :source_station_calendar_entry)
    source_station_calendar_overlaps = Keyword.get(opts, :source_station_calendar_overlaps, [])
    station_calendar_overlap_count = Keyword.get(opts, :station_calendar_overlap_count)

    station_calendar_overlap_entry_ids =
      Keyword.get(opts, :station_calendar_overlap_entry_ids, [])

    station_calendar_overlap_availabilities =
      Keyword.get(opts, :station_calendar_overlap_availabilities, [])

    station_calendar_entry_ambiguous = Keyword.get(opts, :station_calendar_entry_ambiguous)

    station_calendar_ambiguous_entry_count =
      Keyword.get(opts, :station_calendar_ambiguous_entry_count)

    station_calendar_ambiguous_entry_ids =
      Keyword.get(opts, :station_calendar_ambiguous_entry_ids, [])

    station_contention_status = Keyword.get(opts, :station_contention_status)

    station_calendar_reservation_overlap_count =
      Keyword.get(opts, :station_calendar_reservation_overlap_count)

    station_calendar_reservation_expires_at_s =
      Keyword.get(opts, :station_calendar_reservation_expires_at_s, [])

    station_calendar_reservation_ids =
      Keyword.get(opts, :station_calendar_reservation_ids, [])

    station_calendar_reserved_by = Keyword.get(opts, :station_calendar_reserved_by, [])

    station_calendar_reservation_statuses =
      Keyword.get(opts, :station_calendar_reservation_statuses, [])

    station_reservation_id = Keyword.get(opts, :station_reservation_id)
    station_reservation_expires_at_s = Keyword.get(opts, :station_reservation_expires_at_s)
    station_reserved_by = Keyword.get(opts, :station_reserved_by)
    station_reservation_status = Keyword.get(opts, :station_reservation_status)
    station_reservation_match_status = Keyword.get(opts, :station_reservation_match_status)
    capacity_fraction = Keyword.get(opts, :capacity_fraction)
    station_capacity_fraction = Keyword.get(opts, :station_capacity_fraction)
    capacity_pack_capacity_fraction = Keyword.get(opts, :capacity_pack_capacity_fraction)
    fuel_margin = Keyword.get(opts, :fuel_margin)
    power_margin = Keyword.get(opts, :power_margin)
    storage_margin = Keyword.get(opts, :storage_margin)
    downlink_margin = Keyword.get(opts, :downlink_margin)
    battery_capacity_wh = Keyword.get(opts, :battery_capacity_wh)
    battery_energy_used_wh = Keyword.get(opts, :battery_energy_used_wh)
    battery_energy_generated_wh = Keyword.get(opts, :battery_energy_generated_wh)
    battery_state_of_charge = Keyword.get(opts, :battery_state_of_charge)
    spacecraft_available = Keyword.get(opts, :spacecraft_available)
    payload_available = Keyword.get(opts, :payload_available)
    antenna_available = Keyword.get(opts, :antenna_available)
    degraded = Keyword.get(opts, :degraded)
    mode = Keyword.get(opts, :mode)
    incompatible_activity_types = Keyword.get(opts, :incompatible_activity_types, [])
    suppressed_activity_types = Keyword.get(opts, :suppressed_activity_types, [])
    collection_id = Keyword.get(opts, :collection_id)
    product_id = Keyword.get(opts, :product_id)
    product_ids = Keyword.get(opts, :product_ids, [])
    payload_id = Keyword.get(opts, :payload_id)
    instrument_id = Keyword.get(opts, :instrument_id)
    target_priority = Keyword.get(opts, :target_priority)
    target_priority_source = Keyword.get(opts, :target_priority_source)
    target_priority_objective_ids = Keyword.get(opts, :target_priority_objective_ids, [])
    target_priority_objective_type = Keyword.get(opts, :target_priority_objective_type)
    observation_objective_count = Keyword.get(opts, :observation_objective_count)
    observation_objective_ids = Keyword.get(opts, :observation_objective_ids, [])
    observation_objective_source = Keyword.get(opts, :observation_objective_source)
    observation_objective_types = Keyword.get(opts, :observation_objective_types, [])
    contact_success = Keyword.get(opts, :contact_success)
    contact_result = Keyword.get(opts, :contact_result)
    contact_success_factor = Keyword.get(opts, :contact_success_factor)
    contact_success_factor_source = Keyword.get(opts, :contact_success_factor_source)
    command_success = Keyword.get(opts, :command_success)
    command_result = Keyword.get(opts, :command_result)
    command_success_factor = Keyword.get(opts, :command_success_factor)
    command_success_factor_source = Keyword.get(opts, :command_success_factor_source)
    observation_success = Keyword.get(opts, :observation_success)
    observation_result = Keyword.get(opts, :observation_result)
    observation_success_factor = Keyword.get(opts, :observation_success_factor)
    observation_success_factor_source = Keyword.get(opts, :observation_success_factor_source)
    image_quality_score = Keyword.get(opts, :image_quality_score)
    image_quality_status = Keyword.get(opts, :image_quality_status)
    image_quality_source = Keyword.get(opts, :image_quality_source)
    cloud_cover_fraction = Keyword.get(opts, :cloud_cover_fraction)
    blur_score = Keyword.get(opts, :blur_score)
    maneuver_success = Keyword.get(opts, :maneuver_success)
    maneuver_result = Keyword.get(opts, :maneuver_result)
    maneuver_success_factor = Keyword.get(opts, :maneuver_success_factor)
    maneuver_success_factor_source = Keyword.get(opts, :maneuver_success_factor_source)
    feedback_weight = Keyword.get(opts, :feedback_weight)
    feedback_weight_source = Keyword.get(opts, :feedback_weight_source)
    data_volume_mb = Keyword.get(opts, :data_volume_mb)
    planned_data_volume_mb = Keyword.get(opts, :planned_data_volume_mb)
    planned_volume_mb = Keyword.get(opts, :planned_volume_mb)
    actual_data_volume_mb = Keyword.get(opts, :actual_data_volume_mb)
    actual_volume_mb = Keyword.get(opts, :actual_volume_mb)
    estimated_data_volume_mb = Keyword.get(opts, :estimated_data_volume_mb)
    estimated_storage_mb = Keyword.get(opts, :estimated_storage_mb)
    estimated_downlink_mb = Keyword.get(opts, :estimated_downlink_mb)
    required_downlink_mb = Keyword.get(opts, :required_downlink_mb)
    required_volume_mb = Keyword.get(opts, :required_volume_mb)
    required_data_volume_mb = Keyword.get(opts, :required_data_volume_mb)
    target_downlink_mb = Keyword.get(opts, :target_downlink_mb)
    target_volume_mb = Keyword.get(opts, :target_volume_mb)
    target_data_volume_mb = Keyword.get(opts, :target_data_volume_mb)
    min_downlink_mb = Keyword.get(opts, :min_downlink_mb)
    selected_downlink_mb = Keyword.get(opts, :selected_downlink_mb)
    selected_data_volume_mb = Keyword.get(opts, :selected_data_volume_mb)
    selected_volume_mb = Keyword.get(opts, :selected_volume_mb)
    delivered_data_volume_mb = Keyword.get(opts, :delivered_data_volume_mb)
    received_data_volume_mb = Keyword.get(opts, :received_data_volume_mb)
    selected_downlink_shortfall_mb = Keyword.get(opts, :selected_downlink_shortfall_mb)
    selected_data_volume_shortfall_mb = Keyword.get(opts, :selected_data_volume_shortfall_mb)
    data_volume_shortfall_mb = Keyword.get(opts, :data_volume_shortfall_mb)
    actual_data_volume_shortfall_mb = Keyword.get(opts, :actual_data_volume_shortfall_mb)
    missing_data_volume_mb = Keyword.get(opts, :missing_data_volume_mb)
    required_data_volume_gap_mb = Keyword.get(opts, :required_data_volume_gap_mb)
    downlink_requirement_status = Keyword.get(opts, :downlink_requirement_status)
    downlink_completion_source = Keyword.get(opts, :downlink_completion_source)
    downlink_completion_sources = Keyword.get(opts, :downlink_completion_sources, [])
    collection_ends_at_s = Keyword.get(opts, :collection_ends_at_s)
    planned_delivery_at_s = Keyword.get(opts, :planned_delivery_at_s)
    actual_delivery_at_s = Keyword.get(opts, :actual_delivery_at_s)
    max_latency_s = Keyword.get(opts, :max_latency_s)
    planned_latency_s = Keyword.get(opts, :planned_latency_s)
    actual_latency_s = Keyword.get(opts, :actual_latency_s)
    collection_latency_objective_count = Keyword.get(opts, :collection_latency_objective_count)
    collection_latency_objective_ids = Keyword.get(opts, :collection_latency_objective_ids, [])
    collection_latency_objective_source = Keyword.get(opts, :collection_latency_objective_source)

    collection_latency_objective_types =
      Keyword.get(opts, :collection_latency_objective_types, [])

    planned_estimated_throughput_mb = Keyword.get(opts, :planned_estimated_throughput_mb)
    actual_throughput_mb = Keyword.get(opts, :actual_throughput_mb)
    link_protocol = Keyword.get(opts, :link_protocol)
    frequency_band = Keyword.get(opts, :frequency_band)
    modulation = Keyword.get(opts, :modulation)
    coding_scheme = Keyword.get(opts, :coding_scheme)
    polarization = Keyword.get(opts, :polarization)
    data_rate_mbps = Keyword.get(opts, :data_rate_mbps)
    downlink_rate_mbps = Keyword.get(opts, :downlink_rate_mbps)
    data_rate_mb_s = Keyword.get(opts, :data_rate_mb_s)
    downlink_rate_mb_s = Keyword.get(opts, :downlink_rate_mb_s)
    actual_data_rate_mbps = Keyword.get(opts, :actual_data_rate_mbps)
    actual_downlink_rate_mbps = Keyword.get(opts, :actual_downlink_rate_mbps)
    actual_data_rate_mb_s = Keyword.get(opts, :actual_data_rate_mb_s)
    actual_downlink_rate_mb_s = Keyword.get(opts, :actual_downlink_rate_mb_s)
    delivered_rate_mbps = Keyword.get(opts, :delivered_rate_mbps)
    received_rate_mbps = Keyword.get(opts, :received_rate_mbps)
    delivered_rate_mb_s = Keyword.get(opts, :delivered_rate_mb_s)
    received_rate_mb_s = Keyword.get(opts, :received_rate_mb_s)
    actual_duration_s = Keyword.get(opts, :actual_duration_s)
    actual_contact_duration_s = Keyword.get(opts, :actual_contact_duration_s)
    contact_duration_s = Keyword.get(opts, :contact_duration_s)
    link_margin_db = Keyword.get(opts, :link_margin_db)
    snr_db = Keyword.get(opts, :snr_db)
    eb_no_db = Keyword.get(opts, :eb_no_db)
    bit_error_rate = Keyword.get(opts, :bit_error_rate)
    packet_loss_rate = Keyword.get(opts, :packet_loss_rate)
    frame_loss_rate = Keyword.get(opts, :frame_loss_rate)
    carrier_lock = Keyword.get(opts, :carrier_lock)
    symbol_lock = Keyword.get(opts, :symbol_lock)
    link_quality_status = Keyword.get(opts, :link_quality_status)
    pointing_mode = Keyword.get(opts, :pointing_mode)
    pointing_target_id = Keyword.get(opts, :pointing_target_id)
    boresight_axis = Keyword.get(opts, :boresight_axis)
    off_nadir_angle_deg = Keyword.get(opts, :off_nadir_angle_deg)
    slew_angle_deg = Keyword.get(opts, :slew_angle_deg)
    slew_rate_deg_s = Keyword.get(opts, :slew_rate_deg_s)
    pointing_error_deg = Keyword.get(opts, :pointing_error_deg)
    pointing_status = Keyword.get(opts, :pointing_status)
    pointing_model = Keyword.get(opts, :pointing_model)
    pointing_source = Keyword.get(opts, :pointing_source)
    pointing_confidence = Keyword.get(opts, :pointing_confidence)
    attitude_mode = Keyword.get(opts, :attitude_mode)
    attitude_target_id = Keyword.get(opts, :attitude_target_id)
    roll_deg = Keyword.get(opts, :roll_deg)
    pitch_deg = Keyword.get(opts, :pitch_deg)
    yaw_deg = Keyword.get(opts, :yaw_deg)
    attitude_error_deg = Keyword.get(opts, :attitude_error_deg)
    attitude_status = Keyword.get(opts, :attitude_status)
    attitude_model = Keyword.get(opts, :attitude_model)
    attitude_source = Keyword.get(opts, :attitude_source)
    attitude_confidence = Keyword.get(opts, :attitude_confidence)
    thermal_zone_id = Keyword.get(opts, :thermal_zone_id)
    temperature_c = Keyword.get(opts, :temperature_c)
    planned_temperature_c = Keyword.get(opts, :planned_temperature_c)
    actual_temperature_c = Keyword.get(opts, :actual_temperature_c)
    min_operating_temperature_c = Keyword.get(opts, :min_operating_temperature_c)
    max_operating_temperature_c = Keyword.get(opts, :max_operating_temperature_c)
    thermal_margin_c = Keyword.get(opts, :thermal_margin_c)
    thermal_status = Keyword.get(opts, :thermal_status)
    thermal_model = Keyword.get(opts, :thermal_model)
    thermal_source = Keyword.get(opts, :thermal_source)
    thermal_confidence = Keyword.get(opts, :thermal_confidence)
    eclipse_overlap_fraction = Keyword.get(opts, :eclipse_overlap_fraction)
    eclipse_overlap_s = Keyword.get(opts, :eclipse_overlap_s)
    lighting_condition = Keyword.get(opts, :lighting_condition)
    lighting_condition_detail = Keyword.get(opts, :lighting_condition_detail)
    lighting_condition_model = Keyword.get(opts, :lighting_condition_model)
    lighting_detail_model = Keyword.get(opts, :lighting_detail_model)
    lighting_confidence = Keyword.get(opts, :lighting_confidence)
    command_window_id = Keyword.get(opts, :command_window_id)
    command_window_type = Keyword.get(opts, :command_window_type)
    command_window = Keyword.get(opts, :command_window)

    explicit_dependency_activity_ids? = Keyword.has_key?(opts, :dependency_activity_ids)

    dependencies =
      Keyword.get(opts, :dependencies, Keyword.get(opts, :dependency_activity_ids, []))

    dependency_activity_ids = Keyword.get(opts, :dependency_activity_ids, dependencies)
    dependency_timeline_ids = Keyword.get(opts, :dependency_timeline_ids, [])

    explicit_exclusive_with_activity_ids? = Keyword.has_key?(opts, :exclusive_with_activity_ids)

    exclusive_with_activity_ids =
      Keyword.get(opts, :exclusive_with_activity_ids, Keyword.get(opts, :exclusive_with, []))

    exclusive_with_timeline_ids = Keyword.get(opts, :exclusive_with_timeline_ids, [])
    exclusivity_group = Keyword.get(opts, :exclusivity_group)
    source_window = Keyword.get(opts, :source_window)

    source_window_id =
      Keyword.get(opts, :source_window_id, nested_source_window_id(source_window))

    source_window_type =
      Keyword.get(opts, :source_window_type, nested_source_window_type(source_window))

    cadence_import =
      opts
      |> Keyword.get(:cadence_import)
      |> normalize_cadence_import()

    execution_uncertainty = Keyword.get(opts, :execution_uncertainty)
    provenance = Keyword.get(opts, :provenance, %{})

    dependencies = dependencies_input!(dependencies, "dependencies", "activity ids")

    dependency_activity_ids =
      if explicit_dependency_activity_ids? do
        id_list_input!(dependency_activity_ids, "dependency_activity_ids", "activity ids")
      else
        dependency_activity_ids(dependencies)
      end

    dependency_timeline_ids =
      id_list_input!(dependency_timeline_ids, "dependency_timeline_ids", "timeline ids")

    exclusive_with_activity_ids =
      if explicit_exclusive_with_activity_ids? do
        id_list_input!(
          exclusive_with_activity_ids,
          "exclusive_with_activity_ids",
          "activity ids"
        )
      else
        dependency_activity_ids(
          dependencies_input!(
            exclusive_with_activity_ids,
            "exclusive_with_activity_ids",
            "activity ids"
          )
        )
      end

    exclusive_with_timeline_ids =
      id_list_input!(exclusive_with_timeline_ids, "exclusive_with_timeline_ids", "timeline ids")

    source_station_calendar_overlaps =
      map_list_input!(
        source_station_calendar_overlaps,
        "source_station_calendar_overlaps",
        "source station-calendar overlap maps"
      )

    station_calendar_overlap_entry_ids =
      id_list_input!(
        station_calendar_overlap_entry_ids,
        "station_calendar_overlap_entry_ids",
        "station-calendar entry ids"
      )

    station_calendar_overlap_availabilities =
      scalar_list_input!(
        station_calendar_overlap_availabilities,
        "station_calendar_overlap_availabilities",
        "station-calendar availability labels"
      )

    station_calendar_ambiguous_entry_ids =
      id_list_input!(
        station_calendar_ambiguous_entry_ids,
        "station_calendar_ambiguous_entry_ids",
        "station-calendar entry ids"
      )

    station_calendar_reservation_expires_at_s =
      non_negative_number_list_input!(
        station_calendar_reservation_expires_at_s,
        "station_calendar_reservation_expires_at_s"
      )

    station_calendar_reservation_ids =
      id_list_input!(
        station_calendar_reservation_ids,
        "station_calendar_reservation_ids",
        "station reservation ids"
      )

    station_calendar_reserved_by =
      scalar_list_input!(
        station_calendar_reserved_by,
        "station_calendar_reserved_by",
        "reservation owner labels"
      )

    station_calendar_reservation_statuses =
      scalar_list_input!(
        station_calendar_reservation_statuses,
        "station_calendar_reservation_statuses",
        "reservation status labels"
      )

    cond do
      status not in @activity_statuses ->
        raise ArgumentError, "status must be one of #{inspect(@activity_statuses)}"

      approval_status not in @approval_statuses ->
        raise ArgumentError, "approval_status must be one of #{inspect(@approval_statuses)}"

      not is_boolean(locked?) ->
        raise ArgumentError, "locked? must be a boolean"

      not (is_nil(timeline_id) or not invalid_identifier?(timeline_id)) ->
        raise ArgumentError, "timeline_id must be nil or an identifier"

      not (is_nil(scenario_id) or not invalid_identifier?(scenario_id)) ->
        raise ArgumentError, "scenario_id must be nil or an identifier"

      not (is_nil(spacecraft_id) or not invalid_identifier?(spacecraft_id)) ->
        raise ArgumentError, "spacecraft_id must be nil or an identifier"

      not (is_nil(resource_id) or not invalid_identifier?(resource_id)) ->
        raise ArgumentError, "resource_id must be nil or an identifier"

      not optional_scalar?(resource_source_quality) ->
        raise ArgumentError, "resource_source_quality must be nil, a string, or an atom"

      not optional_scalar?(resource_trust_boundary) ->
        raise ArgumentError, "resource_trust_boundary must be nil, a string, or an atom"

      not optional_scalar?(resource_trust_boundary_status) ->
        raise ArgumentError, "resource_trust_boundary_status must be nil, a string, or an atom"

      not (is_nil(resource_provenance) or is_map(resource_provenance)) ->
        raise ArgumentError, "resource_provenance must be nil or a map"

      not optional_scalar?(resource_blocking_dimension) ->
        raise ArgumentError, "resource_blocking_dimension must be nil, a string, or an atom"

      not optional_scalar?(station_availability) ->
        raise ArgumentError, "station_availability must be nil, a string, or an atom"

      not optional_stable_identifier?(station_calendar_entry_id) ->
        raise ArgumentError, "station_calendar_entry_id must be nil or a stable identifier"

      not optional_stable_identifier?(station_calendar_provider_id) ->
        raise ArgumentError, "station_calendar_provider_id must be nil or a stable identifier"

      not optional_stable_identifier?(station_calendar_provider_entry_id) ->
        raise ArgumentError,
              "station_calendar_provider_entry_id must be nil or a stable identifier"

      not valid_scalar_list?(station_calendar_directions) ->
        raise ArgumentError, "station_calendar_directions must be a list of direction labels"

      not optional_scalar?(station_calendar_status) ->
        raise ArgumentError, "station_calendar_status must be nil, a string, or an atom"

      not optional_scalar?(station_calendar_trust_boundary_status) ->
        raise ArgumentError,
              "station_calendar_trust_boundary_status must be nil, a string, or an atom"

      not (is_nil(source_station_calendar_entry) or is_map(source_station_calendar_entry)) ->
        raise ArgumentError, "source_station_calendar_entry must be nil or a map"

      not optional_non_negative_integer?(station_calendar_overlap_count) ->
        raise ArgumentError,
              "station_calendar_overlap_count must be nil or a non-negative integer"

      not optional_boolean?(station_calendar_entry_ambiguous) ->
        raise ArgumentError, "station_calendar_entry_ambiguous must be nil or a boolean"

      not optional_non_negative_integer?(station_calendar_ambiguous_entry_count) ->
        raise ArgumentError,
              "station_calendar_ambiguous_entry_count must be nil or a non-negative integer"

      not optional_scalar?(station_contention_status) ->
        raise ArgumentError, "station_contention_status must be nil, a string, or an atom"

      not optional_non_negative_integer?(station_calendar_reservation_overlap_count) ->
        raise ArgumentError,
              "station_calendar_reservation_overlap_count must be nil or a non-negative integer"

      not optional_stable_identifier?(station_reservation_id) ->
        raise ArgumentError, "station_reservation_id must be nil or a stable identifier"

      not optional_non_negative_number?(station_reservation_expires_at_s) ->
        raise ArgumentError,
              "station_reservation_expires_at_s must be nil or a non-negative number"

      not optional_scalar?(station_reserved_by) ->
        raise ArgumentError, "station_reserved_by must be nil, a string, or an atom"

      not optional_scalar?(station_reservation_status) ->
        raise ArgumentError, "station_reservation_status must be nil, a string, or an atom"

      not optional_scalar?(station_reservation_match_status) ->
        raise ArgumentError,
              "station_reservation_match_status must be nil, a string, or an atom"

      not optional_unit_interval?(capacity_fraction) ->
        raise ArgumentError, "capacity_fraction must be nil or between 0.0 and 1.0"

      not optional_unit_interval?(station_capacity_fraction) ->
        raise ArgumentError, "station_capacity_fraction must be nil or between 0.0 and 1.0"

      not optional_unit_interval?(capacity_pack_capacity_fraction) ->
        raise ArgumentError, "capacity_pack_capacity_fraction must be nil or between 0.0 and 1.0"

      not optional_unit_interval?(fuel_margin) ->
        raise ArgumentError, "fuel_margin must be nil or between 0.0 and 1.0"

      not optional_unit_interval?(power_margin) ->
        raise ArgumentError, "power_margin must be nil or between 0.0 and 1.0"

      not optional_unit_interval?(storage_margin) ->
        raise ArgumentError, "storage_margin must be nil or between 0.0 and 1.0"

      not optional_unit_interval?(downlink_margin) ->
        raise ArgumentError, "downlink_margin must be nil or between 0.0 and 1.0"

      not optional_number?(battery_capacity_wh) ->
        raise ArgumentError, "battery_capacity_wh must be nil or a number"

      not optional_number?(battery_energy_used_wh) ->
        raise ArgumentError, "battery_energy_used_wh must be nil or a number"

      not optional_non_negative_number?(battery_energy_generated_wh) ->
        raise ArgumentError, "battery_energy_generated_wh must be nil or a non-negative number"

      not optional_unit_interval?(battery_state_of_charge) ->
        raise ArgumentError, "battery_state_of_charge must be nil or between 0.0 and 1.0"

      not optional_boolean?(spacecraft_available) ->
        raise ArgumentError, "spacecraft_available must be nil or a boolean"

      not optional_boolean?(payload_available) ->
        raise ArgumentError, "payload_available must be nil or a boolean"

      not optional_boolean?(antenna_available) ->
        raise ArgumentError, "antenna_available must be nil or a boolean"

      not optional_boolean?(degraded) ->
        raise ArgumentError, "degraded must be nil or a boolean"

      not optional_scalar?(mode) ->
        raise ArgumentError, "mode must be nil, a string, or an atom"

      not valid_dependencies?(incompatible_activity_types) ->
        raise ArgumentError, "incompatible_activity_types must be a list of activity types"

      not valid_dependencies?(suppressed_activity_types) ->
        raise ArgumentError, "suppressed_activity_types must be a list of activity types"

      not (is_nil(collection_id) or not invalid_identifier?(collection_id)) ->
        raise ArgumentError, "collection_id must be nil or an identifier"

      not (is_nil(product_id) or not invalid_identifier?(product_id)) ->
        raise ArgumentError, "product_id must be nil or an identifier"

      not valid_dependencies?(product_ids) ->
        raise ArgumentError, "product_ids must be a list of product ids"

      not (is_nil(payload_id) or not invalid_identifier?(payload_id)) ->
        raise ArgumentError, "payload_id must be nil or an identifier"

      not (is_nil(instrument_id) or not invalid_identifier?(instrument_id)) ->
        raise ArgumentError, "instrument_id must be nil or an identifier"

      not optional_number?(target_priority) ->
        raise ArgumentError, "target_priority must be nil or a number"

      not optional_scalar?(target_priority_source) ->
        raise ArgumentError, "target_priority_source must be nil, a string, or an atom"

      not valid_dependencies?(target_priority_objective_ids) ->
        raise ArgumentError, "target_priority_objective_ids must be a list of objective ids"

      not optional_scalar?(target_priority_objective_type) ->
        raise ArgumentError, "target_priority_objective_type must be nil, a string, or an atom"

      not optional_non_negative_integer?(observation_objective_count) ->
        raise ArgumentError,
              "observation_objective_count must be nil or a non-negative integer"

      not valid_dependencies?(observation_objective_ids) ->
        raise ArgumentError, "observation_objective_ids must be a list of objective ids"

      not optional_scalar?(observation_objective_source) ->
        raise ArgumentError,
              "observation_objective_source must be nil, a string, or an atom"

      not valid_scalar_list?(observation_objective_types) ->
        raise ArgumentError, "observation_objective_types must be a list of objective types"

      not optional_boolean?(contact_success) ->
        raise ArgumentError, "contact_success must be nil or a boolean"

      not optional_scalar?(contact_result) ->
        raise ArgumentError, "contact_result must be nil, a string, or an atom"

      not optional_number?(contact_success_factor) ->
        raise ArgumentError, "contact_success_factor must be nil or a number"

      not optional_scalar?(contact_success_factor_source) ->
        raise ArgumentError, "contact_success_factor_source must be nil, a string, or an atom"

      not optional_boolean?(command_success) ->
        raise ArgumentError, "command_success must be nil or a boolean"

      not optional_scalar?(command_result) ->
        raise ArgumentError, "command_result must be nil, a string, or an atom"

      not optional_number?(command_success_factor) ->
        raise ArgumentError, "command_success_factor must be nil or a number"

      not optional_scalar?(command_success_factor_source) ->
        raise ArgumentError, "command_success_factor_source must be nil, a string, or an atom"

      not optional_boolean?(observation_success) ->
        raise ArgumentError, "observation_success must be nil or a boolean"

      not optional_scalar?(observation_result) ->
        raise ArgumentError, "observation_result must be nil, a string, or an atom"

      not optional_number?(observation_success_factor) ->
        raise ArgumentError, "observation_success_factor must be nil or a number"

      not optional_scalar?(observation_success_factor_source) ->
        raise ArgumentError,
              "observation_success_factor_source must be nil, a string, or an atom"

      not optional_number?(image_quality_score) ->
        raise ArgumentError, "image_quality_score must be nil or a number"

      not optional_scalar?(image_quality_status) ->
        raise ArgumentError, "image_quality_status must be nil, a string, or an atom"

      not optional_scalar?(image_quality_source) ->
        raise ArgumentError, "image_quality_source must be nil, a string, or an atom"

      not optional_number?(cloud_cover_fraction) ->
        raise ArgumentError, "cloud_cover_fraction must be nil or a number"

      not optional_number?(blur_score) ->
        raise ArgumentError, "blur_score must be nil or a number"

      not optional_boolean?(maneuver_success) ->
        raise ArgumentError, "maneuver_success must be nil or a boolean"

      not optional_scalar?(maneuver_result) ->
        raise ArgumentError, "maneuver_result must be nil, a string, or an atom"

      not optional_number?(maneuver_success_factor) ->
        raise ArgumentError, "maneuver_success_factor must be nil or a number"

      not optional_scalar?(maneuver_success_factor_source) ->
        raise ArgumentError, "maneuver_success_factor_source must be nil, a string, or an atom"

      not optional_number?(feedback_weight) ->
        raise ArgumentError, "feedback_weight must be nil or a number"

      not optional_scalar?(feedback_weight_source) ->
        raise ArgumentError, "feedback_weight_source must be nil, a string, or an atom"

      not optional_number?(data_volume_mb) ->
        raise ArgumentError, "data_volume_mb must be nil or a number"

      not optional_number?(planned_data_volume_mb) ->
        raise ArgumentError, "planned_data_volume_mb must be nil or a number"

      not optional_number?(planned_volume_mb) ->
        raise ArgumentError, "planned_volume_mb must be nil or a number"

      not optional_number?(actual_data_volume_mb) ->
        raise ArgumentError, "actual_data_volume_mb must be nil or a number"

      not optional_number?(actual_volume_mb) ->
        raise ArgumentError, "actual_volume_mb must be nil or a number"

      not optional_number?(estimated_data_volume_mb) ->
        raise ArgumentError, "estimated_data_volume_mb must be nil or a number"

      not optional_number?(estimated_storage_mb) ->
        raise ArgumentError, "estimated_storage_mb must be nil or a number"

      not optional_number?(estimated_downlink_mb) ->
        raise ArgumentError, "estimated_downlink_mb must be nil or a number"

      not optional_number?(required_downlink_mb) ->
        raise ArgumentError, "required_downlink_mb must be nil or a number"

      not optional_number?(required_volume_mb) ->
        raise ArgumentError, "required_volume_mb must be nil or a number"

      not optional_number?(required_data_volume_mb) ->
        raise ArgumentError, "required_data_volume_mb must be nil or a number"

      not optional_number?(target_downlink_mb) ->
        raise ArgumentError, "target_downlink_mb must be nil or a number"

      not optional_number?(target_volume_mb) ->
        raise ArgumentError, "target_volume_mb must be nil or a number"

      not optional_number?(target_data_volume_mb) ->
        raise ArgumentError, "target_data_volume_mb must be nil or a number"

      not optional_number?(min_downlink_mb) ->
        raise ArgumentError, "min_downlink_mb must be nil or a number"

      not optional_number?(selected_downlink_mb) ->
        raise ArgumentError, "selected_downlink_mb must be nil or a number"

      not optional_number?(selected_data_volume_mb) ->
        raise ArgumentError, "selected_data_volume_mb must be nil or a number"

      not optional_number?(selected_volume_mb) ->
        raise ArgumentError, "selected_volume_mb must be nil or a number"

      not optional_number?(delivered_data_volume_mb) ->
        raise ArgumentError, "delivered_data_volume_mb must be nil or a number"

      not optional_number?(received_data_volume_mb) ->
        raise ArgumentError, "received_data_volume_mb must be nil or a number"

      not optional_number?(selected_downlink_shortfall_mb) ->
        raise ArgumentError, "selected_downlink_shortfall_mb must be nil or a number"

      not optional_number?(selected_data_volume_shortfall_mb) ->
        raise ArgumentError, "selected_data_volume_shortfall_mb must be nil or a number"

      not optional_number?(data_volume_shortfall_mb) ->
        raise ArgumentError, "data_volume_shortfall_mb must be nil or a number"

      not optional_number?(actual_data_volume_shortfall_mb) ->
        raise ArgumentError, "actual_data_volume_shortfall_mb must be nil or a number"

      not optional_number?(missing_data_volume_mb) ->
        raise ArgumentError, "missing_data_volume_mb must be nil or a number"

      not optional_number?(required_data_volume_gap_mb) ->
        raise ArgumentError, "required_data_volume_gap_mb must be nil or a number"

      not optional_scalar?(downlink_requirement_status) ->
        raise ArgumentError, "downlink_requirement_status must be nil, a string, or an atom"

      not optional_scalar?(downlink_completion_source) ->
        raise ArgumentError, "downlink_completion_source must be nil, a string, or an atom"

      not valid_dependencies?(downlink_completion_sources) ->
        raise ArgumentError, "downlink_completion_sources must be a list of source ids"

      not optional_number?(collection_ends_at_s) ->
        raise ArgumentError, "collection_ends_at_s must be nil or a number"

      not optional_number?(planned_delivery_at_s) ->
        raise ArgumentError, "planned_delivery_at_s must be nil or a number"

      not optional_number?(actual_delivery_at_s) ->
        raise ArgumentError, "actual_delivery_at_s must be nil or a number"

      not optional_number?(max_latency_s) ->
        raise ArgumentError, "max_latency_s must be nil or a number"

      not optional_number?(planned_latency_s) ->
        raise ArgumentError, "planned_latency_s must be nil or a number"

      not optional_number?(actual_latency_s) ->
        raise ArgumentError, "actual_latency_s must be nil or a number"

      not optional_non_negative_integer?(collection_latency_objective_count) ->
        raise ArgumentError,
              "collection_latency_objective_count must be nil or a non-negative integer"

      not valid_dependencies?(collection_latency_objective_ids) ->
        raise ArgumentError,
              "collection_latency_objective_ids must be a list of objective ids"

      not optional_scalar?(collection_latency_objective_source) ->
        raise ArgumentError,
              "collection_latency_objective_source must be nil, a string, or an atom"

      not valid_scalar_list?(collection_latency_objective_types) ->
        raise ArgumentError,
              "collection_latency_objective_types must be a list of objective types"

      not optional_number?(planned_estimated_throughput_mb) ->
        raise ArgumentError, "planned_estimated_throughput_mb must be nil or a number"

      not optional_number?(actual_throughput_mb) ->
        raise ArgumentError, "actual_throughput_mb must be nil or a number"

      not optional_scalar?(link_protocol) ->
        raise ArgumentError, "link_protocol must be nil, a string, or an atom"

      not optional_scalar?(frequency_band) ->
        raise ArgumentError, "frequency_band must be nil, a string, or an atom"

      not optional_scalar?(modulation) ->
        raise ArgumentError, "modulation must be nil, a string, or an atom"

      not optional_scalar?(coding_scheme) ->
        raise ArgumentError, "coding_scheme must be nil, a string, or an atom"

      not optional_scalar?(polarization) ->
        raise ArgumentError, "polarization must be nil, a string, or an atom"

      not optional_number?(data_rate_mbps) ->
        raise ArgumentError, "data_rate_mbps must be nil or a number"

      not optional_number?(downlink_rate_mbps) ->
        raise ArgumentError, "downlink_rate_mbps must be nil or a number"

      not optional_number?(data_rate_mb_s) ->
        raise ArgumentError, "data_rate_mb_s must be nil or a number"

      not optional_number?(downlink_rate_mb_s) ->
        raise ArgumentError, "downlink_rate_mb_s must be nil or a number"

      not optional_number?(actual_data_rate_mbps) ->
        raise ArgumentError, "actual_data_rate_mbps must be nil or a number"

      not optional_number?(actual_downlink_rate_mbps) ->
        raise ArgumentError, "actual_downlink_rate_mbps must be nil or a number"

      not optional_number?(actual_data_rate_mb_s) ->
        raise ArgumentError, "actual_data_rate_mb_s must be nil or a number"

      not optional_number?(actual_downlink_rate_mb_s) ->
        raise ArgumentError, "actual_downlink_rate_mb_s must be nil or a number"

      not optional_number?(delivered_rate_mbps) ->
        raise ArgumentError, "delivered_rate_mbps must be nil or a number"

      not optional_number?(received_rate_mbps) ->
        raise ArgumentError, "received_rate_mbps must be nil or a number"

      not optional_number?(delivered_rate_mb_s) ->
        raise ArgumentError, "delivered_rate_mb_s must be nil or a number"

      not optional_number?(received_rate_mb_s) ->
        raise ArgumentError, "received_rate_mb_s must be nil or a number"

      not optional_number?(actual_duration_s) ->
        raise ArgumentError, "actual_duration_s must be nil or a number"

      not optional_number?(actual_contact_duration_s) ->
        raise ArgumentError, "actual_contact_duration_s must be nil or a number"

      not optional_number?(contact_duration_s) ->
        raise ArgumentError, "contact_duration_s must be nil or a number"

      not optional_number?(link_margin_db) ->
        raise ArgumentError, "link_margin_db must be nil or a number"

      not optional_number?(snr_db) ->
        raise ArgumentError, "snr_db must be nil or a number"

      not optional_number?(eb_no_db) ->
        raise ArgumentError, "eb_no_db must be nil or a number"

      not optional_number?(bit_error_rate) ->
        raise ArgumentError, "bit_error_rate must be nil or a number"

      not optional_number?(packet_loss_rate) ->
        raise ArgumentError, "packet_loss_rate must be nil or a number"

      not optional_number?(frame_loss_rate) ->
        raise ArgumentError, "frame_loss_rate must be nil or a number"

      not optional_boolean?(carrier_lock) ->
        raise ArgumentError, "carrier_lock must be nil or a boolean"

      not optional_boolean?(symbol_lock) ->
        raise ArgumentError, "symbol_lock must be nil or a boolean"

      not optional_scalar?(link_quality_status) ->
        raise ArgumentError, "link_quality_status must be nil, a string, or an atom"

      not (is_nil(pointing_target_id) or not invalid_identifier?(pointing_target_id)) ->
        raise ArgumentError, "pointing_target_id must be nil or an identifier"

      not optional_scalar?(pointing_mode) ->
        raise ArgumentError, "pointing_mode must be nil, a string, or an atom"

      not optional_scalar?(boresight_axis) ->
        raise ArgumentError, "boresight_axis must be nil, a string, or an atom"

      not optional_number?(off_nadir_angle_deg) ->
        raise ArgumentError, "off_nadir_angle_deg must be nil or a number"

      not optional_number?(slew_angle_deg) ->
        raise ArgumentError, "slew_angle_deg must be nil or a number"

      not optional_number?(slew_rate_deg_s) ->
        raise ArgumentError, "slew_rate_deg_s must be nil or a number"

      not optional_number?(pointing_error_deg) ->
        raise ArgumentError, "pointing_error_deg must be nil or a number"

      not optional_number?(pointing_confidence) ->
        raise ArgumentError, "pointing_confidence must be nil or a number"

      not optional_scalar?(pointing_status) ->
        raise ArgumentError, "pointing_status must be nil, a string, or an atom"

      not optional_scalar?(pointing_model) ->
        raise ArgumentError, "pointing_model must be nil, a string, or an atom"

      not optional_scalar?(pointing_source) ->
        raise ArgumentError, "pointing_source must be nil, a string, or an atom"

      not (is_nil(attitude_target_id) or not invalid_identifier?(attitude_target_id)) ->
        raise ArgumentError, "attitude_target_id must be nil or an identifier"

      not optional_scalar?(attitude_mode) ->
        raise ArgumentError, "attitude_mode must be nil, a string, or an atom"

      not optional_number?(roll_deg) ->
        raise ArgumentError, "roll_deg must be nil or a number"

      not optional_number?(pitch_deg) ->
        raise ArgumentError, "pitch_deg must be nil or a number"

      not optional_number?(yaw_deg) ->
        raise ArgumentError, "yaw_deg must be nil or a number"

      not optional_number?(attitude_error_deg) ->
        raise ArgumentError, "attitude_error_deg must be nil or a number"

      not optional_number?(attitude_confidence) ->
        raise ArgumentError, "attitude_confidence must be nil or a number"

      not optional_scalar?(attitude_status) ->
        raise ArgumentError, "attitude_status must be nil, a string, or an atom"

      not optional_scalar?(attitude_model) ->
        raise ArgumentError, "attitude_model must be nil, a string, or an atom"

      not optional_scalar?(attitude_source) ->
        raise ArgumentError, "attitude_source must be nil, a string, or an atom"

      not (is_nil(thermal_zone_id) or not invalid_identifier?(thermal_zone_id)) ->
        raise ArgumentError, "thermal_zone_id must be nil or an identifier"

      not optional_number?(temperature_c) ->
        raise ArgumentError, "temperature_c must be nil or a number"

      not optional_number?(planned_temperature_c) ->
        raise ArgumentError, "planned_temperature_c must be nil or a number"

      not optional_number?(actual_temperature_c) ->
        raise ArgumentError, "actual_temperature_c must be nil or a number"

      not optional_number?(min_operating_temperature_c) ->
        raise ArgumentError, "min_operating_temperature_c must be nil or a number"

      not optional_number?(max_operating_temperature_c) ->
        raise ArgumentError, "max_operating_temperature_c must be nil or a number"

      not optional_number?(thermal_margin_c) ->
        raise ArgumentError, "thermal_margin_c must be nil or a number"

      not optional_scalar?(thermal_status) ->
        raise ArgumentError, "thermal_status must be nil, a string, or an atom"

      not optional_scalar?(thermal_model) ->
        raise ArgumentError, "thermal_model must be nil, a string, or an atom"

      not optional_scalar?(thermal_source) ->
        raise ArgumentError, "thermal_source must be nil, a string, or an atom"

      not optional_number?(thermal_confidence) ->
        raise ArgumentError, "thermal_confidence must be nil or a number"

      not optional_number?(eclipse_overlap_fraction) ->
        raise ArgumentError, "eclipse_overlap_fraction must be nil or a number"

      not optional_number?(eclipse_overlap_s) ->
        raise ArgumentError, "eclipse_overlap_s must be nil or a number"

      not optional_scalar?(lighting_condition) ->
        raise ArgumentError, "lighting_condition must be nil, a string, or an atom"

      not optional_scalar?(lighting_condition_detail) ->
        raise ArgumentError, "lighting_condition_detail must be nil, a string, or an atom"

      not optional_scalar?(lighting_condition_model) ->
        raise ArgumentError, "lighting_condition_model must be nil, a string, or an atom"

      not optional_scalar?(lighting_detail_model) ->
        raise ArgumentError, "lighting_detail_model must be nil, a string, or an atom"

      not optional_number_or_scalar?(lighting_confidence) ->
        raise ArgumentError, "lighting_confidence must be nil, a number, a string, or an atom"

      not (is_nil(command_window_id) or not invalid_identifier?(command_window_id)) ->
        raise ArgumentError, "command_window_id must be nil or an identifier"

      not (is_nil(command_window_type) or not invalid_identifier?(command_window_type)) ->
        raise ArgumentError, "command_window_type must be nil or an identifier"

      not (is_nil(command_window) or is_map(command_window)) ->
        raise ArgumentError, "command_window must be nil or a map"

      not valid_dependencies?(dependencies) ->
        raise ArgumentError, "dependencies must be a list of activity ids"

      not valid_dependencies?(dependency_activity_ids) ->
        raise ArgumentError, "dependency_activity_ids must be a list of activity ids"

      not valid_dependencies?(dependency_timeline_ids) ->
        raise ArgumentError, "dependency_timeline_ids must be a list of timeline ids"

      not valid_dependencies?(exclusive_with_activity_ids) ->
        raise ArgumentError, "exclusive_with_activity_ids must be a list of activity ids"

      not valid_dependencies?(exclusive_with_timeline_ids) ->
        raise ArgumentError, "exclusive_with_timeline_ids must be a list of timeline ids"

      not (is_nil(exclusivity_group) or not invalid_identifier?(exclusivity_group)) ->
        raise ArgumentError, "exclusivity_group must be nil or an identifier"

      not (is_nil(source_window_id) or not invalid_identifier?(source_window_id)) ->
        raise ArgumentError, "source_window_id must be nil or an identifier"

      not (is_nil(source_window_type) or not invalid_identifier?(source_window_type)) ->
        raise ArgumentError, "source_window_type must be nil or an identifier"

      not (is_nil(source_window) or is_map(source_window)) ->
        raise ArgumentError, "source_window must be nil or a map"

      not (is_nil(cadence_import) or is_map(cadence_import)) ->
        raise ArgumentError, "cadence_import must be nil or a map"

      not (is_nil(execution_uncertainty) or is_map(execution_uncertainty)) ->
        raise ArgumentError, "execution_uncertainty must be nil or a map"

      not is_map(provenance) ->
        raise ArgumentError, "provenance must be a map"

      true ->
        %{
          status: status,
          approval_status: approval_status,
          locked?: locked?,
          timeline_id: timeline_id,
          scenario_id: scenario_id,
          spacecraft_id: spacecraft_id,
          resource_id: resource_id,
          resource_source_quality: resource_source_quality,
          resource_trust_boundary: resource_trust_boundary,
          resource_trust_boundary_status: resource_trust_boundary_status,
          resource_provenance: resource_provenance,
          resource_blocking_dimension: resource_blocking_dimension,
          station_availability: station_availability,
          station_calendar_entry_id: station_calendar_entry_id,
          station_calendar_provider_id: station_calendar_provider_id,
          station_calendar_provider_entry_id: station_calendar_provider_entry_id,
          station_calendar_directions: station_calendar_directions,
          station_calendar_status: station_calendar_status,
          station_calendar_trust_boundary_status: station_calendar_trust_boundary_status,
          source_station_calendar_entry: source_station_calendar_entry,
          source_station_calendar_overlaps: source_station_calendar_overlaps,
          station_calendar_overlap_count: station_calendar_overlap_count,
          station_calendar_overlap_entry_ids: station_calendar_overlap_entry_ids,
          station_calendar_overlap_availabilities: station_calendar_overlap_availabilities,
          station_calendar_entry_ambiguous: station_calendar_entry_ambiguous,
          station_calendar_ambiguous_entry_count: station_calendar_ambiguous_entry_count,
          station_calendar_ambiguous_entry_ids: station_calendar_ambiguous_entry_ids,
          station_contention_status: station_contention_status,
          station_calendar_reservation_overlap_count: station_calendar_reservation_overlap_count,
          station_calendar_reservation_expires_at_s: station_calendar_reservation_expires_at_s,
          station_calendar_reservation_ids: station_calendar_reservation_ids,
          station_calendar_reserved_by: station_calendar_reserved_by,
          station_calendar_reservation_statuses: station_calendar_reservation_statuses,
          station_reservation_id: station_reservation_id,
          station_reservation_expires_at_s: station_reservation_expires_at_s,
          station_reserved_by: station_reserved_by,
          station_reservation_status: station_reservation_status,
          station_reservation_match_status: station_reservation_match_status,
          capacity_fraction: capacity_fraction,
          station_capacity_fraction: station_capacity_fraction,
          capacity_pack_capacity_fraction: capacity_pack_capacity_fraction,
          fuel_margin: fuel_margin,
          power_margin: power_margin,
          storage_margin: storage_margin,
          downlink_margin: downlink_margin,
          battery_capacity_wh: battery_capacity_wh,
          battery_energy_used_wh: battery_energy_used_wh,
          battery_energy_generated_wh: battery_energy_generated_wh,
          battery_state_of_charge: battery_state_of_charge,
          spacecraft_available: spacecraft_available,
          payload_available: payload_available,
          antenna_available: antenna_available,
          degraded: degraded,
          mode: mode,
          incompatible_activity_types: incompatible_activity_types,
          suppressed_activity_types: suppressed_activity_types,
          collection_id: collection_id,
          product_id: product_id,
          product_ids: product_ids,
          payload_id: payload_id,
          instrument_id: instrument_id,
          target_priority: target_priority,
          target_priority_source: target_priority_source,
          target_priority_objective_ids: target_priority_objective_ids,
          target_priority_objective_type: target_priority_objective_type,
          observation_objective_count: observation_objective_count,
          observation_objective_ids: observation_objective_ids,
          observation_objective_source: observation_objective_source,
          observation_objective_types: observation_objective_types,
          contact_success: contact_success,
          contact_result: contact_result,
          contact_success_factor: contact_success_factor,
          contact_success_factor_source: contact_success_factor_source,
          command_success: command_success,
          command_result: command_result,
          command_success_factor: command_success_factor,
          command_success_factor_source: command_success_factor_source,
          observation_success: observation_success,
          observation_result: observation_result,
          observation_success_factor: observation_success_factor,
          observation_success_factor_source: observation_success_factor_source,
          image_quality_score: image_quality_score,
          image_quality_status: image_quality_status,
          image_quality_source: image_quality_source,
          cloud_cover_fraction: cloud_cover_fraction,
          blur_score: blur_score,
          maneuver_success: maneuver_success,
          maneuver_result: maneuver_result,
          maneuver_success_factor: maneuver_success_factor,
          maneuver_success_factor_source: maneuver_success_factor_source,
          feedback_weight: feedback_weight,
          feedback_weight_source: feedback_weight_source,
          data_volume_mb: data_volume_mb,
          planned_data_volume_mb: planned_data_volume_mb,
          planned_volume_mb: planned_volume_mb,
          actual_data_volume_mb: actual_data_volume_mb,
          actual_volume_mb: actual_volume_mb,
          estimated_data_volume_mb: estimated_data_volume_mb,
          estimated_storage_mb: estimated_storage_mb,
          estimated_downlink_mb: estimated_downlink_mb,
          required_downlink_mb: required_downlink_mb,
          required_volume_mb: required_volume_mb,
          required_data_volume_mb: required_data_volume_mb,
          target_downlink_mb: target_downlink_mb,
          target_volume_mb: target_volume_mb,
          target_data_volume_mb: target_data_volume_mb,
          min_downlink_mb: min_downlink_mb,
          selected_downlink_mb: selected_downlink_mb,
          selected_data_volume_mb: selected_data_volume_mb,
          selected_volume_mb: selected_volume_mb,
          delivered_data_volume_mb: delivered_data_volume_mb,
          received_data_volume_mb: received_data_volume_mb,
          selected_downlink_shortfall_mb: selected_downlink_shortfall_mb,
          selected_data_volume_shortfall_mb: selected_data_volume_shortfall_mb,
          data_volume_shortfall_mb: data_volume_shortfall_mb,
          actual_data_volume_shortfall_mb: actual_data_volume_shortfall_mb,
          missing_data_volume_mb: missing_data_volume_mb,
          required_data_volume_gap_mb: required_data_volume_gap_mb,
          downlink_requirement_status: downlink_requirement_status,
          downlink_completion_source: downlink_completion_source,
          downlink_completion_sources: downlink_completion_sources,
          collection_ends_at_s: collection_ends_at_s,
          planned_delivery_at_s: planned_delivery_at_s,
          actual_delivery_at_s: actual_delivery_at_s,
          max_latency_s: max_latency_s,
          planned_latency_s: planned_latency_s,
          actual_latency_s: actual_latency_s,
          collection_latency_objective_count: collection_latency_objective_count,
          collection_latency_objective_ids: collection_latency_objective_ids,
          collection_latency_objective_source: collection_latency_objective_source,
          collection_latency_objective_types: collection_latency_objective_types,
          planned_estimated_throughput_mb: planned_estimated_throughput_mb,
          actual_throughput_mb: actual_throughput_mb,
          link_protocol: link_protocol,
          frequency_band: frequency_band,
          modulation: modulation,
          coding_scheme: coding_scheme,
          polarization: polarization,
          data_rate_mbps: data_rate_mbps,
          downlink_rate_mbps: downlink_rate_mbps,
          data_rate_mb_s: data_rate_mb_s,
          downlink_rate_mb_s: downlink_rate_mb_s,
          actual_data_rate_mbps: actual_data_rate_mbps,
          actual_downlink_rate_mbps: actual_downlink_rate_mbps,
          actual_data_rate_mb_s: actual_data_rate_mb_s,
          actual_downlink_rate_mb_s: actual_downlink_rate_mb_s,
          delivered_rate_mbps: delivered_rate_mbps,
          received_rate_mbps: received_rate_mbps,
          delivered_rate_mb_s: delivered_rate_mb_s,
          received_rate_mb_s: received_rate_mb_s,
          actual_duration_s: actual_duration_s,
          actual_contact_duration_s: actual_contact_duration_s,
          contact_duration_s: contact_duration_s,
          link_margin_db: link_margin_db,
          snr_db: snr_db,
          eb_no_db: eb_no_db,
          bit_error_rate: bit_error_rate,
          packet_loss_rate: packet_loss_rate,
          frame_loss_rate: frame_loss_rate,
          carrier_lock: carrier_lock,
          symbol_lock: symbol_lock,
          link_quality_status: link_quality_status,
          pointing_mode: pointing_mode,
          pointing_target_id: pointing_target_id,
          boresight_axis: boresight_axis,
          off_nadir_angle_deg: off_nadir_angle_deg,
          slew_angle_deg: slew_angle_deg,
          slew_rate_deg_s: slew_rate_deg_s,
          pointing_error_deg: pointing_error_deg,
          pointing_status: pointing_status,
          pointing_model: pointing_model,
          pointing_source: pointing_source,
          pointing_confidence: pointing_confidence,
          attitude_mode: attitude_mode,
          attitude_target_id: attitude_target_id,
          roll_deg: roll_deg,
          pitch_deg: pitch_deg,
          yaw_deg: yaw_deg,
          attitude_error_deg: attitude_error_deg,
          attitude_status: attitude_status,
          attitude_model: attitude_model,
          attitude_source: attitude_source,
          attitude_confidence: attitude_confidence,
          thermal_zone_id: thermal_zone_id,
          temperature_c: temperature_c,
          planned_temperature_c: planned_temperature_c,
          actual_temperature_c: actual_temperature_c,
          min_operating_temperature_c: min_operating_temperature_c,
          max_operating_temperature_c: max_operating_temperature_c,
          thermal_margin_c: thermal_margin_c,
          thermal_status: thermal_status,
          thermal_model: thermal_model,
          thermal_source: thermal_source,
          thermal_confidence: thermal_confidence,
          eclipse_overlap_fraction: eclipse_overlap_fraction,
          eclipse_overlap_s: eclipse_overlap_s,
          lighting_condition: lighting_condition,
          lighting_condition_detail: lighting_condition_detail,
          lighting_condition_model: lighting_condition_model,
          lighting_detail_model: lighting_detail_model,
          lighting_confidence: lighting_confidence,
          command_window_id: command_window_id,
          command_window_type: command_window_type,
          command_window: command_window,
          dependencies: dependencies,
          dependency_activity_ids: dependency_activity_ids,
          dependency_timeline_ids: dependency_timeline_ids,
          exclusive_with_activity_ids: exclusive_with_activity_ids,
          exclusive_with_timeline_ids: exclusive_with_timeline_ids,
          exclusivity_group: exclusivity_group,
          source_window_id: source_window_id,
          source_window_type: source_window_type,
          source_window: source_window,
          cadence_import: cadence_import,
          execution_uncertainty: execution_uncertainty,
          provenance: provenance
        }
    end
  end

  defp common_opts_from_map!(source) do
    []
    |> maybe_put_opt(
      :status,
      optional_activity_status_atom!(field(source, :status))
    )
    |> maybe_put_opt(
      :approval_status,
      optional_approval_status_atom!(field(source, :approval_status))
    )
    |> maybe_put_opt(
      :locked?,
      optional_boolean!(first_present_field(source, [:locked, :locked?]))
    )
    |> maybe_put_opt(
      :timeline_id,
      optional_identifier!(first_present_field(source, [:timeline_id, :persistent_id]))
    )
    |> maybe_put_opt(:scenario_id, optional_identifier!(field(source, :scenario_id)))
    |> maybe_put_opt(:spacecraft_id, optional_identifier!(spacecraft_id_field(source)))
    |> maybe_put_opt(:resource_id, optional_identifier!(field(source, :resource_id)))
    |> maybe_put_opt(
      :resource_source_quality,
      optional_scalar!(first_present_field(source, [:resource_source_quality, :source_quality]))
    )
    |> maybe_put_opt(
      :resource_trust_boundary,
      optional_scalar!(first_present_field(source, [:resource_trust_boundary, :trust_boundary]))
    )
    |> maybe_put_opt(
      :resource_trust_boundary_status,
      optional_scalar!(
        first_present_field(source, [
          :resource_trust_boundary_status,
          :trust_boundary_status
        ])
      )
    )
    |> maybe_put_opt(:resource_provenance, optional_map!(field(source, :resource_provenance)))
    |> maybe_put_opt(
      :resource_blocking_dimension,
      optional_scalar!(field(source, :resource_blocking_dimension))
    )
    |> maybe_put_opt(
      :station_availability,
      optional_scalar!(field(source, :station_availability), "station_availability")
    )
    |> maybe_put_opt(
      :station_calendar_entry_id,
      optional_stable_identifier!(
        field(source, :station_calendar_entry_id),
        "station_calendar_entry_id"
      )
    )
    |> maybe_put_opt(
      :station_calendar_provider_id,
      optional_stable_identifier!(
        field(source, :station_calendar_provider_id),
        "station_calendar_provider_id"
      )
    )
    |> maybe_put_opt(
      :station_calendar_provider_entry_id,
      optional_stable_identifier!(
        field(source, :station_calendar_provider_entry_id),
        "station_calendar_provider_entry_id"
      )
    )
    |> maybe_put_opt(
      :station_calendar_directions,
      optional_scalar_list!(
        field(source, :station_calendar_directions),
        "station_calendar_directions",
        "direction labels"
      )
    )
    |> maybe_put_opt(
      :station_calendar_status,
      optional_scalar!(field(source, :station_calendar_status), "station_calendar_status")
    )
    |> maybe_put_opt(
      :station_calendar_trust_boundary_status,
      optional_scalar!(
        field(source, :station_calendar_trust_boundary_status),
        "station_calendar_trust_boundary_status"
      )
    )
    |> maybe_put_opt(
      :source_station_calendar_entry,
      optional_map!(
        field(source, :source_station_calendar_entry),
        "source_station_calendar_entry"
      )
    )
    |> maybe_put_opt(
      :source_station_calendar_overlaps,
      optional_map_list!(
        field(source, :source_station_calendar_overlaps),
        "source_station_calendar_overlaps",
        "source station-calendar overlap maps"
      )
    )
    |> maybe_put_opt(
      :station_calendar_overlap_count,
      optional_non_negative_integer!(
        field(source, :station_calendar_overlap_count),
        "station_calendar_overlap_count"
      )
    )
    |> maybe_put_opt(
      :station_calendar_overlap_entry_ids,
      optional_id_list!(
        field(source, :station_calendar_overlap_entry_ids),
        "station_calendar_overlap_entry_ids",
        "station-calendar entry ids"
      )
    )
    |> maybe_put_opt(
      :station_calendar_overlap_availabilities,
      optional_scalar_list!(
        field(source, :station_calendar_overlap_availabilities),
        "station_calendar_overlap_availabilities",
        "station-calendar availability labels"
      )
    )
    |> maybe_put_opt(
      :station_calendar_entry_ambiguous,
      optional_boolean!(
        field(source, :station_calendar_entry_ambiguous),
        "station_calendar_entry_ambiguous"
      )
    )
    |> maybe_put_opt(
      :station_calendar_ambiguous_entry_count,
      optional_non_negative_integer!(
        field(source, :station_calendar_ambiguous_entry_count),
        "station_calendar_ambiguous_entry_count"
      )
    )
    |> maybe_put_opt(
      :station_calendar_ambiguous_entry_ids,
      optional_id_list!(
        field(source, :station_calendar_ambiguous_entry_ids),
        "station_calendar_ambiguous_entry_ids",
        "station-calendar entry ids"
      )
    )
    |> maybe_put_opt(
      :station_contention_status,
      optional_scalar!(field(source, :station_contention_status), "station_contention_status")
    )
    |> maybe_put_opt(
      :station_calendar_reservation_overlap_count,
      optional_non_negative_integer!(
        field(source, :station_calendar_reservation_overlap_count),
        "station_calendar_reservation_overlap_count"
      )
    )
    |> maybe_put_opt(
      :station_calendar_reservation_expires_at_s,
      optional_non_negative_number_list!(
        field(source, :station_calendar_reservation_expires_at_s),
        "station_calendar_reservation_expires_at_s"
      )
    )
    |> maybe_put_opt(
      :station_calendar_reservation_ids,
      optional_id_list!(
        field(source, :station_calendar_reservation_ids),
        "station_calendar_reservation_ids",
        "station reservation ids"
      )
    )
    |> maybe_put_opt(
      :station_calendar_reserved_by,
      optional_scalar_list!(
        field(source, :station_calendar_reserved_by),
        "station_calendar_reserved_by",
        "reservation owner labels"
      )
    )
    |> maybe_put_opt(
      :station_calendar_reservation_statuses,
      optional_scalar_list!(
        field(source, :station_calendar_reservation_statuses),
        "station_calendar_reservation_statuses",
        "reservation status labels"
      )
    )
    |> maybe_put_opt(
      :station_reservation_id,
      optional_stable_identifier!(
        field(source, :station_reservation_id),
        "station_reservation_id"
      )
    )
    |> maybe_put_opt(
      :station_reservation_expires_at_s,
      optional_non_negative_number!(
        field(source, :station_reservation_expires_at_s),
        "station_reservation_expires_at_s"
      )
    )
    |> maybe_put_opt(
      :station_reserved_by,
      optional_scalar!(field(source, :station_reserved_by), "station_reserved_by")
    )
    |> maybe_put_opt(
      :station_reservation_status,
      optional_scalar!(field(source, :station_reservation_status), "station_reservation_status")
    )
    |> maybe_put_opt(
      :station_reservation_match_status,
      optional_scalar!(
        field(source, :station_reservation_match_status),
        "station_reservation_match_status"
      )
    )
    |> maybe_put_opt(
      :capacity_fraction,
      optional_unit_interval!(field(source, :capacity_fraction), "capacity_fraction")
    )
    |> maybe_put_opt(
      :station_capacity_fraction,
      optional_unit_interval!(
        field(source, :station_capacity_fraction),
        "station_capacity_fraction"
      )
    )
    |> maybe_put_opt(
      :capacity_pack_capacity_fraction,
      optional_unit_interval!(
        field(source, :capacity_pack_capacity_fraction),
        "capacity_pack_capacity_fraction"
      )
    )
    |> maybe_put_opt(
      :fuel_margin,
      optional_unit_interval!(field(source, :fuel_margin), "fuel_margin")
    )
    |> maybe_put_opt(
      :power_margin,
      optional_unit_interval!(field(source, :power_margin), "power_margin")
    )
    |> maybe_put_opt(
      :storage_margin,
      optional_unit_interval!(
        first_present_field(source, Map.fetch!(@unit_interval_field_aliases, :storage_margin)),
        "storage_margin"
      )
    )
    |> maybe_put_opt(
      :downlink_margin,
      optional_unit_interval!(
        first_present_field(source, Map.fetch!(@unit_interval_field_aliases, :downlink_margin)),
        "downlink_margin"
      )
    )
    |> maybe_put_opt(
      :battery_capacity_wh,
      optional_number!(field(source, :battery_capacity_wh))
    )
    |> maybe_put_opt(
      :battery_energy_used_wh,
      optional_number!(field(source, :battery_energy_used_wh))
    )
    |> maybe_put_opt(
      :battery_energy_generated_wh,
      optional_non_negative_number!(
        first_present_field(source, @battery_energy_generated_wh_aliases),
        "battery_energy_generated_wh"
      )
    )
    |> maybe_put_opt(
      :battery_state_of_charge,
      optional_unit_interval!(
        first_present_field(
          source,
          Map.fetch!(@unit_interval_field_aliases, :battery_state_of_charge)
        ),
        "battery_state_of_charge"
      )
    )
    |> maybe_put_opt(
      :spacecraft_available,
      optional_boolean!(
        first_present_field(source, [:spacecraft_available, :spacecraft_available?])
      )
    )
    |> maybe_put_opt(
      :payload_available,
      optional_boolean!(first_present_field(source, [:payload_available, :payload_available?]))
    )
    |> maybe_put_opt(
      :antenna_available,
      optional_boolean!(first_present_field(source, [:antenna_available, :antenna_available?]))
    )
    |> maybe_put_opt(
      :degraded,
      optional_boolean!(first_present_field(source, [:degraded, :degraded?]))
    )
    |> maybe_put_opt(:mode, optional_scalar!(field(source, :mode)))
    |> maybe_put_opt(
      :incompatible_activity_types,
      optional_id_list!(
        field(source, :incompatible_activity_types),
        "incompatible_activity_types",
        "activity types"
      )
    )
    |> maybe_put_opt(
      :suppressed_activity_types,
      optional_id_list!(
        field(source, :suppressed_activity_types),
        "suppressed_activity_types",
        "activity types"
      )
    )
    |> maybe_put_opt(
      :collection_id,
      optional_identifier!(first_present_field(source, [:collection_id, :collection]))
    )
    |> maybe_put_opt(
      :product_id,
      optional_identifier!(first_present_field(source, [:product_id, :data_product_id]))
    )
    |> maybe_put_opt(
      :product_ids,
      optional_id_list!(
        first_present_field(source, [:product_ids, :data_product_ids]),
        "product_ids",
        "product ids"
      )
    )
    |> maybe_put_opt(
      :payload_id,
      optional_identifier!(first_present_field(source, [:payload_id, :payload]))
    )
    |> maybe_put_opt(
      :instrument_id,
      optional_identifier!(first_present_field(source, [:instrument_id, :instrument]))
    )
    |> maybe_put_opt(
      :target_priority,
      optional_number!(first_present_field(source, [:target_priority, :priority]))
    )
    |> maybe_put_opt(
      :target_priority_source,
      optional_scalar!(field(source, :target_priority_source))
    )
    |> maybe_put_opt(
      :target_priority_objective_ids,
      optional_id_list!(
        field(source, :target_priority_objective_ids),
        "target_priority_objective_ids",
        "objective ids"
      )
    )
    |> maybe_put_opt(
      :target_priority_objective_type,
      optional_scalar!(field(source, :target_priority_objective_type))
    )
    |> maybe_put_opt(
      :observation_objective_count,
      optional_non_negative_integer!(
        field(source, :observation_objective_count),
        "observation_objective_count"
      )
    )
    |> maybe_put_opt(
      :observation_objective_ids,
      optional_id_list!(
        field(source, :observation_objective_ids),
        "observation_objective_ids",
        "objective ids"
      )
    )
    |> maybe_put_opt(
      :observation_objective_source,
      optional_scalar!(field(source, :observation_objective_source))
    )
    |> maybe_put_opt(
      :observation_objective_types,
      optional_scalar_list!(
        field(source, :observation_objective_types),
        "observation_objective_types",
        "objective types"
      )
    )
    |> maybe_put_opt(:contact_success, optional_boolean!(field(source, :contact_success)))
    |> maybe_put_opt(:contact_result, optional_scalar!(field(source, :contact_result)))
    |> maybe_put_opt(
      :contact_success_factor,
      optional_number!(field(source, :contact_success_factor))
    )
    |> maybe_put_opt(
      :contact_success_factor_source,
      optional_scalar!(field(source, :contact_success_factor_source))
    )
    |> maybe_put_opt(:command_success, optional_boolean!(field(source, :command_success)))
    |> maybe_put_opt(:command_result, optional_scalar!(field(source, :command_result)))
    |> maybe_put_opt(
      :command_success_factor,
      optional_number!(field(source, :command_success_factor))
    )
    |> maybe_put_opt(
      :command_success_factor_source,
      optional_scalar!(field(source, :command_success_factor_source))
    )
    |> maybe_put_opt(
      :observation_success,
      optional_boolean!(field(source, :observation_success))
    )
    |> maybe_put_opt(:observation_result, optional_scalar!(field(source, :observation_result)))
    |> maybe_put_opt(
      :observation_success_factor,
      optional_number!(field(source, :observation_success_factor))
    )
    |> maybe_put_opt(
      :observation_success_factor_source,
      optional_scalar!(field(source, :observation_success_factor_source))
    )
    |> maybe_put_opt(
      :image_quality_score,
      optional_number!(
        first_present_field(source, [:image_quality_score, :product_quality_score, :quality_score])
      )
    )
    |> maybe_put_opt(
      :image_quality_status,
      optional_scalar!(
        first_present_field(source, [
          :image_quality_status,
          :product_quality_status,
          :quality_status
        ])
      )
    )
    |> maybe_put_opt(
      :image_quality_source,
      optional_scalar!(
        first_present_field(source, [
          :image_quality_source,
          :product_quality_source,
          :quality_source
        ])
      )
    )
    |> maybe_put_opt(
      :cloud_cover_fraction,
      optional_number!(
        first_present_field(source, [:cloud_cover_fraction, :cloud_fraction, :cloud_cover])
      )
    )
    |> maybe_put_opt(
      :blur_score,
      optional_number!(
        first_present_field(source, [:blur_score, :image_blur_score, :sharpness_loss_fraction])
      )
    )
    |> maybe_put_opt(:maneuver_success, optional_boolean!(field(source, :maneuver_success)))
    |> maybe_put_opt(:maneuver_result, optional_scalar!(field(source, :maneuver_result)))
    |> maybe_put_opt(
      :maneuver_success_factor,
      optional_number!(field(source, :maneuver_success_factor))
    )
    |> maybe_put_opt(
      :maneuver_success_factor_source,
      optional_scalar!(field(source, :maneuver_success_factor_source))
    )
    |> maybe_put_opt(:feedback_weight, optional_number!(field(source, :feedback_weight)))
    |> maybe_put_opt(
      :feedback_weight_source,
      optional_scalar!(field(source, :feedback_weight_source))
    )
    |> maybe_put_opt(:data_volume_mb, optional_number!(field(source, :data_volume_mb)))
    |> maybe_put_opt(
      :planned_data_volume_mb,
      optional_number!(first_present_field(source, [:planned_data_volume_mb, :planned_volume_mb]))
    )
    |> maybe_put_opt(
      :planned_volume_mb,
      optional_number!(field(source, :planned_volume_mb))
    )
    |> maybe_put_opt(
      :actual_data_volume_mb,
      optional_number!(
        first_present_field(source, [
          :actual_data_volume_mb,
          :actual_volume_mb,
          :actual_storage_mb,
          :actual_downlink_mb,
          :delivered_data_volume_mb,
          :received_data_volume_mb,
          :delivered_data_mb,
          :received_data_mb
        ])
      )
    )
    |> maybe_put_opt(:actual_volume_mb, optional_number!(field(source, :actual_volume_mb)))
    |> maybe_put_opt(
      :estimated_data_volume_mb,
      optional_number!(field(source, :estimated_data_volume_mb))
    )
    |> maybe_put_opt(
      :estimated_storage_mb,
      optional_number!(field(source, :estimated_storage_mb))
    )
    |> maybe_put_opt(
      :estimated_downlink_mb,
      optional_number!(field(source, :estimated_downlink_mb))
    )
    |> maybe_put_opt(
      :required_downlink_mb,
      optional_number!(
        first_present_field(source, [
          :required_downlink_mb,
          :target_downlink_mb,
          :downlink_requirement_mb,
          :required_volume_mb,
          :required_data_volume_mb,
          :target_volume_mb,
          :target_data_volume_mb,
          :min_downlink_mb
        ])
      )
    )
    |> maybe_put_opt(:required_volume_mb, optional_number!(field(source, :required_volume_mb)))
    |> maybe_put_opt(
      :required_data_volume_mb,
      optional_number!(field(source, :required_data_volume_mb))
    )
    |> maybe_put_opt(
      :target_downlink_mb,
      optional_number!(field(source, :target_downlink_mb))
    )
    |> maybe_put_opt(:target_volume_mb, optional_number!(field(source, :target_volume_mb)))
    |> maybe_put_opt(
      :target_data_volume_mb,
      optional_number!(field(source, :target_data_volume_mb))
    )
    |> maybe_put_opt(:min_downlink_mb, optional_number!(field(source, :min_downlink_mb)))
    |> maybe_put_opt(
      :selected_downlink_mb,
      optional_number!(field(source, :selected_downlink_mb))
    )
    |> maybe_put_opt(
      :selected_data_volume_mb,
      optional_number!(field(source, :selected_data_volume_mb))
    )
    |> maybe_put_opt(:selected_volume_mb, optional_number!(field(source, :selected_volume_mb)))
    |> maybe_put_opt(
      :delivered_data_volume_mb,
      optional_number!(field(source, :delivered_data_volume_mb))
    )
    |> maybe_put_opt(
      :received_data_volume_mb,
      optional_number!(field(source, :received_data_volume_mb))
    )
    |> maybe_put_opt(
      :selected_downlink_shortfall_mb,
      optional_number!(field(source, :selected_downlink_shortfall_mb))
    )
    |> maybe_put_opt(
      :selected_data_volume_shortfall_mb,
      optional_number!(field(source, :selected_data_volume_shortfall_mb))
    )
    |> maybe_put_opt(
      :data_volume_shortfall_mb,
      optional_number!(field(source, :data_volume_shortfall_mb))
    )
    |> maybe_put_opt(
      :actual_data_volume_shortfall_mb,
      optional_number!(field(source, :actual_data_volume_shortfall_mb))
    )
    |> maybe_put_opt(
      :missing_data_volume_mb,
      optional_number!(field(source, :missing_data_volume_mb))
    )
    |> maybe_put_opt(
      :required_data_volume_gap_mb,
      optional_number!(field(source, :required_data_volume_gap_mb))
    )
    |> maybe_put_opt(
      :downlink_requirement_status,
      optional_scalar!(field(source, :downlink_requirement_status))
    )
    |> maybe_put_opt(
      :downlink_completion_source,
      optional_scalar!(field(source, :downlink_completion_source))
    )
    |> maybe_put_opt(
      :downlink_completion_sources,
      optional_id_list!(
        field(source, :downlink_completion_sources),
        "downlink_completion_sources",
        "source ids"
      )
    )
    |> maybe_put_opt(
      :collection_ends_at_s,
      optional_number!(
        first_present_field(source, [
          :collection_ends_at_s,
          :collection_end_s,
          :observation_ends_at_s,
          :observed_ends_at_s
        ])
      )
    )
    |> maybe_put_opt(
      :planned_delivery_at_s,
      optional_number!(
        first_present_field(source, [
          :planned_delivery_at_s,
          :planned_delivered_at_s,
          :planned_downlink_at_s,
          :delivery_due_at_s
        ])
      )
    )
    |> maybe_put_opt(
      :actual_delivery_at_s,
      optional_number!(
        first_present_field(source, [
          :actual_delivery_at_s,
          :actual_delivered_at_s,
          :delivered_at_s,
          :received_at_s,
          :actual_downlink_at_s
        ])
      )
    )
    |> maybe_put_opt(
      :max_latency_s,
      optional_number!(
        first_present_field(source, [:max_latency_s, :required_latency_s, :target_latency_s])
      )
    )
    |> maybe_put_opt(:planned_latency_s, optional_number!(field(source, :planned_latency_s)))
    |> maybe_put_opt(:actual_latency_s, optional_number!(field(source, :actual_latency_s)))
    |> maybe_put_opt(
      :collection_latency_objective_count,
      optional_non_negative_integer!(
        field(source, :collection_latency_objective_count),
        "collection_latency_objective_count"
      )
    )
    |> maybe_put_opt(
      :collection_latency_objective_ids,
      optional_id_list!(
        field(source, :collection_latency_objective_ids),
        "collection_latency_objective_ids",
        "objective ids"
      )
    )
    |> maybe_put_opt(
      :collection_latency_objective_source,
      optional_scalar!(field(source, :collection_latency_objective_source))
    )
    |> maybe_put_opt(
      :collection_latency_objective_types,
      optional_scalar_list!(
        field(source, :collection_latency_objective_types),
        "collection_latency_objective_types",
        "objective types"
      )
    )
    |> maybe_put_opt(
      :planned_estimated_throughput_mb,
      optional_number!(
        first_present_field(source, [
          :planned_estimated_throughput_mb,
          :estimated_throughput_mb
        ])
      )
    )
    |> maybe_put_opt(
      :actual_throughput_mb,
      optional_number!(
        first_present_field(source, [
          :actual_throughput_mb,
          :actual_downlink_mb,
          :delivered_throughput_mb,
          :received_throughput_mb
        ])
      )
    )
    |> maybe_put_opt(:link_protocol, optional_scalar!(field(source, :link_protocol)))
    |> maybe_put_opt(
      :frequency_band,
      optional_scalar!(first_present_field(source, [:frequency_band, :rf_band]))
    )
    |> maybe_put_opt(:modulation, optional_scalar!(field(source, :modulation)))
    |> maybe_put_opt(:coding_scheme, optional_scalar!(field(source, :coding_scheme)))
    |> maybe_put_opt(:polarization, optional_scalar!(field(source, :polarization)))
    |> maybe_put_opt(:data_rate_mbps, optional_number!(field(source, :data_rate_mbps)))
    |> maybe_put_opt(:downlink_rate_mbps, optional_number!(field(source, :downlink_rate_mbps)))
    |> maybe_put_opt(:data_rate_mb_s, optional_number!(field(source, :data_rate_mb_s)))
    |> maybe_put_opt(:downlink_rate_mb_s, optional_number!(field(source, :downlink_rate_mb_s)))
    |> maybe_put_opt(
      :actual_data_rate_mbps,
      optional_number!(field(source, :actual_data_rate_mbps))
    )
    |> maybe_put_opt(
      :actual_downlink_rate_mbps,
      optional_number!(field(source, :actual_downlink_rate_mbps))
    )
    |> maybe_put_opt(
      :actual_data_rate_mb_s,
      optional_number!(field(source, :actual_data_rate_mb_s))
    )
    |> maybe_put_opt(
      :actual_downlink_rate_mb_s,
      optional_number!(field(source, :actual_downlink_rate_mb_s))
    )
    |> maybe_put_opt(:delivered_rate_mbps, optional_number!(field(source, :delivered_rate_mbps)))
    |> maybe_put_opt(:received_rate_mbps, optional_number!(field(source, :received_rate_mbps)))
    |> maybe_put_opt(:delivered_rate_mb_s, optional_number!(field(source, :delivered_rate_mb_s)))
    |> maybe_put_opt(:received_rate_mb_s, optional_number!(field(source, :received_rate_mb_s)))
    |> maybe_put_opt(:actual_duration_s, optional_number!(field(source, :actual_duration_s)))
    |> maybe_put_opt(
      :actual_contact_duration_s,
      optional_number!(field(source, :actual_contact_duration_s))
    )
    |> maybe_put_opt(:contact_duration_s, optional_number!(field(source, :contact_duration_s)))
    |> maybe_put_opt(
      :link_margin_db,
      optional_number!(first_present_field(source, [:link_margin_db, :link_margin_d_b]))
    )
    |> maybe_put_opt(:snr_db, optional_number!(field(source, :snr_db)))
    |> maybe_put_opt(
      :eb_no_db,
      optional_number!(first_present_field(source, [:eb_no_db, :ebn0_db, :eb_no_d_b]))
    )
    |> maybe_put_opt(
      :bit_error_rate,
      optional_number!(first_present_field(source, [:bit_error_rate, :ber]))
    )
    |> maybe_put_opt(:packet_loss_rate, optional_number!(field(source, :packet_loss_rate)))
    |> maybe_put_opt(:frame_loss_rate, optional_number!(field(source, :frame_loss_rate)))
    |> maybe_put_opt(
      :carrier_lock,
      optional_boolean!(first_present_field(source, [:carrier_lock, :carrier_locked]))
    )
    |> maybe_put_opt(
      :symbol_lock,
      optional_boolean!(first_present_field(source, [:symbol_lock, :symbol_locked]))
    )
    |> maybe_put_opt(
      :link_quality_status,
      optional_scalar!(first_present_field(source, [:link_quality_status, :rf_status]))
    )
    |> maybe_put_opt(
      :pointing_mode,
      optional_scalar!(first_present_field(source, [:pointing_mode, :attitude_mode]))
    )
    |> maybe_put_opt(
      :pointing_target_id,
      optional_identifier!(
        first_present_field(source, [:pointing_target_id, :attitude_target_id])
      )
    )
    |> maybe_put_opt(
      :boresight_axis,
      optional_scalar!(first_present_field(source, [:boresight_axis, :sensor_axis]))
    )
    |> maybe_put_opt(
      :off_nadir_angle_deg,
      optional_number!(first_present_field(source, [:off_nadir_angle_deg, :look_angle_deg]))
    )
    |> maybe_put_opt(:slew_angle_deg, optional_number!(field(source, :slew_angle_deg)))
    |> maybe_put_opt(:slew_rate_deg_s, optional_number!(field(source, :slew_rate_deg_s)))
    |> maybe_put_opt(
      :pointing_error_deg,
      optional_number!(first_present_field(source, [:pointing_error_deg, :attitude_error_deg]))
    )
    |> maybe_put_opt(
      :pointing_status,
      optional_scalar!(first_present_field(source, [:pointing_status, :attitude_status]))
    )
    |> maybe_put_opt(
      :pointing_model,
      optional_scalar!(first_present_field(source, [:pointing_model, :attitude_model]))
    )
    |> maybe_put_opt(
      :pointing_source,
      optional_scalar!(first_present_field(source, [:pointing_source, :attitude_source]))
    )
    |> maybe_put_opt(
      :pointing_confidence,
      optional_number!(first_present_field(source, [:pointing_confidence, :attitude_confidence]))
    )
    |> maybe_put_opt(:attitude_mode, optional_scalar!(field(source, :attitude_mode)))
    |> maybe_put_opt(
      :attitude_target_id,
      optional_identifier!(field(source, :attitude_target_id))
    )
    |> maybe_put_opt(:roll_deg, optional_number!(field(source, :roll_deg)))
    |> maybe_put_opt(:pitch_deg, optional_number!(field(source, :pitch_deg)))
    |> maybe_put_opt(:yaw_deg, optional_number!(field(source, :yaw_deg)))
    |> maybe_put_opt(:attitude_error_deg, optional_number!(field(source, :attitude_error_deg)))
    |> maybe_put_opt(:attitude_status, optional_scalar!(field(source, :attitude_status)))
    |> maybe_put_opt(:attitude_model, optional_scalar!(field(source, :attitude_model)))
    |> maybe_put_opt(:attitude_source, optional_scalar!(field(source, :attitude_source)))
    |> maybe_put_opt(:attitude_confidence, optional_number!(field(source, :attitude_confidence)))
    |> maybe_put_opt(
      :thermal_zone_id,
      optional_identifier!(
        first_present_field(source, [:thermal_zone_id, :thermal_component_id, :thermal_node_id])
      )
    )
    |> maybe_put_opt(
      :temperature_c,
      optional_number!(first_present_field(source, [:temperature_c, :temp_c]))
    )
    |> maybe_put_opt(
      :planned_temperature_c,
      optional_number!(
        first_present_field(source, [
          :planned_temperature_c,
          :planned_temp_c,
          :predicted_temperature_c,
          :estimated_temperature_c
        ])
      )
    )
    |> maybe_put_opt(
      :actual_temperature_c,
      optional_number!(
        first_present_field(source, [
          :actual_temperature_c,
          :actual_temp_c,
          :measured_temperature_c,
          :measured_temp_c
        ])
      )
    )
    |> maybe_put_opt(
      :min_operating_temperature_c,
      optional_number!(
        first_present_field(source, [
          :min_operating_temperature_c,
          :minimum_operating_temperature_c,
          :min_temperature_c
        ])
      )
    )
    |> maybe_put_opt(
      :max_operating_temperature_c,
      optional_number!(
        first_present_field(source, [
          :max_operating_temperature_c,
          :maximum_operating_temperature_c,
          :max_temperature_c
        ])
      )
    )
    |> maybe_put_opt(
      :thermal_margin_c,
      optional_number!(first_present_field(source, [:thermal_margin_c, :temperature_margin_c]))
    )
    |> maybe_put_opt(
      :thermal_status,
      optional_scalar!(first_present_field(source, [:thermal_status, :temperature_status]))
    )
    |> maybe_put_opt(
      :thermal_model,
      optional_scalar!(first_present_field(source, [:thermal_model, :temperature_model]))
    )
    |> maybe_put_opt(
      :thermal_source,
      optional_scalar!(first_present_field(source, [:thermal_source, :temperature_source]))
    )
    |> maybe_put_opt(
      :thermal_confidence,
      optional_number!(
        first_present_field(source, [:thermal_confidence, :temperature_confidence])
      )
    )
    |> maybe_put_opt(
      :eclipse_overlap_fraction,
      optional_number!(
        first_present_field(source, [
          :eclipse_overlap_fraction,
          :eclipse_fraction,
          :eclipsed_fraction
        ])
      )
    )
    |> maybe_put_opt(
      :eclipse_overlap_s,
      optional_number!(
        first_present_field(source, [:eclipse_overlap_s, :eclipse_overlap_seconds])
      )
    )
    |> maybe_put_opt(
      :lighting_condition,
      optional_scalar!(first_present_field(source, [:lighting_condition, :lighting_status]))
    )
    |> maybe_put_opt(
      :lighting_condition_detail,
      optional_scalar!(
        first_present_field(source, [:lighting_condition_detail, :lighting_detail])
      )
    )
    |> maybe_put_opt(
      :lighting_condition_model,
      optional_scalar!(first_present_field(source, [:lighting_condition_model, :lighting_model]))
    )
    |> maybe_put_opt(
      :lighting_detail_model,
      optional_scalar!(
        first_present_field(source, [:lighting_detail_model, :lighting_detail_source])
      )
    )
    |> maybe_put_opt(
      :lighting_confidence,
      optional_number_or_scalar!(
        first_present_field(source, [:lighting_confidence, :lighting_confidence_label])
      )
    )
    |> maybe_put_opt(:command_window_id, optional_identifier!(command_window_id_field(source)))
    |> maybe_put_opt(
      :command_window_type,
      optional_identifier!(command_window_type_field(source))
    )
    |> maybe_put_opt(:command_window, optional_map!(field(source, :command_window)))
    |> maybe_put_opt(:dependencies, optional_dependencies!(field(source, :dependencies)))
    |> maybe_put_opt(
      :dependency_activity_ids,
      optional_id_list!(
        first_present_field(source, [:dependency_activity_ids, :depends_on_activity_ids]),
        "dependency_activity_ids",
        "activity ids"
      )
    )
    |> maybe_put_opt(
      :dependency_timeline_ids,
      optional_id_list!(
        first_present_field(source, [:dependency_timeline_ids, :depends_on_timeline_ids]),
        "dependency_timeline_ids",
        "timeline ids"
      )
    )
    |> maybe_put_opt(
      :exclusive_with_activity_ids,
      optional_id_list!(
        first_present_field(source, [:exclusive_with_activity_ids, :exclusive_with]),
        "exclusive_with_activity_ids",
        "activity ids"
      )
    )
    |> maybe_put_opt(
      :exclusive_with_timeline_ids,
      optional_id_list!(
        field(source, :exclusive_with_timeline_ids),
        "exclusive_with_timeline_ids",
        "timeline ids"
      )
    )
    |> maybe_put_opt(:exclusivity_group, optional_identifier!(field(source, :exclusivity_group)))
    |> maybe_put_opt(:source_window_id, optional_identifier!(field(source, :source_window_id)))
    |> maybe_put_opt(
      :source_window_type,
      optional_identifier!(
        first_present_field(source, [:source_window_type, :source_window_kind])
      )
    )
    |> maybe_put_opt(:source_window, optional_map!(field(source, :source_window)))
    |> maybe_put_opt(:cadence_import, optional_cadence_import!(field(source, :cadence_import)))
    |> maybe_put_opt(
      :execution_uncertainty,
      optional_execution_uncertainty!(field(source, :execution_uncertainty))
    )
    |> maybe_put_opt(:provenance, optional_map!(field(source, :provenance)))
    |> maybe_put_opt(:metadata, optional_map!(field(source, :metadata)))
    |> maybe_put_opt(:allow_overlap?, optional_boolean!(field(source, :allow_overlap?)))
    |> maybe_put_opt(:ground_station_id, optional_identifier!(ground_station_id_field(source)))
    |> maybe_put_opt(:direction, optional_direction!(field(source, :direction)))
  end

  defp maybe_put_opt(opts, _key, nil), do: opts
  defp maybe_put_opt(opts, key, value), do: Keyword.put(opts, key, value)

  defp first_present_field(source, keys) do
    Enum.find_value(keys, fn key ->
      value = field(source, key)
      if is_nil(value), do: nil, else: {key, value}
    end)
    |> case do
      nil -> nil
      {_key, value} -> value
    end
  end

  defp command_window_id_field(source) do
    first_present_field(source, [:command_window_id, :command_window_ref]) ||
      nested_command_window_field(source, [:id, :window_id, :command_window_id])
  end

  defp command_window_type_field(source) do
    first_present_field(source, [:command_window_type, :window_type, :command_window_kind]) ||
      nested_command_window_field(source, [:type, :window_type, :command_window_type])
  end

  defp nested_command_window_field(source, keys) do
    case field(source, :command_window) do
      %{} = command_window -> first_present_field(command_window, keys)
      _other -> nil
    end
  end

  defp target_id_field(source) do
    field(source, :target_id) ||
      nested_identity_field(source, [:target], [:target_id, :id])
  end

  defp ground_station_id_field(source) do
    field(source, :ground_station_id) ||
      field(source, :station_id) ||
      nested_identity_field(source, [:ground_station], [:ground_station_id, :station_id, :id]) ||
      nested_identity_field(source, [:station], [:ground_station_id, :station_id, :id])
  end

  defp spacecraft_id_field(source) do
    field(source, :spacecraft_id) ||
      field(source, :satellite_id) ||
      nested_identity_field(source, [:spacecraft], [:spacecraft_id, :satellite_id, :id]) ||
      nested_identity_field(source, [:satellite], [:spacecraft_id, :satellite_id, :id])
  end

  defp nested_identity_field(source, object_keys, identity_keys) do
    object_keys
    |> Enum.find_value(&field(source, &1))
    |> case do
      %{} = object -> first_present_field(object, identity_keys)
      _value -> nil
    end
  end

  defp interval_start!(source) do
    source
    |> field(:start_s)
    |> case do
      nil -> field(source, :starts_at_s)
      value -> value
    end
    |> required_number!("start_s")
  end

  defp interval_end!(source) do
    source
    |> field(:end_s)
    |> case do
      nil -> field(source, :ends_at_s)
      value -> value
    end
    |> required_number!("end_s")
  end

  defp required_number!(value, _field) when is_integer(value) or is_float(value), do: value

  defp required_number!(value, field) when is_binary(value) do
    case numeric_or_nil(value) do
      nil -> required_number!(:invalid_number, field)
      number -> number
    end
  end

  defp required_number!(_value, field), do: raise(ArgumentError, "#{field} must be a number")

  defp required_enum_atom!(value, allowed, field) do
    case optional_enum_atom!(value, allowed, field) do
      nil -> raise ArgumentError, "#{field} is required"
      atom -> atom
    end
  end

  defp optional_enum_atom!(nil, _allowed, _field), do: nil

  defp optional_enum_atom!(value, allowed, field) when is_atom(value) do
    if value in allowed do
      value
    else
      raise ArgumentError, "#{field} must be one of #{inspect(allowed)}"
    end
  end

  defp optional_enum_atom!(value, allowed, field) when is_binary(value) do
    case exact_enum_atom(value, allowed) do
      nil -> raise ArgumentError, "#{field} must be one of #{inspect(allowed)}"
      atom -> atom
    end
  end

  defp optional_enum_atom!(_value, allowed, field),
    do: raise(ArgumentError, "#{field} must be one of #{inspect(allowed)}")

  defp required_activity_status_atom!(value) do
    case optional_activity_status_atom!(value) do
      nil -> raise ArgumentError, "status is required"
      atom -> atom
    end
  end

  defp optional_activity_status_atom!(nil), do: nil

  defp optional_activity_status_atom!(value) when is_binary(value) do
    normalized = normalized_token(value)

    cond do
      atom = exact_enum_atom(normalized, @activity_statuses) ->
        atom

      Map.has_key?(@activity_status_aliases, normalized) ->
        Map.fetch!(@activity_status_aliases, normalized)

      true ->
        raise ArgumentError, "status must be one of #{inspect(@activity_statuses)}"
    end
  end

  defp optional_activity_status_atom!(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> optional_activity_status_atom!()
  end

  defp optional_activity_status_atom!(_value),
    do: raise(ArgumentError, "status must be one of #{inspect(@activity_statuses)}")

  defp required_approval_status_atom!(value) do
    case optional_approval_status_atom!(value) do
      nil -> raise ArgumentError, "approval_status is required"
      atom -> atom
    end
  end

  defp optional_approval_status_atom!(nil), do: nil

  defp optional_approval_status_atom!(value) when is_binary(value) do
    normalized = normalized_token(value)

    cond do
      atom = exact_enum_atom(normalized, @approval_statuses) ->
        atom

      Map.has_key?(@approval_status_aliases, normalized) ->
        Map.fetch!(@approval_status_aliases, normalized)

      true ->
        raise ArgumentError, "approval_status must be one of #{inspect(@approval_statuses)}"
    end
  end

  defp optional_approval_status_atom!(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> optional_approval_status_atom!()
  end

  defp optional_approval_status_atom!(_value),
    do: raise(ArgumentError, "approval_status must be one of #{inspect(@approval_statuses)}")

  defp exact_enum_atom(value, allowed) when is_binary(value) do
    Enum.find(allowed, &(Atom.to_string(&1) == value))
  end

  defp normalized_token(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp optional_boolean!(nil), do: nil
  defp optional_boolean!(value) when is_boolean(value), do: value
  defp optional_boolean!(value) when value in ["true", "1", 1], do: true
  defp optional_boolean!(value) when value in ["false", "0", 0], do: false
  defp optional_boolean!(_value), do: raise(ArgumentError, "boolean field must be a boolean")

  defp optional_boolean!(nil, _field), do: nil
  defp optional_boolean!(value, _field) when is_boolean(value), do: value
  defp optional_boolean!(value, _field) when value in ["true", "1", 1], do: true
  defp optional_boolean!(value, _field) when value in ["false", "0", 0], do: false
  defp optional_boolean!(_value, field), do: raise(ArgumentError, "#{field} must be a boolean")

  defp optional_boolean?(nil), do: true
  defp optional_boolean?(value), do: is_boolean(value)

  defp optional_number?(nil), do: true
  defp optional_number?(value), do: is_number(value)

  defp optional_non_negative_number?(nil), do: true

  defp optional_non_negative_number?(value) when is_number(value),
    do: value >= 0.0

  defp optional_non_negative_number?(_value), do: false

  defp optional_non_negative_integer?(nil), do: true

  defp optional_non_negative_integer?(value) when is_integer(value),
    do: value >= 0

  defp optional_non_negative_integer?(_value), do: false

  defp optional_unit_interval?(nil), do: true

  defp optional_unit_interval?(value) when is_number(value),
    do: value >= 0.0 and value <= 1.0

  defp optional_unit_interval?(_value), do: false

  defp optional_scalar?(nil), do: true
  defp optional_scalar?(value) when is_binary(value), do: value != ""
  defp optional_scalar?(value) when is_atom(value), do: true
  defp optional_scalar?(_value), do: false

  defp optional_stable_identifier?(nil), do: true

  defp optional_stable_identifier?(value) when is_binary(value),
    do: Regex.match?(@stable_id_pattern, value)

  defp optional_stable_identifier?(value) when is_atom(value),
    do: value |> Atom.to_string() |> optional_stable_identifier?()

  defp optional_stable_identifier?(_value), do: false

  defp optional_number_or_scalar?(nil), do: true
  defp optional_number_or_scalar?(value) when is_number(value), do: true
  defp optional_number_or_scalar?(value), do: optional_scalar?(value)

  defp optional_number!(nil), do: nil

  defp optional_number!(value) do
    case numeric_or_nil(value) do
      nil -> raise ArgumentError, "number fields must be numbers"
      number -> number
    end
  end

  defp optional_non_negative_number!(nil, _field), do: nil

  defp optional_non_negative_number!(value, field) do
    case numeric_or_nil(value) do
      number when is_number(number) and number >= 0.0 ->
        number

      number when is_number(number) ->
        raise ArgumentError, "#{field} must be a non-negative number"

      nil ->
        raise ArgumentError, "#{field} must be a number"
    end
  end

  defp optional_non_negative_integer!(nil, _field), do: nil

  defp optional_non_negative_integer!(value, _field) when is_integer(value) and value >= 0,
    do: value

  defp optional_non_negative_integer!(value, field) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {integer, ""} when integer >= 0 ->
        integer

      _other ->
        raise ArgumentError, "#{field} must be a non-negative integer"
    end
  end

  defp optional_non_negative_integer!(_value, field),
    do: raise(ArgumentError, "#{field} must be a non-negative integer")

  defp optional_unit_interval!(nil, _field), do: nil

  defp optional_unit_interval!(value, field) do
    case numeric_or_nil(value) do
      number when is_number(number) and number >= 0.0 and number <= 1.0 ->
        number

      number when is_number(number) ->
        raise ArgumentError, "#{field} must be between 0.0 and 1.0"

      nil ->
        raise ArgumentError, "#{field} must be a number"
    end
  end

  defp optional_scalar!(nil), do: nil
  defp optional_scalar!(value) when is_binary(value) and value != "", do: value
  defp optional_scalar!(value) when is_atom(value) and not is_nil(value), do: value

  defp optional_scalar!(_value),
    do: raise(ArgumentError, "scalar fields must be strings or atoms")

  defp optional_scalar!(nil, _field), do: nil
  defp optional_scalar!(value, _field) when is_binary(value) and value != "", do: value
  defp optional_scalar!(value, _field) when is_atom(value) and not is_nil(value), do: value

  defp optional_scalar!(_value, field),
    do: raise(ArgumentError, "#{field} must be nil, a string, or an atom")

  defp optional_number_or_scalar!(nil), do: nil
  defp optional_number_or_scalar!(value) when is_number(value), do: value

  defp optional_number_or_scalar!(value) when is_binary(value) do
    case numeric_or_nil(value) do
      nil -> optional_scalar!(value)
      number -> number
    end
  end

  defp optional_number_or_scalar!(value), do: optional_scalar!(value)

  defp optional_direction!(nil), do: nil
  defp optional_direction!(direction), do: contact_direction!(direction)

  defp optional_dependencies!(nil), do: nil

  defp optional_dependencies!(dependencies),
    do: dependencies_input!(dependencies, "dependencies", "activity ids")

  defp optional_id_list!(nil, _field, _description), do: nil

  defp optional_id_list!(values, field, description),
    do: id_list_input!(values, field, description)

  defp optional_scalar_list!(nil, _field, _description), do: nil

  defp optional_scalar_list!(values, field, description),
    do: scalar_list_input!(values, field, description)

  defp optional_non_negative_number_list!(nil, _field), do: nil

  defp optional_non_negative_number_list!(values, field),
    do: non_negative_number_list_input!(values, field)

  defp optional_map_list!(nil, _field, _description), do: nil

  defp optional_map_list!(values, field, description),
    do: map_list_input!(values, field, description)

  defp optional_identifier!(nil), do: nil

  defp optional_identifier!(value) do
    if invalid_identifier?(value) do
      raise ArgumentError, "identifier fields must be non-empty"
    else
      value
    end
  end

  defp optional_stable_identifier!(nil, _field), do: nil

  defp optional_stable_identifier!(value, field) do
    if optional_stable_identifier?(value) do
      value
    else
      raise ArgumentError, "#{field} must be a stable identifier"
    end
  end

  defp optional_map!(nil), do: nil
  defp optional_map!(value) when is_map(value), do: value
  defp optional_map!(_value), do: raise(ArgumentError, "map fields must be maps")

  defp optional_map!(nil, _field), do: nil
  defp optional_map!(value, _field) when is_map(value), do: value

  defp optional_map!(_value, field),
    do: raise(ArgumentError, "#{field} must be nil or a map")

  defp optional_cadence_import!(nil), do: nil

  defp optional_cadence_import!(value) when is_map(value), do: normalize_cadence_import(value)

  defp optional_cadence_import!(_value), do: raise(ArgumentError, "map fields must be maps")

  defp optional_execution_uncertainty!(nil), do: nil

  defp optional_execution_uncertainty!(%{} = uncertainty) do
    uncertainty
    |> normalize_number_field(:timing_3sigma_s)
    |> normalize_number_field("timing_3sigma_s")
    |> normalize_triplet_field(:delta_v_3sigma_km_s)
    |> normalize_triplet_field("delta_v_3sigma_km_s")
    |> normalize_number_field(:delta_v_3sigma_magnitude_km_s)
    |> normalize_number_field("delta_v_3sigma_magnitude_km_s")
  end

  defp optional_execution_uncertainty!(_value),
    do: raise(ArgumentError, "map fields must be maps")

  defp delta_v!([x, y, z]), do: numeric_triplet!([x, y, z])
  defp delta_v!({x, y, z}), do: numeric_triplet!([x, y, z])

  defp delta_v!(_value),
    do: raise(ArgumentError, "delta_v_km_s must be a numeric {x, y, z} tuple")

  defp numeric_triplet!(values) do
    triplet = Enum.map(values, &numeric_or_nil/1)

    if Enum.all?(triplet, &is_number/1) do
      List.to_tuple(triplet)
    else
      delta_v!(:invalid_triplet)
    end
  end

  defp normalize_triplet_field(%{} = map, key) do
    case Map.fetch(map, key) do
      {:ok, values} ->
        case numeric_triplet_or_nil(values) do
          nil -> map
          triplet -> Map.put(map, key, triplet)
        end

      :error ->
        map
    end
  end

  defp numeric_triplet_or_nil(values) when is_list(values) and length(values) == 3 do
    triplet = Enum.map(values, &numeric_or_nil/1)

    if Enum.all?(triplet, &is_number/1) do
      triplet
    else
      nil
    end
  end

  defp numeric_triplet_or_nil(_values), do: nil

  defp normalize_number_field(%{} = map, key) do
    case Map.fetch(map, key) do
      {:ok, value} ->
        case numeric_or_nil(value) do
          nil -> map
          number -> Map.put(map, key, number)
        end

      :error ->
        map
    end
  end

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp frame_from_input!(nil), do: nil
  defp frame_from_input!(%Frame{} = frame), do: frame
  defp frame_from_input!(:eci_j2000), do: Frame.earth_inertial_j2000()
  defp frame_from_input!("eci_j2000"), do: Frame.earth_inertial_j2000()

  defp frame_from_input!(_frame),
    do: raise(ArgumentError, "frame must be nil, eci_j2000, or an OrbitalDynamics.Frame")

  defp activity_type_field(source) do
    case field(source, :type) do
      nil -> field(source, :activity_type)
      type -> type
    end
  end

  defp field(map, key) when is_atom(key) do
    case Map.fetch(map, key) do
      {:ok, nil} -> Map.get(map, Atom.to_string(key))
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key))
    end
  end

  defp artifact_value(value) when is_boolean(value) or is_nil(value), do: value
  defp artifact_value(value) when is_atom(value), do: Atom.to_string(value)

  defp artifact_value(%Frame{} = frame), do: frame_name(frame) |> artifact_value()

  defp artifact_value(%{} = map) do
    Map.new(map, fn {key, value} ->
      key =
        if is_atom(key) do
          Atom.to_string(key)
        else
          key
        end

      {key, artifact_value(value)}
    end)
  end

  defp artifact_value(values) when is_list(values), do: Enum.map(values, &artifact_value/1)
  defp artifact_value({x, y, z}), do: [artifact_value(x), artifact_value(y), artifact_value(z)]
  defp artifact_value(value), do: value

  defp maybe_put_ground_station(activity, opts) do
    case Keyword.get(opts, :ground_station_id) do
      nil ->
        activity

      ground_station_id ->
        Map.put(
          activity,
          :ground_station_id,
          required_identifier!(ground_station_id, "ground_station_id")
        )
    end
  end

  defp contact_direction!(direction) when direction in @contact_directions, do: direction

  defp contact_direction!(direction) when is_binary(direction) do
    normalized =
      direction
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/[\s-]+/, "_")

    aliased_direction =
      @contact_direction_aliases
      |> Map.get(normalized, normalized)
      |> to_string()

    case Enum.find(@contact_directions, &(Atom.to_string(&1) == aliased_direction)) do
      nil -> contact_direction!(nil)
      direction -> direction
    end
  end

  defp contact_direction!(_direction),
    do: raise(ArgumentError, "direction must be one of #{inspect(@contact_directions)}")

  defp health_check_direction!(direction) do
    case contact_direction!(direction) do
      :health_check ->
        :health_check

      _other ->
        raise ArgumentError, "health_check direction must be health_check"
    end
  end

  defp valid_dependencies?(dependencies) when is_list(dependencies) do
    match?({:ok, _values}, dependency_values(dependencies))
  end

  defp valid_dependencies?(_dependencies), do: false

  defp valid_scalar_list?(values) when is_list(values) do
    match?({:ok, _values}, scalar_list_values(values))
  end

  defp valid_scalar_list?(_values), do: false

  defp dependencies_input!(values, field, description) do
    case dependency_values(values) do
      {:ok, ids} -> ids
      :error -> raise ArgumentError, "#{field} must be a list of #{description}"
    end
  end

  defp dependency_values(values) when is_list(values) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, ids} ->
      case dependency_values(value) do
        {:ok, value_ids} -> {:cont, {:ok, ids ++ value_ids}}
        :error -> {:halt, :error}
      end
    end)
  end

  defp dependency_values(%{} = value), do: {:ok, [value]}

  defp dependency_values(value) do
    case id_list_value(value) do
      [] -> :error
      ids -> {:ok, ids}
    end
  end

  defp dependency_activity_ids(values) when is_list(values) do
    values
    |> Enum.flat_map(&dependency_activity_id_values/1)
    |> Enum.uniq()
  end

  defp dependency_activity_id_values(%{} = value) do
    [:activity_id, "activity_id", :id, "id"]
    |> Enum.flat_map(fn key ->
      case Map.get(value, key) do
        nil -> []
        nested when is_list(nested) -> Enum.flat_map(nested, &id_list_value/1)
        nested -> id_list_value(nested)
      end
    end)
  end

  defp dependency_activity_id_values(value), do: id_list_value(value)

  defp scalar_list_input!(values, field, description) do
    case scalar_list_values(values) do
      {:ok, values} -> values
      :error -> raise ArgumentError, "#{field} must be a list of #{description}"
    end
  end

  defp scalar_list_values(values) when is_list(values) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, scalars} ->
      case scalar_list_values(value) do
        {:ok, value_scalars} -> {:cont, {:ok, scalars ++ value_scalars}}
        :error -> {:halt, :error}
      end
    end)
  end

  defp scalar_list_values(value) do
    case scalar_list_value(value) do
      [] -> :error
      values -> {:ok, values}
    end
  end

  defp scalar_list_value(value) when is_atom(value) and not is_nil(value),
    do: [value]

  defp scalar_list_value(value) when is_binary(value) do
    values =
      value
      |> String.split(",", trim: false)
      |> Enum.map(&String.trim/1)

    if Enum.all?(values, &(&1 != "")), do: values, else: []
  end

  defp scalar_list_value(_value), do: []

  defp non_negative_number_list_input!(values, field) do
    case non_negative_number_list_values(values) do
      {:ok, numbers} -> numbers
      :error -> raise ArgumentError, "#{field} must be a list of non-negative numbers"
    end
  end

  defp non_negative_number_list_values(values) when is_list(values) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, numbers} ->
      case non_negative_number_list_values(value) do
        {:ok, value_numbers} -> {:cont, {:ok, numbers ++ value_numbers}}
        :error -> {:halt, :error}
      end
    end)
  end

  defp non_negative_number_list_values(value) when is_binary(value) do
    values =
      value
      |> String.split(",", trim: false)
      |> Enum.map(&String.trim/1)

    numbers = Enum.map(values, &numeric_or_nil/1)

    if values != [] and Enum.all?(numbers, &(is_number(&1) and &1 >= 0.0)) do
      {:ok, numbers}
    else
      :error
    end
  end

  defp non_negative_number_list_values(value) do
    case numeric_or_nil(value) do
      number when is_number(number) and number >= 0.0 -> {:ok, [number]}
      _other -> :error
    end
  end

  defp map_list_input!(values, field, description) do
    case map_list_values(values) do
      {:ok, maps} -> maps
      :error -> raise ArgumentError, "#{field} must be a list of #{description}"
    end
  end

  defp map_list_values(values) when is_list(values) do
    if Enum.all?(values, &is_map/1), do: {:ok, values}, else: :error
  end

  defp map_list_values(_values), do: :error

  defp id_list_input!(values, field, description) do
    case id_list_values(values) do
      {:ok, ids} -> ids
      :error -> raise ArgumentError, "#{field} must be a list of #{description}"
    end
  end

  defp id_list_values(values) when is_list(values) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, ids} ->
      case id_list_values(value) do
        {:ok, value_ids} -> {:cont, {:ok, ids ++ value_ids}}
        :error -> {:halt, :error}
      end
    end)
  end

  defp id_list_values(value) do
    case id_list_value(value) do
      [] -> :error
      ids -> {:ok, ids}
    end
  end

  defp id_list_value(value) when is_atom(value) and not is_nil(value) do
    string_value = Atom.to_string(value)
    if Regex.match?(@stable_id_pattern, string_value), do: [value], else: []
  end

  defp id_list_value(value) when is_binary(value) do
    values =
      value
      |> String.split(",", trim: false)
      |> Enum.map(&String.trim/1)

    if Enum.all?(values, &stable_id_string?/1), do: values, else: []
  end

  defp id_list_value(_value), do: []

  defp stable_id_string?(value),
    do: value != "" and Regex.match?(@stable_id_pattern, value)

  defp nested_source_window_id(%{} = source_window) do
    Map.get(source_window, :id) || Map.get(source_window, "id") ||
      Map.get(source_window, :window_id) ||
      Map.get(source_window, "window_id")
  end

  defp nested_source_window_id(_source_window), do: nil

  defp nested_source_window_type(%{} = source_window) do
    Map.get(source_window, :type) || Map.get(source_window, "type") ||
      Map.get(source_window, :kind) || Map.get(source_window, "kind") ||
      Map.get(source_window, :window_type) || Map.get(source_window, "window_type")
  end

  defp nested_source_window_type(_source_window), do: nil

  defp normalize_cadence_import(nil), do: nil

  defp normalize_cadence_import(%{} = cadence_import) do
    key_style = map_key_style(cadence_import)

    cadence_import
    |> Map.drop(cadence_import_alias_keys())
    |> put_cadence_import_value(
      key_style,
      :external_id,
      first_present_field(cadence_import, [
        :external_id,
        :id,
        :cadence_id,
        :external_ref,
        :external_reference
      ])
    )
    |> put_cadence_import_value(
      key_style,
      :activity_type,
      first_present_field(cadence_import, [
        :activity_type,
        :type,
        :import_type,
        :cadence_import_type
      ])
    )
    |> put_cadence_import_value(
      key_style,
      :schema_contract,
      first_present_field(cadence_import, [
        :schema_contract,
        :contract,
        :schema,
        :artifact_contract
      ])
    )
    |> put_cadence_import_value(
      key_style,
      :trust_boundary,
      first_present_field(cadence_import, [:trust_boundary])
    )
  end

  defp normalize_cadence_import(value), do: value

  defp cadence_import_alias_keys do
    [
      :external_id,
      "external_id",
      :id,
      "id",
      :cadence_id,
      "cadence_id",
      :external_ref,
      "external_ref",
      :external_reference,
      "external_reference",
      :activity_type,
      "activity_type",
      :type,
      "type",
      :import_type,
      "import_type",
      :cadence_import_type,
      "cadence_import_type",
      :schema_contract,
      "schema_contract",
      :contract,
      "contract",
      :schema,
      "schema",
      :artifact_contract,
      "artifact_contract",
      :trust_boundary,
      "trust_boundary"
    ]
  end

  defp map_key_style(map) do
    if Enum.any?(Map.keys(map), &is_atom/1), do: :atom, else: :string
  end

  defp put_cadence_import_value(map, _key_style, _key, value) when value in [nil, ""], do: map

  defp put_cadence_import_value(map, key_style, key, value) do
    Map.put(map, styled_key(key, key_style), value)
  end

  defp styled_key(key, :atom), do: key
  defp styled_key(key, :string), do: Atom.to_string(key)

  defp required_identifier!(value, field) do
    if invalid_identifier?(value), do: raise(ArgumentError, "#{field} is required"), else: value
  end

  defp frame_name(nil), do: nil
  defp frame_name(%Frame{} = frame), do: frame.name

  defp invalid_identifier?(value), do: value in [nil, ""]
  defp non_negative_number?(value), do: (is_integer(value) or is_float(value)) and value >= 0
end
