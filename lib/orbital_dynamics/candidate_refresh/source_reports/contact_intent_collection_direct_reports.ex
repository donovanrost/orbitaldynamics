defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentCollectionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntent

  def reports(refresh) do
    [
      {"accepted_planning_state.source_contact_intent",
       get_in(refresh, ["accepted_planning_state", "source_contact_intent"])},
      {"accepted_planning_state.source_contact_intents",
       get_in(refresh, ["accepted_planning_state", "source_contact_intents"])},
      {"accepted_planning_state.source_contact_intent_summary",
       get_in(refresh, ["accepted_planning_state", "source_contact_intent_summary"])},
      {"accepted_planning_state.contact_intent_summary",
       get_in(refresh, ["accepted_planning_state", "contact_intent_summary"])},
      {"accepted_planning_state.contact_intent",
       get_in(refresh, ["accepted_planning_state", "contact_intent"])},
      {"accepted_planning_state.contact_intents",
       get_in(refresh, ["accepted_planning_state", "contact_intents"])},
      {"mission_state.source_contact_intent",
       get_in(refresh, ["mission_state", "source_contact_intent"])},
      {"mission_state.source_contact_intents",
       get_in(refresh, ["mission_state", "source_contact_intents"])},
      {"mission_state.source_contact_intent_summary",
       get_in(refresh, ["mission_state", "source_contact_intent_summary"])},
      {"mission_state.contact_intent_summary",
       get_in(refresh, ["mission_state", "contact_intent_summary"])},
      {"mission_state.contact_intent", get_in(refresh, ["mission_state", "contact_intent"])},
      {"mission_state.contact_intents", get_in(refresh, ["mission_state", "contact_intents"])},
      {"source_contact_intent", Map.get(refresh, "source_contact_intent")},
      {"source_contact_intents", Map.get(refresh, "source_contact_intents")},
      {"source_contact_intent_summary", Map.get(refresh, "source_contact_intent_summary")},
      {"contact_intent_summary", Map.get(refresh, "contact_intent_summary")},
      {"contact_intent", Map.get(refresh, "contact_intent")},
      {"contact_intents", Map.get(refresh, "contact_intents")}
    ]
    |> Enum.flat_map(fn {path, intent_or_intents} ->
      ContactIntent.entries(path, intent_or_intents)
    end)
  end
end
