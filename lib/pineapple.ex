defmodule Pineapple do
  @moduledoc """
  A simple tool for running a series of tasks in a given order.

  Providing a Workflow to `begin/1` will start a chain reaction
  that will step through each of the Jobs in the workflow.

  See `PineappleTest` for some basic examples.
  """
  @supervisor __MODULE__.TaskSupervisor
  alias Pineapple.Core

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc """
  Start an instance of the Pineapple task supervisor.
  """
  def start_link(opts) do
    opts
    |> Keyword.put(:name, @supervisor)
    |> Task.Supervisor.start_link()
  end

  @doc """
  Start the process of consuming steps / Jobs in a workflow.
  """
  def begin(workflow) do
    Core.next(workflow)
  end

  # This is likely to change.
  @doc false
  def continue(workflow, next) do
    Task.Supervisor.start_child(@supervisor, Pineapple.Core, :process, [workflow, next])
  end
end
