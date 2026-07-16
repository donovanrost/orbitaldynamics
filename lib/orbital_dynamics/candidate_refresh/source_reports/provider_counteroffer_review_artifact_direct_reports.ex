defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewArtifactDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounteroffer

  def reports(refresh, builder, source_key, artifact_key) do
    [
      {"accepted_planning_state.#{source_key}",
       get_in(refresh, ["accepted_planning_state", source_key])},
      {"accepted_planning_state.#{artifact_key}",
       get_in(refresh, ["accepted_planning_state", artifact_key])},
      {"mission_state.#{source_key}", get_in(refresh, ["mission_state", source_key])},
      {"mission_state.#{artifact_key}", get_in(refresh, ["mission_state", artifact_key])},
      {source_key, Map.get(refresh, source_key)},
      {artifact_key, Map.get(refresh, artifact_key)}
    ]
    |> Enum.flat_map(fn {path, artifact_or_artifacts} ->
      ProviderCounteroffer.build_entries(path, artifact_or_artifacts, builder)
    end)
  end
end
