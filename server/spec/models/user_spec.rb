require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user, id: 1) }
  let(:persisted_user) { create(:user) }

  it { should have_db_index(:facebook_id) }
  it { should belong_to(:waifu).optional }
  it { should have_many(:linked_accounts) }
  it { should have_many(:profile_links) }
  it { should have_many(:stats) }
  it { should have_many(:followers) }
  it { should have_many(:following) }
  it { should validate_uniqueness_of(:slug).case_insensitive.allow_nil }
  it { should validate_uniqueness_of(:email).case_insensitive }
  it { should have_many(:library_events) }
  it { should have_many(:notification_settings) }
  it { should have_many(:reposts).dependent(:destroy) }

  context 'for an unregistered user' do
    subject { build(:user, :unregistered) }

    it { should validate_absence_of(:name) }
    it { should validate_absence_of(:email) }
    it { should validate_absence_of(:password) }
  end

  context 'for a registered user' do
    subject { build(:user, password: nil) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:password_digest) }
  end

  describe 'by_name scope' do
    it 'should match case-insensitively' do
      u = User.by_name(persisted_user.name).first
      expect(u).to eq(persisted_user)
    end
  end

  it 'should reserve certain slugs case-insensitively' do
    user = User.new(slug: 'admin')
    expect(user).to be_invalid
    expect(user.errors[:slug]).not_to be_empty
  end

  it 'should not allow a swastika in a username' do
    user = User.new(name: '卐 Nazi Scum 卐')
    expect(user).to be_invalid
    expect(user.errors[:name]).not_to be_empty
  end

  it 'should not allow a newline in a username' do
    user = User.new(name: "Foo\nBar")
    expect(user).to be_invalid
    expect(user.errors[:name]).not_to be_empty
  end

  it 'should not allow control characters in a username' do
    user = User.new(name: "Foo\0Bar")
    expect(user).to be_invalid
    expect(user.errors[:name]).not_to be_empty
  end

  describe 'find_for_auth' do
    it 'should be able to query by email' do
      u = User.find_for_auth(persisted_user.email)
      expect(u).to eq(persisted_user)
    end
  end

  describe '#pro?' do
    it 'should return false if the user has no pro expiry' do
      user = build(:user, pro_expires_at: nil, pro_tier: nil)
      expect(user).not_to be_pro
    end
    it 'should return false if the user has already run out of pro' do
      user = build(:user, pro_expires_at: 2.months.ago, pro_tier: 'pro')
      expect(user).not_to be_pro
    end
    it 'should return true if the user still has pro left' do
      user = build(:user, pro_expires_at: 2.months.from_now, pro_tier: 'pro')
      expect(user).to be_pro
    end
    it 'should return true if the user has ao_pro and no expiration' do
      user = build(:user, pro_tier: 'ao_pro', pro_expires_at: nil)
      expect(user).to be_pro
    end
    it 'should return true if the user has ao_pro and a past expiration' do
      user = build(:user, pro_tier: 'ao_pro', pro_expires_at: 6.months.ago)
      expect(user).to be_pro
    end
  end

  describe 'past_names' do
    subject { create(:user) }
    context 'when the user changes name for the first time' do
      it 'should include the old name' do
        old_name = subject.name
        subject.name = 'MisakaMikoto'
        subject.save!
        expect(subject.past_names).to include(old_name)
      end
    end
    it 'should push onto the front when user changes name multiple times' do
      expect {
        3.times do |i|
          subject.name = "Misaka100#{i}"
          subject.save!
        end
      }.to change { subject.past_names.length }.by(3)
    end
    it 'should limit to 10 in length' do
      expect {
        20.times do |i|
          subject.name = "Misaka100#{i}"
          subject.save!
        end
      }.to change { subject.past_names.length }.from(0).to(10)
    end
    it 'should remove duplicate names' do
      expect {
        10.times do
          subject.name = 'MisakaMikoto'
          subject.save!
        end
      }.to change { subject.past_names.length }.from(0).to(1)
    end
    it 'should return first in list when previous_name is called' do
      3.times do |i|
        subject.name = "Misaka100#{i}"
        subject.save
      end
      expect(subject.past_names[0]).to equal(subject.previous_name)
    end
  end

  describe '#one_signal_player_ids' do
    it 'should return empty array when not subscribed to one signal' do
      expect(persisted_user.one_signal_player_ids).to be_empty
    end

    it 'should return array of user one signal player ids' do
      FactoryBot.create(:one_signal_player, user: persisted_user)
      FactoryBot.create(:one_signal_player,
        platform: :mobile,
        user: persisted_user)
      expect(persisted_user.one_signal_player_ids.length).to eq(2)
    end
  end

  describe '#profile_feed' do
    it 'should return a Feed::ProfileFeed instance' do
      expect(subject.profile_feed).to be_a(ProfileFeed)
    end
  end

  describe '#pro_streak' do
    context 'for a user with an active pro subscription' do
      it 'should return the length between the start of pro and now' do
        user = build(:user)
        Timecop.freeze do
          user.pro_started_at = 2.weeks.ago
          expect(user.pro_streak).to eq(2.weeks)
        end
      end
    end

    context 'for a user with a past pro subscription' do
      it 'should return the length between start and end of pro' do
        user = build(:user)
        Timecop.freeze do
          user.pro_started_at = 8.weeks.ago
          user.pro_expires_at = 1.week.ago
          expect(user.pro_streak).to eq(7.weeks)
        end
      end
    end
  end

  describe '#max_pro_streak' do
    it 'should be updated in each User update' do
      user = create(:user, max_pro_streak: 2.weeks)
      Timecop.freeze do
        expect(user.max_pro_streak).to eq(2.weeks)
        user.update(pro_started_at: 4.weeks.ago)
        expect(user.max_pro_streak).to eq(4.weeks)
      end
    end
  end

  context 'after creation' do
    before do
      allow_any_instance_of(Feed).to receive(:follow)
      allow_any_instance_of(Feed).to receive(:unfollow)
    end

    it 'should set up the timeline' do
      timeline = double(:feed)
      allow(subject).to receive(:timeline).and_return(timeline)
      expect(timeline).to receive(:setup!)
      subject.save!
    end

    it 'should set up the profile feeds' do
      profile = double(:feed)
      allow(subject).to receive(:profile_feed).and_return(profile)
      expect(profile).to receive(:setup!)
      subject.save!
    end

    it 'should set up the site announcement feed' do
      announcements = double(:feed)
      allow(subject).to receive(:site_announcements_feed)
        .and_return(announcements)
      expect(announcements).to receive(:setup!)
      subject.save!
    end
  end

  context 'after email update' do
    it 'should synchronize the email to Stripe' do
      user = create(:user)
      expect(user.stripe_customer.email).to eq(user.email)
      user.update!(email: 'mariya@takeuchi.org')
      expect(user.stripe_customer.email).to eq('mariya@takeuchi.org')
    end
  end
end
