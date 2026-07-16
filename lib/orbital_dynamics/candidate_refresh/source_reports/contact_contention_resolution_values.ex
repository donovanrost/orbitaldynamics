defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionEncoding

  def report?(%{} = report) do
    recommendations = Map.get(report, "recommendations") || Map.get(report, :recommendations)
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    source_summary_schema_contract =
      Map.get(report, "source_summary_schema_contract") ||
        Map.get(report, :source_summary_schema_contract)

    (is_list(recommendations) and
       schema_contract in [nil, "contact_contention_resolution_report.v1"]) or
      source_summary_schema_contract == "contact_contention_resolution_summary.v1"
  end

  def report?(_report), do: false

  def summary?(%{} = summary) do
    model = Map.get(summary, "model") || Map.get(summary, :model)
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)

    model == "artifact_only_contact_contention_resolution_summary" or
      schema_contract == "contact_contention_resolution_summary.v1"
  end

  def summary?(_summary), do: false

  def stringify_keys(value), do: ContactContentionResolutionEncoding.stringify_keys(value)
end
