require 'rails_helper'

RSpec.describe Comment, type: :model do
  it { should belong_to(:post).counter_cache(true).required }
  it {
    should belong_to(:parent).class_name('Comment')
                             .counter_cache('replies_count').optional
  }
  it { should belong_to(:user).required }
  it { should have_many(:replies).class_name('Comment').dependent(:destroy) }
  it { should have_many(:likes).class_name('CommentLike').dependent(:destroy) }
  it { should validate_length_of(:content).is_at_most(9_000) }

  subject { build(:comment, content: nil) }

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

  it 'should convert basic markdown to fill in content_formatted' do
    comment = create(:comment, content: '*Emphasis* is cool!')
    expect(comment.content_formatted).to include('<em>')
  end

  it 'should not allow grandchildren' do
    grandparent = build(:comment)
    parent = build(:comment, parent: grandparent)
    comment = build(:comment, parent: parent)
    expect(comment).not_to be_valid
    expect(comment.errors[:parent]).to be_present
  end

  context 'which is on AMA that is closed' do
    it 'should not be valid' do
      post = create(:post)
      ama = create(:ama, original_post: post)
      ama.start_date = 6.hours.ago
      ama.end_date = ama.start_date + 1.hour
      ama.save
      comment = build(:comment, post: post)
      expect(comment).not_to be_valid
    end
  end
end
