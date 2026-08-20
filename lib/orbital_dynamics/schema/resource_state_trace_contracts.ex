defmodule OrbitalDynamics.Schema.ResourceStateTraceContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      reject_duplicate_ids: 3,
      validate_stable_id_array_map: 3,
      validate_stable_id_list: 3,
      validate_stable_ids: 4
    ]

  alias OrbitalDynamics.ResourceStateTrace

  @state_fields ~w(
    battery_capacity_wh
    battery_energy_remaining_wh
    battery_state_of_charge
    recorder_capacity_mb
    recorder_used_mb
    recorder_remaining_mb
    recorder_fill_fraction
  )
  @effect_fields ~w(
    status
    ignored_reason
    energy_consumed_wh
    energy_generated_wh
    data_stored_mb
    data_removed_mb
    battery_delta_wh
    recorder_delta_mb
  )
  @limit_evidence_fields ~w(
    unconstrained_battery_energy_remaining_wh
    unconstrained_recorder_used_mb
    battery_depletion_wh
    battery_overflow_wh
    recorder_depletion_mb
    recorder_overflow_mb
  )
  @row_fields ~w(
    id
    activity_id
    activity_type
    spacecraft_id
    starts_at_s
    ends_at_s
    effect_at_s
    effect_status
    ignored_reason
    state_status
    declared_effects
    applied_effects
    state_before
    state_after
    limit_evidence
    violation_types
    assumptions
    provenance
  )
  @invalid_fields ~w(
    id
    activity_id
    reason_codes
    review_status
    source_activity
  )

  def validate(issues, path, trace) do
    required_fields =
      OrbitalDynamics.Schema.ResourceStateTraceRegistryContracts.contracts()
      |> Map.fetch!("resource_state_trace.v1")
      |> Map.fetch!("required_fields")

    issues
    |> require_fields(path, trace, required_fields)
    |> validate_stable_ids(path, trace, ["id", "spacecraft_id"])
    |> expect_equal(path, trace, "schema_contract", "resource_state_trace.v1")
    |> expect_equal(path, trace, "model", ResourceStateTrace.model())
    |> expect_one_of(path, trace, "status", ["clear", "limit_exceeded", "review_required"])
    |> validate_exact_model_limits(path, trace)
    |> validate_top_level_types(path, trace)
    |> validate_state(path <> ".initial_state", Map.get(trace, "initial_state"), true)
    |> validate_state(path <> ".final_state", Map.get(trace, "final_state"), true)
    |> validate_trace_rows(path, trace)
    |> validate_invalid_activities(path, trace)
    |> validate_semantics(path, trace)
    |> validate_identity(path, trace)
  end

  defp validate_top_level_types(issues, path, trace) do
    issues
    |> expect_non_negative_integer(path, trace, "input_activity_count")
    |> expect_non_negative_integer(path, trace, "applied_activity_count")
    |> expect_non_negative_integer(path, trace, "ignored_activity_count")
    |> expect_non_negative_integer(path, trace, "invalid_activity_count")
    |> expect_non_negative_integer(path, trace, "violation_count")
    |> expect_type(path, trace, "initial_state", :map)
    |> expect_type(path, trace, "final_state", :map)
    |> expect_type(path, trace, "invalid_activity_ids", :list)
    |> validate_stable_id_list(
      path <> ".invalid_activity_ids",
      Map.get(trace, "invalid_activity_ids")
    )
    |> expect_type(path, trace, "trace_rows", :list)
    |> expect_type(path, trace, "invalid_activities", :list)
    |> expect_type(path, trace, "violation_types", :list)
    |> validate_string_list_items(path, trace, "violation_types")
    |> expect_type(path, trace, "activity_ids_by_violation_type", :map)
    |> validate_stable_id_array_map(
      path <> ".activity_ids_by_violation_type",
      Map.get(trace, "activity_ids_by_violation_type")
    )
    |> expect_type(path, trace, "assumptions", :map)
    |> expect_type(path, trace, "provenance", :map)
    |> expect_type(path, trace, "model_limits", :list)
    |> validate_string_list_items(path, trace, "model_limits")
  end

  defp validate_exact_model_limits(issues, path, trace) do
    if Map.get(trace, "model_limits") == ResourceStateTrace.model_limits() do
      issues
    else
      [
        error(path <> ".model_limits", "must match ResourceStateTrace.capabilities known limits")
        | issues
      ]
    end
  end

  defp validate_state(issues, path, %{} = state, include_time?) do
    fields = if include_time?, do: ["at_s" | @state_fields], else: @state_fields

    issues = require_fields(issues, path, state, fields)

    issues =
      Enum.reduce(fields, issues, fn field, acc ->
        value = Map.get(state, field)

        if is_number(value) do
          acc
        else
          [error("#{path}.#{field}", "must be a number") | acc]
        end
      end)

    issues
    |> validate_positive_number(path, state, "battery_capacity_wh")
    |> validate_positive_number(path, state, "recorder_capacity_mb")
    |> validate_non_negative_number(path, state, "battery_energy_remaining_wh")
    |> validate_non_negative_number(path, state, "recorder_used_mb")
    |> validate_non_negative_number(path, state, "recorder_remaining_mb")
    |> validate_probability(path, state, "battery_state_of_charge")
    |> validate_probability(path, state, "recorder_fill_fraction")
    |> validate_state_arithmetic(path, state)
  end

  defp validate_state(issues, path, _state, _include_time?),
    do: [error(path, "must be an object") | issues]

  defp validate_trace_rows(issues, path, trace) do
    case Map.get(trace, "trace_rows") do
      rows when is_list(rows) ->
        rows
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {row, index}, acc ->
          validate_row(acc, "#{path}.trace_rows[#{index}]", row)
        end)

      _rows ->
        issues
    end
  end

  defp validate_row(issues, path, %{} = row) do
    issues
    |> require_fields(path, row, @row_fields)
    |> validate_stable_ids(path, row, ["id", "activity_id", "spacecraft_id"])
    |> expect_type(path, row, "activity_type", :binary)
    |> validate_number(path, row, "starts_at_s")
    |> validate_number(path, row, "ends_at_s")
    |> validate_number(path, row, "effect_at_s")
    |> expect_one_of(path, row, "effect_status", ResourceStateTrace.effect_statuses())
    |> expect_one_of(path, row, "state_status", ResourceStateTrace.state_statuses())
    |> validate_ignored_reason(path, row)
    |> validate_effects(path <> ".declared_effects", Map.get(row, "declared_effects"))
    |> validate_effects(path <> ".applied_effects", Map.get(row, "applied_effects"))
    |> validate_state(path <> ".state_before", Map.get(row, "state_before"), false)
    |> validate_state(path <> ".state_after", Map.get(row, "state_after"), false)
    |> validate_limit_evidence(path <> ".limit_evidence", Map.get(row, "limit_evidence"))
    |> expect_type(path, row, "violation_types", :list)
    |> validate_string_list_items(path, row, "violation_types")
    |> expect_type(path, row, "assumptions", :map)
    |> expect_type(path, row, "provenance", :map)
    |> validate_optional_link_budget(path, row)
    |> validate_row_semantics(path, row)
  end

  defp validate_row(issues, path, _row), do: [error(path, "must be an object") | issues]

  defp validate_effects(issues, path, %{} = effects) do
    issues = require_fields(issues, path, effects, @effect_fields)

    issues =
      effects
      |> Map.get("status")
      |> then(fn status ->
        if status in ResourceStateTrace.effect_statuses(),
          do: issues,
          else: [error(path <> ".status", "must be applied or ignored") | issues]
      end)

    Enum.reduce(
      ~w(energy_consumed_wh energy_generated_wh data_stored_mb data_removed_mb),
      issues,
      &validate_non_negative_number(&2, path, effects, &1)
    )
    |> validate_number(path, effects, "battery_delta_wh")
    |> validate_number(path, effects, "recorder_delta_mb")
  end

  defp validate_effects(issues, path, _effects),
    do: [error(path, "must be an object") | issues]

  defp validate_limit_evidence(issues, path, %{} = evidence) do
    issues = require_fields(issues, path, evidence, @limit_evidence_fields)

    issues
    |> validate_number(path, evidence, "unconstrained_battery_energy_remaining_wh")
    |> validate_number(path, evidence, "unconstrained_recorder_used_mb")
    |> validate_non_negative_number(path, evidence, "battery_depletion_wh")
    |> validate_non_negative_number(path, evidence, "battery_overflow_wh")
    |> validate_non_negative_number(path, evidence, "recorder_depletion_mb")
    |> validate_non_negative_number(path, evidence, "recorder_overflow_mb")
  end

  defp validate_limit_evidence(issues, path, _evidence),
    do: [error(path, "must be an object") | issues]

  defp validate_invalid_activities(issues, path, trace) do
    case Map.get(trace, "invalid_activities") do
      rows when is_list(rows) ->
        rows
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {row, index}, acc ->
          validate_invalid_activity(acc, "#{path}.invalid_activities[#{index}]", row)
        end)

      _rows ->
        issues
    end
  end

  defp validate_invalid_activity(issues, path, %{} = row) do
    issues
    |> require_fields(path, row, @invalid_fields)
    |> validate_stable_ids(path, row, ["id", "activity_id"])
    |> expect_type(path, row, "reason_codes", :list)
    |> validate_string_list_items(path, row, "reason_codes")
    |> expect_equal(path, row, "review_status", "operator_review_required")
    |> expect_type(path, row, "source_activity", :map)
  end

  defp validate_invalid_activity(issues, path, _row),
    do: [error(path, "must be an object") | issues]

  defp validate_semantics(issues, path, trace) do
    rows = list_value(trace, "trace_rows")
    invalid = list_value(trace, "invalid_activities")
    violation_rows = Enum.filter(rows, &(list_value(&1, "violation_types") != []))

    violation_types =
      rows |> Enum.flat_map(&list_value(&1, "violation_types")) |> Enum.uniq() |> Enum.sort()

    applied_count = Enum.count(rows, &(&1["effect_status"] == "applied"))
    ignored_count = Enum.count(rows, &(&1["effect_status"] == "ignored"))
    expected_status = expected_status(length(invalid), length(violation_rows))

    issues
    |> expect_semantic(
      path <> ".input_activity_count",
      trace["input_activity_count"] == length(rows) + length(invalid),
      "must equal valid plus invalid activity rows"
    )
    |> expect_semantic(
      path <> ".applied_activity_count",
      trace["applied_activity_count"] == applied_count,
      "must equal applied trace row count"
    )
    |> expect_semantic(
      path <> ".ignored_activity_count",
      trace["ignored_activity_count"] == ignored_count,
      "must equal ignored trace row count"
    )
    |> expect_semantic(
      path <> ".invalid_activity_count",
      trace["invalid_activity_count"] == length(invalid),
      "must equal invalid activity row count"
    )
    |> expect_semantic(
      path <> ".invalid_activity_ids",
      trace["invalid_activity_ids"] == Enum.map(invalid, & &1["id"]),
      "must equal ordered invalid activity row IDs"
    )
    |> expect_semantic(
      path <> ".violation_count",
      trace["violation_count"] == length(violation_rows),
      "must equal trace rows with overflow or depletion evidence"
    )
    |> expect_semantic(
      path <> ".violation_types",
      trace["violation_types"] == violation_types,
      "must equal sorted row-derived violation types"
    )
    |> expect_semantic(
      path <> ".status",
      trace["status"] == expected_status,
      "must match invalid-input and limit evidence"
    )
    |> validate_allowed_violation_types(path, trace)
    |> validate_violation_routing(path, trace, rows, violation_types)
    |> validate_row_order(path, rows)
    |> validate_row_identity(path, trace, rows)
    |> validate_state_chain(path, trace, rows)
    |> reject_duplicate_ids(
      path <> ".trace_rows.activity_id",
      Enum.map(rows, & &1["activity_id"])
    )
    |> reject_duplicate_ids(path <> ".trace_rows.id", Enum.map(rows, & &1["id"]))
  end

  defp validate_identity(issues, path, trace) do
    expected_id = trace |> Map.delete("id") |> ResourceStateTrace.artifact_id()

    if trace["id"] == expected_id do
      issues
    else
      [error(path <> ".id", "must be the deterministic content identity for this trace") | issues]
    end
  end

  defp validate_row_semantics(issues, path, row) do
    declared = Map.get(row, "declared_effects", %{})
    applied = Map.get(row, "applied_effects", %{})
    evidence = Map.get(row, "limit_evidence", %{})
    expected_violations = expected_violation_types(evidence)
    expected_state_status = expected_state_status(row["effect_status"], expected_violations)

    issues
    |> expect_semantic(
      path <> ".id",
      row["id"] == "resource_state_event:#{row["spacecraft_id"]}:#{row["activity_id"]}",
      "must derive from spacecraft and activity identity"
    )
    |> expect_semantic(
      path <> ".effect_at_s",
      row["effect_at_s"] == row["ends_at_s"],
      "must equal ends_at_s"
    )
    |> expect_semantic(path <> ".ends_at_s", valid_interval?(row), "must not precede starts_at_s")
    |> expect_semantic(
      path <> ".effect_status",
      row["effect_status"] == declared["status"],
      "must match declared effect status"
    )
    |> expect_semantic(
      path <> ".violation_types",
      row["violation_types"] == expected_violations,
      "must match limit evidence"
    )
    |> expect_semantic(
      path <> ".state_status",
      row["state_status"] == expected_state_status,
      "must match effect and limit evidence"
    )
    |> expect_semantic(
      path <> ".declared_effects.battery_delta_wh",
      numeric_equal?(
        declared["battery_delta_wh"],
        numeric_value(declared, "energy_generated_wh") -
          numeric_value(declared, "energy_consumed_wh")
      ),
      "must equal generated minus consumed energy"
    )
    |> expect_semantic(
      path <> ".declared_effects.recorder_delta_mb",
      numeric_equal?(
        declared["recorder_delta_mb"],
        numeric_value(declared, "data_stored_mb") - numeric_value(declared, "data_removed_mb")
      ),
      "must equal stored minus removed data"
    )
    |> validate_applied_effects(path, row, declared, applied)
    |> validate_transition_math(path, row)
    |> validate_ignored_transition(path, row, applied)
  end

  defp validate_applied_effects(
         issues,
         path,
         %{"effect_status" => "applied", "downlink_link_budget" => budget},
         declared,
         applied
       ) do
    supported_volume_mb = get_in(budget, ["derived", "supported_volume_mb"])

    if is_number(supported_volume_mb) and is_number(declared["data_removed_mb"]) and
         is_number(declared["data_stored_mb"]) do
      expected_applied =
        declared
        |> Map.put("data_removed_mb", min(declared["data_removed_mb"], supported_volume_mb))
        |> then(fn effects ->
          Map.put(
            effects,
            "recorder_delta_mb",
            effects["data_stored_mb"] - effects["data_removed_mb"]
          )
        end)

      expect_semantic(
        issues,
        path <> ".applied_effects.data_removed_mb",
        applied == expected_applied,
        "must not remove more recorder data than the attached link-budget volume"
      )
    else
      issues
    end
  end

  defp validate_applied_effects(
         issues,
         path,
         %{"effect_status" => "applied"},
         declared,
         applied
       ) do
    expect_semantic(
      issues,
      path <> ".applied_effects",
      applied == declared,
      "must equal declared_effects for an applied activity"
    )
  end

  defp validate_applied_effects(issues, _path, _row, _declared, _applied), do: issues

  defp validate_optional_link_budget(issues, path, row) do
    case Map.get(row, "downlink_link_budget") do
      nil ->
        issues

      %{} = budget ->
        OrbitalDynamics.Schema.DownlinkLinkBudgetContracts.validate(
          issues,
          path <> ".downlink_link_budget",
          budget
        )

      _budget ->
        [error(path <> ".downlink_link_budget", "must be an object") | issues]
    end
  end

  defp validate_transition_math(issues, path, row) do
    before = Map.get(row, "state_before", %{})
    after_state = Map.get(row, "state_after", %{})
    applied = Map.get(row, "applied_effects", %{})
    evidence = Map.get(row, "limit_evidence", %{})

    values = [
      before["battery_energy_remaining_wh"],
      before["battery_capacity_wh"],
      before["recorder_used_mb"],
      before["recorder_capacity_mb"],
      applied["battery_delta_wh"],
      applied["recorder_delta_mb"]
    ]

    if Enum.all?(values, &is_number/1) do
      unconstrained_battery =
        before["battery_energy_remaining_wh"] + applied["battery_delta_wh"]

      unconstrained_recorder = before["recorder_used_mb"] + applied["recorder_delta_mb"]
      battery_capacity = before["battery_capacity_wh"]
      recorder_capacity = before["recorder_capacity_mb"]

      issues
      |> expect_semantic(
        path <> ".limit_evidence.unconstrained_battery_energy_remaining_wh",
        numeric_equal?(
          evidence["unconstrained_battery_energy_remaining_wh"],
          unconstrained_battery
        ),
        "must equal state_before plus applied battery delta"
      )
      |> expect_semantic(
        path <> ".limit_evidence.unconstrained_recorder_used_mb",
        numeric_equal?(evidence["unconstrained_recorder_used_mb"], unconstrained_recorder),
        "must equal state_before plus applied recorder delta"
      )
      |> expect_semantic(
        path <> ".limit_evidence.battery_depletion_wh",
        numeric_equal?(evidence["battery_depletion_wh"], max(-unconstrained_battery, 0.0)),
        "must equal unmet battery depletion"
      )
      |> expect_semantic(
        path <> ".limit_evidence.battery_overflow_wh",
        numeric_equal?(
          evidence["battery_overflow_wh"],
          max(unconstrained_battery - battery_capacity, 0.0)
        ),
        "must equal battery capacity overflow"
      )
      |> expect_semantic(
        path <> ".limit_evidence.recorder_depletion_mb",
        numeric_equal?(evidence["recorder_depletion_mb"], max(-unconstrained_recorder, 0.0)),
        "must equal unmet recorder depletion"
      )
      |> expect_semantic(
        path <> ".limit_evidence.recorder_overflow_mb",
        numeric_equal?(
          evidence["recorder_overflow_mb"],
          max(unconstrained_recorder - recorder_capacity, 0.0)
        ),
        "must equal recorder capacity overflow"
      )
      |> expect_semantic(
        path <> ".state_after.battery_energy_remaining_wh",
        numeric_equal?(
          after_state["battery_energy_remaining_wh"],
          clamp(unconstrained_battery, 0.0, battery_capacity)
        ),
        "must equal saturated battery state"
      )
      |> expect_semantic(
        path <> ".state_after.recorder_used_mb",
        numeric_equal?(
          after_state["recorder_used_mb"],
          clamp(unconstrained_recorder, 0.0, recorder_capacity)
        ),
        "must equal saturated recorder state"
      )
    else
      issues
    end
  end

  defp validate_ignored_transition(issues, path, %{"effect_status" => "ignored"} = row, applied) do
    zero? =
      Enum.all?(
        ~w(energy_consumed_wh energy_generated_wh data_stored_mb data_removed_mb battery_delta_wh recorder_delta_mb),
        fn field ->
          numeric_equal?(Map.get(applied, field), 0.0)
        end
      )

    issues
    |> expect_semantic(
      path <> ".ignored_reason",
      is_binary(row["ignored_reason"]) and String.trim(row["ignored_reason"]) != "",
      "is required for ignored effects"
    )
    |> expect_semantic(path <> ".applied_effects", zero?, "must be zero for an ignored activity")
    |> expect_semantic(
      path <> ".state_after",
      state_equal?(row["state_before"], row["state_after"]),
      "must equal state_before for an ignored activity"
    )
  end

  defp validate_ignored_transition(issues, _path, _row, _applied), do: issues

  defp validate_state_chain(issues, path, trace, rows) do
    initial = trace |> Map.get("initial_state", %{}) |> Map.delete("at_s")
    final = trace |> Map.get("final_state", %{}) |> Map.delete("at_s")

    {issues, previous_state} =
      Enum.with_index(rows)
      |> Enum.reduce({issues, initial}, fn {row, index}, {acc, previous} ->
        acc =
          expect_semantic(
            acc,
            "#{path}.trace_rows[#{index}].state_before",
            state_equal?(row["state_before"], previous),
            "must equal the prior transition state"
          )

        {acc, row["state_after"]}
      end)

    expected_final = if rows == [], do: initial, else: previous_state

    expect_semantic(
      issues,
      path <> ".final_state",
      state_equal?(final, expected_final),
      "must equal the final transition state"
    )
  end

  defp validate_row_order(issues, path, rows) do
    sorted = Enum.sort_by(rows, &{&1["effect_at_s"], &1["starts_at_s"], &1["activity_id"]})

    expect_semantic(
      issues,
      path <> ".trace_rows",
      rows == sorted,
      "must use deterministic effect-time ordering"
    )
  end

  defp validate_row_identity(issues, path, trace, rows) do
    Enum.with_index(rows)
    |> Enum.reduce(issues, fn {row, index}, acc ->
      expect_semantic(
        acc,
        "#{path}.trace_rows[#{index}].spacecraft_id",
        row["spacecraft_id"] == trace["spacecraft_id"],
        "must match trace spacecraft_id"
      )
    end)
  end

  defp validate_allowed_violation_types(issues, path, trace) do
    invalid = list_value(trace, "violation_types") -- ResourceStateTrace.violation_types()

    expect_semantic(
      issues,
      path <> ".violation_types",
      invalid == [],
      "contains unsupported violation types"
    )
  end

  defp validate_violation_routing(issues, path, trace, rows, violation_types) do
    expected =
      Map.new(violation_types, fn type ->
        ids =
          rows
          |> Enum.filter(&(type in list_value(&1, "violation_types")))
          |> Enum.map(& &1["activity_id"])
          |> Enum.sort()

        {type, ids}
      end)

    expect_semantic(
      issues,
      path <> ".activity_ids_by_violation_type",
      trace["activity_ids_by_violation_type"] == expected,
      "must equal row-derived violation routing"
    )
  end

  defp validate_state_arithmetic(issues, path, state) do
    battery_capacity = Map.get(state, "battery_capacity_wh")
    battery_energy = Map.get(state, "battery_energy_remaining_wh")
    recorder_capacity = Map.get(state, "recorder_capacity_mb")
    recorder_used = Map.get(state, "recorder_used_mb")

    if Enum.all?(
         [battery_capacity, battery_energy, recorder_capacity, recorder_used],
         &is_number/1
       ) and battery_capacity > 0 and recorder_capacity > 0 do
      issues
      |> expect_semantic(
        path <> ".battery_energy_remaining_wh",
        battery_energy <= battery_capacity,
        "must not exceed battery capacity"
      )
      |> expect_semantic(
        path <> ".recorder_used_mb",
        recorder_used <= recorder_capacity,
        "must not exceed recorder capacity"
      )
      |> expect_semantic(
        path <> ".battery_state_of_charge",
        numeric_equal?(state["battery_state_of_charge"], battery_energy / battery_capacity),
        "must equal energy divided by capacity"
      )
      |> expect_semantic(
        path <> ".recorder_remaining_mb",
        numeric_equal?(state["recorder_remaining_mb"], recorder_capacity - recorder_used),
        "must equal capacity minus used"
      )
      |> expect_semantic(
        path <> ".recorder_fill_fraction",
        numeric_equal?(state["recorder_fill_fraction"], recorder_used / recorder_capacity),
        "must equal used divided by capacity"
      )
    else
      issues
    end
  end

  defp validate_ignored_reason(issues, path, row) do
    case Map.get(row, "ignored_reason") do
      nil -> issues
      value when is_binary(value) -> issues
      _value -> [error(path <> ".ignored_reason", "must be a string or null") | issues]
    end
  end

  defp validate_number(issues, path, map, field) do
    if is_number(Map.get(map, field)),
      do: issues,
      else: [error("#{path}.#{field}", "must be a number") | issues]
  end

  defp validate_non_negative_number(issues, path, map, field) do
    case Map.get(map, field) do
      value when is_number(value) and value >= 0.0 -> issues
      value when is_number(value) -> [error("#{path}.#{field}", "must be non-negative") | issues]
      _value -> [error("#{path}.#{field}", "must be a number") | issues]
    end
  end

  defp validate_positive_number(issues, path, map, field) do
    case Map.get(map, field) do
      value when is_number(value) and value > 0.0 -> issues
      _value -> [error("#{path}.#{field}", "must be greater than zero") | issues]
    end
  end

  defp validate_probability(issues, path, map, field) do
    case Map.get(map, field) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> issues
      _value -> [error("#{path}.#{field}", "must be between 0.0 and 1.0") | issues]
    end
  end

  defp expected_violation_types(evidence) when is_map(evidence) do
    [
      {"battery_depletion", evidence["battery_depletion_wh"]},
      {"battery_overflow", evidence["battery_overflow_wh"]},
      {"recorder_depletion", evidence["recorder_depletion_mb"]},
      {"recorder_overflow", evidence["recorder_overflow_mb"]}
    ]
    |> Enum.filter(fn {_type, value} -> is_number(value) and value > 0.0 end)
    |> Enum.map(&elem(&1, 0))
  end

  defp expected_violation_types(_evidence), do: []

  defp expected_state_status("ignored", _types), do: "ignored"
  defp expected_state_status(_status, []), do: "nominal"

  defp expected_state_status(_status, types) do
    overflow? = Enum.any?(types, &String.ends_with?(&1, "overflow"))
    depletion? = Enum.any?(types, &String.ends_with?(&1, "depletion"))

    case {overflow?, depletion?} do
      {true, true} -> "overflow_and_depletion"
      {true, false} -> "overflow"
      {false, true} -> "depletion"
    end
  end

  defp expected_status(invalid_count, _violation_count) when invalid_count > 0,
    do: "review_required"

  defp expected_status(0, violation_count) when violation_count > 0, do: "limit_exceeded"
  defp expected_status(0, 0), do: "clear"

  defp valid_interval?(row),
    do:
      is_number(row["starts_at_s"]) and is_number(row["ends_at_s"]) and
        row["ends_at_s"] >= row["starts_at_s"]

  defp state_equal?(left, right) when is_map(left) and is_map(right) do
    Enum.all?(@state_fields, fn field -> numeric_equal?(left[field], right[field]) end)
  end

  defp state_equal?(_left, _right), do: false

  defp numeric_equal?(left, right) when is_number(left) and is_number(right),
    do: abs(left - right) <= 1.0e-9

  defp numeric_equal?(_left, _right), do: false

  defp numeric_value(map, field) do
    case Map.get(map, field) do
      value when is_number(value) -> value
      _value -> 0.0
    end
  end

  defp clamp(value, minimum, maximum), do: value |> max(minimum) |> min(maximum)

  defp list_value(map, field) when is_map(map) do
    case Map.get(map, field) do
      values when is_list(values) -> values
      _value -> []
    end
  end

  defp list_value(_map, _field), do: []

  defp expect_semantic(issues, _path, true, _message), do: issues
  defp expect_semantic(issues, path, false, message), do: [error(path, message) | issues]
end
