defmodule Farmbot.StateTracker do
  @moduledoc """
    Common functionality for modules that need to track
    simple states that can be easily represented as a struct with key value
    pairs.
  """

  alias Farmbot.Context

  @callback load :: {:ok, map}
  defmacro __using__(name: name, model: model) do
    quote do
      alias Farmbot.System.FS.ConfigStorage, as: FBConfigStorage

      defmodule State do
        @moduledoc false
        defstruct unquote(model) ++ [:context]
      end

      defp get_config(:all) do
        GenServer.call(FBConfigStorage, {:get, unquote(name), :all})
      end

      defp get_config(key) do
        GenServer.call(FBConfigStorage, {:get, unquote(name), key})
      end

      defp put_config(key, value) do
        GenServer.cast(FBConfigStorage, {:put, unquote(name), {key, value}})
      end

      @doc """
        Starts a #{unquote(name)} state tracker.
      """
      def start_link(%Context{} = ctx, opts),
        do: GenServer.start_link(unquote(name), ctx, opts)

      def init(ctx) do
        n = unquote(name) |> Module.split |> List.last
        Logger.info ">> is starting #{n} tracker."
        case load() do
          {:ok, %State{} = state} ->
            {:ok, broadcast(%{state | context: ctx})}
          {:error, reason} ->
            Logger.error ">> encountered an error starting #{n}" <>
              "#{inspect reason}"
            {:error, reason}
        end
      end

      # this should be overriden.
      def load, do: {:ok, %State{}}

      defp dispatch(reply, %unquote(name).State{} = state) do
        broadcast(state)
        {:reply, reply, state}
      end

      # If something bad happens in this module it's usually non recoverable.
      defp dispatch(_, {:error, reason}), do: dispatch({:error, reason})
      defp dispatch(%unquote(name).State{} = state) do
        broadcast(state)
        {:noreply, state}
      end

      defp dispatch({:error, reason}) do
        Logger.error ">> encountered a fatal " <>
          " error in #{unquote(name)}: #{inspect reason}"
      end

      defp broadcast(%unquote(name).State{} = state) do
        GenServer.cast(state.context.monitor, state)
        state
      end

      defp broadcast(_), do: dispatch {:error, :bad_dispatch}

      defoverridable [load: 0]
    end
  end
end
