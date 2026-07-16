defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessReportFields

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowValues,
    as: RowValues

  def rows(%{} = summary) do
    summary
    |> Map.get("import_readiness_rows", [])
    |> Enum.filter(&is_map/1)
    |> Enum.map(&RowValues.stringify_keys/1)
  end

  def report_fields(%{} = summary, rows) when is_list(rows) do
    ProviderCounterofferImportReadinessReportFields.report_fields(summary, rows)
  end
end
