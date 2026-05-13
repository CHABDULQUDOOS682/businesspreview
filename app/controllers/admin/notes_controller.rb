class Admin::NotesController < ApplicationController
  layout "admin"

  before_action :set_note, only: [ :edit, :update, :destroy ]

  def create
    @note = Note.new(note_params)

    if @note.save
      redirect_back fallback_location: admin_business_path(@note.business), notice: "Note added."
    else
      redirect_back fallback_location: admin_business_path(@note.business), alert: @note.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    if @note.update(note_params)
      redirect_to admin_business_path(@note.business), notice: "Note updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    business = @note.business
    @note.destroy
    redirect_back fallback_location: admin_business_path(business), notice: "Note deleted."
  end

  private

  def set_note
    @note = Note.find(params[:id])
  end

  def note_params
    params.require(:note).permit(:body, :business_id)
  end
end
