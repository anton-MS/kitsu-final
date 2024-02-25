module Types::Interface::Streamable
  include Types::Interface::Base
  description 'Media that is streamable.'

  field :streamer, Types::Streamer,
    null: false,
    description: 'The site that is streaming this media.'

  def streamer
    Loaders::RecordLoader.for(Streamer).load(object.streamer_id)
  end

  field :regions, [String],
    null: false,
    description: 'Which regions this video is available in.'

  field :subs, [String],
    null: false,
    description: 'Languages this is translated to. Usually placed at bottom of media.'

  field :dubs, [String],
    null: false,
    description: 'Spoken language is replaced by language of choice.'
end
