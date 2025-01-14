defmodule Zoonk.Gamification.TrophyUtils do
  @moduledoc """
  Trophy configuration and utilities.
  """
  import ZoonkWeb.Gettext

  alias Zoonk.Gamification.Trophy

  @doc """
  Supported reasons for receiving a trophy.

  Returns a list of %Trophy{} for the supported reasons for earning a trophy.
  """
  @spec trophies() :: list(Trophy.t())
  def trophies do
    [
      %Trophy{
        key: :course_completed,
        label: dgettext("gamification", "Course completed"),
        description: dgettext("gamification", "You completed a course.")
      },
      %Trophy{
        key: :mission_completed,
        label: dgettext("gamification", "Mission completed"),
        description: dgettext("gamification", "You completed a mission.")
      }
    ]
  end

  @doc """
  Trophy keys.

  Returns a list of atom keys for the supported trophies.
  """
  @spec trophy_keys() :: list(atom())
  def trophy_keys do
    Enum.map(trophies(), & &1.key)
  end

  @doc """
  Get a trophy by key.
  """
  @spec trophy(atom()) :: Trophy.t()
  def trophy(key) do
    Enum.find(trophies(), fn trophy -> trophy.key == key end)
  end
end
