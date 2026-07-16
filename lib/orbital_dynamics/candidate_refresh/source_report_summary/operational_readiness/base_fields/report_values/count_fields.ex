defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.BaseFields.ReportValues.CountFields do
  @moduledoc false

  alias __MODULE__.CountValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(reports) do
    %{
      "import_eligible_count" => sum_report_count(reports, &CountValues.import_eligible_count/1),
      "import_ineligible_count" =>
        sum_report_count(reports, &CountValues.import_ineligible_count/1),
      "handoff_only_count" => CountValues.boolean_sum(reports, "handoff_only", true),
      "execution_allowed_count" => CountValues.boolean_sum(reports, "execution_allowed", true),
      "execution_denied_count" => CountValues.boolean_sum(reports, "execution_allowed", false),
      "cadence_write_allowed_count" =>
        CountValues.boolean_sum(reports, "cadence_write_allowed", true),
      "cadence_write_denied_count" =>
        CountValues.boolean_sum(reports, "cadence_write_allowed", false),
      "operator_authority_granted_count" =>
        CountValues.boolean_sum(reports, "operator_authority_granted", true),
      "operator_authority_denied_count" =>
        CountValues.boolean_sum(reports, "operator_authority_granted", false),
      "gate_count" => sum_report_count(reports, &CountValues.gate_count/1)
    }
  end
end
