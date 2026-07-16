defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.AggregateDelegates do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.AggregateMaps

  defdelegate merge_count_maps(count_maps), to: AggregateMaps
  defdelegate merge_numeric_maps(numeric_maps), to: AggregateMaps
  defdelegate merge_nested_numeric_maps(numeric_maps), to: AggregateMaps
  defdelegate merge_string_lists(lists), to: AggregateMaps
  defdelegate merge_string_list_maps(list_maps), to: AggregateMaps
  defdelegate merge_nested_string_list_maps(list_maps), to: AggregateMaps
  defdelegate merge_numeric_list_maps(list_maps), to: AggregateMaps
end
