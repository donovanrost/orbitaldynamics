defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollectionArtifactReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollectionEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollectionResultArtifacts

  def result_artifact_states(
        refresh,
        source_result_artifacts_fun,
        inherit_result_artifact_trust_boundary_fun
      ) do
    TimelineActivityStateCollectionResultArtifacts.result_artifact_states(
      refresh,
      source_result_artifacts_fun,
      inherit_result_artifact_trust_boundary_fun
    )
  end

  def entries(path, state) do
    EntryFallbacks.entries(path, state, fn entry_path, entry_state ->
      state = stringify_keys(entry_state)

      if activity_state_source?(state) do
        {entry_path, state}
      end
    end)
  end

  def activity_state_source?(%{} = state) do
    schema_contract = Map.get(state, "schema_contract") || Map.get(state, :schema_contract)
    model = Map.get(state, "model") || Map.get(state, :model)

    schema_contract in [
      "timeline_activity_state.v1",
      "timeline_activity_status_state.v1",
      "timeline_activity_approval_state.v1"
    ] or
      model in [
        "artifact_only_timeline_activity_state",
        "artifact_only_timeline_activity_status_state",
        "artifact_only_timeline_activity_approval_state"
      ]
  end

  def activity_state_source?(_state), do: false

  defdelegate stringify_keys(value), to: TimelineActivityStateCollectionEncoding
end
