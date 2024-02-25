class LibraryEntriesController < ApplicationController
  include CustomControllerHelpers
  before_action :authenticate_user!, only: %i[issues]

  def index
    return render_jsonapi_error(400, 'No filter provided') unless params.include?(:filter)
    super
  end

  def authorize_operation(operation)
    has_permission = operation_scope.find_each.all? do |entry|
      LibraryEntryPolicy.new(current_user, entry).public_send(operation)
    end
    if has_permission
      true
    else
      render_jsonapi(serialize_error(401, 'Not permitted'), status: 401)
      false
    end
  end

  def issues
    entries =
      LibraryEntry.where(user: user)
                  .order('reaction_skipped, rating DESC NULLS LAST, finished_at DESC NULLS LAST')
    missing = LibraryGapsService.new(entries).missing_engagement_ids
    render json: missing
  end

  def bulk_delete
    return unless authorize_operation(:destroy?)
    # Disable syncing of full-library deletes
    if params.dig(:filter, :user_id).present?
      LinkedAccount.disable_syncing_for(user) do
        operation_scope.destroy_all
      end
    else
      operation_scope.destroy_all
    end
    head 204
  end

  def bulk_update
    return unless authorize_operation(:update?)
    entries = operation_scope
    entries.each { |r| r.update(update_params) }
    render json: serialize_entries(entries)
  end

  def download_xml
    head 404 unless User.current.present?
    head 404 unless Flipper[:xml_download].enabled?(User.current)
    head 400 unless params[:kind].in?(%w[anime manga])

    user = User.current
    xml = ListSync::MyAnimeList::XMLGenerator.new(user, params[:kind].to_sym).to_xml

    send_data xml, filename: "kitsu-#{user.slug}-#{params[:kind]}.xml"
  end

  def update_params
    params.dig(:data, :attributes).permit(:status)
  end

  def operation_scope
    LibraryEntry.where(operation_filters)
  end

  def operation_filters
    params.require(:filter).permit(:id, :user_id)
          .transform_values { |v| v.split(',') }
          .select { |k, _| %w[id user_id].include?(k) }
  end

  private

  def serialize_entries(entries)
    serializer.serialize_to_hash(wrap_in_resources(entries))
  end

  def wrap_in_resources(entries)
    entries.map { |entry| LibraryEntryResource.new(entry, context) }
  end

  def serializer
    JSONAPI::ResourceSerializer.new(LibraryEntryResource)
  end
end
