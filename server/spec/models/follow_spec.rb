require 'rails_helper'

RSpec.describe Follow, type: :model do
  let(:user_follower) { create(:user) }
  let(:user_followed) { create(:user) }
  let(:timeline) { double(:feed).as_null_object }

  before do
    allow(subject.follower).to receive(:timeline).and_return(timeline)
  end

  subject { build(:follow, follower: user_follower, followed: user_followed) }

  it { should belong_to(:follower).class_name('User')
    .counter_cache(:following_count).touch(true).required }
  it { should belong_to(:followed).class_name('User')
    .counter_cache(:followers_count).touch(true).required }

  it "should add follow to follower's timeline on create" do
    expect(subject.follower.timeline).to receive(:follow)
      .with(subject.followed.profile_feed)
    subject.save!
  end

  it "should remove follow from follower's timeline on destroy" do
    subject.save!
    expect(subject.follower.timeline).to receive(:unfollow)
      .with(subject.followed.profile_feed)
    subject.destroy!
  end

  it 'should not permit you to follow yourself' do
    user = build(:user)
    follow = build(:follow, follower: user, followed: user)
    follow.valid?
    expect(follow.errors[:followed]).to include('cannot follow yourself')
  end

  it "should generate an activity on the followers' aggregated feed" do
    follower_feed = subject.follower.profile_feed.no_fanout
    expect(subject.stream_activity.feed).to eq(follower_feed)
  end

  it "should copy the activity to the followed's notification feed" do
    expect(subject.stream_activity[:to])
      .to include(subject.followed.notifications)
  end
end
