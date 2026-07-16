defmodule OrbitalDynamics.Schema.CampaignPlanJsonSchema do
  @moduledoc false

  @property_fields [
    "proposed_contacts",
    "activities",
    "candidate_activities",
    "contact_intents",
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

  def property("ranked_timelines", opts) do
    array_of(Keyword.fetch!(opts, :ranked_timeline_schema))
  end

  def property("warnings", _opts) do
    string_array_schema()
  end

  def ranked_timeline_from_context(stable_id_pattern, campaign_activity_schema) do
    ranked_timeline(
      stable_id_pattern: stable_id_pattern,
      campaign_activity_schema: campaign_activity_schema
    )
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
        "score_terms" => %{"type" => "object", "additionalProperties" => true},
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

  defp string_array_schema do
    %{"type" => "array", "items" => %{"type" => "string"}}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
