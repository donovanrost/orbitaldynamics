defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.DirectionTokens.Aliases do
  @moduledoc false

  alias __MODULE__.FallbackValues
  alias __MODULE__.ProviderAliases

  def normalized(token) do
    case ProviderAliases.fetch(token) do
      {:ok, normalized_token} -> normalized_token
      :error -> FallbackValues.normalized(token)
    end
  end
end
