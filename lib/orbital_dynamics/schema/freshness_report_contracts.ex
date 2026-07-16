defmodule OrbitalDynamics.Schema.FreshnessReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 5,
      expect_field_equals: 6,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_list: 4,
      expect_optional_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  @freshness_statuses ["current", "stale", "unknown"]

  def validate_optional(issues, _path, nil), do: issues

  def validate_optional(issues, path, %{} = report) do
    issues
    |> require_fields(path, report, [
      "schema_contract",
      "model",
      "generated_at",
      "accepted_at",
      "current_epoch_s",
      "horizon_starts_at_s",
      "accepted_snapshot_age_s",
      "horizon_start_offset_s",
      "max_snapshot_age_s",
      "max_horizon_start_offset_s",
      "status",
      "stale_reasons"
    ])
    |> expect_equal(path, report, "schema_contract", "freshness_report.v1")
    |> expect_equal(
      path,
      report,
      "model",
      "accepted_snapshot_horizon_and_quality_freshness"
    )
    |> expect_type(path, report, "generated_at", :binary)
    |> expect_optional_number(path, report, "current_epoch_s")
    |> expect_optional_number(path, report, "horizon_starts_at_s")
    |> expect_optional_number(path, report, "accepted_snapshot_age_s")
    |> expect_optional_number(path, report, "horizon_start_offset_s")
    |> expect_number(path, report, "max_snapshot_age_s")
    |> expect_number(path, report, "max_horizon_start_offset_s")
    |> expect_optional_type(path, report, "accepted_state_quality_level", :binary)
    |> expect_optional_type(path, report, "state_quality_status", :binary)
    |> expect_optional_list(path, report, "allowed_state_quality_levels")
    |> expect_one_of(path, report, "status", @freshness_statuses)
    |> expect_type(path, report, "stale_reasons", :list)
    |> expect_optional_type(path, report, "unknown_reasons", :list)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_counts(path, report)
  end

  def validate_optional(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  defp validate_counts(issues, path, report) do
    stale_reasons = stale_reasons(report)
    unknown_reasons = unknown_reasons(report)

    issues
    |> expect_field_equals(
      path,
      report,
      "stale_reasons",
      stale_reasons,
      "must equal freshness-policy-derived stale_reasons"
    )
    |> expect_field_equals(
      path,
      report,
      "unknown_reasons",
      unknown_reasons,
      "must equal freshness-policy-derived unknown_reasons"
    )
    |> expect_field_equals(
      path,
      report,
      "status",
      status(stale_reasons, unknown_reasons)
    )
    |> expect_field_equals(
      path,
      report,
      "state_quality_status",
      state_quality_status(report)
    )
    |> expect_field_equals(
      path,
      report,
      "model_limits",
      OrbitalDynamics.CandidateRefresh.model_limits(),
      "must match candidate refresh model limits"
    )
  end

  defp stale_reasons(report) do
    []
    |> maybe_append(snapshot_stale?(report), "accepted_snapshot_older_than_policy")
    |> maybe_append(horizon_stale?(report), "remaining_horizon_does_not_start_at_current_epoch")
    |> maybe_append(
      state_quality_status(report) == "not_accepted",
      "accepted_state_quality_below_policy"
    )
  end

  defp unknown_reasons(report) do
    []
    |> maybe_append(
      not is_number(Map.get(report, "accepted_snapshot_age_s")),
      "accepted_snapshot_age_unknown"
    )
    |> maybe_append(
      not is_number(Map.get(report, "horizon_start_offset_s")),
      "horizon_alignment_unknown"
    )
    |> maybe_append(state_quality_status(report) == "unknown", "accepted_state_quality_unknown")
  end

  defp snapshot_stale?(report) do
    age = Map.get(report, "accepted_snapshot_age_s")
    max_age = Map.get(report, "max_snapshot_age_s")

    is_number(age) and is_number(max_age) and age > max_age
  end

  defp horizon_stale?(report) do
    offset = Map.get(report, "horizon_start_offset_s")
    max_offset = Map.get(report, "max_horizon_start_offset_s")

    is_number(offset) and is_number(max_offset) and abs(offset) > max_offset
  end

  defp state_quality_status(report) do
    level = Map.get(report, "accepted_state_quality_level")
    allowed_levels = list_value(report, "allowed_state_quality_levels")

    cond do
      not is_binary(level) -> "unknown"
      level in allowed_levels -> "accepted"
      true -> "not_accepted"
    end
  end

  defp status(stale_reasons, unknown_reasons) do
    cond do
      stale_reasons != [] -> "stale"
      unknown_reasons != [] -> "unknown"
      true -> "current"
    end
  end

  defp maybe_append(values, true, value), do: values ++ [value]
  defp maybe_append(values, _condition, _value), do: values

  defp list_value(map, key), do: Map.get(map, key) || []
end
