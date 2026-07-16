defmodule OrbitalDynamics.CandidateRefresh.SourceObjectives.ContactContentionResolution do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def objectives(source_reports) when is_list(source_reports) do
    Enum.flat_map(source_reports, fn {path, report} ->
      report
      |> Map.get("recommendations", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {recommendation, index} ->
        recommendation =
          Map.put_new(
            recommendation,
            "_source_report_trust_boundary",
            result_artifact_trust_boundary(report)
          )

        recommendation_objectives(path, recommendation, index)
      end)
    end)
  end

  def objectives(_source_reports), do: []

  defp recommendation_objectives(path, recommendation, index) do
    recommendation = stringify_keys(recommendation)

    recommendation
    |> deferred_contacts()
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {source_contact, contact_index} ->
      deferred_contact_objectives(
        path,
        recommendation,
        source_contact,
        index,
        contact_index
      )
    end)
  end

  defp deferred_contact_objectives(
         path,
         recommendation,
         source_contact,
         recommendation_index,
         contact_index
       ) do
    required_downlink_mb = required_downlink_mb(recommendation, source_contact)
    station_id = station_id(recommendation, source_contact)

    if downlink_candidate?(recommendation, source_contact) and
         positive_number_value?(required_downlink_mb) and station_id not in [nil, ""] do
      [
        %{
          "id" =>
            objective_id(
              path,
              recommendation,
              source_contact,
              recommendation_index,
              contact_index,
              "downlink_completion"
            ),
          "type" => "downlink_completion",
          "scenario_id" =>
            stable_id_or_nil(source_contact["scenario_id"] || recommendation["scenario_id"]),
          "spacecraft_id" =>
            stable_id_or_nil(source_contact["spacecraft_id"] || recommendation["spacecraft_id"]),
          "ground_station_id" => station_id,
          "required_downlink_mb" => required_downlink_mb,
          "source" => "contact_contention_resolution_report.recommendations",
          "source_path" => path,
          "source_contention_group_id" => stable_id_or_nil(recommendation["group_id"]),
          "source_selected_contact_id" => stable_id_or_nil(recommendation["selected_contact_id"]),
          "source_contact_id" =>
            stable_id_or_nil(
              source_contact["id"] || source_contact["contact_id"] ||
                source_contact["activity_id"]
            ),
          "source_selection_reason" => recommendation["selection_reason"],
          "source_resolution_status" => recommendation["resolution_status"],
          "source_review_status" => recommendation["review_status"],
          "source_policy_classification" =>
            get_in(recommendation, ["policy_decision", "classification"]) ||
              get_in(recommendation, ["source_policy_decision", "classification"]),
          "source_activity_ids" => source_activity_ids(recommendation, source_contact),
          "source_window_id" => source_window_id(recommendation, source_contact),
          "source_window_ids" => source_window_ids(recommendation, source_contact),
          "trust_boundary" => trust_boundary(recommendation)
        }
        |> compact_map()
      ]
    else
      []
    end
  end

  defp deferred_contacts(recommendation) do
    recommendation = stringify_keys(recommendation)
    deferred_ids = Map.get(recommendation, "deferred_contact_ids", [])
    candidates = source_contacts(recommendation)

    contacts =
      deferred_ids
      |> List.wrap()
      |> Enum.map(&stable_id_or_nil/1)
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.map(fn contact_id ->
        contact =
          Enum.find(candidates, &contact_match?(&1, contact_id)) ||
            %{"id" => contact_id}

        contact
        |> stringify_keys()
        |> Map.put_new("id", contact_id)
      end)

    case contacts do
      [] ->
        recommendation
        |> source_contact()
        |> case do
          %{} = contact -> [contact]
          _contact -> []
        end

      contacts ->
        contacts
    end
  end

  defp source_contacts(recommendation) do
    [
      recommendation["source_contact_candidates"],
      recommendation["contact_candidates"],
      recommendation["source_contacts"],
      recommendation["contacts"]
    ]
    |> List.flatten()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
  end

  defp source_contact(recommendation) do
    cond do
      is_map(recommendation["source_contact"]) ->
        recommendation["source_contact"] |> stringify_keys()

      is_map(recommendation["contact_candidate"]) ->
        recommendation["contact_candidate"] |> stringify_keys()

      true ->
        %{}
    end
  end

  defp contact_match?(%{} = contact, contact_id) do
    [
      contact["id"],
      contact["contact_id"],
      contact["activity_id"],
      contact["source_activity_id"]
    ]
    |> Enum.any?(&(stable_id_or_nil(&1) == contact_id))
  end

  defp downlink_candidate?(recommendation, source_contact) do
    recommendation = stringify_keys(recommendation)
    source_contact = stringify_keys(source_contact || %{})

    downlink_direction? =
      [
        source_contact["type"],
        source_contact["activity_type"],
        source_contact["direction"],
        recommendation["direction"]
      ]
      |> Enum.any?(&(normalized_token(&1) == "downlink"))

    downlink_direction? or
      positive_number_value?(required_downlink_mb(recommendation, source_contact))
  end

  defp required_downlink_mb(recommendation, source_contact) do
    first_positive_number(source_contact, [
      "selected_downlink_shortfall_mb",
      "required_downlink_mb",
      "candidate_downlink_mb",
      "estimated_throughput_mb",
      "planned_throughput_mb",
      ["throughput_model", "required_downlink_mb"],
      ["throughput_model", "estimated_throughput_mb"],
      ["throughput_model", "planned_throughput_mb"]
    ]) ||
      first_positive_number(recommendation, [
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

  defp station_id(recommendation, source_contact) do
    [
      source_contact["ground_station_id"],
      source_contact["station_id"],
      nested_station_id(source_contact),
      recommendation["ground_station_id"],
      recommendation["station_id"],
      nested_station_id(recommendation)
    ]
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp source_activity_ids(recommendation, source_contact) do
    [
      source_contact["id"],
      source_contact["contact_id"],
      source_contact["activity_id"],
      source_contact["source_activity_id"],
      recommendation["selected_contact_id"]
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

  defp source_window_id(recommendation, source_contact) do
    case source_window_ids(recommendation, source_contact) do
      [source_window_id] -> source_window_id
      _source_window_ids -> nil
    end
  end

  defp source_window_ids(recommendation, source_contact) do
    [
      source_contact["source_window_id"],
      source_contact["source_window_ids"],
      get_in(source_contact, ["source_window", "id"]),
      get_in(source_contact, ["activity_context", "source_window_id"]),
      recommendation["source_window_id"],
      recommendation["source_window_ids"]
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

  defp trust_boundary(recommendation) do
    Map.get(recommendation, "trust_boundary") ||
      get_in(recommendation, ["provenance", "trust_boundary"]) ||
      get_in(recommendation, ["source_recommendation", "trust_boundary"]) ||
      get_in(recommendation, ["source_recommendation", "provenance", "trust_boundary"]) ||
      recommendation["_source_report_trust_boundary"]
  end

  defp objective_id(
         path,
         recommendation,
         source_contact,
         recommendation_index,
         contact_index,
         type
       ) do
    base =
      stable_id_or_nil(
        source_contact["id"] ||
          source_contact["contact_id"] ||
          source_contact["activity_id"] ||
          recommendation["group_id"]
      ) || "#{type}:#{recommendation_index}:#{contact_index}"

    hash =
      :crypto.hash(
        :sha256,
        :erlang.term_to_binary(
          {path, recommendation, source_contact, recommendation_index, contact_index, type}
        )
      )
      |> Base.encode16(case: :lower)
      |> binary_part(0, 8)

    ["contact_contention_resolution", type, base, hash]
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
