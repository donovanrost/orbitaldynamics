defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.IdFields do
  @moduledoc false

  alias __MODULE__.IdValues

  def fields(reports) do
    %{
      "gate_ids_by_status" => IdValues.ids_by_status(reports),
      "gate_ids_by_classification" => IdValues.ids_by_classification(reports),
      "passed_gate_ids" => IdValues.passed_ids(reports),
      "review_required_gate_ids" =>
        IdValues.ids_for_status(reports, "review_required", "review_required_gate_ids"),
      "analysis_only_gate_ids" =>
        IdValues.ids_for_status(reports, "analysis_only", "analysis_only_gate_ids"),
      "blocked_gate_ids" => IdValues.ids_for_status(reports, "blocked", "blocked_gate_ids"),
      "non_passed_gate_ids" => IdValues.non_passed_ids(reports)
    }
  end
end
