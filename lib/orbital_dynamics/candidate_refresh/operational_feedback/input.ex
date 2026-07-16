defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.Input do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues

  def raw(refresh) do
    cond do
      Map.has_key?(refresh, "operational_feedback") ->
        Map.get(refresh, "operational_feedback")

      is_map(Map.get(refresh, "mission_state")) and
          Map.has_key?(Map.get(refresh, "mission_state"), "operational_feedback") ->
        get_in(refresh, ["mission_state", "operational_feedback"])

      is_map(Map.get(refresh, "accepted_planning_state")) and
          Map.has_key?(Map.get(refresh, "accepted_planning_state"), "operational_feedback") ->
        get_in(refresh, ["accepted_planning_state", "operational_feedback"])

      true ->
        %{}
    end
  end

  def normalized(refresh), do: refresh |> raw() |> RowValues.stringify_keys_with_keyword_maps()

  def source_path(refresh) do
    cond do
      Map.has_key?(refresh, "operational_feedback") ->
        "operational_feedback"

      is_map(Map.get(refresh, "mission_state")) and
          Map.has_key?(Map.get(refresh, "mission_state"), "operational_feedback") ->
        "mission_state.operational_feedback"

      is_map(Map.get(refresh, "accepted_planning_state")) and
          Map.has_key?(Map.get(refresh, "accepted_planning_state"), "operational_feedback") ->
        "accepted_planning_state.operational_feedback"

      true ->
        nil
    end
  end

  def invalid?(refresh), do: not is_map(raw(refresh))

  def invalid_sections(refresh) do
    case refresh |> raw() |> RowValues.stringify_keys_with_keyword_maps() do
      %{} = feedback -> OperationalFeedback.invalid_sections(feedback)
      _feedback -> []
    end
  end
end
