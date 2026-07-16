defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionStatusValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionStatusTokens
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionValueEncoding

  def status_value(status) when is_boolean(status),
    do: if(status, do: "met", else: "unmet")

  def status_value(status) do
    status
    |> ObjectiveSatisfactionValueEncoding.normalized_token()
    |> ObjectiveSatisfactionStatusTokens.status_value()
  end
end
