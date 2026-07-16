defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.AggregateMaps do
  @moduledoc false

  alias __MODULE__.ListMaps
  alias __MODULE__.NumberMaps

  def merge_count_maps(count_maps), do: NumberMaps.merge_count_maps(count_maps)

  def merge_numeric_maps(numeric_maps), do: NumberMaps.merge_numeric_maps(numeric_maps)

  def merge_nested_numeric_maps(numeric_maps),
    do: NumberMaps.merge_nested_numeric_maps(numeric_maps)

  def merge_string_lists(lists), do: ListMaps.merge_string_lists(lists)
  def merge_string_list_maps(list_maps), do: ListMaps.merge_string_list_maps(list_maps)

  def merge_nested_string_list_maps(list_maps),
    do: ListMaps.merge_nested_string_list_maps(list_maps)

  def merge_numeric_list_maps(list_maps), do: ListMaps.merge_numeric_list_maps(list_maps)
end
