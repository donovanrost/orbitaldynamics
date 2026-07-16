defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation.Rows.RowValues.ContactSources do
  @moduledoc false

  alias __MODULE__.DirectionPairs

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation.Rows.RowValues.Normalization

  def recommendation_station_contact_pairs(recommendation, status) do
    contact_ids =
      case status do
        :selected ->
          [stable_id_or_nil(recommendation["selected_contact_id"])]

        :deferred ->
          recommendation
          |> Map.get("deferred_contact_ids", [])
          |> List.wrap()
          |> Enum.map(&stable_id_or_nil/1)
      end
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()

    contact_ids
    |> Enum.map(fn contact_id ->
      source_contact =
        recommendation
        |> source_contacts()
        |> Enum.find(&contact_match?(&1, contact_id))

      {station_id(recommendation, source_contact || %{}), contact_id}
    end)
  end

  defdelegate direction_contact_pairs(report), to: DirectionPairs

  def deferred_contacts(recommendation) do
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

  defp nested_station_id(candidate) do
    [
      get_in(candidate, ["ground_station", "id"]),
      get_in(candidate, ["station", "id"]),
      get_in(candidate, ["station", "ground_station_id"]),
      get_in(candidate, ["ground_station", "ground_station_id"])
    ]
    |> Enum.find_value(&stable_id_or_nil/1)
  end

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)

  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
