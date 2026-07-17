defmodule OrbitalDynamics.Schema.LazyProviderResolver do
  @moduledoc false

  def resolver(providers) when is_list(providers) do
    provider_map = Map.new(providers)

    fn name ->
      provider = Map.fetch!(provider_map, name)
      provider.()
    end
  end
end
