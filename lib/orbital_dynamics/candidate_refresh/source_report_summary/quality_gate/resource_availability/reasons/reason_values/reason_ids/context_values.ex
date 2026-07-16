defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.ReasonValues.ReasonIds.ContextValues do
  @moduledoc false

  def reason_id_values(
        report,
        summary_id_field,
        summary_count_field,
        row_id_field,
        row_count_field
      ) do
    case report_rows(report) do
      [] ->
        context_reason_ids(report, summary_id_field, summary_count_field)

      rows ->
        Enum.flat_map(rows, &context_reason_ids(&1, row_id_field, row_count_field))
    end
  end

  defp context_reason_ids(%{} = context, id_field, count_field) do
    list_value(Map.get(context, id_field)) ++
      Map.keys(Map.get(context, count_field) || %{})
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []

  defp report_rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.filter(&is_map/1)
  end
end
