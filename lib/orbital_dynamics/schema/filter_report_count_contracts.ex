defmodule OrbitalDynamics.Schema.FilterReportCountContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.CollectionAggregation

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [error: 2, expect_field_equals: 6, validate_non_negative_integer_count_map: 3]

  def validate_counts(issues, path, report, kind) do
    rows =
      report
      |> Map.get("suppressed_candidates", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(path, report, "suppressed_candidate_count", length(rows))
    |> expect_field_equals(
      path,
      report,
      "kept_candidate_count",
      row_count_difference(report, "input_candidate_count", length(rows))
    )
    |> validate_invalid_inputs(path, report, rows, kind)
    |> validate_duplicate_rows(path, report, rows)
    |> validate_count_maps(path, report, rows, kind)
  end

  defp validate_invalid_inputs(issues, path, report, rows, "contact") do
    invalid_ids =
      rows
      |> Enum.filter(
        &(Map.get(&1, "invalid_contact_shape") == true or
            Map.get(&1, "invalid_contact_input") == true)
      )
      |> Enum.map(&Map.get(&1, "id"))

    issues
    |> expect_field_equals(
      path,
      report,
      "invalid_contact_input_count",
      length(invalid_ids)
    )
    |> validate_ids_match_row_multiset(
      path,
      report,
      "invalid_contact_input_ids",
      invalid_ids,
      "must equal row-derived invalid_contact_input_ids"
    )
  end

  defp validate_invalid_inputs(issues, path, report, rows, "resource") do
    invalid_summary_rows =
      report
      |> Map.get("invalid_resource_summary_inputs", [])
      |> case do
        values when is_list(values) -> Enum.filter(values, &is_map/1)
        _values -> []
      end

    invalid_candidate_ids =
      rows
      |> Enum.filter(
        &(Map.get(&1, "invalid_candidate_input") == true or
            Map.get(&1, "invalid_candidate_shape") == true)
      )
      |> Enum.map(&Map.get(&1, "id"))
      |> Enum.sort()

    issues
    |> expect_field_equals(
      path,
      report,
      "invalid_candidate_input_count",
      length(invalid_candidate_ids)
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_candidate_input_ids",
      invalid_candidate_ids,
      "must equal row-derived invalid_candidate_input_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_resource_summary_input_count",
      length(invalid_summary_rows)
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_resource_summary_input_ids",
      Enum.map(invalid_summary_rows, &Map.get(&1, "resource_summary_id")),
      "must equal row-derived invalid_resource_summary_input_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "valid_resource_summary_count",
      row_count_difference(report, "input_resource_summary_count", length(invalid_summary_rows))
    )
    |> expect_field_equals(
      path,
      report,
      "input_resource_summary_count",
      resource_filter_input_summary_count(report, length(invalid_summary_rows))
    )
  end

  defp resource_filter_input_summary_count(report, invalid_summary_count) do
    case Map.get(report, "valid_resource_summary_count") do
      value when is_integer(value) -> value + invalid_summary_count
      _value -> nil
    end
  end

  defp validate_count_maps(issues, path, report, rows, "contact") do
    issues
    |> validate_non_negative_integer_count_map(
      "#{path}.suppression_reason_counts",
      Map.get(report, "suppression_reason_counts")
    )
    |> validate_non_negative_integer_count_map(
      "#{path}.station_calendar_trust_boundary_status_counts",
      Map.get(report, "station_calendar_trust_boundary_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      "#{path}.station_reservation_match_status_counts",
      Map.get(report, "station_reservation_match_status_counts")
    )
    |> expect_field_equals(
      path,
      report,
      "station_calendar_trust_boundary_status_counts",
      frequency_map(rows, "station_calendar_trust_boundary_status"),
      "must equal row-derived station_calendar_trust_boundary_status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "suppression_reason_counts",
      frequency_map(rows, "suppressed_reason"),
      "must equal row-derived suppression_reason_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "suppressed_candidate_ids_by_reason",
      row_ids_by_field(rows, "suppressed_reason", "id"),
      "must equal row-derived suppressed_candidate_ids_by_reason"
    )
    |> expect_field_equals(
      path,
      report,
      "suppressed_candidate_ids_by_station_calendar_trust_boundary_status",
      row_ids_by_field(rows, "station_calendar_trust_boundary_status", "id"),
      "must equal row-derived suppressed_candidate_ids_by_station_calendar_trust_boundary_status"
    )
    |> expect_field_equals(
      path,
      report,
      "station_reservation_match_status_counts",
      frequency_map(rows, "station_reservation_match_status"),
      "must equal row-derived station_reservation_match_status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "suppressed_candidate_ids_by_reservation_match_status",
      row_ids_by_field(rows, "station_reservation_match_status", "id"),
      "must equal row-derived suppressed_candidate_ids_by_reservation_match_status"
    )
  end

  defp validate_count_maps(issues, path, report, rows, "resource") do
    issues
    |> validate_non_negative_integer_count_map(
      "#{path}.resource_source_quality_counts",
      Map.get(report, "resource_source_quality_counts")
    )
    |> validate_non_negative_integer_count_map(
      "#{path}.resource_trust_boundary_status_counts",
      Map.get(report, "resource_trust_boundary_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      "#{path}.suppressed_resource_source_quality_counts",
      Map.get(report, "suppressed_resource_source_quality_counts")
    )
    |> validate_non_negative_integer_count_map(
      "#{path}.suppressed_resource_trust_boundary_status_counts",
      Map.get(report, "suppressed_resource_trust_boundary_status_counts")
    )
    |> expect_field_equals(
      path,
      report,
      "suppressed_resource_source_quality_counts",
      frequency_map(rows, "resource_source_quality"),
      "must equal row-derived suppressed_resource_source_quality_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "suppressed_candidate_ids_by_resource_source_quality",
      row_ids_by_field(rows, "resource_source_quality", "id"),
      "must equal row-derived suppressed_candidate_ids_by_resource_source_quality"
    )
    |> expect_field_equals(
      path,
      report,
      "suppressed_resource_trust_boundary_status_counts",
      frequency_map(rows, "resource_trust_boundary_status"),
      "must equal row-derived suppressed_resource_trust_boundary_status_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "suppressed_candidate_ids_by_resource_trust_boundary_status",
      row_ids_by_field(rows, "resource_trust_boundary_status", "id"),
      "must equal row-derived suppressed_candidate_ids_by_resource_trust_boundary_status"
    )
  end

  defp validate_duplicate_rows(issues, path, report, rows) do
    duplicate_rows =
      Enum.filter(rows, &(Map.get(&1, "duplicate_suppressed_candidate_id_collision") == true))

    issues =
      issues
      |> expect_field_equals(
        path,
        report,
        "duplicate_suppressed_candidate_row_count",
        length(duplicate_rows)
      )
      |> expect_field_equals(
        path,
        report,
        "duplicate_suppressed_candidate_id_count",
        duplicate_rows
        |> Enum.map(&Map.get(&1, "base_candidate_id"))
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> length()
      )

    duplicate_rows
    |> Enum.group_by(&Map.get(&1, "base_candidate_id"))
    |> Enum.reduce(issues, fn {_base_id, group}, acc ->
      count = length(group)

      indexes =
        group |> Enum.map(&Map.get(&1, "duplicate_suppressed_candidate_index")) |> Enum.sort()

      expected_indexes = Enum.to_list(1..count)

      acc =
        group
        |> Enum.reduce(acc, fn row, row_acc ->
          row_index = Enum.find_index(rows, &(&1 == row)) || 0

          row_acc
          |> expect_field_equals(
            "#{path}.suppressed_candidates[#{row_index}]",
            row,
            "duplicate_suppressed_candidate_count",
            count
          )
        end)

      if indexes == expected_indexes do
        acc
      else
        [
          error(
            "#{path}.suppressed_candidates",
            "duplicate_suppressed_candidate_index values must cover 1..#{count}"
          )
          | acc
        ]
      end
    end)
  end

  defp validate_ids_match_row_multiset(
         issues,
         path,
         report,
         field,
         expected_ids,
         message
       ) do
    ids = Map.get(report, field)

    if is_list(ids) and Enum.sort(ids) != Enum.sort(expected_ids) do
      [error("#{path}.#{field}", message) | issues]
    else
      issues
    end
  end

  defp row_count_difference(report, field, subtract),
    do: CollectionAggregation.row_count_difference(report, field, subtract)

  defp row_ids_by_field(rows, group_field, id_field),
    do: CollectionAggregation.row_ids_by_field(rows, group_field, id_field)

  defp frequency_map(rows, field),
    do: CollectionAggregation.frequency_map(rows, field)

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
