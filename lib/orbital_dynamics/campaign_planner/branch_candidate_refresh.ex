defmodule OrbitalDynamics.CampaignPlanner.BranchCandidateRefresh do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.CandidateRefreshRequest
  alias OrbitalDynamics.Study.Manifest

  alias OrbitalDynamics.{
    CandidateRefresh,
    StudyRunner
  }

  def request(branch, request, derive_request_fun) do
    cond do
      Map.get(branch, "candidate_refresh_request") ->
        Map.get(branch, "candidate_refresh_request")

      Map.get(branch, "candidate_refresh") ->
        nil

      true ->
        derive_request_fun.(branch, request)
    end
  end

  def refresh(branch, request, candidate_refresh_request, source_plan_id) do
    cond do
      Map.get(branch, "candidate_refresh") ->
        Map.get(branch, "candidate_refresh")

      candidate_refresh_request ->
        branch
        |> Map.put("candidate_refresh_request", candidate_refresh_request)
        |> execute(request, source_plan_id)

      true ->
        request.candidate_refresh
    end
  end

  defp execute(branch, request, source_plan_id) do
    manifest_source =
      branch["candidate_refresh_request"]
      |> CandidateRefreshRequest.manifest(
        "branch_refresh_#{branch["id"]}",
        metadata(branch, source_plan_id)
      )

    with {:ok, manifest} <- Manifest.from_map(manifest_source),
         {:ok, result_set} <- StudyRunner.run(manifest.study, manifest.run_opts) do
      CandidateRefresh.build(result_set,
        candidate_refresh: manifest.study.metadata["candidate_refresh"],
        generated_at: request.generated_at
      )
    else
      {:error, reason} ->
        raise ArgumentError,
              "invalid branch candidate_refresh_request for #{branch["id"]}: #{inspect(reason)}"
    end
  end

  defp metadata(branch, source_plan_id) do
    %{
      "strategy_branch_id" => branch["id"],
      "strategy_source_plan_id" => source_plan_id,
      "strategy_branch_events" => branch["events"]
    }
  end
end
