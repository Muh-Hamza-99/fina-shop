class Admin::SignupsController < Admin::BaseController
  layout "auth"

  allow_unauthenticated_access
  before_action :redirect_signed_in_user
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to admin_signup_path, alert: t("admin.flash.rate_limited") }

  def new
    @signup = Signup.new
  end

  def create
    @signup = Signup.new(signup_params)

    if @signup.save
      start_new_session_for @signup.user
      redirect_to admin_root_path, notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def signup_params
      params.expect(signup: %i[store_name_ar store_name_en subdomain name email_address password password_confirmation])
    end

    def redirect_signed_in_user
      redirect_to admin_root_path if authenticated?
    end
end
