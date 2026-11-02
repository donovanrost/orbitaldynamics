defmodule OrbitalDynamics.MissionAnalysis.Environments.Fixed do
  @moduledoc """
  Finite-coverage fixed solar direction and constant z-axis body rotation.

  All orientation and time parameters are explicit assumptions. The Sun is
  fixed in the supplied inertial frame, so this provider is useful for short
  reference studies and analytic tests, not seasonal coverage predictions.
  """
  @behaviour OrbitalDynamics.MissionAnalysis.Environment
  alias OrbitalDynamics.{Epoch, Frame}
  alias OrbitalDynamics.MissionAnalysis.Input

  @enforce_keys [
    :frame,
    :epoch,
    :sun_direction,
    :rotation_rate_rad_s,
    :rotation_angle_rad,
    :starts_at_s,
    :ends_at_s
  ]
  defstruct @enforce_keys

  def new!(%Frame{} = frame, %Epoch{} = epoch, opts) do
    start =
      Input.number!(Keyword.fetch!(opts, :starts_at_s), "environment start", -1.0e12, 1.0e12)

    stop = Input.number!(Keyword.fetch!(opts, :ends_at_s), "environment end", -1.0e12, 1.0e12)

    unless start <= epoch.seconds_since_j2000 and epoch.seconds_since_j2000 <= stop and
             stop > start,
           do: raise(ArgumentError, "environment reference epoch must be inside finite coverage")

    %__MODULE__{
      frame: frame,
      epoch: epoch,
      starts_at_s: start,
      ends_at_s: stop,
      sun_direction: Input.unit!(Keyword.fetch!(opts, :sun_direction), "sun_direction"),
      rotation_rate_rad_s:
        Input.number!(Keyword.fetch!(opts, :rotation_rate_rad_s), "rotation_rate_rad_s", -1, 1),
      rotation_angle_rad:
        Input.number!(
          Keyword.fetch!(opts, :rotation_angle_rad),
          "rotation_angle_rad",
          -1.0e12,
          1.0e12
        )
    }
  end

  @impl true
  def at(%Epoch{} = epoch, %__MODULE__{} = config) do
    cond do
      epoch.scale != config.epoch.scale ->
        {:error, :environment_time_scale_mismatch}

      epoch.seconds_since_j2000 < config.starts_at_s or
          epoch.seconds_since_j2000 > config.ends_at_s ->
        {:error, :environment_outside_coverage}

      true ->
        {:ok,
         %{
           frame: config.frame,
           epoch: epoch,
           sun_direction: config.sun_direction,
           rotation_angle_rad:
             config.rotation_angle_rad +
               (epoch.seconds_since_j2000 - config.epoch.seconds_since_j2000) *
                 config.rotation_rate_rad_s
         }}
    end
  end

  @impl true
  def describe(config) do
    %{
      "model" => "fixed_sun_constant_body_rotation",
      "validation_level" => "assumption_declared",
      "frame" => Atom.to_string(config.frame.name),
      "time_scale" => Atom.to_string(config.epoch.scale),
      "reference_epoch_s" => config.epoch.seconds_since_j2000,
      "sun_direction" => Tuple.to_list(config.sun_direction),
      "rotation_rate_rad_s" => config.rotation_rate_rad_s,
      "rotation_angle_at_reference_epoch_rad" => config.rotation_angle_rad,
      "coverage" => %{"starts_at_s" => config.starts_at_s, "ends_at_s" => config.ends_at_s},
      "known_limits" => [
        "fixed Sun direction is not an ephemeris",
        "constant z-axis rotation; no orientation corrections"
      ]
    }
  end
end
