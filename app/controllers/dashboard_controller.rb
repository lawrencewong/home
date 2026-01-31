class DashboardController < ApplicationController
  def show
    @my_tasks = Task.active
                    .assigned_to_user(Current.user)
                    .where.not(status: :done)
                    .order(:due_date)
                    .limit(10)

    @overdue_reminders = Reminder.overdue.by_due_date.limit(5)
    @upcoming_reminders = Reminder.upcoming(7).by_due_date.limit(5)
  end
end
