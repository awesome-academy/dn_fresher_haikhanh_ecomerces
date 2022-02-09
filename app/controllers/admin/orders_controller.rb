class Admin::OrdersController < Admin::BaseController
  authorize_resource

  before_action :load_order, except: %i(index trash)
  before_action :get_username_search, only: %i(index trash)
  before_action :count_trash_orders, :init_ransack, only: :index
  before_action :check_valid_status_for_update, :get_status_name, only: :update
  before_action :check_valid_status_for_delete, only: :delete
  before_action :check_valid_status_for_destroy_restore?,
                only: %i(destroy restore)

  def index
    @count_orders_by_status = Order.count_orders_by_status
    @orders = if status.present?
                Order.send(status)
              else
                Order.recent_orders
              end
    @pagy, @orders = pagy @orders, items: Settings.length.per_page_5
    return if params[:q].blank?

    @pagy, @orders = pagy(@q.result.includes(:user, :address, :order_details),
                          items: Settings.length.per_page_5)
  end

  def update
    ActiveRecord::Base.transaction do
      update_order status_params_to_i, rejected_reason_message
      if Order.private_instance_methods.include?(
        "restore_product_quantity_when_#{get_status_name}".to_sym
      )
        @order.send "restore_product_quantity_when_#{get_status_name}"
      end
    end
    flash[:success] = t ".update_status_success"
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = t ".update_status_fail"
  ensure
    redirect_to admin_orders_path
  end

  def show; end

  def destroy
    if @order.really_destroy!
      respond_to do |format|
        format.js
      end
    else
      flash[:danger] = t ".destroy_fail"
      redirect_to admin_orders_path
    end
  end

  def trash
    @count_orders_deleted_by_status = Order.count_orders_deleted_by_status
    @trash_orders = if username.present?
                      Order.only_deleted.filter_by_name(username)
                    elsif status.present?
                      Order.only_deleted.send(status)
                    else
                      Order.only_deleted
                    end
    @pagy, @trash_orders = pagy @trash_orders, items: Settings.length.per_page_5
  end

  def delete
    if @order.destroy
      respond_to do |format|
        format.js
      end
    else
      flash[:danger] = t ".delete_fail"
      redirect_to trash_admin_orders_path
    end
  end

  def restore
    if @order.restore recursive: true
      respond_to do |format|
        format.js
      end
    else
      flash[:danger] = t ".restore_fail"
      redirect_to trash_admin_orders_path
    end
  end

  private

  def check_valid_status_for_update
    return if valid_status_for_update?

    flash[:danger] = t ".update_status_fail"
    redirect_to admin_orders_path
  end

  def valid_status_for_update?
    status_exist? && status_not_current? && status_not_pending? &&
      !@order.rejected? && !@order.canceled? && !@order.resolved?
  end

  def check_valid_status_for_delete
    return if @order.permit_delete?

    flash[:danger] = t ".delete_fail"
    redirect_to admin_orders_path
  end

  def check_valid_status_for_destroy_restore?
    return if @order.deleted?

    flash[:danger] = t ".destroy_restore_fail"
    redirect_to trash_admin_orders_path
  end

  def status_params
    params.require :status
  end

  def status_params_to_i
    status_params.to_i
  end

  def status_exist?
    Order.statuses.values.include?(status_params_to_i)
  end

  def status_not_current?
    @order.status_before_type_cast != status_params_to_i
  end

  def status_not_pending?
    Order.statuses[:pending] != status_params_to_i
  end

  def username
    params.slice(:user_name).values.first
  end

  def status
    params.slice(:status).values.first
  end

  def rejected_reason_message
    params[:rejected_reason]
  end

  def load_order
    @order = Order.with_deleted.find_by id: params[:id]
    return if @order

    flash[:danger] = t ".not_found"
    redirect_to admin_orders_path
  end

  def init_ransack
    @q = Order.ransack params[:q]
  end

  def count_trash_orders
    @count_trash_orders = Order.deleted.count
  end

  def get_status_name
    Order.statuses.keys[params[:status].to_i]
  end

  def get_username_search
    @username_search = username if username.present?
  end

  def update_order status, rejected_reason
    @order.update! status: status
    @order.update! rejected_reason: rejected_reason if rejected_reason.present?
  end
end
