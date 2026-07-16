defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence.Values do
  @moduledoc false

  alias __MODULE__.FieldValues
  alias __MODULE__.MergedValues

  def fields(reports) do
    FieldValues.fields(reports)
  end

  def count_sum(reports, field) do
    MergedValues.count_sum(reports, field)
  end

  def count_map_merge(reports, field) do
    MergedValues.count_map_merge(reports, field)
  end

  def string_values(reports, field) do
    MergedValues.string_values(reports, field)
  end

  def string_list_map_merge(reports, field) do
    MergedValues.string_list_map_merge(reports, field)
  end

  def count_map(report, field) do
    MergedValues.count_map(report, field)
  end
end
