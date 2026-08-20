defmodule OrbitalDynamics.EventTiming do
  @moduledoc """
  Detector-wide event timing tolerance metadata.

  Current event detectors are sampled detectors with linear boundary
  interpolation as the compatibility default. Access-window callers may opt
  into detector-local root refinement on an interpolated state path. This
  module retains the conservative default policy; the access detector adds its
  tighter local root bracket and explicit interpolation limits without claiming
  dense propagation or external validation.
  """

  alias OrbitalDynamics.Trajectory

  @doc """
  Builds timing policy metadata for a detected event.
  """
  def policy(%Trajectory{} = trajectory, detector, opts \\ []) do
    max_sample_step_s = max_sample_step_s(trajectory)
    interpolation = Keyword.get(opts, :interpolation, :linear_sample_crossing)

    %{
      event_timing_policy: :sampled_state_linear_boundary,
      event_detector: detector,
      interpolation: interpolation,
      event_time_tolerance_s: max_sample_step_s,
      max_sample_step_s: max_sample_step_s,
      confidence: confidence(max_sample_step_s, interpolation)
    }
  end

  @doc """
  Builds local timing metadata for a refined boundary bracket.

  `policy/3` describes the whole trajectory cadence. Refined event boundaries
  also need the local before/after sample width, because a dense region in an
  otherwise sparse trajectory has a tighter timing bound than the trajectory
  maximum.
  """
  def boundary_policy(before_epoch, after_epoch, opts \\ []) do
    interpolation = Keyword.get(opts, :interpolation, :linear_sample_crossing)
    bracket_s = epoch_delta_s(before_epoch, after_epoch)

    %{
      event_timing_policy: :sampled_state_linear_boundary,
      interpolation: interpolation,
      event_time_tolerance_s: bracket_s,
      event_time_bracket_s: bracket_s,
      before_epoch_s: epoch_seconds(before_epoch),
      after_epoch_s: epoch_seconds(after_epoch),
      root_solved: false,
      confidence: confidence(bracket_s, interpolation)
    }
  end

  @doc """
  Adds event timing policy metadata to an event.
  """
  def annotate_event(%{} = event, %Trajectory{} = trajectory, detector, opts \\ []) do
    metadata = Map.get(event, :metadata, %{})
    Map.put(event, :metadata, Map.merge(policy(trajectory, detector, opts), metadata))
  end

  defp max_sample_step_s(%Trajectory{states: [_state]}), do: 0.0

  defp max_sample_step_s(%Trajectory{states: states}) do
    states
    |> Enum.map(& &1.epoch.seconds_since_j2000)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [before_s, after_s] -> abs(after_s - before_s) end)
    |> Enum.max(fn -> 0.0 end)
    |> Kernel.*(1.0)
  end

  defp confidence(max_sample_step_s, _interpolation) when max_sample_step_s == 0.0,
    do: :exact_sample_only

  defp confidence(_max_sample_step_s, :linear_sample_crossing), do: :bounded_by_sample_cadence
  defp confidence(_max_sample_step_s, _interpolation), do: :sampled

  defp epoch_delta_s(before_epoch, after_epoch) do
    abs(epoch_seconds(after_epoch) - epoch_seconds(before_epoch)) * 1.0
  end

  defp epoch_seconds(%{seconds_since_j2000: seconds}) when is_number(seconds), do: seconds * 1.0

  defp epoch_seconds(%{"seconds_since_j2000" => seconds}) when is_number(seconds),
    do: seconds * 1.0
end
