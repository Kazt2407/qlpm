class BorrowImportsController < ApplicationController
  before_action :require_admin!

  def new
    @preview = nil
  end

  def create
    if params[:file].blank?
      redirect_to new_borrow_import_path, alert: "Vui lòng chọn tệp CSV."
      return
    end

    @preview = BorrowImporter.preview(params[:file].read, current_user)
    session[:borrow_import_rows] = @preview.valid_rows.map(&:attributes)
    render :new
  rescue CSV::MalformedCSVError => e
    redirect_to new_borrow_import_path, alert: "Tệp CSV không hợp lệ: #{e.message}"
  end

  def commit
    rows = Array(session[:borrow_import_rows])
    if rows.blank?
      redirect_to new_borrow_import_path, alert: "Không có dữ liệu hợp lệ để nhập lịch."
      return
    end

    result = BorrowImporter.commit(rows, current_user)
    session.delete(:borrow_import_rows)
    redirect_to borrows_path(source: "imported_schedule"), notice: "Đã nhập #{result.created_count} lịch mượn từ CSV."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_borrow_import_path, alert: "Không thể nhập lịch: #{e.record.errors.full_messages.to_sentence}"
  end
end
