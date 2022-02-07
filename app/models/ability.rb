# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize user
    user ||= User.new
    return if user.blank?

    if user.admin?
      can :manage, :all
    else
      can :manage, :cart
      can %i(index show update create), Order, user_id: user.id
    end
  end
end
