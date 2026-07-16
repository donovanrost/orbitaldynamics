defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.ReasonValues.ReasonIds.FieldValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability.Reasons.ReasonValues.ReasonIds.{
    ContextValues,
    FieldSpecs
  }

  def values(report, reason_family) do
    {summary_id_field, summary_count_field, row_id_field, row_count_field} =
      FieldSpecs.fetch!(reason_family)

    ContextValues.reason_id_values(
      report,
      summary_id_field,
      summary_count_field,
      row_id_field,
      row_count_field
    )
  end
end
