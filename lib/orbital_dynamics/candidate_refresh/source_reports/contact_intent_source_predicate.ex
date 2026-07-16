defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactIntentSourcePredicate do
  @moduledoc false

  def source?(%{} = source), do: intent?(source) or summary?(source)
  def source?(_source), do: false

  defp intent?(%{} = intent) do
    schema_contract = Map.get(intent, "schema_contract") || Map.get(intent, :schema_contract)
    id = Map.get(intent, "id") || Map.get(intent, :id) || Map.get(intent, "activity_id")
    station_id = Map.get(intent, "ground_station_id") || Map.get(intent, :ground_station_id)

    schema_contract in [nil, "contact_intent.v1"] and id not in [nil, ""] and
      station_id not in [nil, ""]
  end

  defp summary?(%{} = summary) do
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)
    schema_contract == "contact_intent_summary.v1"
  end
end
