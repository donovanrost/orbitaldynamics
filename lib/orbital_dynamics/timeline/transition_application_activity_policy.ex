defmodule OrbitalDynamics.Timeline.TransitionApplicationActivityPolicy do
  @moduledoc false

  def transition_application_activity(nil, _opts, _normalize_activity), do: nil

  def transition_application_activity(activity, opts, normalize_activity) do
    normalize_activity.(activity, opts)
  end

  def maybe_preserve_transition_application_provenance(row, activity) do
    case Map.get(activity, "transition_application_provenance") do
      %{} = provenance -> Map.put(row, "transition_application_provenance", provenance)
      _other -> row
    end
  end
end
