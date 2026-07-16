defmodule OrbitalDynamics.Schema.CapabilityCatalogJsonSchema do
  @moduledoc false

  def property_field?("model"), do: true
  def property_field?(_field), do: false

  def property("model") do
    %{
      "type" => "string",
      "const" => "public_capability_catalog"
    }
  end
end
