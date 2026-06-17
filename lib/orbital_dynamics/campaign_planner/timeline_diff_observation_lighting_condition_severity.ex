defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationLightingConditionSeverity do
  @moduledoc false

  def factor(status, callbacks) when is_binary(status) do
    case callback!(callbacks, :normalized_status_token).(status) do
      status when status in ["eclipsed", "full_eclipse", "umbra", "dark", "unlit"] ->
        0.0

      "mostly_eclipsed" ->
        0.25

      status when status in ["penumbra", "partial_eclipse", "partial", "mixed_lighting"] ->
        0.5

      _status ->
        nil
    end
  end

  def factor(_status, _callbacks), do: nil

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
