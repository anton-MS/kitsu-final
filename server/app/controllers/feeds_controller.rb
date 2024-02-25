class FeedsController < ApplicationController
  include CustomControllerHelpers

  before_action :authorize_feed!

  def show
    response_json = stringify_activities(query.list)
    render_jsonapi response_json
  end

  def mark_read
    activities = feed.activities.mark(:read, params[:_json])
    render_jsonapi stringify_activities(activities)
  end

  def mark_seen
    activities = feed.activities.mark(:seen, params[:_json])
    render_jsonapi stringify_activities(activities)
  end

  def destroy_activity
    activity = feed.activities.includes(:subject).find(params[:uuid])
    return head 404 unless activity

    subject_enriched = !activity.subject.is_a?(String)
    can_destroy = subject_enriched && policy_for(activity.subject).destroy?
    if can_destroy || feed_owner?(activity.origin)
      activity.destroy_original
      return head 204
    end
    head 401
  end

  private

  def serialize_activities(list)
    @serializer ||= FeedSerializerService.new(
      list,
      including: params[:include]&.split(','),
      feed: feed,
      # fields: params[:fields]&.split(','),
      context: context,
      base_url: request.url
    )
  end

  def stringify_activities(list)
    Oj.dump(serialize_activities(list))
  end

  def query
    @query ||= FeedQueryService.new(params, current_user&.resource_owner)
  end

  delegate :feed, to: :query

  def authorize_feed!
    unless feed_visible?
      error = serialize_error(403, 'Not allowed to access that feed')
      render_jsonapi error, status: 403
    end
  end

  def feed_visible?
    case params[:group].sub(/_aggr\z/, '')
    when 'media'
      media_type, media_id = params[:id].split('-')
      return false unless %w[Manga Anime Drama].include?(media_type)
      media = media_type.safe_constantize.find_by(id: media_id)
      media && show?(media)
    when 'user'
      user = User.find_by(id: params[:id])
      user && show?(user)
    when 'group'
      group = Group.find_by(id: params[:id])
      group && show?(group)
    when 'site_announcements', 'notifications', 'timeline', 'group_timeline'
      params[:id].to_i == current_user&.resource_owner_id
    when 'episode', 'chapter' then true
    when 'global' then true
    when 'reports'
      user = current_user&.resource_owner
      if params[:id] == 'global'
        # Is admin of something?
        user.permissions.community_mod?
      else
        # Has content rights in the group?
        group = Group.find_by(id: params[:id])
        member = group.member_for(user)
        member&.has_permission?(:content)
      end
    end
  end

  def feed_owner?(feed_group = params[:group], id = params[:id])
    if feed_group.is_a?(Feed)
      id = feed_group.id
      feed_group = feed_group.group
    end

    case feed_group
    when 'user', 'user_aggr'
      user = User.find_by(id: id)
      user && policy_for(user).update?
    when 'group', 'group_aggr'
      group = Group.find_by(id: id)
      group && policy_for(group).update?
    else false
    end
  end
end
