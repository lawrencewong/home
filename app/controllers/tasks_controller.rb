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
