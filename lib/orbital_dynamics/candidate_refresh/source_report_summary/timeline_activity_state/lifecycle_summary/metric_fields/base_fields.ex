defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleSummary.MetricFields.BaseFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.RequiredActions

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.SourceSummary

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleSummary.MetricFields.InvalidActivityFields

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1
    ]

  def fields(states) do
    %{
      "source_summary_model_counts" => SourceSummary.model_counts(states),
      "source_summary_schema_contract_counts" => SourceSummary.schema_contract_counts(states),
      "row_count" => length(states),
      "review_required_count" => Enum.count(states, &RequiredActions.review_required?/1),
      "required_operator_action_counts" =>
        states
        |> Enum.map(&RequiredActions.counts/1)
        |> merge_count_maps(),
      "action_routing" => RequiredActions.routing(states),
      "trust_boundary_status" => source_report_trust_boundary_status(states),
      "trust_boundaries" => source_report_trust_boundaries(states)
    }
    |> Map.merge(InvalidActivityFields.fields(states))
  end
end
