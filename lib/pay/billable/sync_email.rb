module Pay
  module Billable
    module SyncEmail
      extend ActiveSupport::Concern

      # Sync email address changes from the model to the processor.
      # This way they're kept in sync and email notifications are
      # always sent to the correct email address after an update.
      #
      # Processor classes simply need to implement a method named:
      #
      # update_PROCESSOR_email!
      #
      # This method should take the email address on the billable
      # object and update the associated API record.

      class EmailSyncJob < ActiveJob::Base
        queue_as :default

        def perform(id)
          billable = Pay.user_model.find(id)
          billable.sync_email_with_processor
        rescue ActiveRecord::RecordNotFound
          Rails.logger.info "Couldn't find a #{Pay.billable_class} with ID = #{id}"
        end
      end

      included do
        after_update :enqeue_sync_email_job,
                     if: :should_sync_email_with_processor?
      end

      def should_sync_email_with_processor?
        respond_to? :saved_change_to_email?
      end

      def sync_email_with_processor
        update_stripe_email!
      end

      private

      def enqeue_sync_email_job
        # Only update if the processor id is the same
        # This prevents duplicate API hits if this is their first time
        if processor_id? && !processor_id_changed? && saved_change_to_email?
          EmailSyncJob.perform_later(id)
        end
      end
    end
  end
end
