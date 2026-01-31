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
    @reminder.created_by = Current.user

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
