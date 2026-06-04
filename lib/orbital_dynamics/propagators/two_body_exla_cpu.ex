defmodule OrbitalDynamics.Propagators.TwoBodyExlaCpu do
  @moduledoc """
  EXLA CPU two-body backend using the compiled Nx kernel.

  This backend has the same homogeneous-batch restrictions as
  `OrbitalDynamics.Propagators.TwoBodyNxCompiled`, but runs the kernel through
  the EXLA compiler on the host CPU.
  """

  alias OrbitalDynamics.Propagators.TwoBodyNxCompiled
  alias OrbitalDynamics.Scenario

  @behaviour OrbitalDynamics.Propagator
  @behaviour OrbitalDynamics.BatchPropagator

  @impl OrbitalDynamics.Propagator
  def capabilities do
    %{
      backend: :exla_cpu,
      force_models: [:point_mass_two_body],
      numerical_methods: [:rk4_fixed_step],
      validation_level: :educational,
      supports_batching: true,
      supports_events: false,
      supports_maneuvers: false,
      batching: %{
        homogeneous_duration: true,
        homogeneous_output_step: true,
        homogeneous_central_body: true,
        requires_duration_multiple_of_output_step: true,
        requires_output_step_multiple_of_max_step: true
      }
    }
  end

  @impl OrbitalDynamics.Propagator
  def propagate(%Scenario{} = scenario, opts \\ []) do
    case propagate_many([scenario], opts) do
      {:ok, [trajectory]} -> {:ok, trajectory}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl OrbitalDynamics.BatchPropagator
  def propagate_many(scenarios, opts \\ []) when is_list(scenarios) do
    opts =
      opts
      |> Keyword.put(:backend, :exla_cpu)
      |> Keyword.put(:compiler_options, compiler_options(opts))

    TwoBodyNxCompiled.propagate_many(scenarios, opts)
  end

  defp compiler_options(opts) do
    opts
    |> Keyword.get(:compiler_options, [])
    |> Keyword.put_new(:compiler, EXLA)
    |> Keyword.put_new(:client, :host)
  end
end
