defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields.CountMaps do
  @moduledoc false

  alias __MODULE__.FieldValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(reports) do
    %{
      "operational_kind_counts" => count_map(reports, &FieldValues.operational_kind_counts/1),
      "activity_id_counts" => count_map(reports, &FieldValues.activity_id_counts/1),
      "activity_status_counts" => count_map(reports, &FieldValues.activity_status_counts/1),
      "approval_status_counts" => count_map(reports, &FieldValues.approval_status_counts/1),
      "required_operator_action_counts" =>
        count_map(reports, &FieldValues.required_operator_action_counts/1),
      "cadence_import_status_counts" =>
        count_map(reports, &FieldValues.cadence_import_status_counts/1)
    }
  end

  def source_required_operator_action_counts(report) do
    FieldValues.source_required_operator_action_counts(report)
  end

  defp count_map(reports, extractor) do
    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end
end
