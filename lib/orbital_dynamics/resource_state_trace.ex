defmodule OrbitalDynamics.ResourceStateTrace do
  @moduledoc """
  Deterministic Tier 1 battery and data-recorder state traces.

  A trace starts from one `resource_summary.v1` battery/storage state and applies
  explicit per-activity `resource_effects` in activity-end order. Effects are
  lumped, not continuously integrated. Battery and recorder state are saturated
  at their declared bounds while the discarded overflow or unmet depletion is
  retained as evidence on the transition that caused it.

  This module does not mutate a schedule, infer undeclared effects, model
  thermal or fuel behavior, or claim mission calibration or digital-twin
  fidelity.
  """

  alias OrbitalDynamics.ResourceSummary
  alias OrbitalDynamics.Communications.DownlinkLinkBudget

  @schema_contract "resource_state_trace.v1"
  @model "tier_1_declared_activity_resource_state_trace"
  @effect_fields ~w(
    energy_consumed_wh
    energy_generated_wh
    data_stored_mb
    data_removed_mb
  )
  @effect_statuses ~w(applied ignored)
  @state_statuses ~w(nominal overflow depletion overflow_and_depletion ignored)
  @violation_types ~w(
    battery_depletion
    battery_overflow
    recorder_depletion
    recorder_overflow
  )
  @known_limits [
    :activity_end_lumped_effects_only,
    :declared_activity_effects_only,
    :no_battery_degradation_or_charge_dynamics,
    :no_continuous_resource_dynamics,
    :no_fuel_model,
    :no_mission_calibration,
    :no_overlap_concurrency_model,
    :no_schedule_mutation,
    :no_thermal_model,
    :not_digital_twin_state
  ]
  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  @doc """
  Declares the single Tier 1 trace approximation and its fidelity boundary.
  """
  def capabilities do
    %{
      artifact_contract: @schema_contract,
      model: :tier_1_declared_activity_resource_state_trace,
      fidelity_tier: :tier_1,
      validation_level: :artifact_contract,
      public_facades: [:resource_state_trace],
      input_resource_contract: "resource_summary.v1",
      input_activity_effect_path: ["resource_effects"],
      declared_effect_fields: @effect_fields,
      effect_statuses: @effect_statuses,
      state_statuses: @state_statuses,
      violation_types: @violation_types,
      ordering: [:effect_at_s, :starts_at_s, :activity_id],
      subsystem_model_capability_ids: [
        OrbitalDynamics.SubsystemModel.battery_energy_storage()["id"],
        OrbitalDynamics.SubsystemModel.data_storage_buffer()["id"]
      ],
      known_limits: @known_limits
    }
  end

  @doc false
  def model, do: @model

  @doc false
  def model_limits do
    @known_limits
    |> Enum.map(&Atom.to_string/1)
    |> Enum.sort()
  end

  @doc false
  def effect_fields, do: @effect_fields

  @doc false
  def effect_statuses, do: @effect_statuses

  @doc false
  def state_statuses, do: @state_statuses

  @doc false
  def violation_types, do: @violation_types

  @doc """
  Builds an immutable `resource_state_trace.v1` from selected activities and one
  initial resource summary.

  Every valid activity must declare a `resource_effects` map. The four
  non-negative effect fields are `energy_consumed_wh`, `energy_generated_wh`,
  `data_stored_mb`, and `data_removed_mb`; omitted fields mean zero. An activity
  can explicitly set `resource_effects.status` to `ignored` and provide an
  `ignored_reason`, in which case its declared effects remain in the audit row
  but do not change state.

  Options:

    * `:as_of_s` - initial-state time, default `0.0`
    * `:source` - declared source label
    * `:assumptions` - caller assumptions preserved under the model assumptions
    * `:provenance` - caller provenance preserved under trace provenance
  """
  def trace(selected_activities, initial_resource_summary, opts \\ [])

  def trace(selected_activities, initial_resource_summary, opts)
      when is_list(selected_activities) and is_list(opts) do
    opts = normalize_opts!(opts)
    initial = normalize_initial_state!(initial_resource_summary, opts)

    {activities, invalid_activities} =
      selected_activities
      |> Enum.map(&normalize_activity(&1, initial))
      |> Enum.split_with(&match?({:ok, _activity}, &1))
      |> then(fn {valid, invalid} ->
        {
          Enum.map(valid, fn {:ok, activity} -> activity end),
          Enum.map(invalid, fn {:error, activity} -> activity end)
        }
      end)
      |> reject_duplicate_activity_ids()

    activities = Enum.sort_by(activities, &activity_sort_key/1)
    invalid_activities = finalize_invalid_activities(invalid_activities)

    {trace_rows, final_state} = build_rows(activities, initial.state)
    final_at_s = final_at_s(trace_rows, initial.as_of_s)

    violation_rows = Enum.filter(trace_rows, &(Map.get(&1, "violation_types", []) != []))

    violation_types =
      violation_rows
      |> Enum.flat_map(& &1["violation_types"])
      |> Enum.uniq()
      |> Enum.sort()

    applied_activity_count = Enum.count(trace_rows, &(&1["effect_status"] == "applied"))
    ignored_activity_count = Enum.count(trace_rows, &(&1["effect_status"] == "ignored"))

    core = %{
      "schema_contract" => @schema_contract,
      "model" => @model,
      "spacecraft_id" => initial.spacecraft_id,
      "status" => trace_status(length(invalid_activities), length(violation_rows)),
      "initial_state" => Map.put(initial.state, "at_s", initial.as_of_s),
      "final_state" => Map.put(final_state, "at_s", final_at_s),
      "input_activity_count" => length(selected_activities),
      "applied_activity_count" => applied_activity_count,
      "ignored_activity_count" => ignored_activity_count,
      "invalid_activity_count" => length(invalid_activities),
      "invalid_activity_ids" => Enum.map(invalid_activities, & &1["id"]),
      "trace_rows" => trace_rows,
      "invalid_activities" => invalid_activities,
      "violation_count" => length(violation_rows),
      "violation_types" => violation_types,
      "activity_ids_by_violation_type" =>
        activity_ids_by_violation_type(trace_rows, violation_types),
      "assumptions" => assumptions(initial, opts),
      "provenance" => provenance(initial, opts),
      "model_limits" => model_limits()
    }

    Map.put(core, "id", artifact_id(core))
  end

  def trace(selected_activities, _initial_resource_summary, _opts)
      when not is_list(selected_activities),
      do: raise(ArgumentError, "selected activities must be a list")

  def trace(_selected_activities, _initial_resource_summary, _opts),
    do: raise(ArgumentError, "resource state trace options must be a keyword list")

  @doc false
  def artifact_id(core) when is_map(core) do
    "resource_state_trace:" <> digest(json_safe(core))
  end

  defp normalize_opts!(opts) do
    if Keyword.keyword?(opts) do
      %{
        as_of_s: numeric_option!(opts, :as_of_s, 0.0),
        source:
          opts |> Keyword.get(:source, "resource_summary_and_selected_activities") |> text!(),
        assumptions: opts |> Keyword.get(:assumptions, %{}) |> map_option!(:assumptions),
        provenance: opts |> Keyword.get(:provenance, %{}) |> map_option!(:provenance)
      }
    else
      raise ArgumentError, "resource state trace options must be a keyword list"
    end
  end

  defp normalize_initial_state!(%ResourceSummary{} = summary, opts),
    do: summary |> ResourceSummary.to_map() |> normalize_initial_state!(opts)

  defp normalize_initial_state!(%{} = source, opts) do
    summary = source |> json_safe() |> ResourceSummary.from_map!() |> ResourceSummary.to_map()
    battery_capacity_wh = positive_number!(summary["battery_capacity_wh"], "battery_capacity_wh")

    battery_energy_used_wh =
      initial_battery_energy_used!(
        summary["battery_energy_used_wh"],
        summary["battery_state_of_charge"],
        battery_capacity_wh
      )

    recorder_capacity_mb = positive_number!(summary["storage_capacity_mb"], "storage_capacity_mb")
    recorder_used_mb = required_number!(summary["storage_used_mb"], "storage_used_mb")

    require_within_capacity!(
      battery_energy_used_wh,
      battery_capacity_wh,
      "battery_energy_used_wh"
    )

    require_within_capacity!(recorder_used_mb, recorder_capacity_mb, "storage_used_mb")

    battery_energy_remaining_wh = battery_capacity_wh - battery_energy_used_wh

    %{
      spacecraft_id: summary["spacecraft_id"],
      as_of_s: opts.as_of_s,
      state:
        state(
          battery_capacity_wh,
          battery_energy_remaining_wh,
          recorder_capacity_mb,
          recorder_used_mb
        ),
      source_quality: summary["source_quality"],
      trust_boundary: summary["trust_boundary"],
      source_assumptions: json_safe(summary["assumptions"] || %{}),
      source_provenance: json_safe(summary["provenance"] || %{})
    }
  rescue
    error in ArgumentError ->
      raise ArgumentError, "invalid initial resource summary: #{Exception.message(error)}"
  end

  defp normalize_initial_state!(_source, _opts),
    do: raise(ArgumentError, "initial resource summary must be a map or ResourceSummary struct")

  defp initial_battery_energy_used!(value, _state_of_charge, _capacity)
       when is_number(value),
       do: required_number!(value, "battery_energy_used_wh")

  defp initial_battery_energy_used!(nil, state_of_charge, capacity)
       when is_number(state_of_charge),
       do: capacity * (1.0 - state_of_charge)

  defp initial_battery_energy_used!(_value, _state_of_charge, _capacity) do
    raise ArgumentError,
          "battery_energy_used_wh or battery_state_of_charge is required"
  end

  defp normalize_activity(activity, initial) when is_map(activity) do
    source_activity = json_safe(activity)
    activity_id = normalize_stable_id(source_activity["id"])

    activity_type =
      normalize_non_blank_text(source_activity["type"] || source_activity["activity_type"])

    spacecraft_id = normalize_optional_stable_id(source_activity["spacecraft_id"])
    starts_at_s = numeric_or_nil(source_activity["starts_at_s"] || source_activity["start_s"])

    ends_at_s =
      numeric_or_nil(source_activity["ends_at_s"] || source_activity["end_s"]) || starts_at_s

    effects = source_activity["resource_effects"]
    effect_metadata = if is_map(effects), do: effects, else: %{}
    {declared_effects, effect_reasons} = normalize_effects(effects)
    activity_provenance = source_activity["provenance"] || %{}
    downlink_link_budget = DownlinkLinkBudget.evidence_for_contact(source_activity)

    reasons =
      []
      |> add_reason(is_nil(activity_id), "missing_or_invalid_activity_id")
      |> add_reason(is_nil(activity_type), "missing_activity_type")
      |> add_reason(is_nil(starts_at_s), "missing_or_malformed_starts_at_s")
      |> add_reason(is_nil(ends_at_s), "missing_or_malformed_ends_at_s")
      |> add_reason(
        is_number(starts_at_s) and is_number(ends_at_s) and ends_at_s < starts_at_s,
        "ends_before_start"
      )
      |> add_reason(
        is_number(ends_at_s) and ends_at_s < initial.as_of_s,
        "activity_effect_precedes_initial_state"
      )
      |> add_reason(
        not is_nil(spacecraft_id) and spacecraft_id != initial.spacecraft_id,
        "spacecraft_id_mismatch"
      )
      |> add_reason(
        Map.has_key?(source_activity, "spacecraft_id") and is_nil(spacecraft_id),
        "invalid_spacecraft_id"
      )
      |> add_reason(not is_map(activity_provenance), "malformed_activity_provenance")
      |> Kernel.++(effect_reasons)
      |> Enum.uniq()
      |> Enum.sort()

    if reasons == [] do
      {:ok,
       %{
         "id" => activity_id,
         "type" => activity_type,
         "spacecraft_id" => initial.spacecraft_id,
         "starts_at_s" => starts_at_s,
         "ends_at_s" => ends_at_s,
         "effect_at_s" => ends_at_s,
         "declared_effects" => declared_effects,
         "assumptions" => json_safe(effect_metadata["assumptions"] || %{}),
         "provenance" =>
           %{
             "effect_source" => "activity.resource_effects",
             "source_activity_provenance" => json_safe(activity_provenance),
             "source_effect_provenance" => json_safe(effect_metadata["provenance"] || %{})
           }
           |> maybe_put_link_budget_id(downlink_link_budget),
         "downlink_link_budget" => downlink_link_budget,
         "source_activity" => source_activity
       }}
    else
      {:error, invalid_activity(source_activity, activity_id, reasons)}
    end
  end

  defp normalize_activity(activity, _initial) do
    source_activity = %{
      "input_type" => input_type(activity),
      "value" => json_safe(activity)
    }

    {:error, invalid_activity(source_activity, nil, ["invalid_activity_shape"])}
  end

  defp normalize_effects(%{} = effects) do
    effects = json_safe(effects)

    {values, reasons} =
      Enum.reduce(@effect_fields, {%{}, []}, fn field, {values, reasons} ->
        case non_negative_effect_value(effects, field) do
          {:ok, value} -> {Map.put(values, field, value), reasons}
          {:error, reason} -> {Map.put(values, field, 0.0), [reason | reasons]}
        end
      end)

    status = effects |> Map.get("status", "applied") |> normalize_non_blank_text()

    ignored_reason =
      case status do
        "applied" -> "not_applicable"
        _status -> normalize_non_blank_text(effects["ignored_reason"] || effects["reason"])
      end

    reasons =
      reasons
      |> add_reason(status not in @effect_statuses, "invalid_resource_effect_status")
      |> add_reason(status == "ignored" and is_nil(ignored_reason), "missing_ignored_reason")
      |> add_reason(
        Map.has_key?(effects, "assumptions") and not is_map(effects["assumptions"]),
        "malformed_resource_effect_assumptions"
      )
      |> add_reason(
        Map.has_key?(effects, "provenance") and not is_map(effects["provenance"]),
        "malformed_resource_effect_provenance"
      )

    declared =
      values
      |> Map.put("status", status || "invalid")
      |> Map.put("ignored_reason", ignored_reason)
      |> Map.put(
        "battery_delta_wh",
        values["energy_generated_wh"] - values["energy_consumed_wh"]
      )
      |> Map.put(
        "recorder_delta_mb",
        values["data_stored_mb"] - values["data_removed_mb"]
      )

    {declared, Enum.reverse(reasons)}
  end

  defp normalize_effects(_effects), do: {%{}, ["missing_or_malformed_resource_effects"]}

  defp non_negative_effect_value(effects, field) do
    case Map.fetch(effects, field) do
      :error ->
        {:ok, 0.0}

      {:ok, value} ->
        case numeric_or_nil(value) do
          value when is_number(value) and value >= 0.0 -> {:ok, value}
          value when is_number(value) -> {:error, "negative_#{field}"}
          _value -> {:error, "malformed_#{field}"}
        end
    end
  end

  defp reject_duplicate_activity_ids({activities, invalid_activities}) do
    duplicate_ids =
      activities
      |> Enum.map(& &1["id"])
      |> Enum.frequencies()
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> MapSet.new(fn {id, _count} -> id end)

    {duplicates, activities} =
      Enum.split_with(activities, &MapSet.member?(duplicate_ids, &1["id"]))

    duplicate_invalid =
      Enum.map(duplicates, fn activity ->
        invalid_activity(activity["source_activity"], activity["id"], ["duplicate_activity_id"])
      end)

    {activities, invalid_activities ++ duplicate_invalid}
  end

  defp invalid_activity(source_activity, activity_id, reason_codes) do
    digest = digest({source_activity, Enum.sort(reason_codes)})

    %{
      "activity_id" => activity_id || "invalid_activity:#{String.slice(digest, 0, 24)}",
      "reason_codes" => Enum.sort(reason_codes),
      "review_status" => "operator_review_required",
      "source_activity" => source_activity,
      "base_id" => "resource_state_invalid_activity:#{digest}"
    }
  end

  defp finalize_invalid_activities(invalid_activities) do
    invalid_activities
    |> Enum.sort_by(fn row ->
      {row["base_id"], row["activity_id"], row["reason_codes"]}
    end)
    |> Enum.chunk_by(& &1["base_id"])
    |> Enum.flat_map(fn
      [row] ->
        [row |> Map.put("id", row["base_id"]) |> Map.delete("base_id")]

      rows ->
        rows
        |> Enum.with_index(1)
        |> Enum.map(fn {row, index} ->
          row
          |> Map.put("id", "#{row["base_id"]}:#{index}")
          |> Map.delete("base_id")
        end)
    end)
  end

  defp build_rows(activities, initial_state) do
    Enum.map_reduce(activities, initial_state, fn activity, state_before ->
      declared = activity["declared_effects"]
      effect_status = declared["status"]

      status_applied =
        if effect_status == "applied",
          do: declared,
          else: zero_effects(declared["ignored_reason"])

      {applied, link_budget_limit_evidence} =
        apply_link_budget_limit(declared, status_applied, activity["downlink_link_budget"])

      unconstrained_battery_energy_wh =
        state_before["battery_energy_remaining_wh"] + applied["battery_delta_wh"]

      unconstrained_recorder_used_mb =
        state_before["recorder_used_mb"] + applied["recorder_delta_mb"]

      battery_capacity_wh = state_before["battery_capacity_wh"]
      recorder_capacity_mb = state_before["recorder_capacity_mb"]

      limit_evidence =
        %{
          "unconstrained_battery_energy_remaining_wh" => unconstrained_battery_energy_wh,
          "unconstrained_recorder_used_mb" => unconstrained_recorder_used_mb,
          "battery_depletion_wh" => max(-unconstrained_battery_energy_wh, 0.0),
          "battery_overflow_wh" =>
            max(unconstrained_battery_energy_wh - battery_capacity_wh, 0.0),
          "recorder_depletion_mb" => max(-unconstrained_recorder_used_mb, 0.0),
          "recorder_overflow_mb" =>
            max(unconstrained_recorder_used_mb - recorder_capacity_mb, 0.0)
        }
        |> Map.merge(link_budget_limit_evidence)

      violation_types = violation_types(limit_evidence)

      state_after =
        state(
          battery_capacity_wh,
          clamp(unconstrained_battery_energy_wh, 0.0, battery_capacity_wh),
          recorder_capacity_mb,
          clamp(unconstrained_recorder_used_mb, 0.0, recorder_capacity_mb)
        )

      row =
        %{
          "id" => "resource_state_event:#{activity["spacecraft_id"]}:#{activity["id"]}",
          "activity_id" => activity["id"],
          "activity_type" => activity["type"],
          "spacecraft_id" => activity["spacecraft_id"],
          "starts_at_s" => activity["starts_at_s"],
          "ends_at_s" => activity["ends_at_s"],
          "effect_at_s" => activity["effect_at_s"],
          "effect_status" => effect_status,
          "ignored_reason" => declared["ignored_reason"],
          "state_status" => state_status(effect_status, violation_types),
          "declared_effects" => declared,
          "applied_effects" => applied,
          "state_before" => state_before,
          "state_after" => state_after,
          "limit_evidence" => limit_evidence,
          "violation_types" => violation_types,
          "assumptions" => activity["assumptions"],
          "provenance" => activity["provenance"]
        }
        |> maybe_put("downlink_link_budget", activity["downlink_link_budget"])

      {row, state_after}
    end)
  end

  defp zero_effects(ignored_reason) do
    %{
      "status" => "ignored",
      "ignored_reason" => ignored_reason,
      "energy_consumed_wh" => 0.0,
      "energy_generated_wh" => 0.0,
      "data_stored_mb" => 0.0,
      "data_removed_mb" => 0.0,
      "battery_delta_wh" => 0.0,
      "recorder_delta_mb" => 0.0
    }
  end

  defp apply_link_budget_limit(_declared, applied, nil), do: {applied, %{}}

  defp apply_link_budget_limit(declared, applied, %{} = budget) do
    supported_volume_mb = get_in(budget, ["derived", "supported_volume_mb"])
    requested_data_removed_mb = declared["data_removed_mb"]
    status_eligible_data_removed_mb = applied["data_removed_mb"]
    limited_data_removed_mb = min(status_eligible_data_removed_mb, supported_volume_mb)

    applied =
      applied
      |> Map.put("data_removed_mb", limited_data_removed_mb)
      |> Map.put("recorder_delta_mb", applied["data_stored_mb"] - limited_data_removed_mb)

    evidence = %{
      "downlink_link_budget_id" => budget["id"],
      "requested_data_removed_mb" => requested_data_removed_mb,
      "status_eligible_data_removed_mb" => status_eligible_data_removed_mb,
      "link_budget_supported_volume_mb" => supported_volume_mb,
      "link_budget_applied_data_removed_mb" => limited_data_removed_mb,
      "link_budget_limited_data_removed_mb" =>
        max(status_eligible_data_removed_mb - limited_data_removed_mb, 0.0),
      "unused_link_budget_volume_mb" => max(supported_volume_mb - limited_data_removed_mb, 0.0)
    }

    {applied, evidence}
  end

  defp state(
         battery_capacity_wh,
         battery_energy_remaining_wh,
         recorder_capacity_mb,
         recorder_used_mb
       ) do
    %{
      "battery_capacity_wh" => battery_capacity_wh,
      "battery_energy_remaining_wh" => battery_energy_remaining_wh,
      "battery_state_of_charge" => battery_energy_remaining_wh / battery_capacity_wh,
      "recorder_capacity_mb" => recorder_capacity_mb,
      "recorder_used_mb" => recorder_used_mb,
      "recorder_remaining_mb" => recorder_capacity_mb - recorder_used_mb,
      "recorder_fill_fraction" => recorder_used_mb / recorder_capacity_mb
    }
  end

  defp violation_types(evidence) do
    [
      {"battery_depletion", evidence["battery_depletion_wh"]},
      {"battery_overflow", evidence["battery_overflow_wh"]},
      {"recorder_depletion", evidence["recorder_depletion_mb"]},
      {"recorder_overflow", evidence["recorder_overflow_mb"]}
    ]
    |> Enum.filter(fn {_type, value} -> value > 0.0 end)
    |> Enum.map(&elem(&1, 0))
  end

  defp state_status("ignored", _violation_types), do: "ignored"
  defp state_status(_status, []), do: "nominal"

  defp state_status(_status, violation_types) do
    overflow? = Enum.any?(violation_types, &String.ends_with?(&1, "overflow"))
    depletion? = Enum.any?(violation_types, &String.ends_with?(&1, "depletion"))

    case {overflow?, depletion?} do
      {true, true} -> "overflow_and_depletion"
      {true, false} -> "overflow"
      {false, true} -> "depletion"
    end
  end

  defp activity_ids_by_violation_type(rows, violation_types) do
    Map.new(violation_types, fn type ->
      activity_ids =
        rows
        |> Enum.filter(&(type in &1["violation_types"]))
        |> Enum.map(& &1["activity_id"])
        |> Enum.sort()

      {type, activity_ids}
    end)
  end

  defp assumptions(initial, opts) do
    %{
      "model_tier" => "tier_1",
      "ordering" => "effect_at_s_then_starts_at_s_then_activity_id",
      "effect_timing" =>
        "full_declared_effect_applied_atomically_at_ends_at_s_or_starts_at_s_when_end_is_omitted",
      "battery_balance" =>
        "before_plus_declared_generation_minus_declared_consumption_saturated_to_zero_and_capacity_with_residual_evidence",
      "recorder_balance" =>
        "before_plus_declared_data_stored_minus_declared_data_removed_saturated_to_zero_and_capacity_with_residual_evidence",
      "ignored_activity" =>
        "explicitly_ignored_effects_are_audited_but_do_not_change_resource_state",
      "initial_state_source" => "resource_summary.v1_battery_and_storage_fields",
      "source_resource_summary_assumptions" => initial.source_assumptions,
      "caller" => opts.assumptions
    }
  end

  defp provenance(initial, opts) do
    %{
      "source" => opts.source,
      "source_resource_summary_contract" => "resource_summary.v1",
      "source_spacecraft_id" => initial.spacecraft_id,
      "source_quality" => initial.source_quality,
      "trust_boundary" => initial.trust_boundary,
      "source_resource_summary_provenance" => initial.source_provenance,
      "caller" => opts.provenance,
      "trace_builder" => "OrbitalDynamics.ResourceStateTrace.trace/3"
    }
    |> compact_map()
  end

  defp trace_status(invalid_count, _violation_count) when invalid_count > 0,
    do: "review_required"

  defp trace_status(0, violation_count) when violation_count > 0,
    do: "limit_exceeded"

  defp trace_status(0, 0), do: "clear"

  defp final_at_s([], as_of_s), do: as_of_s
  defp final_at_s(rows, _as_of_s), do: rows |> List.last() |> Map.fetch!("effect_at_s")

  defp activity_sort_key(activity),
    do: {activity["effect_at_s"], activity["starts_at_s"], activity["id"]}

  defp add_reason(reasons, true, reason), do: [reason | reasons]
  defp add_reason(reasons, false, _reason), do: reasons

  defp normalize_stable_id(value) when is_integer(value),
    do: value |> Integer.to_string() |> normalize_stable_id()

  defp normalize_stable_id(value) when is_binary(value) do
    value = String.trim(value)
    if Regex.match?(@stable_id_pattern, value), do: value
  end

  defp normalize_stable_id(_value), do: nil

  defp normalize_optional_stable_id(nil), do: nil
  defp normalize_optional_stable_id(value), do: normalize_stable_id(value)

  defp normalize_non_blank_text(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      value -> value
    end
  end

  defp normalize_non_blank_text(_value), do: nil

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp numeric_option!(opts, key, default) do
    case opts |> Keyword.get(key, default) |> numeric_or_nil() do
      value when is_number(value) -> value
      _value -> raise ArgumentError, "#{key} must be numeric"
    end
  end

  defp required_number!(value, field) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 -> value
      value when is_number(value) -> raise ArgumentError, "#{field} must be non-negative"
      _value -> raise ArgumentError, "#{field} is required and must be numeric"
    end
  end

  defp positive_number!(value, field) do
    case required_number!(value, field) do
      value when value > 0.0 -> value
      _value -> raise ArgumentError, "#{field} must be greater than zero"
    end
  end

  defp require_within_capacity!(value, capacity, field) do
    if value <= capacity do
      value
    else
      raise ArgumentError, "#{field} must not exceed its declared capacity"
    end
  end

  defp text!(value) when is_atom(value), do: value |> Atom.to_string() |> text!()

  defp text!(value) when is_binary(value) do
    case String.trim(value) do
      "" -> raise ArgumentError, "source must be a non-empty string"
      value -> value
    end
  end

  defp text!(_value), do: raise(ArgumentError, "source must be a non-empty string")

  defp map_option!(value, _field) when is_map(value), do: json_safe(value)
  defp map_option!(_value, field), do: raise(ArgumentError, "#{field} must be a map")

  defp clamp(value, minimum, maximum), do: value |> max(minimum) |> min(maximum)

  defp digest(value) do
    value
    |> :erlang.term_to_binary([:deterministic])
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_link_budget_id(provenance, nil), do: provenance

  defp maybe_put_link_budget_id(provenance, budget),
    do: Map.put(provenance, "downlink_link_budget_id", budget["id"])

  defp json_safe(nil), do: :null
  defp json_safe(:null), do: :null
  defp json_safe(value) when is_boolean(value) or is_binary(value), do: value
  defp json_safe(value) when is_integer(value) or is_float(value), do: value
  defp json_safe(value) when is_atom(value), do: Atom.to_string(value)

  defp json_safe(value) when is_list(value), do: Enum.map(value, &json_safe/1)

  defp json_safe(value) when is_tuple(value) do
    %{"input_type" => "tuple", "value" => value |> Tuple.to_list() |> json_safe()}
  end

  defp json_safe(%{} = map) do
    map
    |> Enum.sort_by(fn {key, _value} -> {to_string(key), key_precedence(key)} end)
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, to_string(key), json_safe(value))
    end)
  end

  defp json_safe(value), do: %{"input_type" => input_type(value)}

  defp key_precedence(key) when is_atom(key), do: 0
  defp key_precedence(_key), do: 1

  defp input_type(value) when is_boolean(value), do: "boolean"
  defp input_type(value) when is_atom(value), do: "atom"
  defp input_type(value) when is_binary(value), do: "string"
  defp input_type(value) when is_integer(value), do: "integer"
  defp input_type(value) when is_float(value), do: "float"
  defp input_type(value) when is_list(value), do: "list"
  defp input_type(value) when is_tuple(value), do: "tuple"
  defp input_type(value) when is_pid(value), do: "pid"
  defp input_type(value) when is_reference(value), do: "reference"
  defp input_type(value) when is_function(value), do: "function"
  defp input_type(_value), do: "unsupported"
end
