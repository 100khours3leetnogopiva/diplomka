defmodule ZoonkWeb.LessonCompletedLiveTest do
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Content

  alias Zoonk.Accounts
  alias Zoonk.Content
  alias Zoonk.Gamification.UserTrophy
  alias Zoonk.Repo

  describe "completed view (non-authenticated user)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      lesson = lesson_fixture(%{course_id: course.id})

      result = get(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")
      assert redirected_to(result) == "/users/login"
    end
  end

  describe "completed view (course user)" do
    setup :course_setup

    test "returns an 403 error when the user didn't complete the lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      assert_error_sent 403, fn -> get(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed") end
    end

    test "displays the lesson results", %{conn: conn, course: course, user: user} do
      lesson = lesson_fixture(%{course_id: course.id})
      Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 7, total: 10})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      refute has_element?(lv, ~s|li a span:fl-icontains("Home")|)

      assert has_element?(lv, ~s|h1:fl-icontains("Good!")|)
      assert has_element?(lv, ~s|img[src="/images/lessons/good.svg"]|)
      assert has_element?(lv, ~s|p:fl-icontains("You got 7 out of 10 answers right.")|)
      assert has_element?(lv, ~s|span:fl-icontains("7.0")|)
      assert has_element?(lv, ~s|a[href="/c/#{course.slug}"]:fl-icontains("back to the course")|)
    end

    test "display a gold medal for a perfect score on the first try", %{conn: conn, course: course, user: user} do
      lesson = lesson_fixture(%{course_id: course.id})
      Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 10, total: 10})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      assert has_element?(lv, ~s|dd:fl-icontains("You completed a lesson without any errors on your first try.")|)
    end

    test "display a silver medal for a perfect score after practicing", %{conn: conn, course: course, user: user} do
      lesson = lesson_fixture(%{course_id: course.id})
      Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 2, correct: 10, total: 10})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      assert has_element?(lv, "#medal-perfect_lesson_practiced")
      assert has_element?(lv, ~s|dd:fl-icontains("You completed a lesson without any errors after practicing it.")|)
    end

    test "display a bronze medal for a lesson with errors on the first try", %{conn: conn, course: course, user: user} do
      lesson = lesson_fixture(%{course_id: course.id})
      Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 7, total: 10})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      assert has_element?(lv, "#medal-lesson_completed_with_errors")
      assert has_element?(lv, ~s|dd:fl-icontains("You completed a lesson with some errors on your first try.")|)
    end

    test "don't display a medal for a lesson with errors after practicing", %{conn: conn, course: course, user: user} do
      lesson = lesson_fixture(%{course_id: course.id})
      Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 2, correct: 7, total: 10})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      refute has_element?(lv, "#medal-badge")
    end

    test "display a trophy for completing a course", %{conn: conn, course: course, user: user, lesson: lesson} do
      Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 7, total: 10})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      assert has_element?(lv, "#trophy-badge")
      assert has_element?(lv, ~s|dd:fl-icontains("You completed a course.")|)
    end

    test "doesn't display a trophy if the course wasn't completed", %{conn: conn, course: course, user: user} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_fixture(%{course_id: course.id})
      Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 7, total: 10})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      refute has_element?(lv, "#trophy-badge")
    end

    test "doesn't display a trophy when completed more than 3 minutes ago", %{conn: conn, school: school, user: user} do
      course = course_fixture(%{school_id: school.id})
      course_user_fixture(%{course: course, user: user})
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_fixture(%{course: course})

      Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 7, total: 10})

      now = DateTime.utc_now()
      updated_at = DateTime.add(now, -4, :minute)

      Repo.insert(%UserTrophy{user_id: user.id, course_id: course.id, reason: :course_completed, updated_at: updated_at})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      refute has_element?(lv, "#trophy-badge")
    end

    test "plays sound effects when enabled", %{conn: conn, course: course, user: user} do
      Accounts.update_user_settings(user, %{sound_effects?: true})
      lesson = lesson_fixture(%{course_id: course.id})
      Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 7, total: 10})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      assert has_element?(lv, "audio")
    end

    test "doesn't play sound effects when disabled", %{conn: conn, course: course, user: user} do
      Accounts.update_user_settings(user, %{sound_effects?: false})
      lesson = lesson_fixture(%{course_id: course.id})
      Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 7, total: 10})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      refute has_element?(lv, "audio")
    end
  end
end
