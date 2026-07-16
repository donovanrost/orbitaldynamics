defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.FieldValues do
  @moduledoc false

  alias __MODULE__.CompactMaps
  alias __MODULE__.SortedStrings
  alias __MODULE__.SourceFields
  alias __MODULE__.SourceRows

  def sorted_string_values(values) when is_list(values) do
    SortedStrings.from(values)
  end

  def sorted_string_values(_values), do: []

  def source_field_values(%{} = source, field) do
    SourceFields.values(source, field)
  end

  def source_field_values(_source, _field), do: []

  def source_rows(report) do
    SourceRows.values(report)
  end

  def source_rows(report, field) do
    SourceRows.values(report, field)
  end

  def compact_map(map) when is_map(map) do
    CompactMaps.from(map)
  end
end
