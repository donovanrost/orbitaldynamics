defmodule OrbitalDynamics.ResourceProjection do
  @moduledoc """
  Thin planning-grade resource projection over selected activities.

  This module projects externally supplied `resource_summary.v1` rows across a
  selected activity list using simple storage production and downlink transfer
  arithmetic. It is not a subsystem simulator and does not propagate calibrated
  resource state over time.
  """

  @schema_contract "resource_projection_report.v1"
  @flow_summary_schema_contract "resource_projection_flow_summary.v1"
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @activity_stable_identity_fields ~w(
    scenario_id
    spacecraft_id
    ground_station_id
    target_id
    source_window_id
  )
  @resource_availability_value_aliases %{
    "payload_available" => ["payload_available?"],
    "antenna_available" => ["antenna_available?"],
    "spacecraft_available" => ["spacecraft_available?", "spacecraft_availability"]
  }
  @resource_availability_status_aliases %{
    "payload_available" => ["payload_status"],
    "antenna_available" => ["antenna_status"],
    "spacecraft_available" => ["spacecraft_status"]
  }
  @resource_availability_aliases Map.new(@resource_availability_value_aliases, fn {field, aliases} ->
                                   {field,
                                    aliases ++
                                      Map.fetch!(@resource_availability_status_aliases, field)}
                                 end)
  @resource_degraded_aliases ["degraded?"]
  @resource_margin_aliases %{
    "storage_margin" => ["storage_capacity_margin"],
    "downlink_margin" => ["downlink_capacity_margin"],
    "battery_state_of_charge" => ["battery_soc"]
  }
  @resource_source_quality_aliases [
    ["resource_source_quality"],
    ["provenance", "source_quality"],
    ["provenance", "resource_source_quality"],
    ["provenance", "quality"]
  ]
  @resource_trust_boundary_aliases [
    ["resource_trust_boundary"],
    ["provenance", "trust_boundary"],
    ["provenance", "resource_trust_boundary"]
  ]
  @planned_data_volume_paths [
    ["planned_data_volume_mb"],
    ["data_volume_mb"],
    ["estimated_data_volume_mb"],
    ["metadata", "planned_data_volume_mb"],
    ["metadata", "data_volume_mb"],
    ["metadata", "estimated_data_volume_mb"]
  ]
  @actual_data_volume_paths [
    ["actual_data_volume_mb"],
    ["actual_storage_mb"],
    ["actual_downlink_mb"],
    ["delivered_data_mb"],
    ["received_data_mb"],
    ["metadata", "actual_data_volume_mb"],
    ["metadata", "actual_storage_mb"],
    ["metadata", "actual_downlink_mb"],
    ["metadata", "delivered_data_mb"],
    ["metadata", "received_data_mb"]
  ]
  @estimated_downlink_throughput_paths [
    ["estimated_throughput_mb"],
    ["estimated_downlink_mb"],
    ["planned_throughput_mb"],
    ["throughput_model", "estimated_throughput_mb"],
    ["throughput_model", "estimated_downlink_mb"],
    ["throughput_model", "planned_throughput_mb"],
    ["metadata", "estimated_throughput_mb"],
    ["metadata", "estimated_downlink_mb"],
    ["metadata", "planned_throughput_mb"]
  ]
  @battery_energy_consumed_paths [
    ["estimated_energy_used_wh"],
    ["estimated_battery_energy_used_wh"],
    ["planned_energy_used_wh"],
    ["battery_energy_used_wh"],
    ["metadata", "estimated_energy_used_wh"],
    ["metadata", "estimated_battery_energy_used_wh"],
    ["metadata", "planned_energy_used_wh"],
    ["metadata", "battery_energy_used_wh"]
  ]
  @battery_energy_generated_paths [
    ["estimated_energy_generated_wh"],
    ["estimated_battery_energy_generated_wh"],
    ["planned_energy_generated_wh"],
    ["battery_energy_generated_wh"],
    ["metadata", "estimated_energy_generated_wh"],
    ["metadata", "estimated_battery_energy_generated_wh"],
    ["metadata", "planned_energy_generated_wh"],
    ["metadata", "battery_energy_generated_wh"]
  ]
  @resource_availability_true_tokens ~w(true yes y available nominal operational enabled 1)
  @resource_availability_false_tokens ~w(false no n unavailable offline down outage maintenance disabled 0)
  @provider_direction_aliases %{
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
  @station_calendar_direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "commands" => "command",
    "sband_command" => "command",
    "s_band_command" => "command",
    "uplink" => "command",
    "up" => "command",
    "up_link" => "command",
    "dl" => "downlink",
    "down" => "downlink",
    "downlinking" => "downlink",
    "down_link" => "downlink",
    "x_band_downlink" => "downlink",
    "track" => "tracking",
    "track_ing" => "tracking",
    "tracking_pass" => "tracking",
    "health" => "health_check",
    "healthcheck" => "health_check",
    "health_check_window" => "health_check"
  }
  @resource_activity_type_aliases Map.merge(@station_calendar_direction_aliases, %{
                                    "uplink_command" => "command"
                                  })
  @station_capacity_fraction_paths [
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"],
    ["capacity_pack_capacity_fraction"],
    ["station_capacity_fraction"],
    ["capacity_fraction"]
  ]
  @station_capacity_percent_paths [
    ["throughput_model", "station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["activity_context", "station_capacity_percent"],
    ["activity_context", "capacity_percent"],
    ["station_capacity_percent"],
    ["capacity_percent"]
  ]
  @source_station_capacity_fraction_paths [
    ["station_capacity_fraction"],
    ["capacity_fraction"],
    ["capacity_pack_capacity_fraction"],
    ["throughput_model", "station_capacity_fraction"],
    ["throughput_model", "capacity_fraction"],
    ["capacity_model", "station_capacity_fraction"],
    ["capacity_model", "capacity_fraction"],
    ["activity_context", "station_capacity_fraction"],
    ["activity_context", "capacity_fraction"]
  ]
  @source_station_capacity_percent_paths [
    ["station_capacity_percent"],
    ["capacity_percent"],
    ["throughput_model", "station_capacity_percent"],
    ["throughput_model", "capacity_percent"],
    ["capacity_model", "station_capacity_percent"],
    ["capacity_model", "capacity_percent"],
    ["activity_context", "station_capacity_percent"],
    ["activity_context", "capacity_percent"]
  ]
  @station_capacity_value_paths [
    {:fraction, ["throughput_model", "station_capacity_fraction"]},
    {:fraction, ["throughput_model", "capacity_fraction"]},
    {:percent, ["throughput_model", "station_capacity_percent"]},
    {:percent, ["throughput_model", "capacity_percent"]},
    {:fraction, ["capacity_model", "station_capacity_fraction"]},
    {:fraction, ["capacity_model", "capacity_fraction"]},
    {:percent, ["capacity_model", "station_capacity_percent"]},
    {:percent, ["capacity_model", "capacity_percent"]},
    {:fraction, ["activity_context", "station_capacity_fraction"]},
    {:fraction, ["activity_context", "capacity_fraction"]},
    {:percent, ["activity_context", "station_capacity_percent"]},
    {:percent, ["activity_context", "capacity_percent"]},
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:percent, ["station_capacity_percent"]},
    {:percent, ["capacity_percent"]}
  ]
  @source_station_capacity_value_paths [
    {:fraction, ["station_capacity_fraction"]},
    {:fraction, ["capacity_fraction"]},
    {:fraction, ["capacity_pack_capacity_fraction"]},
    {:percent, ["station_capacity_percent"]},
    {:percent, ["capacity_percent"]},
    {:fraction, ["throughput_model", "station_capacity_fraction"]},
    {:fraction, ["throughput_model", "capacity_fraction"]},
    {:percent, ["throughput_model", "station_capacity_percent"]},
    {:percent, ["throughput_model", "capacity_percent"]},
    {:fraction, ["capacity_model", "station_capacity_fraction"]},
    {:fraction, ["capacity_model", "capacity_fraction"]},
    {:percent, ["capacity_model", "station_capacity_percent"]},
    {:percent, ["capacity_model", "capacity_percent"]},
    {:fraction, ["activity_context", "station_capacity_fraction"]},
    {:fraction, ["activity_context", "capacity_fraction"]},
    {:percent, ["activity_context", "station_capacity_percent"]},
    {:percent, ["activity_context", "capacity_percent"]}
  ]

  alias OrbitalDynamics.Policy

  @doc """
  Declares the resource projection model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      flow_summary_artifact_contract: @flow_summary_schema_contract,
      model: :thin_selected_activity_resource_projection,
      validation_level: :artifact_contract,
      approval_policy_boundary: :optional_policy_decision_v1,
      resource_projection_helpers: [:flow_report, :flow_summary],
      public_facades: [
        :resource_projection_report,
        :resource_projection_flow_report,
        :resource_projection_flow_summary
      ],
      handoff_artifacts: [
        "operator_review_package.v1",
        "cadence_import_manifest.v1"
      ],
      handoff_review_type: "resource_projection_review",
      handoff_import_action: "review_resource_projection",
      resource_availability_aliases: @resource_availability_aliases,
      resource_degraded_aliases: @resource_degraded_aliases,
      resource_margin_aliases: @resource_margin_aliases,
      resource_source_quality_aliases: @resource_source_quality_aliases,
      resource_trust_boundary_aliases: @resource_trust_boundary_aliases,
      planned_data_volume_paths: @planned_data_volume_paths,
      actual_data_volume_paths: @actual_data_volume_paths,
      estimated_downlink_throughput_paths: @estimated_downlink_throughput_paths,
      battery_energy_consumed_paths: @battery_energy_consumed_paths,
      battery_energy_generated_paths: @battery_energy_generated_paths,
      resource_availability_true_tokens: @resource_availability_true_tokens,
      resource_availability_false_tokens: @resource_availability_false_tokens,
      provider_direction_aliases: @provider_direction_aliases,
      station_calendar_direction_aliases: @station_calendar_direction_aliases,
      station_capacity_fraction_paths: @station_capacity_fraction_paths,
      station_capacity_percent_paths: @station_capacity_percent_paths,
      station_capacity_value_paths: capacity_value_path_metadata(@station_capacity_value_paths),
      source_station_capacity_fraction_paths: @source_station_capacity_fraction_paths,
      source_station_capacity_percent_paths: @source_station_capacity_percent_paths,
      source_station_capacity_value_paths:
        capacity_value_path_metadata(@source_station_capacity_value_paths),
      activity_stable_identity_fields: @activity_stable_identity_fields,
      row_semantics: [
        :per_spacecraft_activity_counts,
        :time_ordered_activity_resource_flow,
        :resource_projection_row_count_list_consistency,
        :resource_projection_flow_summary,
        :resource_projection_flow_pressure_routing,
        :resource_projection_flow_invalid_input_routing,
        :resource_projection_flow_ignored_activity_routing,
        :status_aware_activity_resource_effects,
        :contact_allocation_status_resource_effects,
        :storage_projection,
        :downlink_capacity_projection,
        :declared_activity_battery_energy_projection,
        :storage_limited_downlink_utilization,
        :resource_projection_flow_quantity_totals,
        :collection_latency_flow_evidence,
        :planned_data_volume_storage_production_aliases,
        :realized_data_volume_evidence,
        :actual_data_volume_audit_only_aliases,
        :estimated_downlink_throughput_aliases,
        :battery_energy_consumed_aliases,
        :battery_energy_generated_aliases,
        :station_calendar_pressure_context,
        :station_calendar_capacity_fraction_context,
        :station_calendar_capacity_percent_aliases,
        :provider_direction_aliases,
        :station_calendar_direction_aliases,
        :station_capacity_value_paths,
        :source_station_capacity_value_paths,
        :activity_source_window_provenance,
        :first_pressure_source_window_context,
        :activity_stable_identity_fields,
        :spacecraft_availability_pressure,
        :resource_availability_aliases,
        :resource_availability_status_tokens,
        :resource_degraded_aliases,
        :resource_margin_aliases,
        :payload_and_antenna_availability_pressure,
        :externally_supplied_thermal_margin_pressure,
        :resource_summary_activity_type_suppression,
        :first_resource_pressure_event,
        :overflow_and_shortfall_warnings,
        :resource_source_quality_counts,
        :resource_source_quality_spacecraft_id_routing,
        :resource_source_quality_aliases,
        :resource_trust_boundary_status_counts,
        :resource_trust_boundary_status_spacecraft_id_routing,
        :resource_trust_boundary_aliases,
        :resource_provenance_alias_normalization,
        :completed_fraction_unit_interval_input_validation,
        :capacity_fraction_unit_interval_input_validation,
        :derived_resource_summary_margin_consistency,
        :negative_activity_resource_quantity_review,
        :malformed_activity_resource_quantity_review,
        :invalid_activity_input_review,
        :invalid_resource_summary_input_review,
        :duplicate_resource_summary_scope_review,
        :mixed_wildcard_resource_summary_scope_review
      ],
      row_review_statuses: ["operator_review_required"],
      known_limits: [
        :artifact_level_only,
        :externally_supplied_resource_summary,
        :no_subsystem_simulation,
        :thin_time_ordered_resource_roll_forward,
        :battery_projection_uses_declared_activity_energy_only,
        :realized_data_volume_is_evidence_not_state_reconciliation,
        :no_realized_state_resource_reconciliation,
        :no_link_budget_model,
        :no_schedule_mutation
      ]
    }
  end

  defp capacity_value_path_metadata(paths) do
    Enum.map(paths, fn {unit, path} -> %{unit: unit, path: path} end)
  end

  @doc """
  Builds a `resource_projection_report.v1`.

  Returns `nil` when no summaries are supplied, matching the existing optional
  campaign and repair artifact behavior.
  """
  def report(resource_projection_report)

  def report(%{"schema_contract" => @schema_contract} = resource_projection_report) do
    resource_projection_report
  end

  def report(%{schema_contract: @schema_contract} = resource_projection_report) do
    stringify_keys(resource_projection_report)
  end

  def report(_resource_projection_report),
    do: raise(ArgumentError, "resource projection report must be a map")

  def report(activities, summaries, opts \\ [])

  def report(_activities, [], _opts), do: nil

  def report(activities, summaries, opts) when is_list(activities) and is_list(summaries) do
    {invalid_activities, activities} =
      activities
      |> Enum.with_index(1)
      |> Enum.map(&normalize_activity_input/1)
      |> Enum.split_with(&invalid_activity_input?/1)

    {invalid_summaries, summaries} =
      summaries
      |> Enum.with_index(1)
      |> Enum.map(&normalize_summary_input/1)
      |> Enum.split_with(&invalid_resource_summary_input?/1)

    {review_summaries, summaries} = split_review_gated_resource_summary_scopes(summaries)
    invalid_summaries = invalid_summaries ++ review_summaries

    input_summary_count = length(summaries) + length(invalid_summaries)
    summary_count = length(summaries)

    model =
      opts
      |> Keyword.get(:model, "thin_selected_activity_resource_projection")
      |> to_string()

    source =
      opts
      |> Keyword.get(:source, "resource_summaries")
      |> to_string()

    approval_policy = Keyword.get(opts, :approval_policy)

    invalid_activities =
      Enum.map(
        invalid_activities,
        &maybe_apply_invalid_activity_approval_policy(&1, approval_policy)
      )

    invalid_summaries =
      Enum.map(
        invalid_summaries,
        &maybe_apply_invalid_summary_approval_policy(&1, approval_policy)
      )

    projected_resources =
      summaries
      |> Enum.map(&resource_projection_row(&1, activities, summary_count))
      |> Enum.sort_by(& &1["spacecraft_id"])
      |> maybe_apply_approval_policy(approval_policy)

    flow_rows = resource_flow_rows(projected_resources)
    pressure_resources = Enum.filter(projected_resources, &resource_pressure_row?/1)
    pressure_types = resource_pressure_types(projected_resources)

    warnings =
      projected_resources
      |> Enum.flat_map(&Map.get(&1, "warnings", []))
      |> Enum.uniq()
      |> Enum.sort()

    %{
      "schema_contract" => @schema_contract,
      "model" => model,
      "input_resource_summary_count" => input_summary_count,
      "valid_resource_summary_count" => summary_count,
      "invalid_resource_summary_input_count" => length(invalid_summaries),
      "invalid_resource_summary_input_ids" =>
        Enum.map(invalid_summaries, & &1["resource_summary_id"]),
      "invalid_resource_summary_inputs" => invalid_summaries,
      "activity_count" => length(activities) + length(invalid_activities),
      "valid_activity_count" => length(activities),
      "invalid_activity_input_count" => length(invalid_activities),
      "invalid_activity_input_ids" => Enum.map(invalid_activities, & &1["activity_id"]),
      "invalid_activity_inputs" => invalid_activities,
      "projected_resources" => projected_resources,
      "resource_pressure_count" => length(pressure_resources),
      "resource_pressure_types" => pressure_types,
      "resource_pressure_spacecraft_ids" => resource_pressure_spacecraft_ids(pressure_resources),
      "resource_pressure_spacecraft_ids_by_type" =>
        resource_pressure_spacecraft_ids_by_type(projected_resources, flow_rows),
      "resource_pressure_activity_ids_by_type" =>
        resource_pressure_activity_ids_by_type(flow_rows),
      "warnings" => warnings,
      "model_limits" => model_limits(),
      "resource_source_quality_counts" => resource_source_quality_counts(projected_resources),
      "resource_spacecraft_ids_by_source_quality" =>
        resource_spacecraft_ids_by_source_quality(projected_resources),
      "resource_trust_boundary_status_counts" =>
        resource_trust_boundary_status_counts(projected_resources),
      "resource_spacecraft_ids_by_trust_boundary_status" =>
        resource_spacecraft_ids_by_trust_boundary_status(projected_resources),
      "assumptions" => %{
        "source" => source,
        "activity_match" =>
          "spacecraft_id_or_scenario_id_match_id_less_single_summary_applies_to_all_activities",
        "storage_model" =>
          "starting_storage_used_mb + estimated_storage_produced_mb - storage_limited_downlinked_mb",
        "downlink_model" => "capacity_adjusted_estimated_throughput_consumes_downlink_capacity",
        "activity_flow_model" =>
          "activities_ordered_by_starts_at_s_then_id_with_storage_downlink_roll_forward",
        "activity_status_model" =>
          "terminal_or_approval_rejected_activities_are_audited_with_zero_projected_resource_effect",
        "realized_data_volume_model" =>
          "actual data-volume fields and delivered/received aliases are preserved as evidence and do not reconcile projected resource state",
        "invalid_activity_input" =>
          "selected activity inputs missing stable identity, activity type, valid unit-interval completion or capacity-fraction evidence, or valid non-negative resource quantities are preserved for operator review and excluded from resource projection",
        "invalid_resource_summary_input" =>
          "external resource summaries with invalid identity, negative capacity/use fields, out-of-range margins, or stale derived margins are preserved for operator review and excluded from resource projection",
        "duplicate_resource_summary_scope" =>
          "duplicate valid resource summaries for the same spacecraft or wildcard scope are preserved for operator review and excluded from resource projection math",
        "mixed_wildcard_resource_summary_scope" =>
          "id-less wildcard resource summaries only apply when they are the single summary; mixed wildcard and scoped summaries are preserved for operator review and excluded from projection math",
        "resource_trust_boundary_model" =>
          "resource_trust_boundary_status records whether each external resource summary declared a trust boundary"
      }
    }
  end

  def report(_activities, _summaries, _opts),
    do: raise(ArgumentError, "activities and summaries must be lists")

  @doc """
  Builds a compact artifact-only flow summary for selected activity projection.

  This helper accepts an existing `resource_projection_flow_summary.v1`,
  an existing `resource_projection_report.v1`, or the source activities and
  resource summaries used to build one. It exposes
  row-derived storage/downlink/battery flow evidence without the full
  operator-review handoff payload. It preserves the planning-grade model
  limits: no subsystem simulation, schedule mutation, link-budget modeling, or
  realized-state reconciliation is performed.
  """
  def flow_report(resource_projection_report)

  def flow_report(%{"schema_contract" => @flow_summary_schema_contract} = flow_summary),
    do: flow_summary

  def flow_report(%{schema_contract: @flow_summary_schema_contract} = flow_summary) do
    flow_summary
    |> stringify_keys()
    |> flow_report()
  end

  def flow_report(%{"schema_contract" => @schema_contract} = resource_projection_report) do
    flow_summary(resource_projection_report)
  end

  def flow_report(%{schema_contract: @schema_contract} = resource_projection_report) do
    resource_projection_report
    |> stringify_keys()
    |> flow_report()
  end

  def flow_report(_resource_projection_report),
    do: raise(ArgumentError, "resource projection report is required")

  def flow_report(activities, summaries, opts \\ []) do
    case report(activities, summaries, opts) do
      nil -> nil
      report -> flow_summary(report)
    end
  end

  @doc """
  Summarizes an existing `resource_projection_report.v1` into compact flow evidence.

  Use `flow_report/3` when the selected activities and resource summaries still
  need to be projected. Use this helper when the projection artifact already
  exists and callers need the deterministic storage/downlink/battery flow
  summary advertised by `capabilities/0`. Existing
  `resource_projection_flow_summary.v1` artifacts are accepted as idempotent
  inputs for handoff pipelines that already hold the compact artifact.
  """
  def flow_summary(resource_projection_report)

  def flow_summary(%{"schema_contract" => @flow_summary_schema_contract} = flow_summary),
    do: flow_summary

  def flow_summary(%{schema_contract: @flow_summary_schema_contract} = flow_summary) do
    flow_summary
    |> stringify_keys()
    |> flow_summary()
  end

  def flow_summary(%{"schema_contract" => @schema_contract} = report) do
    report = stringify_keys(report)
    projected_resources = Map.get(report, "projected_resources", [])
    flow_rows = resource_flow_rows(projected_resources)
    ignored_flow_rows = ignored_activity_flow_rows(flow_rows)
    pressure_resources = Enum.filter(projected_resources, &resource_pressure_row?/1)
    pressure_types = resource_pressure_types(projected_resources)
    invalid_activity_inputs = invalid_input_rows(report, "invalid_activity_inputs")

    invalid_resource_summary_inputs =
      invalid_input_rows(report, "invalid_resource_summary_inputs")

    invalid_activity_input_count = length(invalid_activity_inputs)
    invalid_resource_summary_input_count = length(invalid_resource_summary_inputs)

    valid_activity_count =
      flow_summary_valid_activity_count(
        projected_resources,
        flow_rows,
        report["valid_activity_count"]
      )

    invalid_input_count =
      invalid_activity_input_count + invalid_resource_summary_input_count

    %{
      "schema_contract" => @flow_summary_schema_contract,
      "schema_version" => 1,
      "model" => "artifact_only_selected_activity_resource_flow_summary",
      "source" => get_in(report, ["assumptions", "source"]),
      "activity_count" =>
        derived_activity_count(valid_activity_count, invalid_activity_input_count),
      "valid_activity_count" => valid_activity_count,
      "invalid_activity_input_count" => invalid_activity_input_count,
      "invalid_activity_input_ids" => invalid_row_ids(invalid_activity_inputs, "activity_id"),
      "input_resource_summary_count" =>
        length(projected_resources) + invalid_resource_summary_input_count,
      "valid_resource_summary_count" => length(projected_resources),
      "invalid_resource_summary_input_count" => invalid_resource_summary_input_count,
      "invalid_resource_summary_input_ids" =>
        invalid_row_ids(invalid_resource_summary_inputs, "resource_summary_id"),
      "projected_resource_count" => length(projected_resources),
      "flow_row_count" => length(flow_rows),
      "ignored_activity_count" => length(ignored_flow_rows),
      "ignored_activity_reason_counts" => flow_row_reason_counts(ignored_flow_rows),
      "ignored_activity_ids" => flow_row_activity_ids(ignored_flow_rows),
      "ignored_activity_ids_by_reason" => flow_row_activity_ids_by_reason(ignored_flow_rows),
      "resource_flow_status" =>
        if(
          pressure_resources == [] and invalid_input_count == 0 and
            latency_review_count(flow_rows) == 0,
          do: "clear",
          else: "review_required"
        ),
      "resource_pressure_status" =>
        if(pressure_resources == [], do: "clear", else: "review_required"),
      "resource_pressure_count" => length(pressure_resources),
      "resource_pressure_types" => pressure_types,
      "resource_pressure_spacecraft_ids" => resource_pressure_spacecraft_ids(pressure_resources),
      "resource_pressure_spacecraft_ids_by_type" =>
        resource_pressure_spacecraft_ids_by_type(projected_resources, flow_rows),
      "resource_pressure_activity_ids_by_type" =>
        resource_pressure_activity_ids_by_type(flow_rows),
      "resource_pressure_ground_station_ids_by_type" =>
        resource_pressure_ground_station_ids_by_type(flow_rows),
      "resource_pressure_source_window_ids_by_type" =>
        resource_pressure_source_window_ids_by_type(flow_rows),
      "resource_pressure_station_calendar_entry_ids_by_type" =>
        resource_pressure_station_calendar_entry_ids_by_type(flow_rows),
      "resource_pressure_station_calendar_provider_entry_ids_by_type" =>
        resource_pressure_station_calendar_provider_entry_ids_by_type(flow_rows),
      "total_storage_produced_mb" => sum_flow_field(flow_rows, "storage_produced_mb"),
      "total_planned_downlink_mb" => sum_flow_field(flow_rows, "planned_downlink_mb"),
      "total_storage_limited_downlinked_mb" => sum_flow_field(flow_rows, "downlinked_mb"),
      "total_unused_downlink_capacity_mb" =>
        sum_flow_field(flow_rows, "unused_downlink_capacity_mb"),
      "total_storage_overflow_mb" => sum_flow_field(flow_rows, "storage_overflow_mb"),
      "total_downlink_shortfall_mb" => sum_flow_field(flow_rows, "downlink_shortfall_mb"),
      "total_projected_storage_remaining_mb" =>
        sum_projected_remaining(
          projected_resources,
          "storage_capacity_mb",
          "projected_storage_used_mb"
        ),
      "minimum_projected_storage_remaining_mb" =>
        min_projected_remaining(
          projected_resources,
          "storage_capacity_mb",
          "projected_storage_used_mb"
        ),
      "total_projected_downlink_remaining_mb" =>
        sum_projected_remaining(
          projected_resources,
          "downlink_capacity_mb",
          "estimated_downlink_mb"
        ),
      "minimum_projected_downlink_remaining_mb" =>
        min_projected_remaining(
          projected_resources,
          "downlink_capacity_mb",
          "estimated_downlink_mb"
        ),
      "latency_status" => latency_status(flow_rows),
      "latency_evidence_count" => latency_evidence_count(flow_rows),
      "latency_review_count" => latency_review_count(flow_rows),
      "latency_review_activity_ids" => latency_review_activity_ids(flow_rows),
      "max_planned_latency_s" => max_optional_flow_field(flow_rows, "planned_latency_s"),
      "max_actual_latency_s" => max_optional_flow_field(flow_rows, "actual_latency_s"),
      "total_battery_energy_consumed_wh" =>
        sum_flow_field(flow_rows, "battery_energy_consumed_wh"),
      "total_battery_energy_generated_wh" =>
        sum_flow_field(flow_rows, "battery_energy_generated_wh"),
      "net_battery_energy_delta_wh" => sum_flow_field(flow_rows, "battery_energy_delta_wh"),
      "peak_battery_overuse_wh" => max_flow_field(flow_rows, "battery_overuse_wh"),
      "projected_resources" => Enum.map(projected_resources, &resource_flow_projection_summary/1),
      "activity_resource_flow" => flow_rows,
      "model_limits" => model_limits(),
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "scope" => "selected_activity_resource_flow_and_pressure_evidence",
        "projection_model" => "thin_time_ordered_resource_roll_forward",
        "source" => get_in(report, ["assumptions", "source"]),
        "activity_status_model" =>
          get_in(report, ["assumptions", "activity_status_model"]) ||
            "terminal_or_approval_rejected_activities_are_audited_with_zero_projected_resource_effect",
        "subsystem_simulation" => "not_performed",
        "realized_state_reconciliation" => "not_performed",
        "latency_model" => "declared_activity_timestamps_only"
      }
    }
    |> compact_map()
  end

  def flow_summary(%{schema_contract: @schema_contract} = resource_projection_report) do
    resource_projection_report
    |> stringify_keys()
    |> flow_summary()
  end

  def flow_summary(_resource_projection_report),
    do: raise(ArgumentError, "resource projection report is required")

  defp resource_flow_projection_summary(row) do
    Map.take(row, [
      "spacecraft_id",
      "activity_count",
      "effective_activity_count",
      "ignored_activity_count",
      "ignored_activity_ids",
      "estimated_storage_produced_mb",
      "estimated_downlink_mb",
      "storage_limited_downlinked_mb",
      "unused_downlink_capacity_mb",
      "starting_storage_used_mb",
      "projected_storage_used_mb",
      "storage_capacity_mb",
      "projected_storage_remaining_mb",
      "projected_storage_overflow_mb",
      "downlink_capacity_mb",
      "projected_downlink_remaining_mb",
      "projected_downlink_shortfall_mb",
      "projected_battery_energy_used_wh",
      "projected_battery_state_of_charge",
      "projected_battery_overuse_wh",
      "resource_pressure_status",
      "resource_pressure_types",
      "first_resource_pressure_activity_id",
      "first_resource_pressure_activity_type",
      "first_resource_pressure_kind",
      "first_resource_pressure_starts_at_s",
      "first_resource_pressure_direction",
      "first_resource_pressure_ground_station_id",
      "first_resource_pressure_source_window_id",
      "first_resource_pressure_source_window_type",
      "first_resource_pressure_source_window",
      "first_resource_pressure_station_calendar_entry_id",
      "first_resource_pressure_station_calendar_provider_id",
      "first_resource_pressure_station_calendar_provider_entry_id",
      "first_resource_pressure_station_calendar_directions",
      "first_resource_pressure_capacity_fraction"
    ])
    |> put_projected_remaining(
      "projected_storage_remaining_mb",
      row["storage_capacity_mb"],
      row["projected_storage_used_mb"]
    )
    |> put_projected_remaining(
      "projected_downlink_remaining_mb",
      row["downlink_capacity_mb"],
      row["estimated_downlink_mb"]
    )
  end

  defp put_projected_remaining(row, field, capacity, used_or_demand)
       when is_number(capacity) and is_number(used_or_demand) do
    Map.put(row, field, max(capacity - used_or_demand, 0.0))
  end

  defp put_projected_remaining(row, _field, _capacity, _used_or_demand), do: row

  defp resource_flow_rows(projected_resources) do
    Enum.flat_map(projected_resources, fn projected_resource ->
      spacecraft_id = projected_resource["spacecraft_id"]

      projected_resource
      |> Map.get("activity_resource_flow", [])
      |> Enum.map(&Map.put(&1, "spacecraft_id", spacecraft_id))
    end)
  end

  defp ignored_activity_flow_rows(flow_rows) do
    Enum.filter(flow_rows, &(&1["resource_effect_status"] == "ignored"))
  end

  defp flow_row_activity_ids(flow_rows) do
    flow_rows
    |> Enum.map(& &1["activity_id"])
    |> sorted_stable_ids()
  end

  defp flow_row_reason_counts(flow_rows) do
    flow_rows
    |> Enum.map(& &1["resource_effect_reason"])
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp flow_row_activity_ids_by_reason(flow_rows) do
    flow_rows
    |> Enum.map(&{&1["resource_effect_reason"], &1["activity_id"]})
    |> stable_ids_by_key()
  end

  defp invalid_input_rows(report, field) do
    report
    |> Map.get(field, [])
    |> case do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp invalid_row_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  defp sum_projected_remaining(rows, capacity_field, used_or_demand_field) do
    rows
    |> projected_remaining_values(capacity_field, used_or_demand_field)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp min_projected_remaining(rows, capacity_field, used_or_demand_field) do
    rows
    |> projected_remaining_values(capacity_field, used_or_demand_field)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
  end

  defp projected_remaining_values(rows, capacity_field, used_or_demand_field) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.flat_map(fn row ->
      capacity = row[capacity_field]
      used_or_demand = row[used_or_demand_field]

      if is_number(capacity) and is_number(used_or_demand) do
        [max(capacity - used_or_demand, 0.0)]
      else
        []
      end
    end)
  end

  defp derived_activity_count(valid_activity_count, invalid_activity_input_count)
       when is_integer(valid_activity_count),
       do: valid_activity_count + invalid_activity_input_count

  defp derived_activity_count(valid_activity_count, _invalid_activity_input_count),
    do: valid_activity_count

  defp flow_summary_valid_activity_count(_projected_resources, flow_rows, _report_count)
       when is_list(flow_rows) and flow_rows != [],
       do: length(flow_rows)

  defp flow_summary_valid_activity_count(projected_resources, _flow_rows, report_count)
       when is_list(projected_resources) do
    row_count =
      projected_resources
      |> Enum.map(&Map.get(&1, "activity_count"))
      |> Enum.filter(&is_integer/1)
      |> Enum.sum()

    if row_count > 0, do: row_count, else: report_count
  end

  defp flow_summary_valid_activity_count(_projected_resources, _flow_rows, report_count),
    do: report_count

  defp resource_pressure_row?(row), do: resource_pressure_types([row]) != []

  defp resource_pressure_spacecraft_ids(projected_resources) do
    projected_resources
    |> Enum.map(& &1["spacecraft_id"])
    |> sorted_stable_ids()
  end

  defp resource_pressure_spacecraft_ids_by_type(projected_resources, flow_rows) do
    projected_resource_pairs =
      Enum.flat_map(projected_resources, fn row ->
        row
        |> Map.get("resource_pressure_types", [])
        |> Enum.map(&{&1, row["spacecraft_id"]})
      end)

    flow_row_pairs =
      Enum.flat_map(flow_rows, fn row ->
        Enum.map(resource_pressure_kinds(row), &{&1, row["spacecraft_id"]})
      end)

    (projected_resource_pairs ++ flow_row_pairs)
    |> stable_ids_by_key()
  end

  defp resource_pressure_activity_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(resource_pressure_kinds(row), &{&1, row["activity_id"]})
    end)
    |> stable_ids_by_key()
  end

  defp resource_pressure_ground_station_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(resource_pressure_kinds(row), &{&1, row["ground_station_id"]})
    end)
    |> stable_ids_by_key()
  end

  defp resource_pressure_source_window_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(resource_pressure_kinds(row), &{&1, row["source_window_id"]})
    end)
    |> stable_ids_by_key()
  end

  defp resource_pressure_station_calendar_entry_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(resource_pressure_kinds(row), &{&1, row["station_calendar_entry_id"]})
    end)
    |> stable_ids_by_key()
  end

  defp resource_pressure_station_calendar_provider_entry_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(resource_pressure_kinds(row), &{&1, row["station_calendar_provider_entry_id"]})
    end)
    |> stable_ids_by_key()
  end

  defp sum_flow_field(flow_rows, field) do
    Enum.reduce(flow_rows, 0.0, fn row, total ->
      case Map.get(row, field) do
        value when is_number(value) -> total + value
        _value -> total
      end
    end)
  end

  defp max_flow_field(flow_rows, field) do
    flow_rows
    |> Enum.reduce(0.0, fn row, maximum ->
      case Map.get(row, field) do
        value when is_number(value) -> max(maximum, value)
        _value -> maximum
      end
    end)
  end

  defp max_optional_flow_field(flow_rows, field) do
    flow_rows
    |> Enum.flat_map(fn row ->
      case Map.get(row, field) do
        value when is_number(value) -> [value]
        _value -> []
      end
    end)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  defp latency_status(flow_rows) do
    cond do
      latency_review_count(flow_rows) > 0 -> "review_required"
      latency_evidence_count(flow_rows) > 0 -> "clear"
      true -> nil
    end
  end

  defp latency_evidence_count(flow_rows) do
    Enum.count(flow_rows, fn row ->
      Enum.any?(
        ~w(collection_ends_at_s planned_delivery_at_s actual_delivery_at_s max_latency_s planned_latency_s actual_latency_s),
        &Map.has_key?(row, &1)
      )
    end)
  end

  defp latency_review_count(flow_rows) do
    Enum.count(flow_rows, &(Map.get(&1, "latency_status") == "late"))
  end

  defp latency_review_activity_ids(flow_rows) do
    flow_rows
    |> Enum.filter(&(Map.get(&1, "latency_status") == "late"))
    |> Enum.map(& &1["activity_id"])
    |> sorted_stable_ids()
  end

  defp resource_pressure_types(projected_resources) do
    projection_pressure_types =
      projected_resources
      |> Enum.flat_map(&Map.get(&1, "resource_pressure_types", []))

    flow_pressure_types =
      projected_resources
      |> Enum.flat_map(&Map.get(&1, "activity_resource_flow", []))
      |> Enum.map(&first_resource_pressure_kind/1)
      |> Enum.reject(&is_nil/1)

    (projection_pressure_types ++ flow_pressure_types)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp stable_ids_by_key(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> key end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_stable_ids(values)} end)
  end

  defp sorted_stable_ids(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp normalize_summary_input({summary, index}) when is_map(summary) do
    summary =
      summary
      |> stringify_keys()
      |> normalize_resource_provenance_aliases()
      |> normalize_resource_availability_aliases()
      |> normalize_resource_margin_aliases()
      |> normalize_resource_activity_type_lists()
      |> normalize_resource_summary_numbers()
      |> put_spacecraft_alias()

    case resource_summary_input_issue(summary) do
      nil -> normalize_summary_battery_fields(summary)
      reason -> invalid_resource_summary_input(summary, index, reason)
    end
  end

  defp normalize_summary_input({summary, index}) do
    invalid_resource_summary_input(
      %{"raw_input" => inspect(summary)},
      index,
      "invalid_resource_summary_shape"
    )
  end

  defp resource_summary_input_issue(summary) do
    [
      resource_summary_spacecraft_id_issue(summary),
      resource_summary_non_negative_issue(summary),
      resource_summary_unit_interval_issue(summary),
      resource_summary_derived_margin_issue(summary)
    ]
    |> Enum.find(& &1)
  end

  defp normalize_resource_provenance_aliases(summary) do
    summary
    |> put_resource_provenance_alias("source_quality", @resource_source_quality_aliases)
    |> put_resource_provenance_alias("trust_boundary", @resource_trust_boundary_aliases)
  end

  defp put_resource_provenance_alias(summary, canonical_field, aliases) do
    cond do
      present_value?(Map.get(summary, canonical_field)) ->
        summary

      alias_value = Enum.find_value(aliases, &resource_provenance_alias_value(summary, &1)) ->
        Map.put(summary, canonical_field, alias_value)

      true ->
        summary
    end
  end

  defp resource_provenance_alias_value(summary, path) when is_list(path) do
    summary
    |> get_in(path)
    |> present_value_or_nil()
  end

  defp resource_provenance_alias_value(summary, field) do
    summary
    |> Map.get(field)
    |> present_value_or_nil()
  end

  defp present_value_or_nil(value), do: if(present_value?(value), do: value, else: nil)
  defp present_value?(value), do: value not in [nil, ""]

  defp resource_summary_spacecraft_id_issue(%{"spacecraft_id" => spacecraft_id})
       when spacecraft_id not in [nil, ""] do
    if stable_id?(spacecraft_id), do: nil, else: "invalid_spacecraft_id"
  end

  defp resource_summary_spacecraft_id_issue(_summary), do: nil

  defp put_spacecraft_alias(%{} = summary) do
    case Map.get(summary, "spacecraft_id") || Map.get(summary, "satellite_id") ||
           nested_spacecraft_id(summary) do
      value when value in [nil, ""] -> summary
      value -> Map.put_new(summary, "spacecraft_id", value)
    end
  end

  defp nested_spacecraft_id(summary) do
    Enum.find_value(["spacecraft", "satellite"], fn field ->
      spacecraft_identity_value(Map.get(summary, field))
    end)
  end

  defp spacecraft_identity_value(%{} = spacecraft) do
    Enum.find_value(["spacecraft_id", "satellite_id", "id"], fn field ->
      spacecraft_identity_value(Map.get(spacecraft, field))
    end)
  end

  defp spacecraft_identity_value(value), do: value

  defp resource_summary_non_negative_issue(summary) do
    Enum.find_value(
      ~w(battery_capacity_wh battery_energy_used_wh storage_capacity_mb storage_used_mb downlink_capacity_mb),
      fn field ->
        case Map.get(summary, field) do
          value when is_number(value) and value < 0.0 -> "negative_#{field}"
          value when is_number(value) or is_nil(value) -> nil
          _value -> "invalid_#{field}"
        end
      end
    )
  end

  defp resource_summary_unit_interval_issue(summary) do
    Enum.find_value(
      ~w(fuel_margin power_margin battery_state_of_charge storage_margin downlink_margin),
      fn field ->
        case Map.get(summary, field) do
          value when is_number(value) and value >= 0.0 and value <= 1.0 -> nil
          value when is_number(value) -> "invalid_#{field}"
          nil -> nil
          _value -> "invalid_#{field}"
        end
      end
    )
  end

  defp resource_summary_derived_margin_issue(summary) do
    resource_summary_derived_margin_issue(
      summary,
      "battery_state_of_charge",
      "battery_capacity_wh",
      "battery_energy_used_wh"
    ) ||
      resource_summary_derived_margin_issue(
        summary,
        "storage_margin",
        "storage_capacity_mb",
        "storage_used_mb"
      )
  end

  defp resource_summary_derived_margin_issue(summary, margin_field, capacity_field, used_field) do
    margin = Map.get(summary, margin_field)
    capacity = Map.get(summary, capacity_field)
    used = Map.get(summary, used_field)

    if is_number(margin) and is_number(capacity) and capacity > 0 and is_number(used) do
      expected = max((capacity - used) / capacity, 0.0)

      if abs(margin - expected) <= 1.0e-9 do
        nil
      else
        "stale_#{margin_field}"
      end
    end
  end

  defp invalid_resource_summary_input(summary, index, reason) do
    resource_summary_id = invalid_resource_summary_id(summary, index)

    %{
      "id" => "resource_projection:invalid_resource_summary:#{resource_summary_id}",
      "resource_summary_id" => resource_summary_id,
      "spacecraft_id" => stable_id_or_nil(summary["spacecraft_id"]),
      "required_operator_action" => "review_invalid_resource_projection_summary",
      "approval_status" => "operator_review_required",
      "review_status" => "operator_review_required",
      "invalid_resource_summary_input" => true,
      "invalid_resource_summary_input_reason" => reason,
      "source_resource_summary" => summary
    }
    |> compact_map()
  end

  defp invalid_resource_summary_id(%{"spacecraft_id" => spacecraft_id}, index)
       when spacecraft_id not in [nil, ""] do
    stable_id_or_nil(spacecraft_id) || "resource_summary:#{index}"
  end

  defp invalid_resource_summary_id(_summary, index), do: "resource_summary:#{index}"

  defp invalid_resource_summary_input?(%{"invalid_resource_summary_input" => true}), do: true
  defp invalid_resource_summary_input?(_summary), do: false

  defp split_review_gated_resource_summary_scopes(summaries) do
    summary_counts = Enum.frequencies_by(summaries, &resource_summary_scope_key/1)
    summary_count = length(summaries)

    summaries
    |> Enum.reduce({[], [], %{}}, fn summary, {invalid, valid, duplicate_indexes} ->
      key = resource_summary_scope_key(summary)
      count = Map.fetch!(summary_counts, key)

      cond do
        count > 1 ->
          index = Map.get(duplicate_indexes, key, 0) + 1
          duplicate = duplicate_resource_summary_input(summary, key, index, count)

          {[duplicate | invalid], valid, Map.put(duplicate_indexes, key, index)}

        mixed_wildcard_resource_summary_scope?(key, summary_count) ->
          invalid_summary = mixed_wildcard_resource_summary_input(summary)

          {[invalid_summary | invalid], valid, duplicate_indexes}

        true ->
          {invalid, [summary | valid], duplicate_indexes}
      end
    end)
    |> then(fn {invalid, valid, _duplicate_indexes} ->
      {Enum.reverse(invalid), Enum.reverse(valid)}
    end)
  end

  defp resource_summary_scope_key(%{"spacecraft_id" => spacecraft_id})
       when spacecraft_id not in [nil, ""],
       do: spacecraft_id

  defp resource_summary_scope_key(_summary), do: "*"

  defp duplicate_resource_summary_input(summary, key, index, count) do
    resource_summary_id = duplicate_resource_summary_id(key, index)

    %{
      "id" => "resource_projection:invalid_resource_summary:#{resource_summary_id}",
      "resource_summary_id" => resource_summary_id,
      "spacecraft_id" => stable_id_or_nil(summary["spacecraft_id"]),
      "required_operator_action" => "review_invalid_resource_projection_summary",
      "approval_status" => "operator_review_required",
      "review_status" => "operator_review_required",
      "invalid_resource_summary_input" => true,
      "invalid_resource_summary_input_reason" => "duplicate_resource_summary_scope",
      "duplicate_resource_summary_scope" => true,
      "resource_summary_key" => duplicate_resource_summary_key(key),
      "duplicate_resource_summary_index" => index,
      "duplicate_resource_summary_count" => count,
      "source_resource_summary" => summary
    }
    |> compact_map()
  end

  defp duplicate_resource_summary_id("*", index), do: "all_spacecraft:duplicate:#{index}"
  defp duplicate_resource_summary_id(key, index), do: "#{key}:duplicate:#{index}"

  defp duplicate_resource_summary_key("*"), do: "all_spacecraft"
  defp duplicate_resource_summary_key(key), do: key

  defp mixed_wildcard_resource_summary_scope?("*", summary_count), do: summary_count > 1
  defp mixed_wildcard_resource_summary_scope?(_key, _summary_count), do: false

  defp mixed_wildcard_resource_summary_input(summary) do
    resource_summary_id = "all_spacecraft:mixed_scope"

    %{
      "id" => "resource_projection:invalid_resource_summary:#{resource_summary_id}",
      "resource_summary_id" => resource_summary_id,
      "required_operator_action" => "review_invalid_resource_projection_summary",
      "approval_status" => "operator_review_required",
      "review_status" => "operator_review_required",
      "invalid_resource_summary_input" => true,
      "invalid_resource_summary_input_reason" => "mixed_wildcard_resource_summary_scope",
      "mixed_wildcard_resource_summary_scope" => true,
      "resource_summary_key" => "all_spacecraft",
      "source_resource_summary" => summary
    }
    |> compact_map()
  end

  defp normalize_summary_battery_fields(summary) do
    battery_capacity_wh = Map.get(summary, "battery_capacity_wh")
    battery_energy_used_wh = Map.get(summary, "battery_energy_used_wh")
    battery_state_of_charge = Map.get(summary, "battery_state_of_charge")

    derived_state_of_charge =
      cond do
        is_number(battery_state_of_charge) ->
          battery_state_of_charge * 1.0

        is_number(battery_capacity_wh) and battery_capacity_wh > 0 and
            is_number(battery_energy_used_wh) ->
          ((battery_capacity_wh - battery_energy_used_wh) / battery_capacity_wh)
          |> max(0.0)
          |> min(1.0)

        true ->
          nil
      end

    summary
    |> maybe_put("battery_state_of_charge", derived_state_of_charge)
    |> maybe_put("power_margin", Map.get(summary, "power_margin") || derived_state_of_charge)
  end

  defp normalize_resource_summary_numbers(summary) do
    summary
    |> normalize_number_fields(~w(
      battery_capacity_wh
      battery_energy_used_wh
      storage_capacity_mb
      storage_used_mb
      downlink_capacity_mb
      fuel_margin
      power_margin
      battery_state_of_charge
      storage_margin
      downlink_margin
    ))
  end

  defp normalize_resource_availability_aliases(summary) do
    summary
    |> copy_resource_availability_aliases(@resource_availability_value_aliases)
    |> copy_resource_availability_status_aliases(@resource_availability_status_aliases)
    |> copy_resource_availability_aliases(%{"degraded" => @resource_degraded_aliases})
    |> normalize_resource_availability_boolean_values()
  end

  defp normalize_resource_margin_aliases(summary) do
    Enum.reduce(@resource_margin_aliases, summary, fn {canonical_key, aliases}, acc ->
      Enum.reduce(aliases, acc, fn alias_key, acc ->
        copy_resource_margin_alias(acc, canonical_key, alias_key)
      end)
    end)
  end

  defp copy_resource_margin_alias(summary, canonical_key, alias_key) do
    case {Map.get(summary, canonical_key), Map.get(summary, alias_key)} do
      {nil, value} when value not in [nil, ""] -> Map.put(summary, canonical_key, value)
      _values -> summary
    end
  end

  defp normalize_resource_activity_type_lists(summary) do
    summary
    |> normalize_resource_activity_type_list("suppressed_activity_types")
    |> normalize_resource_activity_type_list("incompatible_activity_types")
  end

  defp normalize_resource_activity_type_list(summary, field) do
    case resource_activity_type_list(Map.get(summary, field)) do
      [] -> Map.delete(summary, field)
      values -> Map.put(summary, field, values)
    end
  end

  defp resource_activity_type_list(values) when is_list(values) do
    values
    |> Enum.flat_map(&resource_activity_type_list/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resource_activity_type_list(%{} = value) do
    ["type", "activity_type", "direction"]
    |> Enum.flat_map(&resource_activity_type_list(Map.get(value, &1)))
  end

  defp resource_activity_type_list(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&normalize_resource_activity_token/1)
    |> Enum.reject(&is_nil/1)
  end

  defp resource_activity_type_list(nil), do: []

  defp resource_activity_type_list(value) when is_atom(value),
    do: value |> Atom.to_string() |> resource_activity_type_list()

  defp resource_activity_type_list(_value), do: []

  defp normalize_resource_activity_token(value) when is_binary(value) do
    value
    |> normalized_direction_token()
    |> case do
      nil ->
        nil

      token when is_map_key(@resource_activity_type_aliases, token) ->
        Map.fetch!(@resource_activity_type_aliases, token)

      token ->
        token
    end
  end

  defp normalized_direction_token(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
    |> case do
      "" -> nil
      "nil" -> nil
      token -> token
    end
  end

  defp activity_type_suppressed?(_activity, values) when values in [nil, []], do: false

  defp activity_type_suppressed?(activity, values) when is_list(values) do
    activity
    |> resource_activity_tokens()
    |> Enum.any?(&(&1 in values))
  end

  defp activity_type_suppressed?(_activity, _values), do: false

  defp resource_activity_tokens(activity) do
    [
      activity["type"],
      activity["direction"],
      resource_direction(activity)
    ]
    |> Enum.flat_map(&resource_activity_type_list/1)
    |> Enum.uniq()
  end

  defp normalize_resource_availability_boolean_values(summary) do
    Enum.reduce(
      ["payload_available", "antenna_available", "spacecraft_available", "degraded"],
      summary,
      fn field, acc ->
        case resource_availability_boolean_value(Map.get(acc, field)) do
          value when is_boolean(value) -> Map.put(acc, field, value)
          nil -> acc
        end
      end
    )
  end

  defp copy_resource_availability_alias(summary, canonical_key, alias_key) do
    summary =
      if Map.has_key?(summary, canonical_key) or not Map.has_key?(summary, alias_key) do
        summary
      else
        Map.put(summary, canonical_key, Map.get(summary, alias_key))
      end

    Map.delete(summary, alias_key)
  end

  defp copy_resource_availability_aliases(summary, aliases_by_field) do
    Enum.reduce(aliases_by_field, summary, fn {canonical_key, aliases}, acc ->
      Enum.reduce(aliases, acc, fn alias_key, acc ->
        copy_resource_availability_alias(acc, canonical_key, alias_key)
      end)
    end)
  end

  defp copy_resource_availability_status_alias(summary, canonical_key, alias_key) do
    alias_value = resource_availability_boolean_value(Map.get(summary, alias_key))

    if Map.has_key?(summary, canonical_key) or not is_boolean(alias_value) do
      summary
    else
      Map.put(summary, canonical_key, alias_value)
    end
  end

  defp copy_resource_availability_status_aliases(summary, aliases_by_field) do
    Enum.reduce(aliases_by_field, summary, fn {canonical_key, aliases}, acc ->
      Enum.reduce(aliases, acc, fn alias_key, acc ->
        copy_resource_availability_status_alias(acc, canonical_key, alias_key)
      end)
    end)
  end

  defp resource_availability_boolean_value(value) when is_boolean(value), do: value

  defp resource_availability_boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp resource_availability_boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      value when value in @resource_availability_true_tokens -> true
      value when value in @resource_availability_false_tokens -> false
      _value -> nil
    end
  end

  defp resource_availability_boolean_value(_value), do: nil

  defp normalize_number_fields(map, fields) do
    Enum.reduce(fields, map, fn field, acc ->
      if Map.has_key?(acc, field) do
        case numeric_or_nil(Map.get(acc, field)) do
          value when is_number(value) -> Map.put(acc, field, value)
          _value -> acc
        end
      else
        acc
      end
    end)
  end

  defp normalize_activity_input({activity, index}) when is_map(activity) do
    activity
    |> stringify_keys()
    |> put_ground_station_alias()
    |> put_time_alias("starts_at_s", "start_s")
    |> put_time_alias("ends_at_s", "end_s")
    |> put_source_window()
    |> put_activity_type_alias()
    |> put_provider_direction_alias()
    |> put_station_calendar_directions()
    |> put_provider_downlink_shape()
    |> maybe_invalid_activity_input(index)
  end

  defp normalize_activity_input({activity, index}) do
    invalid_activity_input(
      %{"raw_input" => inspect(activity)},
      index,
      "invalid_activity_shape"
    )
  end

  defp maybe_invalid_activity_input(activity, index) do
    cond do
      reason = activity_id_issue(activity["id"]) ->
        invalid_activity_input(activity, index, reason)

      not valid_activity_type?(activity) ->
        invalid_activity_input(activity, index, "missing_activity_type")

      reason = activity_identity_issue(activity) ->
        invalid_activity_input(activity, index, reason)

      reason = activity_completed_fraction_issue(activity) ->
        invalid_activity_input(activity, index, reason)

      reason = activity_capacity_fraction_issue(activity) ->
        invalid_activity_input(activity, index, reason)

      reason = activity_latency_evidence_issue(activity) ->
        invalid_activity_input(activity, index, reason)

      reason = activity_resource_quantity_issue(activity) ->
        invalid_activity_input(activity, index, reason)

      true ->
        activity
    end
  end

  defp invalid_activity_input(activity, index, reason) do
    activity_id = invalid_activity_id(activity, index, reason)

    %{
      "id" => "resource_projection:invalid_activity_input:#{activity_id}",
      "activity_id" => activity_id,
      "activity_ids" => [activity_id],
      "type" => activity["type"],
      "scenario_id" =>
        stable_id_or_nil(activity["scenario_id"]) || stable_id_or_nil(activity["spacecraft_id"]) ||
          "missing_scenario_id:#{activity_id}",
      "spacecraft_id" => stable_id_or_nil(activity["spacecraft_id"]),
      "source_window_id" => stable_id_or_nil(activity["source_window_id"]),
      "source_window_type" => activity["source_window_type"],
      "source_window" => activity["source_window"],
      "ground_station_id" => stable_id_or_nil(activity["ground_station_id"]),
      "target_id" => stable_id_or_nil(activity["target_id"]),
      "starts_at_s" => activity["starts_at_s"],
      "ends_at_s" => activity["ends_at_s"],
      "required_operator_action" => "review_invalid_resource_projection_input",
      "approval_status" => "operator_review_required",
      "review_status" => "operator_review_required",
      "invalid_activity_input" => true,
      "invalid_activity_input_reason" => reason,
      "source_activity" => activity
    }
    |> compact_map()
  end

  defp invalid_activity_id(activity, index, reason) do
    case activity["id"] do
      value when is_binary(value) and value != "" ->
        stable_id_or_nil(value) || "#{reason}:#{index}"

      value when is_atom(value) and not is_nil(value) ->
        stable_id_or_nil(value) || "#{reason}:#{index}"

      value when is_integer(value) ->
        stable_id_or_nil(value) || "#{reason}:#{index}"

      _value ->
        "#{reason}:#{index}"
    end
  end

  defp invalid_activity_input?(%{"invalid_activity_input" => true}), do: true
  defp invalid_activity_input?(_activity), do: false

  defp activity_id_issue(id) when id in [nil, ""], do: "missing_activity_id"
  defp activity_id_issue(id), do: if(stable_id?(id), do: nil, else: "invalid_activity_id")

  defp activity_identity_issue(activity) do
    Enum.find_value(@activity_stable_identity_fields, fn field ->
      value = Map.get(activity, field)

      cond do
        value in [nil, ""] -> nil
        stable_id?(value) -> nil
        true -> "invalid_#{field}"
      end
    end)
  end

  defp activity_completed_fraction_issue(activity) do
    activity
    |> activity_completed_fraction_values()
    |> Enum.find_value(fn {field, value} ->
      case numeric_or_nil(value) do
        parsed when is_number(parsed) and parsed >= 0.0 and parsed <= 1.0 -> nil
        _value -> "invalid_#{field}"
      end
    end)
  end

  defp activity_completed_fraction_values(activity) do
    top_level =
      for field <- ~w(completed_fraction completion_fraction),
          Map.has_key?(activity, field),
          do: {field, Map.get(activity, field)}

    metadata = Map.get(activity, "metadata")

    nested =
      if is_map(metadata) do
        for field <- ~w(completed_fraction completion_fraction),
            Map.has_key?(metadata, field),
            do: {field, Map.get(metadata, field)}
      else
        []
      end

    top_level ++ nested
  end

  defp activity_capacity_fraction_issue(activity) do
    activity
    |> activity_capacity_evidence_values()
    |> Enum.find_value(fn
      {:fraction, field, value} ->
        case numeric_or_nil(value) do
          parsed when is_number(parsed) and parsed >= 0.0 and parsed <= 1.0 -> nil
          _value -> "invalid_#{field}"
        end

      {:percent, field, value} ->
        case numeric_or_nil(value) do
          parsed when is_number(parsed) and parsed >= 0.0 and parsed <= 100.0 -> nil
          _value -> "invalid_#{field}"
        end
    end)
  end

  defp activity_capacity_evidence_values(activity) do
    [
      activity,
      activity["throughput_model"],
      activity["capacity_model"],
      activity["activity_context"]
    ]
    |> Enum.flat_map(&capacity_evidence_values/1)
    |> Kernel.++(capacity_evidence_values(activity["source_station_calendar_entry"]))
    |> Kernel.++(capacity_evidence_values(activity["source_station_calendar_overlaps"]))
  end

  defp capacity_evidence_values(values) when is_list(values),
    do: Enum.flat_map(values, &capacity_evidence_values/1)

  defp capacity_evidence_values(%{} = values) do
    fraction_values =
      for field <- ~w(station_capacity_fraction capacity_fraction),
          Map.has_key?(values, field),
          do: {:fraction, field, Map.get(values, field)}

    allocation_fraction_values =
      for field <- ~w(capacity_pack_capacity_fraction),
          Map.has_key?(values, field),
          do: {:fraction, field, Map.get(values, field)}

    percent_values =
      for field <- ~w(station_capacity_percent capacity_percent),
          Map.has_key?(values, field),
          do: {:percent, field, Map.get(values, field)}

    nested_values =
      [values["throughput_model"], values["capacity_model"], values["activity_context"]]
      |> Enum.flat_map(&capacity_evidence_values/1)

    fraction_values ++ allocation_fraction_values ++ percent_values ++ nested_values
  end

  defp capacity_evidence_values(_values), do: []

  defp activity_latency_evidence_issue(activity) do
    activity
    |> activity_latency_evidence_values()
    |> Enum.find_value(fn {field, value, validation} ->
      case numeric_or_nil(value) do
        parsed when is_number(parsed) and validation == :non_negative and parsed < 0.0 ->
          "negative_#{field}"

        parsed when is_number(parsed) ->
          nil

        nil when is_nil(value) ->
          nil

        _value ->
          "invalid_#{field}"
      end
    end)
  end

  defp activity_latency_evidence_values(activity) do
    top_level = latency_evidence_values(activity)
    metadata = latency_evidence_values(activity["metadata"])

    top_level ++ metadata
  end

  defp latency_evidence_values(%{} = values) do
    time_values =
      for field <-
            ~w(collection_ends_at_s collection_end_s planned_delivery_at_s expected_delivery_at_s delivery_at_s actual_delivery_at_s delivered_at_s),
          Map.has_key?(values, field),
          do: {field, Map.get(values, field), :number}

    duration_values =
      for field <- ~w(max_latency_s latency_requirement_s planned_latency_s actual_latency_s),
          Map.has_key?(values, field),
          do: {field, Map.get(values, field), :non_negative}

    time_values ++ duration_values
  end

  defp latency_evidence_values(_values), do: []

  defp activity_resource_quantity_issue(activity) do
    activity
    |> activity_resource_quantity_values()
    |> Enum.find_value(fn {field, value} ->
      case numeric_or_nil(value) do
        parsed when is_number(parsed) and parsed < 0.0 -> "negative_#{field}"
        parsed when is_number(parsed) -> nil
        nil when is_nil(value) -> nil
        _value -> "invalid_#{field}"
      end
    end)
  end

  defp activity_resource_quantity_values(activity) do
    top_level =
      for field <- activity_resource_quantity_fields(),
          Map.has_key?(activity, field),
          do: {field, Map.get(activity, field)}

    metadata = nested_activity_resource_quantity_values(activity, "metadata")
    throughput_model = nested_activity_resource_quantity_values(activity, "throughput_model")

    top_level ++ metadata ++ throughput_model
  end

  defp nested_activity_resource_quantity_values(activity, key) do
    case Map.get(activity, key) do
      %{} = values ->
        for field <- activity_resource_quantity_fields(),
            Map.has_key?(values, field),
            do: {field, Map.get(values, field)}

      _values ->
        []
    end
  end

  defp activity_resource_quantity_fields do
    ~w(
      estimated_storage_mb
      planned_data_volume_mb
      data_volume_mb
      estimated_data_volume_mb
      capacity_adjusted_throughput_mb
      estimated_throughput_mb
      estimated_downlink_mb
      planned_throughput_mb
      estimated_energy_used_wh
      estimated_battery_energy_used_wh
      planned_energy_used_wh
      battery_energy_used_wh
      estimated_energy_generated_wh
      estimated_battery_energy_generated_wh
      planned_energy_generated_wh
      battery_energy_generated_wh
    )
  end

  defp stable_id?(value) when is_atom(value) and not is_nil(value) do
    value
    |> Atom.to_string()
    |> stable_id?()
  end

  defp stable_id?("nil"), do: false
  defp stable_id?(value) when is_binary(value), do: Regex.match?(@stable_id_pattern, value)
  defp stable_id?(value) when is_integer(value), do: value |> Integer.to_string() |> stable_id?()
  defp stable_id?(_value), do: false

  defp stable_id_or_nil(nil), do: nil
  defp stable_id_or_nil("nil"), do: nil
  defp stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  defp stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  defp stable_id_or_nil(_value), do: nil

  defp valid_activity_type?(%{"type" => type}) when is_binary(type) and type != "", do: true

  defp valid_activity_type?(%{"direction" => "downlink", "ground_station_id" => station_id})
       when not is_nil(station_id),
       do: true

  defp valid_activity_type?(_activity), do: false

  defp put_ground_station_alias(%{"ground_station_id" => station_id} = activity)
       when not is_nil(station_id),
       do: activity

  defp put_ground_station_alias(%{"station_id" => station_id} = activity)
       when not is_nil(station_id),
       do: Map.put(activity, "ground_station_id", station_id)

  defp put_ground_station_alias(activity) do
    case nested_station_id(activity) do
      nil -> activity
      station_id -> Map.put(activity, "ground_station_id", station_id)
    end
  end

  defp nested_station_id(activity) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(activity, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp put_time_alias(activity, canonical_key, alternate_key) do
    case numeric_or_nil(Map.get(activity, canonical_key)) ||
           numeric_or_nil(Map.get(activity, alternate_key)) do
      value when is_number(value) -> Map.put(activity, canonical_key, value)
      _value -> activity
    end
  end

  defp put_source_window(%{"source_window" => %{} = source_window} = activity) do
    source_window = normalize_source_window_payload(source_window)

    activity
    |> Map.put("source_window", source_window)
    |> put_new_present("source_window_id", source_window_id_value(source_window))
    |> put_new_present("source_window_type", source_window_type_value(source_window))
    |> put_new_present("source_window_type", Map.get(activity, "source_window_kind"))
  end

  defp put_source_window(%{"metadata" => %{"source_window" => %{} = source_window}} = activity) do
    source_window = normalize_source_window_payload(source_window)

    activity
    |> Map.put("source_window", source_window)
    |> put_new_present("source_window_id", source_window_id_value(source_window))
    |> put_new_present("source_window_type", source_window_type_value(source_window))
    |> put_new_present("source_window_type", get_in(activity, ["metadata", "source_window_kind"]))
  end

  defp put_source_window(
         %{"activity_context" => %{"source_window" => %{} = source_window}} = activity
       ) do
    source_window = normalize_source_window_payload(source_window)

    activity
    |> Map.put("source_window", source_window)
    |> put_new_present("source_window_id", source_window_id_value(source_window))
    |> put_new_present("source_window_type", source_window_type_value(source_window))
    |> put_new_present(
      "source_window_type",
      get_in(activity, ["activity_context", "source_window_kind"])
    )
  end

  defp put_source_window(activity) do
    activity
    |> put_new_present("source_window_type", Map.get(activity, "source_window_kind"))
    |> put_new_present("source_window_type", get_in(activity, ["metadata", "source_window_kind"]))
    |> put_new_present(
      "source_window_type",
      get_in(activity, ["activity_context", "source_window_kind"])
    )
  end

  defp normalize_source_window_payload(source_window) do
    source_window
    |> put_new_present("id", source_window_id_value(source_window))
    |> put_new_present("type", source_window_type_value(source_window))
  end

  defp source_window_id_value(%{} = source_window) do
    Map.get(source_window, "id") || Map.get(source_window, "window_id")
  end

  defp source_window_type_value(%{} = source_window) do
    Map.get(source_window, "type") || Map.get(source_window, "kind") ||
      Map.get(source_window, "window_type")
  end

  defp put_new_present(activity, _key, value) when value in [nil, ""], do: activity
  defp put_new_present(activity, key, value), do: Map.put_new(activity, key, value)

  defp put_provider_downlink_shape(activity) do
    if provider_downlink_activity?(activity) do
      activity
      |> Map.put_new("type", "downlink")
      |> Map.put_new("direction", "downlink")
    else
      activity
    end
  end

  defp put_activity_type_alias(%{"type" => type} = activity) when not is_nil(type),
    do: activity

  defp put_activity_type_alias(%{"activity_type" => type} = activity)
       when is_binary(type) and type != "",
       do: Map.put(activity, "type", type)

  defp put_activity_type_alias(activity), do: activity

  defp put_provider_direction_alias(%{"direction" => direction} = activity) do
    case normalize_provider_direction(direction) do
      nil -> activity
      direction -> Map.put(activity, "direction", direction)
    end
  end

  defp put_provider_direction_alias(activity), do: activity

  defp normalize_provider_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_provider_direction(direction) do
    direction
    |> normalized_direction_token()
    |> case do
      nil -> nil
      token -> Map.get(@provider_direction_aliases, token, token)
    end
  end

  defp put_station_calendar_directions(activity) do
    case station_calendar_directions(activity) do
      [] -> activity
      directions -> Map.put(activity, "station_calendar_directions", directions)
    end
  end

  defp station_calendar_directions(activity) do
    [
      Map.get(activity, "station_calendar_directions"),
      Map.get(activity, "station_calendar_direction"),
      get_in(activity, ["source_station_calendar_entry", "station_calendar_directions"]),
      get_in(activity, ["source_station_calendar_entry", "directions"]),
      get_in(activity, ["source_station_calendar_entry", "direction"]),
      source_station_calendar_values(activity["source_station_calendar_overlaps"], [
        "station_calendar_directions",
        "directions",
        "direction"
      ])
    ]
    |> List.flatten()
    |> Enum.map(&normalize_station_calendar_direction/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalize_station_calendar_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_station_calendar_direction(direction) do
    direction
    |> normalized_direction_token()
    |> case do
      nil -> nil
      token -> Map.get(@station_calendar_direction_aliases, token, token)
    end
  end

  defp provider_downlink_activity?(activity) do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")
    direction = Map.get(activity, "direction")

    type in [nil, "contact", "planned_contact"] and
      direction in [nil, "downlink"] and
      not command_feedback_activity?(activity) and
      not is_nil(Map.get(activity, "ground_station_id")) and
      is_number(Map.get(activity, "starts_at_s")) and
      is_number(Map.get(activity, "ends_at_s"))
  end

  defp command_feedback_activity?(activity) do
    Map.has_key?(activity, "command_success") or Map.has_key?(activity, "command_result")
  end

  defp resource_projection_row(summary, activities, summary_count) do
    matched_activities =
      summary
      |> resource_projection_activities(activities, summary_count)
      |> Enum.sort_by(&activity_sort_key/1)

    resource_effect_context = resource_effect_context(summary)
    spacecraft_available = resource_effect_context["spacecraft_available"]

    effective_activities =
      Enum.filter(matched_activities, &project_resource_effect?(&1, resource_effect_context))

    observations = Enum.filter(effective_activities, &(&1["type"] == "observe"))
    downlinks = Enum.filter(effective_activities, &downlink_activity?/1)

    storage_capacity_mb = Map.get(summary, "storage_capacity_mb")
    downlink_capacity_mb = Map.get(summary, "downlink_capacity_mb")
    starting_storage_used_mb = starting_storage_used_mb(summary)
    battery_capacity_wh = Map.get(summary, "battery_capacity_wh")
    starting_battery_energy_used_wh = starting_battery_energy_used_wh(summary)

    activity_resource_flow =
      activity_resource_flow(
        matched_activities,
        starting_storage_used_mb,
        storage_capacity_mb,
        downlink_capacity_mb,
        starting_battery_energy_used_wh,
        battery_capacity_wh,
        resource_effect_context
      )

    storage_produced_mb =
      observations
      |> Enum.map(&estimated_storage_mb/1)
      |> Enum.sum()

    downlinked_mb =
      downlinks
      |> Enum.map(&resource_projection_downlink_mb/1)
      |> Enum.sum()

    storage_limited_downlinked_mb =
      activity_resource_flow
      |> Enum.map(&Map.get(&1, "downlinked_mb", 0.0))
      |> Enum.sum()

    unused_downlink_capacity_mb =
      unused_downlink_capacity_mb(downlinked_mb, storage_limited_downlinked_mb)

    projected_storage_used_mb =
      activity_resource_flow
      |> List.last(%{})
      |> Map.get(
        "storage_used_after_mb",
        projected_storage_used_mb(starting_storage_used_mb, storage_produced_mb, downlinked_mb)
      )

    projected_storage_margin =
      projected_storage_margin(storage_capacity_mb, projected_storage_used_mb, summary)

    projected_storage_overflow_mb =
      projected_storage_overflow_mb(storage_capacity_mb, projected_storage_used_mb)

    projected_downlink_margin =
      projected_downlink_margin(downlink_capacity_mb, downlinked_mb, summary)

    projected_downlink_shortfall_mb =
      projected_downlink_shortfall_mb(downlink_capacity_mb, downlinked_mb)

    projected_battery_energy_used_wh =
      activity_resource_flow
      |> List.last(%{})
      |> Map.get(
        "battery_energy_used_after_wh",
        projected_battery_energy_used_wh(
          starting_battery_energy_used_wh,
          activity_resource_flow
        )
      )

    projected_battery_state_of_charge =
      projected_battery_state_of_charge(battery_capacity_wh, projected_battery_energy_used_wh)

    projected_battery_overuse_wh =
      projected_battery_overuse_wh(battery_capacity_wh, projected_battery_energy_used_wh)

    resource_pressure_types =
      resource_pressure_types(
        projected_storage_overflow_mb,
        projected_downlink_shortfall_mb,
        projected_battery_overuse_wh,
        Map.get(summary, "thermal_margin_c"),
        activity_resource_flow,
        spacecraft_available
      )

    ignored_activity_ids =
      activity_resource_flow
      |> Enum.filter(&(&1["resource_effect_status"] == "ignored"))
      |> Enum.map(& &1["activity_id"])
      |> Enum.reject(&is_nil/1)

    %{
      "spacecraft_id" => projection_spacecraft_id(summary, summary_count),
      "activity_count" => length(matched_activities),
      "effective_activity_count" => length(effective_activities),
      "ignored_activity_count" => length(ignored_activity_ids),
      "ignored_activity_ids" => ignored_activity_ids,
      "observation_count" => length(observations),
      "downlink_count" => length(downlinks),
      "estimated_storage_produced_mb" => storage_produced_mb,
      "estimated_downlink_mb" => downlinked_mb,
      "storage_limited_downlinked_mb" => storage_limited_downlinked_mb,
      "unused_downlink_capacity_mb" => unused_downlink_capacity_mb,
      "activity_resource_flow" => activity_resource_flow,
      "starting_storage_used_mb" => starting_storage_used_mb,
      "projected_storage_used_mb" => projected_storage_used_mb,
      "storage_capacity_mb" => storage_capacity_mb,
      "starting_storage_margin" => Map.get(summary, "storage_margin"),
      "projected_storage_margin" => projected_storage_margin,
      "projected_storage_overflow_mb" => projected_storage_overflow_mb,
      "downlink_capacity_mb" => downlink_capacity_mb,
      "starting_downlink_margin" => Map.get(summary, "downlink_margin"),
      "projected_downlink_margin" => projected_downlink_margin,
      "projected_downlink_shortfall_mb" => projected_downlink_shortfall_mb,
      "resource_pressure_status" => resource_pressure_status(resource_pressure_types),
      "resource_pressure_types" => resource_pressure_types,
      "resource_source_quality" => Map.get(summary, "source_quality") || "unknown",
      "resource_trust_boundary" => resource_trust_boundary(summary),
      "resource_trust_boundary_status" => resource_trust_boundary_status(summary),
      "resource_provenance" => summary["provenance"],
      "fuel_margin" => Map.get(summary, "fuel_margin"),
      "power_margin" => Map.get(summary, "power_margin"),
      "thermal_margin_c" => Map.get(summary, "thermal_margin_c"),
      "projected_power_margin" =>
        projected_battery_state_of_charge || Map.get(summary, "power_margin"),
      "battery_capacity_wh" => battery_capacity_wh,
      "battery_energy_used_wh" => Map.get(summary, "battery_energy_used_wh"),
      "battery_state_of_charge" => Map.get(summary, "battery_state_of_charge"),
      "starting_battery_energy_used_wh" => starting_battery_energy_used_wh,
      "projected_battery_energy_used_wh" => projected_battery_energy_used_wh,
      "projected_battery_state_of_charge" => projected_battery_state_of_charge,
      "projected_battery_overuse_wh" => projected_battery_overuse_wh,
      "spacecraft_available" => spacecraft_available,
      "payload_available" => resource_effect_context["payload_available"],
      "antenna_available" => resource_effect_context["antenna_available"],
      "degraded" => resource_effect_context["degraded"],
      "mode" => resource_effect_context["mode"],
      "incompatible_activity_types" => resource_effect_context["incompatible_activity_types"],
      "suppressed_activity_types" => resource_effect_context["suppressed_activity_types"],
      "warnings" =>
        resource_projection_warnings(
          summary,
          storage_capacity_mb,
          downlink_capacity_mb,
          projected_storage_overflow_mb,
          projected_downlink_shortfall_mb,
          projected_battery_overuse_wh,
          unused_downlink_capacity_mb,
          resource_pressure_types
        )
    }
    |> Map.merge(first_resource_pressure_event(activity_resource_flow))
    |> compact_map()
  end

  defp maybe_apply_approval_policy(rows, nil), do: rows

  defp maybe_apply_approval_policy(rows, approval_policy) do
    Enum.map(rows, fn row ->
      risks = resource_pressure_risks(row)

      if risks == [] do
        row
      else
        requirements = resource_projection_approval_requirements(row, risks)

        {status, requirements, rule_matches, decision} =
          Policy.decide(
            requirements,
            risks,
            %{"id" => "resource_projection", "events" => []},
            %{},
            approval_policy
          )

        row
        |> Map.put("approval_status", status)
        |> Map.put("approval_requirements", requirements)
        |> Map.put("approval_rule_matches", rule_matches)
        |> Map.put("policy_decision", decision)
      end
    end)
  end

  defp maybe_apply_invalid_activity_approval_policy(row, nil), do: row

  defp maybe_apply_invalid_activity_approval_policy(row, approval_policy) do
    requirement = invalid_activity_approval_requirement(row)

    {status, requirements, rule_matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "resource_projection_invalid_activity", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", rule_matches)
    |> Map.put("policy_decision", decision)
  end

  defp maybe_apply_invalid_summary_approval_policy(row, nil), do: row

  defp maybe_apply_invalid_summary_approval_policy(row, approval_policy) do
    requirement = invalid_summary_approval_requirement(row)

    {status, requirements, rule_matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "resource_projection_invalid_summary", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", rule_matches)
    |> Map.put("policy_decision", decision)
  end

  defp invalid_activity_approval_requirement(row) do
    %{
      "activity_id" => row["activity_id"],
      "activity_type" => "resource_projection_invalid_activity",
      "action" => "review_invalid_resource_projection_input",
      "requirement_type" => "operator_review",
      "reason" =>
        "resource projection activity input requires review: #{row["invalid_activity_input_reason"]}",
      "activity_context" =>
        %{
          "activity_ids" => row["activity_ids"],
          "scenario_id" => row["scenario_id"],
          "spacecraft_id" => row["spacecraft_id"],
          "source_window_id" => row["source_window_id"],
          "source_window_type" => row["source_window_type"],
          "source_window" => row["source_window"],
          "ground_station_id" => row["ground_station_id"],
          "target_id" => row["target_id"],
          "starts_at_s" => row["starts_at_s"],
          "ends_at_s" => row["ends_at_s"],
          "required_operator_action" => row["required_operator_action"],
          "invalid_activity_input" => row["invalid_activity_input"],
          "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
          "source_activity" => row["source_activity"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp invalid_summary_approval_requirement(row) do
    %{
      "activity_id" => row["id"],
      "activity_type" => "resource_projection_invalid_summary",
      "action" => "review_invalid_resource_projection_summary",
      "requirement_type" => "operator_review",
      "reason" =>
        "resource projection summary input requires review: #{row["invalid_resource_summary_input_reason"]}",
      "activity_context" =>
        %{
          "resource_summary_id" => row["resource_summary_id"],
          "spacecraft_id" => row["spacecraft_id"],
          "required_operator_action" => row["required_operator_action"],
          "invalid_resource_summary_input" => row["invalid_resource_summary_input"],
          "invalid_resource_summary_input_reason" => row["invalid_resource_summary_input_reason"],
          "source_resource_summary" => row["source_resource_summary"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp resource_projection_approval_requirements(row, risks) do
    risks
    |> Enum.map(fn risk ->
      spacecraft_id = row["spacecraft_id"] || "unscoped_resource_summary"
      risk_type = risk["type"]

      %{
        "schema_contract" => "approval_requirement.v1",
        "id" => "approval:resource_projection:#{spacecraft_id}:#{risk_type}",
        "activity_id" => "resource_projection:#{spacecraft_id}",
        "activity_type" => "resource_projection",
        "action" => "review_resource_projection",
        "requirement_type" => "operator_review",
        "reason" => risk["reason"],
        "activity_context" =>
          %{
            "spacecraft_id" => spacecraft_id,
            "risk_type" => risk_type,
            "risk_reason" => risk["reason"],
            "severity" => risk["severity"],
            "value" => risk["value"],
            "projected_storage_overflow_mb" => row["projected_storage_overflow_mb"],
            "projected_downlink_shortfall_mb" => row["projected_downlink_shortfall_mb"],
            "projected_battery_overuse_wh" => row["projected_battery_overuse_wh"],
            "projected_battery_state_of_charge" => row["projected_battery_state_of_charge"],
            "projected_power_margin" => row["projected_power_margin"],
            "thermal_margin_c" => row["thermal_margin_c"],
            "resource_pressure_status" => row["resource_pressure_status"],
            "resource_pressure_types" => row["resource_pressure_types"],
            "projected_storage_margin" => row["projected_storage_margin"],
            "projected_downlink_margin" => row["projected_downlink_margin"],
            "spacecraft_available" => row["spacecraft_available"],
            "mode" => row["mode"],
            "incompatible_activity_types" => row["incompatible_activity_types"],
            "suppressed_activity_types" => row["suppressed_activity_types"],
            "resource_source_quality" => row["resource_source_quality"],
            "resource_trust_boundary" => row["resource_trust_boundary"],
            "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
            "resource_provenance" => row["resource_provenance"],
            "first_resource_pressure_activity_id" => row["first_resource_pressure_activity_id"],
            "first_resource_pressure_activity_type" =>
              row["first_resource_pressure_activity_type"],
            "first_resource_pressure_kind" => row["first_resource_pressure_kind"],
            "first_resource_pressure_starts_at_s" => row["first_resource_pressure_starts_at_s"],
            "first_resource_pressure_direction" => row["first_resource_pressure_direction"],
            "direction" => row["first_resource_pressure_direction"],
            "first_resource_pressure_ground_station_id" =>
              row["first_resource_pressure_ground_station_id"],
            "ground_station_id" => row["first_resource_pressure_ground_station_id"],
            "first_resource_pressure_station_calendar_entry_id" =>
              row["first_resource_pressure_station_calendar_entry_id"],
            "station_calendar_entry_id" =>
              row["first_resource_pressure_station_calendar_entry_id"],
            "first_resource_pressure_station_calendar_provider_id" =>
              row["first_resource_pressure_station_calendar_provider_id"],
            "station_calendar_provider_id" =>
              row["first_resource_pressure_station_calendar_provider_id"],
            "first_resource_pressure_station_calendar_provider_entry_id" =>
              row["first_resource_pressure_station_calendar_provider_entry_id"],
            "station_calendar_provider_entry_id" =>
              row["first_resource_pressure_station_calendar_provider_entry_id"],
            "first_resource_pressure_station_calendar_directions" =>
              row["first_resource_pressure_station_calendar_directions"],
            "station_calendar_directions" =>
              row["first_resource_pressure_station_calendar_directions"],
            "first_resource_pressure_capacity_fraction" =>
              row["first_resource_pressure_capacity_fraction"],
            "capacity_fraction" => row["first_resource_pressure_capacity_fraction"],
            "first_resource_pressure_source_window_id" =>
              row["first_resource_pressure_source_window_id"],
            "source_window_id" => row["first_resource_pressure_source_window_id"],
            "first_resource_pressure_source_window_type" =>
              row["first_resource_pressure_source_window_type"],
            "source_window_type" => row["first_resource_pressure_source_window_type"],
            "first_resource_pressure_source_window" =>
              row["first_resource_pressure_source_window"],
            "source_window" => row["first_resource_pressure_source_window"]
          }
          |> compact_map()
      }
      |> compact_map()
    end)
    |> Enum.sort_by(&{&1["activity_id"], &1["id"]})
  end

  defp resource_pressure_risks(row) do
    []
    |> maybe_add_resource_pressure_risk(row, "storage_overflow", "projected_storage_overflow_mb")
    |> maybe_add_resource_pressure_risk(
      row,
      "downlink_shortfall",
      "projected_downlink_shortfall_mb"
    )
    |> maybe_add_resource_pressure_risk(
      row,
      "battery_depletion",
      "projected_battery_overuse_wh"
    )
    |> maybe_add_thermal_margin_risk(row)
    |> maybe_add_spacecraft_unavailable_risk(row)
    |> maybe_add_activity_availability_risks(row)
  end

  defp maybe_add_resource_pressure_risk(risks, row, type, field) do
    case Map.get(row, field) do
      value when is_number(value) and value > 0.0 ->
        [
          %{
            "type" => type,
            "severity" => "high",
            "reason" =>
              "#{type} #{value} #{resource_pressure_unit(field)} for #{row["spacecraft_id"]}",
            "value" => value
          }
          | risks
        ]

      _value ->
        risks
    end
  end

  defp resource_pressure_unit("projected_battery_overuse_wh"), do: "Wh"
  defp resource_pressure_unit(_field), do: "MB"

  defp maybe_add_thermal_margin_risk(risks, %{"thermal_margin_c" => value} = row)
       when is_number(value) and value < 0.0 do
    [
      %{
        "type" => "thermal_margin_below_limit",
        "severity" => "high",
        "reason" => "thermal margin below zero for #{row["spacecraft_id"]}",
        "value" => value
      }
      | risks
    ]
  end

  defp maybe_add_thermal_margin_risk(risks, _row), do: risks

  defp maybe_add_spacecraft_unavailable_risk(risks, %{"spacecraft_available" => false} = row) do
    [
      %{
        "type" => "spacecraft_unavailable",
        "severity" => "high",
        "reason" => "spacecraft unavailable for #{row["spacecraft_id"]}",
        "value" => false
      }
      | risks
    ]
  end

  defp maybe_add_spacecraft_unavailable_risk(risks, _row), do: risks

  defp maybe_add_activity_availability_risks(risks, row) do
    row
    |> Map.get("resource_pressure_types", [])
    |> Enum.filter(&(&1 in activity_availability_risk_types()))
    |> Enum.reduce(risks, fn type, acc ->
      [
        %{
          "type" => type,
          "severity" => "high",
          "reason" => "#{type} for #{row["spacecraft_id"]}",
          "value" => true
        }
        | acc
      ]
    end)
  end

  defp activity_availability_risk_types do
    ~w(
      payload_unavailable
      spacecraft_degraded_payload_unavailable
      activity_type_suppressed_by_resource_summary
      activity_type_incompatible_with_resource_summary
      antenna_unavailable
    )
  end

  defp resource_pressure_types(
         storage_overflow_mb,
         downlink_shortfall_mb,
         battery_overuse_wh,
         thermal_margin_c,
         activity_resource_flow,
         spacecraft_available
       ) do
    []
    |> maybe_add_resource_pressure_type("storage_overflow", storage_overflow_mb)
    |> maybe_add_resource_pressure_type("downlink_shortfall", downlink_shortfall_mb)
    |> maybe_add_resource_pressure_type("battery_depletion", battery_overuse_wh)
    |> maybe_add_thermal_margin_pressure_type(thermal_margin_c)
    |> add_activity_resource_pressure_types(activity_resource_flow)
    |> maybe_add_spacecraft_unavailable_pressure_type(spacecraft_available)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp maybe_add_resource_pressure_type(types, type, value)
       when is_number(value) and value > 0.0,
       do: [type | types]

  defp maybe_add_resource_pressure_type(types, _type, _value), do: types

  defp maybe_add_thermal_margin_pressure_type(types, value) when is_number(value) and value < 0.0,
    do: ["thermal_margin_below_limit" | types]

  defp maybe_add_thermal_margin_pressure_type(types, _value), do: types

  defp add_activity_resource_pressure_types(types, rows) when is_list(rows) do
    Enum.reduce(rows, types, fn row, acc ->
      reason = Map.get(row, "resource_effect_reason")

      if reason in resource_availability_pressure_types() do
        [reason | acc]
      else
        acc
      end
    end)
  end

  defp add_activity_resource_pressure_types(types, _rows), do: types

  defp resource_availability_pressure_types do
    ~w(
      spacecraft_unavailable
      payload_unavailable
      spacecraft_degraded_payload_unavailable
      activity_type_suppressed_by_resource_summary
      activity_type_incompatible_with_resource_summary
      antenna_unavailable
    )
  end

  defp maybe_add_spacecraft_unavailable_pressure_type(types, false),
    do: ["spacecraft_unavailable" | types]

  defp maybe_add_spacecraft_unavailable_pressure_type(types, _spacecraft_available), do: types

  defp resource_pressure_status([]), do: "nominal"

  defp resource_pressure_status(["downlink_shortfall"]), do: "downlink_shortfall"

  defp resource_pressure_status(["spacecraft_unavailable"]), do: "spacecraft_unavailable"

  defp resource_pressure_status(["payload_unavailable"]), do: "payload_unavailable"

  defp resource_pressure_status(["antenna_unavailable"]), do: "antenna_unavailable"

  defp resource_pressure_status(["spacecraft_degraded_payload_unavailable"]),
    do: "spacecraft_degraded_payload_unavailable"

  defp resource_pressure_status(types) when is_list(types) do
    if Enum.all?(types, &(&1 in resource_availability_pressure_types())) do
      "resource_availability_pressure"
    else
      resource_pressure_status_fallback(types)
    end
  end

  defp resource_pressure_status_fallback(["storage_overflow"]), do: "storage_overflow"

  defp resource_pressure_status_fallback(["downlink_shortfall", "storage_overflow"]),
    do: "storage_and_downlink_pressure"

  defp resource_pressure_status_fallback(_types), do: "resource_pressure"

  defp first_resource_pressure_event(rows) when is_list(rows) do
    rows
    |> Enum.find(fn row ->
      positive_number?(row["storage_overflow_mb"]) or
        positive_number?(row["downlink_shortfall_mb"]) or
        positive_number?(row["battery_overuse_wh"]) or
        Map.get(row, "resource_effect_reason") in resource_availability_pressure_types()
    end)
    |> case do
      nil ->
        %{}

      row ->
        %{
          "first_resource_pressure_activity_id" => row["activity_id"],
          "first_resource_pressure_activity_type" => row["activity_type"],
          "first_resource_pressure_kind" => first_resource_pressure_kind(row),
          "first_resource_pressure_starts_at_s" => row["starts_at_s"],
          "first_resource_pressure_direction" => row["direction"],
          "first_resource_pressure_ground_station_id" => row["ground_station_id"],
          "first_resource_pressure_station_calendar_entry_id" => row["station_calendar_entry_id"],
          "first_resource_pressure_station_calendar_provider_id" =>
            row["station_calendar_provider_id"],
          "first_resource_pressure_station_calendar_provider_entry_id" =>
            row["station_calendar_provider_entry_id"],
          "first_resource_pressure_station_calendar_directions" =>
            row["station_calendar_directions"],
          "first_resource_pressure_capacity_fraction" => row["capacity_fraction"],
          "first_resource_pressure_source_window_id" => row["source_window_id"],
          "first_resource_pressure_source_window_type" => row["source_window_type"],
          "first_resource_pressure_source_window" => row["source_window"],
          "source_window_id" => row["source_window_id"],
          "source_window_type" => row["source_window_type"],
          "source_window" => row["source_window"]
        }
        |> compact_map()
    end
  end

  defp first_resource_pressure_kind(%{"storage_overflow_mb" => value})
       when is_number(value) and value > 0.0,
       do: "storage_overflow"

  defp first_resource_pressure_kind(%{"downlink_shortfall_mb" => value})
       when is_number(value) and value > 0.0,
       do: "downlink_shortfall"

  defp first_resource_pressure_kind(%{"battery_overuse_wh" => value})
       when is_number(value) and value > 0.0,
       do: "battery_depletion"

  defp first_resource_pressure_kind(%{"resource_effect_reason" => reason})
       when reason in [
              "spacecraft_unavailable",
              "payload_unavailable",
              "spacecraft_degraded_payload_unavailable",
              "activity_type_suppressed_by_resource_summary",
              "activity_type_incompatible_with_resource_summary",
              "antenna_unavailable"
            ],
       do: reason

  defp first_resource_pressure_kind(_row), do: nil

  defp resource_pressure_kinds(row) do
    []
    |> maybe_add_resource_pressure_kind(row, "storage_overflow", "storage_overflow_mb")
    |> maybe_add_resource_pressure_kind(row, "downlink_shortfall", "downlink_shortfall_mb")
    |> maybe_add_resource_pressure_kind(row, "battery_depletion", "battery_overuse_wh")
    |> maybe_add_availability_resource_pressure_kind(row)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp maybe_add_resource_pressure_kind(types, row, type, field) do
    case Map.get(row, field) do
      value when is_number(value) and value > 0.0 -> [type | types]
      _value -> types
    end
  end

  defp maybe_add_availability_resource_pressure_kind(types, %{"resource_effect_reason" => reason})
       when reason in [
              "spacecraft_unavailable",
              "payload_unavailable",
              "spacecraft_degraded_payload_unavailable",
              "activity_type_suppressed_by_resource_summary",
              "activity_type_incompatible_with_resource_summary",
              "antenna_unavailable"
            ],
       do: [reason | types]

  defp maybe_add_availability_resource_pressure_kind(types, _row), do: types

  defp positive_number?(value), do: is_number(value) and value > 0.0

  defp resource_projection_activities(%{"spacecraft_id" => nil}, activities, 1), do: activities

  defp resource_projection_activities(summary, activities, 1),
    do: resource_projection_activities(summary, activities, :scoped)

  defp resource_projection_activities(summary, activities, _summary_count) do
    spacecraft_id = summary["spacecraft_id"]

    Enum.filter(activities, fn activity ->
      Map.get(activity, "spacecraft_id") == spacecraft_id or
        Map.get(activity, "scenario_id") == spacecraft_id
    end)
  end

  defp resource_effect_context(summary) do
    %{
      "spacecraft_available" => spacecraft_available(summary),
      "payload_available" => Map.get(summary, "payload_available"),
      "antenna_available" => Map.get(summary, "antenna_available"),
      "degraded" => Map.get(summary, "degraded"),
      "mode" => Map.get(summary, "mode"),
      "incompatible_activity_types" => Map.get(summary, "incompatible_activity_types"),
      "suppressed_activity_types" => Map.get(summary, "suppressed_activity_types")
    }
  end

  defp spacecraft_available(summary) do
    cond do
      Map.has_key?(summary, "spacecraft_available") ->
        Map.get(summary, "spacecraft_available")

      Map.has_key?(summary, "spacecraft_availability") ->
        Map.get(summary, "spacecraft_availability")

      true ->
        nil
    end
  end

  defp projection_spacecraft_id(%{"spacecraft_id" => spacecraft_id}, _summary_count)
       when spacecraft_id not in [nil, ""],
       do: spacecraft_id

  defp projection_spacecraft_id(_summary, 1), do: "all_spacecraft"
  defp projection_spacecraft_id(_summary, _summary_count), do: "unscoped_resource_summary"

  defp resource_trust_boundary(summary) do
    Map.get(summary, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"])
  end

  defp resource_trust_boundary_status(summary) do
    case resource_trust_boundary(summary) do
      value when is_binary(value) and value != "" -> "declared"
      _value -> "missing"
    end
  end

  defp resource_trust_boundary_status_counts(summaries) do
    summaries
    |> Enum.map(
      &(Map.get(&1, "resource_trust_boundary_status") || resource_trust_boundary_status(&1))
    )
    |> Enum.frequencies()
  end

  defp resource_source_quality_counts(rows) do
    rows
    |> Enum.map(&Map.get(&1, "resource_source_quality"))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp resource_spacecraft_ids_by_source_quality(rows) do
    rows
    |> Enum.map(&{Map.get(&1, "resource_source_quality"), Map.get(&1, "spacecraft_id")})
    |> stable_ids_by_key()
  end

  defp resource_spacecraft_ids_by_trust_boundary_status(rows) do
    rows
    |> Enum.map(&{Map.get(&1, "resource_trust_boundary_status"), Map.get(&1, "spacecraft_id")})
    |> stable_ids_by_key()
  end

  defp activity_sort_key(activity) do
    {
      Map.get(activity, "starts_at_s") || :infinity,
      Map.get(activity, "ends_at_s") || :infinity,
      Map.get(activity, "id") || ""
    }
  end

  defp estimated_storage_mb(activity) do
    first_number([
      get_in(activity, ["metadata", "estimated_storage_mb"]),
      Map.get(activity, "estimated_storage_mb"),
      planned_data_volume_mb(activity)
    ]) || 0.0
  end

  defp resource_projection_downlink_mb(activity) do
    first_number([
      Map.get(activity, "capacity_adjusted_throughput_mb"),
      get_in(activity, ["throughput_model", "capacity_adjusted_throughput_mb"])
    ]) || estimated_downlink_throughput_mb(activity) * contact_capacity_fraction(activity)
  end

  defp activity_resource_flow(
         activities,
         starting_storage_used_mb,
         storage_capacity_mb,
         downlink_capacity_mb,
         starting_battery_energy_used_wh,
         battery_capacity_wh,
         resource_effect_context
       ) do
    {rows, _acc} =
      Enum.map_reduce(
        activities,
        %{
          "storage_used_mb" => starting_storage_used_mb,
          "downlink_used_mb" => 0.0,
          "battery_energy_used_wh" => starting_battery_energy_used_wh
        },
        fn activity, acc ->
          storage_before = acc["storage_used_mb"]
          downlink_before = acc["downlink_used_mb"]
          battery_before = acc["battery_energy_used_wh"]

          {resource_effect_status, resource_effect_reason} =
            activity_resource_effect(activity, resource_effect_context)

          storage_produced_mb =
            if resource_effect_status == "projected",
              do: activity_storage_produced_mb(activity),
              else: 0.0

          planned_downlink_mb =
            if resource_effect_status == "projected",
              do: activity_downlinked_mb(activity),
              else: 0.0

          battery_energy_consumed_wh =
            if resource_effect_status == "projected",
              do: activity_battery_energy_consumed_wh(activity),
              else: 0.0

          battery_energy_generated_wh =
            if resource_effect_status == "projected",
              do: activity_battery_energy_generated_wh(activity),
              else: 0.0

          battery_delta_wh = battery_energy_consumed_wh - battery_energy_generated_wh
          battery_after = roll_forward_battery_energy(battery_before, battery_delta_wh)

          storage_available_before_downlink_mb =
            storage_available_before_downlink_mb(storage_before, storage_produced_mb)

          downlinked_mb =
            effective_downlinked_mb(planned_downlink_mb, storage_available_before_downlink_mb)

          unused_downlink_capacity_mb =
            unused_downlink_capacity_mb(planned_downlink_mb, downlinked_mb)

          storage_delta_mb = storage_produced_mb - downlinked_mb
          storage_after = roll_forward_storage(storage_before, storage_delta_mb)
          downlink_after = downlink_before + planned_downlink_mb
          downlink_row? = downlink_activity?(activity)
          capacity_fraction = contact_capacity_fraction(activity)
          latency = activity_latency_context(activity)

          row =
            %{
              "activity_id" => activity["id"],
              "activity_type" => activity["type"],
              "activity_status" => activity_status(activity),
              "approval_status" => activity_approval_status(activity),
              "planned_data_volume_mb" => planned_data_volume_mb(activity),
              "actual_data_volume_mb" => actual_data_volume_mb(activity),
              "data_volume_delta_mb" => data_volume_delta_mb(activity),
              "data_volume_completion_fraction" => data_volume_completion_fraction(activity),
              "completed_fraction" => completed_fraction(activity),
              "resource_effect_status" => resource_effect_status,
              "resource_effect_reason" => resource_effect_reason,
              "scenario_id" =>
                stable_id_or_nil(activity["scenario_id"]) ||
                  stable_id_or_nil(activity["spacecraft_id"]),
              "starts_at_s" => activity["starts_at_s"],
              "ends_at_s" => activity["ends_at_s"],
              "collection_ends_at_s" => latency["collection_ends_at_s"],
              "planned_delivery_at_s" => latency["planned_delivery_at_s"],
              "actual_delivery_at_s" => latency["actual_delivery_at_s"],
              "max_latency_s" => latency["max_latency_s"],
              "planned_latency_s" => latency["planned_latency_s"],
              "actual_latency_s" => latency["actual_latency_s"],
              "latency_margin_s" => latency["latency_margin_s"],
              "latency_basis" => latency["latency_basis"],
              "latency_status" => latency["latency_status"],
              "source_window_id" => stable_id_or_nil(activity["source_window_id"]),
              "source_window_type" => activity["source_window_type"],
              "source_window" => activity["source_window"],
              "ground_station_id" => stable_id_or_nil(activity["ground_station_id"]),
              "target_id" => stable_id_or_nil(activity["target_id"]),
              "direction" => activity["direction"],
              "mode" => resource_effect_context["mode"],
              "allocation_status" => contact_allocation_status(activity, "allocation_status"),
              "effective_allocation_status" =>
                contact_allocation_status(activity, "effective_allocation_status"),
              "allocation_reason" => contact_allocation_status(activity, "allocation_reason"),
              "capacity_pack_status" =>
                contact_allocation_status(activity, "capacity_pack_status"),
              "incompatible_activity_types" =>
                resource_effect_context["incompatible_activity_types"],
              "suppressed_activity_types" => resource_effect_context["suppressed_activity_types"],
              "station_calendar_entry_id" => activity_station_calendar_entry_id(activity),
              "station_calendar_provider_id" => activity_station_calendar_provider_id(activity),
              "station_calendar_provider_entry_id" =>
                activity_station_calendar_provider_entry_id(activity),
              "station_calendar_directions" => activity["station_calendar_directions"],
              "capacity_fraction" => downlink_value(downlink_row?, capacity_fraction),
              "storage_used_before_mb" => storage_before,
              "storage_produced_mb" => storage_produced_mb,
              "storage_available_before_downlink_mb" =>
                downlink_value(downlink_row?, storage_available_before_downlink_mb),
              "planned_downlink_mb" => downlink_value(downlink_row?, planned_downlink_mb),
              "downlinked_mb" => downlinked_mb,
              "unused_downlink_capacity_mb" =>
                downlink_value(downlink_row?, unused_downlink_capacity_mb),
              "storage_delta_mb" => storage_delta_mb,
              "storage_used_after_mb" => storage_after,
              "storage_margin_after" =>
                projected_storage_margin(storage_capacity_mb, storage_after, %{}),
              "storage_overflow_mb" =>
                projected_storage_overflow_mb(storage_capacity_mb, storage_after),
              "downlink_used_before_mb" => downlink_before,
              "downlink_used_after_mb" => downlink_after,
              "downlink_margin_after" =>
                projected_downlink_margin(downlink_capacity_mb, downlink_after, %{}),
              "downlink_shortfall_mb" =>
                projected_downlink_shortfall_mb(downlink_capacity_mb, downlink_after),
              "battery_energy_used_before_wh" => battery_before,
              "battery_energy_consumed_wh" => battery_energy_consumed_wh,
              "battery_energy_generated_wh" => battery_energy_generated_wh,
              "battery_energy_delta_wh" => battery_delta_wh,
              "battery_energy_used_after_wh" => battery_after,
              "battery_state_of_charge_after" =>
                projected_battery_state_of_charge(battery_capacity_wh, battery_after),
              "battery_overuse_wh" =>
                projected_battery_overuse_wh(battery_capacity_wh, battery_after)
            }
            |> compact_map()

          {row,
           %{
             "storage_used_mb" => storage_after,
             "downlink_used_mb" => downlink_after,
             "battery_energy_used_wh" => battery_after
           }}
        end
      )

    rows
  end

  defp activity_storage_produced_mb(%{"type" => "observe"} = activity),
    do: estimated_storage_mb(activity)

  defp activity_storage_produced_mb(_activity), do: 0.0

  defp activity_downlinked_mb(activity) do
    if downlink_activity?(activity), do: resource_projection_downlink_mb(activity), else: 0.0
  end

  defp activity_battery_energy_consumed_wh(activity) do
    @battery_energy_consumed_paths
    |> Enum.map(&path_value(activity, &1))
    |> first_number()
    |> case do
      value when is_number(value) -> value
      _value -> 0.0
    end
  end

  defp activity_battery_energy_generated_wh(activity) do
    @battery_energy_generated_paths
    |> Enum.map(&path_value(activity, &1))
    |> first_number()
    |> case do
      value when is_number(value) -> value
      _value -> 0.0
    end
  end

  defp estimated_downlink_throughput_mb(activity) do
    @estimated_downlink_throughput_paths
    |> Enum.map(&path_value(activity, &1))
    |> first_number()
    |> case do
      value when is_number(value) -> value
      _value -> 0.0
    end
  end

  defp planned_data_volume_mb(activity) do
    @planned_data_volume_paths
    |> Enum.map(&path_value(activity, &1))
    |> first_number()
  end

  defp actual_data_volume_mb(activity) do
    @actual_data_volume_paths
    |> Enum.map(&path_value(activity, &1))
    |> first_number()
  end

  defp data_volume_delta_mb(activity) do
    planned = planned_data_volume_mb(activity)
    actual = actual_data_volume_mb(activity)

    if is_number(planned) and is_number(actual), do: actual - planned
  end

  defp data_volume_completion_fraction(activity) do
    planned = planned_data_volume_mb(activity)
    actual = actual_data_volume_mb(activity)

    if is_number(planned) and planned > 0.0 and is_number(actual), do: actual / planned
  end

  defp activity_latency_context(activity) do
    collection_ends_at_s =
      first_number([
        activity["collection_ends_at_s"],
        activity["collection_end_s"],
        get_in(activity, ["metadata", "collection_ends_at_s"]),
        get_in(activity, ["metadata", "collection_end_s"])
      ])

    planned_delivery_at_s =
      first_number([
        activity["planned_delivery_at_s"],
        activity["expected_delivery_at_s"],
        activity["delivery_at_s"],
        get_in(activity, ["metadata", "planned_delivery_at_s"]),
        get_in(activity, ["metadata", "expected_delivery_at_s"]),
        get_in(activity, ["metadata", "delivery_at_s"])
      ])

    actual_delivery_at_s =
      first_number([
        activity["actual_delivery_at_s"],
        activity["delivered_at_s"],
        get_in(activity, ["metadata", "actual_delivery_at_s"]),
        get_in(activity, ["metadata", "delivered_at_s"])
      ])

    max_latency_s =
      first_number([
        activity["max_latency_s"],
        activity["latency_requirement_s"],
        get_in(activity, ["metadata", "max_latency_s"]),
        get_in(activity, ["metadata", "latency_requirement_s"])
      ])

    planned_latency_s =
      first_number([
        activity["planned_latency_s"],
        get_in(activity, ["metadata", "planned_latency_s"])
      ]) || latency_between(collection_ends_at_s, planned_delivery_at_s)

    actual_latency_s =
      first_number([
        activity["actual_latency_s"],
        get_in(activity, ["metadata", "actual_latency_s"])
      ]) || latency_between(collection_ends_at_s, actual_delivery_at_s)

    {latency_basis, selected_latency_s} =
      cond do
        is_number(actual_latency_s) -> {"actual", actual_latency_s}
        is_number(planned_latency_s) -> {"planned", planned_latency_s}
        true -> {nil, nil}
      end

    %{
      "collection_ends_at_s" => collection_ends_at_s,
      "planned_delivery_at_s" => planned_delivery_at_s,
      "actual_delivery_at_s" => actual_delivery_at_s,
      "max_latency_s" => max_latency_s,
      "planned_latency_s" => planned_latency_s,
      "actual_latency_s" => actual_latency_s,
      "latency_margin_s" => latency_margin_s(max_latency_s, selected_latency_s),
      "latency_basis" => latency_basis,
      "latency_status" => activity_latency_status(max_latency_s, selected_latency_s)
    }
  end

  defp latency_between(collection_ends_at_s, delivery_at_s)
       when is_number(collection_ends_at_s) and is_number(delivery_at_s),
       do: max(delivery_at_s - collection_ends_at_s, 0.0)

  defp latency_between(_collection_ends_at_s, _delivery_at_s), do: nil

  defp latency_margin_s(max_latency_s, selected_latency_s)
       when is_number(max_latency_s) and is_number(selected_latency_s),
       do: max_latency_s - selected_latency_s

  defp latency_margin_s(_max_latency_s, _selected_latency_s), do: nil

  defp activity_latency_status(max_latency_s, selected_latency_s)
       when is_number(max_latency_s) and is_number(selected_latency_s) do
    if selected_latency_s > max_latency_s, do: "late", else: "within_limit"
  end

  defp activity_latency_status(_max_latency_s, _selected_latency_s), do: nil

  defp completed_fraction(activity) do
    case first_number([
           activity["completed_fraction"],
           activity["completion_fraction"],
           get_in(activity, ["metadata", "completed_fraction"]),
           get_in(activity, ["metadata", "completion_fraction"])
         ]) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
    end
  end

  defp first_number(values) do
    Enum.find_value(values, &numeric_or_nil/1)
  end

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp project_resource_effect?(activity, resource_effect_context) do
    activity
    |> activity_resource_effect(resource_effect_context)
    |> elem(0)
    |> Kernel.==("projected")
  end

  defp activity_resource_effect(activity, resource_effect_context) do
    status = activity_status(activity)
    approval_status = activity_approval_status(activity)

    cond do
      resource_effect_context["spacecraft_available"] == false ->
        {"ignored", "spacecraft_unavailable"}

      approval_status == "rejected" ->
        {"ignored", "approval_status_rejected"}

      status in terminal_resource_statuses() ->
        {"ignored", "activity_status_#{status}"}

      reason = contact_allocation_resource_effect_reason(activity) ->
        {"ignored", reason}

      activity_type_suppressed?(activity, resource_effect_context["suppressed_activity_types"]) ->
        {"ignored", "activity_type_suppressed_by_resource_summary"}

      activity_type_suppressed?(
        activity,
        resource_effect_context["incompatible_activity_types"]
      ) ->
        {"ignored", "activity_type_incompatible_with_resource_summary"}

      activity["type"] == "observe" and resource_effect_context["payload_available"] == false ->
        {"ignored", "payload_unavailable"}

      activity["type"] == "observe" and resource_effect_context["degraded"] == true ->
        {"ignored", "spacecraft_degraded_payload_unavailable"}

      antenna_required_activity?(activity) and
          resource_effect_context["antenna_available"] == false ->
        {"ignored", "antenna_unavailable"}

      true ->
        {"projected", "active_planning_activity"}
    end
  end

  defp contact_allocation_resource_effect_reason(activity) do
    effective_status = contact_allocation_status(activity, "effective_allocation_status")
    allocation_status = contact_allocation_status(activity, "allocation_status")

    cond do
      effective_status in [nil, "", "allocated"] and allocation_status in [nil, "", "allocated"] ->
        nil

      effective_status not in [nil, "", "allocated"] ->
        "contact_allocation_#{effective_status}"

      allocation_status not in [nil, "", "allocated"] ->
        "contact_allocation_#{allocation_status}"

      true ->
        nil
    end
  end

  defp contact_allocation_status(activity, field) do
    activity
    |> Map.get(field)
    |> status_token()
  end

  defp status_token(value) when value in [nil, ""], do: nil

  defp status_token(value) when is_binary(value) or is_atom(value) or is_integer(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end

  defp status_token(_value), do: nil

  defp antenna_required_activity?(%{"type" => type})
       when type in ["downlink", "tracking", "uplink", "command", "health_check"],
       do: true

  defp antenna_required_activity?(%{"type" => "planned_contact", "direction" => direction})
       when direction in ["downlink", "tracking", "uplink", "command", "health_check"],
       do: true

  defp antenna_required_activity?(%{
         "direction" => direction,
         "ground_station_id" => station_id
       })
       when direction in ["downlink", "tracking", "uplink", "command", "health_check"] and
              not is_nil(station_id),
       do: true

  defp antenna_required_activity?(activity), do: downlink_activity?(activity)

  defp resource_direction(%{"direction" => direction}) when is_binary(direction), do: direction
  defp resource_direction(%{"type" => "downlink"}), do: "downlink"
  defp resource_direction(%{"type" => "tracking"}), do: "tracking"
  defp resource_direction(%{"type" => "uplink"}), do: "uplink"
  defp resource_direction(%{"type" => "command"}), do: "command"
  defp resource_direction(%{"type" => "health_check"}), do: "health_check"
  defp resource_direction(_activity), do: nil

  defp terminal_resource_statuses,
    do: ~w(canceled cancelled completed executed failed missed partial rejected)

  defp activity_status(activity) do
    Map.get(activity, "status") || get_in(activity, ["metadata", "status"]) || "planned"
  end

  defp activity_approval_status(activity) do
    Map.get(activity, "approval_status") || get_in(activity, ["metadata", "approval_status"])
  end

  defp storage_available_before_downlink_mb(nil, _storage_produced_mb), do: nil

  defp storage_available_before_downlink_mb(storage_before, storage_produced_mb)
       when is_number(storage_before) and is_number(storage_produced_mb),
       do: max(storage_before + storage_produced_mb, 0.0)

  defp effective_downlinked_mb(planned_downlink_mb, nil), do: planned_downlink_mb

  defp effective_downlinked_mb(planned_downlink_mb, storage_available_before_downlink_mb)
       when is_number(planned_downlink_mb) and is_number(storage_available_before_downlink_mb),
       do: min(planned_downlink_mb, storage_available_before_downlink_mb)

  defp unused_downlink_capacity_mb(planned_downlink_mb, effective_downlinked_mb)
       when is_number(planned_downlink_mb) and is_number(effective_downlinked_mb),
       do: max(planned_downlink_mb - effective_downlinked_mb, 0.0)

  defp downlink_value(true, value), do: value
  defp downlink_value(false, _value), do: nil

  defp downlink_activity?(%{"type" => "downlink"}), do: true
  defp downlink_activity?(%{"type" => "planned_contact", "direction" => "downlink"}), do: true

  defp downlink_activity?(%{"direction" => "downlink", "ground_station_id" => station_id})
       when not is_nil(station_id),
       do: true

  defp downlink_activity?(_activity), do: false

  defp roll_forward_storage(nil, _storage_delta_mb), do: nil

  defp roll_forward_storage(storage_used_mb, storage_delta_mb)
       when is_number(storage_used_mb) and is_number(storage_delta_mb) do
    max(storage_used_mb + storage_delta_mb, 0.0)
  end

  defp roll_forward_battery_energy(nil, _battery_delta_wh), do: nil

  defp roll_forward_battery_energy(battery_energy_used_wh, battery_delta_wh)
       when is_number(battery_energy_used_wh) and is_number(battery_delta_wh) do
    max(battery_energy_used_wh + battery_delta_wh, 0.0)
  end

  defp contact_capacity_fraction(contact) do
    contact
    |> contact_capacity_fraction_candidates()
    |> Enum.find_value(&numeric_or_nil/1)
    |> case do
      nil -> 1.0
      value -> value |> max(0.0) |> min(1.0)
    end
  end

  defp contact_capacity_fraction_candidates(contact) do
    capacity_value_candidates(contact, @station_capacity_value_paths) ++
      source_station_capacity_fraction_candidates(contact["source_station_calendar_entry"]) ++
      source_station_capacity_fraction_candidates(contact["source_station_calendar_overlaps"])
  end

  defp source_station_capacity_fraction_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_capacity_fraction_candidates/1)

  defp source_station_capacity_fraction_candidates(%{} = source) do
    capacity_value_candidates(source, @source_station_capacity_value_paths)
  end

  defp source_station_capacity_fraction_candidates(_source), do: []

  defp source_station_calendar_values(sources, fields) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_values(&1, fields))

  defp source_station_calendar_values(%{} = source, fields),
    do: Enum.map(fields, &Map.get(source, &1))

  defp source_station_calendar_values(_source, _fields), do: []

  defp capacity_value_candidates(source, paths) do
    Enum.map(paths, fn
      {:fraction, path} -> path_value(source, path)
      {:percent, path} -> capacity_percent_fraction(path_value(source, path))
    end)
  end

  defp path_value(source, [field]), do: Map.get(source, field)
  defp path_value(source, path), do: get_in(source, path)

  defp capacity_percent_fraction(value) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end

  defp activity_station_calendar_entry_id(activity) do
    stable_id_or_nil(activity["station_calendar_entry_id"]) ||
      stable_id_or_nil(
        get_in(activity, ["source_station_calendar_entry", "station_calendar_entry_id"])
      ) ||
      stable_id_or_nil(get_in(activity, ["source_station_calendar_entry", "id"])) ||
      source_station_calendar_overlap_stable_id(activity, [
        "station_calendar_entry_id",
        "entry_id",
        "id"
      ])
  end

  defp activity_station_calendar_provider_id(activity) do
    stable_id_or_nil(activity["station_calendar_provider_id"]) ||
      stable_id_or_nil(get_in(activity, ["source_station_calendar_entry", "provider_id"])) ||
      stable_id_or_nil(
        get_in(activity, ["source_station_calendar_entry", "station_calendar_provider_id"])
      ) ||
      source_station_calendar_overlap_stable_id(activity, [
        "provider_id",
        "station_calendar_provider_id"
      ])
  end

  defp activity_station_calendar_provider_entry_id(activity) do
    stable_id_or_nil(activity["station_calendar_provider_entry_id"]) ||
      stable_id_or_nil(get_in(activity, ["source_station_calendar_entry", "provider_entry_id"])) ||
      stable_id_or_nil(
        get_in(activity, ["source_station_calendar_entry", "station_calendar_provider_entry_id"])
      ) ||
      source_station_calendar_overlap_stable_id(activity, [
        "provider_entry_id",
        "station_calendar_provider_entry_id"
      ])
  end

  defp source_station_calendar_overlap_stable_id(activity, fields) do
    activity
    |> Map.get("source_station_calendar_overlaps")
    |> source_station_calendar_capacity_source()
    |> source_station_calendar_stable_id(fields)
  end

  defp source_station_calendar_capacity_source(sources) when is_list(sources) do
    Enum.find(sources, &source_station_calendar_has_capacity?/1) ||
      Enum.find(sources, &is_map/1)
  end

  defp source_station_calendar_capacity_source(%{} = source), do: source
  defp source_station_calendar_capacity_source(_source), do: nil

  defp source_station_calendar_has_capacity?(%{} = source) do
    source
    |> source_station_capacity_fraction_candidates()
    |> Enum.any?(&(not is_nil(numeric_or_nil(&1))))
  end

  defp source_station_calendar_has_capacity?(_source), do: false

  defp source_station_calendar_stable_id(%{} = source, fields) do
    Enum.find_value(fields, fn field -> stable_id_or_nil(Map.get(source, field)) end)
  end

  defp source_station_calendar_stable_id(_source, _fields), do: nil

  defp starting_storage_used_mb(%{"storage_used_mb" => value}) when is_number(value),
    do: value * 1.0

  defp starting_storage_used_mb(%{"storage_capacity_mb" => capacity, "storage_margin" => margin})
       when is_number(capacity) and is_number(margin),
       do: max(capacity * (1.0 - margin), 0.0)

  defp starting_storage_used_mb(_summary), do: nil

  defp starting_battery_energy_used_wh(%{"battery_energy_used_wh" => value})
       when is_number(value),
       do: value * 1.0

  defp starting_battery_energy_used_wh(%{
         "battery_capacity_wh" => capacity,
         "battery_state_of_charge" => state_of_charge
       })
       when is_number(capacity) and is_number(state_of_charge),
       do: max(capacity * (1.0 - state_of_charge), 0.0)

  defp starting_battery_energy_used_wh(_summary), do: nil

  defp projected_storage_used_mb(nil, _storage_produced_mb, _downlinked_mb), do: nil

  defp projected_storage_used_mb(starting_storage_used_mb, storage_produced_mb, downlinked_mb) do
    max(starting_storage_used_mb + storage_produced_mb - downlinked_mb, 0.0)
  end

  defp projected_storage_margin(capacity, projected_storage_used_mb, _summary)
       when is_number(capacity) and capacity > 0 and is_number(projected_storage_used_mb) do
    max((capacity - projected_storage_used_mb) / capacity, 0.0)
  end

  defp projected_storage_margin(_capacity, _projected_storage_used_mb, summary),
    do: Map.get(summary, "storage_margin")

  defp projected_storage_overflow_mb(capacity, projected_storage_used_mb)
       when is_number(capacity) and is_number(projected_storage_used_mb) do
    max(projected_storage_used_mb - capacity, 0.0)
  end

  defp projected_storage_overflow_mb(_capacity, _projected_storage_used_mb), do: nil

  defp projected_downlink_margin(capacity, downlinked_mb, _summary)
       when is_number(capacity) and capacity > 0 do
    max((capacity - downlinked_mb) / capacity, 0.0)
  end

  defp projected_downlink_margin(_capacity, _downlinked_mb, summary),
    do: Map.get(summary, "downlink_margin")

  defp projected_downlink_shortfall_mb(capacity, downlinked_mb)
       when is_number(capacity) and is_number(downlinked_mb) do
    max(downlinked_mb - capacity, 0.0)
  end

  defp projected_downlink_shortfall_mb(_capacity, _downlinked_mb), do: nil

  defp projected_battery_energy_used_wh(nil, _activity_resource_flow), do: nil

  defp projected_battery_energy_used_wh(starting_battery_energy_used_wh, activity_resource_flow)
       when is_number(starting_battery_energy_used_wh) and is_list(activity_resource_flow) do
    Enum.reduce(activity_resource_flow, starting_battery_energy_used_wh, fn row, acc ->
      roll_forward_battery_energy(acc, Map.get(row, "battery_energy_delta_wh", 0.0))
    end)
  end

  defp projected_battery_state_of_charge(capacity, battery_energy_used_wh)
       when is_number(capacity) and capacity > 0 and is_number(battery_energy_used_wh) do
    ((capacity - battery_energy_used_wh) / capacity)
    |> max(0.0)
    |> min(1.0)
  end

  defp projected_battery_state_of_charge(_capacity, _battery_energy_used_wh), do: nil

  defp projected_battery_overuse_wh(capacity, battery_energy_used_wh)
       when is_number(capacity) and is_number(battery_energy_used_wh) do
    max(battery_energy_used_wh - capacity, 0.0)
  end

  defp projected_battery_overuse_wh(_capacity, _battery_energy_used_wh), do: nil

  defp resource_projection_warnings(
         summary,
         storage_capacity_mb,
         downlink_capacity_mb,
         projected_storage_overflow_mb,
         projected_downlink_shortfall_mb,
         projected_battery_overuse_wh,
         unused_downlink_capacity_mb,
         resource_pressure_types
       ) do
    []
    |> maybe_resource_projection_warning(
      "spacecraft_unavailable" in resource_pressure_types,
      "spacecraft unavailable; projected activity resource effects are ignored"
    )
    |> maybe_resource_projection_warning(
      "payload_unavailable" in resource_pressure_types,
      "payload unavailable; projected observation resource effects are ignored"
    )
    |> maybe_resource_projection_warning(
      "spacecraft_degraded_payload_unavailable" in resource_pressure_types,
      "spacecraft degraded; projected observation resource effects are ignored"
    )
    |> maybe_resource_projection_warning(
      "activity_type_suppressed_by_resource_summary" in resource_pressure_types,
      "resource summary suppresses one or more selected activity types; projected resource effects are ignored"
    )
    |> maybe_resource_projection_warning(
      "activity_type_incompatible_with_resource_summary" in resource_pressure_types,
      "resource summary marks one or more selected activity types incompatible; projected resource effects are ignored"
    )
    |> maybe_resource_projection_warning(
      "antenna_unavailable" in resource_pressure_types,
      "antenna unavailable; projected contact resource effects are ignored"
    )
    |> maybe_resource_projection_warning(
      "thermal_margin_below_limit" in resource_pressure_types,
      "externally supplied thermal margin is below zero; resource projection requires review"
    )
    |> maybe_resource_projection_warning(
      is_nil(storage_capacity_mb) and not is_nil(Map.get(summary, "storage_margin")),
      "storage capacity missing; projected storage margin preserves supplied summary margin"
    )
    |> maybe_resource_projection_warning(
      is_nil(downlink_capacity_mb) and not is_nil(Map.get(summary, "downlink_margin")),
      "downlink capacity missing; projected downlink margin preserves supplied summary margin"
    )
    |> maybe_resource_projection_warning(
      is_number(projected_storage_overflow_mb) and projected_storage_overflow_mb > 0.0,
      "projected storage exceeds declared capacity by #{projected_storage_overflow_mb} MB"
    )
    |> maybe_resource_projection_warning(
      is_number(projected_downlink_shortfall_mb) and projected_downlink_shortfall_mb > 0.0,
      "projected downlink demand exceeds declared capacity by #{projected_downlink_shortfall_mb} MB"
    )
    |> maybe_resource_projection_warning(
      is_nil(Map.get(summary, "battery_capacity_wh")) and
        not is_nil(Map.get(summary, "battery_state_of_charge")),
      "battery capacity missing; projected battery state preserves supplied summary margin"
    )
    |> maybe_resource_projection_warning(
      is_number(projected_battery_overuse_wh) and projected_battery_overuse_wh > 0.0,
      "projected battery energy use exceeds declared capacity by #{projected_battery_overuse_wh} Wh"
    )
    |> maybe_resource_projection_warning(
      is_number(unused_downlink_capacity_mb) and unused_downlink_capacity_mb > 0.0,
      "projected downlink capacity exceeds stored data by #{unused_downlink_capacity_mb} MB"
    )
    |> Enum.reverse()
  end

  defp maybe_resource_projection_warning(warnings, true, warning), do: [warning | warnings]
  defp maybe_resource_projection_warning(warnings, false, _warning), do: warnings

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
