defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.CapacityFields.CapacityMaps.MapFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields.Recommendation
  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

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

  def numeric(reports, extractor, total_extractor) do
    reports
    |> Enum.map(fn report ->
      correlated_numeric_map(extractor.(report), total_extractor.(report))
    end)
    |> merge_numeric_maps()
  end

  def capacity_status(reports, total_extractor, selected_extractor, deferred_extractor) do
    reports
    |> Enum.map(fn report ->
      report
      |> Map.get("capacity_pack_required_capacity_fraction_by_status")
      |> normalize_numeric_map(["selected", "deferred"])
      |> correlate_capacity_status(
        total_extractor.(report),
        selected_extractor.(report),
        deferred_extractor.(report)
      )
    end)
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

  defp correlated_numeric_map(values, total) do
    values = normalize_numeric_map(values, :all_keys)

    if is_number(total) and numeric_map_sum(values) == total, do: values, else: %{}
  end

  defp correlate_capacity_status(values, total, selected_total, deferred_total) do
    if is_number(total) and is_number(selected_total) and is_number(deferred_total) and
         numeric_map_sum(values) == total and
         Map.get(values, "selected", 0) == selected_total and
         Map.get(values, "deferred", 0) == deferred_total do
      values
    else
      %{}
    end
  end

  defp normalize_numeric_map(%{} = values, allowed_keys) do
    Enum.reduce(values, %{}, fn {key, value}, normalized ->
      value = ValueEncoding.numeric_value(value)

      if (allowed_keys == :all_keys or key in allowed_keys) and is_number(value) and value >= 0 do
        Map.put(normalized, key, value)
      else
        normalized
      end
    end)
  end

  defp normalize_numeric_map(_values, _allowed_keys), do: %{}

  defp numeric_map_sum(values), do: values |> Map.values() |> Enum.sum()
end
