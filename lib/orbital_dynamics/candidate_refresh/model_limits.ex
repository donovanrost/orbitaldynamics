defmodule OrbitalDynamics.CandidateRefresh.ModelLimits do
  @moduledoc false

  @known_limits [
    :requires_precomputed_refreshed_event_results,
    :sampled_window_boundaries,
    :thin_resource_filter,
    :thin_ground_network_filter,
    :candidate_budget_is_deterministic_post_filter_selection,
    :artifact_only_no_schedule_mutation
  ]

  def atoms, do: @known_limits

  def strings, do: Enum.map(@known_limits, &Atom.to_string/1)
end
