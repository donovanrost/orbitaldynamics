defmodule OrbitalDynamics.Schema.CampaignPlanJsonSchema do
  @moduledoc false

  @property_fields [
    "proposed_contacts",
    "activities",
    "assumptions",
    "candidate_activities",
    "contact_intents",
    "generated_at",
    "planning_horizon",
    "target_commitments",
    "ranking_explanation",
    "ranked_timelines",
    "warnings"
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property(field, property_opts(field, deps))
    end
  end

  def property_opts("proposed_contacts", deps) do
    [proposed_contact_schema: fetch_dep!(deps, :proposed_contact_schema)]
  end

  def property_opts(field, deps) when field in ["activities", "candidate_activities"] do
    [campaign_activity_schema: fetch_dep!(deps, :campaign_activity_schema)]
  end

  def property_opts("contact_intents", deps) do
    [contact_intent_schema: fetch_dep!(deps, :contact_intent_schema)]
  end

  def property_opts("target_commitments", deps) do
    [target_commitment_schema: fetch_dep!(deps, :target_commitment_schema)]
  end

  def property_opts("ranked_timelines", deps) do
    [ranked_timeline_schema: fetch_dep!(deps, :ranked_timeline_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property("proposed_contacts", opts) do
    array_of(Keyword.fetch!(opts, :proposed_contact_schema))
  end

  def property(field, opts) when field in ["activities", "candidate_activities"] do
    array_of(Keyword.fetch!(opts, :campaign_activity_schema))
  end

  def property("contact_intents", opts) do
    array_of(Keyword.fetch!(opts, :contact_intent_schema))
  end

  def property("target_commitments", opts) do
    array_of(Keyword.fetch!(opts, :target_commitment_schema))
  end

  def property("generated_at", _opts) do
    %{"type" => "string", "format" => "date-time"}
  end

  def property("assumptions", _opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "activity_builder",
        "timeline_selector",
        "resource_filter",
        "contact_filter",
        "cadence_integration",
        "constraints",
        "scoring_policy"
      ],
      "properties" => %{
        "activity_builder" => %{
          "type" => "string",
          "const" => "windows_to_observe_and_downlink_candidates"
        },
        "timeline_selector" => %{
          "type" => "string",
          "const" => "per_spacecraft_greedy_non_overlapping"
        },
        "resource_filter" => %{
          "type" => "string",
          "const" => "resource_summary_availability_and_margin_filter"
        },
        "contact_filter" => %{
          "type" => "string",
          "const" => "ground_network_availability_filter_before_ranking"
        },
        "cadence_integration" => %{
          "type" => "string",
          "const" => "artifact_only_no_api_or_database_writes"
        },
        "constraints" => %{"type" => "object"},
        "scoring_policy" => %{"type" => "object"}
      }
    }
  end

  def property("planning_horizon", _opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "dependentRequired" => %{"output_step_s" => ["duration_s"]},
      "properties" => %{
        "duration_s" => %{"type" => "number", "exclusiveMinimum" => 0.0},
        "output_step_s" => %{"type" => "number", "exclusiveMinimum" => 0.0}
      }
    }
  end

  def property("ranked_timelines", opts) do
    array_of(Keyword.fetch!(opts, :ranked_timeline_schema))
  end

  def property("ranking_explanation", _opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["objective", "formula", "policy"],
      "properties" => %{
        "objective" => %{"type" => "string"},
        "formula" => %{"type" => "string"},
        "policy" => %{
          "type" => "object",
          "additionalProperties" => true
        }
      }
    }
  end

  def property("warnings", _opts) do
    %{
      "type" => "array",
      "uniqueItems" => true,
      "items" => %{"type" => "string", "minLength" => 1, "pattern" => "\\S"}
    }
  end

  def ranked_timeline_from_context(stable_id_pattern, campaign_activity_schema) do
    ranked_timeline(
      stable_id_pattern: stable_id_pattern,
      campaign_activity_schema: campaign_activity_schema
    )
  end

  def target_commitment_from_context(stable_id_pattern) when is_binary(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "target_id",
        "candidate_activity_count",
        "candidate_duration_s",
        "selected_activity_count",
        "selected_duration_s",
        "selected_activity_ids",
        "status"
      ],
      "properties" => %{
        "target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "priority" => OrbitalDynamics.Schema.CommonJsonSchema.number_or_string(),
        "candidate_activity_count" => %{"type" => "integer", "minimum" => 0},
        "candidate_duration_s" => %{"type" => "number", "minimum" => 0.0},
        "selected_activity_count" => %{"type" => "integer", "minimum" => 0},
        "selected_duration_s" => %{"type" => "number", "minimum" => 0.0},
        "selected_activity_ids" => %{
          "type" => "array",
          "uniqueItems" => true,
          "items" => %{"type" => "string", "pattern" => stable_id_pattern}
        },
        "status" => %{
          "type" => "string",
          "enum" => ["selected", "candidate_available", "no_candidate_window"]
        }
      }
    }
  end

  def ranked_timeline_from_context(deps) when is_list(deps) do
    ranked_timeline(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      campaign_activity_schema: fetch_dep!(deps, :campaign_activity_schema)
    )
  end

  def ranked_timeline(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "scenario_id",
        "score",
        "score_terms",
        "activity_count",
        "activities"
      ],
      "properties" => %{
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "score" => %{"type" => "number"},
        "score_terms" => %{
          "type" => "object",
          "additionalProperties" => %{"type" => "number"}
        },
        "activity_count" => %{"type" => "integer"},
        "activities" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :campaign_activity_schema)
        }
      }
    }
  end

  defp array_of(item_schema) do
    %{
      "type" => "array",
      "items" => item_schema
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
