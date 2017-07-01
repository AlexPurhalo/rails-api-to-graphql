QueryType = GraphQL::ObjectType.define do
  name 'Query'
  description 'The query root of this schema'

  field :article do
    type ArticleType
    argument :id, !types.ID
    description 'Find a Article by id'
    resolve ->(obj, args, ctx) { Article.find_by_id(args['id']) }
  end

  field :comment do
    type CommentType
    argument :id, !types.ID
    description 'Find a Comment by id'
    resolve ->(obj, args, ctx) { Comment.find_by_id(args['id'])}
  end
end
