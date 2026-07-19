defmodule OrbitalDynamics.Communications.ContactAllocation.CapacityPacking do
  @moduledoc false

  def default_required_fraction(opts) do
    value =
      Keyword.get(opts, :default_required_capacity_fraction) ||
        get_in(Keyword.get(opts, :capacity_policy, %{}), ["default_required_capacity_fraction"]) ||
        get_in(Keyword.get(opts, :capacity_policy, %{}), [:default_required_capacity_fraction]) ||
        get_in(Keyword.get(opts, :policy, %{}), ["default_required_capacity_fraction"]) ||
        get_in(Keyword.get(opts, :policy, %{}), [:default_required_capacity_fraction])

    case numeric_or_nil(value) do
      nil ->
        nil

      value when value > 0.0 and value <= 1.0 ->
        value

      _value ->
        raise ArgumentError, "default_required_capacity_fraction must be in the interval (0, 1]"
    end
  end

  def apply(rows, default_capacity_requirement) do
    pack_groups =
      rows
      |> Enum.filter(&pack_row?/1)
      |> Enum.group_by(& &1["contention_group_id"])
      |> Enum.map(fn {_group_id, group_rows} ->
        pack_group(group_rows, default_capacity_requirement)
      end)

    decisions =
      pack_groups
      |> Enum.flat_map(& &1["row_decisions"])
      |> Map.new()

    packed_rows =
      Enum.map(rows, fn row ->
        case Map.get(decisions, row["contact_id"]) do
          nil -> row
          decision -> apply_decision(row, decision)
        end
      end)

    {packed_rows, Enum.map(pack_groups, &Map.delete(&1, "row_decisions"))}
  end

  defp pack_row?(%{
         "contention_group_id" => group_id,
         "capacity_fraction" => capacity_fraction,
         "source_contention_recommendation" => %{"resource_scope" => "ground_station"}
       })
       when is_binary(group_id) and is_number(capacity_fraction) and capacity_fraction > 0.0 and
              capacity_fraction < 1.0,
       do: true

  defp pack_row?(_row), do: false

  defp pack_group(group_rows, default_capacity_requirement) do
    recommendation =
      group_rows
      |> Enum.map(& &1["source_contention_recommendation"])
      |> Enum.find(&is_map/1)

    group_id = group_rows |> Enum.map(& &1["contention_group_id"]) |> Enum.find(&is_binary/1)
    capacity_fraction = group_rows |> Enum.map(& &1["capacity_fraction"]) |> Enum.min()
    rows_by_contact_id = Map.new(group_rows, &{&1["contact_id"], &1})

    {contention_selected_ids, contention_deferred_ids} = contact_order(recommendation)

    selected_ids = Enum.filter(contention_selected_ids, &Map.has_key?(rows_by_contact_id, &1))
    deferred_ids = Enum.filter(contention_deferred_ids, &Map.has_key?(rows_by_contact_id, &1))

    {used_fraction, capacity_selected_ids, capacity_packed_ids, capacity_deferred_ids} =
      (selected_ids ++ deferred_ids)
      |> Enum.map(&Map.get(rows_by_contact_id, &1))
      |> Enum.reject(&is_nil/1)
      |> Enum.reduce({0.0, [], [], []}, fn row,
                                           {used_fraction, selected_fit_ids, packed_ids,
                                            deferred_ids} ->
        demand_fraction = requirement(row, default_capacity_requirement)
        contact_id = row["contact_id"]

        if used_fraction + demand_fraction <= capacity_fraction + 1.0e-9 do
          if contact_id in selected_ids do
            {used_fraction + demand_fraction, selected_fit_ids ++ [contact_id], packed_ids,
             deferred_ids}
          else
            {used_fraction + demand_fraction, selected_fit_ids, packed_ids ++ [contact_id],
             deferred_ids}
          end
        else
          {used_fraction, selected_fit_ids, packed_ids, deferred_ids ++ [contact_id]}
        end
      end)

    allocated_ids = capacity_selected_ids ++ capacity_packed_ids
    capacity_selected_contact_id = List.first(allocated_ids)

    row_decisions =
      Enum.map(capacity_selected_ids, fn contact_id ->
        {contact_id,
         decision(
           "selected_by_contention_resolution",
           group_id,
           capacity_fraction,
           used_fraction,
           Map.fetch!(rows_by_contact_id, contact_id),
           default_capacity_requirement,
           nil
         )}
      end) ++
        Enum.map(capacity_packed_ids, fn contact_id ->
          {contact_id,
           decision(
             "selected_by_reduced_station_capacity_pack",
             group_id,
             capacity_fraction,
             used_fraction,
             Map.fetch!(rows_by_contact_id, contact_id),
             default_capacity_requirement,
             nil
           )}
        end) ++
        Enum.map(capacity_deferred_ids, fn contact_id ->
          {contact_id,
           decision(
             "deferred_by_reduced_station_capacity_pack",
             group_id,
             capacity_fraction,
             used_fraction,
             Map.fetch!(rows_by_contact_id, contact_id),
             default_capacity_requirement,
             capacity_selected_contact_id
           )}
        end)

    requirement_rows =
      requirement_rows(group_rows, row_decisions, default_capacity_requirement)

    %{
      "contention_group_id" => group_id,
      "ground_station_id" => first_present(group_rows, "ground_station_id"),
      "capacity_fraction" => capacity_fraction,
      "used_capacity_fraction" => used_fraction,
      "unused_capacity_fraction" => max(capacity_fraction - used_fraction, 0.0),
      "input_contact_ids" => Enum.map(group_rows, & &1["contact_id"]),
      "selected_contact_ids" => capacity_selected_ids,
      "capacity_packed_contact_ids" => capacity_packed_ids,
      "deferred_contact_ids" => capacity_deferred_ids,
      "capacity_requirement_rows" => requirement_rows,
      "default_required_capacity_fraction" => default_capacity_requirement,
      "pack_status" => if(capacity_deferred_ids == [], do: "all_fit", else: "capacity_limited"),
      "source_contention_recommendation" => recommendation,
      "row_decisions" => row_decisions
    }
    |> compact_map()
  end

  defp decision(
         status,
         group_id,
         capacity_fraction,
         used_fraction,
         row,
         default_capacity_requirement,
         selected_contact_id
       ) do
    %{
      "capacity_pack_group_id" => group_id,
      "capacity_pack_status" => status,
      "capacity_pack_capacity_fraction" => capacity_fraction,
      "capacity_pack_used_fraction" => used_fraction,
      "selected_contact_id" => selected_contact_id
    }
    |> Map.merge(requirement_context(row, default_capacity_requirement))
    |> compact_map()
  end

  defp requirement_rows(group_rows, row_decisions, default_capacity_requirement) do
    decisions_by_contact_id = Map.new(row_decisions)

    Enum.map(group_rows, fn row ->
      decision = Map.get(decisions_by_contact_id, row["contact_id"], %{})
      allocation_row = apply_decision(row, decision)

      %{
        "contact_id" => row["contact_id"],
        "allocation_status" => allocation_row["allocation_status"],
        "allocation_reason" => allocation_row["allocation_reason"],
        "capacity_pack_status" => decision["capacity_pack_status"],
        "required_capacity_fraction" => requirement(row, default_capacity_requirement),
        "required_capacity_fraction_source" =>
          requirement_source(row, default_capacity_requirement)
      }
      |> compact_map()
    end)
  end

  defp contact_order(%{} = recommendation) do
    selected_ids = List.wrap(recommendation["selected_contact_id"]) |> Enum.reject(&is_nil/1)
    deferred_ids = Map.get(recommendation, "deferred_contact_ids", [])
    {selected_ids, deferred_ids}
  end

  defp contact_order(_recommendation), do: {[], []}

  defp requirement(row, default_capacity_requirement) do
    known_or_full_requirement(row, default_capacity_requirement)
  end

  defp known_or_full_requirement(%{"required_capacity_fraction" => value}, _default)
       when is_number(value),
       do: value

  defp known_or_full_requirement(_row, default) when is_number(default), do: default

  defp known_or_full_requirement(%{"capacity_fraction" => value}, _default)
       when is_number(value),
       do: value

  defp known_or_full_requirement(_row, _default), do: 1.0

  defp requirement_source(
         %{"required_capacity_fraction" => value, "required_capacity_fraction_source" => source},
         _default
       )
       when is_number(value) and is_binary(source),
       do: source

  defp requirement_source(%{"required_capacity_fraction" => value}, _default)
       when is_number(value),
       do: "contact_required_capacity_fraction"

  defp requirement_source(_row, default) when is_number(default),
    do: "default_reduced_capacity_policy"

  defp requirement_source(%{"capacity_fraction" => value}, _default)
       when is_number(value),
       do: "station_capacity_fraction_fallback"

  defp requirement_source(_row, _default), do: "implicit_full_station_capacity"

  defp requirement_context(row, default) do
    %{
      "required_capacity_fraction" => requirement(row, default),
      "required_capacity_fraction_source" => requirement_source(row, default)
    }
  end

  defp promote_packed_row(%{"allocation_status" => "deferred"} = row) do
    row
    |> Map.put("allocation_status", "allocated")
    |> Map.put("allocation_reason", "selected_by_reduced_station_capacity_pack")
    |> Map.put("selected", true)
    |> Map.put("selected_contact_id", row["contact_id"])
    |> Map.put("review_status", "operator_review_required")
  end

  defp promote_packed_row(row), do: row

  defp defer_limited_row(%{"allocation_status" => "allocated"} = row) do
    row
    |> Map.put("allocation_status", "deferred")
    |> Map.put("allocation_reason", "deferred_by_reduced_station_capacity_pack")
    |> Map.put("selected", false)
    |> Map.put("review_status", "operator_review_required")
  end

  defp defer_limited_row(row), do: row

  defp apply_decision(row, decision) do
    row =
      case decision["capacity_pack_status"] do
        "selected_by_reduced_station_capacity_pack" -> promote_packed_row(row)
        "deferred_by_reduced_station_capacity_pack" -> defer_limited_row(row)
        _status -> row
      end

    Map.merge(row, decision)
  end

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp first_present(rows, field), do: Enum.find_value(rows, &Map.get(&1, field))

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
