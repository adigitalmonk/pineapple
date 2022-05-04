defmodule Pineapple.Workflow do
  @moduledoc """
  Contains the necessary information to define a workflow
  """

  @typedoc """
  Defines the structure of a workflow.
  """
  @type t :: %__MODULE__{
            name: binary() | atom(),
            run_ref: String.t(),
            next: list(module()),
            args: any(),
            assigns: map(),
            target: pid()
          }

  defstruct [:name, :next, :args, :assigns, :run_ref, :target]

  @type option ::
    {:name, String.t()}
    | {:name, atom()}
    | {:target, pid()}

  @doc """
  Create a new workflow, allowing for a few optional configuration choices.

  - `:name` allows for giving the workflow a name.
  - `:target` allows for specifying a process to receive the final result as a tuple `{:finished, any()}`
    - This target will also receive a `{:failure, any()}` when this fails.
  """
  @spec define(steps :: list(module()), opts :: list(option())) :: t()
  def define(steps, opts \\ []) when is_list(steps) do
    name = Keyword.get(opts, :name)
    target = Keyword.get(opts, :target)

    %__MODULE__{
      name: name,
      next: steps,
      assigns: %{},
      target: target,
      run_ref: generate_unique_id()
    }
  end

  @doc """
  Add a new step to the workflow.

    iex> %Workflow{ next: [] } |> Workflow.add_step(Test)
    %Workflow{ next: [Test] }
  """
  def add_step(workflow, step) do
    %__MODULE__{
      workflow
      | next: [step | workflow.next]
    }
  end

  @doc """
  Get a specific value that was previously assigned.

    iex> %Workflow{ assigns: %{ test: "value" }} |> Workflow.get_assign(:test)
    "value"
  """
  def get_assign(workflow, key) do
    workflow.assigns[key]
  end

  @doc """
  Assign a new value into the workflow.

  Examples:

    iex> %Workflow{ assigns: %{} } |> Workflow.assign(:test, "value")
    %Workflow{ assigns: %{ test: "value" }}
  """
  def assign(workflow, key, value) do
    %__MODULE__{
      workflow
      | assigns: Map.put(workflow.assigns, key, value)
    }
  end

  @doc """
  Assign a set of values into the workflow using a keyword list or function

    iex> %Workflow{ assigns: %{} } |> Workflow.assign(test: "value", test2: "value2")
    %Workflow{ assigns: %{ test: "value", test2: "value2" }}

    iex> %Workflow{ assigns: %{} } |> Workflow.assign(& Map.put(&1, :test, "value"))
    %Workflow{ assigns: %{ test: "value" }}
  """
  def assign(workflow, keywords) when is_list(keywords) do
    assigns =
      keywords
      |> Enum.reduce(workflow.assigns, fn {keyword, value}, acc ->
        Map.put(acc, keyword, value)
      end)

    %__MODULE__{workflow | assigns: assigns}
  end

  def assign(workflow, assigner) when is_function(assigner) do
    %__MODULE__{
      workflow
      | assigns: assigner.(workflow.assigns)
    }
  end

  defp generate_unique_id do
    :crypto.strong_rand_bytes(20)
    |> Base.encode64(padding: false)
  end
end
