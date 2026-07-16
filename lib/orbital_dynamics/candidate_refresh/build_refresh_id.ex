defmodule OrbitalDynamics.CandidateRefresh.BuildRefreshId do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{
    BuildContext,
    OperationalFeedback.Input,
    ResourceFiltering,
    SourceReportSummary.Common.EncodedValue,
    TargetLookup,
    ValueEncoding
  }

  def build(
        refresh,
        study_id,
        refresh_ground_network,
        refresh_objectives
      ) do
    hash =
      refresh
      |> stable_input(
        study_id,
        refresh_ground_network,
        refresh_objectives
      )
      |> :erlang.term_to_binary()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 16)

    "candidate_refresh:" <> encode_value(study_id) <> ":" <> hash
  end

  defp stable_input(
         refresh,
         study_id,
         refresh_ground_network,
         refresh_objectives
       ) do
    {
      encode_value(study_id),
      BuildContext.snapshot_id(refresh),
      BuildContext.accepted_planning_state(refresh),
      BuildContext.current_epoch_s(refresh, &ValueEncoding.numeric_value/1),
      BuildContext.remaining_horizon(refresh, &ValueEncoding.numeric_value/1),
      TargetLookup.targets(refresh),
      refresh_objectives.(refresh),
      refresh_spacecraft_states(refresh),
      refresh_ground_network.(refresh),
      ResourceFiltering.refresh_resource_summaries(refresh),
      Map.get(refresh, "prior_candidate_activities", []),
      Map.get(refresh, "freshness_policy", %{}),
      Map.get(refresh, "resource_filter_policy", %{}),
      Map.get(refresh, "candidate_limit_policy", %{}),
      Map.get(refresh, "contact_allocation_policy", %{}),
      Map.get(refresh, "approval_policy", %{}),
      Input.raw(refresh),
      Map.get(refresh, "model_assumptions", %{}),
      Map.get(refresh, "constraints", %{}),
      Map.get(refresh, "scoring_policy", %{})
    }
  end

  defp refresh_spacecraft_states(refresh) do
    [
      get_in(refresh, ["mission_state", "spacecraft_states"]) || [],
      get_in(refresh, ["accepted_planning_state", "spacecraft_states"]) || []
    ]
    |> List.flatten()
    |> Enum.map(&stringify_keys/1)
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()
  defp stringify_keys(value), do: EncodedValue.value_with_keyword_maps(value)

  defp encode_value(value), do: EncodedValue.value_with_keyword_maps(value)
end
