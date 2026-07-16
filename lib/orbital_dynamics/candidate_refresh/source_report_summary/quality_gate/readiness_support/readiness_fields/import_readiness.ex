defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ReadinessSupport.ReadinessFields.ImportReadiness do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.IdFields
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      sorted_string_values: 1
    ]

  def fields(reports) do
    reports
    |> CountFields.fields()
    |> Map.merge(id_fields(reports))
    |> compact_map()
  end

  defp id_fields(reports) do
    Map.new(IdFields.all(), fn field -> {field, string_values(reports, field)} end)
  end

  defp string_values(reports, field) do
    reports
    |> Enum.flat_map(&RowFallbackValues.string_list(&1, field))
    |> sorted_string_values()
  end
end
