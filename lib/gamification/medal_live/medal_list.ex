defmodule ZoonkWeb.Live.MedalList do
  @moduledoc false
  use ZoonkWeb, :live_view

  import ZoonkWeb.Components.MedalList

  alias Zoonk.Gamification

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{current_user: user} = socket.assigns

    gold_medals = Gamification.group_user_medals_by_reason(user.id, :gold)
    silver_medals = Gamification.group_user_medals_by_reason(user.id, :silver)
    bronze_medals = Gamification.group_user_medals_by_reason(user.id, :bronze)

    socket =
      socket
      |> assign(:page_title, dgettext("gamification", "Medals"))
      |> assign(:gold_medals, gold_medals)
      |> assign(:silver_medals, silver_medals)
      |> assign(:bronze_medals, bronze_medals)

    {:ok, socket}
  end
end
