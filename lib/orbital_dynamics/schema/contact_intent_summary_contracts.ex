defmodule OrbitalDynamics.Schema.ContactIntentSummaryContracts do
  @moduledoc false

  def validate_summary(issues, path, summary, callbacks) when is_list(callbacks) do
    station_contact_ids = Map.get(summary, "contact_ids_by_ground_station_id", %{})
    direction_contact_ids = Map.get(summary, "contact_ids_by_direction", %{}) || %{}
    capacity_station_ids = Map.get(summary, "capacity_pack_contact_ids_by_ground_station_id", %{})

    capacity_direction_ids =
      Map.get(summary, "capacity_pack_contact_ids_by_direction", %{}) || %{}

    direction_station_contact_ids =
      Map.get(summary, "contact_ids_by_direction_and_ground_station_id", %{}) || %{}

    capacity_direction_station_ids =
      Map.get(summary, "capacity_pack_contact_ids_by_direction_and_ground_station_id", %{}) || %{}

    source_counts = Map.get(summary, "required_capacity_fraction_source_counts", %{})
    source_contact_ids = Map.get(summary, "required_capacity_fraction_contact_ids_by_source", %{})

    station_capacity_totals =
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_ground_station_id", %{})

    direction_capacity_totals =
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_direction")

    direction_station_capacity_totals =
      Map.get(
        summary,
        "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id"
      )

    issues
    |> expect_equal(callbacks, path, summary, "schema_contract", "contact_intent_summary.v1")
    |> expect_equal(callbacks, path, summary, "model", "artifact_only_contact_intent_summary")
    |> expect_equal(callbacks, path, summary, "source_artifact_type", "contact_intent.v1")
    |> expect_optional_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_contact_intent_model_limits(callbacks, path, summary)
    |> expect_non_negative_integer(callbacks, path, summary, "contact_intent_count")
    |> expect_non_negative_integer(
      callbacks,
      path,
      summary,
      "capacity_pack_required_contact_count"
    )
    |> expect_optional_number(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction"
    )
    |> validate_capacity_fraction_maps(
      callbacks,
      path,
      summary,
      station_capacity_totals,
      direction_capacity_totals,
      direction_station_capacity_totals
    )
    |> validate_contact_id_maps(
      callbacks,
      path,
      summary,
      source_counts,
      source_contact_ids,
      station_contact_ids,
      direction_contact_ids,
      capacity_station_ids,
      capacity_direction_ids,
      direction_station_contact_ids,
      capacity_direction_station_ids
    )
    |> expect_type(callbacks, path, summary, "ground_station_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, summary, "ground_station_ids")
    |> expect_type(callbacks, path, summary, "directions", :list)
    |> validate_string_list_allowed(
      callbacks,
      path,
      summary,
      "directions",
      OrbitalDynamics.Communications.ContactIntent.capabilities().directions
    )
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> validate_assumptions(callbacks, path, summary)
    |> validate_summary_consistency(
      callbacks,
      path,
      summary,
      station_contact_ids,
      direction_contact_ids,
      source_counts,
      capacity_station_ids,
      capacity_direction_ids,
      direction_station_contact_ids,
      capacity_direction_station_ids,
      station_capacity_totals,
      direction_capacity_totals,
      direction_station_capacity_totals
    )
    |> validate_source_id_counts(callbacks, path, summary)
  end

  defp validate_capacity_fraction_maps(
         issues,
         callbacks,
         path,
         summary,
         station_capacity_totals,
         direction_capacity_totals,
         direction_station_capacity_totals
       ) do
    issues
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      :map
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_ground_station_id",
      station_capacity_totals
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_direction",
      :map
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_direction",
      direction_capacity_totals
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id",
      :map
    )
    |> validate_nested_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id",
      direction_station_capacity_totals
    )
  end

  defp validate_contact_id_maps(
         issues,
         callbacks,
         path,
         summary,
         source_counts,
         source_contact_ids,
         station_contact_ids,
         direction_contact_ids,
         capacity_station_ids,
         capacity_direction_ids,
         direction_station_contact_ids,
         capacity_direction_station_ids
       ) do
    issues
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "required_capacity_fraction_source_counts",
      :map
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".required_capacity_fraction_source_counts",
      source_counts
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "required_capacity_fraction_contact_ids_by_source",
      :map
    )
    |> expect_optional_type(callbacks, path, summary, "contact_ids_by_ground_station_id", :map)
    |> expect_optional_type(callbacks, path, summary, "contact_ids_by_direction", :map)
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "contact_ids_by_direction_and_ground_station_id",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "capacity_pack_contact_ids_by_ground_station_id",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "capacity_pack_contact_ids_by_direction",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      summary,
      "capacity_pack_contact_ids_by_direction_and_ground_station_id",
      :map
    )
    |> expect_optional_type(callbacks, path, summary, "direction_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".direction_counts",
      Map.get(summary, "direction_counts")
    )
    |> validate_contact_intent_direction_routing(
      callbacks,
      path,
      Map.get(summary, "direction_routing"),
      summary
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".required_capacity_fraction_contact_ids_by_source",
      source_contact_ids
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".contact_ids_by_ground_station_id",
      station_contact_ids
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".contact_ids_by_direction",
      direction_contact_ids
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".capacity_pack_contact_ids_by_ground_station_id",
      capacity_station_ids
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".capacity_pack_contact_ids_by_direction",
      capacity_direction_ids
    )
    |> validate_nested_stable_id_array_map(
      callbacks,
      path <> ".contact_ids_by_direction_and_ground_station_id",
      direction_station_contact_ids
    )
    |> validate_nested_stable_id_array_map(
      callbacks,
      path <> ".capacity_pack_contact_ids_by_direction_and_ground_station_id",
      capacity_direction_station_ids
    )
  end

  defp validate_summary_consistency(
         issues,
         callbacks,
         path,
         summary,
         station_contact_ids,
         direction_contact_ids,
         source_counts,
         capacity_station_ids,
         capacity_direction_ids,
         direction_station_contact_ids,
         capacity_direction_station_ids,
         station_capacity_totals,
         direction_capacity_totals,
         direction_station_capacity_totals
       ) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "contact_intent_count",
      stable_id_array_map_value_count(station_contact_ids),
      "must equal contact_ids_by_ground_station_id total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "contact_intent_count",
      stable_id_array_map_value_count(direction_contact_ids),
      "must equal contact_ids_by_direction total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_required_contact_count",
      non_negative_integer_map_sum(source_counts),
      "must equal required_capacity_fraction_source_counts total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_required_contact_count",
      stable_id_array_map_value_count(capacity_station_ids),
      "must equal capacity_pack_contact_ids_by_ground_station_id total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_required_contact_count",
      stable_id_array_map_value_count(capacity_direction_ids),
      "must equal capacity_pack_contact_ids_by_direction total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "contact_intent_count",
      nested_stable_id_array_map_value_count(direction_station_contact_ids),
      "must equal contact_ids_by_direction_and_ground_station_id total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_required_contact_count",
      nested_stable_id_array_map_value_count(capacity_direction_station_ids),
      "must equal capacity_pack_contact_ids_by_direction_and_ground_station_id total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction",
      numeric_map_sum(station_capacity_totals),
      "must equal capacity_pack_required_capacity_fraction_by_ground_station_id total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction",
      numeric_map_sum(direction_capacity_totals),
      "must equal capacity_pack_required_capacity_fraction_by_direction total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction",
      nested_numeric_map_sum(direction_station_capacity_totals),
      "must equal capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "ground_station_ids",
      sorted_map_keys(station_contact_ids),
      "must equal contact_ids_by_ground_station_id keys"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "directions",
      sorted_map_keys(direction_contact_ids),
      "must equal contact_ids_by_direction keys"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "direction_counts",
      stable_id_array_map_counts(direction_contact_ids),
      "must equal contact_ids_by_direction counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "direction_routing",
      contact_intent_summary_direction_routing(summary),
      "must equal row-derived direction routing"
    )
  end

  defp validate_assumptions(issues, callbacks, path, summary) do
    case Map.get(summary, "assumptions") do
      assumptions when is_map(assumptions) ->
        issues
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "execution_boundary",
          "artifact_only_no_provider_reservation_or_schedule_mutation"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "source_artifact_type",
          "contact_intent.v1"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_capacity_value_paths",
          station_capacity_value_path_assumptions(callbacks),
          "must match ContactIntent station capacity value paths"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "required_capacity_value_paths",
          required_capacity_value_path_assumptions(callbacks),
          "must match ContactIntent required capacity value paths"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "required_capacity_fraction_source_values",
          required_capacity_fraction_source_values(callbacks),
          "must match ContactIntent required capacity fraction source values"
        )

      _assumptions ->
        issues
    end
  end

  defp validate_source_id_counts(issues, callbacks, path, summary) do
    expected =
      case Map.get(summary, "required_capacity_fraction_contact_ids_by_source", %{}) do
        source_contact_ids when is_map(source_contact_ids) ->
          Map.new(source_contact_ids, fn {source, ids} -> {source, length(ids || [])} end)

        _source_contact_ids ->
          nil
      end

    expect_field_equals(
      issues,
      callbacks,
      path,
      summary,
      "required_capacity_fraction_source_counts",
      expected,
      "must equal required_capacity_fraction_contact_ids_by_source counts"
    )
  end

  defp contact_intent_summary_direction_routing(summary) do
    contact_ids_by_direction = Map.get(summary, "contact_ids_by_direction", %{}) || %{}

    capacity_fraction_by_direction =
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_direction", %{}) || %{}

    capacity_contact_ids_by_direction =
      Map.get(summary, "capacity_pack_contact_ids_by_direction", %{}) || %{}

    contact_ids_by_direction_and_station =
      Map.get(summary, "contact_ids_by_direction_and_ground_station_id", %{}) || %{}

    capacity_fraction_by_direction_and_station =
      Map.get(
        summary,
        "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id",
        %{}
      ) || %{}

    capacity_contact_ids_by_direction_and_station =
      Map.get(summary, "capacity_pack_contact_ids_by_direction_and_ground_station_id", %{}) || %{}

    [
      Map.keys(contact_ids_by_direction),
      Map.keys(capacity_fraction_by_direction),
      Map.keys(capacity_contact_ids_by_direction),
      Map.keys(contact_ids_by_direction_and_station),
      Map.keys(capacity_fraction_by_direction_and_station),
      Map.keys(capacity_contact_ids_by_direction_and_station)
    ]
    |> List.flatten()
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Map.new(fn direction ->
      route =
        %{
          "contact_count" => length(Map.get(contact_ids_by_direction, direction, [])),
          "contact_ids" => Map.get(contact_ids_by_direction, direction, []),
          "capacity_pack_required_capacity_fraction" =>
            Map.get(capacity_fraction_by_direction, direction),
          "capacity_pack_contact_ids" =>
            Map.get(capacity_contact_ids_by_direction, direction, []),
          "ground_station_ids" =>
            contact_ids_by_direction_and_station
            |> Map.get(direction, %{})
            |> Map.keys()
            |> Enum.sort(),
          "contact_ids_by_ground_station_id" =>
            Map.get(contact_ids_by_direction_and_station, direction, %{}),
          "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
            Map.get(capacity_fraction_by_direction_and_station, direction, %{}),
          "capacity_pack_contact_ids_by_ground_station_id" =>
            Map.get(capacity_contact_ids_by_direction_and_station, direction, %{})
        }
        |> Enum.reject(fn
          {"capacity_pack_contact_ids", []} -> false
          {_key, value} when value in [nil, %{}, []] -> true
          _entry -> false
        end)
        |> Map.new()

      {direction, route}
    end)
  end

  defp validate_contact_intent_model_limits(issues, callbacks, path, intent) do
    case Map.get(intent, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if Enum.sort(limits) == contact_intent_model_limits(callbacks) do
          issues
        else
          [
            error(callbacks, "#{path}.model_limits", "must match contact intent model limits")
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp non_negative_integer_map_sum(counts) when is_map(counts) do
    values = Map.values(counts)

    if Enum.all?(values, &(is_integer(&1) and &1 >= 0)),
      do: Enum.sum(values),
      else: nil
  end

  defp non_negative_integer_map_sum(_counts), do: nil

  defp numeric_map_sum(values) when is_map(values) do
    values = Map.values(values)

    if Enum.all?(values, &is_number/1),
      do: Enum.sum(values),
      else: nil
  end

  defp numeric_map_sum(_values), do: nil

  defp nested_numeric_map_sum(values) when is_map(values) do
    values
    |> Map.values()
    |> Enum.reduce_while(0.0, fn
      nested_values, total when is_map(nested_values) ->
        case numeric_map_sum(nested_values) do
          sum when is_number(sum) -> {:cont, total + sum}
          _sum -> {:halt, nil}
        end

      _nested_values, _total ->
        {:halt, nil}
    end)
  end

  defp nested_numeric_map_sum(_values), do: nil

  defp stable_id_array_map_value_count(values) when is_map(values) do
    values
    |> Map.values()
    |> Enum.reduce_while(0, fn
      ids, total when is_list(ids) -> {:cont, total + length(ids)}
      _ids, _total -> {:halt, nil}
    end)
  end

  defp stable_id_array_map_value_count(_values), do: nil

  defp nested_stable_id_array_map_value_count(values) when is_map(values) do
    values
    |> Map.values()
    |> Enum.reduce_while(0, fn
      nested_values, total when is_map(nested_values) ->
        case stable_id_array_map_value_count(nested_values) do
          count when is_integer(count) -> {:cont, total + count}
          _count -> {:halt, nil}
        end

      _nested_values, _total ->
        {:halt, nil}
    end)
  end

  defp nested_stable_id_array_map_value_count(_values), do: nil

  defp stable_id_array_map_counts(values) when is_map(values) do
    values
    |> Map.new(fn
      {key, ids} when is_list(ids) -> {key, length(ids)}
      {key, _ids} -> {key, nil}
    end)
  end

  defp stable_id_array_map_counts(_values), do: nil

  defp sorted_map_keys(values) when is_map(values) do
    values
    |> Map.keys()
    |> Enum.sort()
  end

  defp sorted_map_keys(_values), do: nil

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

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

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_non_negative_number_map(issues, callbacks, path, values),
    do:
      apply(Keyword.fetch!(callbacks, :validate_non_negative_number_map), [issues, path, values])

  defp validate_nested_non_negative_number_map(issues, callbacks, path, values) do
    apply(Keyword.fetch!(callbacks, :validate_nested_non_negative_number_map), [
      issues,
      path,
      values
    ])
  end

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
      issues,
      path,
      counts
    ])
  end

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_nested_stable_id_array_map(issues, callbacks, path, values) do
    apply(Keyword.fetch!(callbacks, :validate_nested_stable_id_array_map), [
      issues,
      path,
      values
    ])
  end

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_string_list_allowed(issues, callbacks, path, map, field, allowed) do
    apply(Keyword.fetch!(callbacks, :validate_string_list_allowed), [
      issues,
      path,
      map,
      field,
      allowed
    ])
  end

  defp validate_contact_intent_direction_routing(issues, callbacks, path, value, summary) do
    apply(Keyword.fetch!(callbacks, :validate_contact_intent_direction_routing), [
      issues,
      path,
      value,
      summary
    ])
  end

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals), [
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

  defp contact_intent_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_intent_model_limits), [])

  defp station_capacity_value_path_assumptions(callbacks),
    do: apply(Keyword.fetch!(callbacks, :station_capacity_value_path_assumptions), [])

  defp required_capacity_value_path_assumptions(callbacks),
    do: apply(Keyword.fetch!(callbacks, :required_capacity_value_path_assumptions), [])

  defp required_capacity_fraction_source_values(callbacks),
    do: apply(Keyword.fetch!(callbacks, :required_capacity_fraction_source_values), [])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
