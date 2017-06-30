CommentType = GraphQL::ObjectType.define do
  name 'Comment'
  field :id, types.Int
  field :body, types.String
end