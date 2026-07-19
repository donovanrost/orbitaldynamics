defmodule OrbitalDynamics.Communications.ContactContention.CapacityDemand do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactContention.{ContactIdentity, ContactNormalization}

  @required_capacity_fraction_paths [
    ["required_capacity_fraction"],
    ["required_station_capacity_fraction"],
    ["station_capacity_requirement"],
    ["throughput_model", "required_capacity_fraction"],
    ["throughput_model", "required_station_capacity_fraction"],
    ["throughput_model", "station_capacity_requirement"],
    ["capacity_model", "required_capacity_fraction"],
    ["capacity_model", "required_station_capacity_fraction"],
    ["capacity_model", "station_capacity_requirement"],
    ["activity_context", "required_capacity_fraction"],
    ["activity_context", "required_station_capacity_fraction"],
    ["activity_context", "station_capacity_requirement"]
  ]
  @required_capacity_percent_paths [
    ["required_capacity_percent"],
    ["required_station_capacity_percent"],
    ["station_capacity_requirement_percent"],
    ["throughput_model", "required_capacity_percent"],
    ["throughput_model", "required_station_capacity_percent"],
    ["throughput_model", "station_capacity_requirement_percent"],
    ["capacity_model", "required_capacity_percent"],
    ["capacity_model", "required_station_capacity_percent"],
    ["capacity_model", "station_capacity_requirement_percent"],
    ["activity_context", "required_capacity_percent"],
    ["activity_context", "required_station_capacity_percent"],
    ["activity_context", "station_capacity_requirement_percent"]
  ]
  @required_capacity_fraction_source_values ~w(
    contact_required_capacity_fraction
    throughput_model
    capacity_model
    activity_context
  )
  @required_capacity_value_paths [
    {:fraction, ["required_capacity_fraction"]},
    {:fraction, ["required_station_capacity_fraction"]},
    {:fraction, ["station_capacity_requirement"]},
    {:percent, ["required_capacity_percent"]},
    {:percent, ["required_station_capacity_percent"]},
    {:percent, ["station_capacity_requirement_percent"]},
    {:fraction, ["throughput_model", "required_capacity_fraction"]},
    {:fraction, ["throughput_model", "required_station_capacity_fraction"]},
    {:fraction, ["throughput_model", "station_capacity_requirement"]},
    {:percent, ["throughput_model", "required_capacity_percent"]},
    {:percent, ["throughput_model", "required_station_capacity_percent"]},
    {:percent, ["throughput_model", "station_capacity_requirement_percent"]},
    {:fraction, ["capacity_model", "required_capacity_fraction"]},
    {:fraction, ["capacity_model", "required_station_capacity_fraction"]},
    {:fraction, ["capacity_model", "station_capacity_requirement"]},
    {:percent, ["capacity_model", "required_capacity_percent"]},
    {:percent, ["capacity_model", "required_station_capacity_percent"]},
    {:percent, ["capacity_model", "station_capacity_requirement_percent"]},
    {:fraction, ["activity_context", "required_capacity_fraction"]},
    {:fraction, ["activity_context", "required_station_capacity_fraction"]},
    {:fraction, ["activity_context", "station_capacity_requirement"]},
    {:percent, ["activity_context", "required_capacity_percent"]},
    {:percent, ["activity_context", "required_station_capacity_percent"]},
    {:percent, ["activity_context", "station_capacity_requirement_percent"]}
  ]

  def required_capacity_fraction_paths, do: @required_capacity_fraction_paths
  def required_capacity_percent_paths, do: @required_capacity_percent_paths
  def required_capacity_value_paths, do: @required_capacity_value_paths
  def required_capacity_fraction_source_values, do: @required_capacity_fraction_source_values

  def build(recommendations) do
    rows = Enum.flat_map(recommendations, &contention_resolution_capacity_pack_demand_rows/1)
    selected_rows = Enum.filter(rows, &(&1.status == :selected))
    deferred_rows = Enum.filter(rows, &(&1.status == :deferred))

    %{
      "capacity_pack_required_capacity_fraction" => demand_row_total(rows),
      "capacity_pack_selected_required_capacity_fraction" => demand_row_total(selected_rows),
      "capacity_pack_deferred_required_capacity_fraction" => demand_row_total(deferred_rows),
      "capacity_pack_required_capacity_fraction_by_status" => demand_rows_by_status(rows),
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        demand_rows_by_station(rows),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" =>
        demand_rows_by_station(selected_rows),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" =>
        demand_rows_by_station(deferred_rows),
      "required_capacity_fraction_source_counts" => demand_rows_by_source(rows),
      "required_capacity_fraction_contact_ids_by_source" => demand_row_ids_by_source(rows)
    }
  end

  defp contention_resolution_capacity_pack_demand_rows(recommendation) do
    candidates = recommendation |> Map.get("source_contact_candidates", []) |> List.wrap()
    selected_contact_id = recommendation["selected_contact_id"]
    deferred_contact_ids = MapSet.new(List.wrap(recommendation["deferred_contact_ids"]))

    candidates
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn contact ->
      contact_id = contact_id(contact)
      required_capacity_fraction = required_capacity_fraction(contact)

      cond do
        is_nil(contact_id) or is_nil(required_capacity_fraction) ->
          []

        contact_id == selected_contact_id ->
          [capacity_pack_demand_row(contact, :selected, required_capacity_fraction)]

        MapSet.member?(deferred_contact_ids, contact_id) ->
          [capacity_pack_demand_row(contact, :deferred, required_capacity_fraction)]

        true ->
          []
      end
    end)
  end

  defp capacity_pack_demand_row(contact, status, required_capacity_fraction) do
    %{
      status: status,
      contact_id: contact_id(contact),
      ground_station_id: stable_id_or_nil(contact["ground_station_id"]),
      required_capacity_fraction: required_capacity_fraction,
      required_capacity_fraction_source: required_capacity_fraction_source(contact)
    }
  end

  defp demand_row_total(rows) do
    rows
    |> Enum.map(& &1.required_capacity_fraction)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp demand_rows_by_station(rows) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      if is_nil(row.ground_station_id) do
        totals
      else
        Map.update(totals, row.ground_station_id, row.required_capacity_fraction, fn value ->
          value + row.required_capacity_fraction
        end)
      end
    end)
    |> case do
      values when values == %{} -> nil
      values -> values
    end
  end

  defp demand_rows_by_status(rows) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      Map.update(totals, Atom.to_string(row.status), row.required_capacity_fraction, fn value ->
        value + row.required_capacity_fraction
      end)
    end)
  end

  defp demand_rows_by_source(rows) do
    rows
    |> Enum.map(& &1.required_capacity_fraction_source)
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp demand_row_ids_by_source(rows) do
    rows
    |> Enum.group_by(& &1.required_capacity_fraction_source, & &1.contact_id)
    |> Enum.reject(fn {source, ids} ->
      is_nil(source) or Enum.all?(ids, &is_nil/1)
    end)
    |> Map.new(fn {source, ids} ->
      {source, compact_sorted_unique_list(ids)}
    end)
  end

  defp required_capacity_fraction(contact) do
    contact
    |> capacity_value_candidates(@required_capacity_value_paths)
    |> Enum.find_value(&unit_interval_number/1)
  end

  defp required_capacity_fraction_source(contact) do
    cond do
      valid_capacity_value_declared?(contact["required_capacity_fraction"]) or
        valid_capacity_value_declared?(contact["required_station_capacity_fraction"]) or
        valid_capacity_value_declared?(contact["station_capacity_requirement"]) or
        valid_capacity_percent_declared?(contact["required_capacity_percent"]) or
        valid_capacity_percent_declared?(contact["required_station_capacity_percent"]) or
          valid_capacity_percent_declared?(contact["station_capacity_requirement_percent"]) ->
        "contact_required_capacity_fraction"

      valid_capacity_value_declared?(
        get_in(contact, ["throughput_model", "required_capacity_fraction"])
      ) or
        valid_capacity_value_declared?(
          get_in(contact, ["throughput_model", "required_station_capacity_fraction"])
        ) or
        valid_capacity_value_declared?(
          get_in(contact, ["throughput_model", "station_capacity_requirement"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["throughput_model", "required_capacity_percent"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["throughput_model", "required_station_capacity_percent"])
        ) or
          valid_capacity_percent_declared?(
            get_in(contact, ["throughput_model", "station_capacity_requirement_percent"])
          ) ->
        "throughput_model"

      valid_capacity_value_declared?(
        get_in(contact, ["capacity_model", "required_capacity_fraction"])
      ) or
        valid_capacity_value_declared?(
          get_in(contact, ["capacity_model", "required_station_capacity_fraction"])
        ) or
        valid_capacity_value_declared?(
          get_in(contact, ["capacity_model", "station_capacity_requirement"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["capacity_model", "required_capacity_percent"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["capacity_model", "required_station_capacity_percent"])
        ) or
          valid_capacity_percent_declared?(
            get_in(contact, ["capacity_model", "station_capacity_requirement_percent"])
          ) ->
        "capacity_model"

      valid_capacity_value_declared?(
        get_in(contact, ["activity_context", "required_capacity_fraction"])
      ) or
        valid_capacity_value_declared?(
          get_in(contact, ["activity_context", "required_station_capacity_fraction"])
        ) or
        valid_capacity_value_declared?(
          get_in(contact, ["activity_context", "station_capacity_requirement"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["activity_context", "required_capacity_percent"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["activity_context", "required_station_capacity_percent"])
        ) or
          valid_capacity_percent_declared?(
            get_in(contact, ["activity_context", "station_capacity_requirement_percent"])
          ) ->
        "activity_context"

      true ->
        nil
    end
  end

  defp valid_capacity_value_declared?(value) do
    case numeric_or_nil(value) do
      value when is_number(value) -> value >= 0.0 and value <= 1.0
      _value -> false
    end
  end

  defp valid_capacity_percent_declared?(value) do
    case numeric_or_nil(value) do
      value when is_number(value) -> value >= 0.0 and value <= 100.0
      _value -> false
    end
  end

  defp capacity_value_candidates(value, paths) do
    Enum.map(paths, fn
      {:fraction, path} ->
        path_value(value, path)

      {:percent, path} ->
        capacity_percent_fraction(path_value(value, path))
    end)
  end

  defp path_value(value, [field]), do: Map.get(value, field)
  defp path_value(value, path), do: get_in(value, path)

  defp capacity_percent_fraction(value) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end

  defp unit_interval_number(value) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> value
      _value -> nil
    end
  end

  defp contact_id(contact), do: ContactIdentity.contact_id(contact)
  defp stable_id_or_nil(value), do: ContactIdentity.stable_id_or_nil(value)
  defp numeric_or_nil(value), do: ContactNormalization.numeric_or_nil(value)
  defp stringify_keys(value), do: ContactNormalization.stringify_keys(value)

  defp compact_sorted_unique_list(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
