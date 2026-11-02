defmodule OrbitalDynamics.MissionAnalysis.Attitude.Pointing do
  @moduledoc "One required body-to-inertial orientation in an explicit frame."
  alias OrbitalDynamics.Frame
  alias OrbitalDynamics.MissionAnalysis.Attitude.Quaternion
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport
  @enforce_keys [:frame, :quaternion]
  defstruct @enforce_keys
  @type t :: %__MODULE__{}
  def new!(%Frame{} = frame, q), do: %__MODULE__{frame: frame, quaternion: Quaternion.new!(q)}

  def from_direction(direction, frame, configuration) do
    SurfaceSupport.fields!(
      configuration,
      ~w(body_to_payload_quaternion roll_reference_inertial),
      "pointing configuration"
    )

    mount = Quaternion.new!(configuration["body_to_payload_quaternion"])

    with {:ok, payload_to_inertial} <-
           Quaternion.from_direction(direction, configuration["roll_reference_inertial"]) do
      {:ok, new!(frame, Quaternion.multiply(payload_to_inertial, mount))}
    end
  end
end
