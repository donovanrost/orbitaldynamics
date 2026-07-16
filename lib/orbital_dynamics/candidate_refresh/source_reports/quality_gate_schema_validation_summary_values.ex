defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSchemaValidationSummaryValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSchemaValidationSummaryEncoding

  def schema_validation_status(%{} = summary) do
    cond do
      list_value(summary["blocked_quality_gate_row_ids"]) != [] or
        summary["schema_validation_import_blocked"] == true or
        positive_summary_count?(summary, "schema_validation_fail_count") or
          positive_summary_count?(summary, "schema_validation_error_count") ->
        "blocked"

      list_value(summary["review_required_quality_gate_row_ids"]) != [] or
        positive_summary_count?(summary, "schema_validation_warning_count") or
          positive_summary_count?(summary, "schema_validation_remediation_count") ->
        "review_required"

      true ->
        "passed"
    end
  end

  def maybe_put(map, _key, nil), do: map
  def maybe_put(map, key, value), do: Map.put(map, key, value)

  def stringify_keys(value), do: QualityGateSchemaValidationSummaryEncoding.stringify_keys(value)

  defp positive_summary_count?(summary, field), do: numeric_report_count(summary, field) > 0

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
