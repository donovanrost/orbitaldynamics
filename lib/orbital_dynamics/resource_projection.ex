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
  alias OrbitalDynamics.ResourceProjection.ApprovalPolicy
  alias OrbitalDynamics.ResourceProjection.ActivityEffectPolicy
  alias OrbitalDynamics.ResourceProjection.ActivityInputValidation
  alias OrbitalDynamics.ResourceProjection.ActivityDeliveryEvidence
  alias OrbitalDynamics.ResourceProjection.FlowSummary
  alias OrbitalDynamics.ResourceProjection.MarginProjection
  alias OrbitalDynamics.ResourceProjection.PressureClassification
  alias OrbitalDynamics.ResourceProjection.ResourceSummaryInput
  alias OrbitalDynamics.ResourceProjection.StationCapacityEvidence

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
      subsystem_model_capability_contract: "subsystem_model_capability.v1",
      subsystem_model_capability_ids: subsystem_model_capability_ids(),
      subsystem_model_capability_ids_by_resource: subsystem_model_capability_ids_by_resource(),
      resource_availability_aliases: @resource_availability_aliases,
      resource_degraded_aliases: @resource_degraded_aliases,
      resource_margin_aliases: @resource_margin_aliases,
      resource_source_quality_aliases: @resource_source_quality_aliases,
      resource_trust_boundary_aliases: @resource_trust_boundary_aliases,
      planned_data_volume_paths: @planned_data_volume_paths,
      actual_data_volume_paths: ActivityInputValidation.actual_data_volume_paths(),
      estimated_downlink_throughput_paths: @estimated_downlink_throughput_paths,
      battery_energy_consumed_paths: @battery_energy_consumed_paths,
      battery_energy_generated_paths: @battery_energy_generated_paths,
      resource_availability_true_tokens: @resource_availability_true_tokens,
      resource_availability_false_tokens: @resource_availability_false_tokens,
      provider_direction_aliases: @provider_direction_aliases,
      station_calendar_direction_aliases: @station_calendar_direction_aliases,
      station_capacity_fraction_paths: StationCapacityEvidence.station_capacity_fraction_paths(),
      station_capacity_percent_paths: StationCapacityEvidence.station_capacity_percent_paths(),
      station_capacity_value_paths:
        StationCapacityEvidence.station_capacity_value_path_metadata(),
      source_station_capacity_fraction_paths:
        StationCapacityEvidence.source_station_capacity_fraction_paths(),
      source_station_capacity_percent_paths:
        StationCapacityEvidence.source_station_capacity_percent_paths(),
      source_station_capacity_value_paths:
        StationCapacityEvidence.source_station_capacity_value_path_metadata(),
      activity_stable_identity_fields: @activity_stable_identity_fields,
      row_semantics: [
        :per_spacecraft_activity_counts,
        :time_ordered_activity_resource_flow,
        :resource_projection_row_count_list_consistency,
        :resource_projection_flow_summary,
        :resource_projection_flow_pressure_routing,
        :resource_projection_flow_provider_calendar_provider_routing,
        :resource_projection_flow_invalid_input_routing,
        :resource_projection_flow_ignored_activity_routing,
        :status_aware_activity_resource_effects,
        :contact_allocation_status_resource_effects,
        :storage_projection,
        :downlink_capacity_projection,
        :declared_activity_battery_energy_projection,
        :subsystem_model_capability_refs,
        :storage_limited_downlink_utilization,
        :resource_projection_flow_quantity_totals,
        :collection_latency_flow_evidence,
        :planned_data_volume_storage_production_aliases,
        :realized_data_volume_evidence,
        :actual_data_volume_audit_only_aliases,
        :actual_data_volume_input_validation,
        :estimated_downlink_throughput_aliases,
        :battery_energy_consumed_aliases,
        :battery_energy_generated_aliases,
        :station_calendar_pressure_context,
        :station_calendar_capacity_fraction_context,
        :station_calendar_capacity_percent_aliases,
        :station_calendar_pressure_direction_and_capacity_maps,
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

  defp subsystem_model_capability_ids do
    [
      subsystem_model_capability_ids_by_resource().battery,
      subsystem_model_capability_ids_by_resource().storage
    ]
  end

  defp subsystem_model_capability_ids_by_resource do
    %{
      battery: OrbitalDynamics.SubsystemModel.battery_energy_storage()["id"],
      storage: OrbitalDynamics.SubsystemModel.data_storage_buffer()["id"]
    }
  end

  defp subsystem_model_capability_assumptions do
    %{
      "subsystem_model_capability_contract" => "subsystem_model_capability.v1",
      "subsystem_model_capability_ids" => subsystem_model_capability_ids(),
      "subsystem_model_capability_ids_by_resource" =>
        subsystem_model_capability_ids_by_resource()
        |> Enum.map(fn {resource, id} -> {Atom.to_string(resource), id} end)
        |> Map.new()
    }
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

    {invalid_summaries, summaries} = ResourceSummaryInput.normalize(summaries)

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
        &ApprovalPolicy.apply_to_invalid_activity(&1, approval_policy)
      )

    invalid_summaries =
      Enum.map(
        invalid_summaries,
        &ApprovalPolicy.apply_to_invalid_summary(&1, approval_policy)
      )

    projected_resources =
      summaries
      |> Enum.map(&resource_projection_row(&1, activities, summary_count))
      |> Enum.sort_by(& &1["spacecraft_id"])
      |> ApprovalPolicy.apply_to_rows(approval_policy)

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
      "assumptions" =>
        %{
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
        |> Map.merge(subsystem_model_capability_assumptions())
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
    FlowSummary.build(
      report,
      model_limits(),
      subsystem_model_capability_assumptions()
    )
  end

  def flow_summary(%{schema_contract: @schema_contract} = resource_projection_report) do
    resource_projection_report
    |> stringify_keys()
    |> flow_summary()
  end

  def flow_summary(_resource_projection_report),
    do: raise(ArgumentError, "resource projection report is required")

  defp resource_flow_rows(projected_resources),
    do: FlowSummary.resource_flow_rows(projected_resources)

  defp resource_pressure_row?(row), do: FlowSummary.resource_pressure_row?(row)

  defp resource_pressure_spacecraft_ids(projected_resources),
    do: FlowSummary.resource_pressure_spacecraft_ids(projected_resources)

  defp resource_pressure_spacecraft_ids_by_type(projected_resources, flow_rows),
    do: FlowSummary.resource_pressure_spacecraft_ids_by_type(projected_resources, flow_rows)

  defp resource_pressure_activity_ids_by_type(flow_rows),
    do: FlowSummary.resource_pressure_activity_ids_by_type(flow_rows)

  defp resource_pressure_types(projected_resources),
    do: FlowSummary.resource_pressure_types(projected_resources)

  defp stable_ids_by_key(pairs), do: FlowSummary.stable_ids_by_key(pairs)

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
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

  defp activity_completed_fraction_issue(activity),
    do: ActivityInputValidation.completed_fraction_issue(activity)

  defp activity_capacity_fraction_issue(activity),
    do: ActivityInputValidation.capacity_fraction_issue(activity)

  defp activity_latency_evidence_issue(activity),
    do: ActivityInputValidation.latency_evidence_issue(activity)

  defp activity_resource_quantity_issue(activity),
    do: ActivityInputValidation.resource_quantity_issue(activity)

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
      ResourceSummaryInput.projection_activities(summary, activities, summary_count)
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
      "spacecraft_id" => ResourceSummaryInput.projection_spacecraft_id(summary, summary_count),
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

  defp resource_pressure_types(
         storage_overflow_mb,
         downlink_shortfall_mb,
         battery_overuse_wh,
         thermal_margin_c,
         activity_resource_flow,
         spacecraft_available
       ),
       do:
         PressureClassification.types(
           storage_overflow_mb,
           downlink_shortfall_mb,
           battery_overuse_wh,
           thermal_margin_c,
           activity_resource_flow,
           spacecraft_available
         )

  defp resource_pressure_status(types), do: PressureClassification.status(types)

  defp first_resource_pressure_event(rows), do: PressureClassification.first_event(rows)

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
    ]) ||
      estimated_downlink_throughput_mb(activity) *
        StationCapacityEvidence.capacity_fraction(activity)
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
          capacity_fraction = StationCapacityEvidence.capacity_fraction(activity)

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
              "resource_effect_status" => resource_effect_status,
              "resource_effect_reason" => resource_effect_reason,
              "scenario_id" =>
                stable_id_or_nil(activity["scenario_id"]) ||
                  stable_id_or_nil(activity["spacecraft_id"]),
              "starts_at_s" => activity["starts_at_s"],
              "ends_at_s" => activity["ends_at_s"],
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
              "station_calendar_entry_id" =>
                StationCapacityEvidence.station_calendar_entry_id(activity),
              "station_calendar_provider_id" =>
                StationCapacityEvidence.station_calendar_provider_id(activity),
              "station_calendar_provider_entry_id" =>
                StationCapacityEvidence.station_calendar_provider_entry_id(activity),
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
            |> Map.merge(ActivityDeliveryEvidence.context(activity))
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
    ActivityInputValidation.actual_data_volume_paths()
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
    ActivityEffectPolicy.evaluate(
      activity,
      resource_effect_context,
      @resource_activity_type_aliases
    )
  end

  defp activity_status(activity), do: ActivityEffectPolicy.activity_status(activity)

  defp activity_approval_status(activity),
    do: ActivityEffectPolicy.activity_approval_status(activity)

  defp contact_allocation_status(activity, field),
    do: ActivityEffectPolicy.contact_allocation_status(activity, field)

  defp normalized_direction_token(value),
    do: ActivityEffectPolicy.normalized_direction_token(value)

  defp downlink_activity?(activity), do: ActivityEffectPolicy.downlink_activity?(activity)

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

  defp roll_forward_storage(nil, _storage_delta_mb), do: nil

  defp roll_forward_storage(storage_used_mb, storage_delta_mb)
       when is_number(storage_used_mb) and is_number(storage_delta_mb) do
    max(storage_used_mb + storage_delta_mb, 0.0)
  end

  defp roll_forward_battery_energy(battery_energy_used_wh, battery_delta_wh),
    do: MarginProjection.roll_forward_battery_energy(battery_energy_used_wh, battery_delta_wh)

  defp source_station_calendar_values(sources, fields) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_values(&1, fields))

  defp source_station_calendar_values(%{} = source, fields),
    do: Enum.map(fields, &Map.get(source, &1))

  defp source_station_calendar_values(_source, _fields), do: []

  defp path_value(source, [field]), do: Map.get(source, field)
  defp path_value(source, path), do: get_in(source, path)

  defp starting_storage_used_mb(summary),
    do: MarginProjection.starting_storage_used_mb(summary)

  defp starting_battery_energy_used_wh(summary),
    do: MarginProjection.starting_battery_energy_used_wh(summary)

  defp projected_storage_used_mb(starting_storage_used_mb, storage_produced_mb, downlinked_mb),
    do:
      MarginProjection.projected_storage_used_mb(
        starting_storage_used_mb,
        storage_produced_mb,
        downlinked_mb
      )

  defp projected_storage_margin(capacity, projected_storage_used_mb, summary),
    do:
      MarginProjection.projected_storage_margin(
        capacity,
        projected_storage_used_mb,
        summary
      )

  defp projected_storage_overflow_mb(capacity, projected_storage_used_mb),
    do: MarginProjection.projected_storage_overflow_mb(capacity, projected_storage_used_mb)

  defp projected_downlink_margin(capacity, downlinked_mb, summary),
    do: MarginProjection.projected_downlink_margin(capacity, downlinked_mb, summary)

  defp projected_downlink_shortfall_mb(capacity, downlinked_mb),
    do: MarginProjection.projected_downlink_shortfall_mb(capacity, downlinked_mb)

  defp projected_battery_energy_used_wh(
         starting_battery_energy_used_wh,
         activity_resource_flow
       ),
       do:
         MarginProjection.projected_battery_energy_used_wh(
           starting_battery_energy_used_wh,
           activity_resource_flow
         )

  defp projected_battery_state_of_charge(capacity, battery_energy_used_wh),
    do: MarginProjection.projected_battery_state_of_charge(capacity, battery_energy_used_wh)

  defp projected_battery_overuse_wh(capacity, battery_energy_used_wh),
    do: MarginProjection.projected_battery_overuse_wh(capacity, battery_energy_used_wh)

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
    MarginProjection.warnings(
      summary,
      storage_capacity_mb,
      downlink_capacity_mb,
      projected_storage_overflow_mb,
      projected_downlink_shortfall_mb,
      projected_battery_overuse_wh,
      unused_downlink_capacity_mb,
      resource_pressure_types
    )
  end

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

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
