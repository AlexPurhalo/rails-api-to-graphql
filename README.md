### Tutorial
## Application Scaffolding, Part I
```
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
