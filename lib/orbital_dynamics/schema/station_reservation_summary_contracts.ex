defmodule OrbitalDynamics.Schema.StationReservationSummaryContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionAggregation,
    only: [frequency_map: 2, id_array_count_map: 1]

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_field_equals: 6,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_number_list_items: 4,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_nested_stable_id_array_map: 3,
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3,
      validate_stable_id_list: 3,
      validate_stable_ids: 4
    ]

  def validate_review(issues, path, summary, model_limits) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "station_reservation_review_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_station_reservation_review_summary"
    )
    |> expect_optional_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      model_limits,
      "must match station calendar report model limits"
    )
    |> expect_one_of(path, summary, "source_artifact_type", [
      "station_reservation_report.v1"
    ])
    |> expect_type(path, summary, "source", :binary)
    |> expect_non_negative_integer(path, summary, "reservation_count")
    |> expect_non_negative_integer(path, summary, "affected_contact_reservation_count")
    |> expect_non_negative_integer(
      path,
      summary,
      "provider_calendar_contention_group_count"
    )
    |> expect_one_of(path, summary, "reservation_review_status", [
      "clear",
      "review_required"
    ])
    |> expect_non_negative_integer(path, summary, "reservation_expiration_count")
    |> expect_optional_number(path, summary, "earliest_reservation_expires_at_s")
    |> expect_type(path, summary, "reservation_expiration_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".reservation_expiration_status_counts",
      Map.get(summary, "reservation_expiration_status_counts")
    )
    |> expect_type(path, summary, "reservation_ids_by_expiration_status", :map)
    |> validate_stable_id_array_map(
      path <> ".reservation_ids_by_expiration_status",
      Map.get(summary, "reservation_ids_by_expiration_status")
    )
    |> expect_non_negative_integer(path, summary, "expired_reservation_count")
    |> expect_non_negative_integer(path, summary, "active_reservation_count")
    |> expect_non_negative_integer(
      path,
      summary,
      "missing_reservation_expiration_count"
    )
    |> expect_type(path, summary, "review_reservation_ids", :list)
    |> validate_stable_id_list(
      path <> ".review_reservation_ids",
      Map.get(summary, "review_reservation_ids")
    )
    |> expect_type(path, summary, "review_rows", :list)
    |> validate_rows(
      path <> ".review_rows",
      Map.get(summary, "review_rows", []),
      &validate_review_row/3
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> validate_review_counts(path, summary)
  end

  def validate_review_row(issues, path, row) do
    issues
    |> expect_one_of(path, row, "reservation_review_row_type", [
      "affected_contact",
      "provider_calendar_contention_group"
    ])
    |> validate_stable_ids(path, row, [
      "contact_id",
      "ground_station_id",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id"
    ])
    |> expect_optional_type(path, row, "station_contention_status", :binary)
    |> expect_optional_type(path, row, "provider_calendar_contention_status", :binary)
    |> expect_optional_type(path, row, "station_reservation_match_status", :binary)
    |> expect_type(path, row, "reservation_ids", :list)
    |> validate_optional_stable_id_list(path, row, "reservation_ids")
    |> expect_optional_type(path, row, "reservation_statuses", :list)
    |> validate_string_list_items(path, row, "reservation_statuses")
    |> expect_optional_type(path, row, "reserved_by", :list)
    |> validate_string_list_items(path, row, "reserved_by")
    |> expect_optional_type(path, row, "reservation_expires_at_s", :list)
    |> validate_number_list_items(path, row, "reservation_expires_at_s")
    |> expect_optional_one_of(path, row, "station_reservation_expiration_status", [
      "missing",
      "expired",
      "active",
      "declared"
    ])
    |> expect_optional_type(path, row, "required_operator_action", :binary)
  end

  defp validate_review_counts(issues, path, summary) do
    rows =
      summary
      |> Map.get("review_rows", [])
      |> Enum.filter(&is_map/1)

    affected_rows = Enum.filter(rows, &(&1["reservation_review_row_type"] == "affected_contact"))

    provider_rows =
      Enum.filter(
        rows,
        &(&1["reservation_review_row_type"] == "provider_calendar_contention_group")
      )

    issues
    |> expect_field_equals(path, summary, "reservation_count", length(rows))
    |> expect_field_equals(
      path,
      summary,
      "affected_contact_reservation_count",
      length(affected_rows),
      "must equal row-derived affected_contact_reservation_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_calendar_contention_group_count",
      length(provider_rows),
      "must equal row-derived provider_calendar_contention_group_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_review_status",
      if(rows == [], do: "clear", else: "review_required")
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_expiration_count",
      summary_expiration_count(rows),
      "must equal row-derived reservation_expiration_count"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "earliest_reservation_expires_at_s",
      summary_earliest_expiration(rows),
      "must equal row-derived earliest_reservation_expires_at_s"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_expiration_status_counts",
      frequency_map(rows, "station_reservation_expiration_status"),
      "must equal row-derived reservation_expiration_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_ids_by_expiration_status",
      summary_ids_by(rows, "station_reservation_expiration_status"),
      "must equal row-derived reservation_ids_by_expiration_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "expired_reservation_count",
      summary_status_count(rows, "expired")
    )
    |> expect_field_equals(
      path,
      summary,
      "active_reservation_count",
      summary_status_count(rows, "active")
    )
    |> expect_field_equals(
      path,
      summary,
      "missing_reservation_expiration_count",
      summary_status_count(rows, "missing")
    )
    |> expect_field_equals(
      path,
      summary,
      "review_reservation_ids",
      summary_ids(rows),
      "must equal row-derived review_reservation_ids"
    )
  end

  def validate_hold(issues, path, summary, model_limits) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "station_reservation_hold_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_station_reservation_hold_summary"
    )
    |> expect_optional_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      model_limits,
      "must match station calendar report model limits"
    )
    |> expect_one_of(path, summary, "source_artifact_type", [
      "station_reservation_report.v1"
    ])
    |> expect_type(path, summary, "source", :binary)
    |> expect_non_negative_integer(path, summary, "reservation_hold_count")
    |> expect_non_negative_integer(
      path,
      summary,
      "affected_contact_reservation_hold_count"
    )
    |> expect_non_negative_integer(
      path,
      summary,
      "provider_calendar_contention_hold_count"
    )
    |> expect_one_of(path, summary, "reservation_hold_review_status", [
      "clear",
      "review_required"
    ])
    |> expect_non_negative_integer(path, summary, "reservation_hold_expiration_count")
    |> expect_optional_number(path, summary, "earliest_reservation_hold_expires_at_s")
    |> expect_type(path, summary, "reservation_hold_expiration_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".reservation_hold_expiration_status_counts",
      Map.get(summary, "reservation_hold_expiration_status_counts")
    )
    |> expect_type(path, summary, "reservation_hold_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".reservation_hold_status_counts",
      Map.get(summary, "reservation_hold_status_counts")
    )
    |> expect_type(path, summary, "reservation_hold_ids", :list)
    |> validate_stable_id_list(
      path <> ".reservation_hold_ids",
      Map.get(summary, "reservation_hold_ids")
    )
    |> expect_type(path, summary, "reservation_hold_ids_by_expiration_status", :map)
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_ids_by_expiration_status",
      Map.get(summary, "reservation_hold_ids_by_expiration_status")
    )
    |> expect_type(path, summary, "reservation_hold_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_ids_by_status",
      Map.get(summary, "reservation_hold_ids_by_status")
    )
    |> expect_type(path, summary, "reservation_hold_ids_by_reserved_by", :map)
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_ids_by_reserved_by",
      Map.get(summary, "reservation_hold_ids_by_reserved_by")
    )
    |> expect_type(path, summary, "reservation_hold_ids_by_row_type", :map)
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_ids_by_row_type",
      Map.get(summary, "reservation_hold_ids_by_row_type")
    )
    |> expect_type(
      path,
      summary,
      "reservation_hold_contact_ids_by_expiration_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_contact_ids_by_expiration_status",
      Map.get(summary, "reservation_hold_contact_ids_by_expiration_status")
    )
    |> expect_type(path, summary, "review_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".review_contact_ids",
      Map.get(summary, "review_contact_ids")
    )
    |> expect_type(path, summary, "review_rows", :list)
    |> validate_rows(
      path <> ".review_rows",
      Map.get(summary, "review_rows", []),
      &validate_hold_row/3
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> validate_hold_counts(path, summary)
  end

  defp validate_hold_row(issues, path, row) do
    issues
    |> validate_review_row(path, row)
    |> validate_hold_row_status(path, row)
  end

  defp validate_hold_row_status(issues, path, row) do
    statuses = list_or_empty(Map.get(row, "reservation_statuses"))

    if Enum.any?(statuses, &hold_status?/1) do
      issues
    else
      [
        error("#{path}.reservation_statuses", "must include a hold reservation status")
        | issues
      ]
    end
  end

  defp hold_status?(status) when is_binary(status) do
    normalized =
      status
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/[\s_-]+/, "_")

    normalized == "held" or String.contains?(normalized, "hold")
  end

  defp hold_status?(_status), do: false

  defp validate_hold_counts(issues, path, summary) do
    rows =
      summary
      |> Map.get("review_rows", [])
      |> Enum.filter(&is_map/1)

    affected_rows = Enum.filter(rows, &(&1["reservation_review_row_type"] == "affected_contact"))

    provider_rows =
      Enum.filter(
        rows,
        &(&1["reservation_review_row_type"] == "provider_calendar_contention_group")
      )

    issues
    |> expect_field_equals(path, summary, "reservation_hold_count", length(rows))
    |> expect_field_equals(
      path,
      summary,
      "affected_contact_reservation_hold_count",
      length(affected_rows),
      "must equal row-derived affected_contact_reservation_hold_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "provider_calendar_contention_hold_count",
      length(provider_rows),
      "must equal row-derived provider_calendar_contention_hold_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_review_status",
      if(rows == [], do: "clear", else: "review_required")
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_expiration_count",
      summary_expiration_count(rows),
      "must equal row-derived reservation_hold_expiration_count"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "earliest_reservation_hold_expires_at_s",
      summary_earliest_expiration(rows),
      "must equal row-derived earliest_reservation_hold_expires_at_s"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_expiration_status_counts",
      frequency_map(rows, "station_reservation_expiration_status"),
      "must equal row-derived reservation_hold_expiration_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_status_counts",
      summary_ids_by_row_values(rows, "reservation_statuses")
      |> id_array_count_map(),
      "must equal row-derived reservation_hold_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_ids",
      summary_ids(rows),
      "must equal row-derived reservation_hold_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_ids_by_expiration_status",
      summary_ids_by(rows, "station_reservation_expiration_status"),
      "must equal row-derived reservation_hold_ids_by_expiration_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_ids_by_status",
      summary_ids_by_row_values(rows, "reservation_statuses"),
      "must equal row-derived reservation_hold_ids_by_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_ids_by_reserved_by",
      summary_ids_by_row_values(rows, "reserved_by"),
      "must equal row-derived reservation_hold_ids_by_reserved_by"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_ids_by_row_type",
      summary_ids_by(rows, "reservation_review_row_type"),
      "must equal row-derived reservation_hold_ids_by_row_type"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_contact_ids_by_expiration_status",
      summary_contact_ids_by(rows, "station_reservation_expiration_status"),
      "must equal row-derived reservation_hold_contact_ids_by_expiration_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_contact_ids",
      summary_contact_ids(rows),
      "must equal row-derived review_contact_ids"
    )
  end

  def validate_hold_import_readiness(issues, path, summary, model_limits) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "station_reservation_hold_import_readiness_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_station_reservation_hold_import_readiness_summary"
    )
    |> expect_optional_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      model_limits,
      "must match station calendar report model limits"
    )
    |> expect_one_of(path, summary, "source_artifact_type", [
      "station_reservation_report.v1"
    ])
    |> expect_optional_type(path, summary, "source", :binary)
    |> expect_non_negative_integer(path, summary, "reservation_hold_count")
    |> expect_one_of(path, summary, "import_readiness_status", [
      "clear",
      "review_required"
    ])
    |> expect_one_of(path, summary, "import_classification", [
      "not_applicable",
      "review_only"
    ])
    |> expect_non_negative_integer(path, summary, "ready_for_import_count")
    |> expect_non_negative_integer(
      path,
      summary,
      "review_required_before_import_count"
    )
    |> expect_non_negative_integer(path, summary, "no_import_required_count")
    |> expect_type(path, summary, "reservation_hold_import_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".reservation_hold_import_status_counts",
      Map.get(summary, "reservation_hold_import_status_counts")
    )
    |> expect_type(path, summary, "reservation_hold_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".reservation_hold_status_counts",
      Map.get(summary, "reservation_hold_status_counts")
    )
    |> expect_type(path, summary, "reservation_hold_expiration_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".reservation_hold_expiration_status_counts",
      Map.get(summary, "reservation_hold_expiration_status_counts")
    )
    |> expect_type(path, summary, "required_import_action_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".required_import_action_counts",
      Map.get(summary, "required_import_action_counts")
    )
    |> expect_type(path, summary, "reservation_hold_ids", :list)
    |> validate_stable_id_list(
      path <> ".reservation_hold_ids",
      Map.get(summary, "reservation_hold_ids")
    )
    |> expect_type(path, summary, "reservation_hold_ids_by_import_status", :map)
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_ids_by_import_status",
      Map.get(summary, "reservation_hold_ids_by_import_status")
    )
    |> expect_type(path, summary, "reservation_hold_ids_by_expiration_status", :map)
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_ids_by_expiration_status",
      Map.get(summary, "reservation_hold_ids_by_expiration_status")
    )
    |> expect_type(path, summary, "reservation_hold_ids_by_status", :map)
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_ids_by_status",
      Map.get(summary, "reservation_hold_ids_by_status")
    )
    |> expect_type(path, summary, "reservation_hold_ids_by_reserved_by", :map)
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_ids_by_reserved_by",
      Map.get(summary, "reservation_hold_ids_by_reserved_by")
    )
    |> expect_type(
      path,
      summary,
      "reservation_hold_ids_by_required_import_action",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_ids_by_required_import_action",
      Map.get(summary, "reservation_hold_ids_by_required_import_action")
    )
    |> expect_optional_type(path, summary, "reservation_hold_ids_by_direction", :map)
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_ids_by_direction",
      Map.get(summary, "reservation_hold_ids_by_direction")
    )
    |> expect_optional_type(
      path,
      summary,
      "reservation_hold_ids_by_direction_and_ground_station_id",
      :map
    )
    |> validate_nested_stable_id_array_map(
      path <> ".reservation_hold_ids_by_direction_and_ground_station_id",
      Map.get(summary, "reservation_hold_ids_by_direction_and_ground_station_id")
    )
    |> expect_type(
      path,
      summary,
      "reservation_hold_contact_ids_by_import_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_contact_ids_by_import_status",
      Map.get(summary, "reservation_hold_contact_ids_by_import_status")
    )
    |> expect_type(
      path,
      summary,
      "reservation_hold_contact_ids_by_expiration_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_contact_ids_by_expiration_status",
      Map.get(summary, "reservation_hold_contact_ids_by_expiration_status")
    )
    |> expect_optional_type(
      path,
      summary,
      "reservation_hold_contact_ids_by_direction",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".reservation_hold_contact_ids_by_direction",
      Map.get(summary, "reservation_hold_contact_ids_by_direction")
    )
    |> expect_optional_type(
      path,
      summary,
      "reservation_hold_contact_ids_by_direction_and_ground_station_id",
      :map
    )
    |> validate_nested_stable_id_array_map(
      path <> ".reservation_hold_contact_ids_by_direction_and_ground_station_id",
      Map.get(summary, "reservation_hold_contact_ids_by_direction_and_ground_station_id")
    )
    |> expect_type(path, summary, "review_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".review_contact_ids",
      Map.get(summary, "review_contact_ids")
    )
    |> expect_type(path, summary, "import_readiness_rows", :list)
    |> validate_rows(
      path <> ".import_readiness_rows",
      Map.get(summary, "import_readiness_rows", []),
      &validate_hold_import_readiness_row/3
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> validate_hold_import_readiness_counts(path, summary)
  end

  defp validate_hold_import_readiness_row(issues, path, row) do
    issues
    |> expect_one_of(path, row, "reservation_review_row_type", [
      "affected_contact",
      "provider_calendar_contention_group"
    ])
    |> validate_stable_ids(path, row, [
      "contact_id",
      "ground_station_id",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id"
    ])
    |> expect_optional_type(path, row, "station_contention_status", :binary)
    |> expect_optional_type(path, row, "provider_calendar_contention_status", :binary)
    |> expect_optional_type(path, row, "station_reservation_match_status", :binary)
    |> expect_type(path, row, "reservation_ids", :list)
    |> validate_optional_stable_id_list(path, row, "reservation_ids")
    |> expect_type(path, row, "reservation_statuses", :list)
    |> validate_string_list_items(path, row, "reservation_statuses")
    |> expect_optional_type(path, row, "reserved_by", :list)
    |> validate_string_list_items(path, row, "reserved_by")
    |> expect_optional_type(path, row, "reservation_expires_at_s", :list)
    |> validate_number_list_items(path, row, "reservation_expires_at_s")
    |> expect_optional_one_of(path, row, "station_reservation_expiration_status", [
      "missing",
      "expired",
      "active",
      "declared"
    ])
    |> expect_equal(
      path,
      row,
      "station_reservation_hold_import_status",
      "review_required_before_import"
    )
    |> expect_type(path, row, "required_operator_action", :binary)
  end

  defp validate_hold_import_readiness_counts(issues, path, summary) do
    rows =
      summary
      |> Map.get("import_readiness_rows", [])
      |> Enum.filter(&is_map/1)

    review_required_rows =
      Enum.filter(
        rows,
        &(&1["station_reservation_hold_import_status"] == "review_required_before_import")
      )

    no_import_rows =
      Enum.reject(
        rows,
        &(&1["station_reservation_hold_import_status"] == "review_required_before_import")
      )

    issues
    |> expect_field_equals(path, summary, "reservation_hold_count", length(rows))
    |> expect_field_equals(
      path,
      summary,
      "import_readiness_status",
      if(rows == [], do: "clear", else: "review_required")
    )
    |> expect_field_equals(
      path,
      summary,
      "import_classification",
      if(rows == [], do: "not_applicable", else: "review_only")
    )
    |> expect_field_equals(path, summary, "ready_for_import_count", 0)
    |> expect_field_equals(
      path,
      summary,
      "review_required_before_import_count",
      length(review_required_rows),
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
      "reservation_hold_import_status_counts",
      frequency_map(rows, "station_reservation_hold_import_status"),
      "must equal row-derived reservation_hold_import_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_status_counts",
      summary_ids_by_row_values(rows, "reservation_statuses")
      |> id_array_count_map(),
      "must equal row-derived reservation_hold_status_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_expiration_status_counts",
      frequency_map(rows, "station_reservation_expiration_status"),
      "must equal row-derived reservation_hold_expiration_status_counts"
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
      "reservation_hold_ids",
      summary_ids(rows),
      "must equal row-derived reservation_hold_ids"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_ids_by_import_status",
      summary_ids_by(rows, "station_reservation_hold_import_status"),
      "must equal row-derived reservation_hold_ids_by_import_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_ids_by_expiration_status",
      summary_ids_by(rows, "station_reservation_expiration_status"),
      "must equal row-derived reservation_hold_ids_by_expiration_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_ids_by_status",
      summary_ids_by_row_values(rows, "reservation_statuses"),
      "must equal row-derived reservation_hold_ids_by_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_ids_by_reserved_by",
      summary_ids_by_row_values(rows, "reserved_by"),
      "must equal row-derived reservation_hold_ids_by_reserved_by"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_ids_by_required_import_action",
      summary_ids_by(rows, "required_operator_action"),
      "must equal row-derived reservation_hold_ids_by_required_import_action"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "reservation_hold_ids_by_direction",
      summary_ids_by_direction(rows),
      "must equal row-derived reservation_hold_ids_by_direction"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "reservation_hold_ids_by_direction_and_ground_station_id",
      summary_ids_by_direction_and_ground_station(rows),
      "must equal row-derived reservation_hold_ids_by_direction_and_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_contact_ids_by_import_status",
      summary_contact_ids_by(rows, "station_reservation_hold_import_status"),
      "must equal row-derived reservation_hold_contact_ids_by_import_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "reservation_hold_contact_ids_by_expiration_status",
      summary_contact_ids_by(rows, "station_reservation_expiration_status"),
      "must equal row-derived reservation_hold_contact_ids_by_expiration_status"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "reservation_hold_contact_ids_by_direction",
      row_ids_by_direction(rows, "contact_id"),
      "must equal row-derived reservation_hold_contact_ids_by_direction"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "reservation_hold_contact_ids_by_direction_and_ground_station_id",
      row_ids_by_direction_and_ground_station(rows, "contact_id"),
      "must equal row-derived reservation_hold_contact_ids_by_direction_and_ground_station_id"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_contact_ids",
      summary_contact_ids(rows),
      "must equal row-derived review_contact_ids"
    )
  end

  defp list_or_empty(values) when is_list(values), do: values
  defp list_or_empty(_values), do: []

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp summary_expiration_count(rows) do
    Enum.count(rows, &(list_or_empty(Map.get(&1, "reservation_expires_at_s")) != []))
  end

  defp summary_earliest_expiration(rows) do
    rows
    |> Enum.flat_map(&list_or_empty(Map.get(&1, "reservation_expires_at_s")))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
  end

  defp summary_status_count(rows, status) do
    Enum.count(rows, &(&1["station_reservation_expiration_status"] == status))
  end

  defp summary_ids(rows) do
    rows
    |> Enum.flat_map(&list_or_empty(Map.get(&1, "reservation_ids")))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp summary_ids_by(rows, field) do
    rows
    |> Enum.flat_map(fn row ->
      reservation_id_value_pairs(Map.get(row, "reservation_ids"), List.wrap(Map.get(row, field)))
    end)
    |> reservation_id_pairs_to_map()
  end

  defp summary_ids_by_row_values(rows, field) do
    rows
    |> Enum.flat_map(fn row ->
      reservation_id_value_pairs(Map.get(row, "reservation_ids"), Map.get(row, field))
    end)
    |> reservation_id_pairs_to_map()
  end

  defp summary_ids_by_direction(rows) do
    rows
    |> Enum.flat_map(fn row ->
      reservation_id_value_pairs(
        Map.get(row, "reservation_ids"),
        station_reservation_row_directions(row)
      )
    end)
    |> reservation_id_pairs_to_map()
  end

  defp summary_ids_by_direction_and_ground_station(rows) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      put_nested_stable_ids(
        acc,
        station_reservation_row_directions(row),
        Map.get(row, "ground_station_id"),
        Map.get(row, "reservation_ids")
      )
    end)
  end

  defp summary_contact_ids(rows) do
    rows
    |> Enum.map(&Map.get(&1, "contact_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp summary_contact_ids_by(rows, field) do
    rows
    |> Enum.flat_map(fn row ->
      reservation_id_value_pairs(
        List.wrap(Map.get(row, "contact_id")),
        List.wrap(Map.get(row, field))
      )
    end)
    |> reservation_id_pairs_to_map()
  end

  defp station_reservation_row_directions(row) do
    [
      Map.get(row, "direction"),
      Map.get(row, "directions"),
      Map.get(row, "station_calendar_directions")
    ]
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp put_nested_stable_ids(acc, directions, group, ids) do
    ids = ids |> List.wrap() |> Enum.reject(&is_nil/1)

    if directions == [] or group in [nil, ""] or ids == [] do
      acc
    else
      Enum.reduce(directions, acc, fn direction, direction_acc ->
        Map.update(direction_acc, direction, %{group => ids |> Enum.uniq() |> Enum.sort()}, fn
          group_map ->
            Map.update(group_map, group, ids |> Enum.uniq() |> Enum.sort(), fn existing_ids ->
              (existing_ids ++ ids) |> Enum.uniq() |> Enum.sort()
            end)
        end)
      end)
    end
  end

  defp reservation_id_value_pairs(ids, values) do
    ids = List.wrap(ids) |> Enum.reject(&is_nil/1)
    values = List.wrap(values) |> Enum.reject(&is_nil/1)

    cond do
      ids == [] or values == [] ->
        []

      length(values) == 1 ->
        Enum.map(ids, &{List.first(values), &1})

      true ->
        Enum.zip(values, ids)
    end
  end

  defp reservation_id_pairs_to_map(pairs) do
    pairs
    |> Enum.group_by(fn {value, _id} -> to_string(value) end, fn {_value, id} -> id end)
    |> Enum.reject(fn {value, ids} -> value == "" or ids == [] end)
    |> Map.new(fn {value, ids} ->
      {
        value,
        ids
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()
      }
    end)
  end

  defp row_ids_by_direction(rows, id_field) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn row, acc ->
      direction = Map.get(row, "direction")
      id = Map.get(row, id_field)

      if direction in [nil, ""] or id in [nil, ""] do
        acc
      else
        Map.update(acc, direction, [id], fn ids -> [id | ids] end)
      end
    end)
    |> Map.new(fn {direction, ids} -> {direction, ids |> Enum.uniq() |> Enum.sort()} end)
  end

  defp row_ids_by_direction_and_ground_station(rows, id_field) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn row, acc ->
      direction = Map.get(row, "direction")
      ground_station_id = Map.get(row, "ground_station_id")
      id = Map.get(row, id_field)

      if direction in [nil, ""] or ground_station_id in [nil, ""] or id in [nil, ""] do
        acc
      else
        Map.update(acc, direction, %{ground_station_id => [id]}, fn station_map ->
          Map.update(station_map, ground_station_id, [id], fn ids -> [id | ids] end)
        end)
      end
    end)
    |> Map.new(fn {direction, station_map} ->
      {direction,
       Map.new(station_map, fn {ground_station_id, ids} ->
         {ground_station_id, ids |> Enum.uniq() |> Enum.sort()}
       end)}
    end)
  end
end
