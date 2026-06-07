defmodule OrbitalDynamics.ResourceFilter do
  @moduledoc """
  Planning-grade resource summary candidate filtering.

  This module applies the thin `resource_summary.v1` availability and margin
  policy used by campaign and refresh artifacts. It is not a subsystem
  simulator and does not propagate resource state over time.
  """

  @schema_contract "resource_filter_report.v1"
  @summary_schema_contract "resource_filter_summary.v1"
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @candidate_stable_identity_fields ~w(
    scenario_id
    spacecraft_id
    ground_station_id
    target_id
    source_window_id
    station_calendar_entry_id
    station_reservation_id
  )
  @station_calendar_id_list_fields ~w(
    station_calendar_overlap_entry_ids
    station_calendar_ambiguous_entry_ids
    station_calendar_reservation_ids
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
  @resource_power_margin_source_aliases ["battery_state_of_charge", "battery_soc"]
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
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  @resource_filter_policy_fields ~w(
    min_activity_fuel_margin
    min_activity_thermal_margin_c
    min_observe_power_margin
    min_observe_storage_margin
    min_downlink_power_margin
    min_downlink_margin
  )
  alias OrbitalDynamics.Policy

  @doc """
  Declares the resource filter model and known limits.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      summary_artifact_contract: @summary_schema_contract,
      model: :resource_summary_availability_and_margin_filter,
      validation_level: :artifact_contract,
      row_semantics: [
        :resource_summary_availability_suppression,
        :resource_filter_summary,
        :resource_filter_summary_routing_id_sets,
        :resource_availability_aliases,
        :resource_availability_status_tokens,
        :resource_degraded_aliases,
        :resource_margin_aliases,
        :resource_power_margin_source_aliases,
        :resource_margin_policy_suppression,
        :resource_thermal_margin_policy_suppression,
        :resource_source_quality_counts,
        :resource_trust_boundary_status_counts,
        :suppressed_resource_source_quality_candidate_id_routing,
        :suppressed_resource_trust_boundary_status_candidate_id_routing,
        :resource_provenance_alias_normalization,
        :resource_battery_mode_evidence_preservation,
        :resource_summary_activity_type_suppression,
        :duplicate_resource_summary_ambiguity,
        :station_context_passthrough,
        :candidate_stable_identity_fields,
        :station_calendar_id_list_fields,
        :station_calendar_direction_context,
        :provider_direction_aliases,
        :station_calendar_direction_aliases,
        :station_calendar_entry_identity_preservation,
        :invalid_candidate_input_review,
        :feedback_unit_interval_input_validation,
        :provider_result_map_value_keys,
        :derived_resource_summary_margin_consistency,
        :invalid_resource_summary_input_review,
        :no_schedule_mutation
      ],
      public_facades: [
        :filter_resource_candidates,
        :resource_filter_report,
        :resource_filter_summary,
        :resource_filter_policy
      ],
      resource_filter_policy_fields: @resource_filter_policy_fields,
      resource_availability_aliases: @resource_availability_aliases,
      resource_degraded_aliases: @resource_degraded_aliases,
      resource_margin_aliases: @resource_margin_aliases,
      resource_power_margin_source_aliases: @resource_power_margin_source_aliases,
      resource_availability_true_tokens: @resource_availability_true_tokens,
      resource_availability_false_tokens: @resource_availability_false_tokens,
      provider_direction_aliases: @provider_direction_aliases,
      station_calendar_direction_aliases: @station_calendar_direction_aliases,
      provider_result_map_value_keys: @provider_result_map_value_keys,
      candidate_stable_identity_fields: @candidate_stable_identity_fields,
      station_calendar_id_list_fields: @station_calendar_id_list_fields,
      suppression_reasons: [
        "fuel_margin_below_policy",
        "thermal_margin_below_policy",
        "spacecraft_unavailable",
        "payload_unavailable",
        "spacecraft_degraded_payload_unavailable",
        "activity_type_suppressed_by_resource_summary",
        "activity_type_incompatible_with_resource_summary",
        "ambiguous_resource_summary",
        "power_margin_below_observe_policy",
        "storage_margin_below_observe_policy",
        "antenna_unavailable",
        "power_margin_below_downlink_policy",
        "downlink_margin_below_policy",
        "invalid_candidate_input",
        "invalid_resource_summary_input"
      ],
      row_review_statuses: ["operator_review_required"],
      known_limits: [
        :artifact_level_only,
        :externally_supplied_resource_summary,
        :no_subsystem_simulation,
        :no_resource_time_propagation,
        :no_schedule_mutation
      ]
    }
  end

  @doc """
  Filters candidate activities using resource summaries.

  Returns `{kept_candidates, resource_filter_report}`. A single summary without
  a spacecraft ID applies as a wildcard, matching the campaign-planner behavior.
  """
  def filter_candidates(candidates, summaries, opts \\ [])

  def filter_candidates(candidates, summaries, opts)
      when is_list(candidates) and is_list(summaries) do
    approval_policy = Keyword.get(opts, :approval_policy)

    candidates =
      candidates
      |> Enum.with_index(1)
      |> Enum.map(fn {candidate, index} -> normalize_candidate(candidate, index) end)

    {invalid_summaries, summaries} =
      summaries
      |> Enum.with_index(1)
      |> Enum.map(&normalize_summary_input/1)
      |> Enum.split_with(&invalid_resource_summary_input?/1)

    invalid_summaries =
      Enum.map(
        invalid_summaries,
        &maybe_apply_invalid_summary_approval_policy(&1, approval_policy)
      )

    summaries_by_key = summaries_by_key(summaries)
    policy = resource_filter_policy(Keyword.get(opts, :policy, %{}))

    {kept, suppressed} =
      Enum.reduce(candidates, {[], []}, fn candidate, {kept, suppressed} ->
        summary = candidate_resource_summary(candidate, summaries_by_key)

        case suppression(candidate, summary, policy) do
          nil ->
            {[annotate_kept_candidate(candidate, summary) | kept], suppressed}

          {reason, summary} ->
            {kept, [suppressed_candidate(candidate, reason, summary) | suppressed]}
        end
      end)

    kept = Enum.reverse(kept)

    suppressed =
      suppressed
      |> Enum.reverse()
      |> disambiguate_suppressed_candidate_ids()
      |> Enum.map(&maybe_apply_approval_policy(&1, approval_policy))

    duplicate_suppressed_candidate_id_groups =
      duplicate_suppressed_candidate_id_groups(suppressed)

    {kept,
     %{
       "schema_contract" => @schema_contract,
       "model" => "resource_summary_availability_and_margin_filter",
       "policy" => policy,
       "model_limits" => model_limits(),
       "assumptions" =>
         Map.merge(
           %{
             "execution_boundary" => "artifact_only_no_schedule_mutation",
             "operator_authority" => "not_granted_by_resource_filter",
             "resource_state_propagation" => "not_performed"
           },
           capability_assumptions()
         ),
       "input_resource_summary_count" => length(summaries) + length(invalid_summaries),
       "valid_resource_summary_count" => length(summaries),
       "invalid_resource_summary_input_count" => length(invalid_summaries),
       "invalid_resource_summary_input_ids" =>
         Enum.map(invalid_summaries, & &1["resource_summary_id"]),
       "invalid_resource_summary_inputs" => invalid_summaries,
       "resource_source_quality_counts" => resource_source_quality_counts(summaries),
       "resource_trust_boundary_status_counts" =>
         resource_trust_boundary_status_counts(summaries),
       "suppressed_resource_source_quality_counts" =>
         suppressed_resource_source_quality_counts(suppressed),
       "suppressed_candidate_ids_by_resource_source_quality" =>
         suppressed_candidate_ids_by_resource_source_quality(suppressed),
       "suppressed_resource_trust_boundary_status_counts" =>
         suppressed_resource_trust_boundary_status_counts(suppressed),
       "suppressed_candidate_ids_by_resource_trust_boundary_status" =>
         suppressed_candidate_ids_by_resource_trust_boundary_status(suppressed),
       "input_candidate_count" => length(candidates),
       "kept_candidate_count" => length(kept),
       "suppressed_candidate_count" => length(suppressed),
       "invalid_candidate_input_count" => invalid_candidate_input_count(suppressed),
       "invalid_candidate_input_ids" => invalid_candidate_input_ids(suppressed),
       "duplicate_suppressed_candidate_id_count" =>
         length(duplicate_suppressed_candidate_id_groups),
       "duplicate_suppressed_candidate_row_count" =>
         duplicate_suppressed_candidate_row_count(duplicate_suppressed_candidate_id_groups),
       "suppressed_candidates" => suppressed
     }}
  end

  def filter_candidates(_candidates, _summaries, _opts),
    do: raise(ArgumentError, "candidates and summaries must be lists")

  @doc """
  Builds only the `resource_filter_report.v1`, discarding kept candidates.
  """
  def report(resource_filter_report)

  def report(%{"schema_contract" => @schema_contract} = report) do
    report
  end

  def report(%{schema_contract: @schema_contract} = report) do
    stringify_keys(report)
  end

  def report(_resource_filter_report),
    do: raise(ArgumentError, "resource filter report must be a map")

  def report(candidates, summaries, opts \\ []) do
    {_kept, report} = filter_candidates(candidates, summaries, opts)
    report
  end

  @doc """
  Builds a compact artifact-only resource suppression summary.

  This helper accepts either an existing `resource_filter_report.v1`, an
  existing `resource_filter_summary.v1`, or the candidate and resource-summary
  inputs used to build one. It exposes suppressed-resource routing counts, ID
  maps, invalid-input evidence, and review rows without mutating schedules or
  propagating resource state.
  """
  def summary(resource_filter_report)

  def summary(%{"schema_contract" => @summary_schema_contract} = summary), do: summary

  def summary(%{"schema_contract" => @schema_contract} = report), do: summary(report, [])

  def summary(%{schema_contract: @summary_schema_contract} = summary) do
    stringify_keys(summary)
  end

  def summary(%{schema_contract: @schema_contract} = report) do
    report
    |> stringify_keys()
    |> summary()
  end

  def summary(_resource_filter_report),
    do: raise(ArgumentError, "resource filter report is required")

  def summary(resource_filter_report, opts)

  def summary(%{"schema_contract" => @summary_schema_contract} = summary, opts)
      when is_list(opts),
      do: summary

  def summary(%{"schema_contract" => @schema_contract} = report, opts) when is_list(opts) do
    resource_filter_summary(report)
  end

  def summary(%{schema_contract: @summary_schema_contract} = summary, opts) when is_list(opts) do
    stringify_keys(summary)
  end

  def summary(%{schema_contract: @schema_contract} = report, opts) when is_list(opts) do
    report
    |> stringify_keys()
    |> summary(opts)
  end

  def summary(_resource_filter_report, _opts),
    do: raise(ArgumentError, "resource filter report is required")

  def summary(candidates, summaries, opts) when is_list(candidates) and is_list(summaries) do
    candidates
    |> report(summaries, opts)
    |> summary(opts)
  end

  def summary(_candidates, _summaries, _opts),
    do: raise(ArgumentError, "candidates and summaries must be lists")

  @doc """
  Normalizes resource filter policy thresholds.
  """
  def resource_filter_policy(policy) do
    policy = stringify_keys(policy || %{})

    Map.new(@resource_filter_policy_fields, fn field ->
      {field, policy_number_or_nil(policy, field)}
    end)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp model_limits do
    capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  defp capability_assumptions do
    capabilities = capabilities()

    %{
      "resource_filter_policy_fields" => capabilities.resource_filter_policy_fields,
      "resource_availability_aliases" => capabilities.resource_availability_aliases,
      "resource_degraded_aliases" => capabilities.resource_degraded_aliases,
      "resource_margin_aliases" => capabilities.resource_margin_aliases,
      "resource_power_margin_source_aliases" => capabilities.resource_power_margin_source_aliases,
      "resource_availability_true_tokens" => capabilities.resource_availability_true_tokens,
      "resource_availability_false_tokens" => capabilities.resource_availability_false_tokens,
      "provider_direction_aliases" => capabilities.provider_direction_aliases,
      "station_calendar_direction_aliases" => capabilities.station_calendar_direction_aliases,
      "provider_result_map_value_keys" => capabilities.provider_result_map_value_keys,
      "candidate_stable_identity_fields" => capabilities.candidate_stable_identity_fields,
      "station_calendar_id_list_fields" => capabilities.station_calendar_id_list_fields,
      "suppression_reasons" => capabilities.suppression_reasons,
      "row_review_statuses" => capabilities.row_review_statuses
    }
  end

  defp resource_filter_summary(report) do
    report = stringify_keys(report)

    suppressed =
      report
      |> Map.get("suppressed_candidates", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)

    invalid_summary_inputs =
      report
      |> Map.get("invalid_resource_summary_inputs", [])
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)

    %{
      "schema_contract" => @summary_schema_contract,
      "model" => "artifact_only_resource_filter_summary",
      "source_artifact_type" => Map.get(report, "schema_contract", @schema_contract),
      "model_limits" => model_limits(),
      "input_candidate_count" => Map.get(report, "input_candidate_count", 0),
      "kept_candidate_count" => Map.get(report, "kept_candidate_count", 0),
      "suppressed_candidate_count" => length(suppressed),
      "suppression_review_status" =>
        if(suppressed == [] and invalid_summary_inputs == [],
          do: "clear",
          else: "review_required"
        ),
      "suppressed_candidate_ids" => row_ids(suppressed, "id"),
      "suppressed_reason_counts" => count_by_field(suppressed, "suppressed_reason"),
      "suppressed_candidate_ids_by_reason" => ids_by_field(suppressed, "suppressed_reason", "id"),
      "resource_blocking_dimension_counts" =>
        count_by_field(suppressed, "resource_blocking_dimension"),
      "suppressed_candidate_ids_by_resource_blocking_dimension" =>
        ids_by_field(suppressed, "resource_blocking_dimension", "id"),
      "suppressed_candidate_ids_by_spacecraft_id" =>
        ids_by_field(suppressed, "spacecraft_id", "id"),
      "suppressed_candidate_ids_by_scenario_id" => ids_by_field(suppressed, "scenario_id", "id"),
      "suppressed_resource_source_quality_counts" =>
        count_by_field(suppressed, "resource_source_quality"),
      "suppressed_candidate_ids_by_resource_source_quality" =>
        ids_by_field(suppressed, "resource_source_quality", "id"),
      "suppressed_resource_trust_boundary_status_counts" =>
        count_by_field(suppressed, "resource_trust_boundary_status"),
      "suppressed_candidate_ids_by_resource_trust_boundary_status" =>
        ids_by_field(suppressed, "resource_trust_boundary_status", "id"),
      "invalid_candidate_input_count" => invalid_candidate_input_count(suppressed),
      "invalid_candidate_input_ids" => invalid_candidate_input_ids(suppressed),
      "invalid_resource_summary_input_count" => length(invalid_summary_inputs),
      "invalid_resource_summary_input_ids" =>
        row_ids(invalid_summary_inputs, "resource_summary_id"),
      "duplicate_suppressed_candidate_id_count" =>
        duplicate_suppressed_candidate_id_count(suppressed),
      "duplicate_suppressed_candidate_row_count" =>
        duplicate_suppressed_candidate_row_count_from_rows(suppressed),
      "review_rows" => suppressed,
      "invalid_resource_summary_inputs" => invalid_summary_inputs,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "source" => "resource_filter_report.v1",
        "operator_authority" => "not_granted_by_resource_filter_summary",
        "resource_state_propagation" => "not_performed"
      }
    }
    |> compact_map()
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
      |> normalize_resource_power_margin()
      |> put_spacecraft_alias()

    case resource_summary_input_issue(summary) do
      nil -> summary
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
    |> put_resource_provenance_alias("source_quality", [
      "resource_source_quality",
      ["provenance", "source_quality"],
      ["provenance", "resource_source_quality"],
      ["provenance", "quality"]
    ])
    |> put_resource_provenance_alias("trust_boundary", [
      "resource_trust_boundary",
      ["provenance", "trust_boundary"],
      ["provenance", "resource_trust_boundary"]
    ])
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
      "id" => "resource_filter:invalid_resource_summary:#{resource_summary_id}",
      "resource_summary_id" => resource_summary_id,
      "spacecraft_id" => stable_id_or_nil(summary["spacecraft_id"]),
      "required_operator_action" => "review_invalid_resource_filter_summary",
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

  defp summaries_by_key(summaries) do
    summaries
    |> Enum.group_by(&resource_summary_lookup_key/1)
    |> Map.new(fn {key, grouped_summaries} ->
      summary =
        case grouped_summaries do
          [summary] -> summary
          summaries -> ambiguous_resource_summary(key, summaries)
        end

      {key, summary}
    end)
  end

  defp resource_summary_lookup_key(%{"spacecraft_id" => spacecraft_id})
       when spacecraft_id not in [nil, ""],
       do: spacecraft_id

  defp resource_summary_lookup_key(_summary), do: "*"

  defp ambiguous_resource_summary(key, summaries) do
    source_qualities =
      summaries
      |> Enum.map(&(Map.get(&1, "source_quality") || "unknown"))
      |> Enum.uniq()
      |> Enum.sort()

    trust_boundary_statuses =
      summaries
      |> Enum.map(&resource_trust_boundary_status/1)
      |> Enum.uniq()
      |> Enum.sort()

    %{
      "spacecraft_id" => if(key == "*", do: nil, else: key),
      "ambiguous_resource_summary" => true,
      "resource_summary_key" => key,
      "resource_summary_count" => length(summaries),
      "source_quality" => "ambiguous",
      "resource_source_qualities" => source_qualities,
      "resource_trust_boundary_status" => "ambiguous",
      "resource_trust_boundary_statuses" => trust_boundary_statuses,
      "source_resource_summaries" => summaries
    }
    |> compact_map()
  end

  defp candidate_resource_summary(candidate, summaries_by_key) do
    Map.get(summaries_by_key, candidate["spacecraft_id"]) ||
      Map.get(summaries_by_key, candidate["scenario_id"]) ||
      Map.get(summaries_by_key, "*")
  end

  defp suppression(candidate, summary, policy) do
    summary = summary || %{}

    case suppression_reason(candidate, summary, policy) do
      nil -> nil
      reason -> {reason, summary}
    end
  end

  defp annotate_kept_candidate(candidate, nil), do: candidate

  defp annotate_kept_candidate(candidate, summary) do
    candidate
    |> Map.merge(resource_summary_context(summary))
    |> compact_map()
  end

  defp resource_summary_context(%{"ambiguous_resource_summary" => true} = summary) do
    %{
      "ambiguous_resource_summary" => true,
      "resource_summary_key" => summary["resource_summary_key"],
      "resource_summary_count" => summary["resource_summary_count"],
      "resource_source_quality" => summary["source_quality"],
      "resource_source_qualities" => summary["resource_source_qualities"],
      "resource_trust_boundary_status" => summary["resource_trust_boundary_status"],
      "resource_trust_boundary_statuses" => summary["resource_trust_boundary_statuses"],
      "source_resource_summaries" => summary["source_resource_summaries"]
    }
    |> compact_map()
  end

  defp resource_summary_context(summary) do
    %{
      "resource_source_quality" => summary["source_quality"],
      "resource_trust_boundary" => resource_trust_boundary(summary),
      "resource_trust_boundary_status" => resource_trust_boundary_status(summary),
      "resource_provenance" => summary["provenance"],
      "fuel_margin" => summary["fuel_margin"],
      "thermal_margin_c" => summary["thermal_margin_c"],
      "power_margin" => summary["power_margin"],
      "storage_margin" => summary["storage_margin"],
      "downlink_margin" => summary["downlink_margin"],
      "battery_capacity_wh" => summary["battery_capacity_wh"],
      "battery_energy_used_wh" => summary["battery_energy_used_wh"],
      "battery_state_of_charge" => summary["battery_state_of_charge"],
      "spacecraft_available" => spacecraft_available(summary),
      "payload_available" => summary["payload_available"],
      "antenna_available" => summary["antenna_available"],
      "degraded" => summary["degraded"],
      "mode" => summary["mode"],
      "incompatible_activity_types" => summary["incompatible_activity_types"],
      "suppressed_activity_types" => summary["suppressed_activity_types"],
      "source_resource_summary" => summary
    }
  end

  defp suppression_reason(%{"invalid_candidate_input" => true}, _summary, _policy),
    do: "invalid_candidate_input"

  defp suppression_reason(_candidate, %{"ambiguous_resource_summary" => true}, _policy),
    do: "ambiguous_resource_summary"

  defp suppression_reason(candidate, summary, policy) do
    cond do
      spacecraft_unavailable?(summary) ->
        "spacecraft_unavailable"

      margin_below?(summary, "fuel_margin", policy["min_activity_fuel_margin"]) ->
        "fuel_margin_below_policy"

      margin_below?(summary, "thermal_margin_c", policy["min_activity_thermal_margin_c"]) ->
        "thermal_margin_below_policy"

      candidate["type"] == "observe" and Map.get(summary, "payload_available") == false ->
        "payload_unavailable"

      candidate["type"] == "observe" and Map.get(summary, "degraded") == true ->
        "spacecraft_degraded_payload_unavailable"

      activity_type_suppressed?(candidate, summary["suppressed_activity_types"]) ->
        "activity_type_suppressed_by_resource_summary"

      activity_type_suppressed?(candidate, summary["incompatible_activity_types"]) ->
        "activity_type_incompatible_with_resource_summary"

      candidate["type"] == "observe" and
          margin_below?(summary, "power_margin", policy["min_observe_power_margin"]) ->
        "power_margin_below_observe_policy"

      candidate["type"] == "observe" and
          margin_below?(summary, "storage_margin", policy["min_observe_storage_margin"]) ->
        "storage_margin_below_observe_policy"

      antenna_required_candidate?(candidate) and Map.get(summary, "antenna_available") == false ->
        "antenna_unavailable"

      downlink_candidate?(candidate) and
          margin_below?(summary, "power_margin", policy["min_downlink_power_margin"]) ->
        "power_margin_below_downlink_policy"

      downlink_candidate?(candidate) and
          margin_below?(summary, "downlink_margin", policy["min_downlink_margin"]) ->
        "downlink_margin_below_policy"

      true ->
        nil
    end
  end

  defp spacecraft_unavailable?(summary) do
    Map.get(summary, "spacecraft_available") == false or
      Map.get(summary, "spacecraft_availability") == false
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

  defp downlink_candidate?(%{"type" => "downlink"}), do: true
  defp downlink_candidate?(%{"type" => "planned_contact", "direction" => "downlink"}), do: true

  defp downlink_candidate?(%{"direction" => "downlink", "ground_station_id" => station_id})
       when not is_nil(station_id),
       do: true

  defp downlink_candidate?(_candidate), do: false

  defp antenna_required_candidate?(%{"type" => type})
       when type in ["downlink", "tracking", "uplink", "command", "health_check"],
       do: true

  defp antenna_required_candidate?(%{"type" => "planned_contact", "direction" => direction})
       when direction in ["downlink", "tracking", "uplink", "command", "health_check"],
       do: true

  defp antenna_required_candidate?(%{
         "direction" => direction,
         "ground_station_id" => station_id
       })
       when direction in ["downlink", "tracking", "uplink", "command", "health_check"] and
              not is_nil(station_id),
       do: true

  defp antenna_required_candidate?(candidate), do: downlink_candidate?(candidate)

  defp margin_below?(_summary, _field, nil), do: false

  defp margin_below?(summary, field, threshold) do
    case Map.get(summary, field) do
      value when is_number(value) -> value < threshold
      _value -> false
    end
  end

  defp suppressed_candidate(candidate, reason, summary) do
    %{
      "id" => candidate["id"],
      "type" => candidate["type"],
      "scenario_id" => stable_id_or_nil(candidate["scenario_id"]),
      "spacecraft_id" =>
        stable_id_or_nil(candidate["spacecraft_id"]) || stable_id_or_nil(summary["spacecraft_id"]),
      "starts_at_s" => candidate["starts_at_s"],
      "ends_at_s" => candidate["ends_at_s"],
      "suppressed_reason" => reason,
      "resource_blocking_dimension" => resource_blocking_dimension(reason),
      "source_window_id" => stable_id_or_nil(candidate["source_window_id"]),
      "ground_station_id" => stable_id_or_nil(candidate["ground_station_id"]),
      "target_id" => stable_id_or_nil(candidate["target_id"]),
      "direction" => candidate["direction"] || resource_direction(candidate),
      "station_availability" => candidate["station_availability"],
      "station_calendar_entry_id" => candidate_station_calendar_entry_id(candidate),
      "station_calendar_directions" => candidate["station_calendar_directions"],
      "station_calendar_status" => candidate["station_calendar_status"],
      "station_calendar_overlap_count" => candidate["station_calendar_overlap_count"],
      "station_calendar_overlap_entry_ids" => candidate["station_calendar_overlap_entry_ids"],
      "station_calendar_overlap_availabilities" =>
        candidate["station_calendar_overlap_availabilities"],
      "station_calendar_entry_ambiguous" => candidate["station_calendar_entry_ambiguous"],
      "station_calendar_ambiguous_entry_count" =>
        candidate["station_calendar_ambiguous_entry_count"],
      "station_calendar_ambiguous_entry_ids" => candidate["station_calendar_ambiguous_entry_ids"],
      "station_calendar_reservation_overlap_count" =>
        candidate["station_calendar_reservation_overlap_count"],
      "station_calendar_reservation_ids" => candidate["station_calendar_reservation_ids"],
      "station_calendar_reserved_by" => candidate["station_calendar_reserved_by"],
      "station_calendar_reservation_statuses" =>
        candidate["station_calendar_reservation_statuses"],
      "source_station_calendar_entry" => candidate["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => candidate["source_station_calendar_overlaps"],
      "station_contention_status" => candidate["station_contention_status"],
      "station_reservation_id" => stable_id_or_nil(candidate["station_reservation_id"]),
      "station_reserved_by" => candidate["station_reserved_by"],
      "station_reservation_status" => candidate["station_reservation_status"],
      "station_reservation_match_status" => candidate["station_reservation_match_status"],
      "contact_success" => candidate["contact_success"],
      "contact_result" => provider_result_artifact_value(candidate["contact_result"]),
      "contact_success_factor" => unit_interval_factor(candidate, "contact_success_factor"),
      "contact_success_factor_source" => candidate["contact_success_factor_source"],
      "command_success" => candidate["command_success"],
      "command_result" => provider_result_artifact_value(candidate["command_result"]),
      "command_success_factor" => unit_interval_factor(candidate, "command_success_factor"),
      "command_success_factor_source" => candidate["command_success_factor_source"],
      "resource_source_quality" => summary["source_quality"],
      "resource_trust_boundary" => resource_trust_boundary(summary),
      "resource_trust_boundary_status" => resource_trust_boundary_status(summary),
      "resource_provenance" => summary["provenance"],
      "fuel_margin" => summary["fuel_margin"],
      "thermal_margin_c" => summary["thermal_margin_c"],
      "power_margin" => summary["power_margin"],
      "storage_margin" => summary["storage_margin"],
      "downlink_margin" => summary["downlink_margin"],
      "battery_capacity_wh" => summary["battery_capacity_wh"],
      "battery_energy_used_wh" => summary["battery_energy_used_wh"],
      "battery_state_of_charge" => summary["battery_state_of_charge"],
      "spacecraft_available" => spacecraft_available(summary),
      "payload_available" => summary["payload_available"],
      "antenna_available" => summary["antenna_available"],
      "degraded" => summary["degraded"],
      "mode" => summary["mode"],
      "incompatible_activity_types" => summary["incompatible_activity_types"],
      "suppressed_activity_types" => summary["suppressed_activity_types"],
      "invalid_candidate_input" => candidate["invalid_candidate_input"],
      "invalid_candidate_input_reason" => candidate["invalid_candidate_input_reason"],
      "source_candidate" => candidate["source_candidate"]
    }
    |> Map.merge(resource_summary_context(summary))
    |> normalize_station_calendar_id_lists()
    |> compact_map()
  end

  defp disambiguate_suppressed_candidate_ids(suppressed_candidates) do
    duplicates = duplicate_suppressed_candidate_id_groups(suppressed_candidates)
    duplicate_ids = duplicates |> Enum.map(fn {id, _rows} -> id end) |> MapSet.new()
    duplicate_counts = Map.new(duplicates, fn {id, rows} -> {id, length(rows)} end)

    {rows, _indexes} =
      Enum.map_reduce(suppressed_candidates, %{}, fn row, indexes ->
        row_id = row["id"]
        index = Map.get(indexes, row_id, 0) + 1
        indexes = Map.put(indexes, row_id, index)

        row =
          if MapSet.member?(duplicate_ids, row_id) do
            row
            |> Map.put("id", "#{row_id}:#{index}")
            |> Map.put("base_candidate_id", row_id)
            |> Map.put("duplicate_suppressed_candidate_id_collision", true)
            |> Map.put("duplicate_suppressed_candidate_index", index)
            |> Map.put(
              "duplicate_suppressed_candidate_count",
              Map.fetch!(duplicate_counts, row_id)
            )
          else
            row
          end

        {row, indexes}
      end)

    rows
  end

  defp duplicate_suppressed_candidate_id_groups(suppressed_candidates) do
    suppressed_candidates
    |> Enum.group_by(&Map.get(&1, "base_candidate_id", Map.get(&1, "id")))
    |> Enum.filter(fn {_candidate_id, rows} -> length(rows) > 1 end)
    |> Enum.sort_by(fn {candidate_id, _rows} -> candidate_id end)
  end

  defp duplicate_suppressed_candidate_row_count(duplicate_groups) do
    duplicate_groups
    |> Enum.map(fn {_candidate_id, rows} -> length(rows) end)
    |> Enum.sum()
  end

  defp invalid_candidate_input_count(suppressed) do
    Enum.count(suppressed, &(&1["invalid_candidate_input"] == true))
  end

  defp invalid_candidate_input_ids(suppressed) do
    suppressed
    |> Enum.filter(&(&1["invalid_candidate_input"] == true))
    |> Enum.map(& &1["id"])
    |> Enum.reject(&is_nil/1)
    |> Enum.sort()
  end

  defp maybe_apply_approval_policy(row, nil), do: row

  defp maybe_apply_approval_policy(row, approval_policy) do
    requirement = resource_suppression_approval_requirement(row)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        resource_suppression_risks(row),
        %{"id" => "resource_filter", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  defp resource_suppression_approval_requirement(row) do
    %{
      "activity_id" => row["id"],
      "activity_type" => row["type"],
      "action" => resource_filter_approval_action(row),
      "requirement_type" => resource_requirement_type(row),
      "reason" => row["suppressed_reason"] || "resource filter suppressed candidate",
      "activity_context" =>
        %{
          "spacecraft_id" => row["spacecraft_id"],
          "scenario_id" => row["scenario_id"],
          "direction" => resource_direction(row),
          "ground_station_id" => row["ground_station_id"],
          "source_window_id" => row["source_window_id"],
          "starts_at_s" => row["starts_at_s"],
          "ends_at_s" => row["ends_at_s"],
          "station_availability" => row["station_availability"],
          "station_calendar_entry_id" => row["station_calendar_entry_id"],
          "station_calendar_directions" => row["station_calendar_directions"],
          "station_calendar_status" => row["station_calendar_status"],
          "station_calendar_overlap_count" => row["station_calendar_overlap_count"],
          "station_calendar_overlap_entry_ids" => row["station_calendar_overlap_entry_ids"],
          "station_calendar_overlap_availabilities" =>
            row["station_calendar_overlap_availabilities"],
          "station_calendar_entry_ambiguous" => row["station_calendar_entry_ambiguous"],
          "station_calendar_ambiguous_entry_count" =>
            row["station_calendar_ambiguous_entry_count"],
          "station_calendar_ambiguous_entry_ids" => row["station_calendar_ambiguous_entry_ids"],
          "station_calendar_reservation_overlap_count" =>
            row["station_calendar_reservation_overlap_count"],
          "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
          "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
          "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
          "source_station_calendar_entry" => row["source_station_calendar_entry"],
          "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
          "station_contention_status" => row["station_contention_status"],
          "station_reservation_id" => row["station_reservation_id"],
          "station_reserved_by" => row["station_reserved_by"],
          "station_reservation_status" => row["station_reservation_status"],
          "station_reservation_match_status" => row["station_reservation_match_status"],
          "contact_success" => row["contact_success"],
          "contact_result" => row["contact_result"],
          "contact_success_factor" => row["contact_success_factor"],
          "contact_success_factor_source" => row["contact_success_factor_source"],
          "command_success" => row["command_success"],
          "command_result" => row["command_result"],
          "command_success_factor" => row["command_success_factor"],
          "command_success_factor_source" => row["command_success_factor_source"],
          "suppressed_reason" => row["suppressed_reason"],
          "resource_source_quality" => row["resource_source_quality"],
          "resource_trust_boundary" => row["resource_trust_boundary"],
          "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
          "resource_provenance" => row["resource_provenance"],
          "resource_blocking_dimension" => row["resource_blocking_dimension"],
          "fuel_margin" => row["fuel_margin"],
          "thermal_margin_c" => row["thermal_margin_c"],
          "power_margin" => row["power_margin"],
          "storage_margin" => row["storage_margin"],
          "downlink_margin" => row["downlink_margin"],
          "battery_capacity_wh" => row["battery_capacity_wh"],
          "battery_energy_used_wh" => row["battery_energy_used_wh"],
          "battery_state_of_charge" => row["battery_state_of_charge"],
          "payload_available" => row["payload_available"],
          "antenna_available" => row["antenna_available"],
          "degraded" => row["degraded"],
          "mode" => row["mode"],
          "incompatible_activity_types" => row["incompatible_activity_types"],
          "suppressed_activity_types" => row["suppressed_activity_types"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp resource_filter_approval_action(%{"invalid_candidate_input" => true}),
    do: "review_invalid_resource_filter_input"

  defp resource_filter_approval_action(row), do: resource_suppression_action(row)

  defp maybe_apply_invalid_summary_approval_policy(row, nil), do: row

  defp maybe_apply_invalid_summary_approval_policy(row, approval_policy) do
    requirement = invalid_summary_approval_requirement(row)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        invalid_summary_risks(row),
        %{"id" => "resource_filter", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  defp invalid_summary_approval_requirement(row) do
    %{
      "activity_id" => row["id"],
      "activity_type" => "resource_filter_invalid_summary",
      "action" => "review_invalid_resource_filter_summary",
      "requirement_type" => "operator_review",
      "reason" =>
        row["invalid_resource_summary_input_reason"] || "invalid resource summary input",
      "activity_context" =>
        %{
          "spacecraft_id" => row["spacecraft_id"],
          "resource_summary_id" => row["resource_summary_id"],
          "invalid_resource_summary_input" => row["invalid_resource_summary_input"],
          "invalid_resource_summary_input_reason" => row["invalid_resource_summary_input_reason"],
          "source_resource_summary" => row["source_resource_summary"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp invalid_summary_risks(row) do
    [
      %{
        "type" => "invalid_resource_summary_input",
        "severity" => "medium",
        "reason" =>
          row["invalid_resource_summary_input_reason"] || "invalid resource summary input",
        "activity_id" => row["id"],
        "activity_type" => "resource_filter_invalid_summary",
        "spacecraft_id" => row["spacecraft_id"]
      }
      |> compact_map()
    ]
  end

  defp resource_suppression_action(row) do
    cond do
      antenna_required_candidate?(row) -> "review_suppressed_contact"
      row["type"] == "observe" -> "review_suppressed_observation"
      true -> "review_suppressed_candidate"
    end
  end

  defp resource_requirement_type(row) do
    cond do
      health_check_contact_candidate?(row) -> "health_check_review"
      command_contact_candidate?(row) -> "command_review"
      antenna_required_candidate?(row) -> "contact_schedule_change"
      row["type"] == "observe" -> "observation_reassignment"
      true -> "operator_review"
    end
  end

  defp command_contact_candidate?(row) do
    resource_direction(row) in ["command", "uplink"]
  end

  defp health_check_contact_candidate?(row) do
    resource_direction(row) == "health_check"
  end

  defp resource_direction(%{"direction" => direction}) when is_binary(direction), do: direction
  defp resource_direction(%{"type" => "downlink"}), do: "downlink"
  defp resource_direction(%{"type" => "tracking"}), do: "tracking"
  defp resource_direction(%{"type" => "uplink"}), do: "uplink"
  defp resource_direction(%{"type" => "command"}), do: "command"
  defp resource_direction(%{"type" => "health_check"}), do: "health_check"
  defp resource_direction(_row), do: nil

  defp resource_suppression_risks(%{"suppressed_reason" => reason} = row) do
    reason
    |> resource_risk_type()
    |> case do
      nil ->
        []

      risk_type ->
        [
          %{
            "type" => risk_type,
            "severity" => "medium",
            "reason" => reason,
            "resource_blocking_dimension" => row["resource_blocking_dimension"],
            "activity_id" => row["id"],
            "activity_type" => row["type"],
            "spacecraft_id" => row["spacecraft_id"],
            "scenario_id" => row["scenario_id"],
            "ground_station_id" => row["ground_station_id"],
            "target_id" => row["target_id"],
            "direction" => row["direction"]
          }
          |> compact_map()
        ]
    end
  end

  defp resource_suppression_risks(_row), do: []

  defp resource_risk_type("fuel_margin_below_policy"), do: "fuel_margin_low"
  defp resource_risk_type("thermal_margin_below_policy"), do: "thermal_margin_low"
  defp resource_risk_type("spacecraft_unavailable"), do: "spacecraft_unavailable"
  defp resource_risk_type("payload_unavailable"), do: "payload_unavailable"
  defp resource_risk_type("spacecraft_degraded_payload_unavailable"), do: "spacecraft_degraded"

  defp resource_risk_type("activity_type_suppressed_by_resource_summary"),
    do: "activity_type_suppressed"

  defp resource_risk_type("activity_type_incompatible_with_resource_summary"),
    do: "activity_type_incompatible"

  defp resource_risk_type("antenna_unavailable"), do: "antenna_unavailable"
  defp resource_risk_type("storage_margin_below_observe_policy"), do: "storage_overflow"
  defp resource_risk_type("downlink_margin_below_policy"), do: "downlink_shortfall"
  defp resource_risk_type("power_margin_below_observe_policy"), do: "power_margin_low"
  defp resource_risk_type("power_margin_below_downlink_policy"), do: "power_margin_low"
  defp resource_risk_type("invalid_candidate_input"), do: "invalid_resource_candidate_input"
  defp resource_risk_type(_reason), do: nil

  defp resource_blocking_dimension("fuel_margin_below_policy"), do: "fuel"
  defp resource_blocking_dimension("thermal_margin_below_policy"), do: "thermal"
  defp resource_blocking_dimension("spacecraft_unavailable"), do: "spacecraft_health"
  defp resource_blocking_dimension("payload_unavailable"), do: "payload"

  defp resource_blocking_dimension("spacecraft_degraded_payload_unavailable"),
    do: "spacecraft_health"

  defp resource_blocking_dimension("activity_type_suppressed_by_resource_summary"),
    do: "activity_type"

  defp resource_blocking_dimension("activity_type_incompatible_with_resource_summary"),
    do: "activity_type"

  defp resource_blocking_dimension("ambiguous_resource_summary"), do: "resource_summary"
  defp resource_blocking_dimension("power_margin_below_observe_policy"), do: "power"
  defp resource_blocking_dimension("power_margin_below_downlink_policy"), do: "power"
  defp resource_blocking_dimension("storage_margin_below_observe_policy"), do: "storage"
  defp resource_blocking_dimension("antenna_unavailable"), do: "antenna"
  defp resource_blocking_dimension("downlink_margin_below_policy"), do: "downlink"
  defp resource_blocking_dimension(_reason), do: nil

  defp resource_source_quality_counts(summaries) do
    summaries
    |> Enum.map(&(Map.get(&1, "source_quality") || "unknown"))
    |> Enum.frequencies()
  end

  defp resource_trust_boundary_status_counts(summaries) do
    summaries
    |> Enum.map(&resource_trust_boundary_status/1)
    |> Enum.frequencies()
  end

  defp suppressed_resource_source_quality_counts(suppressed) do
    suppressed
    |> Enum.map(&Map.get(&1, "resource_source_quality"))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {quality, _count} -> quality end)
    |> Map.new()
  end

  defp suppressed_candidate_ids_by_resource_source_quality(suppressed) do
    suppressed
    |> Enum.map(&{Map.get(&1, "resource_source_quality"), Map.get(&1, "id")})
    |> stable_ids_by_key()
  end

  defp suppressed_resource_trust_boundary_status_counts(suppressed) do
    suppressed
    |> Enum.map(&Map.get(&1, "resource_trust_boundary_status"))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {status, _count} -> status end)
    |> Map.new()
  end

  defp suppressed_candidate_ids_by_resource_trust_boundary_status(suppressed) do
    suppressed
    |> Enum.map(&{Map.get(&1, "resource_trust_boundary_status"), Map.get(&1, "id")})
    |> stable_ids_by_key()
  end

  defp count_by_field(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> Enum.sort_by(fn {key, _count} -> key end)
    |> Map.new()
  end

  defp ids_by_field(rows, field, id_field) do
    rows
    |> Enum.map(&{Map.get(&1, field), Map.get(&1, id_field)})
    |> stable_ids_by_key()
  end

  defp row_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> sorted_stable_ids()
  end

  defp duplicate_suppressed_candidate_id_count(rows) do
    rows
    |> duplicate_suppressed_candidate_id_groups()
    |> length()
  end

  defp duplicate_suppressed_candidate_row_count_from_rows(rows) do
    rows
    |> duplicate_suppressed_candidate_id_groups()
    |> duplicate_suppressed_candidate_row_count()
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

  defp resource_trust_boundary(%{"ambiguous_resource_summary" => true}), do: nil

  defp resource_trust_boundary(summary) do
    Map.get(summary, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"])
  end

  defp resource_trust_boundary_status(%{"ambiguous_resource_summary" => true}), do: "ambiguous"

  defp resource_trust_boundary_status(summary) do
    case resource_trust_boundary(summary) do
      value when is_binary(value) and value != "" -> "declared"
      _value -> "missing"
    end
  end

  defp policy_number_or_nil(policy, key) do
    case Map.get(policy, key) do
      value when is_number(value) -> value * 1.0
      value when is_binary(value) -> numeric_or_nil(value)
      _value -> nil
    end
  end

  defp normalize_candidate(%{} = candidate, index) do
    candidate
    |> stringify_keys()
    |> put_ground_station_alias()
    |> put_time_alias("starts_at_s", "start_s")
    |> put_time_alias("ends_at_s", "end_s")
    |> put_activity_type_alias()
    |> put_provider_direction_alias()
    |> put_station_calendar_directions()
    |> put_provider_downlink_shape()
    |> put_direction_contact_shape()
    |> maybe_invalid_candidate_input(index)
  end

  defp normalize_candidate(candidate, _index) do
    %{
      "id" => "missing_candidate_id",
      "type" => "invalid_candidate_input",
      "scenario_id" => "missing_scenario_id",
      "invalid_candidate_input" => true,
      "invalid_candidate_input_reason" => "invalid_candidate_shape",
      "source_candidate" => %{"raw_input" => inspect(candidate)}
    }
  end

  defp maybe_invalid_candidate_input(candidate, index) do
    cond do
      reason = candidate_id_issue(candidate["id"]) ->
        invalid_candidate_input(candidate, index, reason)

      not valid_candidate_kind?(candidate) ->
        invalid_candidate_input(candidate, index, "missing_candidate_type")

      reason = candidate_identity_issue(candidate) ->
        invalid_candidate_input(candidate, index, reason)

      reason = candidate_feedback_factor_issue(candidate) ->
        invalid_candidate_input(candidate, index, reason)

      true ->
        candidate
    end
  end

  defp candidate_feedback_factor_issue(candidate) do
    Enum.find_value(["contact_success_factor", "command_success_factor"], fn field ->
      case Map.get(candidate, field) do
        nil ->
          nil

        value ->
          case numeric_or_nil(value) do
            number when is_number(number) ->
              if number >= 0.0 and number <= 1.0, do: nil, else: "invalid_#{field}"

            _value ->
              "invalid_#{field}"
          end
      end
    end)
  end

  defp invalid_candidate_input(candidate, index, reason) do
    candidate_id =
      case candidate["id"] do
        value when is_binary(value) and value != "" ->
          stable_id_or_nil(value) || "#{reason}:#{index}"

        _value ->
          "#{reason}:#{index}"
      end

    %{
      "id" => candidate_id,
      "type" => candidate_type_or_invalid(candidate),
      "scenario_id" =>
        stable_id_or_nil(Map.get(candidate, "scenario_id")) ||
          "missing_scenario_id:#{candidate_id}",
      "spacecraft_id" => stable_id_or_nil(candidate["spacecraft_id"]),
      "source_window_id" => stable_id_or_nil(candidate["source_window_id"]),
      "ground_station_id" => stable_id_or_nil(candidate["ground_station_id"]),
      "target_id" => stable_id_or_nil(candidate["target_id"]),
      "station_calendar_entry_id" => candidate_station_calendar_entry_id(candidate),
      "station_calendar_directions" => candidate["station_calendar_directions"],
      "station_calendar_overlap_entry_ids" => candidate["station_calendar_overlap_entry_ids"],
      "station_calendar_ambiguous_entry_ids" => candidate["station_calendar_ambiguous_entry_ids"],
      "station_calendar_reservation_ids" => candidate["station_calendar_reservation_ids"],
      "source_station_calendar_entry" => candidate["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => candidate["source_station_calendar_overlaps"],
      "station_reservation_id" => stable_id_or_nil(candidate["station_reservation_id"]),
      "starts_at_s" => candidate["starts_at_s"],
      "ends_at_s" => candidate["ends_at_s"],
      "invalid_candidate_input" => true,
      "invalid_candidate_input_reason" => reason,
      "source_candidate" => candidate
    }
    |> normalize_station_calendar_id_lists()
    |> compact_map()
  end

  defp candidate_id_issue(id) when id in [nil, ""], do: "missing_candidate_id"
  defp candidate_id_issue(id), do: if(stable_id?(id), do: nil, else: "invalid_candidate_id")

  defp candidate_identity_issue(candidate) do
    Enum.find_value(@candidate_stable_identity_fields, fn field ->
      value = Map.get(candidate, field)

      cond do
        value in [nil, ""] -> nil
        stable_id?(value) -> nil
        true -> "invalid_#{field}"
      end
    end)
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

  defp candidate_station_calendar_entry_id(candidate) do
    stable_id_or_nil(candidate["station_calendar_entry_id"]) ||
      stable_id_or_nil(
        get_in(candidate, ["source_station_calendar_entry", "station_calendar_entry_id"])
      ) ||
      stable_id_or_nil(get_in(candidate, ["source_station_calendar_entry", "id"]))
  end

  defp normalize_station_calendar_id_lists(context) do
    Enum.reduce(@station_calendar_id_list_fields, context, fn field, acc ->
      case normalize_id_list(Map.get(acc, field)) do
        nil -> Map.delete(acc, field)
        ids -> Map.put(acc, field, ids)
      end
    end)
  end

  defp normalize_id_list(nil), do: nil

  defp normalize_id_list(values) when is_list(values) do
    values
    |> Enum.flat_map(&id_values/1)
    |> Enum.flat_map(&stable_id_value/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp normalize_id_list(value), do: normalize_id_list([value])

  defp id_values(%{} = value) do
    ["id", "station_calendar_entry_id", "station_reservation_id", "reservation_id"]
    |> Enum.flat_map(fn key ->
      case Map.get(value, key) do
        nil -> []
        nested when is_list(nested) -> nested
        nested -> [nested]
      end
    end)
  end

  defp id_values(value), do: [value]

  defp stable_id_value(nil), do: []
  defp stable_id_value(value) when is_boolean(value), do: []

  defp stable_id_value(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_value()

  defp stable_id_value("nil"), do: []

  defp stable_id_value(value) when is_binary(value),
    do: if(stable_id?(value), do: [value], else: [])

  defp stable_id_value(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_value()

  defp stable_id_value(_value), do: []

  defp candidate_type_or_invalid(%{"type" => type}) when is_binary(type) and type != "",
    do: type

  defp candidate_type_or_invalid(_candidate), do: "invalid_candidate_input"

  defp valid_candidate_kind?(%{"type" => type}) when is_binary(type) and type != "", do: true

  defp valid_candidate_kind?(%{"direction" => direction})
       when direction in ["downlink", "tracking"],
       do: true

  defp valid_candidate_kind?(_candidate), do: false

  defp put_ground_station_alias(%{"ground_station_id" => station_id} = candidate)
       when not is_nil(station_id),
       do: candidate

  defp put_ground_station_alias(%{"station_id" => station_id} = candidate)
       when not is_nil(station_id),
       do: Map.put(candidate, "ground_station_id", station_id)

  defp put_ground_station_alias(candidate) do
    case nested_station_id(candidate) do
      nil -> candidate
      station_id -> Map.put(candidate, "ground_station_id", station_id)
    end
  end

  defp nested_station_id(candidate) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(candidate, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp put_time_alias(candidate, canonical_key, alternate_key) do
    case numeric_or_nil(Map.get(candidate, canonical_key)) ||
           numeric_or_nil(Map.get(candidate, alternate_key)) do
      value when is_number(value) -> Map.put(candidate, canonical_key, value)
      _value -> candidate
    end
  end

  defp put_provider_downlink_shape(candidate) do
    if provider_downlink_candidate?(candidate) do
      candidate
      |> Map.put_new("type", "downlink")
      |> Map.put_new("direction", "downlink")
    else
      candidate
    end
  end

  defp put_direction_contact_shape(candidate) do
    type = Map.get(candidate, "type") || Map.get(candidate, "activity_type")
    direction = Map.get(candidate, "direction")

    cond do
      typed_contact_window?(type, direction, candidate) and direction == "health_check" ->
        Map.put_new(candidate, "type", "health_check")

      typed_contact_window?(type, direction, candidate) ->
        Map.put_new(candidate, "type", "planned_contact")

      true ->
        candidate
    end
  end

  defp typed_contact_window?(type, direction, candidate) do
    type in [nil, "contact", "planned_contact"] and
      direction in ["tracking", "uplink", "command", "health_check"] and
      not is_nil(Map.get(candidate, "ground_station_id")) and
      is_number(Map.get(candidate, "starts_at_s")) and
      is_number(Map.get(candidate, "ends_at_s"))
  end

  defp put_activity_type_alias(%{"type" => type} = candidate) when not is_nil(type),
    do: candidate

  defp put_activity_type_alias(%{"activity_type" => type} = candidate)
       when is_binary(type) and type != "",
       do: Map.put(candidate, "type", type)

  defp put_activity_type_alias(candidate), do: candidate

  defp put_provider_direction_alias(%{"direction" => direction} = candidate) do
    case normalize_provider_direction(direction) do
      nil -> candidate
      direction -> Map.put(candidate, "direction", direction)
    end
  end

  defp put_provider_direction_alias(candidate), do: candidate

  defp normalize_provider_direction(direction) when direction in [nil, ""], do: nil

  defp normalize_provider_direction(direction) do
    direction
    |> normalized_direction_token()
    |> case do
      nil -> nil
      token -> Map.get(@provider_direction_aliases, token, token)
    end
  end

  defp put_station_calendar_directions(candidate) do
    case station_calendar_directions(candidate) do
      [] -> candidate
      directions -> Map.put(candidate, "station_calendar_directions", directions)
    end
  end

  defp station_calendar_directions(candidate) do
    [
      Map.get(candidate, "station_calendar_directions"),
      Map.get(candidate, "station_calendar_direction"),
      get_in(candidate, ["source_station_calendar_entry", "station_calendar_directions"]),
      get_in(candidate, ["source_station_calendar_entry", "directions"]),
      get_in(candidate, ["source_station_calendar_entry", "direction"])
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

  defp provider_downlink_candidate?(candidate) do
    type = Map.get(candidate, "type") || Map.get(candidate, "activity_type")
    direction = Map.get(candidate, "direction")

    type in [nil, "contact", "planned_contact"] and
      direction in [nil, "downlink"] and
      not command_feedback_candidate?(candidate) and
      not is_nil(Map.get(candidate, "ground_station_id")) and
      is_number(Map.get(candidate, "starts_at_s")) and
      is_number(Map.get(candidate, "ends_at_s"))
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
      thermal_margin_c
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

  defp normalize_resource_power_margin(%{"power_margin" => value} = summary)
       when is_number(value),
       do: summary

  defp normalize_resource_power_margin(summary) do
    case Map.get(summary, "battery_state_of_charge") do
      value when is_number(value) -> Map.put(summary, "power_margin", value)
      _value -> summary
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

  defp activity_type_suppressed?(_candidate, values) when values in [nil, []], do: false

  defp activity_type_suppressed?(candidate, values) when is_list(values) do
    candidate
    |> resource_activity_tokens()
    |> Enum.any?(&(&1 in values))
  end

  defp activity_type_suppressed?(_candidate, _values), do: false

  defp resource_activity_tokens(candidate) do
    [
      candidate["type"],
      candidate["direction"],
      resource_direction(candidate)
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

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp command_feedback_candidate?(candidate) do
    Map.has_key?(candidate, "command_success") or Map.has_key?(candidate, "command_result")
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

  defp provider_result_values(values) when is_list(values) do
    values
    |> Enum.flat_map(&provider_result_values/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(%{} = result) do
    @provider_result_map_value_keys
    |> Enum.flat_map(fn key -> provider_result_values(Map.get(result, key)) end)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> []
      normalized -> [normalized]
    end
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(value) when is_atom(value),
    do: provider_result_values(Atom.to_string(value))

  defp provider_result_values(value), do: provider_result_values(to_string(value))

  defp provider_result_artifact_value(value) do
    case provider_result_values(value) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp unit_interval_factor(row, field) do
    case numeric_or_nil(Map.get(row, field)) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
    end
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
