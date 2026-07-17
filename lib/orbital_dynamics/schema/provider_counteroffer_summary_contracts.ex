defmodule OrbitalDynamics.Schema.ProviderCounterofferSummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.ProviderCounterofferReportContracts

  import OrbitalDynamics.Schema.CollectionAggregation, only: [frequency_map: 2]
  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_stable_id_array_map: 3,
      validate_stable_id_list: 3,
      validate_stable_ids: 4
    ]

  def validate_review(issues, path, summary) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "provider_counteroffer_review_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_provider_counteroffer_review_summary"
    )
    |> expect_one_of(path, summary, "source_artifact_type", [
      "provider_counteroffer_report.v1"
    ])
    |> expect_optional_one_of(path, summary, "source_counteroffer_artifact_type", [
      "station_calendar_provider.v1",
      "station_calendar_report.v1"
    ])
    |> expect_optional_type(path, summary, "source", :binary)
    |> validate_stable_ids(path, summary, ["source_artifact_id"])
    |> expect_non_negative_integer(path, summary, "counteroffer_count")
    |> expect_non_negative_integer(path, summary, "reviewable_count")
    |> expect_one_of(path, summary, "counteroffer_review_status", [
      "clear",
      "review_required"
    ])
    |> expect_type(path, summary, "counteroffer_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".counteroffer_status_counts",
      Map.get(summary, "counteroffer_status_counts")
    )
    |> expect_type(path, summary, "counteroffer_negotiation_state_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".counteroffer_negotiation_state_counts",
      Map.get(summary, "counteroffer_negotiation_state_counts")
    )
    |> expect_non_negative_integer(path, summary, "counteroffer_lock_deadline_count")
    |> expect_optional_number(path, summary, "earliest_counteroffer_lock_deadline_s")
    |> expect_type(path, summary, "counteroffer_lock_deadline_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".counteroffer_lock_deadline_status_counts",
      Map.get(summary, "counteroffer_lock_deadline_status_counts")
    )
    |> expect_type(path, summary, "counteroffer_ids_by_lock_deadline_status", :map)
    |> validate_stable_id_array_map(
      path <> ".counteroffer_ids_by_lock_deadline_status",
      Map.get(summary, "counteroffer_ids_by_lock_deadline_status")
    )
    |> expect_non_negative_integer(
      path,
      summary,
      "expired_counteroffer_lock_deadline_count"
    )
    |> expect_non_negative_integer(
      path,
      summary,
      "active_counteroffer_lock_deadline_count"
    )
    |> expect_non_negative_integer(
      path,
      summary,
      "missing_counteroffer_lock_deadline_count"
    )
    |> expect_type(path, summary, "review_counteroffer_ids", :list)
    |> validate_stable_id_list(
      path <> ".review_counteroffer_ids",
      Map.get(summary, "review_counteroffer_ids")
    )
    |> expect_type(path, summary, "rows", :list)
    |> validate_rows(
      path <> ".rows",
      Map.get(summary, "rows", []),
      row_validator()
    )
    |> expect_type(path, summary, "review_rows", :list)
    |> validate_rows(
      path <> ".review_rows",
      Map.get(summary, "review_rows", []),
      row_validator()
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> validate_review_counts(path, summary)
  end

  defp validate_review_counts(issues, path, summary) do
    rows =
      summary
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    review_rows = Enum.filter(rows, &(&1["reviewable"] == true))

    issues
    |> expect_field_equals(path, summary, "counteroffer_count", length(rows))
    |> expect_field_equals(path, summary, "reviewable_count", length(review_rows))
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_review_status",
      if(review_rows == [], do: "clear", else: "review_required")
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_status_counts",
      frequency_map(rows, "provider_counteroffer_status"),
      "must equal row-derived counteroffer_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_negotiation_state_counts",
      frequency_map(rows, "provider_counteroffer_negotiation_state"),
      "must equal row-derived counteroffer_negotiation_state_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_lock_deadline_count",
      numeric_value_count(rows, "provider_counteroffer_lock_deadline_s"),
      "must equal row-derived counteroffer_lock_deadline_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "earliest_counteroffer_lock_deadline_s",
      numeric_value_min(rows, "provider_counteroffer_lock_deadline_s"),
      "must equal row-derived earliest_counteroffer_lock_deadline_s"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_lock_deadline_status_counts",
      frequency_map(rows, "provider_counteroffer_lock_deadline_status"),
      "must equal row-derived counteroffer_lock_deadline_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_ids_by_lock_deadline_status",
      ids_by(rows, "provider_counteroffer_lock_deadline_status"),
      "must equal row-derived counteroffer_ids_by_lock_deadline_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "expired_counteroffer_lock_deadline_count",
      status_count(rows, "provider_counteroffer_lock_deadline_status", "expired"),
      "must equal row-derived expired_counteroffer_lock_deadline_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "active_counteroffer_lock_deadline_count",
      status_count(rows, "provider_counteroffer_lock_deadline_status", "active"),
      "must equal row-derived active_counteroffer_lock_deadline_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "missing_counteroffer_lock_deadline_count",
      status_count(rows, "provider_counteroffer_lock_deadline_status", "missing"),
      "must equal row-derived missing_counteroffer_lock_deadline_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_counteroffer_ids",
      ids(review_rows),
      "must equal row-derived review_counteroffer_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_rows",
      review_rows,
      "must equal reviewable provider-counteroffer rows"
    )
  end

  def validate_import_readiness(issues, path, summary) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "provider_counteroffer_import_readiness_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_provider_counteroffer_import_readiness_summary"
    )
    |> expect_one_of(path, summary, "source_artifact_type", [
      "provider_counteroffer_report.v1"
    ])
    |> expect_optional_one_of(path, summary, "source_counteroffer_artifact_type", [
      "station_calendar_provider.v1",
      "station_calendar_report.v1"
    ])
    |> expect_optional_type(path, summary, "source", :binary)
    |> validate_stable_ids(path, summary, ["source_artifact_id"])
    |> expect_non_negative_integer(path, summary, "counteroffer_count")
    |> expect_non_negative_integer(path, summary, "reviewable_count")
    |> expect_one_of(
      path,
      summary,
      "import_readiness_status",
      capabilities().provider_counteroffer_import_readiness_statuses
    )
    |> expect_one_of(
      path,
      summary,
      "import_classification",
      capabilities().provider_counteroffer_import_classifications
    )
    |> expect_non_negative_integer(path, summary, "ready_for_import_count")
    |> expect_non_negative_integer(
      path,
      summary,
      "review_required_before_import_count"
    )
    |> expect_non_negative_integer(path, summary, "no_import_required_count")
    |> expect_type(path, summary, "counteroffer_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".counteroffer_status_counts",
      Map.get(summary, "counteroffer_status_counts")
    )
    |> expect_type(path, summary, "counteroffer_negotiation_state_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".counteroffer_negotiation_state_counts",
      Map.get(summary, "counteroffer_negotiation_state_counts")
    )
    |> expect_type(path, summary, "required_import_action_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".required_import_action_counts",
      Map.get(summary, "required_import_action_counts")
    )
    |> expect_type(path, summary, "provider_counteroffer_import_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".provider_counteroffer_import_status_counts",
      Map.get(summary, "provider_counteroffer_import_status_counts")
    )
    |> expect_type(path, summary, "counteroffer_lock_deadline_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".counteroffer_lock_deadline_status_counts",
      Map.get(summary, "counteroffer_lock_deadline_status_counts")
    )
    |> expect_type(path, summary, "counteroffer_ids_by_required_import_action", :map)
    |> validate_stable_id_array_map(
      path <> ".counteroffer_ids_by_required_import_action",
      Map.get(summary, "counteroffer_ids_by_required_import_action")
    )
    |> expect_type(path, summary, "counteroffer_ids_by_import_status", :map)
    |> validate_stable_id_array_map(
      path <> ".counteroffer_ids_by_import_status",
      Map.get(summary, "counteroffer_ids_by_import_status")
    )
    |> expect_type(path, summary, "counteroffer_ids_by_lock_deadline_status", :map)
    |> validate_stable_id_array_map(
      path <> ".counteroffer_ids_by_lock_deadline_status",
      Map.get(summary, "counteroffer_ids_by_lock_deadline_status")
    )
    |> expect_type(path, summary, "review_counteroffer_ids", :list)
    |> validate_stable_id_list(
      path <> ".review_counteroffer_ids",
      Map.get(summary, "review_counteroffer_ids")
    )
    |> expect_type(path, summary, "no_import_required_counteroffer_ids", :list)
    |> validate_stable_id_list(
      path <> ".no_import_required_counteroffer_ids",
      Map.get(summary, "no_import_required_counteroffer_ids")
    )
    |> expect_type(path, summary, "import_readiness_rows", :list)
    |> validate_rows(
      path <> ".import_readiness_rows",
      Map.get(summary, "import_readiness_rows", []),
      row_validator()
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> validate_import_readiness_counts(path, summary)
  end

  defp validate_import_readiness_counts(issues, path, summary) do
    rows =
      summary
      |> Map.get("import_readiness_rows", [])
      |> Enum.filter(&is_map/1)

    review_rows = Enum.filter(rows, &(&1["reviewable"] == true))
    no_import_rows = Enum.reject(rows, &(&1["reviewable"] == true))

    issues
    |> expect_field_equals(path, summary, "counteroffer_count", length(rows))
    |> expect_field_equals(path, summary, "reviewable_count", length(review_rows))
    |> expect_field_equals(
      path,
      summary,
      "import_readiness_status",
      if(review_rows == [], do: "clear", else: "review_required")
    )
    |> expect_field_equals(
      path,
      summary,
      "import_classification",
      if(review_rows == [], do: "not_applicable", else: "review_only")
    )
    |> expect_field_equals(path, summary, "ready_for_import_count", 0)
    |> expect_field_equals(
      path,
      summary,
      "review_required_before_import_count",
      length(review_rows),
      "must equal row-derived review_required_before_import_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "no_import_required_count",
      length(no_import_rows),
      "must equal row-derived no_import_required_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_status_counts",
      frequency_map(rows, "provider_counteroffer_status"),
      "must equal row-derived counteroffer_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_negotiation_state_counts",
      frequency_map(rows, "provider_counteroffer_negotiation_state"),
      "must equal row-derived counteroffer_negotiation_state_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "required_import_action_counts",
      frequency_map(rows, "required_operator_action"),
      "must equal row-derived required_import_action_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_counteroffer_import_status_counts",
      frequency_map(rows, "provider_counteroffer_import_status"),
      "must equal row-derived provider_counteroffer_import_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_lock_deadline_status_counts",
      frequency_map(rows, "provider_counteroffer_lock_deadline_status"),
      "must equal row-derived counteroffer_lock_deadline_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_ids_by_required_import_action",
      ids_by(rows, "required_operator_action"),
      "must equal row-derived counteroffer_ids_by_required_import_action"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_ids_by_import_status",
      ids_by(rows, "provider_counteroffer_import_status"),
      "must equal row-derived counteroffer_ids_by_import_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_ids_by_lock_deadline_status",
      ids_by(rows, "provider_counteroffer_lock_deadline_status"),
      "must equal row-derived counteroffer_ids_by_lock_deadline_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_counteroffer_ids",
      ids(review_rows),
      "must equal row-derived review_counteroffer_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "no_import_required_counteroffer_ids",
      ids(no_import_rows),
      "must equal row-derived no_import_required_counteroffer_ids"
    )
  end

  def validate_plan_impact(issues, path, summary) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "provider_counteroffer_plan_impact_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_provider_counteroffer_plan_impact_summary"
    )
    |> expect_one_of(path, summary, "source_artifact_type", [
      "provider_counteroffer_report.v1"
    ])
    |> expect_optional_one_of(path, summary, "source_counteroffer_artifact_type", [
      "station_calendar_provider.v1",
      "station_calendar_report.v1"
    ])
    |> expect_optional_type(path, summary, "source", :binary)
    |> validate_stable_ids(path, summary, ["source_artifact_id"])
    |> expect_non_negative_integer(path, summary, "counteroffer_count")
    |> expect_non_negative_integer(path, summary, "reviewable_count")
    |> expect_one_of(
      path,
      summary,
      "plan_impact_status",
      capabilities().provider_counteroffer_plan_impact_statuses
    )
    |> expect_non_negative_integer(path, summary, "timing_shift_counteroffer_count")
    |> expect_non_negative_integer(path, summary, "counteroffer_cost_delta_count")
    |> expect_number(path, summary, "counteroffer_cost_delta_total")
    |> expect_type(path, summary, "counteroffer_lock_deadline_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".counteroffer_lock_deadline_status_counts",
      Map.get(summary, "counteroffer_lock_deadline_status_counts")
    )
    |> expect_type(path, summary, "affected_station_calendar_entry_ids", :list)
    |> validate_stable_id_list(
      path <> ".affected_station_calendar_entry_ids",
      Map.get(summary, "affected_station_calendar_entry_ids")
    )
    |> expect_type(path, summary, "affected_provider_entry_ids", :list)
    |> validate_stable_id_list(
      path <> ".affected_provider_entry_ids",
      Map.get(summary, "affected_provider_entry_ids")
    )
    |> expect_type(path, summary, "impact_counteroffer_ids", :list)
    |> validate_stable_id_list(
      path <> ".impact_counteroffer_ids",
      Map.get(summary, "impact_counteroffer_ids")
    )
    |> expect_type(path, summary, "timing_shift_counteroffer_ids", :list)
    |> validate_stable_id_list(
      path <> ".timing_shift_counteroffer_ids",
      Map.get(summary, "timing_shift_counteroffer_ids")
    )
    |> expect_type(path, summary, "cost_delta_counteroffer_ids", :list)
    |> validate_stable_id_list(
      path <> ".cost_delta_counteroffer_ids",
      Map.get(summary, "cost_delta_counteroffer_ids")
    )
    |> expect_type(path, summary, "counteroffer_ids_by_lock_deadline_status", :map)
    |> validate_stable_id_array_map(
      path <> ".counteroffer_ids_by_lock_deadline_status",
      Map.get(summary, "counteroffer_ids_by_lock_deadline_status")
    )
    |> expect_type(path, summary, "rows", :list)
    |> validate_rows(
      path <> ".rows",
      Map.get(summary, "rows", []),
      row_validator()
    )
    |> expect_type(path, summary, "impact_rows", :list)
    |> validate_rows(
      path <> ".impact_rows",
      Map.get(summary, "impact_rows", []),
      row_validator()
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> validate_plan_impact_counts(path, summary)
  end

  defp validate_plan_impact_counts(issues, path, summary) do
    rows =
      summary
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    reviewable_rows = Enum.filter(rows, &(&1["reviewable"] == true))
    timing_shift_rows = timing_shift_rows(rows)
    cost_delta_rows = numeric_rows(rows, "provider_counteroffer_cost_delta")

    issues
    |> expect_field_equals(path, summary, "counteroffer_count", length(rows))
    |> expect_field_equals(path, summary, "reviewable_count", length(reviewable_rows))
    |> expect_field_equals(
      path,
      summary,
      "plan_impact_status",
      if(reviewable_rows == [], do: "clear", else: "review_required")
    )
    |> expect_field_equals(
      path,
      summary,
      "timing_shift_counteroffer_count",
      length(timing_shift_rows),
      "must equal row-derived timing_shift_counteroffer_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_cost_delta_count",
      length(cost_delta_rows),
      "must equal row-derived counteroffer_cost_delta_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_cost_delta_total",
      numeric_value_sum(rows, "provider_counteroffer_cost_delta"),
      "must equal row-derived counteroffer_cost_delta_total"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_lock_deadline_status_counts",
      frequency_map(rows, "provider_counteroffer_lock_deadline_status"),
      "must equal row-derived counteroffer_lock_deadline_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "affected_station_calendar_entry_ids",
      stable_ids(rows, "station_calendar_entry_id"),
      "must equal row-derived affected_station_calendar_entry_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "affected_provider_entry_ids",
      stable_ids(rows, "station_calendar_provider_entry_id"),
      "must equal row-derived affected_provider_entry_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "impact_counteroffer_ids",
      ids(reviewable_rows),
      "must equal row-derived impact_counteroffer_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "timing_shift_counteroffer_ids",
      ids(timing_shift_rows),
      "must equal row-derived timing_shift_counteroffer_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "cost_delta_counteroffer_ids",
      ids(cost_delta_rows),
      "must equal row-derived cost_delta_counteroffer_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "counteroffer_ids_by_lock_deadline_status",
      ids_by(rows, "provider_counteroffer_lock_deadline_status"),
      "must equal row-derived counteroffer_ids_by_lock_deadline_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "impact_rows",
      reviewable_rows,
      "must equal reviewable provider-counteroffer rows"
    )
  end

  defp capabilities, do: OrbitalDynamics.Communications.StationCalendar.capabilities()

  defp row_validator, do: &ProviderCounterofferReportContracts.validate_row/3

  defp numeric_value_count(rows, field), do: length(numeric_values(rows, field))
  defp numeric_value_sum(rows, field), do: rows |> numeric_values(field) |> Enum.sum()

  defp numeric_value_min(rows, field),
    do: rows |> numeric_values(field) |> Enum.min(fn -> nil end)

  defp numeric_values(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
  end

  defp numeric_rows(rows, field) do
    Enum.filter(rows, fn row -> is_number(Map.get(row, field)) end)
  end

  defp timing_shift_rows(rows) do
    Enum.filter(rows, fn row ->
      Enum.any?(
        [
          row["provider_counteroffer_start_delta_s"],
          row["provider_counteroffer_end_delta_s"],
          row["provider_counteroffer_duration_delta_s"]
        ],
        fn value -> is_number(value) and value != 0.0 end
      )
    end)
  end

  defp ids(rows), do: stable_ids(rows, "provider_counteroffer_id")

  defp stable_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp ids_by(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "provider_counteroffer_id"))
    |> Enum.reject(fn {key, _ids} -> is_nil(key) end)
    |> Map.new(fn {key, ids} ->
      {key, ids |> Enum.filter(&is_binary/1) |> Enum.uniq() |> Enum.sort()}
    end)
  end

  defp status_count(rows, field, status) do
    Enum.count(rows, &(Map.get(&1, field) == status))
  end

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
