defmodule OrbitalDynamics.Schema.CommandWindowCapabilityContext do
  @moduledoc false

  def command_window_report_model_limits do
    OrbitalDynamics.Communications.CommandWindow.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
