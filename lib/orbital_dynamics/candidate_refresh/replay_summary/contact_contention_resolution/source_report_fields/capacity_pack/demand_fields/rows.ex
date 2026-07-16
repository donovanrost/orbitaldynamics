defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.CapacityPack.DemandFields.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Aggregation.Values

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.CapacityPack.Normalization

  alias __MODULE__.CapacityFraction

  def rows(report) do
    report
    |> Map.get("recommendations", [])
    |> Enum.flat_map(&recommendation_capacity_pack_demand_rows/1)
  end

  def total(rows) do
    rows
    |> Enum.map(& &1.required_capacity_fraction)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  def by_station(rows) do
    rows
    |> Enum.reduce(%{}, fn row, totals ->
      if row.ground_station_id in [nil, ""] do
        totals
      else
        Map.update(totals, row.ground_station_id, row.required_capacity_fraction, fn value ->
          value + row.required_capacity_fraction
        end)
      end
    end)
    |> Values.compact_map()
  end

  defp recommendation_capacity_pack_demand_rows(recommendation) do
    recommendation = stringify_keys(recommendation)
    candidates = source_contacts(recommendation)
    selected_contact_id = stable_id_or_nil(recommendation["selected_contact_id"])

    deferred_contact_ids =
      recommendation
      |> Map.get("deferred_contact_ids", [])
      |> List.wrap()
      |> Enum.map(&stable_id_or_nil/1)
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    candidates
    |> Enum.flat_map(fn contact ->
      contact_id =
        stable_id_or_nil(contact["id"]) ||
          stable_id_or_nil(contact["contact_id"]) ||
          stable_id_or_nil(contact["activity_id"])

      required_capacity_fraction = CapacityFraction.required_capacity_fraction(contact)

      cond do
        is_nil(contact_id) or is_nil(required_capacity_fraction) ->
          []

        contact_id == selected_contact_id ->
          [demand_row(contact, :selected, required_capacity_fraction)]

        MapSet.member?(deferred_contact_ids, contact_id) ->
          [demand_row(contact, :deferred, required_capacity_fraction)]

        true ->
          []
      end
    end)
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

  defp demand_row(contact, status, required_capacity_fraction) do
    %{
      status: status,
      ground_station_id:
        stable_id_or_nil(contact["ground_station_id"]) || stable_id_or_nil(contact["station_id"]),
      required_capacity_fraction: required_capacity_fraction
    }
  end

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)

  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
