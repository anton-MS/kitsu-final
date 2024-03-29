require 'rails_helper'

RSpec.describe Post, type: :model do
  subject { build(:post) }

  it { should belong_to(:user).required }
  it { should belong_to(:target_user).class_name('User').optional }
  it { should belong_to(:media).optional }
  it { should belong_to(:spoiled_unit).optional }
  it { should belong_to(:locked_by).class_name('User').optional }
  it { should have_many(:post_likes).dependent(:destroy) }
  it { should have_many(:comments).dependent(:destroy) }
  it { should validate_length_of(:content).is_at_most(9_000) }
  it { should have_many(:reposts).dependent(:delete_all) }

  subject { build(:post, content: nil) }

  context 'with content' do
    before { subject.content = 'some content' }

    it { should_not validate_presence_of(:uploads).with_message('must exist') }
  end

  context 'with uploads' do
    before do
      subject.uploads = [build(:upload)]
      subject.content = nil
    end

    it { should_not validate_presence_of(:content) }
  end

  context 'with a spoiled unit' do
    subject { build(:post, spoiled_unit: build(:episode)) }
    it { should validate_presence_of(:media) }
    it { should allow_value(true).for(:spoiler) }
  end

  context 'with a media' do
    let(:media) { create(:anime) }
    subject { build(:post, media: media) }
    let(:activity) { subject.stream_activity.as_json.with_indifferent_access }

    it 'should have an activity with media feed in "to" list' do
      expect(activity[:to]).to include("media:Anime-#{media.id}")
    end
  end

  it 'should convert basic markdown to fill in content_formatted' do
    post = create(:post, content: '*Emphasis* is cool!')
    expect(post.content_formatted).to include('<em>')
  end

  context 'with an @mention' do
    let!(:user) { create(:user, slug: 'thisisatest') }
    subject { build(:post, content: '@thisisatest') }
    let(:activity) { subject.stream_activity.as_json.with_indifferent_access }

    describe '#stream_activity' do
      it "should have the mentioned user's notifications in the to field" do
        notifications_feed = user.notifications.read_target.join(':')
        expect(activity[:to]).to include(notifications_feed)
      end
    end
  end

  context 'with a target user' do
    let(:user) { create(:user) }
    subject { build(:post, target_user: user) }
    let(:activity) { subject.stream_activity.as_json.with_indifferent_access }

    describe '#stream_activity' do
      it "should have the target user's feed as the target" do
        expect(subject.stream_activity.feed).to eq(user.profile_feed)
      end

      it "should have the target user's notifications in the to field" do
        notifications_feed = user.notifications.read_target.join(':')
        expect(activity[:to]).to include(notifications_feed)
      end
    end
  end

  context 'with a target group' do
    let(:group) { create(:group) }
    subject { build(:post, target_group: group) }

    describe '#stream_activity' do
      it "should have the group's feed as the target" do
        expect(subject.stream_activity.feed).to eq(group.feed)
      end
    end

    context 'which is NSFW' do
      before { group.nsfw = true }

      it 'should automatically be marked NSFW before save' do
        subject.save!
        expect(subject.nsfw).to eq(true)
      end
    end
  end

  it 'should not allow target_group and target_user to coexist' do
    group = build(:group)
    user = build(:user)
    post = build(:post, target_group: group, target_user: user)
    post.valid?
    expect(post.errors).to include(:target_group, :target_user)
  end
end
