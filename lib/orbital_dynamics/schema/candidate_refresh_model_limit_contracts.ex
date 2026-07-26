defmodule OrbitalDynamics.Schema.CandidateRefreshModelLimitContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate(issues, _path, nil), do: issues
  def validate(issues, _path, :null), do: issues

  def validate(issues, path, limits) when is_list(limits) do
    if limits == OrbitalDynamics.CandidateRefresh.model_limits() do
      issues
    else
      [error(path, "must match candidate refresh model limits") | issues]
    end
  end

  def validate(issues, _path, _limits), do: issues
end
