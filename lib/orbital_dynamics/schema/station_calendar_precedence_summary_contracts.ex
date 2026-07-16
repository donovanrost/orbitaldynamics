defmodule OrbitalDynamics.Schema.StationCalendarPrecedenceSummaryContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionAggregation,
    only: [id_array_count_map: 1, stable_id_array_map_value_count: 1]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_field_equals: 6,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_array_map: 3, validate_stable_id_list: 3]

  def validate(issues, path, summary, model_limits) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "station_calendar_precedence_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_station_calendar_precedence_summary"
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
      "station_calendar_report.v1"
    ])
    |> expect_optional_type(path, summary, "source", :binary)
    |> expect_non_negative_integer(path, summary, "affected_contact_count")
    |> expect_one_of(path, summary, "precedence_review_status", [
      "clear",
      "review_required"
    ])
    |> expect_type(path, summary, "applied_availability_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".applied_availability_counts",
      Map.get(summary, "applied_availability_counts")
    )
    |> expect_optional_type(path, summary, "applied_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".applied_status_counts",
      Map.get(summary, "applied_status_counts")
    )
    |> expect_type(path, summary, "overlap_availability_counts", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".overlap_availability_counts",
      Map.get(summary, "overlap_availability_counts")
    )
    |> expect_type(
      path,
      summary,
      "affected_contact_ids_by_applied_availability",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".affected_contact_ids_by_applied_availability",
      Map.get(summary, "affected_contact_ids_by_applied_availability")
    )
    |> expect_optional_type(
      path,
      summary,
      "affected_contact_ids_by_applied_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".affected_contact_ids_by_applied_status",
      Map.get(summary, "affected_contact_ids_by_applied_status")
    )
    |> expect_type(
      path,
      summary,
      "affected_contact_ids_by_overlap_availability",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".affected_contact_ids_by_overlap_availability",
      Map.get(summary, "affected_contact_ids_by_overlap_availability")
    )
    |> expect_non_negative_integer(
      path,
      summary,
      "reserved_under_higher_precedence_contact_count"
    )
    |> expect_type(
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids",
      :list
    )
    |> validate_stable_id_list(
      path <> ".reserved_under_higher_precedence_contact_ids",
      Map.get(summary, "reserved_under_higher_precedence_contact_ids")
    )
    |> expect_type(
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids_by_applied_availability",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".reserved_under_higher_precedence_contact_ids_by_applied_availability",
      Map.get(summary, "reserved_under_higher_precedence_contact_ids_by_applied_availability")
    )
    |> expect_optional_type(
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids_by_applied_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".reserved_under_higher_precedence_contact_ids_by_applied_status",
      Map.get(summary, "reserved_under_higher_precedence_contact_ids_by_applied_status")
    )
    |> expect_optional_type(
      path,
      summary,
      "reserved_under_higher_precedence_reservation_ids",
      :list
    )
    |> validate_stable_id_list(
      path <> ".reserved_under_higher_precedence_reservation_ids",
      Map.get(summary, "reserved_under_higher_precedence_reservation_ids")
    )
    |> expect_optional_type(
      path,
      summary,
      "reserved_under_higher_precedence_reservation_ids_by_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".reserved_under_higher_precedence_reservation_ids_by_status",
      Map.get(summary, "reserved_under_higher_precedence_reservation_ids_by_status")
    )
    |> expect_optional_type(
      path,
      summary,
      "reserved_under_higher_precedence_reservation_ids_by_reserved_by",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".reserved_under_higher_precedence_reservation_ids_by_reserved_by",
      Map.get(summary, "reserved_under_higher_precedence_reservation_ids_by_reserved_by")
    )
    |> expect_optional_type(
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids_by_reservation_status",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".reserved_under_higher_precedence_contact_ids_by_reservation_status",
      Map.get(summary, "reserved_under_higher_precedence_contact_ids_by_reservation_status")
    )
    |> expect_optional_type(
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids_by_reserved_by",
      :map
    )
    |> validate_stable_id_array_map(
      path <> ".reserved_under_higher_precedence_contact_ids_by_reserved_by",
      Map.get(summary, "reserved_under_higher_precedence_contact_ids_by_reserved_by")
    )
    |> expect_type(path, summary, "unavailable_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".unavailable_contact_ids",
      Map.get(summary, "unavailable_contact_ids")
    )
    |> expect_type(path, summary, "reserved_overlap_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".reserved_overlap_contact_ids",
      Map.get(summary, "reserved_overlap_contact_ids")
    )
    |> expect_type(path, summary, "reduced_capacity_contact_ids", :list)
    |> validate_stable_id_list(
      path <> ".reduced_capacity_contact_ids",
      Map.get(summary, "reduced_capacity_contact_ids")
    )
    |> expect_type(path, summary, "assumptions", :map)
    |> validate_assumptions(path, summary)
    |> validate_counts(path, summary)
  end

  defp validate_assumptions(issues, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        issues
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "execution_boundary",
          "artifact_only_no_provider_reservation"
        )
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "scope",
          "station_calendar_availability_precedence_review"
        )
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "operator_authority",
          "not_granted_by_summary"
        )

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, path, summary) do
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

    affected_contact_count = stable_id_array_map_value_count(applied_id_map)

    issues
    |> expect_field_equals(
      path,
      summary,
      "affected_contact_count",
      affected_contact_count,
      "must equal applied availability contact ID count"
    )
    |> expect_field_equals(
      path,
      summary,
      "precedence_review_status",
      station_calendar_precedence_review_status(affected_contact_count)
    )
    |> expect_field_equals(
      path,
      summary,
      "applied_availability_counts",
      id_array_count_map(applied_id_map),
      "must equal contact IDs by applied availability"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "applied_status_counts",
      id_array_count_map(applied_status_id_map),
      "must equal contact IDs by applied status"
    )
    |> expect_field_equals(
      path,
      summary,
      "overlap_availability_counts",
      id_array_count_map(overlap_id_map),
      "must equal contact IDs by overlap availability"
    )
    |> expect_field_equals(
      path,
      summary,
      "reserved_under_higher_precedence_contact_count",
      length(list_or_empty(Map.get(summary, "reserved_under_higher_precedence_contact_ids"))),
      "must equal reserved-under-higher-precedence contact ID count"
    )
    |> expect_field_equals(
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids",
      stable_id_array_map_ids(reserved_under_higher_precedence_id_map),
      "must equal reserved-under-higher-precedence IDs by applied availability"
    )
    |> expect_field_equals(
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids",
      stable_id_array_map_ids(reserved_under_higher_precedence_status_id_map),
      "must equal reserved-under-higher-precedence IDs by applied status"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "reserved_under_higher_precedence_reservation_ids",
      stable_id_array_map_ids(reserved_under_higher_precedence_reservation_ids_by_status),
      "must equal reserved-under-higher-precedence reservation IDs by reservation status"
    )
    |> expect_optional_field_equals(
      path,
      summary,
      "reserved_under_higher_precedence_contact_ids",
      stable_id_array_map_ids(reserved_under_higher_precedence_contact_ids_by_reservation_status),
      "must equal reserved-under-higher-precedence contact IDs by reservation status"
    )
    |> expect_field_equals(
      path,
      summary,
      "unavailable_contact_ids",
      station_calendar_precedence_unavailable_ids(applied_id_map),
      "must equal unavailable or maintenance applied contact IDs"
    )
    |> expect_field_equals(
      path,
      summary,
      "reserved_overlap_contact_ids",
      station_calendar_precedence_ids_by_availability(overlap_id_map, "reserved"),
      "must equal reserved overlap contact IDs"
    )
    |> expect_field_equals(
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

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
