module ListSync
  class UpdateWorker
    include Sidekiq::Worker
    include ListSync::ErrorHandling
    sidekiq_options retry: 3, queue: 'soon'

    def perform(linked_account_id, library_entry_id)
      return if Rails.env.staging?
      begin
        linked_account = LinkedAccount.find(linked_account_id)
        library_entry = LibraryEntry.find(library_entry_id)
      rescue ActiveRecord::RecordNotFound
        return
      end
      logs = LibraryEntryLog.where(linked_account: linked_account).for_entry(library_entry).pending

      capture_sync_errors(linked_account, logs) do
        linked_account.list_sync.update!(library_entry)
        logs.each { |log| log.update!(sync_status: :success) }
      end
    end
  end
end
