defmodule OrbitalDynamics.Timeline.DiffProtectionContextPolicy do
  @moduledoc false

  def build(_prefix, nil, _protection_decision), do: %{}
  def build(_prefix, row, _protection_decision) when row == %{}, do: %{}

  def build(prefix, row, protection_decision) do
    decision =
      row
      |> Map.put("id", row["activity_id"])
      |> protection_decision.()

    %{
      "#{prefix}_protection_decision" => decision,
      "#{prefix}_protection_category" => decision["protection_category"],
      "#{prefix}_protection_reason" => decision["reason"]
    }
  end
end
