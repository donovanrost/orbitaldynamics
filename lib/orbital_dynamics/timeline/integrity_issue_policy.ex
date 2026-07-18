defmodule OrbitalDynamics.Timeline.IntegrityIssuePolicy do
  @moduledoc false

  def issue(type, fields), do: Map.put(fields, "type", type)
end
