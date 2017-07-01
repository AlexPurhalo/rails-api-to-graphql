## Tutorial
### Application Scaffolding, Part I
```
$ rails new rails_api_to_graphql
$ rails g model Article title body
$ rails g model User username email hashed_password
$ rails g model Comment body article:references user:references
```
```
# app/models/article.rb

class Article < ApplicationRecord
  has_many :comments
end
```
```
# app/models/user.rb

class User < ApplicationRecord
  has_many :comments
end
```

```
$ rake db:migrate
$ rails c
> article = Article.create(title: "Something new", body: "Let's talk about news")
> user = User.create(userame: "alex", email: "alex@mail.com", hashed_password: "some_hashed_data")
> Comment.create(article_id: article.id, user_id: user.id, body: "Shiiiiit!")
```
### GraphQL configuration, Part 2
```
# Gemfile
...
gem "graphql"
gem 'graphiql-rails', group: :development
gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'
```
```
$ bundle install
$ rails g graphql:install
$ mv app/graphql/rails_api_to_graphql_schema.rb app/graphql/schema.rb
```
```
# app/graphql/schema.rb

Schema = GraphQL::Schema.define do
  query(QueryType)
end
```
```
# app/controllers/graphql_controller.rb
class GraphqlController < ApplicationController
  def execute
    ...
    result = Schema.execute(query, variables: variables, context: context, operation_name: operation_name)
  end
  ...
end
```
```
# app/graphql/types/query_type.rb
QueryType = GraphQL::ObjectType.define do
end
```
```
# config/routes.rb

Rails.application.routes.draw do
  post "/graphql", to: "graphql#execute"

end
```
```
# config/application.rb
...
module RailsApiToGraphql
  class Application < Rails::Application
    ...
    config.autoload_paths << Rails.root.join('app/graphql')
    config.autoload_paths << Rails.root.join('app/graphql/types')  
  end
end
```
Run server
```
$ rails s
```
Open new console and enter following input:
```
$ curl -XPOST http://localhost:3000/graphql -d "query=query { testField }"
```
You see output in console
```
"data":{"testField":"Hello World!"}}
```

Visit http://localhost:3000/graphiql
Create a new query using interface with following input:
```
query {
  testField
}
```
Output in neighbor window: 
```
"data":{"testField":"Hello World!"}}
```
### Receiving record's data with GraphQL
Firstly let's add field that helps to find a record
```
# app/graphql/types/query_type.rb

QueryType = GraphQL::ObjectType.define do
  name 'Query'
  description 'The query root of this schema'

  field :article do
    type ArticleType
    argument :id, !types.ID
    description 'Find a Article by ID'
    resolve ->(obj, args, ctx) { Article.find_by_id(args['id']) }
  end
end
```

Next we need to provide a type of the record we are looking for
```
  $ touch app/graphql/types/article_type.rb 
```
```
# app/graphql/types/article_type.rb

ArticleType = GraphQL::ObjectType.define do
  name 'Article'
  field :id, types.Int
  field :title, types.String
  field :body, types.String
end
```
Visit graphiql interface and enter following data:
```
query {
  article(id: 1) {
    id
    title
    body
  }
}
```
Output:
```
{
  "data": {
    "article": {
      "id": 1,
      "title": "Something new",
      "body": "Let's talk about news"
    }
  }
}
```
### Nested queries implementation  
Let's provide comment type as we article has comments
```
# app/graphql/types/article_type.rb

ArticleType = GraphQL::ObjectType.define do
  ...
  field :comments, types[CommentType]
end
```
```
$ touch app/graphql/types/comment_type.rb
```
```
# app/graphql/types/comment_type.rb

CommentType = GraphQL::ObjectType.define do
  name 'Comment'
  field :id, types.Int
  field :body, types.String
end
```
Query to graphiql interface
```
query {
  article(id: 1) {
    id
    title
    body
    comments {
      id
      body
    }
  }
}
```
Output: 
```
{
  "data": {
    "article": {
      "id": 1,
      "title": "Something new",
      "body": "Let's talk about news",
      "comments": [
        {
          "id": 1,
          "body": "Shiiiiit!"
        }
      ]
    }
  }
}
```
Now we want to show comment's user
```
# app/graphql/types/comment_type.rb

CommentType = GraphQL::ObjectType.define do
  ...
  field :user, UserType
end
```
```
$ touch app/graphql/types/user_type.rb
```
```
# app/graphql/types/user_type.rb

UserType = GraphQL::ObjectType.define do
  name 'User'
  field :id, types.Int
  field :name, types.String
  field :email, types.String
end
```
Go to interface with following input:
```
query {
  article(id: 1) {
    id
    title
    body
    comments {
      id
      body
      user {
        id
        username
        email
      }
    }
  }
}
```
Output: 
```
{
  "data": {
    "article": {
      "id": 1,
      "title": "Something new",
      "body": "Let's talk about news",
      "comments": [
        {
          "id": 1,
          "body": "Shiiiiit!",
          "user": {
            "id": 1,
            "username": "alex",
            "email": "12323"
          }
        }
      ]
    }
  }
}
```

### Solving N+1 query in GraphQL using graphql-batch
Let's build file with feature that helps reduce queries count
```
$ touch app/graphql/record_loader.rb

```
```
# app/graphql/record_loader.rb

require 'graphql/batch'
class RecordLoader < GraphQL::Batch::Loader
  def initialize(model)
    @model = model
  end

  def perform(ids)
    @model.where(id: ids).each { |record| fulfill(record.id, record) }
    ids.each { |id| fulfill(id, nil) unless fulfilled?(id) }
  end
end
```

```
# app/graphql/schema.rb

Schema = GraphQL::Schema.define do
  ...

  use GraphQL::Batch
end
```

And here how and where you should use it
```
# app/graphql/types/comment_type.rb

CommentType = GraphQL::ObjectType.define do
  ...
  field :user, -> { UserType } do
    resolve -> (obj, args, ctx) {
      RecordLoader.for(User).load(obj.user_id)
    }
  end
end
```
Before 
![before example](/tutorial/before.png "before example")
After
![after example](/tutorial/after.png "after example")