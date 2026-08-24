defmodule OrbitalDynamics.Schema.LocalSearchOptimizationCertificateJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Optimizer.LocalSearchCertificate

  @count_fields ~w(
    budget_used budget_remaining evaluated_count eligible_count rejected_count unevaluated_count
  )
  @boolean_fields ~w(global_optimality_claimed budget_limited search_space_exhausted)

  def property("schema_contract", _stable_id_pattern),
    do: %{"type" => "string", "const" => LocalSearchCertificate.schema_contract()}

  def property("id", stable_id_pattern),
    do: %{"type" => "string", "pattern" => stable_id_pattern}

  def property("model", _stable_id_pattern),
    do: %{"type" => "string", "const" => LocalSearchCertificate.model()}

  def property(field, _stable_id_pattern) when field in ["objective", "incumbent_update_rule"],
    do: %{"type" => "string", "minLength" => 1}

  def property("objective_direction", _stable_id_pattern),
    do: %{"type" => "string", "enum" => ["maximize", "minimize"]}

  def property("claim", stable_id_pattern), do: claim_schema(stable_id_pattern)
  def property("search_space", stable_id_pattern), do: search_space_schema(stable_id_pattern)

  def property("source_evidence_registry", stable_id_pattern),
    do: source_evidence_registry_schema(stable_id_pattern)

  def property("evaluation_budget", _stable_id_pattern) do
    %{
      "type" => "integer",
      "minimum" => 1,
      "maximum" => LocalSearchCertificate.max_evaluations()
    }
  end

  def property(field, _stable_id_pattern) when field in @count_fields,
    do: %{"type" => "integer", "minimum" => 0}

  def property(field, _stable_id_pattern) when field in @boolean_fields,
    do: %{"type" => "boolean"}

  def property("termination_reason", _stable_id_pattern) do
    %{
      "type" => "string",
      "enum" => ["search_space_exhausted", "evaluation_budget_exhausted"]
    }
  end

  def property("selected_alternative_id", stable_id_pattern),
    do: %{"type" => ["string", "null"], "pattern" => stable_id_pattern}

  def property("selected_score", _stable_id_pattern),
    do: %{"type" => ["number", "null"]}

  def property("eligible_ids_by_rank", stable_id_pattern),
    do: stable_id_array(stable_id_pattern)

  def property("evaluations", stable_id_pattern),
    do: %{"type" => "array", "items" => evaluation_schema(stable_id_pattern)}

  def property("deterministic_ordering", _stable_id_pattern), do: string_array()

  def property("model_limits", _stable_id_pattern) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => LocalSearchCertificate.model_limits()}
    }
  end

  def property("assumptions", _stable_id_pattern),
    do: %{"type" => "object", "additionalProperties" => true}

  defp claim_schema(stable_id_pattern) do
    object_schema(
      ~w(status type scope selected_alternative_id reason global_optimality_claimed),
      %{
        "status" => %{"type" => "string", "enum" => ["supported", "not_supported"]},
        "type" => %{
          "type" => "string",
          "enum" => [
            "best_eligible_alternative_in_enumerated_finite_neighborhood",
            "no_eligible_alternative_in_enumerated_finite_neighborhood",
            "no_optimality_claim"
          ]
        },
        "scope" => %{"type" => "string", "const" => "enumerated_search_space_only"},
        "selected_alternative_id" => %{
          "type" => ["string", "null"],
          "pattern" => stable_id_pattern
        },
        "reason" => %{"type" => "string", "minLength" => 1},
        "global_optimality_claimed" => %{"type" => "boolean", "const" => false}
      }
    )
  end

  defp search_space_schema(stable_id_pattern) do
    object_schema(
      ~w(
        generator_model seed_id seed_parameters step_parameters steps bounds ordering id_prefix
        candidate_count generation_attempt_count generation_rejected_count candidates
        generation_rejected_moves identity
      ),
      %{
        "generator_model" => %{"type" => "string"},
        "seed_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "seed_parameters" => numeric_map(),
        "step_parameters" => string_array(),
        "steps" => numeric_map(),
        "bounds" => %{
          "type" => "object",
          "additionalProperties" =>
            object_schema(~w(minimum maximum), %{
              "minimum" => %{"type" => "number"},
              "maximum" => %{"type" => "number"}
            })
        },
        "ordering" => %{"type" => "string"},
        "id_prefix" => %{"type" => "string", "minLength" => 1},
        "candidate_count" => non_negative_integer(),
        "generation_attempt_count" => non_negative_integer(),
        "generation_rejected_count" => non_negative_integer(),
        "candidates" => %{
          "type" => "array",
          "items" => candidate_schema(stable_id_pattern)
        },
        "generation_rejected_moves" => %{
          "type" => "array",
          "items" => %{"type" => "object", "additionalProperties" => true}
        },
        "identity" => identity_schema()
      }
    )
  end

  defp candidate_schema(stable_id_pattern) do
    object_schema(~w(id generation_index parameters move), %{
      "id" => %{"type" => "string", "pattern" => stable_id_pattern},
      "generation_index" => non_negative_integer(),
      "parameters" => numeric_map(),
      "move" => %{"type" => "object", "additionalProperties" => true}
    })
  end

  defp source_evidence_registry_schema(stable_id_pattern) do
    object_schema(~w(trust_boundary entry_count entries identity), %{
      "trust_boundary" => %{
        "type" => "string",
        "const" => LocalSearchCertificate.source_trust_boundary()
      },
      "entry_count" => non_negative_integer(),
      "entries" => %{
        "type" => "array",
        "items" =>
          object_schema(
            ~w(alternative_id source_id source_revision content_identity),
            %{
              "alternative_id" => %{"type" => "string", "pattern" => stable_id_pattern},
              "source_id" => %{"type" => "string", "pattern" => stable_id_pattern},
              "source_revision" => %{"type" => "string", "pattern" => stable_id_pattern},
              "content_identity" => identity_schema()
            }
          )
      },
      "identity" => identity_schema()
    })
  end

  defp evaluation_schema(stable_id_pattern) do
    object_schema(
      ~w(
        alternative_id generation_index source_evidence_identity score_terms score eligible
        rejection_reasons incumbent_after_evaluation_id rank
      ),
      %{
        "alternative_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "generation_index" => non_negative_integer(),
        "source_evidence_identity" => identity_schema(),
        "score_terms" => numeric_map(),
        "score" => %{"type" => "number"},
        "eligible" => %{"type" => "boolean"},
        "rejection_reasons" => string_array(),
        "incumbent_after_evaluation_id" => %{
          "type" => ["string", "null"],
          "pattern" => stable_id_pattern
        },
        "rank" => %{"type" => ["integer", "null"], "minimum" => 1}
      }
    )
  end

  defp identity_schema do
    object_schema(~w(algorithm sha256), %{
      "algorithm" => %{"type" => "string", "const" => LocalSearchCertificate.identity_algorithm()},
      "sha256" => %{"type" => "string", "pattern" => "^[0-9a-f]{64}$"}
    })
  end

  defp numeric_map do
    %{
      "type" => "object",
      "minProperties" => 1,
      "additionalProperties" => %{"type" => "number"}
    }
  end

  defp stable_id_array(stable_id_pattern),
    do: %{"type" => "array", "items" => %{"type" => "string", "pattern" => stable_id_pattern}}

  defp string_array, do: %{"type" => "array", "items" => %{"type" => "string"}}
  defp non_negative_integer, do: %{"type" => "integer", "minimum" => 0}

  defp object_schema(required, properties) do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => required,
      "properties" => properties
    }
  end
end
