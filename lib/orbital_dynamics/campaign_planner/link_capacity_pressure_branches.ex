defmodule OrbitalDynamics.CampaignPlanner.LinkCapacityPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityTiming,
    ContactAllocationPressureBranches,
    DownlinkActivityNormalization,
    ScalarValues,
    ValueEncoding
  }

  def from_reports(reports, callbacks \\ default_callbacks()) do
    Enum.flat_map(reports, fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> rows(callbacks)
      |> Enum.map(&Map.put(&1, "_source_report_trust_boundary", trust_boundary))
      |> Enum.flat_map(&build(&1, source_path, callbacks))
    end)
  end

  def rows(report, callbacks \\ default_callbacks())

  def rows(%{"rows" => rows} = report, callbacks) when is_list(rows) do
    if relay_data_path_summary_source?(report) do
      relay_data_path_pressure_rows(report, callbacks)
    else
      rows =
        rows
        |> Enum.map(&stringify_keys(&1, callbacks))
        |> Enum.map(&Map.put_new(&1, "source_report", "rows"))

      if Enum.any?(rows, &pressure_row?(&1, callbacks)) do
        rows
      else
        [Map.put(report, "source_report", "top_level")]
      end
    end
  end

  def rows(%{} = report, callbacks) do
    if relay_data_path_summary_source?(report) do
      relay_data_path_pressure_rows(report, callbacks)
    else
      [Map.put(report, "source_report", "top_level")]
    end
  end

  def build(row, source_path, callbacks \\ default_callbacks()) do
    event = pressure_event(row, source_path, callbacks)

    if is_nil(event) do
      []
    else
      branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
      compact_map = Keyword.fetch!(callbacks, :compact_map)
      station_id = ground_station_id(row, callbacks) || "all_stations"

      [
        %{
          "id" => "derived_link_capacity_pressure_#{branch_id_fragment.(station_id)}",
          "label" => "Derived link capacity pressure #{station_id}",
          "events" => [event],
          "metadata" =>
            %{
              "derived_source" => source_path,
              "link_capacity_source_report" => row["source_report"],
              "downlink_requirement_status" => row["downlink_requirement_status"],
              "actual_downlink_completion_ratio" => row["actual_downlink_completion_ratio"],
              "actual_downlink_requirement_status" => row["actual_downlink_requirement_status"]
            }
            |> compact_map.()
        }
      ]
    end
  end

  def disambiguate(branches, callbacks \\ default_callbacks()) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      branch_id = branch["id"]

      if Map.get(id_counts, branch_id, 0) <= 1 do
        branch
      else
        suffix =
          branch
          |> branch_identity(index, callbacks)
          |> branch_id_fragment.()

        branch
        |> Map.put("id", "#{branch_id}_#{suffix}")
        |> Map.update("metadata", %{}, fn metadata ->
          metadata
          |> Map.put("link_capacity_branch_base_id", branch_id)
          |> Map.put("link_capacity_branch_identity", suffix)
        end)
      end
    end)
  end

  def pressure_row?(row), do: pressure_row?(row, pressure_row_callbacks())

  def pressure_row?(row, callbacks) do
    row
    |> shortfall_mb(callbacks)
    |> positive_number?(callbacks)
  end

  defp relay_data_path_pressure_rows(%{} = report, callbacks) do
    report = stringify_keys(report, callbacks)

    rows =
      report
      |> Map.get("rows", [])
      |> List.wrap()
      |> Enum.map(&stringify_keys(&1, callbacks))
      |> Enum.filter(&relay_data_path_pressure_row?/1)
      |> Enum.map(&relay_data_path_pressure_row(&1, report))

    if rows == [] and relay_data_path_pressure_row?(report) do
      [relay_data_path_pressure_row(report, report)]
    else
      rows
    end
  end

  defp relay_data_path_pressure_row(row, report) do
    row
    |> Map.put_new("source_report", "relay_data_path_summary.rows")
    |> Map.put("_relay_data_path_summary", true)
    |> Map.put("_relay_data_path_summary_assumptions", Map.get(report, "assumptions"))
    |> Map.put("_relay_data_path_summary_route_count", Map.get(report, "route_count"))
    |> Map.put("_relay_data_path_summary_relay_route_count", Map.get(report, "relay_route_count"))
    |> Map.put(
      "_relay_data_path_summary_direct_downlink_route_count",
      Map.get(report, "direct_downlink_route_count")
    )
    |> Map.put(
      "_relay_data_path_summary_custody_status_counts",
      Map.get(report, "custody_status_counts")
    )
    |> Map.put(
      "_relay_data_path_summary_latency_status_counts",
      Map.get(report, "latency_status_counts")
    )
    |> Map.put(
      "_relay_data_path_summary_risk_status_counts",
      Map.get(report, "risk_status_counts")
    )
    |> Map.put(
      "_relay_data_path_summary_route_ids_by_custody_status",
      Map.get(report, "route_ids_by_custody_status")
    )
    |> Map.put(
      "_relay_data_path_summary_route_ids_by_latency_status",
      Map.get(report, "route_ids_by_latency_status")
    )
    |> Map.put(
      "_relay_data_path_summary_route_ids_by_risk_status",
      Map.get(report, "route_ids_by_risk_status")
    )
    |> Map.put(
      "_relay_data_path_summary_route_ids_by_ground_station_id",
      Map.get(report, "route_ids_by_ground_station_id")
    )
  end

  defp relay_data_path_summary_source?(%{} = report) do
    Map.get(report, "schema_contract") == "relay_data_path_summary.v1" or
      Map.get(report, "source_summary_schema_contract") == "relay_data_path_summary.v1" or
      Map.get(report, "model") == "artifact_only_relay_data_path_summary" or
      Map.get(report, "source_summary_model") == "artifact_only_relay_data_path_summary"
  end

  defp branch_identity(branch, index, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)
    event = branch |> Map.get("events", []) |> List.wrap() |> List.first() || %{}

    [
      event["source_window_id"],
      event["source_window_ids"],
      event["source_activity_ids"],
      event["route_id"],
      event["ground_downlink_contact_id"],
      event["downlink_completion_source"],
      event["downlink_completion_sources"],
      event["required_downlink_mb"],
      index
    ]
    |> List.flatten()
    |> Enum.map(&encode_value.(&1))
    |> Enum.find(&stable_id_string?.(&1))
  end

  defp pressure_event(%{"_relay_data_path_summary" => true} = row, source_path, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    %{
      "type" => "relay_data_path_pressure",
      "ground_station_id" => ground_station_id(row, callbacks),
      "route_id" => row["route_id"],
      "route_ids" => relay_data_path_pressure_route_ids(row, callbacks),
      "source_spacecraft_id" => row["source_spacecraft_id"],
      "source_spacecraft_ids" => relay_data_path_pressure_source_spacecraft_ids(row, callbacks),
      "relay_spacecraft_ids" => relay_data_path_pressure_relay_spacecraft_ids(row, callbacks),
      "relay_chain_spacecraft_ids" =>
        relay_data_path_pressure_relay_chain_spacecraft_ids(row, callbacks),
      "relay_hop_count" => numeric_or_nil.(row["relay_hop_count"]),
      "ground_downlink_contact_id" => row["ground_downlink_contact_id"],
      "ground_downlink_contact_ids" =>
        relay_data_path_pressure_ground_downlink_contact_ids(row, callbacks),
      "custody_status" => row["custody_status"],
      "latency_s" => numeric_or_nil.(row["latency_s"]),
      "latency_limit_s" => numeric_or_nil.(row["latency_limit_s"]),
      "latency_status" => row["latency_status"],
      "risk_status" => row["risk_status"],
      "risk_reasons" => relay_data_path_pressure_risk_reasons(row, callbacks),
      "product_ids" =>
        relay_data_path_pressure_values(row, ["product_id", "product_ids"], callbacks),
      "collection_ids" =>
        relay_data_path_pressure_values(row, ["collection_id", "collection_ids"], callbacks),
      "route_count" => numeric_or_nil.(row["_relay_data_path_summary_route_count"]),
      "relay_route_count" => numeric_or_nil.(row["_relay_data_path_summary_relay_route_count"]),
      "direct_downlink_route_count" =>
        numeric_or_nil.(row["_relay_data_path_summary_direct_downlink_route_count"]),
      "custody_status_counts" => row["_relay_data_path_summary_custody_status_counts"],
      "latency_status_counts" => row["_relay_data_path_summary_latency_status_counts"],
      "risk_status_counts" => row["_relay_data_path_summary_risk_status_counts"],
      "route_ids_by_custody_status" =>
        row["_relay_data_path_summary_route_ids_by_custody_status"],
      "route_ids_by_latency_status" =>
        row["_relay_data_path_summary_route_ids_by_latency_status"],
      "route_ids_by_risk_status" => row["_relay_data_path_summary_route_ids_by_risk_status"],
      "route_ids_by_ground_station_id" =>
        row["_relay_data_path_summary_route_ids_by_ground_station_id"],
      "derivation_reasons" => relay_data_path_pressure_reasons(row, callbacks),
      "feedback_source" => source_path,
      "feedback_scope" => "link_capacity",
      "feedback_key" => row["route_id"] || row["ground_downlink_contact_id"],
      "trust_boundary" => trust_boundary(row),
      "assumptions" => row["_relay_data_path_summary_assumptions"]
    }
    |> compact_map.()
  end

  defp pressure_event(row, source_path, callbacks) do
    shortfall = shortfall_mb(row, callbacks)

    if not (is_number(shortfall) and shortfall > 0.0) do
      nil
    else
      compact_map = Keyword.fetch!(callbacks, :compact_map)

      %{
        "type" => "downlink_completion_gap",
        "ground_station_id" => ground_station_id(row, callbacks),
        "required_contacts" => 1,
        "planned_contacts" => planned_contacts(row, callbacks),
        "required_downlink_mb" => shortfall,
        "planned_downlink_mb" => 0.0,
        "starts_at_s" => start_s(row, callbacks),
        "ends_at_s" => end_s(row, callbacks),
        "source_activity_ids" => source_contact_ids(row, callbacks),
        "source_window_id" => source_window_id(row, callbacks),
        "source_window_ids" => source_window_ids(row, callbacks),
        "derivation_reasons" => pressure_reasons(row, callbacks),
        "feedback_source" => source_path,
        "feedback_scope" => "link_capacity",
        "trust_boundary" => trust_boundary(row),
        "selected_capacity_adjusted_throughput_mb" =>
          row["selected_capacity_adjusted_throughput_mb"],
        "selected_downlink_shortfall_mb" => row["selected_downlink_shortfall_mb"],
        "actual_throughput_mb" => row["actual_throughput_mb"],
        "actual_downlink_completion_ratio" => row["actual_downlink_completion_ratio"],
        "actual_downlink_shortfall_mb" => row["actual_downlink_shortfall_mb"],
        "downlink_requirement_status" => row["downlink_requirement_status"],
        "actual_downlink_requirement_status" => row["actual_downlink_requirement_status"],
        "downlink_completion_source" => row["downlink_completion_source"],
        "downlink_demand_sources" => downlink_demand_sources(row, callbacks),
        "downlink_completion_sources" => downlink_completion_sources(row, callbacks)
      }
      |> compact_map.()
    end
  end

  defp ground_station_id(row, callbacks) do
    nested_ground_station_id = Keyword.fetch!(callbacks, :nested_ground_station_id)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    [
      row["ground_station_id"],
      row["station_id"],
      nested_ground_station_id.(row)
    ]
    |> Enum.find(&stable_id_string?.(&1))
  end

  defp start_s(row, callbacks) do
    activity_raw_start = Keyword.fetch!(callbacks, :activity_raw_start)

    activity_raw_start.(row) || 0.0
  end

  defp end_s(row, callbacks) do
    activity_raw_end = Keyword.fetch!(callbacks, :activity_raw_end)

    activity_raw_end.(row)
  end

  defp relay_data_path_pressure_row?(row) do
    custody_status = row["custody_status"]
    latency_status = row["latency_status"]
    risk_status = row["risk_status"]

    Enum.any?([
      custody_status not in [nil, "", "confirmed", "acknowledged", "delivered", "nominal"],
      latency_status not in [nil, "", "within_limit", "nominal", "on_time"],
      risk_status not in [nil, "", "nominal", "low"]
    ])
  end

  defp shortfall_mb(row, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    positive_number? = Keyword.fetch!(callbacks, :positive_number?)

    [
      row["selected_downlink_shortfall_mb"],
      row["actual_downlink_shortfall_mb"]
    ]
    |> Enum.map(&numeric_or_nil.(&1))
    |> Enum.find(&positive_number?.(&1))
  end

  defp source_contact_ids(row, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    row
    |> source_contact_values()
    |> Enum.map(&source_contact_id(&1, callbacks))
    |> Enum.filter(&stable_id_string?.(&1))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp planned_contacts(row, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    case numeric_or_nil.(row["selected_contact_count"]) do
      value when is_number(value) ->
        value

      _value ->
        row
        |> selected_contact_values()
        |> Enum.map(&source_contact_id(&1, callbacks))
        |> Enum.filter(&stable_id_string?.(&1))
        |> Enum.uniq()
        |> length()
    end
  end

  defp selected_contact_values(row) do
    [
      row["selected_contact_ids"],
      row["selected_contact_id"],
      row["selected_contacts"],
      row["selected_contact"]
    ]
    |> List.flatten()
  end

  defp source_contact_values(row) do
    [
      row["selected_contact_ids"],
      row["selected_contact_id"],
      row["actual_throughput_contact_ids"],
      row["actual_throughput_contact_id"],
      row["actual_completion_contact_ids"],
      row["actual_completion_contact_id"],
      row["required_downlink_contact_ids"],
      row["required_downlink_contact_id"],
      row["contact_ids"],
      row["contact_id"],
      row["selected_contacts"],
      row["selected_contact"],
      row["actual_throughput_contacts"],
      row["actual_throughput_contact"],
      row["actual_completion_contacts"],
      row["actual_completion_contact"],
      row["required_downlink_contacts"],
      row["required_downlink_contact"],
      row["source_contacts"],
      row["source_contact"],
      row["contacts"],
      row["contact"]
    ]
    |> List.flatten()
  end

  defp source_contact_id(%{} = contact, callbacks) do
    contact_identity = Keyword.fetch!(callbacks, :contact_identity)

    contact
    |> stringify_keys(callbacks)
    |> contact_identity.()
  end

  defp source_contact_id(value, _callbacks), do: value

  defp source_window_id(row, callbacks) do
    case source_window_ids(row, callbacks) do
      [source_window_id] -> source_window_id
      _source_window_ids -> nil
    end
  end

  defp source_window_ids(row, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    [
      row["source_window_id"],
      row["source_window_ids"],
      get_in(row, ["source_window", "id"]),
      get_in(row, ["activity_context", "source_window_id"]),
      source_contact_window_ids(row, callbacks)
    ]
    |> List.flatten()
    |> Enum.map(&encode_value.(&1))
    |> Enum.filter(&stable_id_string?.(&1))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      source_window_ids -> source_window_ids
    end
  end

  defp source_contact_window_ids(row, callbacks) do
    activity_source_window_id = Keyword.fetch!(callbacks, :activity_source_window_id)

    row
    |> source_contact_values()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys(&1, callbacks))
    |> Enum.flat_map(fn contact ->
      [
        activity_source_window_id.(contact),
        get_in(contact, ["activity_context", "source_window_id"])
      ]
    end)
  end

  defp downlink_demand_sources(row, callbacks) do
    [
      row["downlink_demand_source"],
      row["downlink_demand_sources"],
      source_contact_downlink_demand_sources(row, callbacks)
    ]
    |> normalize_downlink_source_list(callbacks)
    |> case do
      [] -> downlink_completion_sources(row, callbacks)
      sources -> sources
    end
  end

  defp downlink_completion_sources(row, callbacks) do
    [
      row["downlink_completion_source"],
      row["downlink_completion_sources"],
      source_contact_downlink_completion_sources(row, callbacks)
    ]
    |> normalize_downlink_source_list(callbacks)
    |> case do
      [] -> nil
      sources -> sources
    end
  end

  defp source_contact_downlink_demand_sources(row, callbacks) do
    row
    |> source_contact_values()
    |> source_contact_downlink_sources(
      [
        "downlink_demand_source",
        "downlink_demand_sources"
      ],
      callbacks
    )
  end

  defp source_contact_downlink_completion_sources(row, callbacks) do
    row
    |> source_contact_values()
    |> source_contact_downlink_sources(
      [
        "downlink_completion_source",
        "downlink_completion_sources"
      ],
      callbacks
    )
  end

  defp source_contact_downlink_sources(values, fields, callbacks) do
    values
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys(&1, callbacks))
    |> Enum.flat_map(fn contact ->
      Enum.flat_map(fields, fn field ->
        [
          contact[field],
          get_in(contact, ["throughput_model", field]),
          get_in(contact, ["activity_context", field])
        ]
      end)
    end)
  end

  defp normalize_downlink_source_list(values, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    values
    |> List.flatten()
    |> Enum.map(&encode_value.(&1))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp pressure_reasons(row, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    positive_number? = Keyword.fetch!(callbacks, :positive_number?)

    []
    |> maybe_append_reason(
      positive_number?.(numeric_or_nil.(row["selected_downlink_shortfall_mb"])),
      "link_capacity_selected_downlink_shortfall"
    )
    |> maybe_append_reason(
      positive_number?.(numeric_or_nil.(row["actual_downlink_shortfall_mb"])),
      "link_capacity_actual_downlink_shortfall"
    )
    |> Enum.reverse()
  end

  defp relay_data_path_pressure_reasons(row, callbacks) do
    []
    |> maybe_append_reason(
      row["custody_status"] not in [nil, "", "confirmed", "acknowledged", "delivered", "nominal"],
      "relay_data_path_custody_#{row["custody_status"]}"
    )
    |> maybe_append_reason(
      row["latency_status"] not in [nil, "", "within_limit", "nominal", "on_time"],
      "relay_data_path_latency_#{row["latency_status"]}"
    )
    |> maybe_append_reason(
      row["risk_status"] not in [nil, "", "nominal", "low"],
      "relay_data_path_risk_#{row["risk_status"]}"
    )
    |> Enum.reverse()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Kernel.++(relay_data_path_pressure_risk_reasons(row, callbacks) || [])
    |> Enum.uniq()
  end

  defp maybe_append_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_append_reason(reasons, false, _reason), do: reasons

  defp relay_data_path_pressure_route_ids(row, callbacks),
    do: relay_data_path_pressure_values(row, ["route_id", "route_ids"], callbacks)

  defp relay_data_path_pressure_source_spacecraft_ids(row, callbacks),
    do:
      relay_data_path_pressure_values(
        row,
        ["source_spacecraft_id", "source_spacecraft_ids"],
        callbacks
      )

  defp relay_data_path_pressure_relay_spacecraft_ids(row, callbacks) do
    relay_data_path_pressure_values(
      row,
      [
        "relay_spacecraft_id",
        "relay_spacecraft_ids",
        "relay_chain_spacecraft_ids"
      ],
      callbacks
    )
  end

  defp relay_data_path_pressure_relay_chain_spacecraft_ids(row, callbacks),
    do: relay_data_path_pressure_values(row, ["relay_chain_spacecraft_ids"], callbacks)

  defp relay_data_path_pressure_ground_downlink_contact_ids(row, callbacks) do
    relay_data_path_pressure_values(
      row,
      [
        "ground_downlink_contact_id",
        "ground_downlink_contact_ids"
      ],
      callbacks
    )
  end

  defp relay_data_path_pressure_risk_reasons(row, callbacks),
    do: relay_data_path_pressure_values(row, ["risk_reason", "risk_reasons"], callbacks)

  defp relay_data_path_pressure_values(row, fields, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    fields
    |> Enum.flat_map(fn field -> row |> Map.get(field) |> List.wrap() end)
    |> Enum.map(&encode_value.(&1))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_link_capacity", "trust_boundary"]) ||
      get_in(row, ["source_link_capacity", "provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp stringify_keys(value, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    stringify_keys.(value)
  end

  defp positive_number?(value, callbacks) do
    positive_number? = Keyword.fetch!(callbacks, :positive_number?)

    positive_number?.(value)
  end

  defp default_callbacks do
    [
      activity_raw_end: &ActivityTiming.activity_raw_end/1,
      activity_raw_start: &ActivityTiming.activity_raw_start/1,
      activity_source_window_id: &activity_source_window_id/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      compact_map: &ValueEncoding.compact_map/1,
      contact_identity: &ContactAllocationPressureBranches.contact_identity/1,
      encode_value: &ValueEncoding.encode_value/1,
      nested_ground_station_id: &DownlinkActivityNormalization.nested_ground_station_id/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      positive_number?: &ScalarValues.positive_number?/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end

  defp activity_source_window_id(activity) do
    activity["source_window_id"] ||
      get_in(activity, ["source_window", "id"]) ||
      get_in(activity, ["metadata", "source_window_id"])
  end

  defp pressure_row_callbacks do
    [
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      positive_number?: &ScalarValues.positive_number?/1
    ]
  end
end
