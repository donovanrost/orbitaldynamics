defmodule OrbitalDynamics.CandidateRefresh.SourceObjectives.ContactAllocation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def objectives(source_reports) when is_list(source_reports) do
    Enum.flat_map(source_reports, fn {path, report} ->
      report
      |> Map.get("rows", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {row, index} ->
        row =
          Map.put_new(
            row,
            "_source_report_trust_boundary",
            result_artifact_trust_boundary(report)
          )

        row_objectives(path, row, index)
      end)
    end)
  end

  def objectives(_source_reports), do: []

  defp row_objectives(path, row, index) do
    row = row |> stringify_keys() |> normalize_row()

    if downlink_pressure?(row) do
      downlink_objectives(path, row, index)
    else
      []
    end
  end

  defp downlink_objectives(path, row, index) do
    source_contact = source_contact(row)
    required_downlink_mb = required_downlink_mb(row, source_contact)
    station_id = station_id(row, source_contact)

    if positive_number_value?(required_downlink_mb) and station_id not in [nil, ""] do
      [
        %{
          "id" => objective_id(path, row, index, "downlink_completion"),
          "type" => "downlink_completion",
          "scenario_id" => stable_id_or_nil(row["scenario_id"] || source_contact["scenario_id"]),
          "spacecraft_id" =>
            stable_id_or_nil(row["spacecraft_id"] || source_contact["spacecraft_id"]),
          "ground_station_id" => station_id,
          "required_downlink_mb" => required_downlink_mb,
          "source" => "contact_allocation_report.rows",
          "source_path" => path,
          "source_contact_id" => contact_id(row, source_contact),
          "source_allocation_status" => row["allocation_status"],
          "source_effective_allocation_status" => row["effective_allocation_status"],
          "source_allocation_reason" => row["allocation_reason"],
          "source_review_status" => row["review_status"],
          "source_approval_status" => row["approval_status"],
          "source_policy_classification" => get_in(row, ["policy_decision", "classification"]),
          "source_activity_ids" => source_activity_ids(row, source_contact),
          "source_window_id" => source_window_id(row, source_contact),
          "source_window_ids" => source_window_ids(row, source_contact),
          "trust_boundary" => trust_boundary(row)
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  defp normalize_row(row) do
    row
    |> normalize_status_field("allocation_status")
    |> normalize_status_field("effective_allocation_status")
    |> normalize_status_field("review_status")
    |> normalize_status_field("approval_status")
    |> normalize_policy_decision()
  end

  defp normalize_status_field(row, field) do
    case Map.get(row, field) do
      value when value in [nil, ""] -> row
      value -> Map.put(row, field, normalized_token(value))
    end
  end

  defp normalize_policy_decision(%{"policy_decision" => %{} = decision} = row) do
    decision =
      decision
      |> stringify_keys()
      |> normalize_status_field("classification")

    Map.put(row, "policy_decision", decision)
  end

  defp normalize_policy_decision(row), do: row

  defp downlink_pressure?(row) do
    status = effective_status(row)

    status in ["deferred", "blocked", "policy_blocked", "blocked_by_policy"] and
      downlink_row?(row) and
      positive_number_value?(required_downlink_mb(row, source_contact(row))) and
      station_id(row, source_contact(row)) not in [nil, ""]
  end

  defp effective_status(row) do
    Map.get(row, "effective_allocation_status") ||
      Map.get(row, "allocation_status") ||
      Map.get(row, "approval_status") ||
      get_in(row, ["policy_decision", "classification"])
  end

  defp downlink_row?(row) do
    downlink_candidate?(row) or downlink_candidate?(source_contact(row))
  end

  defp downlink_candidate?(%{} = row) do
    type =
      row["type"] ||
        row["activity_type"] ||
        get_in(row, ["activity_context", "type"])

    direction =
      row["direction"] ||
        get_in(row, ["activity_context", "direction"])

    type in ["downlink", :downlink] or direction in ["downlink", :downlink]
  end

  defp downlink_candidate?(_row), do: false

  defp source_contact(row) do
    contact_id = contact_id(row, %{})

    cond do
      is_map(row["source_contact_candidate"]) ->
        stringify_keys(row["source_contact_candidate"])

      source_contact = direct_source_contact(row, contact_id) ->
        source_contact

      is_list(get_in(row, ["source_contention_recommendation", "source_contact_candidates"])) ->
        row
        |> get_in(["source_contention_recommendation", "source_contact_candidates"])
        |> Enum.map(&stringify_keys/1)
        |> Enum.find(%{}, &contact_match?(&1, contact_id))

      true ->
        %{}
    end
  end

  defp direct_source_contact(row, contact_id) do
    [
      row["source_contact"],
      row["contact_candidate"],
      row["contact"],
      row["source_contacts"],
      row["contact_candidates"],
      row["contacts"]
    ]
    |> List.flatten()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
    |> Enum.find(&contact_match?(&1, contact_id))
  end

  defp contact_match?(contact, contact_id) do
    contact_id in [nil, ""] or contact_id(contact, %{}) == contact_id
  end

  defp contact_id(row, source_contact) do
    [
      row["contact_id"],
      row["activity_id"],
      row["source_activity_id"],
      row["downlink_activity_id"],
      row["id"],
      source_contact["contact_id"],
      source_contact["activity_id"],
      source_contact["source_activity_id"],
      source_contact["downlink_activity_id"],
      source_contact["id"]
    ]
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp required_downlink_mb(row, source_contact) do
    first_positive_number(row, [
      "selected_downlink_shortfall_mb",
      "required_downlink_mb",
      "candidate_downlink_mb",
      "estimated_throughput_mb",
      "planned_throughput_mb",
      ["throughput_model", "required_downlink_mb"],
      ["throughput_model", "estimated_throughput_mb"],
      ["throughput_model", "planned_throughput_mb"]
    ]) ||
      first_positive_number(source_contact, [
        "selected_downlink_shortfall_mb",
        "required_downlink_mb",
        "candidate_downlink_mb",
        "estimated_throughput_mb",
        "planned_throughput_mb",
        ["throughput_model", "required_downlink_mb"],
        ["throughput_model", "estimated_throughput_mb"],
        ["throughput_model", "planned_throughput_mb"]
      ])
  end

  defp station_id(row, source_contact) do
    [
      row["ground_station_id"],
      row["station_id"],
      nested_station_id(row),
      source_contact["ground_station_id"],
      source_contact["station_id"],
      nested_station_id(source_contact)
    ]
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp source_activity_ids(row, source_contact) do
    [
      contact_id(row, source_contact),
      row["source_activity_ids"],
      row["deferred_contact_ids"],
      source_contact["source_activity_ids"]
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp source_window_id(row, source_contact) do
    case source_window_ids(row, source_contact) do
      [source_window_id] -> source_window_id
      _source_window_ids -> nil
    end
  end

  defp source_window_ids(row, source_contact) do
    [
      row["source_window_id"],
      row["source_window_ids"],
      get_in(row, ["source_window", "id"]),
      get_in(row, ["activity_context", "source_window_id"]),
      source_contact["source_window_id"],
      source_contact["source_window_ids"],
      get_in(source_contact, ["source_window", "id"]),
      get_in(source_contact, ["activity_context", "source_window_id"])
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      Map.get(row, "resource_trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_contact_allocation", "trust_boundary"]) ||
      get_in(row, ["source_contact_allocation", "provenance", "trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp objective_id(path, row, index, type) do
    base =
      contact_id(row, source_contact(row)) ||
        stable_id_or_nil(row["id"]) ||
        "#{type}:#{index}"

    hash =
      :crypto.hash(:sha256, :erlang.term_to_binary({path, row, index, type}))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 8)

    ["contact_allocation", type, base, hash]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(":")
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp first_positive_number(row, paths) do
    paths
    |> Enum.find_value(fn path ->
      case number(row, path) do
        value when is_number(value) and value > 0.0 -> value
        _value -> nil
      end
    end)
  end

  defp number(row, path) when is_list(path), do: row |> get_in(path) |> numeric_value()
  defp number(row, path), do: row |> Map.get(path) |> numeric_value()

  defp nested_station_id(candidate) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(candidate, station_key) do
        %{} = station ->
          station = stringify_keys(station)

          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end

  defp positive_number_value?(value), do: is_number(value) and value > 0.0

  defp stable_id_or_nil(value), do: ValueEncoding.stable_id_or_nil(value)
  defp stringify_keys(value), do: ValueEncoding.stringify_keys(value)
  defp normalized_token(value), do: ValueEncoding.normalized_token(value)
  defp numeric_value(value), do: ValueEncoding.numeric_value(value)
  defp compact_map(map), do: ValueEncoding.compact_nil_values(map)
end
