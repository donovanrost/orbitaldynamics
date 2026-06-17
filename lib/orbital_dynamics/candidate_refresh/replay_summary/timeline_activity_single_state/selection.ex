defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivitySingleState.Selection do
  @moduledoc false

  def summary_for_replay(refresh_or_artifact, family, contract, source_model, callbacks) do
    {state_summary, branch_summary?} =
      refresh_or_artifact
      |> direct_state_summary(contract, source_model, callbacks)
      |> case do
        nil -> summary_from_source_reports(refresh_or_artifact, contract, callbacks)
        summary -> {summary, false}
      end
      |> case do
        nil -> {%{}, false}
        {summary, branch_summary?} -> {summary, branch_summary?}
      end

    {summary_source, replay_scope} = source_and_scope(family, branch_summary?)

    {state_summary, summary_source, replay_scope}
  end

  def selected_source_report_summary(
        refresh_or_artifact,
        source_reports,
        contract,
        source_model,
        callbacks
      ) do
    refresh_or_artifact
    |> direct_state_summary(contract, source_model, callbacks)
    |> case do
      nil ->
        source_reports
        |> Map.get("timeline_activity_state")
        |> summary_matching_contract(contract)

      summary ->
        summary
    end
  end

  defp source_and_scope(family, true = _branch_summary?) do
    {
      "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.#{family}",
      "#{family}_candidate_source_report_summary_only"
    }
  end

  defp source_and_scope(family, false = _branch_summary?) do
    {
      "candidate_refresh.source_report_provenance.#{family}",
      "#{family}_source_report_provenance_only"
    }
  end

  defp summary_from_source_reports(refresh_or_artifact, contract, callbacks) do
    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    branch_state_summary =
      refresh_or_artifact
      |> source_report_summary_branch_family.("timeline_activity_state")
      |> summary_matching_contract(contract)

    if branch_state_summary do
      {branch_state_summary, true}
    else
      state_summary =
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "timeline_activity_state"])

      state_summary
      |> summary_matching_contract(contract)
      |> case do
        nil -> nil
        state_summary -> {state_summary, false}
      end
    end
  end

  defp direct_state_summary(refresh_or_artifact, contract, source_model, callbacks) do
    source_timeline_activity_states = Keyword.fetch!(callbacks, :source_timeline_activity_states)

    source_timeline_activity_state_input_summary =
      Keyword.fetch!(callbacks, :source_timeline_activity_state_input_summary)

    refresh_or_artifact
    |> source_timeline_activity_states.()
    |> Enum.filter(fn {_path, state} ->
      Map.get(state, "schema_contract") == contract or Map.get(state, "model") == source_model
    end)
    |> source_timeline_activity_state_input_summary.()
  end

  defp summary_matching_contract(state_summary, contract) do
    contract_counts = Map.get(state_summary || %{}, "source_summary_schema_contract_counts", %{})

    cond do
      Map.get(state_summary || %{}, "contract") == contract ->
        state_summary

      map_size(contract_counts) == 1 and Map.has_key?(contract_counts, contract) ->
        state_summary

      true ->
        nil
    end
  end
end
