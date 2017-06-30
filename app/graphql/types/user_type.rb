UserType = GraphQL::ObjectType.define do
  name 'User'
  field :id, types.Int
  field :username, types.String
  field :email, types.String
end