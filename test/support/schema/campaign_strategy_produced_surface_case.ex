defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  @strategy_fixture "study_results/leo_constellation_campaign_strategy_v3.json"
                    |> File.read!()
                    |> :json.decode()

  using do
    quote do
      setup_all do
        %{
          strategy: OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceCase.strategy_fixture()
        }
      end
    end
  end

  def strategy_fixture, do: @strategy_fixture
end
