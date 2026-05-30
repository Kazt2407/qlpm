class BorrowMailer < ApplicationMailer
  def reminder(borrow)
    @borrow = borrow
    @asset = borrow.asset

    mail(
      to: borrow.created_by.email,
      subject: "Nhắc trả thiết bị #{borrow.asset.code}"
    )
  end
end
