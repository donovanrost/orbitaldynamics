defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePreservation do
  @moduledoc false

  alias __MODULE__.ReplayInput
  alias __MODULE__.Summary

  def source_report_flags(refresh_or_artifact) do
    summary =
      if ReplayInput.input?(refresh_or_artifact) do
        summary(refresh_or_artifact)
      else
        %{
          "branch_local_timeline_preservation_pressure" => false,
          "branch_local_timeline_preservation_review_pressure" => false,
          "branch_local_timeline_preservation_record_pressure" => false,
          "branch_local_timeline_preservation_action_pressure" => false,
          "branch_local_timeline_preservation_routing_pressure" => false
        }
      end

    %{
      "source_report_timeline_preservation_branch_local_timeline_preservation_pressure" =>
        Map.get(summary, "branch_local_timeline_preservation_pressure"),
      "source_report_timeline_preservation_branch_local_review_pressure" =>
        Map.get(summary, "branch_local_timeline_preservation_review_pressure"),
      "source_report_timeline_preservation_branch_local_record_pressure" =>
        Map.get(summary, "branch_local_timeline_preservation_record_pressure"),
      "source_report_timeline_preservation_branch_local_action_pressure" =>
        Map.get(summary, "branch_local_timeline_preservation_action_pressure"),
      "source_report_timeline_preservation_branch_local_routing_pressure" =>
        Map.get(summary, "branch_local_timeline_preservation_routing_pressure")
    }
  end

  def summary(refresh_or_artifact) do
    Summary.summary(refresh_or_artifact)
  end
end
