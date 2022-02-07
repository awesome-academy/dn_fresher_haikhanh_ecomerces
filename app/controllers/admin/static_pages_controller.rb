class Admin::StaticPagesController < Admin::BaseController
  authorize_resource class: false

  def home; end

  def destroy
    log_out_admin
    redirect_to home_path
  end
end
