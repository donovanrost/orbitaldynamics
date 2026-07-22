defmodule OrbitalDynamics.CampaignPlanner.BranchComparisonContext.FieldValues do
  @moduledoc false

  def branch_event_trust_boundary_status_counts([]), do: %{}

  def branch_event_trust_boundary_status_counts(events) do
    events
    |> Enum.map(&branch_event_trust_boundary_status/1)
    |> Enum.frequencies()
  end

  def branch_event_unique_values(events, field) when is_binary(field) do
    branch_event_unique_values(events, [field])
  end

  def branch_event_unique_values(events, fields) when is_list(fields) do
    events
    |> Enum.flat_map(fn event ->
      Enum.map(fields, &Map.get(event, &1))
    end)
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.map(&encode_value/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def branch_source_window_bounds(events) do
    events
    |> Enum.reduce(%{}, fn event, bounds_by_id ->
      source_window_ids =
        branch_event_unique_values([event], ["source_window_id", "source_window_ids"])

      earliest_starts_at_s = numeric_or_nil(Map.get(event, "starts_at_s"))
      latest_ends_at_s = numeric_or_nil(Map.get(event, "ends_at_s"))

      if source_window_ids == [] or
           (is_nil(earliest_starts_at_s) and is_nil(latest_ends_at_s)) do
        bounds_by_id
      else
        Enum.reduce(source_window_ids, bounds_by_id, fn source_window_id, acc ->
          Map.update(
            acc,
            source_window_id,
            source_window_bound(source_window_id, earliest_starts_at_s, latest_ends_at_s),
            fn bound ->
              bound
              |> put_minimum("earliest_starts_at_s", earliest_starts_at_s)
              |> put_maximum("latest_ends_at_s", latest_ends_at_s)
            end
          )
        end)
      end
    end)
    |> Map.values()
    |> Enum.sort_by(& &1["source_window_id"])
  end

  def branch_event_map_keys(events, field) do
    events
    |> Enum.flat_map(fn event ->
      case Map.get(event, field) do
        %{} = map -> Map.keys(map)
        _value -> []
      end
    end)
    |> Enum.map(&encode_value/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def branch_event_merged_maps(events, field) do
    events
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn map, acc ->
      map
      |> stringify_keys()
      |> Enum.reduce(acc, fn {key, value}, inner ->
        values =
          value
          |> List.wrap()
          |> Enum.map(&encode_value/1)
          |> Enum.filter(&(is_binary(&1) and &1 != ""))

        Map.update(inner, key, values, fn existing ->
          (List.wrap(existing) ++ values)
          |> Enum.uniq()
          |> Enum.sort()
        end)
      end)
    end)
    |> Map.new(fn {key, values} -> {key, Enum.sort(Enum.uniq(values))} end)
  end

  def branch_event_merged_numeric_maps(events, field) do
    events
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn map, acc ->
      map
      |> stringify_keys()
      |> Enum.reduce(acc, fn {key, value}, inner ->
        case numeric_or_nil(value) do
          nil -> inner
          number -> Map.update(inner, key, number, &(&1 + number))
        end
      end)
    end)
  end

  def branch_station_reservation_conflict_unique_values(events, fields) do
    events
    |> Enum.filter(&station_reservation_conflict_event?/1)
    |> branch_event_unique_values(fields)
  end

  def branch_station_reservation_conflict_match_statuses(events, fields) do
    events
    |> Enum.filter(&station_reservation_conflict_event?/1)
    |> branch_event_unique_values(fields)
    |> Enum.filter(&station_reservation_conflict_match_status?/1)
  end

  def branch_event_requires_operator_review(events) do
    values =
      events
      |> Enum.map(&branch_event_operator_review_value/1)
      |> Enum.filter(&is_boolean/1)

    cond do
      Enum.any?(values, &(&1 == true)) -> true
      values != [] -> false
      true -> nil
    end
  end

  def branch_event_operator_review_count(events) do
    count =
      events
      |> Enum.count(&(branch_event_operator_review_value(&1) == true))

    if count > 0, do: count
  end

  def branch_event_transition_values(events, field) do
    events
    |> Enum.flat_map(fn event ->
      [Map.get(event, field), get_in(event, ["status_transition", field])]
    end)
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.map(&encode_value/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def branch_event_station_availabilities(events) do
    events
    |> Enum.map(fn
      %{"station_availability" => availability} ->
        availability

      %{"availability" => availability} ->
        availability

      %{"type" => "ground_station_outage"} ->
        "unavailable"

      %{"type" => "ground_station_reserved"} ->
        "reserved"

      _event ->
        nil
    end)
    |> Enum.map(&encode_value/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def maybe_put_combined_source_branch_ids(fields, []), do: fields

  def maybe_put_combined_source_branch_ids(fields, source_branch_ids) do
    Map.put(fields, "combined_source_branch_ids", source_branch_ids)
  end

  def maybe_put_nonempty(fields, key) do
    case Map.get(fields, key) do
      value when value in [%{}, [], nil] -> Map.delete(fields, key)
      _value -> fields
    end
  end

  def minimum_present(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.map(&numeric_or_nil/1)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
  end

  def maximum_present(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.map(&numeric_or_nil/1)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  def sum_present(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.map(&numeric_or_nil/1)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  def encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  def encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  def encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  def encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  def encode_value(nil), do: nil
  def encode_value(value) when is_boolean(value), do: value
  def encode_value(value) when is_atom(value), do: Atom.to_string(value)
  def encode_value(value), do: value

  defp branch_event_trust_boundary_status(%{} = event) do
    case branch_event_trust_boundary(event) do
      trust_boundary when is_binary(trust_boundary) and trust_boundary != "" -> "declared"
      _trust_boundary -> "missing"
    end
  end

  defp branch_event_trust_boundary_status(_event), do: "missing"

  defp branch_event_trust_boundary(%{} = event) do
    [Map.get(event, "trust_boundary"), get_in(event, ["provenance", "trust_boundary"])]
    |> Enum.map(&encode_value/1)
    |> Enum.find(&(is_binary(&1) and &1 != ""))
  end

  defp station_reservation_conflict_event?(event) do
    [event]
    |> branch_event_unique_values([
      "station_reservation_match_status",
      "reservation_match_status"
    ])
    |> Enum.any?(&station_reservation_conflict_match_status?/1)
  end

  defp station_reservation_conflict_match_status?(status) do
    status
    |> normalized_status_token()
    |> case do
      nil -> false
      "" -> false
      "matched" -> false
      "owner_matched" -> false
      "owned" -> false
      "owner" -> false
      _status -> true
    end
  end

  defp branch_event_operator_review_value(event) do
    [
      Map.get(event, "requires_operator_review"),
      get_in(event, ["status_transition", "requires_operator_review"])
    ]
    |> Enum.map(&json_boolean_value/1)
    |> Enum.find(&is_boolean/1)
  end

  defp normalized_status_token(nil), do: nil

  defp normalized_status_token(status) when is_atom(status) do
    status
    |> Atom.to_string()
    |> normalized_status_token()
  end

  defp normalized_status_token(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp normalized_status_token(status), do: status

  defp json_boolean_value(value) when is_boolean(value), do: value

  defp json_boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp json_boolean_value(value) when is_binary(value) do
    case value |> String.trim() |> String.downcase() do
      token when token in ["true", "1", "yes", "y"] -> true
      token when token in ["false", "0", "no", "n"] -> false
      _token -> nil
    end
  end

  defp json_boolean_value(_value), do: nil

  defp source_window_bound(source_window_id, earliest_starts_at_s, latest_ends_at_s) do
    %{"source_window_id" => source_window_id}
    |> put_minimum("earliest_starts_at_s", earliest_starts_at_s)
    |> put_maximum("latest_ends_at_s", latest_ends_at_s)
  end

  defp put_minimum(bound, _field, nil), do: bound

  defp put_minimum(bound, field, value) do
    Map.update(bound, field, value, &min(&1, value))
  end

  defp put_maximum(bound, _field, nil), do: bound

  defp put_maximum(bound, field, value) do
    Map.update(bound, field, value, &max(&1, value))
  end

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)
end
