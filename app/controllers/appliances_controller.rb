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
