defmodule OrbitalDynamics.CampaignPlanner.ResourceMarginPressureEvents do
  @moduledoc false

  def build(mission_state, sources, policy, field, threshold_key, reason, callbacks) do
    resource_spacecraft_id = Keyword.fetch!(callbacks, :resource_spacecraft_id)
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    sources
    |> Enum.filter(fn source ->
      is_number(source[field]) and source[field] <= policy[threshold_key]
    end)
    |> case do
      [] ->
        []

      sources ->
        sources
    end
    |> Enum.map(fn source ->
      %{
        "type" => "resource_margin_pressure",
        "spacecraft_id" =>
          Map.get(source || %{}, "spacecraft_id") ||
            resource_spacecraft_id.(mission_state),
        "resource_field" => field,
        field => source[field],
        threshold_key => policy[threshold_key],
        "derivation_reasons" => [reason],
        "source_quality" => source && source["source_quality"]
      }
      |> compact_map.()
    end)
  end
end
