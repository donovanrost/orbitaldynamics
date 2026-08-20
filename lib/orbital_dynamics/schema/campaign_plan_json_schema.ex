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
    "provenance",
    "optimizer_search_trace",
    "target_commitments",
    "ranking_explanation",
    "ranked_timelines",
    "warnings"
  ]

  @contact_activity_types ["downlink", "command", "tracking", "health_check"]

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
    opts
    |> Keyword.fetch!(:campaign_activity_schema)
    |> with_activity_constraints()
    |> array_of()
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

  def property("provenance", _opts) do
    nullable_string = %{"type" => ["string", "null"], "minLength" => 1}

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["run_id", "manifest", "git_revision", "propagator", "propagator_opts"],
      "properties" => %{
        "run_id" => nullable_string,
        "manifest" => %{
          "type" => ["object", "null"],
          "additionalProperties" => true,
          "properties" => %{
            "path" => nullable_string,
            "sha256" => %{
              "type" => ["string", "null"],
              "pattern" => "^[0-9a-f]{64}$"
            }
          }
        },
        "git_revision" => nullable_string,
        "propagator" => nullable_string,
        "propagator_opts" => %{"type" => ["object", "null"]}
      }
    }
  end

  def property("optimizer_search_trace", _opts) do
    OrbitalDynamics.Schema.CampaignPlanSearchTraceJsonSchema.json_schema()
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
    opts
    |> Keyword.fetch!(:ranked_timeline_schema)
    |> update_in(
      ["properties", "activities", "items"],
      &with_activity_constraints/1
    )
    |> array_of()
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
          "required" => [
            "activity_score",
            "activity_count_penalty",
            "selected_observation_count",
            "selected_contact_count",
            "target_value",
            "contact_value",
            "eclipse_penalty"
          ],
          "properties" => %{
            "activity_score" => %{"type" => "number"},
            "activity_count_penalty" => %{"type" => "number"},
            "selected_observation_count" => %{"type" => "integer", "minimum" => 0},
            "selected_contact_count" => %{"type" => "integer", "minimum" => 0},
            "target_value" => %{"type" => "number"},
            "contact_value" => %{"type" => "number"},
            "eclipse_penalty" => %{"type" => "number"}
          },
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

  defp with_activity_constraints(activity_schema) do
    activity_schema
    |> update_in(["required"], &Enum.uniq(&1 ++ ["cadence_import"]))
    |> put_in(
      ["properties", "type"],
      %{"type" => "string", "minLength" => 1, "pattern" => "\\S"}
    )
    |> update_in(["properties", "duration_s"], &Map.put(&1, "minimum", 0.0))
    |> put_in(
      ["properties", "score_terms", "additionalProperties"],
      %{"type" => "number"}
    )
    |> update_in(["properties", "source_window"], fn source_window_schema ->
      Map.put(source_window_schema, "required", ["id"])
    end)
    |> put_in(
      ["properties", "cadence_import"],
      %{
        "type" => "object",
        "additionalProperties" => true,
        "required" => ["external_id", "activity_type"],
        "properties" => %{
          "external_id" => %{
            "type" => "string",
            "pattern" => OrbitalDynamics.Schema.StableIdValidation.pattern()
          },
          "activity_type" => %{
            "type" => "string",
            "minLength" => 1,
            "pattern" => "\\S"
          }
        }
      }
    )
    |> Map.update("allOf", conditional_activity_constraints(), fn constraints ->
      constraints ++ conditional_activity_constraints()
    end)
  end

  defp conditional_activity_constraints do
    contact_activity_constraints() ++
      cadence_activity_type_constraints() ++
      source_window_type_constraints() ++ cadence_schema_contract_constraints()
  end

  defp contact_activity_constraints do
    Enum.map(@contact_activity_types, fn type ->
      %{
        "if" => %{
          "required" => ["type"],
          "properties" => %{"type" => %{"const" => type}}
        },
        "then" => %{
          "required" => ["ground_station_id", "direction"],
          "properties" => %{"direction" => %{"const" => type}}
        }
      }
    end)
  end

  defp cadence_activity_type_constraints do
    Enum.map(
      OrbitalDynamics.Schema.CampaignPlanActivityCadenceContracts.activity_type_mappings(),
      fn {activity_type, cadence_type} ->
        %{
          "if" => %{
            "required" => ["type"],
            "properties" => %{"type" => %{"const" => activity_type}}
          },
          "then" => %{
            "properties" => %{
              "cadence_import" => %{
                "properties" => %{"activity_type" => %{"const" => cadence_type}}
              }
            }
          }
        }
      end
    )
  end

  defp source_window_type_constraints do
    Enum.map(
      OrbitalDynamics.Schema.CampaignPlanActivitySourceWindowTypeContracts.activity_type_mappings(),
      fn {activity_type, source_window_type} ->
        %{
          "if" => %{
            "required" => ["type"],
            "properties" => %{"type" => %{"const" => activity_type}}
          },
          "then" => %{
            "properties" => %{
              "source_window" => %{
                "required" => ["type"],
                "properties" => %{"type" => %{"const" => source_window_type}}
              }
            }
          }
        }
      end
    )
  end

  defp cadence_schema_contract_constraints do
    Enum.map(
      OrbitalDynamics.Schema.CampaignPlanActivityCadenceSchemaContracts.activity_type_mappings(),
      fn {activity_type, schema_contract} ->
        %{
          "if" => %{
            "required" => ["type"],
            "properties" => %{"type" => %{"const" => activity_type}}
          },
          "then" => %{
            "properties" => %{
              "cadence_import" => %{
                "required" => ["schema_contract"],
                "properties" => %{"schema_contract" => %{"const" => schema_contract}}
              }
            }
          }
        }
      end
    )
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
