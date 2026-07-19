defmodule OrbitalDynamics.Communications.LinkCapacity.RelayDataPath do
  @moduledoc false

  alias OrbitalDynamics.Communications.LinkCapacity.ContactIdentity

  @schema_contract "relay_data_path_summary.v1"
  @model_limits [
    "artifact_level_relay_data_path_summary",
    "no_crosslink_visibility_model",
    "no_relay_scheduling",
    "no_custody_acknowledgement_delivery",
    "no_provider_reservation",
    "no_schedule_mutation"
  ]
  @custody_statuses ~w(confirmed pending missing_ack failed unknown)
  @latency_statuses ~w(within_limit exceeds_limit not_evaluated unknown)
  @risk_statuses ~w(nominal review high unknown)

  def schema_contract, do: @schema_contract
  def model_limits, do: @model_limits

  def statuses do
    %{
      custody: @custody_statuses,
      latency: @latency_statuses,
      risk: @risk_statuses
    }
  end

  def summary(routes, opts \\ [])

  def summary(
        %{"schema_contract" => @schema_contract} = summary,
        _opts
      ) do
    summary
  end

  def summary(
        %{schema_contract: @schema_contract} = summary,
        opts
      ) do
    summary
    |> stringify_keys()
    |> summary(opts)
  end

  def summary(routes, opts) when is_list(routes) and is_list(opts) do
    source = opts |> Keyword.get(:source, "relay_data_path_inputs") |> to_string()
    default_latency_limit_s = opts |> Keyword.get(:latency_limit_s) |> numeric_value()

    rows =
      routes
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(fn route -> relay_data_path_row(route, default_latency_limit_s) end)
      |> Enum.sort_by(& &1["route_id"])

    %{
      "schema_contract" => @schema_contract,
      "schema_version" => 1,
      "model" => "artifact_only_relay_data_path_summary",
      "source" => source,
      "route_count" => length(rows),
      "relay_route_count" => Enum.count(rows, &(&1["relay_hop_count"] > 0)),
      "direct_downlink_route_count" => Enum.count(rows, &(&1["relay_hop_count"] == 0)),
      "custody_status_counts" => relay_status_count_map(rows, "custody_status"),
      "latency_status_counts" => relay_status_count_map(rows, "latency_status"),
      "risk_status_counts" => relay_status_count_map(rows, "risk_status"),
      "route_ids" => row_list_values(rows, "route_id", :stable_id) || [],
      "source_spacecraft_ids" => row_list_values(rows, "source_spacecraft_id", :stable_id) || [],
      "relay_spacecraft_ids" =>
        row_list_values(rows, "relay_chain_spacecraft_ids", :stable_id) || [],
      "ground_station_ids" => row_list_values(rows, "ground_station_id", :stable_id) || [],
      "ground_downlink_contact_ids" =>
        row_list_values(rows, "ground_downlink_contact_id", :stable_id) || [],
      "route_ids_by_custody_status" => relay_route_ids_by_field(rows, "custody_status"),
      "route_ids_by_latency_status" => relay_route_ids_by_field(rows, "latency_status"),
      "route_ids_by_risk_status" => relay_route_ids_by_field(rows, "risk_status"),
      "route_ids_by_ground_station_id" => relay_route_ids_by_field(rows, "ground_station_id"),
      "maximum_latency_s" => relay_maximum_number(rows, "latency_s"),
      "maximum_latency_limit_s" => relay_maximum_number(rows, "latency_limit_s"),
      "model_limits" => @model_limits,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
        "crosslink_visibility_model" => "not_evaluated",
        "custody_acknowledgement_delivery" => "not_performed",
        "provider_reservation" => "not_performed",
        "operator_authority" => "not_granted_by_summary"
      },
      "rows" => rows
    }
    |> compact_map()
  end

  def summary(_routes, _opts),
    do: raise(ArgumentError, "relay data path routes must be a list")

  defp relay_data_path_row(route, default_latency_limit_s) do
    source_spacecraft_id = relay_source_spacecraft_id(route)
    ground_station_id = relay_ground_station_id(route)
    ground_downlink_contact_id = relay_ground_downlink_contact_id(route)
    relay_chain_spacecraft_ids = relay_chain_spacecraft_ids(route)
    latency_s = relay_latency_s(route)
    latency_limit_s = relay_latency_limit_s(route, default_latency_limit_s)
    custody_status = relay_custody_status(route)
    latency_status = relay_latency_status(route, latency_s, latency_limit_s)
    risk_reasons = relay_risk_reasons(route, custody_status, latency_status)
    risk_status = relay_risk_status(route, custody_status, latency_status)
    product_ids = relay_stable_id_list(route, ["product_ids", "product_id"])
    collection_ids = relay_stable_id_list(route, ["collection_ids", "collection_id"])

    %{
      "route_id" =>
        relay_route_id(
          route,
          source_spacecraft_id,
          relay_chain_spacecraft_ids,
          ground_station_id,
          ground_downlink_contact_id,
          latency_s,
          latency_limit_s,
          product_ids,
          collection_ids
        ),
      "source_spacecraft_id" => source_spacecraft_id,
      "relay_chain_spacecraft_ids" => relay_chain_spacecraft_ids,
      "relay_hop_count" => length(relay_chain_spacecraft_ids),
      "ground_station_id" => ground_station_id,
      "ground_downlink_contact_id" => ground_downlink_contact_id,
      "custody_status" => custody_status,
      "latency_s" => latency_s,
      "latency_limit_s" => latency_limit_s,
      "latency_status" => latency_status,
      "risk_status" => risk_status,
      "risk_reasons" => risk_reasons,
      "product_ids" => product_ids,
      "collection_ids" => collection_ids
    }
    |> compact_map()
  end

  defp relay_route_id(
         route,
         source_spacecraft_id,
         relay_chain_spacecraft_ids,
         ground_station_id,
         ground_downlink_contact_id,
         latency_s,
         latency_limit_s,
         product_ids,
         collection_ids
       ) do
    [
      route["route_id"],
      route["id"],
      route["data_path_id"]
    ]
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> List.first()
    |> case do
      nil ->
        readable =
          [source_spacecraft_id, ground_downlink_contact_id]
          |> Enum.reject(&is_nil/1)
          |> Enum.join(":")

        fingerprint =
          [
            source_spacecraft_id,
            relay_chain_spacecraft_ids,
            ground_station_id,
            ground_downlink_contact_id,
            latency_s,
            latency_limit_s,
            product_ids,
            collection_ids
          ]
          |> :erlang.term_to_binary()
          |> then(&:crypto.hash(:sha256, &1))
          |> Base.encode16(case: :lower)
          |> binary_part(0, 12)

        ["relay_data_path", readable, fingerprint]
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.join(":")

      route_id ->
        route_id
    end
  end

  defp relay_source_spacecraft_id(route) do
    relay_first_stable_id(route, [
      ["source_spacecraft_id"],
      ["spacecraft_id"],
      ["satellite_id"],
      ["source", "spacecraft_id"],
      ["source", "satellite_id"]
    ])
  end

  defp relay_ground_station_id(route) do
    relay_first_stable_id(route, [
      ["ground_station_id"],
      ["station_id"],
      ["ground_downlink", "ground_station_id"],
      ["ground_downlink", "station_id"]
    ])
  end

  defp relay_ground_downlink_contact_id(route) do
    relay_first_stable_id(route, [
      ["ground_downlink_contact_id"],
      ["downlink_contact_id"],
      ["contact_id"],
      ["ground_downlink", "id"],
      ["ground_downlink", "contact_id"]
    ])
  end

  defp relay_chain_spacecraft_ids(route) do
    [
      route["relay_chain_spacecraft_ids"],
      route["relay_spacecraft_ids"],
      route["relay_chain"],
      route["relays"]
    ]
    |> List.flatten()
    |> Enum.map(fn
      %{} = relay ->
        relay_first_stable_id(relay, [["spacecraft_id"], ["satellite_id"], ["id"]])

      value ->
        stable_id_or_nil(value)
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp relay_latency_s(route) do
    relay_first_number(route, [
      ["latency_s"],
      ["planned_latency_s"],
      ["delivery_latency_s"],
      ["data_latency_s"],
      ["ground_downlink", "latency_s"]
    ])
  end

  defp relay_latency_limit_s(route, default_latency_limit_s) do
    relay_first_number(route, [
      ["latency_limit_s"],
      ["max_latency_s"],
      ["required_latency_s"],
      ["target_latency_s"]
    ]) || default_latency_limit_s
  end

  defp relay_custody_status(route) do
    route
    |> relay_first_string([["custody_status"], ["custody", "status"], ["status"]])
    |> normalize_relay_status(@custody_statuses, %{
      "acknowledged" => "confirmed",
      "ack" => "confirmed",
      "received" => "confirmed",
      "in_custody" => "pending",
      "pending_ack" => "pending",
      "missing" => "missing_ack",
      "missing_acknowledgement" => "missing_ack",
      "lost" => "failed"
    })
    |> case do
      nil -> "unknown"
      status -> status
    end
  end

  defp relay_latency_status(route, latency_s, latency_limit_s) do
    explicit =
      route
      |> relay_first_string([["latency_status"], ["delivery_latency_status"]])
      |> normalize_relay_status(@latency_statuses, %{
        "ok" => "within_limit",
        "satisfied" => "within_limit",
        "late" => "exceeds_limit",
        "overdue" => "exceeds_limit",
        "not evaluated" => "not_evaluated"
      })

    cond do
      is_binary(explicit) ->
        explicit

      is_number(latency_s) and is_number(latency_limit_s) and latency_s <= latency_limit_s ->
        "within_limit"

      is_number(latency_s) and is_number(latency_limit_s) ->
        "exceeds_limit"

      is_nil(latency_s) ->
        "not_evaluated"

      true ->
        "unknown"
    end
  end

  defp relay_risk_status(route, custody_status, latency_status) do
    explicit =
      route
      |> relay_first_string([["risk_status"], ["risk", "status"]])
      |> normalize_relay_status(@risk_statuses, %{
        "low" => "nominal",
        "ok" => "nominal",
        "medium" => "review",
        "requires_review" => "review",
        "blocked" => "high",
        "failed" => "high"
      })

    cond do
      is_binary(explicit) ->
        explicit

      custody_status == "failed" or latency_status == "exceeds_limit" ->
        "high"

      custody_status in ["pending", "missing_ack", "unknown"] or
          latency_status in ["not_evaluated", "unknown"] ->
        "review"

      true ->
        "nominal"
    end
  end

  defp relay_risk_reasons(route, custody_status, latency_status) do
    declared =
      route
      |> Map.get("risk_reasons", Map.get(route, "reasons", []))
      |> List.wrap()
      |> normalized_string_values()
      |> Kernel.||([])

    derived =
      []
      |> maybe_append_relay_reason(custody_status != "confirmed", "custody_#{custody_status}")
      |> maybe_append_relay_reason(latency_status != "within_limit", "latency_#{latency_status}")

    (declared ++ derived)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp maybe_append_relay_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_append_relay_reason(reasons, false, _reason), do: reasons

  defp relay_first_stable_id(route, paths) do
    paths
    |> Enum.map(&get_in(route, &1))
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> List.first()
  end

  defp relay_first_number(route, paths) do
    paths
    |> Enum.map(&get_in(route, &1))
    |> Enum.map(&numeric_value/1)
    |> Enum.reject(&is_nil/1)
    |> List.first()
  end

  defp relay_first_string(route, paths) do
    paths
    |> Enum.map(&get_in(route, &1))
    |> Enum.map(&string_value/1)
    |> Enum.reject(&is_nil/1)
    |> List.first()
  end

  defp normalize_relay_status(nil, _allowed, _aliases), do: nil

  defp normalize_relay_status(value, allowed, aliases) do
    normalized =
      value
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/[\s-]+/, "_")

    Map.get(aliases, normalized, normalized)
    |> case do
      status ->
        if status in allowed, do: status, else: "unknown"
    end
  end

  defp relay_stable_id_list(route, fields) do
    fields
    |> Enum.flat_map(fn field -> route |> Map.get(field, []) |> List.wrap() end)
    |> sorted_stable_ids()
  end

  defp relay_route_ids_by_field(rows, field) do
    rows
    |> Enum.group_by(&Map.get(&1, field), & &1["route_id"])
    |> Enum.reject(fn {value, route_ids} ->
      is_nil(value) or Enum.all?(route_ids, &is_nil(stable_id_or_nil(&1)))
    end)
    |> Map.new(fn {value, route_ids} -> {value, sorted_stable_ids(route_ids)} end)
  end

  defp relay_status_count_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp relay_maximum_number(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> Enum.max(fn -> nil end)
  end

  defp row_list_values(rows, field, :stable_id) do
    rows
    |> Enum.flat_map(&List.wrap(Map.get(&1, field)))
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp normalized_string_values(values) do
    values
    |> List.flatten()
    |> Enum.map(&string_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp string_value(value) when value in [nil, ""], do: nil

  defp string_value(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp string_value(value) when is_atom(value), do: value |> Atom.to_string() |> string_value()
  defp string_value(value) when is_integer(value), do: Integer.to_string(value)
  defp string_value(value), do: value |> to_string() |> string_value()

  defp numeric_value(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _parse_error -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp sorted_stable_ids(values) do
    values
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp stable_id_or_nil(value), do: ContactIdentity.stable_id_or_nil(value)

  defp empty_list_to_nil([]), do: nil
  defp empty_list_to_nil(values), do: values

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
