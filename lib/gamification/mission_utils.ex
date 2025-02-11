defmodule Zoonk.Gamification.MissionUtils do
  @moduledoc """
  Utility functions for missions.
  """
  import ZoonkWeb.Gettext

  alias Zoonk.Gamification.Mission

  @doc """
  Returns a list of supported missions.
  """
  @spec supported_missions() :: [Mission.t()]
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  def supported_missions do
    [
      %Mission{
        key: :profile_name,
        prize: :trophy,
        label: dgettext("gamification", "Profile name"),
        description: dgettext("gamification", "Add your name to your profile."),
        success_message: dgettext("gamification", "You added your name to your profile.")
      },
      %Mission{
        key: :lesson_1,
        prize: :trophy,
        label: dgettext("gamification", "First lesson"),
        description: dgettext("gamification", "Complete your first lesson."),
        success_message: dgettext("gamification", "You completed your first lesson.")
      },
      %Mission{
        key: :perfect_lesson_1,
        prize: :trophy,
        label: dgettext("gamification", "Perfect lesson"),
        description: dgettext("gamification", "Complete a lesson without errors."),
        success_message: dgettext("gamification", "You completed a lesson without errors.")
      },
      %Mission{
        key: :lesson_5,
        prize: :bronze,
        label: dgettext("gamification", "%{count} lessons", count: 5),
        description: dgettext("gamification", "Complete %{count} lessons.", count: 5),
        success_message: dgettext("gamification", "You completed %{count} lessons.", count: 5)
      },
      %Mission{
        key: :lesson_10,
        prize: :bronze,
        label: dgettext("gamification", "%{count} lessons", count: 10),
        description: dgettext("gamification", "Complete %{count} lessons.", count: 10),
        success_message: dgettext("gamification", "You completed %{count} lessons.", count: 10)
      },
      %Mission{
        key: :lesson_50,
        prize: :silver,
        label: dgettext("gamification", "%{count} lessons", count: 50),
        description: dgettext("gamification", "Complete %{count} lessons.", count: 50),
        success_message: dgettext("gamification", "You completed %{count} lessons.", count: 50)
      },
      %Mission{
        key: :lesson_100,
        prize: :gold,
        label: dgettext("gamification", "%{count} lessons", count: 100),
        description: dgettext("gamification", "Complete %{count} lessons.", count: 100),
        success_message: dgettext("gamification", "You completed %{count} lessons.", count: 100)
      },
      %Mission{
        key: :lesson_500,
        prize: :gold,
        label: dgettext("gamification", "%{count} lessons", count: 500),
        description: dgettext("gamification", "Complete %{count} lessons.", count: 500),
        success_message: dgettext("gamification", "You completed %{count} lessons.", count: 500)
      },
      %Mission{
        key: :lesson_1000,
        prize: :trophy,
        label: dgettext("gamification", "%{count} lessons", count: 1000),
        description: dgettext("gamification", "Complete %{count} lessons.", count: 1000),
        success_message: dgettext("gamification", "You completed %{count} lessons.", count: 1000)
      },
      %Mission{
        key: :perfect_lesson_10,
        prize: :bronze,
        label: dgettext("gamification", "%{count} perfect lessons", count: 10),
        description: dgettext("gamification", "Complete %{count} lessons without errors.", count: 10)
      },
      %Mission{
        key: :perfect_lesson_50,
        prize: :silver,
        label: dgettext("gamification", "%{count} perfect lessons", count: 50),
        description: dgettext("gamification", "Complete %{count} lessons without errors.", count: 50)
      },
      %Mission{
        key: :perfect_lesson_100,
        prize: :gold,
        label: dgettext("gamification", "%{count} perfect lessons", count: 100),
        description: dgettext("gamification", "Complete %{count} lessons without errors.", count: 100)
      },
      %Mission{
        key: :perfect_lesson_500,
        prize: :trophy,
        label: dgettext("gamification", "%{count} perfect lessons", count: 500),
        description: dgettext("gamification", "Complete %{count} lessons without errors.", count: 500)
      }
    ]
  end

  @doc """
  Returns a list of supported mission keys.
  """
  @spec mission_keys() :: [atom()]
  def mission_keys do
    Enum.map(supported_missions(), & &1.key)
  end

  @doc """
  Get a mission by its key.
  """
  @spec mission(atom()) :: Mission.t()
  def mission(key) do
    Enum.find(supported_missions(), fn mission -> mission.key == key end)
  end
end
