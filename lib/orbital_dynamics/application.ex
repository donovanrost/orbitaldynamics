defmodule OrbitalDynamics.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: OrbitalDynamics.ScenarioSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: OrbitalDynamics.Supervisor)
  end
end
