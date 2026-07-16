defmodule OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationBatchReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReportEntries
  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReportValues

  def entries(path, %{} = value) do
    value = SchemaValidationReportValues.stringify_keys(value)

    batch_trust_boundary =
      Map.get(value, "trust_boundary") || get_in(value, ["provenance", "trust_boundary"])

    value
    |> Map.get("reports", [])
    |> List.wrap()
    |> Enum.with_index()
    |> Enum.flat_map(fn {entry, index} ->
      entry = SchemaValidationReportValues.stringify_keys(entry)

      case SchemaValidationReportValues.stringify_keys(Map.get(entry, "report", %{})) do
        %{} = report when map_size(report) > 0 ->
          report =
            report
            |> Map.put_new("artifact_path", entry["path"])
            |> Map.put("batch_entry_path", entry["path"])
            |> maybe_put_inherited_trust_boundary(batch_trust_boundary)

          SchemaValidationReportEntries.entries("#{path}.reports[#{index}].report", report)

        _report ->
          []
      end
    end)
  end

  def report?(%{} = report) do
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)
    reports = Map.get(report, "reports") || Map.get(report, :reports)

    schema_contract in [nil, "schema_validation_batch_report.v1"] and is_list(reports)
  end

  def report?(_report), do: false

  defp maybe_put_inherited_trust_boundary(report, trust_boundary)
       when trust_boundary in [nil, ""],
       do: report

  defp maybe_put_inherited_trust_boundary(report, trust_boundary),
    do: Map.put_new(report, "trust_boundary", trust_boundary)
end
