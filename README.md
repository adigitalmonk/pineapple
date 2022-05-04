# Pineapple

Pineapple is a simple library intended to be used as an ETL system. The API is
subject to change.

Erlang processes each are able to garbage collect themselves, but the fastest
way to clean things up is to just let the process go away.

As a result, each Job in a workflow will run in it's own isolated process before
kicking off the next step in the workflow in another process.

## Installation

Pineapple is still in alpha, but you can use it now by adding it via Git.

```elixir
def deps do
    [
      {:pineapple, github: "adigitalmonk/pineapple", branch: "master"}
    ]
end
```

Then you can add Pineapple to your supervisior tree.

```elixir
  def start(_type, _args) do
    children = [
      Pineapple
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
```

## Usage

The main focus of Pineapple is a combination of "Workflows", and the "Jobs" that
make them up.

### Jobs

The jobs are the core components, they consist of a single `run/1` function that
accepts a workflow, and returns one of three types of tuples.

- `{:ok, workflow}`
  - Continue to the next step in the workflow
- `{:done, result, workflow}`
  - Finish the workflow now with this result
- `{:error, reason, workflow}`
  - Stop the workflow early, with the given reason

```elixir
defmodule MyJob do
  use Pineapple.Job

  def run(workflow) do
    # do some stuff

    {:ok, workflow}
  end
end
```

Tasks all run in different processes. The only way to pass data between
processes is via the `assign/2` or `assign/3` method from the
`Pipeline.Workflow` module. These methods are imported into Jobs (assuming you
used the macro).

```elixir
# One key, one value
assign(workflow, :key, "value")

# Keyword list
assign(workflow, key: "value", key2: "value2")

# Function that accepts the current assigns and returns the new assigns map
assign(workflow, fn assigns -> 
  Map.drop(assigns, [:key])
end)
```

A workflow is a description of the process. You can save data into a workflow
and retrive it in future steps.

### Workflows

Workflows are the actual structures that define the data pipeline.

They can be created via `Pineapple.Workflow.define/2`.

```elixir
workflow = Pineapple.Workflow.define([MyJobA, MyJobB])
```

Two optional settings for workflows are a name, and a target.

- `:name` is either a string or an atom that can be used to identify the object.
- `:target` is a pid for some process that will wait for the message to arrive.
  - The message will be in the format `{:finished, result}` or
    `{:failed, reason}`

## TODO

- Telemetry
- Better documentation in general
- More examples
