defmodule ZoonkWeb.Router do
  use ZoonkWeb, :router

  import ZoonkWeb.Plugs.Course
  import ZoonkWeb.Plugs.School
  import ZoonkWeb.Plugs.Translate
  import ZoonkWeb.Plugs.UserAuth

  @nonce 10 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  @csp_connect_src Application.compile_env(:zoonk, :csp)[:connect_src]
  @cdn_url Application.compile_env(:zoonk, :cdn)[:url]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ZoonkWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; script-src-elem 'self' https://plausible.io; connect-src 'self' https://plausible.io #{@csp_connect_src}; img-src 'self' #{@cdn_url} imagedelivery.net data: blob:;"
    }

    plug :fetch_current_user
    plug :fetch_school
    plug :check_school_setup
    plug :setup_school
    plug :set_session_locale
  end

  pipeline :dev_dashboard do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug ZoonkWeb.Plugs.CspNonce, nonce: @nonce
    plug :put_secure_browser_headers, %{"content-security-policy" => "style-src 'self' 'nonce-#{@nonce}'"}
  end

  pipeline :mailbox do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers, %{"content-security-policy" => "style-src 'unsafe-inline'"}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # We don't have an actual home page. It redirects to the most recent course or the course list.
  scope "/", ZoonkWeb.Controller do
    pipe_through :browser
    get "/", Home, :index
  end

  ## Authentication routes
  scope "/", ZoonkWeb.Live do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      layout: {ZoonkWeb.Layouts, :auth},
      on_mount: [
        {ZoonkWeb.Plugs.UserAuth, :redirect_if_user_is_authenticated},
        {ZoonkWeb.Plugs.School, :mount_school},
        {ZoonkWeb.Plugs.Translate, :set_locale_from_session}
      ] do
      live "/users/register", Registration, :new
      live "/users/login", Login, :new
      live "/users/reset_password", ForgotPassword, :new
      live "/users/reset_password/:token", ResetPassword, :edit
    end
  end

  scope "/", ZoonkWeb.Live do
    pipe_through [:browser]

    live_session :public_routes,
      layout: {ZoonkWeb.Layouts, :auth},
      on_mount: [
        {ZoonkWeb.Plugs.UserAuth, :mount_current_user},
        {ZoonkWeb.Plugs.School, :mount_school},
        {ZoonkWeb.Plugs.Translate, :set_locale_from_session}
      ] do
      live "/users/confirm/:token", UserConfirmation, :edit
      live "/users/confirm", ConfirmationInstructions, :new
    end
  end

  scope "/", ZoonkWeb.Live do
    pipe_through [
      :browser,
      :require_authenticated_user,
      :prevent_guest_to_create_school,
      :require_subscription_for_private_schools,
      :fetch_course,
      :require_course_user_for_lesson
    ]

    live_session :requires_authentication,
      on_mount: [
        {ZoonkWeb.Plugs.UserAuth, :ensure_authenticated},
        {ZoonkWeb.Plugs.School, :mount_school},
        {ZoonkWeb.Plugs.Translate, :set_locale_from_session},
        {ZoonkWeb.Plugs.Course, :mount_course},
        {ZoonkWeb.Plugs.Course, :mount_lesson}
      ] do
      live "/contact", Contact

      live "/missions", MissionList
      live "/trophies", TrophyList
      live "/medals", MedalList

      live "/users/settings", UserSettings, :profile
      live "/users/settings/avatar", UserSettings, :avatar
      live "/users/settings/email", UserSettings, :email
      live "/users/settings/password", UserSettings, :password
      live "/users/settings/delete", UserSettings, :delete
      live "/users/settings/confirm_email/:token", UserSettings, :confirm_email

      live "/schools/new", SchoolNew

      live "/courses", CourseList
      live "/courses/my", MyCourses
      live "/c/:course_slug", CourseView
      live "/c/:course_slug/:lesson_id", LessonPlay
      live "/c/:course_slug/:lesson_id/completed", LessonCompleted
    end
  end

  scope "/", ZoonkWeb.Controller do
    pipe_through [:browser, :redirect_if_user_is_authenticated]
    post "/users/login", UserSession, :create
  end

  scope "/", ZoonkWeb.Controller do
    pipe_through [:browser]
    delete "/users/logout", UserSession, :delete
  end

  # Routes visible to school managers only.
  scope "/dashboard", ZoonkWeb.Live do
    pipe_through [:browser, :require_authenticated_user, :require_manager]

    live_session :school_dashboard,
      layout: {ZoonkWeb.Layouts, :dashboard_school},
      on_mount: [
        {ZoonkWeb.Plugs.UserAuth, :ensure_authenticated},
        {ZoonkWeb.Plugs.School, :mount_school},
        {ZoonkWeb.Plugs.Translate, :set_locale_from_session}
      ] do
      live "/", Dashboard.Home
      live "/edit/logo", Dashboard.SchoolEdit, :logo
      live "/edit/icon", Dashboard.SchoolEdit, :icon
      live "/edit/settings", Dashboard.SchoolEdit, :settings
      live "/edit/delete", Dashboard.SchoolEdit, :delete

      live "/billing", Dashboard.SchoolBilling

      live "/users", Dashboard.SchoolUserList
      live "/users/search", Dashboard.SchoolUserList, :search
      live "/u/:username", Dashboard.SchoolUserView

      live "/schools", Dashboard.SchoolList
      live "/schools/:id", Dashboard.SchoolView
    end
  end

  scope "/dashboard", ZoonkWeb.Controller do
    pipe_through [:browser, :require_authenticated_user, :require_manager]

    get "/billing/:from/:to/:currency/:price_id", SchoolSubscription, :show
  end

  # These routes are only available to managers and teachers.
  scope "/dashboard", ZoonkWeb.Controller.Dashboard do
    pipe_through [:browser, :require_authenticated_user, :fetch_course, :require_manager_or_teacher]

    get "/courses", Courses, :index
  end

  scope "/dashboard", ZoonkWeb.Controller do
    pipe_through [:browser, :require_authenticated_user, :fetch_course, :require_manager_or_teacher]

    get "/c/:course_slug/l/:lesson_id/s/:step_order/suggested_course/:course_id", LessonStep, :add_suggested_course
  end

  scope "/dashboard", ZoonkWeb.Live.Dashboard do
    pipe_through [:browser, :require_authenticated_user, :fetch_course, :require_manager_or_teacher]

    live_session :course_dashboard,
      layout: {ZoonkWeb.Layouts, :dashboard_course},
      on_mount: [
        {ZoonkWeb.Plugs.UserAuth, :ensure_authenticated},
        {ZoonkWeb.Plugs.School, :mount_school},
        {ZoonkWeb.Plugs.Translate, :set_locale_from_session},
        {ZoonkWeb.Plugs.Course, :mount_course},
        {ZoonkWeb.Plugs.Course, :mount_lesson}
      ] do
      live "/courses/new", CourseNew

      live "/c/:course_slug", CourseView
      live "/c/:course_slug/edit/cover", CourseEdit, :cover
      live "/c/:course_slug/edit/settings", CourseEdit, :settings
      live "/c/:course_slug/edit/delete", CourseEdit, :delete

      live "/c/:course_slug/users", CourseUserList
      live "/c/:course_slug/users/search", CourseUserList, :search
      live "/c/:course_slug/u/:user_id", CourseUserView

      live "/c/:course_slug/l/:lesson_id/s/:step_order", LessonEditor
      live "/c/:course_slug/l/:lesson_id/s/:step_order/edit_step", LessonEditor, :edit_step
      live "/c/:course_slug/l/:lesson_id/s/:step_order/cover", LessonEditor, :cover
      live "/c/:course_slug/l/:lesson_id/s/:step_order/edit", LessonEditor, :edit
      live "/c/:course_slug/l/:lesson_id/s/:step_order/image", LessonEditor, :step_img
      live "/c/:course_slug/l/:lesson_id/s/:step_order/search", LessonEditor, :search
      live "/c/:course_slug/l/:lesson_id/s/:step_order/o/:option_id", LessonEditor, :option
      live "/c/:course_slug/l/:lesson_id/s/:step_order/o/:option_id/image", LessonEditor, :option_img
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ZoonkWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:zoonk, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev/dashboard" do
      pipe_through :dev_dashboard
      live_dashboard "/", metrics: ZoonkWeb.Telemetry, csp_nonce_assign_key: :csp_nonce
    end

    scope "/dev/mailbox" do
      pipe_through :mailbox
      forward "/", Plug.Swoosh.MailboxPreview
    end
  end
end
