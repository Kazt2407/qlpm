class BorrowLifecycleService
  ACTIVE_WORKFLOW_STATES = %w[approved active].freeze

  def self.apply_defaults!(borrow, actor)
    new(borrow, actor).apply_defaults!
  end

  def self.sync_asset_status!(asset)
    return unless asset

    active_exists = asset.borrows
      .where(returned_at: nil, workflow_state: ACTIVE_WORKFLOW_STATES)
      .where("ends_at >= ?", Time.current)
      .exists?

    target_status = if active_exists
      asset.asset_type == "room" ? "in_use" : "borrowed"
    else
      "active"
    end

    asset.update!(status: target_status) if asset.status != target_status
  end

  def self.mark_returned!(borrow)
    borrow.transaction do
      borrow.update!(returned_at: Time.current, workflow_state: "returned")
      sync_asset_status!(borrow.asset)
    end
  end

  def self.approve!(borrow, approver)
    borrow.transaction do
      borrow.update!(
        workflow_state: "approved",
        approved_by: approver,
        approved_at: Time.current,
        returned_at: nil
      )
      sync_asset_status!(borrow.asset)
    end
  end

  def self.reject!(borrow)
    borrow.transaction do
      borrow.update!(workflow_state: "rejected")
      sync_asset_status!(borrow.asset)
    end
  end

  def self.cancel!(borrow)
    borrow.transaction do
      borrow.update!(workflow_state: "cancelled")
      sync_asset_status!(borrow.asset)
    end
  end

  def self.remind!(borrow, channel: "email")
    borrow.update!(reminded_at: Time.current, reminder_channel: channel)
  end

  def initialize(borrow, actor)
    @borrow = borrow
    @actor = actor
  end

  def apply_defaults!
    if @actor.admin?
      apply_admin_defaults
    else
      apply_non_admin_defaults
    end

    apply_import_defaults if @borrow.borrow_source == "imported_schedule"
    @borrow
  end

  private

  def apply_non_admin_defaults
    @borrow.created_by = @actor
    @borrow.borrower_type = inferred_borrower_type
    @borrow.borrower_name = @actor.full_name
    @borrow.borrower_identifier = @actor.identifier
    @borrow.borrower_group = @actor.department
    @borrow.borrow_source = "manual_request"
    @borrow.workflow_state = @borrow.returned_at.present? ? "returned" : "pending"
  end

  def apply_admin_defaults
    if @borrow.borrow_source == "manual_request"
      @borrow.workflow_state = "pending" if @borrow.workflow_state.blank?
    end

    @borrow.workflow_state = "returned" if @borrow.returned_at.present?

    if @borrow.workflow_state == "approved"
      @borrow.approved_by ||= @actor
      @borrow.approved_at ||= Time.current
    end
  end

  def apply_import_defaults
    @borrow.borrower_type = "system"
    @borrow.borrower_name = "Hệ thống xếp lịch" if @borrow.borrower_name.blank?
    @borrow.workflow_state = "approved" if @borrow.workflow_state.blank?
    @borrow.approved_at ||= Time.current
  end

  def inferred_borrower_type
    @actor.user_type.in?(%w[teacher student]) ? @actor.user_type : "teacher"
  end
end
