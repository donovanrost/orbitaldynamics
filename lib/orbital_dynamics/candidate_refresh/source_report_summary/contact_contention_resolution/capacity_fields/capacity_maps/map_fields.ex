defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.CapacityFields.CapacityMaps.MapFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_numeric_maps: 1,
      merge_string_list_maps: 1
    ]

  def count_field(reports, field) do
    reports
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_count_maps()
  end

  def numeric(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_numeric_maps()
  end

  def numeric_field(reports, field) do
    reports
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_numeric_maps()
  end

  def capacity_source_contact_ids(reports) do
    reports
    |> Enum.map(&report_capacity_source_contact_ids/1)
    |> merge_string_list_maps()
  end

  defp report_capacity_source_contact_ids(report) do
    values_by_source = Map.get(report, "required_capacity_fraction_contact_ids_by_source")
    source_counts = Map.get(report, "required_capacity_fraction_source_counts")

    allowed_contact_ids =
      List.wrap(Recommendation.selected_contact_ids(report)) ++
        List.wrap(Recommendation.deferred_contact_ids(report))

    filter_contact_ids(values_by_source, source_counts, allowed_contact_ids)
  end

  defp filter_contact_ids(%{} = values_by_source, %{} = source_counts, allowed_contact_ids) do
    allowed_contact_ids = MapSet.new(allowed_contact_ids)

    source_counts
    |> Enum.filter(fn {_source, count} -> is_integer(count) and count > 0 end)
    |> Enum.reduce(%{}, fn {source, _count}, filtered ->
      contact_ids =
        values_by_source
        |> Map.get(source, [])
        |> List.wrap()
        |> Enum.filter(&MapSet.member?(allowed_contact_ids, &1))

      case contact_ids do
        [] -> filtered
        contact_ids -> Map.put(filtered, source, contact_ids)
      end
    end)
  end

  defp filter_contact_ids(_values_by_source, _source_counts, _allowed_contact_ids), do: %{}
end
