class Admin::BulkOrdersController < Admin::BaseController
  authorize_resource class: false

  before_action :load_deleted_by_ids, only: %i(delete destroy restore)
  before_action :check_valid_statuses_for_delete?, only: %i(delete)
  before_action :check_valid_statuses_for_destroy_restore?,
                only: %i(destroy restore)

  def destroy
    rejected_count = @orders.rejected.count
    canceled_count = @orders.canceled.count

    ActiveRecord::Base.transaction do
      @orders.each(&:really_destroy!)
    end
    respond_to do |format|
      format.json do
        render json: {rejected_count: rejected_count,
                      canceled_count: canceled_count}
      end
    end
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = t ".destroy_fail"
    redirect_to admin_orders_path
  end

  def delete
    ActiveRecord::Base.transaction do
      @orders.each(&:destroy!)
    end
    respond_to do |format|
      format.json do
        render json: {rejected_count: @orders.rejected.count,
                      canceled_count: @orders.canceled.count,
                      deleted_count: @orders.count}
      end
    end
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = t ".delete_fail"
    redirect_to admin_orders_path
  end

  def restore
    ActiveRecord::Base.transaction do
      @orders.each do |order|
        order.restore! recursive: true
      end
    end
    respond_to do |format|
      format.json do
        render json: {rejected_count: @orders.rejected.count,
                      canceled_count: @orders.canceled.count}
      end
    end
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = t ".restore_fail"
    redirect_to trash_admin_orders_path
  end

  private

  def check_valid_statuses_for_delete?
    return if params[:order_ids].any? &&
              @orders.not_rejected_canceled.empty?

    flash[:danger] = t ".delete_denied"
    redirect_to admin_orders_path
  end

  def check_valid_statuses_for_destroy_restore?
    return if params[:order_ids].any? &&
              @orders.not_deleted.empty?

    flash[:danger] = t ".destroy_restore_fail"
    redirect_to trash_admin_orders_path
  end

  def load_by_ids
    @orders = Order.load_by_ids params[:order_ids]
  end

  def load_deleted_by_ids
    @orders = Order.with_deleted.load_by_ids params[:order_ids]
  end
end
