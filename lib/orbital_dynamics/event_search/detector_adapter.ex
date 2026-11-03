defmodule OrbitalDynamics.EventSearch.DetectorAdapter do
  @moduledoc false
  alias OrbitalDynamics.{Epoch, EventSearch, EventSearch.Source, Trajectory}

  def detect(%Trajectory{} = trajectory, functions, opts, types) do
    with {:ok, report} <-
           EventSearch.run(
             Source.from_trajectory!(trajectory,
               interpolation: Keyword.fetch!(opts, :interpolation)
             ),
             functions,
             Keyword.fetch!(opts, :search)
           ) do
      if report["status"] == "unknown" do
        {:error, {:incomplete_event_search, report}}
      else
        scale = hd(trajectory.states).epoch.scale

        events =
          for r <- report["results"], e <- r["events"] do
            %{
              type: Map.fetch!(types, e["type"]),
              starts_at: Epoch.new!(e["epoch_s"], scale),
              metadata: %{
                "event_search" => e,
                "state_source" => report["source"],
                "function" => r["function"],
                "timing_policy" => "bounded_root_on_explicit_state_source",
                "validation_level" => "analysis",
                "limits" => report["limits"]
              }
            }
          end

        {:ok, Enum.sort_by(events, & &1.starts_at.seconds_since_j2000)}
      end
    end
  rescue
    e in [ArgumentError, KeyError] -> {:error, {:invalid_event_search, Exception.message(e)}}
  end

  def fields!(opts, fields) do
    unless Keyword.keyword?(opts) and Enum.sort(Keyword.keys(opts)) == Enum.sort(fields),
      do:
        raise(
          ArgumentError,
          "explicit detector parameters, interpolation and search controls required"
        )
  end
end
