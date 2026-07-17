defmodule OrbitalDynamics.Schema.LinkCapacitySummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.LinkCapacityReportContracts

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_numeric_map: 3]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_number_list_items: 4,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3,
      validate_stable_id_list: 3
    ]

  def validate_summary(issues, path, summary) do
    issues
    |> expect_equal(path, summary, "schema_contract", "link_capacity_summary.v1")
    |> expect_equal(path, summary, "model", "artifact_only_link_capacity_summary")
    |> expect_equal(path, summary, "source_artifact_type", "link_capacity_report.v1")
    |> expect_type(path, summary, "source", :binary)
    |> expect_optional_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      model_limits(),
      "must match link capacity capability model limits"
    )
    |> validate_field_types(path, summary)
    |> expect_type(path, summary, "assumptions", :map)
    |> LinkCapacityReportContracts.validate_assumptions(path, summary)
    |> validate_summary_assumptions(path, summary)
    |> validate_counts(path, summary)
  end

  defp validate_field_types(issues, path, summary) do
    issues =
      Enum.reduce(count_fields(), issues, fn field, acc ->
        expect_non_negative_integer(acc, path, summary, field)
      end)

    issues =
      Enum.reduce(number_fields(), issues, fn field, acc ->
        expect_number(acc, path, summary, field)
      end)

    issues =
      Enum.reduce(count_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(path, summary, field, :map)
        |> validate_non_negative_integer_count_map(
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end)

    issues =
      Enum.reduce(numeric_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(path, summary, field, :map)
        |> validate_numeric_map(path <> ".#{field}", Map.get(summary, field))
      end)

    issues =
      Enum.reduce(stable_id_list_fields(), issues, fn field, acc ->
        acc
        |> expect_type(path, summary, field, :list)
        |> validate_stable_id_list(path <> ".#{field}", Map.get(summary, field))
      end)

    issues =
      Enum.reduce(string_list_fields(), issues, fn field, acc ->
        acc
        |> expect_type(path, summary, field, :list)
        |> validate_string_list_items(path, summary, field)
      end)

    issues =
      Enum.reduce(optional_stable_id_list_fields(), issues, fn field, acc ->
        acc
        |> expect_optional_type(path, summary, field, :list)
        |> validate_optional_stable_id_list(path, summary, field)
      end)

    issues =
      Enum.reduce(stable_id_array_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(path, summary, field, :map)
        |> validate_stable_id_array_map(path <> ".#{field}", Map.get(summary, field))
      end)

    issues =
      Enum.reduce(optional_status_fields(), issues, fn field, acc ->
        expect_optional_type(acc, path, summary, field, :binary)
      end)

    issues
    |> expect_type(path, summary, "station_reservation_expires_at_s", :list)
    |> validate_number_list_items(path, summary, "station_reservation_expires_at_s")
  end

  defp count_fields do
    [
      "station_count",
      "contact_count",
      "effective_contact_count",
      "ignored_contact_count",
      "selected_contact_count",
      "ignored_selected_contact_count",
      "required_downlink_contact_count",
      "actual_throughput_contact_count",
      "actual_completion_contact_count",
      "unmatched_actual_throughput_contact_count",
      "ambiguous_actual_throughput_contact_count",
      "unmatched_actual_completion_contact_count",
      "ambiguous_actual_completion_contact_count",
      "invalid_contact_input_count",
      "invalid_selected_contact_input_count",
      "invalid_policy_required_downlink_station_count"
    ]
  end

  defp number_fields do
    [
      "selected_downlink_shortfall_mb",
      "actual_downlink_shortfall_mb",
      "capacity_adjusted_throughput_mb",
      "selected_capacity_adjusted_throughput_mb",
      "unused_capacity_adjusted_throughput_mb"
    ]
  end

  defp count_map_fields do
    [
      "ignored_contact_reason_counts",
      "ignored_selected_contact_reason_counts",
      "station_reservation_match_status_counts"
    ]
  end

  defp numeric_map_fields do
    [
      "selected_downlink_shortfall_mb_by_ground_station_id",
      "actual_downlink_shortfall_mb_by_ground_station_id",
      "capacity_adjusted_throughput_mb_by_ground_station_id",
      "selected_capacity_adjusted_throughput_mb_by_ground_station_id",
      "unused_capacity_adjusted_throughput_mb_by_ground_station_id"
    ]
  end

  defp stable_id_list_fields do
    [
      "station_reservation_ids",
      "contact_ids",
      "selected_contact_ids",
      "ignored_contact_ids",
      "ignored_selected_contact_ids",
      "required_downlink_contact_ids",
      "actual_throughput_contact_ids",
      "actual_completion_contact_ids",
      "unmatched_actual_throughput_contact_ids",
      "ambiguous_actual_throughput_contact_ids",
      "unmatched_actual_completion_contact_ids",
      "ambiguous_actual_completion_contact_ids",
      "ambiguous_selected_contact_ids",
      "unmatched_selected_contact_ids",
      "invalid_contact_input_ids",
      "invalid_selected_contact_input_ids",
      "ground_station_ids",
      "shortfall_ground_station_ids",
      "actual_shortfall_ground_station_ids"
    ]
  end

  defp string_list_fields do
    [
      "station_reserved_bys",
      "station_reservation_statuses",
      "invalid_policy_required_downlink_station_ids"
    ]
  end

  defp optional_stable_id_list_fields do
    [
      "station_calendar_entry_ids",
      "station_calendar_provider_ids",
      "station_calendar_provider_entry_ids"
    ]
  end

  defp stable_id_array_map_fields do
    [
      "ground_station_ids_by_station_availability",
      "ground_station_ids_by_reservation_match_status",
      "ground_station_ids_by_reservation_status",
      "ground_station_ids_by_reserved_by",
      "station_calendar_entry_ids_by_ground_station_id",
      "station_calendar_provider_ids_by_ground_station_id",
      "station_calendar_provider_entry_ids_by_ground_station_id",
      "station_reservation_ids_by_ground_station_id",
      "ignored_contact_ids_by_ground_station_id",
      "selected_contact_ids_by_ground_station_id",
      "required_downlink_contact_ids_by_ground_station_id",
      "actual_throughput_contact_ids_by_ground_station_id",
      "actual_completion_contact_ids_by_ground_station_id",
      "unmatched_actual_throughput_contact_ids_by_ground_station_id",
      "ambiguous_actual_throughput_contact_ids_by_ground_station_id",
      "unmatched_actual_completion_contact_ids_by_ground_station_id",
      "ambiguous_actual_completion_contact_ids_by_ground_station_id"
    ]
  end

  defp optional_status_fields do
    [
      "downlink_requirement_status",
      "actual_downlink_requirement_status",
      "selection_utilization_status"
    ]
  end

  defp validate_summary_assumptions(issues, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
        issues
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "execution_boundary",
          "artifact_only_no_provider_reservation_or_schedule_mutation"
        )
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "source",
          "link_capacity_report.v1"
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
    issues
    |> expect_field_equals(
      path,
      summary,
      "station_count",
      list_count(summary, "ground_station_ids"),
      "must equal ground_station_ids count"
    )
    |> expect_field_equals(
      path,
      summary,
      "ground_station_ids",
      sorted_map_keys(Map.get(summary, "capacity_adjusted_throughput_mb_by_ground_station_id")),
      "must equal capacity_adjusted_throughput_mb_by_ground_station_id keys"
    )
    |> validate_list_count_consistency(path, summary)
    |> validate_numeric_total_consistency(path, summary)
    |> validate_station_calendar_id_consistency(path, summary)
  end

  defp validate_list_count_consistency(issues, path, summary) do
    Enum.reduce(
      [
        {"contact_count", "contact_ids", "must equal contact_ids count"},
        {"selected_contact_count", "selected_contact_ids",
         "must equal selected_contact_ids count"},
        {"ignored_contact_count", "ignored_contact_ids", "must equal ignored_contact_ids count"},
        {"ignored_selected_contact_count", "ignored_selected_contact_ids",
         "must equal ignored_selected_contact_ids count"},
        {"required_downlink_contact_count", "required_downlink_contact_ids",
         "must equal required_downlink_contact_ids count"},
        {"actual_throughput_contact_count", "actual_throughput_contact_ids",
         "must equal actual_throughput_contact_ids count"},
        {"actual_completion_contact_count", "actual_completion_contact_ids",
         "must equal actual_completion_contact_ids count"},
        {"unmatched_actual_throughput_contact_count", "unmatched_actual_throughput_contact_ids",
         "must equal unmatched_actual_throughput_contact_ids count"},
        {"ambiguous_actual_throughput_contact_count", "ambiguous_actual_throughput_contact_ids",
         "must equal ambiguous_actual_throughput_contact_ids count"},
        {"unmatched_actual_completion_contact_count", "unmatched_actual_completion_contact_ids",
         "must equal unmatched_actual_completion_contact_ids count"},
        {"ambiguous_actual_completion_contact_count", "ambiguous_actual_completion_contact_ids",
         "must equal ambiguous_actual_completion_contact_ids count"},
        {"invalid_contact_input_count", "invalid_contact_input_ids",
         "must equal invalid_contact_input_ids count"},
        {"invalid_selected_contact_input_count", "invalid_selected_contact_input_ids",
         "must equal invalid_selected_contact_input_ids count"},
        {"invalid_policy_required_downlink_station_count",
         "invalid_policy_required_downlink_station_ids",
         "must equal invalid_policy_required_downlink_station_ids count"}
      ],
      issues,
      fn {count_field, list_field, message}, acc ->
        expect_field_equals(
          acc,
          path,
          summary,
          count_field,
          list_count(summary, list_field),
          message
        )
      end
    )
  end

  defp validate_numeric_total_consistency(issues, path, summary) do
    Enum.reduce(
      [
        {"selected_downlink_shortfall_mb", "selected_downlink_shortfall_mb_by_ground_station_id",
         "must equal selected_downlink_shortfall_mb_by_ground_station_id total"},
        {"actual_downlink_shortfall_mb", "actual_downlink_shortfall_mb_by_ground_station_id",
         "must equal actual_downlink_shortfall_mb_by_ground_station_id total"},
        {"capacity_adjusted_throughput_mb",
         "capacity_adjusted_throughput_mb_by_ground_station_id",
         "must equal capacity_adjusted_throughput_mb_by_ground_station_id total"},
        {"selected_capacity_adjusted_throughput_mb",
         "selected_capacity_adjusted_throughput_mb_by_ground_station_id",
         "must equal selected_capacity_adjusted_throughput_mb_by_ground_station_id total"},
        {"unused_capacity_adjusted_throughput_mb",
         "unused_capacity_adjusted_throughput_mb_by_ground_station_id",
         "must equal unused_capacity_adjusted_throughput_mb_by_ground_station_id total"}
      ],
      issues,
      fn {field, map_field, message}, acc ->
        expect_field_equals(
          acc,
          path,
          summary,
          field,
          numeric_map_sum(Map.get(summary, map_field)),
          message
        )
      end
    )
  end

  defp validate_station_calendar_id_consistency(issues, path, summary) do
    Enum.reduce(
      [
        {"station_calendar_entry_ids", "station_calendar_entry_ids_by_ground_station_id",
         "must equal station_calendar_entry_ids_by_ground_station_id values"},
        {"station_calendar_provider_ids", "station_calendar_provider_ids_by_ground_station_id",
         "must equal station_calendar_provider_ids_by_ground_station_id values"},
        {"station_calendar_provider_entry_ids",
         "station_calendar_provider_entry_ids_by_ground_station_id",
         "must equal station_calendar_provider_entry_ids_by_ground_station_id values"},
        {"station_reservation_ids", "station_reservation_ids_by_ground_station_id",
         "must equal station_reservation_ids_by_ground_station_id values"}
      ],
      issues,
      fn {field, map_field, message}, acc ->
        expect_field_equals(
          acc,
          path,
          summary,
          field,
          sorted_stable_id_array_map_values(Map.get(summary, map_field)),
          message
        )
      end
    )
  end

  defp list_count(map, field) do
    case Map.get(map, field) do
      values when is_list(values) -> length(values)
      _values -> nil
    end
  end

  defp numeric_map_sum(values) when is_map(values) do
    values = Map.values(values)

    if Enum.all?(values, &is_number/1),
      do: Enum.sum(values),
      else: nil
  end

  defp numeric_map_sum(_values), do: nil

  defp sorted_map_keys(values) when is_map(values) do
    values
    |> Map.keys()
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp sorted_map_keys(_values), do: nil

  defp sorted_stable_id_array_map_values(values) when is_map(values) do
    values
    |> Map.values()
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp sorted_stable_id_array_map_values(_values), do: nil

  def model_limits do
    OrbitalDynamics.Communications.LinkCapacity.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
