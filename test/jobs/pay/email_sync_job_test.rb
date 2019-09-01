require 'test_helper'

module Pay
  class EmailSyncJobTest < ActiveJob::TestCase
    setup do
      @billable = User.new email: 'johnny@appleseed.com'
    end

    test "user with stripe as processor" do
      @billable.processor = 'stripe'
      User.stubs(:find).returns(@billable)
      @billable.expects(:update_stripe_email!)
      Pay::EmailSyncJob.perform_now(@billable.id)
    end
  end
end
