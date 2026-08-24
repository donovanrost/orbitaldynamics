defmodule OrbitalDynamics.Validation.ArtifactObservations.LocalSearchOptimizationCertificate do
  @moduledoc false

  alias OrbitalDynamics.Optimizer.LocalSearchCertificate
  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.{JsonSafety, PrimitiveValidation}

  @contract "local_search_optimization_certificate.v1"

  def build(artifact) do
    case Schema.validate_artifact(artifact, schema_contract: @contract) do
      {:ok, _report} ->
        artifact
        |> extract()
        |> ensure_json_safe()

      {:error, %{"errors" => errors}} when is_list(errors) ->
        failure(errors)

      {:error, _report} ->
        failure([PrimitiveValidation.error("$", "certificate validation failed safely")])
    end
  rescue
    _error -> failure([PrimitiveValidation.error("$", "observation extraction failed safely")])
  catch
    _kind, _reason ->
      failure([PrimitiveValidation.error("$", "observation extraction failed safely")])
  end

  defp extract(artifact) do
    search_space = map_value(artifact, "search_space")
    registry = map_value(artifact, "source_evidence_registry")
    claim = map_value(artifact, "claim")
    evaluator_policy = map_value(artifact, "evaluator_execution_policy")

    %{
      "schema_contract" => Map.get(artifact, "schema_contract"),
      "id" => Map.get(artifact, "id"),
      "identity_matches_content" => identity_matches_content?(artifact),
      "model" => Map.get(artifact, "model"),
      "objective_direction" => Map.get(artifact, "objective_direction"),
      "candidate_count" => Map.get(search_space, "candidate_count"),
      "evaluated_count" => Map.get(artifact, "evaluated_count"),
      "eligible_count" => Map.get(artifact, "eligible_count"),
      "rejected_count" => Map.get(artifact, "rejected_count"),
      "selected_alternative_id" => Map.get(artifact, "selected_alternative_id"),
      "selected_score" => Map.get(artifact, "selected_score"),
      "search_space_exhausted" => Map.get(artifact, "search_space_exhausted"),
      "budget_limited" => Map.get(artifact, "budget_limited"),
      "termination_reason" => Map.get(artifact, "termination_reason"),
      "claim_status" => Map.get(claim, "status"),
      "claim_type" => Map.get(claim, "type"),
      "claim_scope" => Map.get(claim, "scope"),
      "global_optimality_claimed" => Map.get(artifact, "global_optimality_claimed"),
      "source_evidence_registry_entry_count" => Map.get(registry, "entry_count"),
      "source_evidence_registry_sha256" => registry |> map_value("identity") |> Map.get("sha256"),
      "evaluator_policy_version" => Map.get(evaluator_policy, "policy_version"),
      "evaluator_timeout_ms" => Map.get(evaluator_policy, "timeout_ms"),
      "model_limit_count" => count(artifact, "model_limits")
    }
  end

  defp ensure_json_safe(observations) do
    case JsonSafety.errors(observations) do
      [] -> observations
      errors -> failure(errors)
    end
  end

  defp failure(errors) do
    safe_errors =
      case JsonSafety.errors(errors, "$.errors") do
        [] -> errors
        safety_errors -> safety_errors
      end

    %{
      "contract" => @contract,
      "status" => "error",
      "reason" => "artifact_observation_input_invalid",
      "errors" => safe_errors
    }
  end

  defp identity_matches_content?(artifact) do
    case LocalSearchCertificate.certificate_id(Map.delete(artifact, "id")) do
      expected_id when is_binary(expected_id) -> Map.get(artifact, "id") == expected_id
      {:error, _failure} -> false
    end
  end

  defp count(map, key) do
    case Map.get(map, key) do
      rows when is_list(rows) -> length(rows)
      _rows -> 0
    end
  end

  defp map_value(map, key) do
    case Map.get(map, key) do
      value when is_map(value) -> value
      _value -> %{}
    end
  end
end
