class Users::PasswordsController < Devise::PasswordsController
  def update
    super do |resource|
      resource.update_column(:active, true) if resource.persisted? && !resource.active?
    end
  end
end
