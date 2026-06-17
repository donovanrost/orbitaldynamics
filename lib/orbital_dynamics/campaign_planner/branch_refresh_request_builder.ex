defmodule OrbitalDynamics.CampaignPlanner.BranchRefreshRequestBuilder do
  @moduledoc false

  def build(branch, request, defaults, inputs) do
    outputs = Map.fetch!(inputs, :outputs)
    ground_stations = Map.fetch!(inputs, :ground_stations)

    candidate_refresh =
      %{
        "accepted_planning_state" => Map.fetch!(inputs, :accepted_state),
        "current_epoch_s" => request.current_epoch_s,
        "remaining_horizon" => Map.fetch!(inputs, :remaining_horizon),
        "targets" => Map.fetch!(inputs, :targets),
        "ground_network" => Map.fetch!(inputs, :ground_network),
        "constraints" => Map.fetch!(inputs, :constraints),
        "resource_filter_policy" => Map.fetch!(inputs, :resource_filter_policy),
        "candidate_limit_policy" => Map.fetch!(inputs, :candidate_limit_policy),
        "source_timeline_feedback_report" => Map.get(inputs, :source_timeline_feedback_report),
        "timeline_feedback_report" => Map.get(inputs, :timeline_feedback_report),
        "source_operational_timeline_report" =>
          Map.get(inputs, :source_operational_timeline_report),
        "operational_timeline_report" => Map.get(inputs, :operational_timeline_report),
        "mission_state" => Map.get(inputs, :mission_state),
        "operational_feedback" => Map.fetch!(inputs, :operational_feedback),
        "scoring_policy" => Map.fetch!(inputs, :scoring_policy),
        "model_assumptions" => model_assumptions(defaults, branch),
        "resource_summaries" => Map.fetch!(inputs, :resource_summaries),
        "prior_candidate_activities" => Map.fetch!(inputs, :prior_candidate_activities),
        "approval_policy" => Map.get(inputs, :approval_policy)
      }
      |> compact_map()

    %{
      "schema_version" => 1,
      "study_id" => "branch_refresh_#{branch["id"]}",
      "central_body" => Map.get(defaults, "central_body", "earth"),
      "propagator" => Map.get(defaults, "propagator", "two_body"),
      "propagator_opts" => Map.get(defaults, "propagator_opts", %{"max_step_s" => 10.0}),
      "outputs" => outputs,
      "ground_stations" => ground_stations,
      "candidate_refresh" => candidate_refresh
    }
  end

  defp model_assumptions(defaults, branch) do
    Map.merge(Map.get(defaults, "model_assumptions", %{}), %{
      "candidate_refresh_level" => "branch_event_derived_v1",
      "derived_from_branch_id" => branch["id"]
    })
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
