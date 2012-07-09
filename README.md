flexi-model
===========

[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/we4tech/flexi-model)

Build flexible database model with dynamic fields (right now based on ActiveRecord soon it will work with mongoid too)

How to do ?
===========

Define your first model.
---------
```ruby
class User
  include FlexiModel
  _string :name, :email
  _text :bio
  validates_presence_of :name, :email
end
```

Create your new record.
------------
```ruby
User.create name: 'hasan', email: 'hasan@welltreat.us', bio: 'Ruby developer'
#=> #<User:...>
```

Find record by id.
-----------
```ruby
User.find(1)
```

Find records by name
--------
```ruby
User.where(name: 'hasan')
#=> #<...::Criteria...> # Instance of criteria object
```

Define belongs to and has many relationship
---------
```ruby
class Blog
  include FlexiModel
  _string :title
  _text :content
  belongs_to :user
end

class User
  include FlexiModel
  _string :name
  has_many :blogs
end

# Create records
user = User.create(name: 'nafi')
Blog.create(title: 'Hello world', content: 'Hello content', user: user)

# Find all related blogs
user.blogs

# Find parent record
user.blogs.first.user
```

Define has and belongs to many relationships
-----------
```ruby
class User
  inlude FlexiModel
  _string :name
  has_and_belongs_to_many :roles
end

class Role
  include FlexiModel
  _string :name
  has_and_belongs_to_many :users
end

# Create user with roles
User.create(name: 'khan', roles: [Role.create(name: 'admin'), Role.create(name: 'moderator')])

# Find user roles
user = User.where(name: 'khan').first
user.roles
```

Update attribute
---------
```ruby
user = User.where(...)
user.update_attribute :name, 'raju'
```

Update attributes
-----------
```ruby
user = User.where(...)
user.update_attributes name: 'raju', email: 'hola@hola.com'
```

Destroy record
-------
```ruby
user.destroy
User.where(...conditions...).destroy_all
```

Observers
--------
 * Before, After and Around Create
 * Before, After and Around Update
 * Before, After and Around Destroy

TODOS
=====

* Write documentation
