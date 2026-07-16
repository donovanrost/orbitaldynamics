defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.AggregateMaps.ListMaps do
  @moduledoc false

  alias __MODULE__.NumericListMaps
  alias __MODULE__.StringListMaps
  alias __MODULE__.StringLists

  def merge_string_lists(lists) do
    StringLists.merge(lists)
  end

  def merge_string_list_maps(list_maps) do
    StringListMaps.merge(list_maps)
  end

  def merge_nested_string_list_maps(list_maps),
    do: StringListMaps.merge_nested(list_maps)

  def merge_numeric_list_maps(list_maps), do: NumericListMaps.merge(list_maps)
end
