defmodule VerisiteBe.Storage.Provider do
  @moduledoc false

  alias VerisiteBe.Storage.StorageSetting

  @callback store(map(), StorageSetting.t()) ::
              {:ok,
               %{
                 path: String.t(),
                 provider: String.t(),
                 storage_key: String.t(),
                 content_type: String.t()
               }}
              | {:error, term()}
end
