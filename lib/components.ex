defmodule ScenicUI.Components do
  alias Scenic.Primitive
  alias Scenic.Primitive.SceneRef
  alias Scenic.Graph

  @doc """
  Create a group which can be moved by pointer events. Must contain one or more `drag_handle` children.

  Example:

  ```
  Graph.build()
  |> draggable_group(fn g ->
    g
    |> rect({200, 15}, fill: {220, 225, 230}, t: {0, 0})
    |> drag_handle({200, 15}, t: {0, 0})
    |> rect({200, 100}, fill: {80, 80, 80}, t: {0, 15})
  end, id: :my_widget, t: {0, 0})
  ```

  The given example will create a rectangle with a top bar that, when grabbed,
  will change the group's position and also send the following events up the the parent scene:

  * `{:begin_move, id, {x, y}}`
  * `{:move, id, {x, y}}`
  * `{:end_move, id, {x, y}}`

  These events can be used for changing styles, adding drop shadows, etc.

  If you want a conditional drop you can check the `x` and `y` (or some other value) upon receiving the
  :end_move event and call `ScenicUI.Component.DragHandle.cancel_move(context)`.
  """
  @spec draggable_group(
          source :: Graph.t() | Primitive.t(),
          data :: list({String.t(), any} | {String.t(), any, boolean}),
          options :: list
        ) :: Graph.t() | Primitive.t()
  def draggable_group(graph, data, options \\ [])

  def draggable_group(%Graph{} = g, data, options) do
    add_to_graph(g, ScenicUI.Component.DraggableGroup, {g, data}, options)
  end

  @doc """
  Create a drag handle that sends events when it is grabbed with the mouse.

  Example:

  `drag_handle(graph, {200, 15}, t: {0, 0})`

  The given example will create a clear rectangle 200 pixels wide and 15 pixels tall that, when grabbed,
  will send the following events:

  * `{:begin_move, {x, y}}`
  * `{:move, {x, y}}`
  * `{:end_move, {x, y, origin_x, origin_y}}`

  If you want a conditional drop you could check the current `x` and `y` (or some other value) and if
  desired send the moved element back to `origin_x`, `origin_y`.
  """
  @spec drag_handle(
          source :: Graph.t() | Primitive.t(),
          data :: list({String.t(), any} | {String.t(), any, boolean}),
          options :: list
        ) :: Graph.t() | Primitive.t()
  def drag_handle(graph, data, options \\ [])

  def drag_handle(%Graph{} = g, data, options) do
    add_to_graph(g, ScenicUI.Component.DragHandle, data, options)
  end

  def drag_handle(%Primitive{module: SceneRef} = p, data, options) do
    modify(p, ScenicUI.Component.DragHandle, data, options)
  end

  # ============================================================================

  defp add_to_graph(%Graph{} = g, mod, data, options) do
    mod.verify!(data)
    mod.add_to_graph(g, data, options)
  end

  defp modify(%Primitive{module: SceneRef} = p, mod, data, options) do
    mod.verify!(data)
    Primitive.put(p, {mod, data}, options)
  end
end
