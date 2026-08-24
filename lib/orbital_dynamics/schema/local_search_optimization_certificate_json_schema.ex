defmodule OrbitalDynamics.Schema.LocalSearchOptimizationCertificateJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Optimizer.LocalSearchCertificate

  @count_fields ~w(
    budget_used budget_remaining evaluated_count eligible_count rejected_count unevaluated_count
  )
  @boolean_fields ~w(global_optimality_claimed budget_limited search_space_exhausted)
  @stable_id_pattern "^[A-Za-z0-9][A-Za-z0-9._:@-]*(?![\\s\\S])"
  @score_term_name_pattern "^[A-Za-z][A-Za-z0-9_.-]*(?![\\s\\S])"
  @sha256_pattern "^[0-9a-f]{64}(?![\\s\\S])"

  def property("schema_contract", _stable_id_pattern),
    do: %{"type" => "string", "const" => LocalSearchCertificate.schema_contract()}

  def property("id", _stable_id_pattern),
    do: stable_id_schema()

  def property("model", _stable_id_pattern),
    do: %{"type" => "string", "const" => LocalSearchCertificate.model()}

  def property(field, _stable_id_pattern) when field in ["objective", "incumbent_update_rule"],
    do: %{"type" => "string", "minLength" => 1}

  def property("objective_direction", _stable_id_pattern),
    do: %{"type" => "string", "enum" => ["maximize", "minimize"]}

  def property("claim", _stable_id_pattern), do: claim_schema()
  def property("search_space", _stable_id_pattern), do: search_space_schema()

  def property("source_evidence_registry", _stable_id_pattern),
    do: source_evidence_registry_schema()

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

  def property("selected_alternative_id", _stable_id_pattern),
    do: nullable_stable_id_schema()

  def property("selected_score", _stable_id_pattern),
    do: %{"type" => ["number", "null"]}

  def property("eligible_ids_by_rank", _stable_id_pattern),
    do: stable_id_array()

  def property("evaluations", _stable_id_pattern),
    do: %{"type" => "array", "items" => evaluation_schema()}

  def property("deterministic_ordering", _stable_id_pattern), do: string_array()

  def property("model_limits", _stable_id_pattern) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => LocalSearchCertificate.model_limits()}
    }
  end

  def property("assumptions", _stable_id_pattern),
    do: %{"type" => "object", "additionalProperties" => true}

  defp claim_schema do
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
        "selected_alternative_id" => nullable_stable_id_schema(),
        "reason" => %{"type" => "string", "minLength" => 1},
        "global_optimality_claimed" => %{"type" => "boolean", "const" => false}
      }
    )
  end

  defp search_space_schema do
    object_schema(
      ~w(
        generator_model seed_id seed_parameters step_parameters steps bounds ordering id_prefix
        candidate_count generation_attempt_count generation_rejected_count candidates
        generation_rejected_moves identity
      ),
      %{
        "generator_model" => %{"type" => "string"},
        "seed_id" => stable_id_schema(),
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
        "id_prefix" => stable_id_schema(),
        "candidate_count" => non_negative_integer(),
        "generation_attempt_count" => non_negative_integer(),
        "generation_rejected_count" => non_negative_integer(),
        "candidates" => %{
          "type" => "array",
          "items" => candidate_schema()
        },
        "generation_rejected_moves" => %{
          "type" => "array",
          "items" => %{"type" => "object", "additionalProperties" => true}
        },
        "identity" => identity_schema()
      }
    )
  end

  defp candidate_schema do
    object_schema(~w(id generation_index parameters move), %{
      "id" => stable_id_schema(),
      "generation_index" => non_negative_integer(),
      "parameters" => numeric_map(),
      "move" => %{"type" => "object", "additionalProperties" => true}
    })
  end

  defp source_evidence_registry_schema do
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
              "alternative_id" => stable_id_schema(),
              "source_id" => stable_id_schema(),
              "source_revision" => stable_id_schema(),
              "content_identity" => identity_schema()
            }
          )
      },
      "identity" => identity_schema()
    })
  end

  defp evaluation_schema do
    object_schema(
      ~w(
        alternative_id generation_index source_evidence_identity score_terms score eligible
        rejection_reasons incumbent_after_evaluation_id rank
      ),
      %{
        "alternative_id" => stable_id_schema(),
        "generation_index" => non_negative_integer(),
        "source_evidence_identity" => identity_schema(),
        "score_terms" => numeric_map(),
        "score" => %{"type" => "number"},
        "eligible" => %{"type" => "boolean"},
        "rejection_reasons" => string_array(),
        "incumbent_after_evaluation_id" => nullable_stable_id_schema(),
        "rank" => %{"type" => ["integer", "null"], "minimum" => 1}
      }
    )
  end

  defp identity_schema do
    object_schema(~w(algorithm sha256), %{
      "algorithm" => %{"type" => "string", "const" => LocalSearchCertificate.identity_algorithm()},
      "sha256" => %{"type" => "string", "pattern" => @sha256_pattern}
    })
  end

  defp numeric_map do
    %{
      "type" => "object",
      "minProperties" => 1,
      "propertyNames" => %{"pattern" => @score_term_name_pattern},
      "additionalProperties" => %{"type" => "number"}
    }
  end

  defp stable_id_array,
    do: %{"type" => "array", "items" => stable_id_schema()}

  defp stable_id_schema, do: %{"type" => "string", "pattern" => @stable_id_pattern}

  defp nullable_stable_id_schema,
    do: %{"type" => ["string", "null"], "pattern" => @stable_id_pattern}

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
