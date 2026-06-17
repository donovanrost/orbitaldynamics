defmodule OrbitalDynamics.Schema.Inference do
  @moduledoc false

  @campaign_plan "campaign_plan.v1"
  @campaign_repair "campaign_repair.v2"
  @campaign_strategy "campaign_strategy.v3"
  @accepted_planning_state "accepted_planning_state.v1"
  @candidate_refresh "candidate_refresh.v1"
  @execution_report "execution_report.v1"
  @manifest_field_reference "manifest_field_reference.v1"
  @proposed_contact "proposed_contact.v1"
  @result_artifact "result_artifact.v1"
  @study_benchmark "study_benchmark.v1"

  def artifact_for_validation(%{} = artifact, opts, contracts) when is_map(contracts) do
    contract_name = contract_name_from_opts(opts)

    if contract_name == @result_artifact do
      {:ok, @result_artifact, artifact}
    else
      artifact_for_validation_inferred(artifact, contract_name, contracts)
    end
  end

  def contract_name_from_opts(opts) do
    Keyword.get(opts, :contract) || Keyword.get(opts, :schema_contract)
  end

  defp artifact_for_validation_inferred(
         %{"campaign_plan" => %{} = campaign_plan},
         contract_name,
         _contracts
       ) do
    {:ok, contract_name || @campaign_plan, campaign_plan}
  end

  defp artifact_for_validation_inferred(
         %{"candidate_refresh" => %{} = candidate_refresh},
         contract_name,
         _contracts
       ) do
    {:ok, contract_name || @candidate_refresh, candidate_refresh}
  end

  defp artifact_for_validation_inferred(
         %{"schema_version" => 1, "study_id" => _study_id, "execution_report" => %{}} = artifact,
         nil,
         _contracts
       ) do
    {:ok, @result_artifact, artifact}
  end

  defp artifact_for_validation_inferred(
         %{"execution_report" => %{} = execution_report},
         contract_name,
         _contracts
       ) do
    {:ok, contract_name || @execution_report, execution_report}
  end

  defp artifact_for_validation_inferred(%{} = artifact, contract_name, contracts) do
    case contract_name || infer_contract(artifact, contracts) do
      nil -> {:error, "could not infer schema contract from artifact"}
      contract_name -> {:ok, contract_name, artifact}
    end
  end

  defp infer_contract(
         %{
           "schema_version" => 1,
           "planner" => "OrbitalDynamics.CampaignPlanner.V1"
         },
         _contracts
       ),
       do: @campaign_plan

  defp infer_contract(
         %{"schema_version" => 1, "artifact_type" => "accepted_planning_state"},
         _contracts
       ),
       do: @accepted_planning_state

  defp infer_contract(
         %{"schema_version" => 1, "artifact_type" => "candidate_refresh"},
         _contracts
       ),
       do: @candidate_refresh

  defp infer_contract(
         %{
           "reference_mode" => "study_manifest_schema_field_reference",
           "fields" => fields
         },
         _contracts
       )
       when is_list(fields),
       do: @manifest_field_reference

  defp infer_contract(
         %{"schema_version" => 1, "benchmark_options" => %{}, "results" => results},
         _contracts
       )
       when is_list(results),
       do: @study_benchmark

  defp infer_contract(%{"schema_contract" => contract_name}, contracts)
       when is_binary(contract_name) do
    if Map.has_key?(contracts, contract_name), do: contract_name
  end

  defp infer_contract(
         %{"cadence_import" => %{"schema_contract" => "proposed_contact.v1"}},
         _contracts
       ),
       do: @proposed_contact

  defp infer_contract(
         %{
           "schema_version" => 2,
           "planner" => "OrbitalDynamics.CampaignPlanner.V2"
         },
         _contracts
       ),
       do: @campaign_repair

  defp infer_contract(
         %{
           "schema_version" => 3,
           "planner" => "OrbitalDynamics.CampaignPlanner.V3"
         },
         _contracts
       ),
       do: @campaign_strategy

  defp infer_contract(_artifact, _contracts), do: nil
end
