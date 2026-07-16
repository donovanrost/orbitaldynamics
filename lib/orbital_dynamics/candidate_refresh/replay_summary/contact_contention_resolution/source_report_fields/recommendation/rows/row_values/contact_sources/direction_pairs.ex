defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation.Rows.RowValues.ContactSources.DirectionPairs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation.Rows.RowValues.Normalization

  def direction_contact_pairs(report) do
    report
    |> Map.get("recommendations", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(&recommendation_direction_contact_pairs/1)
  end

  defp recommendation_direction_contact_pairs(recommendation) do
    selected_contact_id = stable_id_or_nil(recommendation["selected_contact_id"])

    deferred_contact_ids =
      recommendation
      |> Map.get("deferred_contact_ids", [])
      |> List.wrap()
      |> Enum.map(&stable_id_or_nil/1)
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    source_contacts = source_contacts(recommendation)

    pairs =
      source_contacts
      |> Enum.map(&contact_direction_pair(&1, recommendation))
      |> Enum.filter(fn {_direction, contact_id} ->
        contact_id == selected_contact_id or MapSet.member?(deferred_contact_ids, contact_id)
      end)

    case pairs do
      [] ->
        fallback_direction_contact_pairs(
          recommendation,
          selected_contact_id,
          deferred_contact_ids
        )

      pairs ->
        pairs
    end
    |> Enum.reject(fn {direction, contact_id} ->
      direction in [nil, ""] or contact_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  defp fallback_direction_contact_pairs(recommendation, selected_contact_id, deferred_contact_ids) do
    directions = recommendation_directions(recommendation)

    contact_ids =
      ([selected_contact_id] ++ MapSet.to_list(deferred_contact_ids))
      |> Enum.reject(&(&1 in [nil, ""]))

    for direction <- directions, contact_id <- contact_ids, do: {direction, contact_id}
  end

  defp contact_direction_pair(contact, recommendation) do
    direction =
      [
        contact["direction"],
        contact["type"],
        contact["activity_type"],
        get_in(contact, ["activity_context", "direction"]),
        recommendation["direction"]
      ]
      |> Enum.map(&normalize_direction/1)
      |> Enum.find(&(&1 not in [nil, "", "mixed", "contact"]))

    contact_id =
      [
        contact["id"],
        contact["contact_id"],
        contact["activity_id"],
        contact["source_activity_id"],
        get_in(contact, ["activity_context", "contact_id"]),
        get_in(contact, ["activity_context", "id"])
      ]
      |> Enum.map(&stable_id_or_nil/1)
      |> Enum.find(&(&1 not in [nil, ""]))

    {direction, contact_id}
  end

  defp recommendation_directions(recommendation) do
    [
      recommendation["directions"],
      recommendation["direction"]
    ]
    |> List.flatten()
    |> Enum.map(&normalize_direction/1)
    |> Enum.reject(&(&1 in [nil, "", "mixed", "contact"]))
    |> Enum.uniq()
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

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
  defp normalize_direction(direction), do: Normalization.normalize_direction(direction)
end
