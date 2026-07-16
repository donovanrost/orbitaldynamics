defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.ModelIdFields.GroupedIds do
  @moduledoc false

  alias __MODULE__.RowGroups

  def by_status(report) do
    RowGroups.by(report, "model_ids_by_status", fn _report, row ->
      Map.get(row, "status") || "unknown"
    end)
  end

  def by_validation_level(report) do
    RowGroups.by(report, "model_ids_by_validation_level", fn _report, row ->
      Map.get(row, "validation_level") || "unknown"
    end)
  end

  def by_intended_use(report) do
    RowGroups.by(report, "model_ids_by_intended_use", fn report, _row ->
      Map.get(report, "intended_use") || "unknown"
    end)
  end
end
