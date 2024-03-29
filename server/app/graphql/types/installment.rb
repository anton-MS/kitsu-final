class Types::Installment < Types::BaseObject
  implements Types::Interface::WithTimestamps

  description 'Individual media that belongs to a franchise'

  field :id, ID, null: false

  field :release_order, Integer,
    null: true,
    description: 'Order based by date released'

  # Try preloaded rank first, fall back to ranked-model's slower COUNT(*) query
  def release_order
    object.attributes['release_order_rank'] || object.release_order_rank
  end

  field :alternative_order, Integer,
    null: true,
    description: 'Order based chronologically'

  # Try preloaded rank first, fall back to ranked-model's slower COUNT(*) query
  def alternative_order
    object.attributes['alternative_order_rank'] || object.alternative_order_rank
  end

  field :tag, Types::Enum::InstallmentTag,
    null: true,
    description: 'Further explains the media relationship corresponding to a franchise'

  field :media, Types::Interface::Media,
    null: false,
    description: 'The media related to this installment'

  def media
    Loaders::RecordLoader.for(object.media_type.safe_constantize).load(object.media_id)
  end

  field :franchise, Types::Franchise,
    null: false,
    description: 'The franchise related to this installment'
end
