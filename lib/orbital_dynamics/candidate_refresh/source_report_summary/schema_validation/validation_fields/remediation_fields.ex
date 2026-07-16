defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.SchemaValidation.ValidationFields.RemediationFields do
  @moduledoc false

  alias __MODULE__.CountFields
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      merge_count_maps: 1
    ]

  def fields(reports) do
    Map.merge(CountFields.fields(reports), remediation_map_fields(reports))
  end

  defp remediation_map_fields(reports) do
    %{
      "remediation_action_counts" => remediation_field_counts(reports, "action"),
      "remediation_category_counts" => remediation_field_counts(reports, "category"),
      "remediation_path_counts" => remediation_field_counts(reports, "path")
    }
  end

  defp remediation_field_counts(reports, field) do
    reports
    |> Enum.map(&report_remediation_field_counts(&1, field))
    |> merge_count_maps()
  end

  defp report_remediation_field_counts(report, field) do
    report
    |> Map.get("remediation", [])
    |> Enum.map(&EncodedValue.stringify_keys/1)
    |> Enum.map(&Map.get(&1, field))
    |> count_source_report_values()
  end
end
