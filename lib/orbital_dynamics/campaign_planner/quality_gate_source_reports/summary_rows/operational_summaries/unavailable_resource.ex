defmodule OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.OperationalSummaries.UnavailableResource do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.QualityGateSourceReports.SummaryRows.OperationalSummaries.Common

  def pressure_rows_for_report(
        %{"schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1"} =
          summary
      ) do
    summary = Common.stringify_keys(summary)

    case unavailable_resource_summary_gate_status(summary) do
      nil ->
        []

      gate_status ->
        gate_classification = Common.quality_gate_status_classification(gate_status)

        resource_availability_reason_counts =
          unavailable_resource_summary_resource_availability_reason_counts(summary)

        [
          %{
            "source" => "operational_quality_gate_unavailable_resource_summary",
            "report_id" => summary["source_quality_gate_report_id"],
            "source_artifact_type" => summary["source_artifact_type"],
            "source_artifact_id" => summary["source_artifact_id"],
            "source_readiness_report_id" => summary["source_readiness_report_id"],
            "readiness_level" => Common.quality_gate_status_readiness_level(gate_status),
            "import_classification" => gate_classification,
            "quality_gate_status" => gate_status,
            "gate_count" => summary["resource_availability_row_count"],
            "review_gate_count" => length(summary["review_required_quality_gate_row_ids"] || []),
            "analysis_gate_count" =>
              length(get_in(summary, ["quality_gate_row_ids_by_status", "analysis_only"]) || []),
            "blocked_gate_count" => length(summary["blocked_quality_gate_row_ids"] || []),
            "gate_id" => single_quality_gate_id(summary["resource_availability_gate_ids"]),
            "gate_status" => gate_status,
            "gate_classification" => gate_classification,
            "gate_reason" => unavailable_resource_summary_gate_reason(gate_status),
            "resource_availability_pressure_count" =>
              Common.count_map_value_sum(resource_availability_reason_counts),
            "resource_availability_reason_counts" => resource_availability_reason_counts,
            "resource_availability_reason_ids" =>
              Common.sorted_count_map_keys(resource_availability_reason_counts),
            "unavailable_resource_reason_counts" => summary["unavailable_resource_reason_counts"],
            "unavailable_resource_reason_ids" => summary["unavailable_resource_reason_ids"],
            "station_availability_reason_counts" => summary["station_availability_reason_counts"],
            "station_availability_reason_ids" => summary["station_availability_reason_ids"],
            "resource_blocking_dimension_counts" => summary["resource_blocking_dimension_counts"],
            "blocked_contact_ids_by_blocking_dimension" =>
              summary["blocked_contact_ids_by_blocking_dimension"],
            "blocked_contact_ids_by_spacecraft_id" =>
              summary["blocked_contact_ids_by_spacecraft_id"],
            "blocked_contact_ids_by_status" => summary["blocked_contact_ids_by_status"],
            "assumptions" => summary["assumptions"],
            "source_quality_gate_row" => unavailable_resource_summary_source_row(summary),
            "source_quality_gate_report" => summary
          }
          |> Common.compact_map()
        ]
    end
  end

  defp unavailable_resource_summary_gate_status(summary) do
    cond do
      length(summary["blocked_quality_gate_row_ids"] || []) > 0 ->
        "blocked"

      length(get_in(summary, ["quality_gate_row_ids_by_status", "analysis_only"]) || []) > 0 ->
        "analysis_only"

      length(summary["review_required_quality_gate_row_ids"] || []) > 0 ->
        "review_required"

      true ->
        nil
    end
  end

  defp unavailable_resource_summary_gate_reason("blocked"),
    do: "unavailable resource summary blocks import"

  defp unavailable_resource_summary_gate_reason("analysis_only"),
    do: "unavailable resource summary requires analysis"

  defp unavailable_resource_summary_gate_reason(_status),
    do: "unavailable resource summary requires review"

  defp single_quality_gate_id([id | _rest]) when id not in [nil, ""], do: id
  defp single_quality_gate_id(_ids), do: "resource_availability"

  defp unavailable_resource_summary_source_row(summary) do
    %{
      "gate_id" => single_quality_gate_id(summary["resource_availability_gate_ids"]),
      "quality_gate_row_ids_by_status" => summary["quality_gate_row_ids_by_status"],
      "quality_gate_ids_by_status" => summary["quality_gate_ids_by_status"],
      "review_required_quality_gate_row_ids" => summary["review_required_quality_gate_row_ids"],
      "blocked_quality_gate_row_ids" => summary["blocked_quality_gate_row_ids"],
      "resource_availability_gate_ids" => summary["resource_availability_gate_ids"]
    }
    |> Common.compact_map()
  end

  defp unavailable_resource_summary_resource_availability_reason_counts(summary) do
    [
      summary["unavailable_resource_reason_counts"],
      summary["station_availability_reason_counts"]
    ]
    |> Enum.filter(&is_map/1)
    |> Enum.reduce(%{}, fn counts, merged ->
      counts
      |> Common.stringify_keys()
      |> Enum.reduce(merged, fn {key, value}, acc ->
        case Common.numeric_or_nil(value) do
          number when is_number(number) and number > 0 ->
            Map.update(acc, key, number, &(&1 + number))

          _value ->
            acc
        end
      end)
    end)
  end
end
