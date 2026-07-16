defmodule OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.PressureRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows

  def pressure_rows(sources) do
    sources
    |> Enum.flat_map(fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> SummaryRows.pressure_rows_for_report()
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        row = Map.put(row, "_source_report_trust_boundary", trust_boundary)

        {row, pressure_row_source(row, source_path), index}
      end)
    end)
  end

  defp pressure_row_source(row, source_path) do
    row_source = Map.get(row, "source", "quality_gate_report")

    cond do
      String.starts_with?(row_source, "quality_gate_report") ->
        String.replace_prefix(row_source, "quality_gate_report", source_path)

      String.starts_with?(row_source, "operational_quality_gate_summary") ->
        String.replace_prefix(row_source, "operational_quality_gate_summary", source_path)

      String.starts_with?(row_source, "operational_quality_gate_unavailable_resource_summary") ->
        String.replace_prefix(
          row_source,
          "operational_quality_gate_unavailable_resource_summary",
          source_path
        )

      String.starts_with?(row_source, "operational_quality_gate_operator_training_summary") ->
        String.replace_prefix(
          row_source,
          "operational_quality_gate_operator_training_summary",
          source_path
        )

      String.starts_with?(row_source, "operational_quality_gate_schema_validation_summary") ->
        String.replace_prefix(
          row_source,
          "operational_quality_gate_schema_validation_summary",
          source_path
        )

      String.starts_with?(row_source, "operational_quality_gate_import_readiness_summary") ->
        String.replace_prefix(
          row_source,
          "operational_quality_gate_import_readiness_summary",
          source_path
        )

      true ->
        source_path
    end
  end
end
