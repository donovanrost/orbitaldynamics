defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarEncoding

  def report?(%{} = report) do
    rows = Map.get(report, "affected_contacts") || Map.get(report, :affected_contacts)

    provider_groups =
      Map.get(report, "provider_calendar_contention_groups") ||
        Map.get(report, :provider_calendar_contention_groups)

    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)
    source_summary_schema_contract = Map.get(report, "source_summary_schema_contract")

    ((is_list(rows) or is_list(provider_groups)) and
       schema_contract in [nil, "station_calendar_report.v1"]) or
      source_summary_schema_contract == "station_calendar_precedence_summary.v1"
  end

  def report?(_report), do: false

  def precedence_summary?(%{} = summary) do
    model = Map.get(summary, "model") || Map.get(summary, :model)
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)

    model == "artifact_only_station_calendar_precedence_summary" or
      schema_contract == "station_calendar_precedence_summary.v1"
  end

  def precedence_summary?(_summary), do: false

  def report_from_precedence_summary(%{} = summary) do
    summary = stringify_keys(summary)

    summary
    |> Map.put_new("affected_contacts", [])
    |> Map.put("source_summary_schema_contract", Map.get(summary, "schema_contract"))
    |> Map.put("source_summary_model", Map.get(summary, "model"))
    |> Map.put("source_artifact_type", Map.get(summary, "source_artifact_type"))
  end

  def stringify_keys(value), do: StationCalendarEncoding.stringify_keys(value)
end
