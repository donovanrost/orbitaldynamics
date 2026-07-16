defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields.CountMaps.FieldValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields.RowValues

  def operational_kind_counts(report), do: field_counts(report, "operational_kind")
  def activity_status_counts(report), do: field_counts(report, "status")
  def approval_status_counts(report), do: field_counts(report, "approval_status")

  def required_operator_action_counts(report),
    do: field_counts(report, "required_operator_action")

  def cadence_import_status_counts(report), do: field_counts(report, "cadence_import_status")

  def activity_id_counts(report), do: RowValues.activity_id_counts(report)

  def source_required_operator_action_counts(report) do
    case Map.get(report, "rows", []) do
      [] -> Map.get(report, "required_operator_action_counts")
      _rows -> required_operator_action_counts(report)
    end
  end

  defp field_counts(report, field), do: RowValues.field_counts(report, field)
end
