defmodule OrbitalDynamics.Schema.ProviderCounterofferSummaryContracts do
  @moduledoc false

  def validate_review(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "provider_counteroffer_review_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_provider_counteroffer_review_summary"
    )
    |> expect_one_of(callbacks, path, summary, "source_artifact_type", [
      "provider_counteroffer_report.v1"
    ])
    |> expect_optional_one_of(callbacks, path, summary, "source_counteroffer_artifact_type", [
      "station_calendar_provider.v1",
      "station_calendar_report.v1"
    ])
    |> expect_optional_type(callbacks, path, summary, "source", :binary)
    |> validate_stable_ids(callbacks, path, summary, ["source_artifact_id"])
    |> expect_non_negative_integer(callbacks, path, summary, "counteroffer_count")
    |> expect_non_negative_integer(callbacks, path, summary, "reviewable_count")
    |> expect_one_of(callbacks, path, summary, "counteroffer_review_status", [
      "clear",
      "review_required"
    ])
    |> expect_type(callbacks, path, summary, "counteroffer_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".counteroffer_status_counts",
      Map.get(summary, "counteroffer_status_counts")
    )
    |> expect_type(callbacks, path, summary, "counteroffer_negotiation_state_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".counteroffer_negotiation_state_counts",
      Map.get(summary, "counteroffer_negotiation_state_counts")
    )
    |> expect_non_negative_integer(callbacks, path, summary, "counteroffer_lock_deadline_count")
    |> expect_optional_number(callbacks, path, summary, "earliest_counteroffer_lock_deadline_s")
    |> expect_type(callbacks, path, summary, "counteroffer_lock_deadline_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".counteroffer_lock_deadline_status_counts",
      Map.get(summary, "counteroffer_lock_deadline_status_counts")
    )
    |> expect_type(callbacks, path, summary, "counteroffer_ids_by_lock_deadline_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".counteroffer_ids_by_lock_deadline_status",
      Map.get(summary, "counteroffer_ids_by_lock_deadline_status")
    )
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "expired_counteroffer_lock_deadline_count"
    )
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "active_counteroffer_lock_deadline_count"
    )
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "missing_counteroffer_lock_deadline_count"
    )
    |> expect_type(callbacks, path, summary, "review_counteroffer_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".review_counteroffer_ids",
      Map.get(summary, "review_counteroffer_ids")
    )
    |> expect_type(callbacks, path, summary, "rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(summary, "rows", []),
      row_validator(callbacks)
    )
    |> expect_type(callbacks, path, summary, "review_rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".review_rows",
      Map.get(summary, "review_rows", []),
      row_validator(callbacks)
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> validate_review_counts(callbacks, path, summary)
  end

  defp validate_review_counts(issues, callbacks, path, summary) do
    rows =
      summary
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    review_rows = Enum.filter(rows, &(&1["reviewable"] == true))

    issues
    |> expect_field_equals(callbacks, path, summary, "counteroffer_count", length(rows))
    |> expect_field_equals(callbacks, path, summary, "reviewable_count", length(review_rows))
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_review_status",
      if(review_rows == [], do: "clear", else: "review_required")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_status_counts",
      frequency_map(callbacks, rows, "provider_counteroffer_status"),
      "must equal row-derived counteroffer_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_negotiation_state_counts",
      frequency_map(callbacks, rows, "provider_counteroffer_negotiation_state"),
      "must equal row-derived counteroffer_negotiation_state_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_lock_deadline_count",
      numeric_value_count(callbacks, rows, "provider_counteroffer_lock_deadline_s"),
      "must equal row-derived counteroffer_lock_deadline_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "earliest_counteroffer_lock_deadline_s",
      numeric_value_min(callbacks, rows, "provider_counteroffer_lock_deadline_s"),
      "must equal row-derived earliest_counteroffer_lock_deadline_s"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_lock_deadline_status_counts",
      frequency_map(callbacks, rows, "provider_counteroffer_lock_deadline_status"),
      "must equal row-derived counteroffer_lock_deadline_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_ids_by_lock_deadline_status",
      ids_by(callbacks, rows, "provider_counteroffer_lock_deadline_status"),
      "must equal row-derived counteroffer_ids_by_lock_deadline_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "expired_counteroffer_lock_deadline_count",
      status_count(callbacks, rows, "provider_counteroffer_lock_deadline_status", "expired"),
      "must equal row-derived expired_counteroffer_lock_deadline_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "active_counteroffer_lock_deadline_count",
      status_count(callbacks, rows, "provider_counteroffer_lock_deadline_status", "active"),
      "must equal row-derived active_counteroffer_lock_deadline_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "missing_counteroffer_lock_deadline_count",
      status_count(callbacks, rows, "provider_counteroffer_lock_deadline_status", "missing"),
      "must equal row-derived missing_counteroffer_lock_deadline_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_counteroffer_ids",
      ids(callbacks, review_rows),
      "must equal row-derived review_counteroffer_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_rows",
      review_rows,
      "must equal reviewable provider-counteroffer rows"
    )
  end

  def validate_import_readiness(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "provider_counteroffer_import_readiness_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_provider_counteroffer_import_readiness_summary"
    )
    |> expect_one_of(callbacks, path, summary, "source_artifact_type", [
      "provider_counteroffer_report.v1"
    ])
    |> expect_optional_one_of(callbacks, path, summary, "source_counteroffer_artifact_type", [
      "station_calendar_provider.v1",
      "station_calendar_report.v1"
    ])
    |> expect_optional_type(callbacks, path, summary, "source", :binary)
    |> validate_stable_ids(callbacks, path, summary, ["source_artifact_id"])
    |> expect_non_negative_integer(callbacks, path, summary, "counteroffer_count")
    |> expect_non_negative_integer(callbacks, path, summary, "reviewable_count")
    |> expect_one_of(
      callbacks,
      path,
      summary,
      "import_readiness_status",
      capabilities().provider_counteroffer_import_readiness_statuses
    )
    |> expect_one_of(
      callbacks,
      path,
      summary,
      "import_classification",
      capabilities().provider_counteroffer_import_classifications
    )
    |> expect_non_negative_integer(callbacks, path, summary, "ready_for_import_count")
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "review_required_before_import_count"
    )
    |> expect_non_negative_integer(callbacks, path, summary, "no_import_required_count")
    |> expect_type(callbacks, path, summary, "counteroffer_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".counteroffer_status_counts",
      Map.get(summary, "counteroffer_status_counts")
    )
    |> expect_type(callbacks, path, summary, "counteroffer_negotiation_state_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".counteroffer_negotiation_state_counts",
      Map.get(summary, "counteroffer_negotiation_state_counts")
    )
    |> expect_type(callbacks, path, summary, "required_import_action_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".required_import_action_counts",
      Map.get(summary, "required_import_action_counts")
    )
    |> expect_type(callbacks, path, summary, "provider_counteroffer_import_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".provider_counteroffer_import_status_counts",
      Map.get(summary, "provider_counteroffer_import_status_counts")
    )
    |> expect_type(callbacks, path, summary, "counteroffer_lock_deadline_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".counteroffer_lock_deadline_status_counts",
      Map.get(summary, "counteroffer_lock_deadline_status_counts")
    )
    |> expect_type(callbacks, path, summary, "counteroffer_ids_by_required_import_action", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".counteroffer_ids_by_required_import_action",
      Map.get(summary, "counteroffer_ids_by_required_import_action")
    )
    |> expect_type(callbacks, path, summary, "counteroffer_ids_by_import_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".counteroffer_ids_by_import_status",
      Map.get(summary, "counteroffer_ids_by_import_status")
    )
    |> expect_type(callbacks, path, summary, "counteroffer_ids_by_lock_deadline_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".counteroffer_ids_by_lock_deadline_status",
      Map.get(summary, "counteroffer_ids_by_lock_deadline_status")
    )
    |> expect_type(callbacks, path, summary, "review_counteroffer_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".review_counteroffer_ids",
      Map.get(summary, "review_counteroffer_ids")
    )
    |> expect_type(callbacks, path, summary, "no_import_required_counteroffer_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".no_import_required_counteroffer_ids",
      Map.get(summary, "no_import_required_counteroffer_ids")
    )
    |> expect_type(callbacks, path, summary, "import_readiness_rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".import_readiness_rows",
      Map.get(summary, "import_readiness_rows", []),
      row_validator(callbacks)
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> validate_import_readiness_counts(callbacks, path, summary)
  end

  defp validate_import_readiness_counts(issues, callbacks, path, summary) do
    rows =
      summary
      |> Map.get("import_readiness_rows", [])
      |> Enum.filter(&is_map/1)

    review_rows = Enum.filter(rows, &(&1["reviewable"] == true))
    no_import_rows = Enum.reject(rows, &(&1["reviewable"] == true))

    issues
    |> expect_field_equals(callbacks, path, summary, "counteroffer_count", length(rows))
    |> expect_field_equals(callbacks, path, summary, "reviewable_count", length(review_rows))
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "import_readiness_status",
      if(review_rows == [], do: "clear", else: "review_required")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "import_classification",
      if(review_rows == [], do: "not_applicable", else: "review_only")
    )
    |> expect_field_equals(callbacks, path, summary, "ready_for_import_count", 0)
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_required_before_import_count",
      length(review_rows),
      "must equal row-derived review_required_before_import_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "no_import_required_count",
      length(no_import_rows),
      "must equal row-derived no_import_required_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_status_counts",
      frequency_map(callbacks, rows, "provider_counteroffer_status"),
      "must equal row-derived counteroffer_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_negotiation_state_counts",
      frequency_map(callbacks, rows, "provider_counteroffer_negotiation_state"),
      "must equal row-derived counteroffer_negotiation_state_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "required_import_action_counts",
      frequency_map(callbacks, rows, "required_operator_action"),
      "must equal row-derived required_import_action_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "provider_counteroffer_import_status_counts",
      frequency_map(callbacks, rows, "provider_counteroffer_import_status"),
      "must equal row-derived provider_counteroffer_import_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_lock_deadline_status_counts",
      frequency_map(callbacks, rows, "provider_counteroffer_lock_deadline_status"),
      "must equal row-derived counteroffer_lock_deadline_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_ids_by_required_import_action",
      ids_by(callbacks, rows, "required_operator_action"),
      "must equal row-derived counteroffer_ids_by_required_import_action"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_ids_by_import_status",
      ids_by(callbacks, rows, "provider_counteroffer_import_status"),
      "must equal row-derived counteroffer_ids_by_import_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_ids_by_lock_deadline_status",
      ids_by(callbacks, rows, "provider_counteroffer_lock_deadline_status"),
      "must equal row-derived counteroffer_ids_by_lock_deadline_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_counteroffer_ids",
      ids(callbacks, review_rows),
      "must equal row-derived review_counteroffer_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "no_import_required_counteroffer_ids",
      ids(callbacks, no_import_rows),
      "must equal row-derived no_import_required_counteroffer_ids"
    )
  end

  def validate_plan_impact(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "provider_counteroffer_plan_impact_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_provider_counteroffer_plan_impact_summary"
    )
    |> expect_one_of(callbacks, path, summary, "source_artifact_type", [
      "provider_counteroffer_report.v1"
    ])
    |> expect_optional_one_of(callbacks, path, summary, "source_counteroffer_artifact_type", [
      "station_calendar_provider.v1",
      "station_calendar_report.v1"
    ])
    |> expect_optional_type(callbacks, path, summary, "source", :binary)
    |> validate_stable_ids(callbacks, path, summary, ["source_artifact_id"])
    |> expect_non_negative_integer(callbacks, path, summary, "counteroffer_count")
    |> expect_non_negative_integer(callbacks, path, summary, "reviewable_count")
    |> expect_one_of(
      callbacks,
      path,
      summary,
      "plan_impact_status",
      capabilities().provider_counteroffer_plan_impact_statuses
    )
    |> expect_non_negative_integer(callbacks, path, summary, "timing_shift_counteroffer_count")
    |> expect_non_negative_integer(callbacks, path, summary, "counteroffer_cost_delta_count")
    |> expect_number(callbacks, path, summary, "counteroffer_cost_delta_total")
    |> expect_type(callbacks, path, summary, "counteroffer_lock_deadline_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".counteroffer_lock_deadline_status_counts",
      Map.get(summary, "counteroffer_lock_deadline_status_counts")
    )
    |> expect_type(callbacks, path, summary, "affected_station_calendar_entry_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".affected_station_calendar_entry_ids",
      Map.get(summary, "affected_station_calendar_entry_ids")
    )
    |> expect_type(callbacks, path, summary, "affected_provider_entry_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".affected_provider_entry_ids",
      Map.get(summary, "affected_provider_entry_ids")
    )
    |> expect_type(callbacks, path, summary, "impact_counteroffer_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".impact_counteroffer_ids",
      Map.get(summary, "impact_counteroffer_ids")
    )
    |> expect_type(callbacks, path, summary, "timing_shift_counteroffer_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".timing_shift_counteroffer_ids",
      Map.get(summary, "timing_shift_counteroffer_ids")
    )
    |> expect_type(callbacks, path, summary, "cost_delta_counteroffer_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".cost_delta_counteroffer_ids",
      Map.get(summary, "cost_delta_counteroffer_ids")
    )
    |> expect_type(callbacks, path, summary, "counteroffer_ids_by_lock_deadline_status", :map)
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".counteroffer_ids_by_lock_deadline_status",
      Map.get(summary, "counteroffer_ids_by_lock_deadline_status")
    )
    |> expect_type(callbacks, path, summary, "rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(summary, "rows", []),
      row_validator(callbacks)
    )
    |> expect_type(callbacks, path, summary, "impact_rows", :list)
    |> validate_rows(
      callbacks,
      path <> ".impact_rows",
      Map.get(summary, "impact_rows", []),
      row_validator(callbacks)
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> validate_plan_impact_counts(callbacks, path, summary)
  end

  defp validate_plan_impact_counts(issues, callbacks, path, summary) do
    rows =
      summary
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    reviewable_rows = Enum.filter(rows, &(&1["reviewable"] == true))
    timing_shift_rows = timing_shift_rows(callbacks, rows)
    cost_delta_rows = numeric_rows(callbacks, rows, "provider_counteroffer_cost_delta")

    issues
    |> expect_field_equals(callbacks, path, summary, "counteroffer_count", length(rows))
    |> expect_field_equals(callbacks, path, summary, "reviewable_count", length(reviewable_rows))
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "plan_impact_status",
      if(reviewable_rows == [], do: "clear", else: "review_required")
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "timing_shift_counteroffer_count",
      length(timing_shift_rows),
      "must equal row-derived timing_shift_counteroffer_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_cost_delta_count",
      length(cost_delta_rows),
      "must equal row-derived counteroffer_cost_delta_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_cost_delta_total",
      numeric_value_sum(callbacks, rows, "provider_counteroffer_cost_delta"),
      "must equal row-derived counteroffer_cost_delta_total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_lock_deadline_status_counts",
      frequency_map(callbacks, rows, "provider_counteroffer_lock_deadline_status"),
      "must equal row-derived counteroffer_lock_deadline_status_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "affected_station_calendar_entry_ids",
      stable_ids(callbacks, rows, "station_calendar_entry_id"),
      "must equal row-derived affected_station_calendar_entry_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "affected_provider_entry_ids",
      stable_ids(callbacks, rows, "station_calendar_provider_entry_id"),
      "must equal row-derived affected_provider_entry_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "impact_counteroffer_ids",
      ids(callbacks, reviewable_rows),
      "must equal row-derived impact_counteroffer_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "timing_shift_counteroffer_ids",
      ids(callbacks, timing_shift_rows),
      "must equal row-derived timing_shift_counteroffer_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "cost_delta_counteroffer_ids",
      ids(callbacks, cost_delta_rows),
      "must equal row-derived cost_delta_counteroffer_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "counteroffer_ids_by_lock_deadline_status",
      ids_by(callbacks, rows, "provider_counteroffer_lock_deadline_status"),
      "must equal row-derived counteroffer_ids_by_lock_deadline_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "impact_rows",
      reviewable_rows,
      "must equal reviewable provider-counteroffer rows"
    )
  end

  defp capabilities, do: OrbitalDynamics.Communications.StationCalendar.capabilities()

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp row_validator(callbacks),
    do: fn issues, path, row ->
      apply(require_callback(callbacks, :validate_provider_counteroffer_row), [issues, path, row])
    end

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_optional_one_of(issues, callbacks, path, map, field, allowed),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_non_negative_integer), [issues, path, map, field])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_number), [issues, path, map, field])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(require_callback(callbacks, :expect_field_equals), [
        issues,
        path,
        map,
        field,
        expected
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(require_callback(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_non_negative_integer_count_map(issues, callbacks, path, values),
    do:
      apply(require_callback(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        values
      ])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(require_callback(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(require_callback(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp frequency_map(callbacks, rows, field),
    do: apply(require_callback(callbacks, :frequency_map), [rows, field])

  defp numeric_value_count(callbacks, rows, field),
    do:
      apply(require_callback(callbacks, :provider_counteroffer_numeric_value_count), [rows, field])

  defp numeric_value_sum(callbacks, rows, field),
    do:
      apply(require_callback(callbacks, :provider_counteroffer_numeric_value_sum), [rows, field])

  defp numeric_value_min(callbacks, rows, field),
    do:
      apply(require_callback(callbacks, :provider_counteroffer_numeric_value_min), [rows, field])

  defp numeric_rows(callbacks, rows, field),
    do: apply(require_callback(callbacks, :provider_counteroffer_numeric_rows), [rows, field])

  defp timing_shift_rows(callbacks, rows),
    do: apply(require_callback(callbacks, :provider_counteroffer_timing_shift_rows), [rows])

  defp stable_ids(callbacks, rows, field),
    do: apply(require_callback(callbacks, :provider_counteroffer_stable_ids), [rows, field])

  defp ids_by(callbacks, rows, field),
    do: apply(require_callback(callbacks, :provider_counteroffer_ids_by), [rows, field])

  defp status_count(callbacks, rows, field, status),
    do:
      apply(require_callback(callbacks, :provider_counteroffer_status_count), [
        rows,
        field,
        status
      ])

  defp ids(callbacks, rows),
    do: apply(require_callback(callbacks, :provider_counteroffer_ids), [rows])
end
