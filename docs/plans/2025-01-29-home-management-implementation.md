# Home Management App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Rails 8 home management app for tracking tasks, reminders, appliances, wishlist items, and wiki pages for a two-person household.

**Architecture:** Rails 8 with server-rendered views (no JavaScript framework), SQLite database, Pico CSS for minimal styling. Authentication via Rails 8 built-in generator. All pages mobile-friendly.

**Tech Stack:** Ruby 3.3+, Rails 8, SQLite3, Pico CSS (CDN), Anthropic Ruby SDK

---

## Milestone 1: Project Setup & Authentication
**Testable outcome:** Run server, visit localhost:3000, see login page, create accounts, log in/out

### Task 1.1: Create Rails App

**Step 1: Generate new Rails app**

Run:
```bash
rails new home_app --database=sqlite3 --skip-action-mailbox --skip-action-text --skip-active-storage --skip-action-cable --skip-hotwire --skip-jbuilder --skip-test --css=tailwind
cd home_app
```

Note: We'll replace Tailwind with Pico CSS, but this gives us a clean setup.

**Step 2: Verify app runs**

Run:
```bash
bin/rails server
```

Visit: http://localhost:3000
Expected: Rails welcome page

**Step 3: Commit**

```bash
git add -A
git commit -m "chore: initial Rails 8 app setup"
```

---

### Task 1.2: Replace Tailwind with Pico CSS

**Files:**
- Modify: `app/views/layouts/application.html.erb`
- Delete: `app/assets/stylesheets/application.tailwind.css`

**Step 1: Update layout to use Pico CSS CDN**

Replace `app/views/layouts/application.html.erb`:
```erb
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) || "Home" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
  </head>

  <body>
    <% if user_signed_in? %>
      <nav class="container-fluid">
        <ul>
          <li><strong>Home Manager</strong></li>
        </ul>
        <ul>
          <li><%= link_to "Dashboard", root_path %></li>
          <li><%= link_to "Tasks", tasks_path %></li>
          <li><%= link_to "Wishlist", wishlist_items_path %></li>
          <li><%= link_to "Reminders", reminders_path %></li>
          <li><%= link_to "Wiki", wiki_pages_path %></li>
          <li><%= link_to "Appliances", appliances_path %></li>
          <li><%= link_to current_user.name, edit_user_path(current_user) %></li>
          <li><%= button_to "Logout", session_path, method: :delete, class: "outline" %></li>
        </ul>
      </nav>
    <% end %>

    <main class="container">
      <% if notice.present? %>
        <article class="notice"><%= notice %></article>
      <% end %>
      <% if alert.present? %>
        <article class="alert"><%= alert %></article>
      <% end %>

      <%= yield %>
    </main>
  </body>
</html>
```

**Step 2: Create minimal custom stylesheet**

Create `app/assets/stylesheets/application.css`:
```css
/* Custom styles for Home Manager */

.notice {
  background: var(--pico-ins-color);
  padding: 1rem;
  border-radius: var(--pico-border-radius);
  margin-bottom: 1rem;
}

.alert {
  background: var(--pico-del-color);
  padding: 1rem;
  border-radius: var(--pico-border-radius);
  margin-bottom: 1rem;
}

/* Status badges */
.badge {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  border-radius: var(--pico-border-radius);
  font-size: 0.875rem;
}

.badge-todo { background: var(--pico-secondary-background); }
.badge-in-progress { background: var(--pico-primary-background); color: white; }
.badge-done { background: var(--pico-ins-color); }

.badge-low { background: var(--pico-secondary-background); }
.badge-medium { background: var(--pico-mark-background-color); }
.badge-high { background: var(--pico-del-color); }

/* Warranty status */
.warranty-ok { color: green; }
.warranty-warning { color: orange; }
.warranty-expired { color: red; }

/* Card grid for appliances */
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1rem;
}

/* Quick actions */
.quick-actions {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 1rem;
}
```

**Step 3: Remove Tailwind (if present)**

Run:
```bash
rm -f app/assets/stylesheets/application.tailwind.css
```

**Step 4: Verify styling works**

Run: `bin/rails server`
Visit: http://localhost:3000
Expected: Page loads without errors (will show routing error, that's fine)

**Step 5: Commit**

```bash
git add -A
git commit -m "style: replace Tailwind with Pico CSS"
```

---

### Task 1.3: Generate Authentication with Rails 8

**Step 1: Generate authentication**

Run:
```bash
bin/rails generate authentication
```

This creates:
- User model with email and password
- Session controller
- Authentication concern
- Login/password views

**Step 2: Add name field to User**

Run:
```bash
bin/rails generate migration AddNameToUsers name:string
```

**Step 3: Update migration to make name required**

Edit the generated migration file in `db/migrate/*_add_name_to_users.rb`:
```ruby
class AddNameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string, null: false, default: ""
  end
end
```

**Step 4: Run migrations**

Run:
```bash
bin/rails db:migrate
```

**Step 5: Update User model validation**

Modify `app/models/user.rb`:
```ruby
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  normalizes :email, with: ->(e) { e.strip.downcase }
end
```

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: add Rails 8 authentication with name field"
```

---

### Task 1.4: Create Registration Flow

**Files:**
- Create: `app/controllers/registrations_controller.rb`
- Create: `app/views/registrations/new.html.erb`
- Modify: `config/routes.rb`

**Step 1: Create registrations controller**

Create `app/controllers/registrations_controller.rb`:
```ruby
class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for(@user)
      redirect_to root_path, notice: "Welcome, #{@user.name}!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
```

**Step 2: Create registration view**

Create `app/views/registrations/new.html.erb`:
```erb
<article>
  <header>
    <h1>Create Account</h1>
  </header>

  <%= form_with model: @user, url: registration_path do |f| %>
    <% if @user.errors.any? %>
      <article class="alert">
        <ul>
          <% @user.errors.full_messages.each do |message| %>
            <li><%= message %></li>
          <% end %>
        </ul>
      </article>
    <% end %>

    <label>
      Name
      <%= f.text_field :name, required: true, autofocus: true %>
    </label>

    <label>
      Email
      <%= f.email_field :email, required: true, autocomplete: "email" %>
    </label>

    <label>
      Password
      <%= f.password_field :password, required: true, autocomplete: "new-password" %>
    </label>

    <label>
      Confirm Password
      <%= f.password_field :password_confirmation, required: true %>
    </label>

    <%= f.submit "Create Account" %>
  <% end %>

  <footer>
    <p>Already have an account? <%= link_to "Sign in", new_session_path %></p>
  </footer>
</article>
```

**Step 3: Update login view to link to registration**

Modify `app/views/sessions/new.html.erb`:
```erb
<article>
  <header>
    <h1>Sign In</h1>
  </header>

  <%= form_with url: session_path do |f| %>
    <label>
      Email
      <%= f.email_field :email, required: true, autofocus: true, autocomplete: "email" %>
    </label>

    <label>
      Password
      <%= f.password_field :password, required: true, autocomplete: "current-password" %>
    </label>

    <%= f.submit "Sign In" %>
  <% end %>

  <footer>
    <p>Don't have an account? <%= link_to "Create one", new_registration_path %></p>
  </footer>
</article>
```

**Step 4: Update routes**

Modify `config/routes.rb`:
```ruby
Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]

  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"
end
```

**Step 5: Create placeholder dashboard controller**

Create `app/controllers/dashboard_controller.rb`:
```ruby
class DashboardController < ApplicationController
  def show
  end
end
```

Create `app/views/dashboard/show.html.erb`:
```erb
<h1>Welcome, <%= current_user.name %>!</h1>
<p>Dashboard coming soon...</p>
```

**Step 6: Verify authentication flow**

Run: `bin/rails server`

Test:
1. Visit http://localhost:3000 → redirects to login
2. Click "Create one" → registration form
3. Create account → logged in, see dashboard
4. Click Logout → back to login
5. Sign in with created account → dashboard

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add registration flow and dashboard placeholder"
```

---

### Task 1.5: Create Seed Data

**Files:**
- Modify: `db/seeds.rb`

**Step 1: Create seed file with two users**

Replace `db/seeds.rb`:
```ruby
# Create two user accounts for the household
puts "Creating users..."

User.find_or_create_by!(email: "user1@home.local") do |u|
  u.name = "User One"
  u.password = "password123"
end

User.find_or_create_by!(email: "user2@home.local") do |u|
  u.name = "User Two"
  u.password = "password123"
end

puts "Created #{User.count} users"
```

**Step 2: Run seeds**

Run:
```bash
bin/rails db:seed
```

**Step 3: Verify login works with seeded users**

Run: `bin/rails server`
Login with: user1@home.local / password123

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add seed data for two household users"
```

---

## Milestone 2: Tasks Feature
**Testable outcome:** Create, view, edit, complete tasks. Filter by assignee. See status badges.

### Task 2.1: Generate Task Model

**Step 1: Generate model**

Run:
```bash
bin/rails generate model Task \
  title:string \
  status:integer \
  notes:text \
  due_date:date \
  archived_at:datetime \
  assigned_to:references \
  created_by:references
```

**Step 2: Update migration for proper references and defaults**

Edit the generated migration:
```ruby
class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.integer :status, default: 0, null: false
      t.text :notes
      t.date :due_date
      t.datetime :archived_at
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tasks, :status
    add_index :tasks, :due_date
  end
end
```

**Step 3: Run migration**

Run:
```bash
bin/rails db:migrate
```

**Step 4: Update Task model**

Replace `app/models/task.rb`:
```ruby
class Task < ApplicationRecord
  belongs_to :assigned_to, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User"

  enum :status, { todo: 0, in_progress: 1, done: 2 }

  validates :title, presence: true

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :overdue, -> { where("due_date < ?", Date.current).where.not(status: :done) }
  scope :assigned_to_user, ->(user) { where(assigned_to: user) }

  def overdue?
    due_date.present? && due_date < Date.current && !done?
  end
end
```

**Step 5: Update User model with association**

Add to `app/models/user.rb`:
```ruby
class User < ApplicationRecord
  has_secure_password

  has_many :assigned_tasks, class_name: "Task", foreign_key: :assigned_to_id
  has_many :created_tasks, class_name: "Task", foreign_key: :created_by_id

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  normalizes :email, with: ->(e) { e.strip.downcase }
end
```

**Step 6: Verify in console**

Run:
```bash
bin/rails console
```

```ruby
user = User.first
Task.create!(title: "Test task", created_by: user, status: :todo)
Task.count # => 1
Task.first.todo? # => true
```

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add Task model with status enum and scopes"
```

---

### Task 2.2: Create Tasks Controller

**Files:**
- Create: `app/controllers/tasks_controller.rb`

**Step 1: Generate controller**

Run:
```bash
bin/rails generate controller Tasks index show new edit
```

**Step 2: Implement controller**

Replace `app/controllers/tasks_controller.rb`:
```ruby
class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy]

  def index
    @tasks = Task.active.includes(:assigned_to, :created_by)

    if params[:filter] == "mine"
      @tasks = @tasks.assigned_to_user(current_user)
    elsif params[:filter] == "unassigned"
      @tasks = @tasks.where(assigned_to: nil)
    end

    @tasks = @tasks.order(Arel.sql("CASE status WHEN 0 THEN 1 WHEN 1 THEN 2 WHEN 2 THEN 3 END"), :due_date)
  end

  def show
  end

  def new
    @task = Task.new
  end

  def edit
  end

  def create
    @task = Task.new(task_params)
    @task.created_by = current_user

    if @task.save
      redirect_to tasks_path, notice: "Task created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @task.update(task_params)
      redirect_to tasks_path, notice: "Task updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy
    redirect_to tasks_path, notice: "Task deleted."
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :status, :notes, :due_date, :assigned_to_id)
  end
end
```

**Step 3: Update routes**

Modify `config/routes.rb`:
```ruby
Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]

  resources :tasks

  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"
end
```

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add Tasks controller with CRUD and filtering"
```

---

### Task 2.3: Create Task Views

**Files:**
- Replace: `app/views/tasks/index.html.erb`
- Replace: `app/views/tasks/show.html.erb`
- Replace: `app/views/tasks/new.html.erb`
- Replace: `app/views/tasks/edit.html.erb`
- Create: `app/views/tasks/_form.html.erb`

**Step 1: Create index view**

Replace `app/views/tasks/index.html.erb`:
```erb
<header>
  <h1>Tasks</h1>
  <%= link_to "New Task", new_task_path, role: "button" %>
</header>

<nav>
  <ul>
    <li><%= link_to "All", tasks_path, class: params[:filter].blank? ? "contrast" : "" %></li>
    <li><%= link_to "Mine", tasks_path(filter: "mine"), class: params[:filter] == "mine" ? "contrast" : "" %></li>
    <li><%= link_to "Unassigned", tasks_path(filter: "unassigned"), class: params[:filter] == "unassigned" ? "contrast" : "" %></li>
  </ul>
</nav>

<% %w[todo in_progress done].each do |status| %>
  <% tasks_for_status = @tasks.select { |t| t.status == status } %>
  <% next if tasks_for_status.empty? %>

  <section>
    <h2><%= status.titleize %></h2>

    <% tasks_for_status.each do |task| %>
      <article>
        <header>
          <div>
            <strong><%= link_to task.title, task_path(task) %></strong>
            <% if task.overdue? %>
              <mark>Overdue</mark>
            <% end %>
          </div>
          <small>
            <% if task.assigned_to %>
              Assigned to: <%= task.assigned_to.name %>
            <% else %>
              Unassigned
            <% end %>
            <% if task.due_date %>
              | Due: <%= task.due_date.strftime("%b %d") %>
            <% end %>
          </small>
        </header>

        <footer>
          <%= form_with model: task, method: :patch, style: "display: inline;" do |f| %>
            <% if task.todo? %>
              <%= f.hidden_field :status, value: "in_progress" %>
              <%= f.submit "Start", class: "outline" %>
            <% elsif task.in_progress? %>
              <%= f.hidden_field :status, value: "done" %>
              <%= f.submit "Complete", class: "outline" %>
            <% end %>
          <% end %>
          <%= link_to "Edit", edit_task_path(task), class: "outline", role: "button" %>
        </footer>
      </article>
    <% end %>
  </section>
<% end %>

<% if @tasks.empty? %>
  <p>No tasks found. <%= link_to "Create one", new_task_path %>.</p>
<% end %>
```

**Step 2: Create form partial**

Create `app/views/tasks/_form.html.erb`:
```erb
<%= form_with model: task do |f| %>
  <% if task.errors.any? %>
    <article class="alert">
      <ul>
        <% task.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </article>
  <% end %>

  <label>
    Title
    <%= f.text_field :title, required: true, autofocus: true %>
  </label>

  <label>
    Status
    <%= f.select :status, Task.statuses.keys.map { |s| [s.titleize, s] } %>
  </label>

  <label>
    Assigned To
    <%= f.collection_select :assigned_to_id, User.all, :id, :name, include_blank: "Unassigned" %>
  </label>

  <label>
    Due Date
    <%= f.date_field :due_date %>
  </label>

  <label>
    Notes
    <%= f.text_area :notes, rows: 4 %>
  </label>

  <div class="grid">
    <%= f.submit %>
    <%= link_to "Cancel", tasks_path, role: "button", class: "outline" %>
  </div>
<% end %>
```

**Step 3: Create new view**

Replace `app/views/tasks/new.html.erb`:
```erb
<h1>New Task</h1>
<%= render "form", task: @task %>
```

**Step 4: Create edit view**

Replace `app/views/tasks/edit.html.erb`:
```erb
<h1>Edit Task</h1>
<%= render "form", task: @task %>
```

**Step 5: Create show view**

Replace `app/views/tasks/show.html.erb`:
```erb
<article>
  <header>
    <h1><%= @task.title %></h1>
    <span class="badge badge-<%= @task.status.dasherize %>"><%= @task.status.titleize %></span>
    <% if @task.overdue? %>
      <mark>Overdue</mark>
    <% end %>
  </header>

  <dl>
    <dt>Assigned To</dt>
    <dd><%= @task.assigned_to&.name || "Unassigned" %></dd>

    <dt>Created By</dt>
    <dd><%= @task.created_by.name %></dd>

    <dt>Due Date</dt>
    <dd><%= @task.due_date&.strftime("%B %d, %Y") || "No due date" %></dd>

    <dt>Created</dt>
    <dd><%= @task.created_at.strftime("%B %d, %Y at %I:%M %p") %></dd>

    <% if @task.notes.present? %>
      <dt>Notes</dt>
      <dd><%= simple_format(@task.notes) %></dd>
    <% end %>
  </dl>

  <footer>
    <%= link_to "Edit", edit_task_path(@task), role: "button" %>
    <%= link_to "Back to Tasks", tasks_path, role: "button", class: "outline" %>
    <%= button_to "Delete", task_path(@task), method: :delete,
        data: { turbo_confirm: "Are you sure?" },
        class: "outline contrast" %>
  </footer>
</article>
```

**Step 6: Test the tasks feature**

Run: `bin/rails server`

Test:
1. Go to Tasks → see empty list
2. Click "New Task" → create a task
3. Task appears in "Todo" section
4. Click "Start" → moves to "In Progress"
5. Click "Complete" → moves to "Done"
6. Use filters → only shows relevant tasks
7. Edit task → changes save

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add Task views with status workflow and filtering"
```

---

## Milestone 3: Wishlist Feature
**Testable outcome:** Create wishlist items (purchases/projects), see tabs, running total for shopping

### Task 3.1: Generate WishlistItem Model

**Step 1: Generate model**

Run:
```bash
bin/rails generate model WishlistItem \
  title:string \
  item_type:integer \
  price:decimal \
  priority:integer \
  notes:text \
  link:string \
  created_by:references
```

**Step 2: Update migration**

Edit the migration:
```ruby
class CreateWishlistItems < ActiveRecord::Migration[8.0]
  def change
    create_table :wishlist_items do |t|
      t.string :title, null: false
      t.integer :item_type, default: 0, null: false
      t.decimal :price, precision: 10, scale: 2
      t.integer :priority, default: 1, null: false
      t.text :notes
      t.string :link
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :wishlist_items, :item_type
    add_index :wishlist_items, :priority
  end
end
```

**Step 3: Run migration**

```bash
bin/rails db:migrate
```

**Step 4: Update model**

Replace `app/models/wishlist_item.rb`:
```ruby
class WishlistItem < ApplicationRecord
  belongs_to :created_by, class_name: "User"

  enum :item_type, { purchase: 0, future_project: 1 }
  enum :priority, { low: 0, medium: 1, high: 2 }

  validates :title, presence: true

  scope :purchases, -> { where(item_type: :purchase) }
  scope :projects, -> { where(item_type: :future_project) }
  scope :by_priority, -> { order(priority: :desc, created_at: :desc) }
end
```

**Step 5: Add association to User**

Add to `app/models/user.rb` (in the associations section):
```ruby
has_many :wishlist_items, foreign_key: :created_by_id
```

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: add WishlistItem model with type and priority enums"
```

---

### Task 3.2: Create WishlistItems Controller and Views

**Step 1: Generate controller**

```bash
bin/rails generate controller WishlistItems index show new edit
```

**Step 2: Implement controller**

Replace `app/controllers/wishlist_items_controller.rb`:
```ruby
class WishlistItemsController < ApplicationController
  before_action :set_wishlist_item, only: %i[show edit update destroy]

  def index
    @tab = params[:tab] || "purchases"
    @items = if @tab == "projects"
      WishlistItem.projects.by_priority
    else
      WishlistItem.purchases.by_priority
    end
    @total = WishlistItem.purchases.sum(:price) if @tab == "purchases"
  end

  def show
  end

  def new
    @wishlist_item = WishlistItem.new(item_type: params[:type] || :purchase)
  end

  def edit
  end

  def create
    @wishlist_item = WishlistItem.new(wishlist_item_params)
    @wishlist_item.created_by = current_user

    if @wishlist_item.save
      redirect_to wishlist_items_path(tab: @wishlist_item.purchase? ? "purchases" : "projects"),
                  notice: "Item added to wishlist."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @wishlist_item.update(wishlist_item_params)
      redirect_to wishlist_items_path, notice: "Item updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @wishlist_item.destroy
    redirect_to wishlist_items_path, notice: "Item removed."
  end

  private

  def set_wishlist_item
    @wishlist_item = WishlistItem.find(params[:id])
  end

  def wishlist_item_params
    params.require(:wishlist_item).permit(:title, :item_type, :price, :priority, :notes, :link)
  end
end
```

**Step 3: Add routes**

Add to `config/routes.rb` (inside the draw block):
```ruby
resources :wishlist_items
```

**Step 4: Create index view**

Replace `app/views/wishlist_items/index.html.erb`:
```erb
<header>
  <h1>Wishlist</h1>
  <div class="quick-actions">
    <%= link_to "Add Purchase", new_wishlist_item_path(type: "purchase"), role: "button" %>
    <%= link_to "Add Project", new_wishlist_item_path(type: "future_project"), role: "button", class: "outline" %>
  </div>
</header>

<nav>
  <ul>
    <li>
      <%= link_to "Shopping List", wishlist_items_path(tab: "purchases"),
          class: @tab == "purchases" ? "contrast" : "" %>
    </li>
    <li>
      <%= link_to "Future Projects", wishlist_items_path(tab: "projects"),
          class: @tab == "projects" ? "contrast" : "" %>
    </li>
  </ul>
</nav>

<% if @tab == "purchases" && @total && @total > 0 %>
  <p><strong>Total: <%= number_to_currency(@total) %></strong></p>
<% end %>

<% if @items.empty? %>
  <p>No items yet.</p>
<% else %>
  <% @items.each do |item| %>
    <article>
      <header>
        <div>
          <strong><%= link_to item.title, wishlist_item_path(item) %></strong>
          <span class="badge badge-<%= item.priority %>"><%= item.priority.titleize %></span>
        </div>
        <% if item.price.present? %>
          <strong><%= number_to_currency(item.price) %></strong>
        <% end %>
      </header>

      <% if item.notes.present? %>
        <p><%= truncate(item.notes, length: 100) %></p>
      <% end %>

      <footer>
        <% if item.link.present? %>
          <%= link_to "View Link", item.link, target: "_blank", rel: "noopener", role: "button", class: "outline" %>
        <% end %>
        <%= link_to "Edit", edit_wishlist_item_path(item), role: "button", class: "outline" %>
        <%= button_to "Remove", wishlist_item_path(item), method: :delete,
            data: { turbo_confirm: "Remove from wishlist?" }, class: "outline contrast" %>
      </footer>
    </article>
  <% end %>
<% end %>
```

**Step 5: Create form partial**

Create `app/views/wishlist_items/_form.html.erb`:
```erb
<%= form_with model: wishlist_item do |f| %>
  <% if wishlist_item.errors.any? %>
    <article class="alert">
      <ul>
        <% wishlist_item.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </article>
  <% end %>

  <label>
    Title
    <%= f.text_field :title, required: true, autofocus: true %>
  </label>

  <label>
    Type
    <%= f.select :item_type, WishlistItem.item_types.keys.map { |t| [t.titleize, t] } %>
  </label>

  <label>
    Priority
    <%= f.select :priority, WishlistItem.priorities.keys.map { |p| [p.titleize, p] } %>
  </label>

  <label>
    Price (optional)
    <%= f.number_field :price, step: 0.01, min: 0, placeholder: "0.00" %>
  </label>

  <label>
    Link (optional)
    <%= f.url_field :link, placeholder: "https://..." %>
  </label>

  <label>
    Notes
    <%= f.text_area :notes, rows: 4 %>
  </label>

  <div class="grid">
    <%= f.submit %>
    <%= link_to "Cancel", wishlist_items_path, role: "button", class: "outline" %>
  </div>
<% end %>
```

**Step 6: Create new/edit/show views**

Replace `app/views/wishlist_items/new.html.erb`:
```erb
<h1>Add to Wishlist</h1>
<%= render "form", wishlist_item: @wishlist_item %>
```

Replace `app/views/wishlist_items/edit.html.erb`:
```erb
<h1>Edit Item</h1>
<%= render "form", wishlist_item: @wishlist_item %>
```

Replace `app/views/wishlist_items/show.html.erb`:
```erb
<article>
  <header>
    <h1><%= @wishlist_item.title %></h1>
    <span class="badge badge-<%= @wishlist_item.priority %>"><%= @wishlist_item.priority.titleize %></span>
    <span class="badge"><%= @wishlist_item.item_type.titleize %></span>
  </header>

  <dl>
    <% if @wishlist_item.price.present? %>
      <dt>Price</dt>
      <dd><%= number_to_currency(@wishlist_item.price) %></dd>
    <% end %>

    <% if @wishlist_item.link.present? %>
      <dt>Link</dt>
      <dd><%= link_to @wishlist_item.link, @wishlist_item.link, target: "_blank", rel: "noopener" %></dd>
    <% end %>

    <dt>Added By</dt>
    <dd><%= @wishlist_item.created_by.name %></dd>

    <dt>Added On</dt>
    <dd><%= @wishlist_item.created_at.strftime("%B %d, %Y") %></dd>

    <% if @wishlist_item.notes.present? %>
      <dt>Notes</dt>
      <dd><%= simple_format(@wishlist_item.notes) %></dd>
    <% end %>
  </dl>

  <footer>
    <%= link_to "Edit", edit_wishlist_item_path(@wishlist_item), role: "button" %>
    <%= link_to "Back to Wishlist", wishlist_items_path, role: "button", class: "outline" %>
  </footer>
</article>
```

**Step 7: Test wishlist feature**

Run: `bin/rails server`

Test:
1. Go to Wishlist → see empty shopping list
2. Add a purchase with price → appears in list with price
3. Add another → see running total
4. Switch to "Future Projects" tab
5. Add a project → shows in projects tab

**Step 8: Commit**

```bash
git add -A
git commit -m "feat: add Wishlist feature with purchases and projects tabs"
```

---

## Milestone 4: Reminders Feature
**Testable outcome:** Create reminders, mark complete, recurring reminders create next occurrence

### Task 4.1: Generate Reminder Model

**Step 1: Generate model**

```bash
bin/rails generate model Reminder \
  title:string \
  due_date:date \
  recurrence_rule:string \
  completed_at:datetime \
  remindable:references{polymorphic} \
  created_by:references
```

**Step 2: Update migration**

```ruby
class CreateReminders < ActiveRecord::Migration[8.0]
  def change
    create_table :reminders do |t|
      t.string :title, null: false
      t.date :due_date, null: false
      t.string :recurrence_rule
      t.datetime :completed_at
      t.references :remindable, polymorphic: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :reminders, :due_date
    add_index :reminders, :completed_at
  end
end
```

**Step 3: Run migration**

```bash
bin/rails db:migrate
```

**Step 4: Implement model with recurrence logic**

Replace `app/models/reminder.rb`:
```ruby
class Reminder < ApplicationRecord
  belongs_to :remindable, polymorphic: true, optional: true
  belongs_to :created_by, class_name: "User"

  validates :title, presence: true
  validates :due_date, presence: true

  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :overdue, -> { pending.where("due_date < ?", Date.current) }
  scope :upcoming, ->(days = 7) { pending.where(due_date: Date.current..days.days.from_now) }
  scope :by_due_date, -> { order(:due_date) }

  RECURRENCE_RULES = %w[daily weekly monthly yearly].freeze

  def overdue?
    completed_at.nil? && due_date < Date.current
  end

  def recurring?
    recurrence_rule.present?
  end

  def complete!
    transaction do
      update!(completed_at: Time.current)
      create_next_occurrence if recurring?
    end
  end

  private

  def create_next_occurrence
    next_date = calculate_next_date
    return unless next_date

    Reminder.create!(
      title: title,
      due_date: next_date,
      recurrence_rule: recurrence_rule,
      remindable: remindable,
      created_by: created_by
    )
  end

  def calculate_next_date
    case recurrence_rule
    when "daily"
      due_date + 1.day
    when "weekly"
      due_date + 1.week
    when "monthly"
      due_date + 1.month
    when "yearly"
      due_date + 1.year
    when /^every_(\d+)_days$/
      due_date + ::Regexp.last_match(1).to_i.days
    end
  end
end
```

**Step 5: Add association to User**

Add to `app/models/user.rb`:
```ruby
has_many :reminders, foreign_key: :created_by_id
```

**Step 6: Test in console**

```bash
bin/rails console
```

```ruby
user = User.first
r = Reminder.create!(title: "Test", due_date: Date.today, recurrence_rule: "weekly", created_by: user)
r.complete!
Reminder.count # => 2 (original completed + new pending)
Reminder.pending.last.due_date # => 7 days from now
```

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add Reminder model with recurring logic"
```

---

### Task 4.2: Create Reminders Controller and Views

**Step 1: Generate controller**

```bash
bin/rails generate controller Reminders index show new edit
```

**Step 2: Implement controller**

Replace `app/controllers/reminders_controller.rb`:
```ruby
class RemindersController < ApplicationController
  before_action :set_reminder, only: %i[show edit update destroy complete]

  def index
    @reminders = Reminder.pending.by_due_date.includes(:remindable, :created_by)
    @overdue = @reminders.select(&:overdue?)
    @upcoming = @reminders.reject(&:overdue?)
  end

  def show
  end

  def new
    @reminder = Reminder.new(due_date: Date.current)
  end

  def edit
  end

  def create
    @reminder = Reminder.new(reminder_params)
    @reminder.created_by = current_user

    if @reminder.save
      redirect_to reminders_path, notice: "Reminder created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @reminder.update(reminder_params)
      redirect_to reminders_path, notice: "Reminder updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @reminder.destroy
    redirect_to reminders_path, notice: "Reminder deleted."
  end

  def complete
    @reminder.complete!
    notice = @reminder.recurring? ? "Completed. Next reminder created." : "Completed."
    redirect_to reminders_path, notice: notice
  end

  private

  def set_reminder
    @reminder = Reminder.find(params[:id])
  end

  def reminder_params
    params.require(:reminder).permit(:title, :due_date, :recurrence_rule)
  end
end
```

**Step 3: Add routes**

Update `config/routes.rb`:
```ruby
resources :reminders do
  member do
    post :complete
  end
end
```

**Step 4: Create index view**

Replace `app/views/reminders/index.html.erb`:
```erb
<header>
  <h1>Reminders</h1>
  <%= link_to "New Reminder", new_reminder_path, role: "button" %>
</header>

<% if @overdue.any? %>
  <section>
    <h2><mark>Overdue</mark></h2>
    <% @overdue.each do |reminder| %>
      <%= render "reminder", reminder: reminder %>
    <% end %>
  </section>
<% end %>

<% if @upcoming.any? %>
  <section>
    <h2>Upcoming</h2>
    <% @upcoming.each do |reminder| %>
      <%= render "reminder", reminder: reminder %>
    <% end %>
  </section>
<% end %>

<% if @reminders.empty? %>
  <p>No reminders. <%= link_to "Create one", new_reminder_path %>.</p>
<% end %>
```

**Step 5: Create reminder partial**

Create `app/views/reminders/_reminder.html.erb`:
```erb
<article>
  <header>
    <div>
      <strong><%= link_to reminder.title, reminder_path(reminder) %></strong>
      <% if reminder.recurring? %>
        <small>(Recurring: <%= reminder.recurrence_rule.titleize %>)</small>
      <% end %>
    </div>
    <span><%= reminder.due_date.strftime("%b %d, %Y") %></span>
  </header>

  <% if reminder.remindable.present? %>
    <p>
      <small>
        Linked to:
        <% case reminder.remindable %>
        <% when Appliance %>
          <%= link_to reminder.remindable.name, appliance_path(reminder.remindable) %>
        <% end %>
      </small>
    </p>
  <% end %>

  <footer>
    <%= button_to "Complete", complete_reminder_path(reminder), method: :post, class: "outline" %>
    <%= link_to "Edit", edit_reminder_path(reminder), role: "button", class: "outline" %>
  </footer>
</article>
```

**Step 6: Create form partial**

Create `app/views/reminders/_form.html.erb`:
```erb
<%= form_with model: reminder do |f| %>
  <% if reminder.errors.any? %>
    <article class="alert">
      <ul>
        <% reminder.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </article>
  <% end %>

  <label>
    Title
    <%= f.text_field :title, required: true, autofocus: true %>
  </label>

  <label>
    Due Date
    <%= f.date_field :due_date, required: true %>
  </label>

  <label>
    Recurrence (optional)
    <%= f.select :recurrence_rule,
        [["None", nil], ["Daily", "daily"], ["Weekly", "weekly"], ["Monthly", "monthly"], ["Yearly", "yearly"]],
        include_blank: false %>
  </label>

  <div class="grid">
    <%= f.submit %>
    <%= link_to "Cancel", reminders_path, role: "button", class: "outline" %>
  </div>
<% end %>
```

**Step 7: Create new/edit/show views**

Replace `app/views/reminders/new.html.erb`:
```erb
<h1>New Reminder</h1>
<%= render "form", reminder: @reminder %>
```

Replace `app/views/reminders/edit.html.erb`:
```erb
<h1>Edit Reminder</h1>
<%= render "form", reminder: @reminder %>
```

Replace `app/views/reminders/show.html.erb`:
```erb
<article>
  <header>
    <h1><%= @reminder.title %></h1>
    <% if @reminder.recurring? %>
      <span class="badge"><%= @reminder.recurrence_rule.titleize %></span>
    <% end %>
  </header>

  <dl>
    <dt>Due Date</dt>
    <dd><%= @reminder.due_date.strftime("%B %d, %Y") %></dd>

    <dt>Created By</dt>
    <dd><%= @reminder.created_by.name %></dd>

    <% if @reminder.remindable.present? %>
      <dt>Linked To</dt>
      <dd><%= @reminder.remindable.try(:name) || @reminder.remindable.try(:title) %></dd>
    <% end %>
  </dl>

  <footer>
    <%= button_to "Complete", complete_reminder_path(@reminder), method: :post %>
    <%= link_to "Edit", edit_reminder_path(@reminder), role: "button", class: "outline" %>
    <%= link_to "Back", reminders_path, role: "button", class: "outline" %>
  </footer>
</article>
```

**Step 8: Test reminders feature**

Run: `bin/rails server`

Test:
1. Create a non-recurring reminder → appears in list
2. Complete it → disappears
3. Create a weekly recurring reminder
4. Complete it → old one gone, new one appears 1 week later
5. Overdue reminders show at top with highlight

**Step 9: Commit**

```bash
git add -A
git commit -m "feat: add Reminders feature with recurring support"
```

---

## Milestone 5: Appliances Feature
**Testable outcome:** Add appliances with warranty info, see warranty status colors, link reminders

### Task 5.1: Generate Appliance Model

**Step 1: Generate model**

```bash
bin/rails generate model Appliance \
  name:string \
  location:string \
  brand:string \
  model_number:string \
  serial_number:string \
  purchase_date:date \
  warranty_expires:date \
  manual_url:string \
  notes:text
```

**Step 2: Update migration**

```ruby
class CreateAppliances < ActiveRecord::Migration[8.0]
  def change
    create_table :appliances do |t|
      t.string :name, null: false
      t.string :location
      t.string :brand
      t.string :model_number
      t.string :serial_number
      t.date :purchase_date
      t.date :warranty_expires
      t.string :manual_url
      t.text :notes

      t.timestamps
    end
  end
end
```

**Step 3: Run migration**

```bash
bin/rails db:migrate
```

**Step 4: Implement model**

Replace `app/models/appliance.rb`:
```ruby
class Appliance < ApplicationRecord
  has_many :reminders, as: :remindable, dependent: :nullify

  validates :name, presence: true

  def warranty_status
    return :none unless warranty_expires

    if warranty_expires < Date.current
      :expired
    elsif warranty_expires < 6.months.from_now
      :warning
    else
      :ok
    end
  end

  def warranty_status_class
    case warranty_status
    when :ok then "warranty-ok"
    when :warning then "warranty-warning"
    when :expired then "warranty-expired"
    else ""
    end
  end
end
```

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add Appliance model with warranty status"
```

---

### Task 5.2: Create Appliances Controller and Views

**Step 1: Generate controller**

```bash
bin/rails generate controller Appliances index show new edit
```

**Step 2: Implement controller**

Replace `app/controllers/appliances_controller.rb`:
```ruby
class AppliancesController < ApplicationController
  before_action :set_appliance, only: %i[show edit update destroy]

  def index
    @appliances = Appliance.order(:name)
  end

  def show
    @reminders = @appliance.reminders.pending.by_due_date
  end

  def new
    @appliance = Appliance.new
  end

  def edit
  end

  def create
    @appliance = Appliance.new(appliance_params)

    if @appliance.save
      redirect_to @appliance, notice: "Appliance added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @appliance.update(appliance_params)
      redirect_to @appliance, notice: "Appliance updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @appliance.destroy
    redirect_to appliances_path, notice: "Appliance removed."
  end

  private

  def set_appliance
    @appliance = Appliance.find(params[:id])
  end

  def appliance_params
    params.require(:appliance).permit(
      :name, :location, :brand, :model_number, :serial_number,
      :purchase_date, :warranty_expires, :manual_url, :notes
    )
  end
end
```

**Step 3: Add routes**

Update `config/routes.rb`:
```ruby
resources :appliances
```

**Step 4: Create index view**

Replace `app/views/appliances/index.html.erb`:
```erb
<header>
  <h1>Appliances</h1>
  <%= link_to "Add Appliance", new_appliance_path, role: "button" %>
</header>

<% if @appliances.empty? %>
  <p>No appliances added yet.</p>
<% else %>
  <div class="card-grid">
    <% @appliances.each do |appliance| %>
      <article>
        <header>
          <strong><%= link_to appliance.name, appliance_path(appliance) %></strong>
          <% if appliance.warranty_expires %>
            <span class="<%= appliance.warranty_status_class %>">
              <% case appliance.warranty_status %>
              <% when :ok %>
                ✓ Warranty OK
              <% when :warning %>
                ⚠ Warranty expires soon
              <% when :expired %>
                ✗ Warranty expired
              <% end %>
            </span>
          <% end %>
        </header>

        <% if appliance.location.present? %>
          <p><small><%= appliance.location %></small></p>
        <% end %>

        <% if appliance.brand.present? || appliance.model_number.present? %>
          <p>
            <%= [appliance.brand, appliance.model_number].compact.join(" - ") %>
          </p>
        <% end %>
      </article>
    <% end %>
  </div>
<% end %>
```

**Step 5: Create form partial**

Create `app/views/appliances/_form.html.erb`:
```erb
<%= form_with model: appliance do |f| %>
  <% if appliance.errors.any? %>
    <article class="alert">
      <ul>
        <% appliance.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </article>
  <% end %>

  <label>
    Name
    <%= f.text_field :name, required: true, autofocus: true, placeholder: "e.g., Refrigerator" %>
  </label>

  <label>
    Location
    <%= f.text_field :location, placeholder: "e.g., Kitchen, Basement" %>
  </label>

  <div class="grid">
    <label>
      Brand
      <%= f.text_field :brand %>
    </label>

    <label>
      Model Number
      <%= f.text_field :model_number %>
    </label>
  </div>

  <label>
    Serial Number
    <%= f.text_field :serial_number %>
  </label>

  <div class="grid">
    <label>
      Purchase Date
      <%= f.date_field :purchase_date %>
    </label>

    <label>
      Warranty Expires
      <%= f.date_field :warranty_expires %>
    </label>
  </div>

  <label>
    Manual URL
    <%= f.url_field :manual_url, placeholder: "https://..." %>
  </label>

  <label>
    Notes
    <%= f.text_area :notes, rows: 4 %>
  </label>

  <div class="grid">
    <%= f.submit %>
    <%= link_to "Cancel", appliances_path, role: "button", class: "outline" %>
  </div>
<% end %>
```

**Step 6: Create new/edit views**

Replace `app/views/appliances/new.html.erb`:
```erb
<h1>Add Appliance</h1>
<%= render "form", appliance: @appliance %>
```

Replace `app/views/appliances/edit.html.erb`:
```erb
<h1>Edit Appliance</h1>
<%= render "form", appliance: @appliance %>
```

**Step 7: Create show view**

Replace `app/views/appliances/show.html.erb`:
```erb
<article>
  <header>
    <h1><%= @appliance.name %></h1>
    <% if @appliance.warranty_expires %>
      <span class="<%= @appliance.warranty_status_class %>">
        Warranty: <%= @appliance.warranty_expires.strftime("%B %d, %Y") %>
        (<%= @appliance.warranty_status.to_s.titleize %>)
      </span>
    <% end %>
  </header>

  <dl>
    <% if @appliance.location.present? %>
      <dt>Location</dt>
      <dd><%= @appliance.location %></dd>
    <% end %>

    <% if @appliance.brand.present? %>
      <dt>Brand</dt>
      <dd><%= @appliance.brand %></dd>
    <% end %>

    <% if @appliance.model_number.present? %>
      <dt>Model</dt>
      <dd><%= @appliance.model_number %></dd>
    <% end %>

    <% if @appliance.serial_number.present? %>
      <dt>Serial Number</dt>
      <dd><%= @appliance.serial_number %></dd>
    <% end %>

    <% if @appliance.purchase_date.present? %>
      <dt>Purchase Date</dt>
      <dd><%= @appliance.purchase_date.strftime("%B %d, %Y") %></dd>
    <% end %>

    <% if @appliance.manual_url.present? %>
      <dt>Manual</dt>
      <dd><%= link_to "View Manual", @appliance.manual_url, target: "_blank", rel: "noopener" %></dd>
    <% end %>

    <% if @appliance.notes.present? %>
      <dt>Notes</dt>
      <dd><%= simple_format(@appliance.notes) %></dd>
    <% end %>
  </dl>

  <% if @reminders.any? %>
    <section>
      <h2>Linked Reminders</h2>
      <% @reminders.each do |reminder| %>
        <p>
          <%= link_to reminder.title, reminder_path(reminder) %>
          - Due: <%= reminder.due_date.strftime("%b %d") %>
        </p>
      <% end %>
    </section>
  <% end %>

  <footer>
    <%= link_to "Edit", edit_appliance_path(@appliance), role: "button" %>
    <%= link_to "Back", appliances_path, role: "button", class: "outline" %>
    <%= button_to "Delete", appliance_path(@appliance), method: :delete,
        data: { turbo_confirm: "Delete this appliance?" }, class: "outline contrast" %>
  </footer>
</article>
```

**Step 8: Update reminder form to link appliances**

Update `app/views/reminders/_form.html.erb` to add appliance selection:
```erb
<%= form_with model: reminder do |f| %>
  <% if reminder.errors.any? %>
    <article class="alert">
      <ul>
        <% reminder.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </article>
  <% end %>

  <label>
    Title
    <%= f.text_field :title, required: true, autofocus: true %>
  </label>

  <label>
    Due Date
    <%= f.date_field :due_date, required: true %>
  </label>

  <label>
    Recurrence (optional)
    <%= f.select :recurrence_rule,
        [["None", nil], ["Daily", "daily"], ["Weekly", "weekly"], ["Monthly", "monthly"], ["Yearly", "yearly"]],
        include_blank: false %>
  </label>

  <label>
    Link to Appliance (optional)
    <%= f.select :remindable_id, Appliance.order(:name).pluck(:name, :id), include_blank: "None" %>
    <%= f.hidden_field :remindable_type, value: "Appliance" %>
  </label>

  <div class="grid">
    <%= f.submit %>
    <%= link_to "Cancel", reminders_path, role: "button", class: "outline" %>
  </div>
<% end %>
```

Update `app/controllers/reminders_controller.rb` to permit remindable fields:
```ruby
def reminder_params
  params.require(:reminder).permit(:title, :due_date, :recurrence_rule, :remindable_id, :remindable_type)
end
```

**Step 9: Test appliances feature**

Run: `bin/rails server`

Test:
1. Add an appliance with warranty date in past → shows red "expired"
2. Add one expiring in 3 months → shows yellow "warning"
3. Add one expiring in 1 year → shows green "ok"
4. Create a reminder linked to an appliance → shows on appliance detail page

**Step 10: Commit**

```bash
git add -A
git commit -m "feat: add Appliances feature with warranty status and linked reminders"
```

---

## Milestone 6: Wiki Feature
**Testable outcome:** Create wiki pages with markdown, link between pages with [[Title]] syntax

### Task 6.1: Generate WikiPage Model

**Step 1: Generate model**

```bash
bin/rails generate model WikiPage \
  title:string \
  body:text \
  created_by:references \
  updated_by:references
```

**Step 2: Update migration**

```ruby
class CreateWikiPages < ActiveRecord::Migration[8.0]
  def change
    create_table :wiki_pages do |t|
      t.string :title, null: false
      t.text :body
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :wiki_pages, :title, unique: true
  end
end
```

**Step 3: Run migration**

```bash
bin/rails db:migrate
```

**Step 4: Add redcarpet gem for markdown**

Add to `Gemfile`:
```ruby
gem "redcarpet"
```

Run:
```bash
bundle install
```

**Step 5: Implement model with wiki links**

Replace `app/models/wiki_page.rb`:
```ruby
class WikiPage < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"

  validates :title, presence: true, uniqueness: { case_sensitive: false }

  before_save :normalize_title

  def self.find_by_title(title)
    find_by("LOWER(title) = ?", title.downcase)
  end

  def rendered_body
    return "" if body.blank?

    # Convert [[Page Title]] links to actual links
    linked_body = body.gsub(/\[\[([^\]]+)\]\]/) do |_match|
      page_title = ::Regexp.last_match(1)
      if WikiPage.find_by_title(page_title)
        "[#{page_title}](/wiki_pages/#{CGI.escape(page_title)})"
      else
        "[#{page_title}](/wiki_pages/new?title=#{CGI.escape(page_title)})"
      end
    end

    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(hard_wrap: true, link_attributes: { target: "_blank" }),
      autolink: true,
      tables: true,
      fenced_code_blocks: true
    )
    markdown.render(linked_body).html_safe
  end

  private

  def normalize_title
    self.title = title.strip if title.present?
  end
end
```

**Step 6: Add association to User**

Add to `app/models/user.rb`:
```ruby
has_many :wiki_pages, foreign_key: :created_by_id
```

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add WikiPage model with markdown rendering and wiki links"
```

---

### Task 6.2: Create WikiPages Controller and Views

**Step 1: Generate controller**

```bash
bin/rails generate controller WikiPages index show new edit
```

**Step 2: Implement controller with title-based lookup**

Replace `app/controllers/wiki_pages_controller.rb`:
```ruby
class WikiPagesController < ApplicationController
  before_action :set_wiki_page, only: %i[show edit update destroy]

  def index
    @wiki_pages = WikiPage.order(:title)
  end

  def show
  end

  def new
    @wiki_page = WikiPage.new(title: params[:title])
  end

  def edit
  end

  def create
    @wiki_page = WikiPage.new(wiki_page_params)
    @wiki_page.created_by = current_user
    @wiki_page.updated_by = current_user

    if @wiki_page.save
      redirect_to wiki_page_path(@wiki_page.title), notice: "Page created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @wiki_page.updated_by = current_user
    if @wiki_page.update(wiki_page_params)
      redirect_to wiki_page_path(@wiki_page.title), notice: "Page updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @wiki_page.destroy
    redirect_to wiki_pages_path, notice: "Page deleted."
  end

  private

  def set_wiki_page
    @wiki_page = WikiPage.find_by_title(params[:id]) || WikiPage.find(params[:id])
  end

  def wiki_page_params
    params.require(:wiki_page).permit(:title, :body)
  end
end
```

**Step 3: Add routes**

Update `config/routes.rb`:
```ruby
resources :wiki_pages
```

**Step 4: Create index view**

Replace `app/views/wiki_pages/index.html.erb`:
```erb
<header>
  <h1>Wiki</h1>
  <%= link_to "New Page", new_wiki_page_path, role: "button" %>
</header>

<% if @wiki_pages.empty? %>
  <p>No wiki pages yet. <%= link_to "Create the first one", new_wiki_page_path %>.</p>
<% else %>
  <ul>
    <% @wiki_pages.each do |page| %>
      <li>
        <%= link_to page.title, wiki_page_path(page.title) %>
        <small>Updated <%= time_ago_in_words(page.updated_at) %> ago by <%= page.updated_by.name %></small>
      </li>
    <% end %>
  </ul>
<% end %>
```

**Step 5: Create form partial**

Create `app/views/wiki_pages/_form.html.erb`:
```erb
<%= form_with model: wiki_page do |f| %>
  <% if wiki_page.errors.any? %>
    <article class="alert">
      <ul>
        <% wiki_page.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </article>
  <% end %>

  <label>
    Title
    <%= f.text_field :title, required: true, autofocus: wiki_page.new_record? %>
  </label>

  <label>
    Content (Markdown supported)
    <%= f.text_area :body, rows: 15, autofocus: !wiki_page.new_record? %>
  </label>

  <details>
    <summary>Formatting Help</summary>
    <ul>
      <li><code>**bold**</code> for <strong>bold</strong></li>
      <li><code>*italic*</code> for <em>italic</em></li>
      <li><code>[[Page Title]]</code> to link to another wiki page</li>
      <li><code># Heading</code> for headings (## for smaller)</li>
      <li><code>- item</code> for bullet lists</li>
      <li><code>1. item</code> for numbered lists</li>
    </ul>
  </details>

  <div class="grid">
    <%= f.submit %>
    <%= link_to "Cancel", wiki_pages_path, role: "button", class: "outline" %>
  </div>
<% end %>
```

**Step 6: Create new/edit/show views**

Replace `app/views/wiki_pages/new.html.erb`:
```erb
<h1>New Wiki Page</h1>
<%= render "form", wiki_page: @wiki_page %>
```

Replace `app/views/wiki_pages/edit.html.erb`:
```erb
<h1>Edit: <%= @wiki_page.title %></h1>
<%= render "form", wiki_page: @wiki_page %>
```

Replace `app/views/wiki_pages/show.html.erb`:
```erb
<article>
  <header>
    <h1><%= @wiki_page.title %></h1>
    <small>
      Last updated <%= time_ago_in_words(@wiki_page.updated_at) %> ago
      by <%= @wiki_page.updated_by.name %>
    </small>
  </header>

  <div class="wiki-content">
    <%= @wiki_page.rendered_body %>
  </div>

  <footer>
    <%= link_to "Edit", edit_wiki_page_path(@wiki_page.title), role: "button" %>
    <%= link_to "All Pages", wiki_pages_path, role: "button", class: "outline" %>
    <%= button_to "Delete", wiki_page_path(@wiki_page), method: :delete,
        data: { turbo_confirm: "Delete this page?" }, class: "outline contrast" %>
  </footer>
</article>
```

**Step 7: Test wiki feature**

Run: `bin/rails server`

Test:
1. Create a wiki page "HVAC System" with some markdown
2. In body, add `[[Maintenance Schedule]]` link
3. Save → link appears (clicking creates new page)
4. Create "Maintenance Schedule" page
5. Go back to HVAC page → link now works

**Step 8: Commit**

```bash
git add -A
git commit -m "feat: add Wiki feature with markdown and page linking"
```

---

## Milestone 7: Dashboard & Search
**Testable outcome:** Dashboard shows my tasks and upcoming reminders. Search finds content across all models.

### Task 7.1: Implement Dashboard

**Step 1: Update dashboard controller**

Replace `app/controllers/dashboard_controller.rb`:
```ruby
class DashboardController < ApplicationController
  def show
    @my_tasks = Task.active
                    .assigned_to_user(current_user)
                    .where(status: [:todo, :in_progress])
                    .or(Task.active.overdue.assigned_to_user(current_user))
                    .order(:due_date)
                    .limit(10)

    @overdue_reminders = Reminder.overdue.by_due_date.limit(5)
    @upcoming_reminders = Reminder.upcoming(7).by_due_date.limit(5)
  end
end
```

**Step 2: Update dashboard view**

Replace `app/views/dashboard/show.html.erb`:
```erb
<h1>Welcome, <%= current_user.name %>!</h1>

<div class="grid">
  <section>
    <h2>My Tasks</h2>
    <% if @my_tasks.empty? %>
      <p>No tasks assigned to you.</p>
    <% else %>
      <% @my_tasks.each do |task| %>
        <article>
          <header>
            <%= link_to task.title, task_path(task) %>
            <span class="badge badge-<%= task.status.dasherize %>"><%= task.status.titleize %></span>
            <% if task.overdue? %>
              <mark>Overdue</mark>
            <% end %>
          </header>
          <% if task.due_date %>
            <small>Due: <%= task.due_date.strftime("%b %d") %></small>
          <% end %>
        </article>
      <% end %>
    <% end %>
    <%= link_to "View All Tasks", tasks_path %>
  </section>

  <section>
    <h2>Reminders</h2>

    <% if @overdue_reminders.any? %>
      <h3><mark>Overdue</mark></h3>
      <% @overdue_reminders.each do |reminder| %>
        <p>
          <%= link_to reminder.title, reminder_path(reminder) %>
          <small>(<%= reminder.due_date.strftime("%b %d") %>)</small>
        </p>
      <% end %>
    <% end %>

    <% if @upcoming_reminders.any? %>
      <h3>Next 7 Days</h3>
      <% @upcoming_reminders.each do |reminder| %>
        <p>
          <%= link_to reminder.title, reminder_path(reminder) %>
          <small>(<%= reminder.due_date.strftime("%b %d") %>)</small>
        </p>
      <% end %>
    <% end %>

    <% if @overdue_reminders.empty? && @upcoming_reminders.empty? %>
      <p>No upcoming reminders.</p>
    <% end %>

    <%= link_to "View All Reminders", reminders_path %>
  </section>
</div>

<section>
  <h2>Quick Add</h2>
  <div class="quick-actions">
    <%= link_to "New Task", new_task_path, role: "button", class: "outline" %>
    <%= link_to "New Reminder", new_reminder_path, role: "button", class: "outline" %>
    <%= link_to "Add to Wishlist", new_wishlist_item_path, role: "button", class: "outline" %>
  </div>
</section>
```

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: implement dashboard with tasks and reminders"
```

---

### Task 7.2: Add Search

**Step 1: Create search controller**

```bash
bin/rails generate controller Search index
```

**Step 2: Implement search**

Replace `app/controllers/search_controller.rb`:
```ruby
class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    return if @query.blank?

    @tasks = Task.active.where("title LIKE ? OR notes LIKE ?", "%#{@query}%", "%#{@query}%").limit(10)
    @wiki_pages = WikiPage.where("title LIKE ? OR body LIKE ?", "%#{@query}%", "%#{@query}%").limit(10)
    @appliances = Appliance.where("name LIKE ? OR brand LIKE ? OR notes LIKE ?",
      "%#{@query}%", "%#{@query}%", "%#{@query}%").limit(10)
    @wishlist_items = WishlistItem.where("title LIKE ? OR notes LIKE ?", "%#{@query}%", "%#{@query}%").limit(10)
  end
end
```

**Step 3: Add route**

Update `config/routes.rb`:
```ruby
get "search", to: "search#index"
```

**Step 4: Create search view**

Replace `app/views/search/index.html.erb`:
```erb
<h1>Search</h1>

<%= form_with url: search_path, method: :get, data: { turbo_frame: "_top" } do |f| %>
  <div class="grid">
    <%= f.search_field :q, value: @query, placeholder: "Search...", autofocus: true %>
    <%= f.submit "Search" %>
  </div>
<% end %>

<% if @query.present? %>
  <% total = [@tasks, @wiki_pages, @appliances, @wishlist_items].compact.sum(&:count) %>

  <p><%= total %> results for "<%= @query %>"</p>

  <% if @tasks&.any? %>
    <section>
      <h2>Tasks (<%= @tasks.count %>)</h2>
      <ul>
        <% @tasks.each do |task| %>
          <li><%= link_to task.title, task_path(task) %> - <%= task.status.titleize %></li>
        <% end %>
      </ul>
    </section>
  <% end %>

  <% if @wiki_pages&.any? %>
    <section>
      <h2>Wiki Pages (<%= @wiki_pages.count %>)</h2>
      <ul>
        <% @wiki_pages.each do |page| %>
          <li><%= link_to page.title, wiki_page_path(page.title) %></li>
        <% end %>
      </ul>
    </section>
  <% end %>

  <% if @appliances&.any? %>
    <section>
      <h2>Appliances (<%= @appliances.count %>)</h2>
      <ul>
        <% @appliances.each do |appliance| %>
          <li><%= link_to appliance.name, appliance_path(appliance) %> - <%= appliance.location %></li>
        <% end %>
      </ul>
    </section>
  <% end %>

  <% if @wishlist_items&.any? %>
    <section>
      <h2>Wishlist (<%= @wishlist_items.count %>)</h2>
      <ul>
        <% @wishlist_items.each do |item| %>
          <li><%= link_to item.title, wishlist_item_path(item) %></li>
        <% end %>
      </ul>
    </section>
  <% end %>

  <% if total == 0 %>
    <p>No results found.</p>
  <% end %>
<% end %>
```

**Step 5: Add search to navigation**

Update the navigation in `app/views/layouts/application.html.erb` to include search:
```erb
<% if user_signed_in? %>
  <nav class="container-fluid">
    <ul>
      <li><strong>Home Manager</strong></li>
    </ul>
    <ul>
      <li><%= link_to "Dashboard", root_path %></li>
      <li><%= link_to "Tasks", tasks_path %></li>
      <li><%= link_to "Wishlist", wishlist_items_path %></li>
      <li><%= link_to "Reminders", reminders_path %></li>
      <li><%= link_to "Wiki", wiki_pages_path %></li>
      <li><%= link_to "Appliances", appliances_path %></li>
      <li><%= link_to "Search", search_path %></li>
      <li><%= link_to current_user.name, edit_user_path(current_user) %></li>
      <li><%= button_to "Logout", session_path, method: :delete, class: "outline" %></li>
    </ul>
  </nav>
<% end %>
```

**Step 6: Test search**

Run: `bin/rails server`

Test:
1. Add some tasks, wiki pages, appliances
2. Click Search → enter query
3. Results appear grouped by type

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add global search across all content types"
```

---

## Milestone 8: AI Assistant
**Testable outcome:** Click Ask button, enter question, get AI response using household context

### Task 8.1: Add Anthropic Gem and Configure

**Step 1: Add gem**

Add to `Gemfile`:
```ruby
gem "anthropic"
```

Run:
```bash
bundle install
```

**Step 2: Add API key to credentials**

Run:
```bash
EDITOR="code --wait" bin/rails credentials:edit
```

Add:
```yaml
anthropic:
  api_key: your-api-key-here
```

**Step 3: Commit**

```bash
git add -A
git commit -m "chore: add anthropic gem for AI assistant"
```

---

### Task 8.2: Create AI Assistant Controller

**Step 1: Generate controller**

```bash
bin/rails generate controller Assistant show
```

**Step 2: Implement controller**

Replace `app/controllers/assistant_controller.rb`:
```ruby
class AssistantController < ApplicationController
  def show
    @question = params[:question].to_s.strip
    return if @question.blank?

    context = gather_context(@question)
    @response = ask_claude(@question, context)
  end

  private

  def gather_context(question)
    context_parts = []

    # All appliances (small dataset, include all)
    appliances = Appliance.all
    if appliances.any?
      context_parts << "## Appliances\n" + appliances.map { |a|
        details = [a.name]
        details << "Location: #{a.location}" if a.location.present?
        details << "Brand: #{a.brand}" if a.brand.present?
        details << "Model: #{a.model_number}" if a.model_number.present?
        details << "Notes: #{a.notes}" if a.notes.present?
        details.join(", ")
      }.join("\n")
    end

    # Relevant wiki pages (keyword search)
    keywords = question.downcase.split(/\s+/).reject { |w| w.length < 3 }
    wiki_pages = WikiPage.all.select do |page|
      keywords.any? do |keyword|
        page.title.downcase.include?(keyword) ||
        page.body.to_s.downcase.include?(keyword)
      end
    end.first(10)

    if wiki_pages.any?
      context_parts << "## Wiki Pages\n" + wiki_pages.map { |p|
        "### #{p.title}\n#{p.body}"
      }.join("\n\n")
    end

    # Upcoming reminders
    reminders = Reminder.pending.by_due_date.limit(10)
    if reminders.any?
      context_parts << "## Upcoming Reminders\n" + reminders.map { |r|
        "- #{r.title} (due: #{r.due_date.strftime('%B %d, %Y')})"
      }.join("\n")
    end

    context_parts.join("\n\n")
  end

  def ask_claude(question, context)
    client = Anthropic::Client.new(api_key: Rails.application.credentials.dig(:anthropic, :api_key))

    system_prompt = <<~PROMPT
      You are a helpful home assistant for a household. You have access to information about
      the household's appliances, wiki documentation, and reminders.

      Answer questions helpfully and concisely. If you don't have enough information to answer,
      say so. Format your response using markdown.

      Here is the household information:

      #{context}
    PROMPT

    response = client.messages.create(
      model: "claude-sonnet-4-20250514",
      max_tokens: 1024,
      system: system_prompt,
      messages: [{ role: "user", content: question }]
    )

    response.content.first.text
  rescue Anthropic::Error => e
    "Sorry, I couldn't process your question. Error: #{e.message}"
  rescue StandardError => e
    Rails.logger.error("AI Assistant error: #{e.message}")
    "Sorry, something went wrong. Please try again."
  end
end
```

**Step 3: Add route**

Update `config/routes.rb`:
```ruby
get "assistant", to: "assistant#show"
```

**Step 4: Create view**

Replace `app/views/assistant/show.html.erb`:
```erb
<h1>Ask the Assistant</h1>

<%= form_with url: assistant_path, method: :get, data: { turbo_frame: "_top" } do |f| %>
  <label>
    Your Question
    <%= f.text_area :question, value: @question, rows: 3, autofocus: true,
        placeholder: "e.g., When was the HVAC last serviced?" %>
  </label>

  <%= f.submit "Ask" %>
<% end %>

<% if @question.present? %>
  <article>
    <header>
      <strong>Your question:</strong>
      <p><%= @question %></p>
    </header>

    <% if @response.present? %>
      <div class="wiki-content">
        <%= Redcarpet::Markdown.new(
          Redcarpet::Render::HTML.new(hard_wrap: true),
          autolink: true, tables: true, fenced_code_blocks: true
        ).render(@response).html_safe %>
      </div>
    <% end %>
  </article>
<% end %>
```

**Step 5: Add to navigation**

Update navigation in `app/views/layouts/application.html.erb` to add Ask link before Search:
```erb
<li><%= link_to "Ask", assistant_path %></li>
```

**Step 6: Test AI assistant**

Run: `bin/rails server`

Test:
1. Add some appliances and wiki pages with info
2. Go to Ask
3. Ask "What appliances do we have?" → should list them
4. Ask about specific appliance info → should respond with details

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add AI assistant with household context"
```

---

## Final Routes Summary

Your final `config/routes.rb` should look like:
```ruby
Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]

  resources :tasks
  resources :wishlist_items
  resources :reminders do
    member do
      post :complete
    end
  end
  resources :appliances
  resources :wiki_pages

  get "search", to: "search#index"
  get "assistant", to: "assistant#show"

  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"
end
```

---

## Summary of Milestones

| Milestone | Features | Test By |
|-----------|----------|---------|
| 1 | Rails app + Auth | Login/logout works |
| 2 | Tasks | Create, assign, complete tasks |
| 3 | Wishlist | Add purchases/projects, see totals |
| 4 | Reminders | Create recurring reminders |
| 5 | Appliances | Track warranty status |
| 6 | Wiki | Markdown pages with [[links]] |
| 7 | Dashboard + Search | Overview + find anything |
| 8 | AI Assistant | Ask questions about home |

Each milestone is independently testable and commits frequently.
