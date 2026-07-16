defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.Fallbacks.RoutedMaps.FieldSpecs do
  @moduledoc false

  @status_row_fields ~w(analysis_only blocked review_required)
  @classification_row_fields ~w(analysis_only blocked_by_policy operator_review_required)

  def status_row_fields, do: @status_row_fields
  def classification_row_fields, do: @classification_row_fields
end
