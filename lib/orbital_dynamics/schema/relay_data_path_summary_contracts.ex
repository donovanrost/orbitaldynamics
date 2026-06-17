defmodule OrbitalDynamics.Schema.RelayDataPathSummaryContracts do
  @moduledoc false

  def validate_summary(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, summary, "schema_contract", "relay_data_path_summary.v1")
    |> expect_equal(callbacks, path, summary, "schema_version", 1)
    |> expect_equal(callbacks, path, summary, "model", "artifact_only_relay_data_path_summary")
    |> expect_type(callbacks, path, summary, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, summary, "route_count")
    |> expect_non_negative_integer(callbacks, path, summary, "relay_route_count")
    |> expect_non_negative_integer(callbacks, path, summary, "direct_downlink_route_count")
    |> validate_field_types(callbacks, path, summary)
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> validate_assumptions(callbacks, path, summary)
    |> expect_type(callbacks, path, summary, "rows", :list)
    |> validate_rows(callbacks, path <> ".rows", Map.get(summary, "rows", []), &validate_row/4)
    |> validate_counts(callbacks, path, summary)
  end

  defp validate_field_types(issues, callbacks, path, summary) do
    issues =
      Enum.reduce(count_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, summary, field, :map)
        |> validate_non_negative_integer_count_map(
          callbacks,
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end)

    issues =
      Enum.reduce(stable_id_list_fields(), issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, summary, field, :list)
        |> validate_stable_id_list(callbacks, path <> ".#{field}", Map.get(summary, field))
      end)

    issues =
      Enum.reduce(stable_id_array_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, summary, field, :map)
        |> validate_stable_id_array_map(callbacks, path <> ".#{field}", Map.get(summary, field))
      end)

    issues
    |> expect_optional_number(callbacks, path, summary, "maximum_latency_s")
    |> expect_optional_number(callbacks, path, summary, "maximum_latency_limit_s")
    |> expect_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      relay_data_path_model_limits(callbacks),
      "must match relay data-path capability model limits"
    )
  end

  defp count_map_fields do
    [
      "custody_status_counts",
      "latency_status_counts",
      "risk_status_counts"
    ]
  end

  defp stable_id_list_fields do
    [
      "route_ids",
      "source_spacecraft_ids",
      "relay_spacecraft_ids",
      "ground_station_ids",
      "ground_downlink_contact_ids"
    ]
  end

  defp stable_id_array_map_fields do
    [
      "route_ids_by_custody_status",
      "route_ids_by_latency_status",
      "route_ids_by_risk_status",
      "route_ids_by_ground_station_id"
    ]
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
          "artifact_only_no_relay_scheduling_or_schedule_mutation"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "crosslink_visibility_model",
          "not_evaluated"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "custody_acknowledgement_delivery",
          "not_performed"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "provider_reservation",
          "not_performed"
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

  defp validate_row(issues, callbacks, path, row) do
    issues
    |> require_fields(callbacks, path, row, [
      "route_id",
      "source_spacecraft_id",
      "relay_chain_spacecraft_ids",
      "relay_hop_count",
      "ground_station_id",
      "ground_downlink_contact_id",
      "custody_status",
      "latency_status",
      "risk_status",
      "risk_reasons",
      "product_ids",
      "collection_ids"
    ])
    |> validate_stable_ids(callbacks, path, row, [
      "route_id",
      "source_spacecraft_id",
      "ground_station_id",
      "ground_downlink_contact_id"
    ])
    |> expect_non_negative_integer(callbacks, path, row, "relay_hop_count")
    |> expect_optional_number(callbacks, path, row, "latency_s")
    |> expect_optional_number(callbacks, path, row, "latency_limit_s")
    |> expect_one_of(callbacks, path, row, "custody_status", relay_custody_statuses())
    |> expect_one_of(callbacks, path, row, "latency_status", relay_latency_statuses())
    |> expect_one_of(callbacks, path, row, "risk_status", relay_risk_statuses())
    |> expect_type(callbacks, path, row, "relay_chain_spacecraft_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".relay_chain_spacecraft_ids",
      Map.get(row, "relay_chain_spacecraft_ids")
    )
    |> expect_type(callbacks, path, row, "risk_reasons", :list)
    |> validate_string_list_items(callbacks, path, row, "risk_reasons")
    |> expect_type(callbacks, path, row, "product_ids", :list)
    |> validate_stable_id_list(callbacks, path <> ".product_ids", Map.get(row, "product_ids"))
    |> expect_type(callbacks, path, row, "collection_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".collection_ids",
      Map.get(row, "collection_ids")
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "relay_hop_count",
      list_count(row, "relay_chain_spacecraft_ids"),
      "must equal relay_chain_spacecraft_ids count"
    )
  end

  defp validate_counts(issues, callbacks, path, summary) do
    rows =
      summary
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(callbacks, path, summary, "route_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "relay_route_count",
      Enum.count(rows, &(Map.get(&1, "relay_hop_count", 0) > 0)),
      "must equal rows with relay_hop_count greater than zero"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "direct_downlink_route_count",
      Enum.count(rows, &(Map.get(&1, "relay_hop_count", 0) == 0)),
      "must equal rows with relay_hop_count equal to zero"
    )
    |> validate_status_counts(callbacks, path, summary, rows)
    |> validate_stable_id_derived_fields(callbacks, path, summary, rows)
    |> validate_route_id_maps(callbacks, path, summary, rows)
    |> validate_latency_maximums(callbacks, path, summary, rows)
  end

  defp validate_status_counts(issues, callbacks, path, summary, rows) do
    Enum.reduce(
      [
        {"custody_status_counts", "custody_status",
         "must equal row-derived custody_status_counts"},
        {"latency_status_counts", "latency_status",
         "must equal row-derived latency_status_counts"},
        {"risk_status_counts", "risk_status", "must equal row-derived risk_status_counts"}
      ],
      issues,
      fn {summary_field, row_field, message}, acc ->
        expect_field_equals(
          acc,
          callbacks,
          path,
          summary,
          summary_field,
          frequency_map(rows, row_field),
          message
        )
      end
    )
  end

  defp validate_stable_id_derived_fields(issues, callbacks, path, summary, rows) do
    Enum.reduce(
      [
        {"route_ids", "route_id", "must equal row-derived route_ids"},
        {"source_spacecraft_ids", "source_spacecraft_id",
         "must equal row-derived source_spacecraft_ids"},
        {"relay_spacecraft_ids", "relay_chain_spacecraft_ids",
         "must equal row-derived relay_spacecraft_ids"},
        {"ground_station_ids", "ground_station_id", "must equal row-derived ground_station_ids"},
        {"ground_downlink_contact_ids", "ground_downlink_contact_id",
         "must equal row-derived ground_downlink_contact_ids"}
      ],
      issues,
      fn {summary_field, row_field, message}, acc ->
        expect_field_equals(
          acc,
          callbacks,
          path,
          summary,
          summary_field,
          row_stable_ids(rows, row_field),
          message
        )
      end
    )
  end

  defp validate_route_id_maps(issues, callbacks, path, summary, rows) do
    Enum.reduce(
      [
        {"route_ids_by_custody_status", "custody_status",
         "must equal row-derived route_ids_by_custody_status"},
        {"route_ids_by_latency_status", "latency_status",
         "must equal row-derived route_ids_by_latency_status"},
        {"route_ids_by_risk_status", "risk_status",
         "must equal row-derived route_ids_by_risk_status"},
        {"route_ids_by_ground_station_id", "ground_station_id",
         "must equal row-derived route_ids_by_ground_station_id"}
      ],
      issues,
      fn {summary_field, row_field, message}, acc ->
        expect_field_equals(
          acc,
          callbacks,
          path,
          summary,
          summary_field,
          route_ids_by_field(rows, row_field),
          message
        )
      end
    )
  end

  defp validate_latency_maximums(issues, callbacks, path, summary, rows) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "maximum_latency_s",
      maximum_number(rows, "latency_s"),
      "must equal maximum row latency_s"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "maximum_latency_limit_s",
      maximum_number(rows, "latency_limit_s"),
      "must equal maximum row latency_limit_s"
    )
  end

  defp row_stable_ids(rows, field) do
    rows
    |> Enum.flat_map(fn row -> row |> Map.get(field, []) |> List.wrap() end)
    |> sorted_unique_binary_values()
  end

  defp route_ids_by_field(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), &Map.get(&1, "route_id"))
    |> Enum.reject(fn {value, route_ids} -> is_nil(value) or route_ids == [] end)
    |> Map.new(fn {value, route_ids} -> {value, sorted_unique_binary_values(route_ids)} end)
  end

  defp maximum_number(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> Enum.max(fn -> nil end)
  end

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Map.new()
  end

  defp list_count(map, field) do
    case Map.get(map, field) do
      values when is_list(values) -> length(values)
      _values -> nil
    end
  end

  defp sorted_unique_binary_values(values) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp relay_custody_statuses, do: ~w(confirmed pending missing_ack failed unknown)
  defp relay_latency_statuses, do: ~w(within_limit exceeds_limit not_evaluated unknown)
  defp relay_risk_statuses, do: ~w(nominal review high unknown)

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [
      issues,
      path,
      map,
      field
    ])
  end

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_number), [issues, path, map, field])

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

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_rows(issues, callbacks, path, rows, validator) do
    wrapped_validator = fn acc, row_path, row -> validator.(acc, callbacks, row_path, row) end
    apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, wrapped_validator])
  end

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
      issues,
      path,
      counts
    ])
  end

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, values])

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

  defp relay_data_path_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :relay_data_path_model_limits), [])
end
