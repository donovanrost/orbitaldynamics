defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.CapacityFields.CapacityMaps.MapValues do
  @moduledoc false

  alias __MODULE__.CountMaps
  alias __MODULE__.NumericMaps
  alias __MODULE__.StringListMaps

  def values(summaries, field_specs) do
    Map.new(field_specs, fn {output_field, {source_field, merge_type}} ->
      {output_field, merge_capacity_field(summaries, source_field, merge_type)}
    end)
  end

  defp merge_capacity_field(summaries, source_field, :numeric) do
    NumericMaps.values(summaries, source_field)
  end

  defp merge_capacity_field(summaries, source_field, :count) do
    CountMaps.values(summaries, source_field)
  end

  defp merge_capacity_field(summaries, source_field, :string_list) do
    StringListMaps.values(summaries, source_field)
  end
end
