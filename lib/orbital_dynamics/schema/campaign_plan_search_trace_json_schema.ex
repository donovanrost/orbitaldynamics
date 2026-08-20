defmodule OrbitalDynamics.Schema.CampaignPlanSearchTraceJsonSchema do
  @moduledoc false

  @required_fields ~w(
    schema_contract id plan_id status selection_contract objective objective_direction
    base_scoring_policy selected_scoring_policy searched_scoring_policy_keys fixed_constraints
    selected_alternative_id selected_alternative selected_timeline_scenario_id
    selected_timeline_score selected_activity_ids selected_activity_count search_root search_result
  )

  def property_field?(field) when field in @required_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(field, _context), do: property(field)

  def json_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => @required_fields,
      "properties" => Map.new(@required_fields, &{&1, property(&1)})
    }
  end

  def property("schema_contract"),
    do: %{"type" => "string", "const" => "campaign_plan_search_trace.v1"}

  def property(field) when field in ["id", "plan_id"] do
    %{
      "type" => "string",
      "pattern" => OrbitalDynamics.Schema.StableIdValidation.pattern()
    }
  end

  def property("status"),
    do: %{"type" => "string", "enum" => ["selected_plan", "no_selected_plan"]}

  def property("selection_contract"),
    do: %{"type" => "string", "const" => "v1_outer_local_search_inner_greedy"}

  def property("objective"),
    do: %{"type" => "string", "const" => "maximize first ranked timeline aggregate score"}

  def property("objective_direction"), do: %{"type" => "string", "const" => "maximize"}

  def property("base_scoring_policy"), do: scoring_policy_schema()

  def property("selected_scoring_policy") do
    scoring_policy_schema()
    |> Map.put("type", ["object", "null"])
  end

  def property("searched_scoring_policy_keys") do
    %{
      "type" => "array",
      "minItems" => 1,
      "uniqueItems" => true,
      "items" => %{
        "type" => "string",
        "enum" => OrbitalDynamics.CampaignPlanner.LocalSearchSelection.numeric_policy_keys()
      }
    }
  end

  def property("fixed_constraints"), do: %{"type" => "object", "additionalProperties" => true}

  def property(field)
      when field in ["selected_alternative_id", "selected_timeline_scenario_id"] do
    %{
      "type" => ["string", "null"],
      "pattern" => OrbitalDynamics.Schema.StableIdValidation.pattern()
    }
  end

  def property("selected_alternative") do
    alternative_schema()
    |> Map.put("type", ["object", "null"])
  end

  def property("selected_timeline_score"), do: %{"type" => ["number", "null"]}

  def property("selected_activity_ids") do
    %{
      "type" => "array",
      "uniqueItems" => true,
      "items" => %{
        "type" => "string",
        "pattern" => OrbitalDynamics.Schema.StableIdValidation.pattern()
      }
    }
  end

  def property("selected_activity_count"), do: %{"type" => "integer", "minimum" => 0}
  def property("search_root"), do: search_root_schema()
  def property("search_result"), do: search_result_schema()

  defp search_root_schema do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => ~w(
        binding_contract id plan_id base_scoring_policy fixed_constraints
        source_evidence_registry source_evidence_registry_entries
        source_candidate_evidence alternative_plan_bindings
      ),
      "properties" => %{
        "binding_contract" => %{
          "type" => "string",
          "const" => "campaign_plan_search_root.v1"
        },
        "id" => stable_id_schema(),
        "plan_id" => stable_id_schema(),
        "base_scoring_policy" => scoring_policy_schema(),
        "fixed_constraints" => %{"type" => "object"},
        "source_evidence_registry" => %{"type" => "object"},
        "source_evidence_registry_entries" => %{
          "type" => "array",
          "items" => %{"type" => "object"}
        },
        "source_candidate_evidence" => %{
          "type" => "array",
          "items" => %{"type" => "object"}
        },
        "alternative_plan_bindings" => %{
          "type" => "array",
          "items" => %{"type" => "object"}
        }
      }
    }
  end

  defp scoring_policy_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" =>
        Map.new(
          OrbitalDynamics.CampaignPlanner.LocalSearchSelection.numeric_policy_keys(),
          &{&1, %{"type" => "number"}}
        )
    }
  end

  defp search_result_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ~w(
        model objective objective_direction seed_id seed_score selected_id selected_score
        improved improvement_from_seed evaluated_count eligible_count infeasible_count
        feasibility_mode source_evidence_registry candidate_feasibility_evaluations
        recommendation_outcome feasibility_transition alternatives rejected_moves neighborhood
        deterministic_ordering model_limits assumptions
      ),
      "properties" => %{
        "model" => %{
          "type" => "string",
          "const" => "deterministic_bounded_axis_step_local_search"
        },
        "objective" => property("objective"),
        "objective_direction" => property("objective_direction"),
        "seed_id" => stable_id_schema(),
        "seed_score" => %{"type" => "number"},
        "selected_id" => nullable_stable_id_schema(),
        "selected_score" => %{"type" => ["number", "null"]},
        "improved" => %{"type" => "boolean"},
        "improvement_from_seed" => %{"type" => ["number", "null"]},
        "evaluated_count" => count_schema(),
        "eligible_count" => count_schema(),
        "infeasible_count" => count_schema(),
        "feasibility_mode" => %{"type" => "string", "const" => "hard"},
        "source_evidence_registry" => %{"type" => "object"},
        "candidate_feasibility_evaluations" => %{
          "type" => "array",
          "items" => feasibility_schema()
        },
        "recommendation_outcome" => %{"type" => "object"},
        "feasibility_transition" => %{"type" => ["object", "null"]},
        "alternatives" => %{"type" => "array", "minItems" => 1, "items" => alternative_schema()},
        "rejected_moves" => %{"type" => "array", "items" => %{"type" => "object"}},
        "neighborhood" => %{"type" => "object"},
        "deterministic_ordering" => %{
          "type" => "array",
          "items" => %{"type" => "string"}
        },
        "model_limits" => %{"type" => "array", "items" => %{"type" => "string"}},
        "assumptions" => %{"type" => "object"}
      }
    }
  end

  defp alternative_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ~w(
        id generation_index parameters move score_terms score rank candidate_feasibility
        score_delta_from_seed selected selection_explanation
      ),
      "properties" => %{
        "id" => stable_id_schema(),
        "generation_index" => count_schema(),
        "parameters" => finite_number_map_schema(),
        "move" => %{"type" => "object"},
        "score_terms" => finite_number_map_schema(),
        "score" => %{"type" => "number"},
        "rank" => %{"type" => ["integer", "null"], "minimum" => 1},
        "candidate_feasibility" => feasibility_schema(),
        "score_delta_from_seed" => %{"type" => "number"},
        "selected" => %{"type" => "boolean"},
        "selection_explanation" => %{"type" => "string"}
      }
    }
  end

  defp feasibility_schema do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ~w(
        schema_contract mode alternative_id parameter_revision parameter_content_identity
        source_evidence_registry_id spacecraft_id status eligible evidence_bindings
        threshold_evaluations blocker_reasons blockers model_limits
      )
    }
  end

  defp finite_number_map_schema do
    %{
      "type" => "object",
      "minProperties" => 1,
      "additionalProperties" => %{"type" => "number"}
    }
  end

  defp count_schema, do: %{"type" => "integer", "minimum" => 0}

  defp stable_id_schema do
    %{"type" => "string", "pattern" => OrbitalDynamics.Schema.StableIdValidation.pattern()}
  end

  defp nullable_stable_id_schema do
    stable_id_schema()
    |> Map.put("type", ["string", "null"])
  end
end
