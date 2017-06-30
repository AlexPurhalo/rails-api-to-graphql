## Tutorial
### Application Scaffolding, Part I
```
$ rails new rails_api_to_graphql
$ rails g model Article title body
$ rails g model Comment body article:references
```
```
# app/models/article.rb

class Article < ApplicationRecord
  has_many :comments
end
```
```
$ rake db:migrate
$ rails c
> article = Article.create(title: "Something new", body: "Let's talk about news")
> Comment.create(article_id: article.id, body: "Shiiiiit!")
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