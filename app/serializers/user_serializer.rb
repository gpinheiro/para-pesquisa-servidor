class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :username, :role, :email, :created_at, :get_avatar => 'avatar'

  def get_avatar
    object.avatar.url
  end
end
