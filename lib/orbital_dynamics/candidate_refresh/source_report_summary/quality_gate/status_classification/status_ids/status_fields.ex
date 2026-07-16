defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.StatusFields do
  @moduledoc false

  alias __MODULE__.Aggregates
  alias __MODULE__.FieldSpecs

  def fields(reports) do
    reports
    |> Aggregates.gate_status_id_fields(FieldSpecs.gate_id_status_fields())
    |> Map.merge(Aggregates.row_status_id_fields(reports, FieldSpecs.row_id_status_fields()))
  end
end
