class Types::ProfileStats < Types::BaseObject
  description 'The different types of user stats that we calculate.'

  OPTIONS = {
    anime_amount_consumed: 'Stat::AnimeAmountConsumed',
    manga_amount_consumed: 'Stat::MangaAmountConsumed',
    anime_category_breakdown: 'Stat::AnimeCategoryBreakdown',
    manga_category_breakdown: 'Stat::MangaCategoryBreakdown'
  }.freeze

  field :anime_amount_consumed, Types::ProfileStats::AnimeAmountConsumed,
    null: false,
    description: 'The total amount of anime you have watched over your whole life.'

  field :manga_amount_consumed, Types::ProfileStats::MangaAmountConsumed,
    null: false,
    description: 'The total amount of manga you ahve read over your whole life.'

  field :anime_category_breakdown, Types::ProfileStats::AnimeCategoryBreakdown,
    null: false,
    description: 'The breakdown of the different categories related to the anime you have completed'

  field :manga_category_breakdown, Types::ProfileStats::MangaCategoryBreakdown,
    null: false,
    description: 'The breakdown of the different categories related to the manga you have completed'

  def anime_amount_consumed
    stat(:anime_amount_consumed)
  end

  def manga_amount_consumed
    stat(:manga_amount_consumed)
  end

  def anime_category_breakdown
    stat(:anime_category_breakdown)
  end

  def manga_category_breakdown
    stat(:manga_category_breakdown)
  end

  def stat(type)
    Loaders::AssociationLoader.for(object.class, :stats).scope(object).then do |stats|
      stats.find_by(type: OPTIONS[type])
    end
  end
end
