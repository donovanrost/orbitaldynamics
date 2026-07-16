defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation.ContactFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Aggregation.Values

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation.Rows,
    only: [
      deferred_contacts: 1,
      grouped_ids: 1,
      map_value_lists: 1,
      recommendation_station_contact_pairs: 2,
      sorted_non_empty_values: 1,
      stable_id_or_nil: 1,
      stringify_keys: 1
    ]

  def deferred_contact_count(report) do
    case Map.get(report, "recommendations", []) do
      [] ->
        case Values.numeric_report_count(report, "deferred_contact_count") do
          0 -> report |> Map.get("deferred_contact_ids", []) |> length()
          count -> count
        end

      recommendations ->
        recommendations
        |> stringify_recommendations()
        |> Enum.map(&deferred_contacts/1)
        |> Enum.map(&length/1)
        |> Enum.sum()
    end
  end

  def selected_contact_ids(report) do
    case Map.get(report, "recommendations", []) do
      [] ->
        report
        |> Map.get("selected_contact_ids")
        |> List.wrap()
        |> sorted_non_empty_values()

      recommendations ->
        recommendations
        |> stringify_recommendations()
        |> Enum.map(&stable_id_or_nil(&1["selected_contact_id"]))
        |> sorted_non_empty_values()
    end
  end

  def deferred_contact_ids(report) do
    case Map.get(report, "recommendations", []) do
      [] ->
        report
        |> Map.get("deferred_contact_ids")
        |> List.wrap()
        |> sorted_non_empty_values()

      recommendations ->
        recommendations
        |> stringify_recommendations()
        |> Enum.flat_map(&(Map.get(&1, "deferred_contact_ids", []) |> List.wrap()))
        |> Enum.map(&stable_id_or_nil/1)
        |> sorted_non_empty_values()
    end
  end

  def selected_contact_ids_by_station(report) do
    contact_ids_by_station(report, "selected_contact_ids_by_ground_station", :selected)
  end

  def deferred_contact_ids_by_station(report) do
    contact_ids_by_station(report, "deferred_contact_ids_by_ground_station", :deferred)
  end

  defp contact_ids_by_station(report, fallback_field, contact_type) do
    case Map.get(report, "recommendations", []) do
      [] ->
        report
        |> Map.get(fallback_field)
        |> map_value_lists()

      recommendations ->
        recommendations
        |> stringify_recommendations()
        |> Enum.flat_map(&recommendation_station_contact_pairs(&1, contact_type))
        |> grouped_ids()
    end
  end

  defp stringify_recommendations(recommendations) do
    Enum.map(recommendations, &stringify_keys/1)
  end
end
