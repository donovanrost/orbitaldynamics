defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence.Values.FieldValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence.Values.FieldSets

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence.Values.MergedValues

  def fields(reports) do
    reports
    |> count_fields()
    |> Map.merge(count_map_fields(reports))
  end

  defp count_fields(reports) do
    Map.new(FieldSets.count_fields(), fn field ->
      {field, MergedValues.count_sum(reports, field)}
    end)
  end

  defp count_map_fields(reports) do
    Map.new(FieldSets.map_fields(), fn field ->
      {field, MergedValues.count_map_merge(reports, field)}
    end)
  end
end
