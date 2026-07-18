defmodule OrbitalDynamics.Timeline.DiffInvalidInputContextPolicy do
  @moduledoc false

  def build(_prefix, row) when row == %{}, do: %{}

  def build(prefix, %{"invalid_activity_input" => true} = row) do
    %{
      "#{prefix}_invalid_activity_input" => true,
      "#{prefix}_invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "#{prefix}_activity" => row["source_activity"]
    }
  end

  def build(_prefix, _row), do: %{}
end
