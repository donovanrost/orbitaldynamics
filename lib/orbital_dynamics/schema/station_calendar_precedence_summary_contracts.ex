defmodule OrbitalDynamics.Schema.StationCalendarPrecedenceSummaryContracts do
  @moduledoc false

  def validate(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "station_calendar_precedence_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_station_calendar_precedence_summary"
    )
    |> expect_optional_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      station_calendar_report_model_limits(callbacks),
      "must match station calendar report model limits"
    )
    |> expect_one_of(callbacks, path, summary, "source_artifact_type", [
      "station_calendar_report.v1"
    ])
    |> expect_optional_type(callbacks, path, summary, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, summary, "affected_contact_count")
    |> expect_one_of(callbacks, path, summary, "precedence_review_status", [
      "clear",
      "review_required"
    ])
    |> expect_type(callbacks, path, summary, "applied_availability_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".applied_availability_counts",
      Map.get(summary, "applied_availability_counts")
    )
    |> expect_optional_type(callbacks, path, summary, "applied_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".applied_status_counts",
      Map.get(summary, "applied_status_counts")
    )
    |> expect_type(callbacks, path, summary, "overlap_availability_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".overlap_availability_counts",
      Map.get(summary, "overlap_availability_counts")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "affected_contact_ids_by_applied_availability",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".affected_contact_ids_by_applied_availability",
      Map.get(summary, "affected_contact_ids_by_applied_availability")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "affected_contact_ids_by_applied_status",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".affected_contact_ids_by_applied_status",
      Map.get(summary, "affected_contact_ids_by_applied_status")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "affected_contact_ids_by_overlap_availability",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".affected_contact_ids_by_overlap_availability",
      Map.get(summary, "affected_contact_ids_by_overlap_availability")
    )
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_contact_count"
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids",
      :list
    )
    |> validate_stable_id_list(
      callbacks,
      path <> ".reserved_under_higher_precedence_contact_ids",
      Map.get(summary, "reserved_under_higher_precedence_contact_ids")
    )
    |> expect_type(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids_by_applied_availability",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".reserved_under_higher_precedence_contact_ids_by_applied_availability",
      Map.get(summary, "reserved_under_higher_precedence_contact_ids_by_applied_availability")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids_by_applied_status",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".reserved_under_higher_precedence_contact_ids_by_applied_status",
      Map.get(summary, "reserved_under_higher_precedence_contact_ids_by_applied_status")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_reservation_ids",
      :list
    )
    |> validate_stable_id_list(
      callbacks,
      path <> ".reserved_under_higher_precedence_reservation_ids",
      Map.get(summary, "reserved_under_higher_precedence_reservation_ids")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_reservation_ids_by_status",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".reserved_under_higher_precedence_reservation_ids_by_status",
      Map.get(summary, "reserved_under_higher_precedence_reservation_ids_by_status")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_reservation_ids_by_reserved_by",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".reserved_under_higher_precedence_reservation_ids_by_reserved_by",
      Map.get(summary, "reserved_under_higher_precedence_reservation_ids_by_reserved_by")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids_by_reservation_status",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".reserved_under_higher_precedence_contact_ids_by_reservation_status",
      Map.get(summary, "reserved_under_higher_precedence_contact_ids_by_reservation_status")
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids_by_reserved_by",
      :map
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".reserved_under_higher_precedence_contact_ids_by_reserved_by",
      Map.get(summary, "reserved_under_higher_precedence_contact_ids_by_reserved_by")
    )
    |> expect_type(callbacks, path, summary, "unavailable_contact_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".unavailable_contact_ids",
      Map.get(summary, "unavailable_contact_ids")
    )
    |> expect_type(callbacks, path, summary, "reserved_overlap_contact_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".reserved_overlap_contact_ids",
      Map.get(summary, "reserved_overlap_contact_ids")
    )
    |> expect_type(callbacks, path, summary, "reduced_capacity_contact_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".reduced_capacity_contact_ids",
      Map.get(summary, "reduced_capacity_contact_ids")
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> validate_assumptions(callbacks, path, summary)
    |> validate_counts(callbacks, path, summary)
  end

  defp validate_assumptions(issues, callbacks, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        issues
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "execution_boundary",
          "artifact_only_no_provider_reservation"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "scope",
          "station_calendar_availability_precedence_review"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "operator_authority",
          "not_granted_by_summary"
        )

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, callbacks, path, summary) do
    applied_id_map = Map.get(summary, "affected_contact_ids_by_applied_availability")
    applied_status_id_map = Map.get(summary, "affected_contact_ids_by_applied_status")
    overlap_id_map = Map.get(summary, "affected_contact_ids_by_overlap_availability")

    reserved_under_higher_precedence_id_map =
      Map.get(summary, "reserved_under_higher_precedence_contact_ids_by_applied_availability")

    reserved_under_higher_precedence_status_id_map =
      Map.get(summary, "reserved_under_higher_precedence_contact_ids_by_applied_status")

    reserved_under_higher_precedence_reservation_ids_by_status =
      Map.get(summary, "reserved_under_higher_precedence_reservation_ids_by_status")

    reserved_under_higher_precedence_contact_ids_by_reservation_status =
      Map.get(summary, "reserved_under_higher_precedence_contact_ids_by_reservation_status")

    affected_contact_count = stable_id_array_map_value_count(callbacks, applied_id_map)

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "affected_contact_count",
      affected_contact_count,
      "must equal applied availability contact ID count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "precedence_review_status",
      station_calendar_precedence_review_status(affected_contact_count)
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "applied_availability_counts",
      id_array_count_map(callbacks, applied_id_map),
      "must equal contact IDs by applied availability"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "applied_status_counts",
      id_array_count_map(callbacks, applied_status_id_map),
      "must equal contact IDs by applied status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "overlap_availability_counts",
      id_array_count_map(callbacks, overlap_id_map),
      "must equal contact IDs by overlap availability"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_contact_count",
      length(list_or_empty(Map.get(summary, "reserved_under_higher_precedence_contact_ids"))),
      "must equal reserved-under-higher-precedence contact ID count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids",
      stable_id_array_map_ids(reserved_under_higher_precedence_id_map),
      "must equal reserved-under-higher-precedence IDs by applied availability"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids",
      stable_id_array_map_ids(reserved_under_higher_precedence_status_id_map),
      "must equal reserved-under-higher-precedence IDs by applied status"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_reservation_ids",
      stable_id_array_map_ids(reserved_under_higher_precedence_reservation_ids_by_status),
      "must equal reserved-under-higher-precedence reservation IDs by reservation status"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids",
      stable_id_array_map_ids(reserved_under_higher_precedence_contact_ids_by_reservation_status),
      "must equal reserved-under-higher-precedence contact IDs by reservation status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "unavailable_contact_ids",
      station_calendar_precedence_unavailable_ids(applied_id_map),
      "must equal unavailable or maintenance applied contact IDs"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "reserved_overlap_contact_ids",
      station_calendar_precedence_ids_by_availability(overlap_id_map, "reserved"),
      "must equal reserved overlap contact IDs"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "reduced_capacity_contact_ids",
      station_calendar_precedence_ids_by_availability(overlap_id_map, "reduced_capacity"),
      "must equal reduced-capacity overlap contact IDs"
    )
  end

  defp station_calendar_precedence_review_status(0), do: "clear"

  defp station_calendar_precedence_review_status(count) when is_integer(count) and count > 0,
    do: "review_required"

  defp station_calendar_precedence_review_status(_count), do: nil

  defp station_calendar_precedence_unavailable_ids(values) do
    if is_map(values) do
      (list_or_empty(Map.get(values, "unavailable")) ++
         list_or_empty(Map.get(values, "maintenance")))
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()
      |> Enum.sort()
    end
  end

  defp station_calendar_precedence_ids_by_availability(values, availability) do
    if is_map(values) do
      values
      |> Map.get(availability)
      |> list_or_empty()
      |> Enum.filter(&is_binary/1)
      |> Enum.uniq()
      |> Enum.sort()
    end
  end

  defp stable_id_array_map_ids(values) when is_map(values) do
    values
    |> Map.values()
    |> List.flatten()
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp stable_id_array_map_ids(_values), do: nil

  defp list_or_empty(values) when is_list(values), do: values
  defp list_or_empty(_values), do: []

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [issues, path, map, field])
  end

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals), [issues, path, map, field, expected])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp expect_optional_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_optional_field_equals), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_exact_model_limits(issues, callbacks, path, artifact, expected, message) do
    apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
      issues,
      path,
      artifact,
      expected,
      message
    ])
  end

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
      issues,
      path,
      counts
    ])
  end

  defp validate_stable_id_array_map(issues, callbacks, path, value),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, value])

  defp validate_stable_id_list(issues, callbacks, path, value),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, value])

  defp station_calendar_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :station_calendar_report_model_limits), [])

  defp stable_id_array_map_value_count(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :stable_id_array_map_value_count), [values])

  defp id_array_count_map(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :id_array_count_map), [values])
end
