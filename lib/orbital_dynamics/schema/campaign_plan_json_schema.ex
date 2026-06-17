defmodule OrbitalDynamics.Schema.CampaignPlanJsonSchema do
  @moduledoc false

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

  defp array_of(item_schema) do
    %{
      "type" => "array",
      "items" => item_schema
    }
  end
end
