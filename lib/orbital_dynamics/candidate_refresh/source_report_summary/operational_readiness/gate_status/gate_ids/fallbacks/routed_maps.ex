defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds.Fallbacks.RoutedMaps do
  @moduledoc false

  alias __MODULE__.FieldSpecs
  alias __MODULE__.MapValues

  def by_status(row_ids, report) do
    MapValues.with_row_ids(row_ids, report, "gate_ids_by_status", FieldSpecs.status_row_fields())
  end

  def by_classification(row_ids, report) do
    MapValues.with_row_ids(
      row_ids,
      report,
      "gate_ids_by_classification",
      FieldSpecs.classification_row_fields()
    )
  end
end
